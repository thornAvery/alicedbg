module debugger.disasm;

import debugger.arch;

extern (C):

/// Disassembler parameters structure
struct disasm_params_t { align(1):
	/// Character buffer for MACHINE CODE
	char [DISASM_BUF_SIZE]mcbuf;
	/// Character buffer index and current length for MACHINE CODE
	size_t mcbufi;
	/// Character buffer for MNEMONICS
	char [DISASM_BUF_SIZE]mnbuf;
	/// Character buffer index and current length for MNEMONICS
	size_t mnbufi;
	union {
		/// Memory address entry point. This value is modified to point
		/// to the next instruction address. Acts as instruction
		/// pointer/program counter.
		void *addr;
		/// Memory address entry point. This value is modified to point
		/// to the next instruction address. Acts as instruction
		/// pointer/program counter.
		size_t addrv;
		// Aliases
		ubyte  *addru8; 	/// Used internally
		ushort *addru16;	/// Used internally
		uint   *addru32;	/// Used internally
		ulong  *addru64;	/// Used internally
		byte   *addri8; 	/// Used internally
		short  *addri16;	/// Used internally
		int    *addri32;	/// Used internally
		long   *addri64;	/// Used internally
		float  *addrf32;	/// Used internally
		double *addrd32;	/// Used internally
	}
	/// Saved address position before the operation begins, good for
	/// printing purposes or calculating the delta after disassembling.
	size_t thisaddr;
	/// Error code. See DisasmError enumeration for more details.
	DisasmError error;
	/// Platform to disasm. See the DisasmABI enum for more details.
	ubyte abi;
	/// Assembler style. See DisasmStyle enums for more details.
	ubyte style;
	/// Operation mode. See DISASM_I_* flags. If unset, calculate
	/// and modify address pointer only.
	ubyte include;
	/// Demangle option. See DisasmDemangle enum.
	ubyte demangle;
	/// Settings flags. See DISASM_O_* flags.
	ushort options;
}
pragma(msg, "* disasm_params_t.sizeof: ", disasm_params_t.sizeof);

//
// Enumerations
//

/// Disassembler error
enum DisasmError {
	None,	/// Nothing to report, you can continue
	NoAuto,	/// Automatic mode is unavailable for compiled platform
	NoABI,	/// Invalid ABI was selected
}

/// Disassembler ABI
enum DisasmABI : ubyte {
	Auto,	/// Automatic (platform-dependant)
	x86,	/// x86
	x86_64,	/// AMD64
	ARM,	/// (Not implemented) ARM
	ARM64,	/// (Not implemented) AArch64
}

/// Disassembler x86 styles
enum DisasmStyleX86 : ubyte {
	Dasm,	/// (Not implemented) D inline x86 assembler
	Nasm,	/// (Not implemented) (NASM) Netwide Assembler
	Masm,	/// (Not implemented) (MASM) Microsoft Assembler
	Ideal,	/// (Not implemented) Borland Ideal
	Hydeasm,	/// (Not implemented) Randall Hyde High Level Assembly Language
	Att,	/// (Not implemented) AT&T
}

/// Disassembler symbol demangling
enum DisasmDemangle : ubyte {
	None,	/// (Not implemented) Leave symbol as-is
	C,	/// (Not implemented) C mangling
}

//
// Disasm constants
//

/// Character buffer size
enum DISASM_BUF_SIZE = 128;

version (X86)
	enum DISASM_DEFAULT_ABI = DisasmABI.x86;	/// Platform default ABI
else
version (X86_64)
	enum DISASM_DEFAULT_ABI = DisasmABI.x86_64;	/// Platform default ABI
else
version (ARM)
	enum DISASM_DEFAULT_ABI = DisasmABI.ARM;	/// Platform default ABI
else
version (AArch64)
	enum DISASM_DEFAULT_ABI = DisasmABI.ARM64;	/// Platform default ABI
else
	enum DISASM_DEFAULT_ABI = DisasmABI.Auto;	/// Platform default ABI


//
// Include bits
//

enum DISASM_I_MACHINECODE	= 0b0000_0001;	/// Include machine code
enum DISASM_I_MNEMONICS	= 0b0000_0010;	/// Include instruction mnemonics
enum DISASM_I_SYMBOLS	= 0b0000_0100;	/// (Not implemented) Include symbols
enum DISASM_I_SOURCE	= 0b0000_1000;	/// (Not implemented) Include source code
enum DISASM_I_EVERYTHING	= 0xFF;	/// Include everything

//
// Option bits
//

/// Disassembler flag: Go backwards instead of forward. More expensive to calculate!
enum DISASM_O_BACKWARD	= 0x0002;

/**
 * Disassemble from a memory pointer given in params. The caller must ensure
 * memory access rights are present and bounds must be respected.
 * Params:
 * 	p = Disassembler parameters
 * Returns: Error code if non-zero
 */
int disasm_line(ref disasm_params_t p) {
	with (p) mcbufi = mnbufi = 0;

	if (p.abi == DisasmABI.Auto) {
		p.abi = DISASM_DEFAULT_ABI;
	}

	p.thisaddr = p.addrv;

	with (DisasmABI)
	switch (p.abi) {
	case x86: return disasm_x86(p);
	case x86_64: return disasm_x86_64(p);
	default: return DisasmError.NoABI;
	}
}

//
// Disasm internals/utilities
//
// NOTE: The include checking is not done in these functions for performance
//       reasons (pushing 3+ values into stack just a bit to be checked is
//       silly).
//

package:

void mcadd(ref disasm_params_t params, const(char) *str) {
	import utils.str : stradd;
	with (params)
	mcbufi = stradd(cast(char*)mcbuf, str, mcbufi, DISASM_BUF_SIZE);
}

void mcaddf(ref disasm_params_t params, const(char) *f, ...) {
	import core.stdc.stdarg : va_list, va_start;
	import core.stdc.stdio : vsnprintf;
	va_list va;
	va_start(va, f);
	char [DISASM_BUF_SIZE]buf;
	vsnprintf(cast(char*)buf, DISASM_BUF_SIZE, f, va);
	mcadd(params, cast(char*)buf);
}

void mnadd(ref disasm_params_t params, const(char) *str) {
	import utils.str : stradd;
	with (params)
	mnbufi = stradd(cast(char*)mnbuf, str, mnbufi, DISASM_BUF_SIZE);
}

void mnaddf(ref disasm_params_t params, const(char) *f, ...) {
	import core.stdc.stdarg : va_list, va_start;
	import core.stdc.stdio : vsnprintf;
	va_list va;
	va_start(va, f);
	char [DISASM_BUF_SIZE]buf;
	vsnprintf(cast(char*)buf, DISASM_BUF_SIZE, f, va);
	mnadd(params, cast(char*)buf);
}