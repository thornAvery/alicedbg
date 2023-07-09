/**
 * Command interpreter.
 *
 * Authors: dd86k <dd@dax.moe>
 * Copyright: © dd86k <dd@dax.moe>
 * License: BSD-3-Clause
 */
module ui.cmd;

import adbg.include.c.stdio;
import adbg.include.c.stdlib : exit, free;
import core.stdc.string;
import adbg.error;
import adbg.utils.string;
import adbg.v1.debugger;
import adbg.v1.debugger.exception;
import adbg.v1.debugger.context;
import adbg.v1.disassembler;
import common, term;

extern (C):

/// Enter the command-line loop
/// Returns: Error code
int app_cmd() {
	term_init;
	return cmd_loop;
}

//TODO: cmd_file -- read (commands) from file

/// Execute a line of command
/// Returns: Error code
int cmd_exec(char *command) {
	return cmd_execl(command, strlen(command));
}
/// Execute a line of command
/// Returns: Error code
int cmd_execl(char *command, size_t len) {
	int argc = void;
	char** argv = adbg_util_expand(command, &argc);
	return cmd_execv(argc, cast(const(char)**)argv);
}

private:

//
// Private globals
//

__gshared immutable const(char) *cmd_fmt   = " %-10s                      %s\n";
__gshared immutable const(char) *cmd_fmta  = " %-10s %-20s %s\n";
__gshared bool continue_; /// if user wants to continue
__gshared bool paused;	/// if debuggee is paused
__gshared int lasterror;	/// last command error

//
// loop
//

int cmd_loop() {
	char* line = void;
	int argc = void;
	continue_ = true;
	
	while (continue_) {
		cmd_prompt(lasterror); // print prompt
		line = term_readline(&argc); // read line
		
		//TODO: remove once term gets key events
		if (line == null) {
			printf("^D");
			return 0;
		}
		
		lasterror = cmd_execl(line, argc); // execute line
	}
	
	return lasterror;
}

//
// prompt
//

void cmd_prompt(int err) {
	enum fmt = "[%d adbg%c] ";
	printf(fmt, err, paused ? '*' : ' ');
}

void cmd_help_chapter(const(char) *name) {
	puts(name);
}
void cmd_help_paragraph(const(char) *p) {
L_PRINT:
	int o = printf("\t%.72s\n", p);
	if (o < 72)
		return;
	p += 72;
	goto L_PRINT;
}

//
// Command handling
//

struct command_t {
	const(char) *str;	/// command string
	const(char) *synop;	/// command synopsis
	const(char) *desc;	/// help description
	int function(int, const(char)**) func;	/// command implementation
	void function() help;	/// help implementation
}
immutable command_t[] commands = [
	{
		"load", "<file> [<arg>...]",
		"Load executable file into the debugger",
		&cmd_c_load, &cmd_h_load
	},
//	{ "core",   null, "Load core debugging object into debugger", &cmd_c_load },
//	{ "attach", null, "Attach the debugger to pid", &cmd_c_pid },
//	{ "b",      "<action>", "Breakpoint management", & },
//	{ "d",      "<addr>", "Disassemble address", & },
	{
		"run", null,
		"Run debugger after loading an executable",
		&cmd_c_run
	},
	{
		"r", null,
		"Register management",
		&cmd_c_r
	},
	{
		"help", "<command>",
		"Show this help screen",
		&cmd_c_help
	},
	{
		"maps", null,
		"Show memory maps",
		&cmd_c_maps
	},
	{
		"quit", null,
		"Quit",
		&cmd_c_quit
	},
	{
		"q", null,
		"Alias to quit",
		&cmd_c_quit
	},
];

int cmd_execv(int argc, const(char) **argv) {
	if (argc <= 0 || argv == null)
		return 0;
	
	foreach (comm; commands)
		if (strcmp(argv[0], comm.str) == 0)
			return comm.func(argc, argv);
	
	printf("unknown command: '%s'\n", argv[0]);
	return AppError.invalidCommand;
}

//
// Action handling
//

struct action_t {
	immutable(char) *str;	/// long strion
	immutable(char) *desc;	/// help description
	AdbgAction val;	/// action value
}
immutable action_t[] actions = [
	{ "continue", "Resume debuggee", AdbgAction.proceed },
	{ "c",        "Alias to continue", AdbgAction.proceed },
	{ "close",    "Close debuggee process", AdbgAction.exit },
	{ "si",       "Instruction step", AdbgAction.step },
];

int cmd_action(const(char) *a) {
	foreach (action; actions)
		if (strcmp(a, action.str) == 0)
			return action.val;
	
	return -1;
}

//
// load command
//

int cmd_c_load(int argc, const(char) **argv) {
	if (argc < 2) {
		puts("missing file argument");
		return AppError.invalidParameter;
	}
	
	if (adbg_load(argv[1], argc > 2 ? argv + 2: null)) {
		printerror;
		return AppError.loadFailed;
	}
	
	printf("Program '%s' loaded\n", argv[1]);
	return 0;
}
void cmd_h_load() {
	cmd_help_chapter("DESCRIPTION");
	cmd_help_paragraph(
	`Load an executable file into the debugger. Any arguments after the `~
	`file are arguments passed into the debugger.`
	);
}

//
// r command
//

int cmd_c_r(int argc, const(char) **argv) {
	if (adbg_state == AdbgStatus.idle) {
		puts("No program loaded or not paused");
		return AppError.pauseRequired;
	}
	
	thread_context_t ctx = void;
	adbg_ctx_init(&ctx);
	adbg_ctx_get(&ctx);
	
	if (ctx.count == 0) {
		puts("No registers available");
		return AppError.unavailable;
	}
	
	int m = ctx.count;
	register_t *r = ctx.items.ptr;
	const(char) *reg = argv[1];
	
	// searching for reg
	//TODO: reg=value when setting context is available
	if (reg) {
		for (size_t i; i < m; ++i, ++r) {
			if (strcmp(reg, r.name))
				continue;
			printf("%-8s  0x%8s  %s\n",
				r.name,
				adbg_ctx_reg_hex(r),
				adbg_ctx_reg_val(r));
			return 0;
		}
		puts("Register not found");
		return AppError.invalidParameter;
	}
	
	for (size_t i; i < m; ++i, ++r)
		printf("%-8s  0x%8s  %s\n",
			r.name,
			adbg_ctx_reg_hex(r),
			adbg_ctx_reg_val(r));
	return 0;
}

//
// help command
//

int cmd_c_help(int argc, const(char) **argv) {
	const(char) *arg = argv[1];
	
	// Help on command
	if (arg) {
		foreach (comm; commands) {
			if (strcmp(arg, comm.str))
				continue;
			if (comm.help == null) {
				puts("Command has no help article available");
				return AppError.unavailable;
			}
			printf("COMMAND\n\t%s - %s\n\nSYNOPSIS\n\t%s %s\n\n",
				comm.str, comm.desc,
				comm.str, comm.synop);
			comm.help();
			return 0;
		}
		printf("No help article found for '%s'\n", arg);
		return AppError.invalidCommand;
	}
	
	// Command list
	puts("Debugger commands:");
	foreach (comm; commands) {
		if (comm.synop)
			printf(cmd_fmta, comm.str, comm.synop, comm.desc);
		else
			printf(cmd_fmt, comm.str, comm.desc);
	}
	
	// Action list
	puts("\nWhen debuggee is paused:");
	foreach (action; actions)
		printf(cmd_fmt, action.str, action.desc);
	
	return 0;
}

//
// run command
//

int cmd_c_run(int argc, const(char) **argv) {
	if (adbg_state != AdbgStatus.ready) {
		puts("No programs loaded");
		return AppError.alreadyLoaded;
	}
	return adbg_run(&cmd_handler);
}

//
// maps command
//

int cmd_c_maps(int argc, const(char) **argv) {
	if (adbg_state() == AdbgStatus.idle) {
		puts("error: Attach or spawn debuggee first");
		return 1;
	}
	
	adbg_mm_map *maps = void;
	size_t mlen = void;
	if (adbg_mm_maps(&maps, &mlen))
	{
		printf("error: %s\n", adbg_error_msg());
		return adbg_errno();
	}
	for (size_t i; i < mlen; ++i)
	{
		adbg_mm_map *map = &maps[i];
		printf("%16llx %8llx %s\n", cast(size_t)map.base, map.size, map.name.ptr);
	}
	if (mlen) free(maps);
	
	return 0;
}

//
// quit command
//

int cmd_c_quit(int argc, const(char) **argv) {
	//TODO: Quit confirmation if debuggee is alive
	exit(0);
	return 0;
}

//
// exception handler
//

int cmd_handler(exception_t *ex) {
	memcpy(&globals.last_exception, ex, exception_t.sizeof);
	
	printf("*	Thread %d stopped for: %s ("~ADBG_OS_ERROR_FORMAT~")\n",
		ex.tid, adbg_exception_string(ex.type), ex.oscode);
	
	int length = void;
	int argc = void;
	paused = true;
	
	if (ex.fault) {
		printf("	Fault address: %zx\n", ex.fault.sz);
		adbg_disasm_opcode_t op = void;
		if (adbg_disasm_once_debuggee(&globals.dism,
			&op,
			AdbgDisasmMode.file,
			ex.fault.sz)) {
			printf("	Faulting instruction: (error:%s)\n", adbg_error_msg);
		} else with (globals) {
			adbg_disasm_format(&dism,
				bufferMnemonic.ptr,
				bufferMnemonic.sizeof, &op);
			adbg_disasm_machine(&dism,
				bufferMachine.ptr,
				bufferMachine.sizeof, &op);
			printf("	Faulting instruction: [%s] %s\n",
				bufferMachine.ptr, bufferMnemonic.ptr);
		}
	}
	
L_INPUT:
	cmd_prompt(lasterror);
	char* line = term_readline(&length);
	if (line == null) {
		continue_ = false;
		return AdbgAction.exit;
	}
	const(char)** argv = cast(const(char)**)adbg_util_expand(line, &argc);
	
	int a = cmd_action(argv[0]);
	if (a > 0) {
		paused = false;
		return a;
	}
	
	lasterror = cmd_execv(argc, argv);
	goto L_INPUT;
}
