/// Loop on exceptions and continue whenever possible.
///
/// Authors: dd86k <dd@dax.moe>
/// Copyright: © dd86k <dd@dax.moe>
/// License: BSD-3-Clause
module examples.simple;

import core.stdc.stdio;
import core.stdc.stdlib;
import adbg;

extern (C):

int main(int argc, const(char) **argv) {
	if (argc < 2)
		die(1, "Missing path to executable");
	
	process = adbg_debugger_spawn(argv[1], 0);
	if (process == null)
		die;
	
	feature_disasm = adbg_dasm_open(&dasm, adbg_process_get_machine(process)) == 0;
	if (feature_disasm == false)
		printf("warning: Disassembler unavailable (%s)", adbg_error_msg);
	
	// Process input
LOOP:
	switch (choice("Action [?=Help]")) {
	case '?':
		puts(
		"s - Instruction step.\n"~
		"c - Continue.\n"~
		"q - Quit."
		);
		goto LOOP;
	case 's':
		puts("Stepping...");
		adbg_debugger_stepi(process);
		break;
	case 'c':
		puts("Continuing...");
		adbg_debugger_continue(process);
		break;
	case 'q':
		puts("Quitting...");
		return 0;
	default:
		goto LOOP;
	}
	
	adbg_debugger_wait(process, &loop_handler);
	goto LOOP;
}

private: // Shuts up dscanner

void die(int code = 0, const(char) *reason = null) {
	printf("error: %s\n", reason ? reason : adbg_error_msg);
	if (code == 0) code = adbg_errno;
	exit(code);
}

int choice(const(char) *msg) {
	import core.stdc.ctype : isprint;
	printf("\n%s: ", msg);
INPUT:
	int c = getchar;
	if (isprint(c)) return c;
	goto INPUT;
}

__gshared adbg_process_t *process;
__gshared adbg_disassembler_t dasm;
__gshared bool feature_disasm;

void loop_handler(adbg_exception_t *ex) {
	__gshared uint ex_num; /// Exception counter
	printf(
	"\n----------------------------------------\n"~
	"* EXCEPTION #%u: %s ("~ADBG_OS_ERROR_FORMAT~")\n"~
	"* PID=%u TID=%u\n"~
	"* FAULT=%8llx ",
	ex_num++, adbg_exception_name(ex), ex.oscode,
	ex.pid, ex.tid,
	ex.fault_address
	);
	
	// Print disassembly if available
	if (feature_disasm && ex.faultz) {
		adbg_opcode_t op = void;
		if (adbg_dasm_process_once(&dasm, &op, process, ex.fault_address)) {
			printf(" (error:%s)\n", adbg_error_msg);
			return;
		}
		if (op.operands)
			printf(" (%s %s)\n", op.mnemonic, op.operands);
		else
			printf(" (%s)\n", op.mnemonic);
	}
}