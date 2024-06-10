/// Error handling, printing, and contracting
///
/// Authors: dd86k <dd@dax.moe>
/// Copyright: © dd86k <dd@dax.moe>
/// License: BSD-3-Clause-Clear
module common.error;


import adbg.platform;
import adbg.include.c.stdlib : exit;
import adbg.debugger.exception : adbg_exception_t, adbg_exception_name;
import adbg.self;
import adbg.machines : adbg_machine_default;
import adbg.disassembler;
import adbg.error;
import adbg.debugger.process;
import adbg.error;
import adbg.disassembler;
import adbg.debugger.exception;
import core.stdc.string : strerror;
import core.stdc.errno : errno;
import core.stdc.stdio;
import core.stdc.stdlib : malloc;

extern (C):

void print_error(const(char) *message,
	const(char)* mod = cast(char*)__MODULE__,
	int line = __LINE__) {
	debug {
		printf("[%s@%d] ", mod, line);
	}
	printf("error: %s\n", message);
}
void print_error_adbg(
	const(char)* mod = cast(char*)__FILE__,
	int line = __LINE__) {
	debug {
		printf("[%s@%d] ", mod, line);
	}
	const(adbg_error_t)* e = adbg_error_current();
	print_error(adbg_error_message(), e.mod, e.line);
}

void panic(int code, const(char)* message,
	const(char)* prefix = null,
	const(char)* mod = cast(char*)__MODULE__,
	int line = __LINE__) {
	if (prefix) printf("%s: ", prefix);
	print_error(message, mod, line);
	exit(code);
}
void panic_crt(const(char)* prefix = null,
	const(char)* mod = cast(char*)__MODULE__,
	int line = __LINE__) {
	panic(errno, strerror(errno), prefix, mod, line);
}
void panic_adbg(const(char)* prefix = null,
	const(char)* mod = cast(char*)__MODULE__,
	int line = __LINE__) {
	const(adbg_error_t)* e = adbg_error_current();
	panic(adbg_errno(), adbg_error_message(), prefix, e.mod, e.line);
}

void crashed(adbg_process_t *proc, adbg_exception_t *ex) {
	puts(
`
   _ _ _   _ _ _       _ _       _ _ _   _     _   _
 _|_|_|_| |_|_|_|_   _|_|_|_   _|_|_|_| |_|   |_| |_|
|_|       |_|_ _|_| |_|_ _|_| |_|_ _    |_|_ _|_| |_|
|_|       |_|_|_|_  |_|_|_|_|   |_|_|_  |_|_|_|_| |_|
|_|_ _ _  |_|   |_| |_|   |_|  _ _ _|_| |_|   |_|  _
  |_|_|_| |_|   |_| |_|   |_| |_|_|_|   |_|   |_| |_|
`
	);
	
	printf(
	"Exception  : %s\n"~
	"PID        : %d\n",
	adbg_exception_name(ex), adbg_process_get_pid(proc));
	
	//TODO: Get thread context
	
	// Fault address & disasm if available
	if (ex.faultz) {
		printf("Address    : %#zx\n", ex.faultz);
		
		adbg_opcode_t op = void;
		adbg_disassembler_t *dis = adbg_dis_open(adbg_machine_default());
		printf("Instruction:");
		if (dis && adbg_dis_process_once(dis, &op, proc, ex.fault_address) == 0) {
			// Print address
			// Print machine bytes
			for (size_t bi; bi < op.size; ++bi)
				printf(" %02x", op.machine[bi]);
			// 
			printf(" (%s", op.mnemonic);
			if (op.operands)
				printf(" %s", op.operands);
			// 
			puts(")");
		} else {
			printf(" Disassembly unavailable (%s)\n", adbg_error_message());
		}
	}
	
	//TODO: Option to attach debugger to this process
	exit(ex.oscode);
}
