/// Command interpreter.
///
/// Authors: dd86k <dd@dax.moe>
/// Copyright: © dd86k <dd@dax.moe>
/// License: BSD-3-Clause
module ui.cmd;

import adbg.include.c.stdio;
import adbg.include.c.stdlib;
import core.stdc.string;
import adbg.error;
import adbg.utils.string;
import adbg.v2.debugger;
import adbg.v2.disassembler;
import common, term;

//TODO: cmd_file -- read (commands) from file
//TODO: cmd_strace [on|off]
//TODO: Command re-structure
//      show r|registers
//      show b|breakpoints

extern (C):

/// Enter the command-line loop
/// Returns: Error code
int app_cmd() {
	tracee = alloc!adbg_process_t();
	disasm = alloc!adbg_disassembler_t();
	context = alloc!adbg_thread_context_t();
	
	// If file specified, load it
	if (globals.file) {
		if (adbg_spawn(tracee, globals.file, 0))
			return oops;
	}
	
	disasm_available = adbg_dasm_open(disasm) == AdbgError.success;
	if (disasm_available == false) {
		printf("warning: Disassembler not available (%s)\n",
			adbg_error_msg());
	}
	
	term_init;
	
	user_continue = true;
	
	return prompt();
}

private:

int prompt() {
	char* line = void;
	int argc = void;
	int error;
	while (user_continue) {
		cmd_prompt(error); // print prompt
		line = term_readline(&argc); // read line
		
		//TODO: remove once term gets key events
		if (line == null) {
			printf("^D");
			return 0;
		}
		
		error = cmd_execl(line, argc); // execute line
	}
	return error;
}

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

//
// Private globals
//

immutable const(char) *cmd_fmt   = " %-10s                      %s\n";
immutable const(char) *cmd_fmta  = " %-10s %-20s %s\n";
__gshared adbg_process_t *tracee;
__gshared adbg_disassembler_t *disasm;
__gshared adbg_thread_context_t *context;
__gshared bool user_continue;	/// if user wants to continue

__gshared bool disasm_available;

//
// prompt
//

void cmd_prompt(int err) {
	printf("[%3d adbg%c] ", err, adbg_status(tracee) == AdbgStatus.paused ? '*' : ' ');
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
	
	if (adbg_spawn(tracee, argv[1], argc > 2 ? argv + 2: null, 0)) {
		oops();
		return AppError.loadFailed;
	}
	
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
	if (adbg_status(tracee) == AdbgStatus.idle) {
		puts("No program loaded or not debugger_paused");
		return AppError.pauseRequired;
	}
	
	adbg_context_start(context, tracee);
	adbg_context_fill(tracee, context);
	
	if (context.count == 0) {
		puts("No registers available");
		return AppError.unavailable;
	}
	
	adbg_register_t *regs = context.items.ptr;
	const(char) *rselect = argc >= 1 ? argv[1] : null;
	bool found;
	for (size_t i; i < context.count; ++i) {
		adbg_register_t *reg = &context.items[i];
		char[12] hex = void;
		char[12] val = void;
		adbg_context_reg_hex(hex.ptr, 12, reg);
		adbg_context_reg_val(val.ptr, 12, reg);
		printf("%-8s  0x%8s  %s\n", regs[i].name, hex.ptr, val.ptr);
		if (rselect && strcmp(rselect, regs[i].name) == 0) break;
	}
	if (rselect && found == false) {
		puts("Register not found");
		return AppError.invalidParameter;
	}
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
	puts("\nWhen debuggee is debugger_paused:");
	foreach (action; actions)
		printf(cmd_fmt, action.str, action.desc);
	
	return 0;
}

//
// run command
//

int cmd_c_run(int argc, const(char) **argv) {
	if (adbg_status(tracee) != AdbgStatus.ready) {
		puts("No programs loaded");
		return AppError.alreadyLoaded;
	}
	return adbg_start(tracee, &cmd_handler);
}

//
// maps command
//

int cmd_c_maps(int argc, const(char) **argv) {
	if (adbg_status(tracee) == AdbgStatus.idle) {
		puts("error: Attach or spawn debuggee first");
		return 1;
	}
	
	adbg_memory_map_t *mmaps = void;
	size_t mcount = void;
	scope(exit) if (mcount) free(mmaps);
	
	if (adbg_memory_maps(tracee, &mmaps, &mcount, 0)) {
		return AppError.alicedbg;
	}
	for (size_t i; i < mcount; ++i) {
		adbg_memory_map_t *map = &mmaps[i];
		with (map) printf("%8zx %8llx %s\n", cast(size_t)base, size, name.ptr);
	}
	
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

int cmd_handler(adbg_exception_t *ex) {
	printf("*	Process %d thread %d stopped\n"
		~"	Due to %s ("~ADBG_OS_ERROR_FORMAT~")\n",
		ex.pid, ex.tid,
		adbg_exception_name(ex), ex.oscode);
	
	if (disasm_available && ex.fault) {
		// BUG: There should be something detecting VS2013 and earlier MSVCRT
		version (Windows)
			enum fmt = "	Fault address: %Ix\n";
		else
			enum fmt = "	Fault address: %zx\n";
		printf(fmt, ex.fault.sz);
		ubyte[16] data = void;
		adbg_opcode_t op = void;
		if (adbg_memory_read(tracee, ex.fault.sz, data.ptr, 16)) {
			oops;
			goto L_SKIP;
		}
		printf("	Faulting instruction: ");
		if (adbg_dasm_once(disasm, &op, data.ptr, 16))
			printf("(error:%s)\n", adbg_error_msg);
		else
			printf(" %llx %s %s\n",
				ex.fault.i64, op.mnemonic, op.operands);
	}
	
L_SKIP:
	return prompt;
}
