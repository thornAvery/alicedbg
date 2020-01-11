/**
 * Loop on exceptions and continue whenever possible. No user input for this UI.
 */
module ui.loop;

//import misc.ddc;
import core.stdc.stdio;
import debugger.exception, debugger.core, debugger.disasm;

extern (C):

/// Starts plain UI
int ui_loop() {
	dbg_sethandle(&except);
	return dbg_loop;
}

private:

__gshared uint en;
int except(exception_t *e) {
	disasm_params_t p;
	p.include = DISASM_I_MACHINECODE | DISASM_I_MNEMONICS;
	p.addr = e.addr;
	disasm_line(p);
	printf(
	"* EXCEPTION #%d\n"~
	"PID=%u  TID=%u\n"~
	"%s (%X) at %zX\n"~
	"Code: %s (%s)\n"~
	"\n"
	,
	en++,
	e.pid, e.tid,
	e.type.typestr, e.oscode, e.addrv,
	&p.mcbuf, &p.mnbuf
	);
	return DebuggerAction.proceed;
}