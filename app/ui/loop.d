/**
 * Loop on exceptions and continue whenever possible.
 *
 * Authors: dd86k <dd@dax.moe>
 * Copyright: © 2019-2021 dd86k
 * License: BSD-3-Clause
 */
module ui.loop;

import core.stdc.string : memcpy;
import adbg.etc.c.stdio;
import adbg.dbg, adbg.sys.err : SYS_ERR_FMT;
import adbg.disassembler, adbg.error;
import common, term;

//TODO: loop option or new ui for just logging in faults

extern (C):

/// Starts loop UI
int app_loop() {
	if (adbg_state != AdbgState.loaded) {
		puts("loop: No program loaded");
		return 1;
	}
	if (term_init) return 1;
	return adbg_run(&loop_handler);
}

private:

int loop_handler(exception_t *e) {
	__gshared uint en;
	printf(
	"\n----------------------------------------\n"~
	"* EXCEPTION #%u: %s ("~SYS_ERR_FMT~")\n"~
	"* PID=%u TID=%u\n",
	en++, adbg_exception_string(e.type), e.oscode,
	e.pid, e.tid,
	);
	
	// * Print disassembly, if available
	if (e.fault) {
		adbg_disasm_opcode_t op = void;
		if (adbg_disasm_once_debuggee(&globals.app.disasm, &op,
			AdbgDisasmMode.file, e.fault.sz)) {
			printf("> %p: (error:%s)\n", e.fault.raw, adbg_error_msg);
		} else with (globals.app) {
			adbg_disasm_format(&disasm,
				bufferMnemonic.ptr, bufferMnemonic.sizeof, &op);
			adbg_disasm_machine(&disasm,
				bufferMachine.ptr, bufferMachine.sizeof, &op);
			printf("> %p: (%s) %s\n",
				e.fault.raw, bufferMachine.ptr, bufferMnemonic.ptr);
		}
	}
	
	// * Process input
L_PROMPT:
	printf("\nAction [S=Step,C=Continue,Q=Quit] ");
	InputInfo input = void;
L_INPUT:
	term_read(&input);
	if (input.type != InputType.Key)
		goto L_INPUT;
	with (AdbgAction)
	switch (input.key.keyCode) {
	case Key.S: puts("Stepping...");	return step;
	case Key.C: puts("Continuing...");	return proceed;
	case Key.Q: puts("Quitting...");	return exit;
	default: goto L_PROMPT;
	}
}