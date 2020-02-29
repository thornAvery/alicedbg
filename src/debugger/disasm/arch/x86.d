/**
 * x86-specific disassembler.
 */
module debugger.disasm.arch.x86;

import debugger.disasm.core;
import debugger.disasm.formatter;
import utils.str;

extern (C):

package
struct x86_internals_t {
	union {
		int group1;
		int lock;
		int rep;
		int repne;
		int repe;
	}
	union {
		int group2;
		int segreg;
	}
	union {
		int group3;
		int pf_operand; /// 66H Operand prefix
	}
	union {
		int group4;
		int pf_address; /// 67H Address prefix
	}
}

/**
 * x86 disassembler.
 * Params: p = Disassembler parameters
 * Returns: DisasmError
 */
void disasm_x86(ref disasm_params_t p) {
	x86_internals_t internals;
	p.x86 = &internals;

	with (p.x86)
	group1 = group2 = group3 = group4 = 0;

L_CONTINUE:
	ubyte b = *p.addru8;
	++p.addrv;

	if (p.mode >= DisasmMode.File)
		disasm_push_x8(p, b);

	main: switch (b) {
	case 0x00:	// ADD R/M8, REG8
	case 0x01:	// ADD R/M32, REG32
	case 0x02:	// ADD REG8, R/M8
	case 0x03:	// ADD REG32, R/M32
		if (p.mode >= DisasmMode.File)
			disasm_push_str(p, "add");
		x86_modrm(p, X86_OP_WIDE(b), X86_OP_DIR(b));
		break;
	case 0x04:	// ADD AL, IMM8
		if (p.mode >= DisasmMode.File) {
			disasm_push_x8(p, *p.addru8);
			disasm_push_str(p, "add");
			disasm_push_reg(p, "al");
			disasm_push_imm(p, *p.addru8);
		}
		++p.addrv;
		break;
	case 0x05:	// ADD EAX, IMM32
		if (p.mode >= DisasmMode.File) {
			disasm_push_str(p, "add");
			disasm_push_reg(p, p.x86.pf_operand ? "ax" : "eax");
		}
		x86_vu32imm(p);
		break;
	case 0x06:	// PUSH ES
		if (p.mode >= DisasmMode.File) {
			disasm_push_str(p, "push");
			disasm_push_reg(p, "es");
		}
		break;
	case 0x07:	// POP ES
		if (p.mode >= DisasmMode.File) {
			disasm_push_str(p, "pop");
			disasm_push_reg(p, "es");
		}
		break;
	case 0x08:	// OR R/M8, REG8
	case 0x09:	// OR R/M32, REG32
	case 0x0A:	// OR REG8, R/M8
	case 0x0B:	// OR REG32, R/M32
		if (p.mode >= DisasmMode.File)
			disasm_push_str(p, "or");
		x86_modrm(p, X86_OP_WIDE(b), X86_OP_DIR(b));
		break;
	case 0x0C:	// OR AL, IMM8
		if (p.mode >= DisasmMode.File) {
			disasm_push_x8(p, *p.addru8);
			disasm_push_str(p, "or");
			disasm_push_reg(p, "al");
			disasm_push_imm(p, *p.addru8);
		}
		++p.addrv;
		break;
	case 0x0D:	// OR EAX, IMM32
		if (p.mode >= DisasmMode.File) {
			disasm_push_str(p, "or");
			disasm_push_reg(p, p.x86.pf_operand ? "ax" : "eax");
		}
		x86_vu32imm(p);
		break;
	case 0x0E:	// PUSH CS
		if (p.mode >= DisasmMode.File) {
			disasm_push_str(p, "push");
			disasm_push_reg(p, "cs");
		}
		break;
	case 0x0F:	// 2-byte opcode
		x86_0f(p);
		break;
	case 0x10:	// ADC R/M8, REG8
	case 0x11:	// ADC R/M32, REG32
	case 0x12:	// ADC REG8, R/M8
	case 0x13:	// ADC REG32, R/M32
		if (p.mode >= DisasmMode.File)
			disasm_push_str(p, "adc");
		x86_modrm(p, X86_OP_WIDE(b), X86_OP_DIR(b));
		break;
	case 0x14:	// ADC AL, IMM8
		if (p.mode >= DisasmMode.File) {
			disasm_push_x8(p, *p.addru8);
			disasm_push_str(p, "adc");
			disasm_push_reg(p, "al");
			disasm_push_imm(p, *p.addru8);
		}
		++p.addrv;
		break;
	case 0x15:	// ADC EAX, IMM32
		if (p.mode >= DisasmMode.File) {
			disasm_push_str(p, "adc");
			disasm_push_reg(p, p.x86.pf_operand ? "ax" : "eax");
		}
		x86_vu32imm(p);
		break;
	case 0x16:	// PUSH SS
		if (p.mode >= DisasmMode.File) {
			disasm_push_str(p, "push");
			disasm_push_reg(p, "ss");
		}
		break;
	case 0x17:	// POP SS
		if (p.mode >= DisasmMode.File) {
			disasm_push_str(p, "pop");
			disasm_push_reg(p, "ss");
		}
		break;
	case 0x18:	// SBB R/M8, REG8
	case 0x19:	// SBB R/M32, REG32
	case 0x1A:	// SBB REG8, R/M8
	case 0x1B:	// SBB REG32, R/M32
		if (p.mode >= DisasmMode.File)
			disasm_push_str(p, "sbb");
		x86_modrm(p, X86_OP_WIDE(b), X86_OP_DIR(b));
		break;
	case 0x1C:	// SBB AL, IMM8
		if (p.mode >= DisasmMode.File) {
			disasm_push_x8(p, *p.addru8);
			disasm_push_str(p, "sbb");
			disasm_push_reg(p, "al");
			disasm_push_imm(p, *p.addru8);
		}
		++p.addrv;
		break;
	case 0x1D:	// SBB EAX, IMM32
		if (p.mode >= DisasmMode.File) {
			disasm_push_str(p, "sbb");
			disasm_push_reg(p, p.x86.pf_operand ? "ax" : "eax");
		}
		x86_vu32imm(p);
		break;
	case 0x1E:	// PUSH DS
		if (p.mode >= DisasmMode.File) {
			disasm_push_str(p, "push");
			disasm_push_reg(p, "ds");
		}
		break;
	case 0x1F:	// POP DS
		if (p.mode >= DisasmMode.File) {
			disasm_push_str(p, "pop");
			disasm_push_reg(p, "ds");
		}
		break;
	case 0x20:	// AND R/M8, REG8
	case 0x21:	// AND R/M32, REG32
	case 0x22:	// AND REG8, R/M8
	case 0x23:	// AND REG32, R/M32
		if (p.mode >= DisasmMode.File)
			disasm_push_str(p, "and");
		x86_modrm(p, X86_OP_WIDE(b), X86_OP_DIR(b));
		break;
	case 0x24:	// AND AL, IMM8
		if (p.mode >= DisasmMode.File) {
			disasm_push_x8(p, *p.addru8);
			disasm_push_str(p, "and");
			disasm_push_reg(p, "al");
			disasm_push_imm(p, *p.addru8);
		}
		++p.addrv;
		break;
	case 0x25:	// AND EAX, IMM32
		if (p.mode >= DisasmMode.File) {
			disasm_push_str(p, "and");
			disasm_push_reg(p, p.x86.pf_operand ? "ax" : "eax");
		}
		x86_vu32imm(p);
		break;
	case 0x26:	// ES:
		if (p.x86.group2) {
			p.error = DisasmError.Illegal;
			break;
		}
		p.x86.segreg = PrefixReg.ES;
		goto L_CONTINUE;
	case 0x27:	// DAA
		if (p.mode >= DisasmMode.File)
			disasm_push_str(p, "daa");
		break;
	case 0x28:	// SUB R/M8, REG8
	case 0x29:	// SUB R/M32, REG32
	case 0x2A:	// SUB REG8, R/M8
	case 0x2B:	// SUB REG32, R/M32
		if (p.mode >= DisasmMode.File)
			disasm_push_str(p, "sub");
		x86_modrm(p, X86_OP_WIDE(b), X86_OP_DIR(b));
		break;
	case 0x2C:	// SUB AL, IMM8
		if (p.mode >= DisasmMode.File) {
			disasm_push_x8(p, *p.addru8);
			disasm_push_str(p, "sub");
			disasm_push_reg(p, "al");
			disasm_push_imm(p, *p.addru8);
		}
		++p.addrv;
		break;
	case 0x2D:	// SUB EAX, IMM32
		if (p.mode >= DisasmMode.File) {
			disasm_push_str(p, "sub");
			disasm_push_reg(p, p.x86.pf_operand ? "ax" : "eax");
		}
		x86_vu32imm(p);
		break;
	case 0x2E:	// CS:
		if (p.x86.group2) {
			p.error = DisasmError.Illegal;
			break;
		}
		p.x86.segreg = PrefixReg.CS;
		goto L_CONTINUE;
	case 0x2F:	// DAS
		if (p.mode >= DisasmMode.File)
			disasm_push_str(p, "das");
		break;
	case 0x30:	// XOR R/M8, REG8
	case 0x31:	// XOR R/M32, REG32
	case 0x32:	// XOR REG8, R/M8
	case 0x33:	// XOR REG32, R/M32
		if (p.mode >= DisasmMode.File)
			disasm_push_str(p, "xor");
		x86_modrm(p, X86_OP_WIDE(b), X86_OP_DIR(b));
		break;
	case 0x34:	// XOR AL, IMM8
		if (p.mode >= DisasmMode.File) {
			disasm_push_x8(p, *p.addru8);
			disasm_push_str(p, "xor");
			disasm_push_reg(p, "al");
			disasm_push_imm(p, *p.addru8);
		}
		++p.addrv;
		break;
	case 0x35:	// XOR EAX, IMM32
		if (p.mode >= DisasmMode.File) {
			disasm_push_str(p, "xor");
			disasm_push_reg(p, p.x86.pf_operand ? "ax" : "eax");
		}
		x86_vu32imm(p);
		break;
	case 0x36:	// SS:
		if (p.x86.group2) {
			p.error = DisasmError.Illegal;
			break;
		}
		p.x86.segreg = PrefixReg.SS;
		goto L_CONTINUE;
	case 0x37:	// AAA
		if (p.mode >= DisasmMode.File)
			disasm_push_str(p, "aaa");
		break;
	case 0x38:	// CMP R/M8, REG8
	case 0x39:	// CMP R/M32, REG32
	case 0x3A:	// CMP REG8, R/M8
	case 0x3B:	// CMP REG32, R/M32
		if (p.mode >= DisasmMode.File)
			disasm_push_str(p, "cmp");
		x86_modrm(p, X86_OP_WIDE(b), X86_OP_DIR(b));
		break;
	case 0x3C:	// CMP AL, IMM8
		if (p.mode >= DisasmMode.File) {
			disasm_push_x8(p, *p.addru8);
			disasm_push_str(p, "cmp");
			disasm_push_reg(p, "al");
			disasm_push_imm(p, *p.addru8);
		}
		++p.addrv;
		break;
	case 0x3D:	// CMP EAX, IMM32
		if (p.mode >= DisasmMode.File) {
			disasm_push_str(p, "cmp");
			disasm_push_reg(p, p.x86.pf_operand ? "ax" : "eax");
		}
		x86_vu32imm(p);
		break;
	case 0x3E:	// DS:
		if (p.x86.group2) {
			p.error = DisasmError.Illegal;
			break;
		}
		p.x86.segreg = PrefixReg.DS;
		goto L_CONTINUE;
	case 0x3F:	// AAS
		if (p.mode >= DisasmMode.File)
			disasm_push_str(p, "aas");
		break;
	case 0x40:	// INC EAX
		if (p.mode >= DisasmMode.File) {
			disasm_push_str(p, "inc");
			disasm_push_reg(p, p.x86.pf_operand ? "ax" : "eax");
		}
		break;
	case 0x41:	// INC ECX
		if (p.mode >= DisasmMode.File) {
			disasm_push_str(p, "inc");
			disasm_push_reg(p, p.x86.pf_operand ? "cx" : "ecx");
		}
		break;
	case 0x42:	// INC EDX
		if (p.mode >= DisasmMode.File) {
			disasm_push_str(p, "inc");
			disasm_push_reg(p, p.x86.pf_operand ? "dx" : "edx");
		}
		break;
	case 0x43:	// INC EBX
		if (p.mode >= DisasmMode.File) {
			disasm_push_str(p, "inc");
			disasm_push_reg(p, p.x86.pf_operand ? "bx" : "ebx");
		}
		break;
	case 0x44:	// INC ESP
		if (p.mode >= DisasmMode.File) {
			disasm_push_str(p, "inc");
			disasm_push_reg(p, p.x86.pf_operand ? "sp" : "esp");
		}
		break;
	case 0x45:	// INC EBP
		if (p.mode >= DisasmMode.File) {
			disasm_push_str(p, "inc");
			disasm_push_reg(p, p.x86.pf_operand ? "bp" : "ebp");
		}
		break;
	case 0x46:	// INC ESI
		if (p.mode >= DisasmMode.File) {
			disasm_push_str(p, "inc");
			disasm_push_reg(p, p.x86.pf_operand ? "si" : "esi");
		}
		break;
	case 0x47:	// INC EDI
		if (p.mode >= DisasmMode.File) {
			disasm_push_str(p, "inc");
			disasm_push_reg(p, p.x86.pf_operand ? "di" : "edi");
		}
		break;
	case 0x48:	// DEC EAX
		if (p.mode >= DisasmMode.File) {
			disasm_push_str(p, "dec");
			disasm_push_reg(p, p.x86.pf_operand ? "ax" : "eax");
		}
		break;
	case 0x49:	// DEC ECX
		if (p.mode >= DisasmMode.File) {
			disasm_push_str(p, "dec");
			disasm_push_reg(p, p.x86.pf_operand ? "cx" : "ecx");
		}
		break;
	case 0x4A:	// DEC EDX
		if (p.mode >= DisasmMode.File) {
			disasm_push_str(p, "dec");
			disasm_push_reg(p, p.x86.pf_operand ? "dx" : "edx");
		}
		break;
	case 0x4B:	// DEC EBX
		if (p.mode >= DisasmMode.File) {
			disasm_push_str(p, "dec");
			disasm_push_reg(p, p.x86.pf_operand ? "bx" : "ebx");
		}
		break;
	case 0x4C:	// DEC ESP
		if (p.mode >= DisasmMode.File) {
			disasm_push_str(p, "dec");
			disasm_push_reg(p, p.x86.pf_operand ? "sp" : "esp");
		}
		break;
	case 0x4D:	// DEC EBP
		if (p.mode >= DisasmMode.File) {
			disasm_push_str(p, "dec");
			disasm_push_reg(p, p.x86.pf_operand ? "bp" : "ebp");
		}
		break;
	case 0x4E:	// DEC ESI
		if (p.mode >= DisasmMode.File) {
			disasm_push_str(p, "dec");
			disasm_push_reg(p, p.x86.pf_operand ? "si" : "esi");
		}
		break;
	case 0x4F:	// DEC EDI
		if (p.mode >= DisasmMode.File) {
			disasm_push_str(p, "dec");
			disasm_push_reg(p, p.x86.pf_operand ? "di" : "edi");
		}
		break;
	case 0x50:	// PUSH EAX
		if (p.mode >= DisasmMode.File) {
			disasm_push_str(p, "push");
			disasm_push_reg(p, p.x86.pf_operand ? "ax" : "eax");
		}
		break;
	case 0x51:	// PUSH ECX
		if (p.mode >= DisasmMode.File) {
			disasm_push_str(p, "push");
			disasm_push_reg(p, p.x86.pf_operand ? "ax" : "ecx");
		}
		break;
	case 0x52:	// PUSH EDX
		if (p.mode >= DisasmMode.File) {
			disasm_push_str(p, "push");
			disasm_push_reg(p, p.x86.pf_operand ? "dx" : "edx");
		}
		break;
	case 0x53:	// PUSH EBX
		if (p.mode >= DisasmMode.File) {
			disasm_push_str(p, "push");
			disasm_push_reg(p, p.x86.pf_operand ? "bx" : "ebx");
		}
		break;
	case 0x54:	// PUSH ESP
		if (p.mode >= DisasmMode.File) {
			disasm_push_str(p, "push");
			disasm_push_reg(p, p.x86.pf_operand ? "sp" : "esp");
		}
		break;
	case 0x55:	// PUSH EBP
		if (p.mode >= DisasmMode.File) {
			disasm_push_str(p, "push");
			disasm_push_reg(p, p.x86.pf_operand ? "bp" : "ebp");
		}
		break;
	case 0x56:	// PUSH ESI
		if (p.mode >= DisasmMode.File) {
			disasm_push_str(p, "push");
			disasm_push_reg(p, p.x86.pf_operand ? "si" : "esi");
		}
		break;
	case 0x57:	// PUSH EDI
		if (p.mode >= DisasmMode.File) {
			disasm_push_str(p, "push");
			disasm_push_reg(p, p.x86.pf_operand ? "di" : "edi");
		}
		break;
	case 0x58:	// POP EAX
		if (p.mode >= DisasmMode.File) {
			disasm_push_str(p, "pop");
			disasm_push_reg(p, p.x86.pf_operand ? "ax" : "eax");
		}
		break;
	case 0x59:	// POP ECX
		if (p.mode >= DisasmMode.File) {
			disasm_push_str(p, "pop");
			disasm_push_reg(p, p.x86.pf_operand ? "cx" : "ecx");
		}
		break;
	case 0x5A:	// POP EDX
		if (p.mode >= DisasmMode.File) {
			disasm_push_str(p, "pop");
			disasm_push_reg(p, p.x86.pf_operand ? "dx" : "edx");
		}
		break;
	case 0x5B:	// POP EBX
		if (p.mode >= DisasmMode.File) {
			disasm_push_str(p, "pop");
			disasm_push_reg(p, p.x86.pf_operand ? "bx" : "ebx");
		}
		break;
	case 0x5C:	// POP ESP
		if (p.mode >= DisasmMode.File) {
			disasm_push_str(p, "pop");
			disasm_push_reg(p, p.x86.pf_operand ? "sp" : "esp");
		}
		break;
	case 0x5D:	// POP EBP
		if (p.mode >= DisasmMode.File) {
			disasm_push_str(p, "pop");
			disasm_push_reg(p, p.x86.pf_operand ? "bp" : "ebp");
		}
		break;
	case 0x5E:	// POP ESI
		if (p.mode >= DisasmMode.File) {
			disasm_push_str(p, "pop");
			disasm_push_reg(p, p.x86.pf_operand ? "si" : "esi");
		}
		break;
	case 0x5F:	// POP EDI
		if (p.mode >= DisasmMode.File) {
			disasm_push_str(p, "pop");
			disasm_push_reg(p, p.x86.pf_operand ? "di" : "edi");
		}
		break;
	case 0x60:	// PUSHAD
		if (p.mode >= DisasmMode.File)
			disasm_push_str(p, p.x86.pf_operand ? "pusha" : "pushad");
		break;
	case 0x61:	// POPAD
		if (p.mode >= DisasmMode.File)
			disasm_push_str(p, p.x86.pf_operand ? "popa" : "popad");
		break;
	case 0x62:	// BOUND REG32, MEM&MEM32
		if (p.mode >= DisasmMode.File)
			disasm_push_str(p, "bound");
		ubyte modrm = *p.addru8;
		if ((modrm & RM_MOD) == RM_MOD_11)
			disasm_err(p);
		else
			x86_modrm(p, X86_WIDTH_WIDE, X86_DIR_REG);
		break;
	case 0x63:	// ARPL REG16, R/M16
		if (p.mode >= DisasmMode.File)
			disasm_push_str(p, "arpl");
		x86_modrm(p, X86_WIDTH_NONE, X86_DIR_REG);
		break;
	case 0x64:	// FS:
		if (p.x86.group2) {
			p.error = DisasmError.Illegal;
			break;
		}
		p.x86.segreg = PrefixReg.FS;
		goto L_CONTINUE;
	case 0x65:	// GS:
		if (p.x86.group2) {
			p.error = DisasmError.Illegal;
			break;
		}
		p.x86.segreg = PrefixReg.GS;
		goto L_CONTINUE;
	case 0x66:	// PREFIX: OPERAND SIZE
		if (p.x86.group3) {
			p.error = DisasmError.Illegal;
			break;
		}
		p.x86.pf_operand = 0x66;
		goto L_CONTINUE;
	case 0x67:	// PREFIX: ADDRESS SIZE
		if (p.x86.group4) {
			p.error = DisasmError.Illegal;
			break;
		}
		p.x86.pf_address = true;
		goto L_CONTINUE;
	case 0x68:	// PUSH IMM32
		if (p.mode >= DisasmMode.File) {
			disasm_push_x32(p, *p.addru32);
			disasm_push_str(p, "push");
			disasm_push_imm(p, *p.addru32);
		}
		p.addrv += 4;
		break;
	case 0x69:	// IMUL REG32, R/M32, IMM32
		if (p.mode >= DisasmMode.File)
			disasm_push_str(p, "imul");
		x86_modrm(p, X86_WIDTH_WIDE, X86_DIR_REG);
		if (p.mode >= DisasmMode.File) {
			disasm_push_x32(p, *p.addru32);
			disasm_push_imm(p, *p.addru32);
		}
		p.addrv += 4;
		break;
	case 0x6A:	// PUSH IMM8
		if (p.mode >= DisasmMode.File) {
			disasm_push_x8(p, *p.addru8);
			disasm_push_str(p, "push");
			disasm_push_imm(p, *p.addru8);
		}
		++p.addrv;
		break;
	case 0x6B:	// IMUL REG32, R/M32, IMM8
		if (p.mode >= DisasmMode.File)
			disasm_push_str(p, "imul");
		x86_modrm(p, X86_WIDTH_WIDE, X86_DIR_REG);
		if (p.mode >= DisasmMode.File) {
			disasm_push_x8(p, *p.addru8);
			disasm_push_imm(p, *p.addru8);
		}
		++p.addrv;
		break;
	case 0x6C:	// INSB
		if (p.mode >= DisasmMode.File)
			disasm_push_str(p, "insb");
		break;
	case 0x6D:	// INSD
		if (p.mode >= DisasmMode.File)
			disasm_push_str(p, "insd");
		break;
	case 0x6E:	// OUTSB
		if (p.mode >= DisasmMode.File)
			disasm_push_str(p, "outsb");
		break;
	case 0x6F:	// OUTSD
		if (p.mode >= DisasmMode.File)
			disasm_push_str(p, "outsd");
		break;
	case 0x70:	// JO
		if (p.mode >= DisasmMode.File) {
			disasm_push_x8(p, *p.addru8);
			disasm_push_str(p, "jo");
			disasm_push_imm(p, *p.addri8);
		}
		++p.addrv;
		break;
	case 0x71:	// JNO
		if (p.mode >= DisasmMode.File) {
			disasm_push_x8(p, *p.addru8);
			disasm_push_str(p, "jno");
			disasm_push_imm(p, *p.addri8);
		}
		++p.addrv;
		break;
	case 0x72:	// JB
		if (p.mode >= DisasmMode.File) {
			disasm_push_x8(p, *p.addru8);
			disasm_push_str(p, "jb");
			disasm_push_imm(p, *p.addri8);
		}
		++p.addrv;
		break;
	case 0x73:	// JNB
		if (p.mode >= DisasmMode.File) {
			disasm_push_x8(p, *p.addru8);
			disasm_push_str(p, "jnb");
			disasm_push_imm(p, *p.addri8);
		}
		++p.addrv;
		break;
	case 0x74:	// JZ
		if (p.mode >= DisasmMode.File) {
			disasm_push_x8(p, *p.addru8);
			disasm_push_str(p, "jz");
			disasm_push_imm(p, *p.addri8);
		}
		++p.addrv;
		break;
	case 0x75:	// JNZ
		if (p.mode >= DisasmMode.File) {
			disasm_push_x8(p, *p.addru8);
			disasm_push_str(p, "jnz");
			disasm_push_imm(p, *p.addri8);
		}
		++p.addrv;
		break;
	case 0x76:	// JBE
		if (p.mode >= DisasmMode.File) {
			disasm_push_x8(p, *p.addru8);
			disasm_push_str(p, "jbe");
			disasm_push_imm(p, *p.addri8);
		}
		++p.addrv;
		break;
	case 0x77:	// JNBE
		if (p.mode >= DisasmMode.File) {
			disasm_push_x8(p, *p.addru8);
			disasm_push_str(p, "jnbe");
			disasm_push_imm(p, *p.addri8);
		}
		++p.addrv;
		break;
	case 0x78:	// JS
		if (p.mode >= DisasmMode.File) {
			disasm_push_x8(p, *p.addru8);
			disasm_push_str(p, "js");
			disasm_push_imm(p, *p.addri8);
		}
		++p.addrv;
		break;
	case 0x79:	// JNS
		if (p.mode >= DisasmMode.File) {
			disasm_push_x8(p, *p.addru8);
			disasm_push_str(p, "jns");
			disasm_push_imm(p, *p.addri8);
		}
		++p.addrv;
		break;
	case 0x7A:	// JP
		if (p.mode >= DisasmMode.File) {
			disasm_push_x8(p, *p.addru8);
			disasm_push_str(p, "jp");
			disasm_push_imm(p, *p.addri8);
		}
		++p.addrv;
		break;
	case 0x7B:	// JNP
		if (p.mode >= DisasmMode.File) {
			disasm_push_x8(p, *p.addru8);
			disasm_push_str(p, "jnp");
			disasm_push_imm(p, *p.addri8);
		}
		++p.addrv;
		break;
	case 0x7C:	// JL
		if (p.mode >= DisasmMode.File) {
			disasm_push_x8(p, *p.addru8);
			disasm_push_str(p, "jl");
			disasm_push_imm(p, *p.addri8);
		}
		++p.addrv;
		break;
	case 0x7D:	// JNL
		if (p.mode >= DisasmMode.File) {
			disasm_push_x8(p, *p.addru8);
			disasm_push_str(p, "jnl");
			disasm_push_imm(p, *p.addri8);
		}
		++p.addrv;
		break;
	case 0x7E:	// JLE
		if (p.mode >= DisasmMode.File) {
			disasm_push_x8(p, *p.addru8);
			disasm_push_str(p, "jle");
			disasm_push_imm(p, *p.addri8);
		}
		++p.addrv;
		break;
	case 0x7F:	// JNLE
		if (p.mode >= DisasmMode.File) {
			disasm_push_x8(p, *p.addru8);
			disasm_push_str(p, "jnle");
			disasm_push_imm(p, *p.addri8);
		}
		++p.addrv;
		break;
	case 0x81:	// GRP1 REG32, IMM32
		ubyte modrm = *p.addru8;
		++p.addrv;
		if (p.mode >= DisasmMode.File) {
			const(char) *f = void;
			switch (modrm & RM_REG) {
			case RM_REG_000: f = "add"; break;
			case RM_REG_001: f = "or";  break;
			case RM_REG_010: f = "adc"; break;
			case RM_REG_011: f = "sbb"; break;
			case RM_REG_100: f = "and"; break;
			case RM_REG_101: f = "sub"; break;
			case RM_REG_110: f = "xor"; break;
			case RM_REG_111: f = "cmp"; break;
			default: // impossible
			}
			disasm_push_x8(p, modrm);
			disasm_push_str(p, f);
			disasm_push_reg(p, x86_modrm_reg(p, modrm << 3,
				p.x86.pf_operand ? X86_WIDTH_NONE : X86_WIDTH_WIDE));
		}
		x86_vu32imm(p);
		break;
	case 0x80:	// GRP1 REG8, IMM8
	case 0x82:	// GRP1 REG8, IMM8
	case 0x83:	// GRP1 REG32, IMM8
		ubyte modrm = *p.addru8;
		++p.addrv;
		if (p.mode >= DisasmMode.File) {
			const(char) *f = void;
			switch (modrm & RM_RM) {
			case RM_RM_000: f = "add"; break;
			case RM_RM_001: f = "or";  break;
			case RM_RM_010: f = "adc"; break;
			case RM_RM_011: f = "sbb"; break;
			case RM_RM_100: f = "and"; break;
			case RM_RM_101: f = "sub"; break;
			case RM_RM_110: f = "xor"; break;
			case RM_RM_111: f = "cmp"; break;
			default: // impossible
			}
			disasm_push_x8(p, modrm);
			disasm_push_x8(p, *p.addru8);
			disasm_push_str(p, f);
			disasm_push_reg(p, x86_modrm_reg(p, modrm, X86_OP_WIDE(b)));
			disasm_push_imm(p, *p.addru8);
		}
		++p.addrv;
		break;
	case 0x84:	// TEST R/M8, REG8
	case 0x85:	// TEST R/M32, REG32
		if (p.mode >= DisasmMode.File)
			disasm_push_str(p, "test");
		x86_modrm(p, X86_OP_WIDE(b), X86_DIR_MEM);
		break;
	case 0x86:	// XCHG R/M8, REG8
	case 0x87:	// XCHG R/M32, REG32
		if (p.mode >= DisasmMode.File)
			disasm_push_str(p, "xchg");
		x86_modrm(p, X86_OP_WIDE(b), X86_DIR_MEM);
		break;
	case 0x88:	// MOV R/M8, REG8
	case 0x89:	// MOV R/M32, REG32
	case 0x8A:	// MOV REG8, R/M8
	case 0x8B:	// MOV REG32, R/M32
		if (p.mode >= DisasmMode.File)
			disasm_push_str(p, "mov");
		x86_modrm(p, X86_OP_WIDE(b), X86_OP_DIR(b));
		break;
	case 0x8C:	// MOV REG16, SEGREG16
	case 0x8E:	// MOV SEGREG16, REG16
		ubyte modrm = *p.addru8;
		++p.addrv;
		const(char) *seg = void;
		switch (modrm & RM_REG) {
		case RM_REG_000: seg = "es"; break;
		case RM_REG_001: seg = "cs"; break;
		case RM_REG_010: seg = "ss"; break;
		case RM_REG_011: seg = "ds"; break;
		case RM_REG_100: seg = "fs"; break;
		case RM_REG_101: seg = "gs"; break;
		default: disasm_err(p); break main;
		}
		if (p.mode >= DisasmMode.File) {
			p.x86.pf_operand = 1;
			disasm_push_x8(p, modrm);
			disasm_push_str(p, "mov");
			const(char) *reg = x86_modrm_reg(p, modrm, X86_WIDTH_NONE);
			if (X86_OP_DIR(b)) {
				disasm_push_reg(p, seg);
				disasm_push_reg(p, reg);
			} else {
				disasm_push_reg(p, reg);
				disasm_push_reg(p, seg);
			}
		}
		break;
	case 0x8D:	// LEA REG32, MEM32
		if (p.mode >= DisasmMode.File)
			disasm_push_str(p, "lea");
		x86_modrm(p, X86_WIDTH_WIDE, X86_DIR_REG);
		break;
	case 0x8F:	// GRP1A POP REG32
		ubyte modrm = *p.addru8;
		++p.addrv;
		if (modrm & RM_RM) { // Invalid
			disasm_err(p);
			break;
		}
		if (p.mode >= DisasmMode.File) {
			disasm_push_x8(p, modrm);
			disasm_push_str(p, "pop");
			disasm_push_reg(p, x86_modrm_reg(p, modrm, X86_WIDTH_WIDE));
		}
		break;
	case 0x90:	// NOP
		if (p.mode >= DisasmMode.File)
			disasm_push_str(p, "nop");
		break;
	case 0x91:	// XCHG ECX, EAX
		if (p.mode >= DisasmMode.File) {
			disasm_push_str(p, "xchg");
			disasm_push_reg(p, p.x86.pf_operand ? "cx" : "ecx");
			disasm_push_reg(p, p.x86.pf_operand ? "ax" : "eax");
		}
		break;
	case 0x92:	// XCHG EDX, EAX
		if (p.mode >= DisasmMode.File) {
			disasm_push_str(p, "xchg");
			disasm_push_reg(p, p.x86.pf_operand ? "dx" : "edx");
			disasm_push_reg(p, p.x86.pf_operand ? "ax" : "eax");
		}
		break;
	case 0x93:	// XCHG EBX, EAX
		if (p.mode >= DisasmMode.File) {
			disasm_push_str(p, "xchg");
			disasm_push_reg(p, p.x86.pf_operand ? "bx" : "ebx");
			disasm_push_reg(p, p.x86.pf_operand ? "ax" : "eax");
		}
		break;
	case 0x94:	// XCHG ESP, EAX
		if (p.mode >= DisasmMode.File) {
			disasm_push_str(p, "xchg");
			disasm_push_reg(p, p.x86.pf_operand ? "sp" : "esp");
			disasm_push_reg(p, p.x86.pf_operand ? "ax" : "eax");
		}
		break;
	case 0x95:	// XCHG EBP, EAX
		if (p.mode >= DisasmMode.File) {
			disasm_push_str(p, "xchg");
			disasm_push_reg(p, p.x86.pf_operand ? "bp" : "ebp");
			disasm_push_reg(p, p.x86.pf_operand ? "ax" : "eax");
		}
		break;
	case 0x96:	// XCHG ESI, EAX
		if (p.mode >= DisasmMode.File) {
			disasm_push_str(p, "xchg");
			disasm_push_reg(p, p.x86.pf_operand ? "si" : "esi");
			disasm_push_reg(p, p.x86.pf_operand ? "ax" : "eax");
		}
		break;
	case 0x97:	// XCHG EDI, EAX
		if (p.mode >= DisasmMode.File) {
			disasm_push_str(p, "xchg");
			disasm_push_reg(p, p.x86.pf_operand ? "di" : "edi");
			disasm_push_reg(p, p.x86.pf_operand ? "ax" : "eax");
		}
		break;
	case 0x98:	// CBW
		if (p.mode >= DisasmMode.File)
			disasm_push_str(p, "cbw");
		break;
	case 0x99:	// CBD
		if (p.mode >= DisasmMode.File)
			disasm_push_str(p, "cbd");
		break;
	case 0x9A:	// CALL (FAR)
		if (p.mode >= DisasmMode.File) {
			disasm_push_x32(p, *p.addru32);
			disasm_push_str(p, "call");
			disasm_push_imm(p, *p.addri32);
		}
		p.addrv += 4;
		break;
	case 0x9B:	// WAIT/FWAIT
		if (p.mode >= DisasmMode.File)
			disasm_push_str(p, "wait");
		break;
	case 0x9C:	// PUSHFD
		if (p.mode >= DisasmMode.File)
			disasm_push_str(p, "pushf");
		break;
	case 0x9D:	// POPF/D/Q
		if (p.mode >= DisasmMode.File)
			disasm_push_str(p, "popf");
		break;
	case 0x9E:	// SAHF
		if (p.mode >= DisasmMode.File)
			disasm_push_str(p, "sahf");
		break;
	case 0x9F:	// LAHF
		if (p.mode >= DisasmMode.File)
			disasm_push_str(p, "lahf");
		break;
	case 0xA0:	// MOV AL, MEM8
		if (p.mode >= DisasmMode.File) {
			disasm_push_x32(p, *p.addru32);
			disasm_push_str(p, "mov");
			disasm_push_reg(p, "al");
			disasm_push_mem(p, *p.addri32);
		}
		p.addrv += 4;
		break;
	case 0xA1:	// MOV EAX, MEM32
		if (p.mode >= DisasmMode.File) {
			disasm_push_x32(p, *p.addru32);
			disasm_push_str(p, "mov");
			disasm_push_reg(p, "eax");
			disasm_push_mem(p, *p.addri32);
		}
		p.addrv += 4;
		break;
	case 0xA2:	// MOV MEM8, AL
		if (p.mode >= DisasmMode.File) {
			disasm_push_x32(p, *p.addru32);
			disasm_push_str(p, "mov");
			disasm_push_mem(p, *p.addri32);
			disasm_push_reg(p, "al");
		}
		p.addrv += 4;
		break;
	case 0xA3:	// MOV MEM32, EAX
		if (p.mode >= DisasmMode.File) {
			disasm_push_x32(p, *p.addru32);
			disasm_push_str(p, "mov");
			disasm_push_mem(p, *p.addri32);
			disasm_push_reg(p, "eax");
		}
		p.addrv += 4;
		break;
	case 0xA4:	// MOVSB ES:EDI, DS:ESI
		if (p.mode >= DisasmMode.File) {
			disasm_push_str(p, "movsb");
			disasm_push_segreg(p, "es:", "edi");
			disasm_push_segreg(p, "ds:", "esi");
		}
		break;
	case 0xA5:	// MOVSD ES:EDI, DS:ESI
		if (p.mode >= DisasmMode.File) {
			disasm_push_str(p, "movsd");
			disasm_push_segreg(p, "es:", "edi");
			disasm_push_segreg(p, "ds:", "esi");
		}
		break;
	case 0xA6:	// MOVSB DS:ESI, ES:EDI
		if (p.mode >= DisasmMode.File) {
			disasm_push_str(p, "movsb");
			disasm_push_segreg(p, "ds:", "esi");
			disasm_push_segreg(p, "es:", "edi");
		}
		break;
	case 0xA7:	// MOVSD DS:ESI, ES:EDI
		if (p.mode >= DisasmMode.File) {
			disasm_push_str(p, "movsd");
			disasm_push_segreg(p, "ds:", "esi");
			disasm_push_segreg(p, "es:", "edi");
		}
		break;
	case 0xA8:	// TEST AL, IMM8
		if (p.mode >= DisasmMode.File) {
			disasm_push_x8(p, *p.addru8);
			disasm_push_str(p, "test");
			disasm_push_reg(p, "al");
			disasm_push_imm(p, *p.addru8);
		}
		++p.addrv;
		break;
	case 0xA9:	// TEST EAX, IMM32
		if (p.mode >= DisasmMode.File) {
			disasm_push_str(p, "test");
			disasm_push_reg(p, "eax");
		}
		x86_vu32imm(p);
		break;
	case 0xAA:	// STOSB ES:EDI, AL
		if (p.mode >= DisasmMode.File) {
			disasm_push_str(p, "stosb");
			disasm_push_segreg(p, "es:", "edi");
			disasm_push_reg(p, "al");
		}
		break;
	case 0xAB:	// STOSD ES:EDI, EAX
		if (p.mode >= DisasmMode.File) {
			disasm_push_str(p, "stosd");
			disasm_push_segreg(p, "es:", "edi");
			disasm_push_reg(p, "eax");
		}
		break;
	case 0xAC:	// LODSB AL, DS:ESI
		if (p.mode >= DisasmMode.File) {
			disasm_push_str(p, "lodsb");
			disasm_push_reg(p, "al");
			disasm_push_segreg(p, "ds:", "esi");
		}
		break;
	case 0xAD:	// LODSD EAX, DS:ESI
		if (p.mode >= DisasmMode.File) {
			disasm_push_str(p, "lodsd");
			disasm_push_reg(p, "eax");
			disasm_push_segreg(p, "ds:", "esi");
		}
		break;
	case 0xAE:	// SCASB AL, ES:EDI
		if (p.mode >= DisasmMode.File) {
			disasm_push_str(p, "scasb");
			disasm_push_reg(p, "al");
			disasm_push_segreg(p, "es:", "edi");
		}
		break;
	case 0xAF:	// SCASD EAX, ES:EDI
		if (p.mode >= DisasmMode.File) {
			disasm_push_str(p, "scasd");
			disasm_push_reg(p, "eax");
			disasm_push_segreg(p, "es:", "edi");
		}
		break;
	case 0xB0:	// MOV AL, IMM8
		if (p.mode >= DisasmMode.File) {
			disasm_push_x8(p, *p.addru8);
			disasm_push_str(p, "mov");
			disasm_push_reg(p, "al");
			disasm_push_imm(p, *p.addru8);
		}
		++p.addrv;
		break;
	case 0xB1:	// MOV DL, IMM8
		if (p.mode >= DisasmMode.File) {
			disasm_push_x8(p, *p.addru8);
			disasm_push_str(p, "mov");
			disasm_push_reg(p, "dl");
			disasm_push_imm(p, *p.addru8);
		}
		++p.addrv;
		break;
	case 0xB2:	// MOV CL, IMM8
		if (p.mode >= DisasmMode.File) {
			disasm_push_x8(p, *p.addru8);
			disasm_push_str(p, "mov");
			disasm_push_reg(p, "cl");
			disasm_push_imm(p, *p.addru8);
		}
		++p.addrv;
		break;
	case 0xB3:	// MOV BL, IMM8
		if (p.mode >= DisasmMode.File) {
			disasm_push_x8(p, *p.addru8);
			disasm_push_str(p, "mov");
			disasm_push_reg(p, "bl");
			disasm_push_imm(p, *p.addru8);
		}
		++p.addrv;
		break;
	case 0xB4:	// MOV AH, IMM8
		if (p.mode >= DisasmMode.File) {
			disasm_push_x8(p, *p.addru8);
			disasm_push_str(p, "mov");
			disasm_push_reg(p, "ah");
			disasm_push_imm(p, *p.addru8);
		}
		++p.addrv;
		break;
	case 0xB5:	// MOV CH, IMM8
		if (p.mode >= DisasmMode.File) {
			disasm_push_x8(p, *p.addru8);
			disasm_push_str(p, "mov");
			disasm_push_reg(p, "ch");
			disasm_push_imm(p, *p.addru8);
		}
		++p.addrv;
		break;
	case 0xB6:	// MOV DH, IMM8
		if (p.mode >= DisasmMode.File) {
			disasm_push_x8(p, *p.addru8);
			disasm_push_str(p, "mov");
			disasm_push_reg(p, "dh");
			disasm_push_imm(p, *p.addru8);
		}
		++p.addrv;
		break;
	case 0xB7:	// MOV BH, IMM8
		if (p.mode >= DisasmMode.File) {
			disasm_push_x8(p, *p.addru8);
			disasm_push_str(p, "mov");
			disasm_push_reg(p, "bh");
			disasm_push_imm(p, *p.addru8);
		}
		++p.addrv;
		break;
	case 0xB8:	// MOV EAX, IMM32
		if (p.mode >= DisasmMode.File) {
			disasm_push_str(p, "mov");
			disasm_push_reg(p, p.x86.pf_operand ? "ax" : "eax");
		}
		x86_vu32imm(p);
		break;
	case 0xB9:	// MOV ECX, IMM32
		if (p.mode >= DisasmMode.File) {
			disasm_push_str(p, "mov");
			disasm_push_reg(p, p.x86.pf_operand ? "cx" : "ecx");
		}
		x86_vu32imm(p);
		break;
	case 0xBA:	// MOV EDX, IMM32
		if (p.mode >= DisasmMode.File) {
			disasm_push_str(p, "mov");
			disasm_push_reg(p, p.x86.pf_operand ? "dx" : "edx");
		}
		x86_vu32imm(p);
		break;
	case 0xBB:	// MOV EBX, IMM32
		if (p.mode >= DisasmMode.File) {
			disasm_push_str(p, "mov");
			disasm_push_reg(p, p.x86.pf_operand ? "bx" : "ebx");
		}
		x86_vu32imm(p);
		break;
	case 0xBC:	// MOV ESP, IMM32
		if (p.mode >= DisasmMode.File) {
			disasm_push_str(p, "mov");
			disasm_push_reg(p, p.x86.pf_operand ? "sp" : "esp");
		}
		x86_vu32imm(p);
		break;
	case 0xBD:	// MOV EBP, IMM32
		if (p.mode >= DisasmMode.File) {
			disasm_push_str(p, "mov");
			disasm_push_reg(p, p.x86.pf_operand ? "bp" : "ebp");
		}
		x86_vu32imm(p);
		break;
	case 0xBE:	// MOV ESI, IMM32
		if (p.mode >= DisasmMode.File) {
			disasm_push_str(p, "mov");
			disasm_push_reg(p, p.x86.pf_operand ? "si" : "esi");
		}
		x86_vu32imm(p);
		break;
	case 0xBF:	// MOV EDI, IMM32
		if (p.mode >= DisasmMode.File) {
			disasm_push_str(p, "mov");
			disasm_push_reg(p, p.x86.pf_operand ? "di" : "edi");
		}
		x86_vu32imm(p);
		break;
	case 0xC0:	// GRP2 R/M8, IMM8
	case 0xC1:	// GRP2 R/M32, IMM8
		ubyte modrm = *p.addru8;
		++p.addrv;
		const(char) *r = void;
		switch (modrm & RM_REG) {
		case RM_REG_000: r = "ror"; break;
		case RM_REG_001: r = "rcl"; break;
		case RM_REG_010: r = "rcr"; break;
		case RM_REG_011: r = "shl"; break;
		case RM_REG_100: r = "shr"; break;
		case RM_REG_101: r = "ror"; break;
		case RM_REG_111: r = "sar"; break;
		default: disasm_err(p); break main;
		}
		if (p.mode >= DisasmMode.File)
			disasm_push_reg(p, r);
		x86_modrm_rm(p, modrm, X86_OP_WIDE(b));
		if (p.mode >= DisasmMode.File) {
			disasm_push_x8(p, *p.addru8);
			disasm_push_imm(p, *p.addru8);
		}
		break;
	case 0xC2:	// RET IMM16
		if (p.mode >= DisasmMode.File) {
			disasm_push_x16(p, *p.addru16);
			disasm_push_str(p, "ret");
			disasm_push_imm(p, *p.addri16);
		}
		p.addrv += 2;
		break;
	case 0xC3:	// RET
		if (p.mode >= DisasmMode.File)
			disasm_push_str(p, "ret");
		break;
	case 0xC4:	// LES REG32, MEM32
		if (p.mode >= DisasmMode.File)
			disasm_push_str(p, "les");
		x86_modrm(p, X86_WIDTH_NONE, X86_DIR_REG);
		break;
	case 0xC5:	// LDS REG32, MEM32
		if (p.mode >= DisasmMode.File)
			disasm_push_str(p, "lds");
		x86_modrm(p, X86_WIDTH_NONE, X86_DIR_REG);
		break;
	case 0xC6:	// GRP11(1A) - MOV MEM8, IMM8
		ubyte modrm = *p.addru8;
		++p.addrv;
		if (modrm & RM_REG) {
			disasm_err(p);
			break main;
		}
		if (p.mode >= DisasmMode.File)
			disasm_push_str(p, "mov");
		x86_modrm_rm(p, modrm, X86_WIDTH_NONE);
		if (p.mode >= DisasmMode.File) {
			disasm_push_x8(p, *p.addru8);
			disasm_push_imm(p, *p.addru8);
		}
		++p.addrv;
		break;
	case 0xC7:	// GRP11(1A) - MOV MEM32, IMM32
		ubyte modrm = *p.addru8;
		++p.addrv;
		if (modrm & RM_REG) {
			disasm_err(p);
			break main;
		}
		if (p.mode >= DisasmMode.File)
			disasm_push_str(p, "mov");
		x86_modrm_rm(p, modrm, X86_WIDTH_WIDE);
		x86_vu32imm(p);
		break;
	case 0xC8:	// ENTER IMM16, IMM8
		if (p.mode >= DisasmMode.File) {
			ushort v1 = *p.addru16;
			ubyte v2 = *(p.addru8 + 2);
			disasm_push_x16(p, v1);
			disasm_push_x8(p, v2);
			disasm_push_str(p, "enter");
			disasm_push_imm(p, v1);
			disasm_push_imm(p, v2);
		}
		p.addrv += 3;
		break;
	case 0xC9:	// LEAVE
		if (p.mode >= DisasmMode.File)
			disasm_push_str(p, "leave");
		break;
	case 0xCA:	// RET (far) IMM16
		if (p.mode >= DisasmMode.File) {
			disasm_push_x16(p, *p.addru16);
			disasm_push_str(p, "ret");
			disasm_push_imm(p, *p.addri16);
		}
		p.addrv += 2;
		break;
	case 0xCB:	// RET (far)
		if (p.mode >= DisasmMode.File)
			disasm_push_str(p, "ret");
		p.addrv += 2;
		break;
	case 0xCC:	// INT 3
		if (p.mode >= DisasmMode.File)
			disasm_push_str(p, "int3");
		break;
	case 0xCD:	// INT IMM8
		if (p.mode >= DisasmMode.File) {
			disasm_push_x8(p, *p.addru8);
			disasm_push_str(p, "int");
			disasm_push_imm(p, *p.addru8);
		}
		++p.addrv;
		break;
	case 0xCE:	// INTO
		if (p.mode >= DisasmMode.File)
			disasm_push_str(p, "into");
		break;
	case 0xCF:	// IRET
		if (p.mode >= DisasmMode.File)
			disasm_push_str(p, "iret");
		break;
	case 0xD0:	// GRP2 R/M8, 1
	case 0xD1:	// GRP2 R/M32, 1
	case 0xD2:	// GRP2 R/M8, CL
	case 0xD3:	// GRP2 R/M32, CL
		ubyte modrm = *p.addru8;
		++p.addrv;
		const(char) *m = void;
		switch (modrm & RM_REG) {
		case RM_REG_000: m = "rol"; break;
		case RM_REG_001: m = "ror"; break;
		case RM_REG_010: m = "rcl"; break;
		case RM_REG_011: m = "rcr"; break;
		case RM_REG_100: m = "shl"; break;
		case RM_REG_101: m = "shr"; break;
		case RM_REG_111: m = "rol"; break;
		default: disasm_err(p); break main;
		}
		if (p.mode >= DisasmMode.File)
			disasm_push_str(p, m);

		x86_modrm_rm(p, modrm, X86_OP_WIDE(b));

		if (p.mode >= DisasmMode.File) {
			if (b >= 0xD2)
				disasm_push_reg(p, "cl");
			else
				disasm_push_imm(p, 1);
		}
		break;
	case 0xD4:	// AAM IMM8
		if (p.mode >= DisasmMode.File) {
			disasm_push_x8(p, *p.addru8);
			disasm_push_str(p, "amm");
			disasm_push_imm(p, *p.addru8);
		}
		++p.addrv;
		break;
	case 0xD5:	// AAD IMM8
		if (p.mode >= DisasmMode.File) {
			disasm_push_x8(p, *p.addru8);
			disasm_push_str(p, "aad");
			disasm_push_imm(p, *p.addru8);
		}
		++p.addrv;
		break;
	case 0xD7:	// XLAT
		if (p.mode >= DisasmMode.File)
			disasm_push_str(p, "xlat");
		break;
	case 0xD8:	// ESCAPE D8
		ubyte modrm = *p.addru8;
		++p.addrv;
		if (p.mode >= DisasmMode.File)
			disasm_push_x8(p, modrm);
		const(char) *m = void, seg = void;
		if (modrm > 0xBF) { // operand is FP
			if (p.mode >= DisasmMode.File) {
				ubyte sti = modrm & 0xF; // ST index
				switch (modrm & 0xF0) {
				case 0xC0: // FADD/FMUL
					if (sti < 0x8) { // FADD
						m = "fadd";
					} else { // FMUL
						sti -= 8;
						m = "fmul";
					}
					break;
				case 0xD0: // FCOM/FCOMP
					if (sti < 0x8) { // FCOM
						m = "fcom";
					} else { // FCOMP
						sti -= 8;
						m = "fcomp";
					}
					break;
				case 0xE0: // FSUB/FSUBR
					if (sti < 0x8) { // FSUB
						m = "fsub";
					} else { // FSUBR
						sti -= 8;
						m = "fsubr";
					}
					break;
				case 0xF0: // FDIV/FDIVR
					if (sti < 0x8) { // FDIV
						m = "fdiv";
					} else { // FDIVR
						sti -= 8;
						m = "fdivr";
					}
					break;
				default:
				}
				disasm_push_str(p, m);
				disasm_push_str(p, x87_ststr(p, 0));
				disasm_push_str(p, x87_ststr(p, sti));
			}
		} else { // operand is memory pointer
			if (p.mode >= DisasmMode.File) {
				switch (modrm & RM_REG) {
				case RM_REG_000: m = "fadd"; break;
				case RM_REG_001: m = "fmul"; break;
				case RM_REG_010: m = "fcom"; break;
				case RM_REG_011: m = "fcomp"; break;
				case RM_REG_100: m = "fsub"; break;
				case RM_REG_101: m = "fsubr"; break;
				case RM_REG_110: m = "fdiv"; break;
				case RM_REG_111: m = "fdivr"; break;
				default: // never
				}
				seg = x86_segstr(p.x86.segreg);
				disasm_push_x32(p, *p.addru32);
				disasm_push_str(p, m);
				disasm_push_memregimm(p, seg, *p.addru32);
			}
			p.addrv += 4;
		}
		break;
	case 0xD9:	// ESCAPE D9
		ubyte modrm = *p.addru8;
		++p.addrv;
		if (p.mode >= DisasmMode.File)
			disasm_push_x8(p, modrm);
		const(char) *m = void, seg = void;
		if (modrm > 0xBF) { // operand is FP
			if (p.mode >= DisasmMode.File) {
				ubyte sti = modrm & 0xF;
				switch (modrm & 0xF0) {
				case 0xC0: // FLD/FXCH
					if (sti < 0x8) { // FLD
						m = "fld";
					} else { // FXCH
						sti -= 8;
						m = "fxch";
					}
					disasm_push_str(p, m);
					disasm_push_str(p, x87_ststr(p, 0));
					disasm_push_str(p, x87_ststr(p, sti));
					break;
				case 0xD0: // FNOP/Reserved
					if (sti == 0)
						disasm_push_str(p, "fnop");
					else
						disasm_err(p);
					break;
				case 0xE0:
					switch (sti) {
					case 0: m = "fchs"; break;
					case 1: m = "fabs"; break;
					case 4: m = "ftst"; break;
					case 5: m = "fxam"; break;
					case 8: m = "fld1"; break;
					case 9: m = "fldl2t"; break;
					case 0xA: m = "fldl2e"; break;
					case 0xB: m = "fldpi"; break;
					case 0xC: m = "fldlg2"; break;
					case 0xD: m = "fldln2"; break;
					case 0xE: m = "fldz"; break;
					default: //  2,3,6,7,0xF:
						disasm_err(p);
						break main;
					}
					disasm_push_str(p, m);
					break;
				case 0xF0:
					switch (sti) {
					case 0: m = "f2xm1"; break;
					case 1: m = "fyl2x"; break;
					case 2: m = "fptan"; break;
					case 3: m = "fpatan"; break;
					case 4: m = "fxtract"; break;
					case 5: m = "fprem1"; break;
					case 6: m = "fdecstp"; break;
					case 7: m = "fincstp"; break;
					case 8: m = "fprem"; break;
					case 9: m = "fyl2xp1"; break;
					case 0xA: m = "fsqrt"; break;
					case 0xB: m = "fsincos"; break;
					case 0xC: m = "frndint"; break;
					case 0xD: m = "fscale"; break;
					case 0xE: m = "fsin"; break;
					case 0xF: m = "fcos"; break;
					default: // never
					}
					disasm_push_str(p, m);
					break;
				default:
				}
			}
		} else { // operand is memory pointer
			if (p.mode >= DisasmMode.File) {
				switch (modrm & RM_REG) {
				case RM_REG_000: m = "fld"; break;
				case RM_REG_010: m = "fst"; break;
				case RM_REG_011: m = "fstp"; break;
				case RM_REG_100: m = "fldenv"; break;
				case RM_REG_101: m = "fldcw"; break;
				case RM_REG_110: m = "fstenv"; break;
				case RM_REG_111: m = "fstcw"; break;
				default:
					disasm_err(p);
					break main;
				}
				seg = x86_segstr(p.x86.segreg);
				disasm_push_x32(p, *p.addru32);
				disasm_push_str(p, m);
				disasm_push_memregimm(p, seg, *p.addru32);
			}
			p.addrv += 4;
		}
		break;
	case 0xDA:	// ESCAPE DA
		ubyte modrm = *p.addru8;
		++p.addrv;
		if (p.mode >= DisasmMode.File)
			disasm_push_x8(p, modrm);
		const(char) *m = void, seg = void;
		if (modrm > 0xBF) { // operand is FP
			if (p.mode >= DisasmMode.File) {
				ubyte sti = modrm & 0xF;
				switch (modrm & 0xF0) {
				case 0xC0: // FCMOVB/FCMOVE
					if (sti < 0x8) { // FCMOVB
						m = "fcmovb";
					} else { // FCMOVE
						sti -= 8;
						m = "fcmove";
					}
					disasm_push_str(p, m);
					disasm_push_str(p, x87_ststr(p, 0));
					disasm_push_str(p, x87_ststr(p, sti));
					break;
				case 0xD0: // FCMOVBE/FCMOVU
					if (sti < 0x8) { // FCMOVBE
						m = "fcmovbe";
					} else { // FCMOVU
						sti -= 8;
						m = "fcmovu";
					}
					disasm_push_str(p, m);
					disasm_push_str(p, x87_ststr(p, 0));
					disasm_push_str(p, x87_ststr(p, sti));
					break;
				case 0xE0:
					if (sti == 9)
						disasm_push_str(p, "fucompp");
					else
						disasm_err(p);
					break;
				default: // 0xF0:
					disasm_err(p);
				}
			}
		} else { // operand is memory pointer
			if (p.mode >= DisasmMode.File) {
				switch (modrm & RM_REG) {
				case RM_REG_000: m = "fiadd"; break;
				case RM_REG_001: m = "fimul"; break;
				case RM_REG_010: m = "ficom"; break;
				case RM_REG_011: m = "ficomp"; break;
				case RM_REG_100: m = "fisub"; break;
				case RM_REG_101: m = "fisubr"; break;
				case RM_REG_110: m = "fidiv"; break;
				case RM_REG_111: m = "fidivr"; break;
				default: // never
				}
				seg = x86_segstr(p.x86.segreg);
				disasm_push_x32(p, *p.addru32);
				disasm_push_str(p, m);
				disasm_push_memregimm(p, seg, *p.addru32);
			}
			p.addrv += 4;
		}
		break;
	case 0xDB:	// ESCAPE DB
		ubyte modrm = *p.addru8;
		++p.addrv;
		if (p.mode >= DisasmMode.File)
			disasm_push_x8(p, modrm);
		const(char) *m = void, seg = void;
		if (modrm > 0xBF) { // operand is FP
			if (p.mode >= DisasmMode.File) {
				ubyte sti = modrm & 0xF;
				switch (modrm & 0xF0) {
				case 0xC0: // FCMOVNB/FCMOVNE
					if (sti < 0x8) { // FCMOVNB
						m = "fcmovnb";
					} else { // FCMOVNE
						sti -= 8;
						m = "fcmovne";
					}
					disasm_push_str(p, m);
					disasm_push_str(p, x87_ststr(p, 0));
					disasm_push_str(p, x87_ststr(p, sti));
					break;
				case 0xD0: // FCMOVNBE/FCMOVNU
					if (sti < 0x8) { // FCMOVNBE
						m = "fcmovnbe";
					} else { // FCMOVNU
						sti -= 8;
						m = "fcmovnu";
					}
					disasm_push_str(p, m);
					disasm_push_str(p, x87_ststr(p, 0));
					disasm_push_str(p, x87_ststr(p, sti));
					break;
				case 0xE0: // */FUCOMI
					if (sti < 0x8) { // FCMOVNBE
						switch (sti) {
						case 1: m = "fclex"; break;
						case 2: m = "finit"; break;
						default: disasm_err(p); break main;
						}
						disasm_push_str(p, m);
					} else { // FUCOMI
						sti -= 8;
						disasm_push_str(p, "fucomi");
						disasm_push_str(p, x87_ststr(p, 0));
						disasm_push_str(p, x87_ststr(p, sti));
					}
					break;
				case 0xF0: // FCOMI/Reserved
					if (sti < 0x8) { // FCOMI
						disasm_push_str(p, "fcomi");
						disasm_push_str(p, x87_ststr(p, 0));
						disasm_push_str(p, x87_ststr(p, sti));
					} else { // Reserved
						disasm_err(p);
					}
					break;
				default:
				}
			}
		} else { // operand is memory pointer
			if (p.mode >= DisasmMode.File) {
				switch (modrm & RM_REG) {
				case RM_REG_000: m = "fiadd"; break;
				case RM_REG_001: m = "fimul"; break;
				case RM_REG_010: m = "ficom"; break;
				case RM_REG_011: m = "ficomp"; break;
				case RM_REG_100: m = "fisub"; break;
				case RM_REG_101: m = "fisubr"; break;
				case RM_REG_110: m = "fidiv"; break;
				case RM_REG_111: m = "fidivr"; break;
				default: // never
				}
				seg = x86_segstr(p.x86.segreg);
				disasm_push_x32(p, *p.addru32);
				disasm_push_str(p, m);
				disasm_push_memregimm(p, seg, *p.addru32);
			}
			p.addrv += 4;
		}
		break;
	case 0xDC:	// ESCAPE DC
		ubyte modrm = *p.addru8;
		++p.addrv;
		if (p.mode >= DisasmMode.File)
			disasm_push_x8(p, modrm);
		const(char) *m = void, seg = void;
		if (modrm > 0xBF) { // operand is FP
			if (p.mode >= DisasmMode.File) {
				ubyte sti = modrm & 0xF;
				switch (modrm & 0xF0) {
				case 0xC0: // FADD/FMUL
					if (sti < 0x8) { // FADD
						m = "fadd";
					} else { // FMUL
						sti -= 8;
						m = "fmul";
					}
					break;
				case 0xE0: // FSUBR/FSUB
					if (sti < 0x8) { // FSUBR
						m = "fsubr";
					} else { // FSUB
						sti -= 8;
						m = "fsub";
					}
					break;
				case 0xF0: // FDIVR/FDIV
					if (sti < 0x8) { // FDIVR
						m = "fdivr";
					} else { // FDIV
						sti -= 8;
						m = "fdiv";
					}
					break;
				default: // 0x0D
					disasm_err(p);
					break main;
				}
				disasm_push_str(p, m);
				disasm_push_str(p, x87_ststr(p, sti));
				disasm_push_str(p, x87_ststr(p, 0));
			}
		} else { // operand is memory pointer
			if (p.mode >= DisasmMode.File) {
				switch (modrm & RM_REG) {
				case RM_REG_000: m = "fadd"; break;
				case RM_REG_001: m = "fmul"; break;
				case RM_REG_010: m = "fcom"; break;
				case RM_REG_011: m = "fcomp"; break;
				case RM_REG_100: m = "fsub"; break;
				case RM_REG_101: m = "fsubr"; break;
				case RM_REG_110: m = "fdiv"; break;
				case RM_REG_111: m = "fdivr"; break;
				default: // never
				}
				seg = x86_segstr(p.x86.segreg);
				disasm_push_x32(p, *p.addru32);
				disasm_push_str(p, m);
				disasm_push_memregimm(p, seg, *p.addru32);
			}
			p.addrv += 4;
		}
		break;
	case 0xDD:	// ESCAPE DD
		ubyte modrm = *p.addru8;
		++p.addrv;
		if (p.mode >= DisasmMode.File)
			disasm_push_x8(p, modrm);
		const(char) *m = void, seg = void;
		if (modrm > 0xBF) { // operand is FP
			if (p.mode >= DisasmMode.File) {
				ubyte sti = modrm & 0xF;
				switch (modrm & 0xF0) {
				case 0xC0: // FFREE/Reserved
					if (sti < 0x8) { // FFREE
						disasm_push_str(p, "ffree");
						disasm_push_str(p, x87_ststr(p, sti));
					} else { // Reserved
						disasm_err(p);
					}
					break;
				case 0xD0: // FST/FSTP
					if (sti < 0x8) { // FST
						m = "fst";
					} else { // FSTP
						sti -= 8;
						m = "fstp";
					}
					disasm_push_str(p, m);
					disasm_push_str(p, x87_ststr(p, sti));
					break;
				case 0xE0: // FUCOM/FUCOMP
					if (sti < 0x8) { // FUCOM
						disasm_push_str(p, "fucom");
						disasm_push_str(p, x87_ststr(p, sti));
						disasm_push_str(p, x87_ststr(p, 0));
					} else { // FUCOMP
						sti -= 8;
						disasm_push_str(p, "fucomp");
						disasm_push_str(p, x87_ststr(p, sti));
					}
					break;
				default: // 0xF0
					disasm_err(p);
				}
			}
		} else { // operand is memory pointer
			if (p.mode >= DisasmMode.File) {
				switch (modrm & RM_REG) {
				case RM_REG_000: m = "fld"; break;
				case RM_REG_001: m = "fisttp"; break;
				case RM_REG_010: m = "fst"; break;
				case RM_REG_011: m = "fstp"; break;
				case RM_REG_100: m = "frstor"; break;
				case RM_REG_110: m = "fsave"; break;
				case RM_REG_111: m = "fstsw"; break;
				default: disasm_err(p); break main;
				}
				seg = x86_segstr(p.x86.segreg);
				disasm_push_x32(p, *p.addru32);
				disasm_push_str(p, m);
				disasm_push_memregimm(p, seg, *p.addru32);
			}
			p.addrv += 4;
		}
		break;
	case 0xDE:	// ESCAPE DE
		ubyte modrm = *p.addru8;
		++p.addrv;
		if (p.mode >= DisasmMode.File)
			disasm_push_x8(p, modrm);
		const(char) *m = void, seg = void;
		if (modrm > 0xBF) { // operand is FP
			if (p.mode >= DisasmMode.File) {
				ubyte sti = modrm & 0xF;
				switch (modrm & 0xF0) {
				case 0xC0: // FADDP/FMULP
					if (sti < 0x8) { // FADDP
						m = "faddp";
					} else { // FMULP
						sti -= 8;
						m = "fmulp";
					}
					break;
				case 0xD0: // Reserved/FCOMPP*
					if (sti == 9)
						disasm_push_str(p, "fcompp");
					else
						disasm_err(p);
					break main;
				case 0xE0: // FSUBRP/FSUBP
					if (sti < 0x8) { // FSUBP
						m = "fsubrp";
					} else { // FSUBP
						sti -= 8;
						m = "fucomp";
					}
					break;
				case 0xF0: // FDIVRP/FDIVP
					if (sti < 0x8) { // FDIVRP
						m = "fdivrp";
					} else { // FDIVP
						sti -= 8;
						m = "fdivp";
					}
					break;
				default:
				}
				disasm_push_str(p, m);
				disasm_push_str(p, x87_ststr(p, sti));
				disasm_push_str(p, x87_ststr(p, 0));
			}
		} else { // operand is memory pointer
			if (p.mode >= DisasmMode.File) {
				switch (modrm & RM_REG) {
				case RM_REG_000: m = "fiadd"; break;
				case RM_REG_001: m = "fimul"; break;
				case RM_REG_010: m = "ficom"; break;
				case RM_REG_011: m = "ficomp"; break;
				case RM_REG_100: m = "fisub"; break;
				case RM_REG_101: m = "fisubr"; break;
				case RM_REG_110: m = "fidiv"; break;
				case RM_REG_111: m = "fidivr"; break;
				default: // never
				}
				seg = x86_segstr(p.x86.segreg);
				disasm_push_x32(p, *p.addru32);
				disasm_push_str(p, m);
				disasm_push_memregimm(p, seg, *p.addru32);
			}
			p.addrv += 4;
		}
		break;
	case 0xDF:	// ESCAPE DF
		ubyte modrm = *p.addru8;
		++p.addrv;
		if (p.mode >= DisasmMode.File)
			disasm_push_x8(p, modrm);
		const(char) *m = void, seg = void;
		if (modrm > 0xBF) { // operand is FP
			if (p.mode >= DisasmMode.File) {
				ubyte sti = modrm & 0xF;
				switch (modrm & 0xF0) {
				case 0xE0: // FSTSW*/FUCOMIP
					if (sti < 0x8) { // FSUBP
						if (sti == 0) {
							disasm_push_str(p, "fstsw");
							disasm_push_reg(p, "ax");
						} else
							disasm_err(p);
					} else { // FUCOMIP
						sti -= 8;
						disasm_push_str(p, "fstsw");
						disasm_push_str(p, x87_ststr(p, 0));
						disasm_push_str(p, x87_ststr(p, sti));
					}
					break;
				case 0xF0: // FCOMIP/Reserved
					if (sti < 0x8) { // FCOMIP
						disasm_push_str(p, "fcomip");
						disasm_push_str(p, x87_ststr(p, 0));
						disasm_push_str(p, x87_ststr(p, sti));
					} else // Reserved
						disasm_err(p);
					break;
				default:
					disasm_err(p);
				}
			}
		} else { // operand is memory pointer
			if (p.mode >= DisasmMode.File) {
				switch (modrm & RM_REG) {
				case RM_REG_000: m = "fild"; break;
				case RM_REG_001: m = "fisttp"; break;
				case RM_REG_010: m = "fist"; break;
				case RM_REG_011: m = "fistp"; break;
				case RM_REG_100: m = "fbld"; break;
				case RM_REG_101: m = "fild"; break;
				case RM_REG_110: m = "fbstp"; break;
				case RM_REG_111: m = "fistp"; break;
				default: // never
				}
				seg = x86_segstr(p.x86.segreg);
				disasm_push_x32(p, *p.addru32);
				disasm_push_str(p, m);
				disasm_push_memregimm(p, seg, *p.addru32);
			}
			p.addrv += 4;
		}
		break;
	case 0xE0:	// LOOPNE IMM8
		if (p.mode >= DisasmMode.File) {
			disasm_push_x8(p, *p.addru8);
			disasm_push_str(p, "loopne");
			disasm_push_imm(p, *p.addri8);
		}
		++p.addrv;
		break;
	case 0xE1:	// LOOPE IMM8
		if (p.mode >= DisasmMode.File) {
			disasm_push_x8(p, *p.addru8);
			disasm_push_str(p, "loope");
			disasm_push_imm(p, *p.addri8);
		}
		++p.addrv;
		break;
	case 0xE2:	// LOOP IMM8
		if (p.mode >= DisasmMode.File) {
			disasm_push_x8(p, *p.addru8);
			disasm_push_str(p, "loop");
			disasm_push_imm(p, *p.addri8);
		}
		++p.addrv;
		break;
	case 0xE3:	// JECXZ IMM8
		if (p.mode >= DisasmMode.File) {
			disasm_push_x8(p, *p.addru8);
			disasm_push_str(p, "jecxz");
			disasm_push_imm(p, *p.addri8);
		}
		++p.addrv;
		break;
	case 0xE4:	// IN AL, IMM8
		if (p.mode >= DisasmMode.File) {
			disasm_push_x8(p, *p.addru8);
			disasm_push_str(p, "in");
			disasm_push_reg(p, "al");
			disasm_push_imm(p, *p.addri8);
		}
		++p.addrv;
		break;
	case 0xE5:	// IN EAX, IMM8
		if (p.mode >= DisasmMode.File) {
			disasm_push_x8(p, *p.addru8);
			disasm_push_str(p, "in");
			disasm_push_reg(p, "eax");
			disasm_push_imm(p, *p.addri8);
		}
		++p.addrv;
		break;
	case 0xE6:	// OUT IMM8, AL
		if (p.mode >= DisasmMode.File) {
			disasm_push_x8(p, *p.addru8);
			disasm_push_str(p, "out");
			disasm_push_imm(p, *p.addri8);
			disasm_push_reg(p, "al");
		}
		++p.addrv;
		break;
	case 0xE7:	// OUT IMM8, EAX
		if (p.mode >= DisasmMode.File) {
			disasm_push_x8(p, *p.addru8);
			disasm_push_str(p, "out");
			disasm_push_imm(p, *p.addri8);
			disasm_push_reg(p, "eax");
		}
		++p.addrv;
		break;
	case 0xE8:	// CALL IMM32
		if (p.mode >= DisasmMode.File) {
			disasm_push_x32(p, *p.addru32);
			disasm_push_str(p, "call");
			disasm_push_imm(p, *p.addru32);
		}
		p.addrv += 4;
		break;
	case 0xE9:	// JMP NEAR IMM32
		if (p.mode >= DisasmMode.File)
			disasm_push_str(p, "jmp");
		x86_vu32imm(p);
		break;
	case 0xEB:	// JMP IMM8
		if (p.mode >= DisasmMode.File) {
			disasm_push_x8(p, *p.addru8);
			disasm_push_str(p, "jmp");
			disasm_push_imm(p, *p.addru8);
		}
		++p.addrv;
		break;
	case 0xF0:	// LOCK
		if (p.x86.group1) {
			disasm_err(p);
			break;
		}
		p.x86.lock = 0xF0;
		//TODO: Uncomment when formatter prefix setting is working
//		p.fmt.settings |= FORMATTER_O_PREFIX;
//		if (p.mode >= DisasmMode.File)
//			disasm_push_str(p, "lock");
		goto L_CONTINUE;
	case 0xF1:	// INT1
		if (p.mode >= DisasmMode.File)
			disasm_push_str(p, "int1");
		break;
	case 0xF2:	// REPNE
		if (p.x86.group1) {
			disasm_err(p);
			break;
		}
		p.x86.repne = 0xF2;
		//TODO: Uncomment when formatter prefix setting is working
//		p.fmt.settings |= FORMATTER_O_PREFIX;
//		if (p.mode >= DisasmMode.File)
//			disasm_push_str(p, "repne");
		goto L_CONTINUE;
	case 0xF3:	// REP
		if (p.x86.group1) {
			disasm_err(p);
			break;
		}
		p.x86.rep = 0xF3;
		//TODO: Uncomment when formatter prefix setting is working
//		p.fmt.settings |= FORMATTER_O_PREFIX;
//		if (p.mode >= DisasmMode.File)
//			disasm_push_str(p, "rep");
		goto L_CONTINUE;
	case 0xF4:	// HLT
		if (p.mode >= DisasmMode.File)
			disasm_push_str(p, "hlt");
		break;
	case 0xF5:	// CMC
		if (p.mode >= DisasmMode.File)
			disasm_push_str(p, "cmc");
		break;
	case 0xF6:	// GRP 3 R/M8
	case 0xF7:	// GRP 3 R/M32
		int w = X86_OP_WIDE(b);
		ubyte modrm = *p.addru8;
		++p.addrv;
		switch (modrm & RM_REG) {
		case RM_REG_000: // TEST R/M*, IMM8
			if (p.mode >= DisasmMode.File)
				disasm_push_str(p, "test");
			x86_modrm_rm(p, modrm, w);
			if (p.mode >= DisasmMode.File) {
				disasm_push_x8(p, *p.addru8);
				disasm_push_imm(p, *p.addru8);
			}
			++p.addrv;
			break;
		case RM_REG_010: // NOT R/M*
			if (p.mode >= DisasmMode.File)
				disasm_push_str(p, "not");
			x86_modrm_rm(p, modrm, w);
			break;
		case RM_REG_011: // NEG R/M*
			if (p.mode >= DisasmMode.File)
				disasm_push_str(p, "neg");
			x86_modrm_rm(p, modrm, w);
			break;
		case RM_REG_100: // MUL R/M*, reg-a
			if (p.mode >= DisasmMode.File)
				disasm_push_str(p, "mul");
			x86_modrm_rm(p, modrm, w);
			if (p.mode >= DisasmMode.File)
				disasm_push_reg(p, w ? "eax" : "al");
			break;
		case RM_REG_101: // IMUL R/M*, reg-a
			if (p.mode >= DisasmMode.File)
				disasm_push_str(p, "imul");
			x86_modrm_rm(p, modrm, w);
			if (p.mode >= DisasmMode.File)
				disasm_push_reg(p, w ? "eax" : "al");
			break;
		case RM_REG_110:
			if (p.mode >= DisasmMode.File)
				disasm_push_str(p, "div");
			x86_modrm_rm(p, modrm, w);
			if (p.mode >= DisasmMode.File)
				disasm_push_reg(p, w ? "eax" : "al");
			break;
		case RM_REG_111:
			if (p.mode >= DisasmMode.File)
				disasm_push_str(p, "idiv");
			x86_modrm_rm(p, modrm, w);
			if (p.mode >= DisasmMode.File)
				disasm_push_reg(p, w ? "eax" : "al");
			break;
		default:
			disasm_err(p);
		}
		break;
	case 0xF8:	// CLC
		if (p.mode >= DisasmMode.File)
			disasm_push_str(p, "clc");
		break;
	case 0xF9:	// STC
		if (p.mode >= DisasmMode.File)
			disasm_push_str(p, "stc");
		break;
	case 0xFA:	// CLI
		if (p.mode >= DisasmMode.File)
			disasm_push_str(p, "cli");
		break;
	case 0xFB:	// STI
		if (p.mode >= DisasmMode.File)
			disasm_push_str(p, "sti");
		break;
	case 0xFC:	// CLD
		if (p.mode >= DisasmMode.File)
			disasm_push_str(p, "cld");
		break;
	case 0xFD:	// STD
		if (p.mode >= DisasmMode.File)
			disasm_push_str(p, "std");
		break;
	case 0xFE:	// GRP 4
		ubyte modrm = *p.addru8;
		++p.addrv;
		switch (modrm & RM_REG) {
		case RM_REG_000: // INC R/M8
			if (p.mode >= DisasmMode.File)
				disasm_push_str(p, "inc");
			x86_modrm_rm(p, modrm, X86_WIDTH_NONE);
			break;
		case RM_REG_001: // DEC R/M8
			if (p.mode >= DisasmMode.File)
				disasm_push_str(p, "dec");
			x86_modrm_rm(p, modrm, X86_WIDTH_NONE);
			break;
		default:
			disasm_err(p);
		}
		break;
	case 0xFF:	// GRP 5
		ubyte modrm = *p.addru8;
		++p.addrv;
		switch (modrm & RM_REG) {
		case RM_REG_000: // INC R/M32
			if (p.mode >= DisasmMode.File)
				disasm_push_str(p, "inc");
			x86_modrm_rm(p, modrm, X86_WIDTH_WIDE);
			break;
		case RM_REG_001: // DEC R/M32
			if (p.mode >= DisasmMode.File)
				disasm_push_str(p, "dec");
			x86_modrm_rm(p, modrm, X86_WIDTH_WIDE);
			break;
		case RM_REG_010: // CALL NEAR R/M32
			if (p.mode >= DisasmMode.File)
				disasm_push_str(p, "call");
			x86_modrm_rm(p, modrm, X86_WIDTH_WIDE);
			break;
		case RM_REG_011: // CALL FAR M16:M32
			if (p.mode >= DisasmMode.File) {
				disasm_push_x32(p, *p.addru32);
				disasm_push_str(p, "call");
				disasm_push_memregimm(p,
					x86_segstr(p.x86.segreg),
					*p.addru32);
			}
			p.addrv += 4;
			break;
		case RM_REG_100: // JMP NEAR R/M32
			if (p.mode >= DisasmMode.File)
				disasm_push_str(p, "call");
			x86_modrm_rm(p, modrm, X86_WIDTH_WIDE);
			break;
		case RM_REG_101: // JMP FAR M16:M32
			if (p.mode >= DisasmMode.File) {
				disasm_push_x32(p, *p.addru32);
				disasm_push_str(p, "jmp");
				disasm_push_memregimm(p,
					x86_segstr(p.x86.segreg),
					*p.addru32);
			}
			p.addrv += 4;
			break;
		case RM_REG_110: // PUSH R/M32
			if (p.mode >= DisasmMode.File)
				disasm_push_str(p, "push");
			x86_modrm_rm(p, modrm, X86_WIDTH_WIDE);
			break;
		default:
			disasm_err(p);
		}
		break;
	default:
		disasm_err(p);
	}
}

private:

void x86_0f(ref disasm_params_t p) {
	ubyte b = *p.addru8;
	++p.addrv;

	if (p.mode >= DisasmMode.File)
		disasm_push_x8(p, b);

	main: switch (b) {
	case 0x00: // GRP6
		ubyte modrm = *p.addru8;
		++p.addrv;

		const(char) *m = void;
		switch (modrm & RM_REG) {
		case RM_REG_000: m = "sldt"; break;
		case RM_REG_001: m = "str"; break;
		case RM_REG_010: m = "lldt"; break;
		case RM_REG_011: m = "ltr"; break;
		case RM_REG_100: m = "verr"; break;
		case RM_REG_101: m = "verw"; break;
		default: disasm_err(p); break main;
		}

		if (p.mode >= DisasmMode.File)
			disasm_push_str(p, m);
		x86_modrm_rm(p, modrm, X86_WIDTH_WIDE);
		break;
	case 0x01: // GRP7
		ubyte modrm = *p.addru8;
		ubyte mod11 = (modrm & RM_MOD) == RM_MOD_11;
		++p.addrv;

		const(char) *m = void;
		switch (modrm & RM_REG) {
		case RM_REG_000:
			if (mod11) { // VM*
				if (p.mode < DisasmMode.File)
					break;
				switch (modrm & RM_RM) {
				case RM_RM_001: m = "vmcall"; break;
				case RM_RM_010: m = "vmlaunch"; break;
				case RM_RM_011: m = "vmresume"; break;
				case RM_RM_100: m = "vmxoff"; break;
				default: disasm_err(p); break main;
				}
				disasm_push_x8(p, modrm);
				disasm_push_str(p, m);
			} else { // SGDT
				if (p.mode >= DisasmMode.File)
					disasm_push_str(p, "sgdt");
				x86_modrm_rm(p, modrm, X86_WIDTH_WIDE);
			}
			break;
		case RM_REG_001:
			if (mod11) { // MONITOR*
				if (p.mode < DisasmMode.File)
					break;
				switch (modrm & RM_RM) {
				case RM_RM_000: m = "monitor"; break;
				case RM_RM_001: m = "mwait"; break;
				case RM_RM_010: m = "clac"; break;
				case RM_RM_011: m = "stac"; break;
				case RM_RM_111: m = "encls"; break;
				default: disasm_err(p); break main;
				}
				disasm_push_x8(p, modrm);
				disasm_push_str(p, m);
			} else { // SIDT
				if (p.mode >= DisasmMode.File)
					disasm_push_str(p, "sidt");
				x86_modrm_rm(p, modrm, X86_WIDTH_WIDE);
			}
			break;
		case RM_REG_010:
			if (mod11) { // X*
				if (p.mode < DisasmMode.File)
					break;
				switch (modrm & RM_RM) {
				case RM_RM_000: m = "xgetbv"; break;
				case RM_RM_001: m = "xsetbv"; break;
				case RM_RM_100: m = "vmfunc"; break;
				case RM_RM_101: m = "xend"; break;
				case RM_RM_110: m = "xtest"; break;
				case RM_RM_111: m = "enclu"; break;
				default: disasm_err(p); break main;
				}
				disasm_push_x8(p, modrm);
				disasm_push_str(p, m);
			} else { // LGDT
				if (p.mode >= DisasmMode.File)
					disasm_push_str(p, "lgdt");
				x86_modrm_rm(p, modrm, X86_WIDTH_WIDE);
			}
			break;
		case RM_REG_011:
			if (mod11) { // (AMD) SVM
				if (p.mode < DisasmMode.File)
					break;
				switch (modrm & RM_RM) {
				case RM_RM_000: m = "vmrun"; break;
				case RM_RM_001: m = "vmmcall"; break;
				case RM_RM_010: m = "vmload"; break;
				case RM_RM_011: m = "vmsave"; break;
				case RM_RM_100: m = "stgi"; break;
				case RM_RM_101: m = "clgi"; break;
				case RM_RM_110: m = "skinit"; break;
				case RM_RM_111: m = "invlpga"; break;
				default: // never
				}
				disasm_push_x8(p, modrm);
				disasm_push_str(p, m);
			} else { // LIDT
				if (p.mode >= DisasmMode.File)
					disasm_push_str(p, "lgdt");
				x86_modrm_rm(p, modrm, X86_WIDTH_WIDE);
			}
			break;
		case RM_REG_100: // SMSW
			if (p.mode >= DisasmMode.File)
				disasm_push_str(p, "smsw");
			x86_modrm_rm(p, modrm, X86_WIDTH_WIDE);
			break;
		case RM_REG_110: // LMSW
			if (p.mode >= DisasmMode.File)
				disasm_push_str(p, "lmsw");
			x86_modrm_rm(p, modrm, X86_WIDTH_WIDE);
			break;
		case RM_REG_111:
			if (mod11) { // *
				if ((modrm & RM_RM) == RM_RM_001) {
					if (p.mode >= DisasmMode.File) {
						disasm_push_x8(p, modrm);
						disasm_push_str(p, "rdtscp");
					}
				} else
					disasm_err(p);
			} else { // INVLPG
				if (p.mode >= DisasmMode.File)
					disasm_push_str(p, "invlpg");
				x86_modrm_rm(p, modrm, X86_WIDTH_WIDE);
			}
			break;
		default:
			disasm_err(p);
		}
		break;
	case 0x02: // LAR REG32, R/M16
		if (p.mode >= DisasmMode.File)
			disasm_push_str(p, "lar");
		x86_modrm(p, X86_WIDTH_WIDE, X86_DIR_REG);
		break;
	case 0x03: // LSL REG32, R/M16
		if (p.mode >= DisasmMode.File)
			disasm_push_str(p, "lsl");
		x86_modrm(p, X86_WIDTH_WIDE, X86_DIR_REG);
		break;
	case 0x06: // CLTS
		if (p.mode >= DisasmMode.File)
			disasm_push_str(p, "clts");
		break;
	case 0x08: // INVD
		if (p.mode >= DisasmMode.File)
			disasm_push_str(p, "invd");
		break;
	case 0x09: // WBINVD
		if (p.mode >= DisasmMode.File)
			disasm_push_str(p, "wbinvd");
		break;
	case 0x0B: // UD2
		if (p.mode >= DisasmMode.File)
			disasm_push_str(p, "ud2");
		break;
	case 0x0D: // PREFETCHW /1
		ubyte modrm = *p.addru8;
		++p.addrv;
		if ((modrm & RM_REG) == RM_REG_001) {
			if (p.mode >= DisasmMode.File)
				disasm_push_str(p, "prefetchw");
			x86_modrm_rm(p, modrm, X86_WIDTH_WIDE);
		} else
			disasm_err(p);
		break;
	case 0x10, 0x11: // MOVUPS/MOVUPD/MOVSS/MOVSD
		const(char) *m = void;
		switch (x86_0f_select(p)) {
		case X86_0F_NONE: m = "movups"; break;
		case X86_0F_66H: m = "movupd"; break;
		case X86_0F_F2H: m = "movsd"; break;
		case X86_0F_F3H: m = "movss"; break;
		default: disasm_err(p); break main;
		}
		if (p.mode >= DisasmMode.File)
			disasm_push_str(p, m);
		x86_modrm(p, X86_WIDTH_XMM, X86_OP_DIR(b));
		break;
	case 0x12: // (MOVLPS|MOVHLPS)/MOVSLDUP/MOVLPD/MOVDDUP
		const(char) *m = void;
		switch (x86_0f_select(p)) {
		case X86_0F_NONE:
			m = (*p.addru8 & RM_MOD) == RM_MOD_11 ?
				"movhlps" : "movlps";
			break;
		case X86_0F_66H: m = "movlpd"; break;
		case X86_0F_F2H: m = "movddup"; break;
		case X86_0F_F3H: m = "movsldup"; break;
		default: disasm_err(p); break main;
		}
		if (p.mode >= DisasmMode.File)
			disasm_push_str(p, m);
		x86_modrm(p, X86_WIDTH_XMM, X86_DIR_REG);
		break;
	case 0x13: // MOVLPS/MOVLPD
		const(char) *m = void;
		switch (x86_0f_select(p)) {
		case X86_0F_NONE: m = "movlps"; break;
		case X86_0F_66H: m = "movlpd"; break;
		default: disasm_err(p); break main;
		}
		if (p.mode >= DisasmMode.File)
			disasm_push_str(p, m);
		x86_modrm(p, X86_WIDTH_XMM, X86_DIR_MEM);
		break;
	case 0x14: // UNPCKLPS/UNPCKLPD
		const(char) *m = void;
		switch (x86_0f_select(p)) {
		case X86_0F_NONE: m = "unpcklpd"; break;
		case X86_0F_66H: m = "unpcklpd"; break;
		default: disasm_err(p); break main;
		}
		if (p.mode >= DisasmMode.File)
			disasm_push_str(p, m);
		x86_modrm(p, X86_WIDTH_XMM, X86_DIR_REG);
		break;
	case 0x15: // UNPCKHPS/UNPCKHPD
		const(char) *m = void;
		switch (x86_0f_select(p)) {
		case X86_0F_NONE: m = "unpckhps"; break;
		case X86_0F_66H: m = "unpckhpd"; break;
		default: disasm_err(p); break main;
		}
		if (p.mode >= DisasmMode.File)
			disasm_push_str(p, m);
		x86_modrm(p, X86_WIDTH_XMM, X86_DIR_REG);
		break;
	case 0x16: // (MOVHPS|MOVLHPS)/MOVHPD/MOVSHDUP
		const(char) *m = void;
		switch (x86_0f_select(p)) {
		case X86_0F_NONE:
			m = (*p.addru8 & RM_MOD) == RM_MOD_11 ?
				"movlhps" : "movhps";
			break;
		case X86_0F_66H: m = "movhpd"; break;
		case X86_0F_F3H: m = "movshdup "; break;
		default: disasm_err(p); break main;
		}
		if (p.mode >= DisasmMode.File)
			disasm_push_str(p, m);
		x86_modrm(p, X86_WIDTH_XMM, X86_DIR_REG);
		break;
	case 0x17: // MOVHPS/MOVHPD
		const(char) *m = void;
		switch (x86_0f_select(p)) {
		case X86_0F_NONE: m = "movhps"; break;
		case X86_0F_66H: m = "movhpd"; break;
		default: disasm_err(p); break main;
		}
		if (p.mode >= DisasmMode.File)
			disasm_push_str(p, m);
		x86_modrm(p, X86_WIDTH_XMM, X86_DIR_MEM);
		break;
	case 0x18: // GRP 16
		ubyte modrm = *p.addru8;
		++p.addrv;

		if ((modrm & RM_MOD) == RM_MOD_11) {
			disasm_err(p);
			break;
		}

		const(char) *m = void;
		switch (modrm & RM_REG) {
		case RM_REG_000: m = "prefetchnta"; break;
		case RM_REG_001: m = "prefetcht0"; break;
		case RM_REG_010: m = "prefetcht1"; break;
		case RM_REG_011: m = "prefetcht2"; break;
		default: // NOP (reserved)
			if (p.mode >= DisasmMode.File)
				disasm_push_str(p, "nop");
			break main;
		}
		if (p.mode >= DisasmMode.File)
			disasm_push_str(p, m);
		x86_modrm_rm(p, modrm, X86_WIDTH_WIDE);
		break;
	case 0x19, 0x1C, 0x1D, 0x1E: // NOP (reserved)
		if (p.mode >= DisasmMode.File)
			disasm_push_str(p, "nop");
		break;
	case 0x1A: // BNDLDX/BNDMOV/BNDCU/BNDCL
		const(char) *m = void; // instruction
		const(char) *r = void; // bound keyword (bnd0..bnd3)
		ubyte modrm = *p.addru8;
		++p.addrv;
		switch (modrm & RM_REG) {
		case RM_REG_000: r = "bnd0"; break;
		case RM_REG_001: r = "bnd1"; break;
		case RM_REG_010: r = "bnd2"; break;
		case RM_REG_011: r = "bnd3"; break;
		default: disasm_err(p); break main;
		}
		switch (x86_0f_select(p)) {
		case X86_0F_NONE: m = "bndldx"; break;
		case X86_0F_66H: m = "bndmov"; break;
		case X86_0F_F2H: m = "bndcu"; break;
		case X86_0F_F3H: m = "bndcl"; break;
		default: disasm_err(p); break main;
		}
		if (p.mode >= DisasmMode.File) {
			disasm_push_str(p, m);
			disasm_push_reg(p, r);
		}
		x86_modrm_rm(p, modrm, X86_WIDTH_WIDE);
		break;
	case 0x1B: // BNDSTX/BNDMOV/BNDCN/BNDMK
		const(char) *m = void; // instruction
		const(char) *r = void; // bound keyword (bnd0..bnd3)
		ubyte modrm = *p.addru8;
		++p.addrv;
		switch (modrm & RM_REG) {
		case RM_REG_000: r = "bnd0"; break;
		case RM_REG_001: r = "bnd1"; break;
		case RM_REG_010: r = "bnd2"; break;
		case RM_REG_011: r = "bnd3"; break;
		default: disasm_err(p); break main;
		}
		switch (x86_0f_select(p)) {
		case X86_0F_NONE: m = "bndstx"; break;
		case X86_0F_66H: m = "bndmov"; break;
		case X86_0F_F2H: m = "bndcn"; break;
		case X86_0F_F3H: m = "bndmk"; break;
		default: disasm_err(p); break main;
		}
		if (p.mode >= DisasmMode.File)
			disasm_push_str(p, m);
		x86_modrm_rm(p, modrm, X86_WIDTH_WIDE);
		if (p.mode >= DisasmMode.File)
			disasm_push_reg(p, r);
		break;
	case 0x1F: // Multi-byte NOP
		ubyte modrm = *p.addru8;
		++p.addrv;
		if (p.mode >= DisasmMode.File)
			disasm_push_str(p, "nop");
		x86_modrm_rm(p, modrm, X86_WIDTH_WIDE);
		break;
	case 0x20: // MOV REG, CR
	case 0x22: // MOV CR, REG
		//TODO: LOCK prefix can extend modrm to get upto cr15
		ubyte modrm = *p.addru8;
		++p.addrv;
		if (p.mode >= DisasmMode.File)
			disasm_push_x8(p, modrm);
		if ((modrm & RM_MOD) != RM_MOD_11) {
			disasm_err(p);
			break;
		}
		if (p.mode >= DisasmMode.File) {
			const(char) *reg = x86_modrm_reg(p, modrm << 3, X86_WIDTH_WIDE);
			const(char) *cr = void;
			switch (modrm & RM_REG) {
			case RM_REG_000: cr = "cr0"; break;
			case RM_REG_001: cr = "cr1"; break;
			case RM_REG_010: cr = "cr2"; break;
			case RM_REG_011: cr = "cr3"; break;
			case RM_REG_100: cr = "cr4"; break;
			case RM_REG_101: cr = "cr5"; break;
			case RM_REG_110: cr = "cr6"; break;
			case RM_REG_111: cr = "cr7"; break;
			default: // never
			}
			disasm_push_str(p, "mov");
			if (X86_OP_DIR(b)) {
				disasm_push_reg(p, cr);
				disasm_push_reg(p, reg);
			} else {
				disasm_push_reg(p, reg);
				disasm_push_reg(p, cr);
			}
		}
		break;
	case 0x21: // MOV REG, DR
	case 0x23: // MOV DR, REG
		ubyte modrm = *p.addru8;
		++p.addrv;
		if (p.mode >= DisasmMode.File)
			disasm_push_x8(p, modrm);
		if ((modrm & RM_MOD) != RM_MOD_11) {
			disasm_err(p);
			break;
		}
		if (p.mode >= DisasmMode.File) {
			const(char) *reg = x86_modrm_reg(p, modrm << 3, X86_WIDTH_WIDE);
			const(char) *dr = void;
			switch (modrm & RM_REG) {
			case RM_REG_000: dr = "dr0"; break;
			case RM_REG_001: dr = "dr1"; break;
			case RM_REG_010: dr = "dr2"; break;
			case RM_REG_011: dr = "dr3"; break;
			case RM_REG_100: dr = "dr4"; break;
			case RM_REG_101: dr = "dr5"; break;
			case RM_REG_110: dr = "dr6"; break;
			case RM_REG_111: dr = "dr7"; break;
			default: // never
			}
			disasm_push_str(p, "mov");
			if (X86_OP_DIR(b)) {
				disasm_push_reg(p, dr);
				disasm_push_reg(p, reg);
			} else {
				disasm_push_reg(p, reg);
				disasm_push_reg(p, dr);
			}
		}
		break;
	case 0x28: // MOVAPS/MOVAPD XMM, R/M
	case 0x29: // MOVAPS/MOVAPD R/M, XMM
		const(char) *m = void;
		switch (x86_0f_select(p)) {
		case X86_0F_NONE: m = "movaps"; break;
		case X86_0F_66H: m = "movapd"; break;
		default: disasm_err(p); break main;
		}
		if (p.mode >= DisasmMode.File)
			disasm_push_str(p, m);
		x86_modrm(p, X86_WIDTH_XMM, X86_OP_DIR(b));
		break;
	case 0x2A: // CVTPI2PS/CVTPI2PD/CVTSI2SD/CVTSI2SS REG, R/M
		const(char) *m = void;
		switch (x86_0f_select(p)) {
		case X86_0F_NONE: m = "cvtpi2ps"; break;
		case X86_0F_66H: m = "cvtpi2pd"; break;
		case X86_0F_F2H: m = "cvtsi2sd"; break;
		case X86_0F_F3H: m = "cvtsi2ss"; break;
		default: disasm_err(p); break main;
		}
		if (p.mode >= DisasmMode.File)
			disasm_push_str(p, m);
		x86_modrm(p, X86_WIDTH_XMM, X86_DIR_REG);
		break;
	case 0x2B: // MOVNTPS/MOVNTPD R/M, REG
		const(char) *m = void;
		switch (x86_0f_select(p)) {
		case X86_0F_NONE: m = "movntps"; break;
		case X86_0F_66H: m = "movntpd"; break;
		default: disasm_err(p); break main;
		}
		if (p.mode >= DisasmMode.File)
			disasm_push_str(p, m);
		x86_modrm(p, X86_WIDTH_XMM, X86_DIR_MEM);
		break;
	case 0x2C: // CVTTPS2PI/CVTTPD2PI/CVTTSD2SI/CVTTSS2SI
		ubyte modrm = *p.addru8;
		++p.addr;
		switch (x86_0f_select(p)) {
		case X86_0F_NONE:
			if (p.mode >= DisasmMode.File) {
				disasm_push_str(p, "cvttps2pi");
				disasm_push_reg(p,
					x86_modrm_reg(p, modrm, X86_WIDTH_MM));
			}
			break;
		case X86_0F_66H:
			if (p.mode >= DisasmMode.File) {
				disasm_push_str(p, "cvttpd2pi");
				disasm_push_reg(p,
					x86_modrm_reg(p, modrm, X86_WIDTH_MM));
			}
			break;
		case X86_0F_F2H:
			if (p.mode >= DisasmMode.File) {
				disasm_push_str(p, "cvttsd2si");
				disasm_push_reg(p,
					x86_modrm_reg(p, modrm, X86_WIDTH_WIDE));
			}
			break;
		case X86_0F_F3H:
			if (p.mode >= DisasmMode.File) {
				disasm_push_str(p, "cvttss2si");
				disasm_push_reg(p,
					x86_modrm_reg(p, modrm, X86_WIDTH_WIDE));
			}
			break;
		default: disasm_err(p); break main;
		}
		x86_modrm_rm(p, modrm, X86_WIDTH_XMM);
		break;
	case 0x2D: // CVTPS2PI/CVTPD2PI/CVTSD2SI/CVTSS2SI
		ubyte modrm = *p.addru8;
		++p.addr;
		switch (x86_0f_select(p)) {
		case X86_0F_NONE:
			if (p.mode >= DisasmMode.File) {
				disasm_push_str(p, "cvtps2pi");
				disasm_push_reg(p,
					x86_modrm_reg(p, modrm, X86_WIDTH_MM));
			}
			break;
		case X86_0F_66H:
			if (p.mode >= DisasmMode.File) {
				disasm_push_str(p, "cvtpd2pi");
				disasm_push_reg(p,
					x86_modrm_reg(p, modrm, X86_WIDTH_MM));
			}
			break;
		case X86_0F_F2H:
			if (p.mode >= DisasmMode.File) {
				disasm_push_str(p, "cvtsd2si");
				disasm_push_reg(p,
					x86_modrm_reg(p, modrm, X86_WIDTH_WIDE));
			}
			break;
		case X86_0F_F3H:
			if (p.mode >= DisasmMode.File) {
				disasm_push_str(p, "cvtss2si");
				disasm_push_reg(p,
					x86_modrm_reg(p, modrm, X86_WIDTH_WIDE));
			}
			break;
		default: disasm_err(p); break main;
		}
		x86_modrm_rm(p, modrm, X86_WIDTH_XMM);
		break;
	case 0x2E: // UCOMISS/UCOMISD
		const(char) *m = void;
		switch (x86_0f_select(p)) {
		case X86_0F_NONE: m = "ucomiss"; break;
		case X86_0F_66H: m = "ucomisd"; break;
		default: disasm_err(p); break main;
		}
		if (p.mode >= DisasmMode.File)
			disasm_push_str(p, m);
		x86_modrm(p, X86_WIDTH_XMM, X86_DIR_REG);
		break;
	case 0x2F: // COMISS/COMISD
		const(char) *m = void;
		switch (x86_0f_select(p)) {
		case X86_0F_NONE: m = "comiss"; break;
		case X86_0F_66H: m = "comisd"; break;
		default: disasm_err(p); break main;
		}
		if (p.mode >= DisasmMode.File)
			disasm_push_str(p, m);
		x86_modrm(p, X86_WIDTH_XMM, X86_DIR_REG);
		break;
	case 0x30: // WRMSR
		if (p.mode >= DisasmMode.File)
			disasm_push_str(p, "wrmsr");
		break;
	case 0x31: // RDTSC
		if (p.mode >= DisasmMode.File)
			disasm_push_str(p, "rdtsc");
		break;
	case 0x32: // RDMSR
		if (p.mode >= DisasmMode.File)
			disasm_push_str(p, "rdmsr");
		break;
	case 0x33: // RDPMC
		if (p.mode >= DisasmMode.File)
			disasm_push_str(p, "rdpmc");
		break;
	case 0x34: // SYSENTER
		if (p.mode >= DisasmMode.File)
			disasm_push_str(p, "sysenter");
		break;
	case 0x35: // SYSEXIT
		if (p.mode >= DisasmMode.File)
			disasm_push_str(p, "sysexit");
		break;
	case 0x37: // GETSEC
		if (p.mode >= DisasmMode.File)
			disasm_push_str(p, "getsec");
		break;
	case 0x38: // 3-byte opcode
		x86_0f_38h(p);
		break;
	case 0x3A: // 3-byte-opcode
		x86_0f_3Ah(p);
		break;
	case 0x40: // CMOVO
		if (p.mode >= DisasmMode.File)
			disasm_push_str(p, "cmovo");
		x86_modrm(p, X86_WIDTH_WIDE, X86_DIR_REG);
		break;
	case 0x41: // CMOVNO
		if (p.mode >= DisasmMode.File)
			disasm_push_str(p, "cmovno");
		x86_modrm(p, X86_WIDTH_WIDE, X86_DIR_REG);
		break;
	case 0x42: // CMOVB
		if (p.mode >= DisasmMode.File)
			disasm_push_str(p, "cmovb");
		x86_modrm(p, X86_WIDTH_WIDE, X86_DIR_REG);
		break;
	case 0x43: // CMOVAE
		if (p.mode >= DisasmMode.File)
			disasm_push_str(p, "cmovae");
		x86_modrm(p, X86_WIDTH_WIDE, X86_DIR_REG);
		break;
	case 0x44: // CMOVE
		if (p.mode >= DisasmMode.File)
			disasm_push_str(p, "cmove");
		x86_modrm(p, X86_WIDTH_WIDE, X86_DIR_REG);
		break;
	case 0x45: // CMOVNE
		if (p.mode >= DisasmMode.File)
			disasm_push_str(p, "cmovne");
		x86_modrm(p, X86_WIDTH_WIDE, X86_DIR_REG);
		break;
	case 0x46: // CMOVBE
		if (p.mode >= DisasmMode.File)
			disasm_push_str(p, "cmovbe");
		x86_modrm(p, X86_WIDTH_WIDE, X86_DIR_REG);
		break;
	case 0x47: // CMOVA
		if (p.mode >= DisasmMode.File)
			disasm_push_str(p, "cmova");
		x86_modrm(p, X86_WIDTH_WIDE, X86_DIR_REG);
		break;
	case 0x48: // CMOVS
		if (p.mode >= DisasmMode.File)
			disasm_push_str(p, "cmovs");
		x86_modrm(p, X86_WIDTH_WIDE, X86_DIR_REG);
		break;
	case 0x49: // CMOVNS
		if (p.mode >= DisasmMode.File)
			disasm_push_str(p, "cmovns");
		x86_modrm(p, X86_WIDTH_WIDE, X86_DIR_REG);
		break;
	case 0x4A: // CMOVP
		if (p.mode >= DisasmMode.File)
			disasm_push_str(p, "cmovp");
		x86_modrm(p, X86_WIDTH_WIDE, X86_DIR_REG);
		break;
	case 0x4B: // CMOVNP
		if (p.mode >= DisasmMode.File)
			disasm_push_str(p, "cmovnp");
		x86_modrm(p, X86_WIDTH_WIDE, X86_DIR_REG);
		break;
	case 0x4C: // CMOVL
		if (p.mode >= DisasmMode.File)
			disasm_push_str(p, "cmovl");
		x86_modrm(p, X86_WIDTH_WIDE, X86_DIR_REG);
		break;
	case 0x4D: // CMOVNL
		if (p.mode >= DisasmMode.File)
			disasm_push_str(p, "cmovnl");
		x86_modrm(p, X86_WIDTH_WIDE, X86_DIR_REG);
		break;
	case 0x4E: // CMOVLE
		if (p.mode >= DisasmMode.File)
			disasm_push_str(p, "cmovle");
		x86_modrm(p, X86_WIDTH_WIDE, X86_DIR_REG);
		break;
	case 0x4F: // CMOVNLE
		if (p.mode >= DisasmMode.File)
			disasm_push_str(p, "cmovnle");
		x86_modrm(p, X86_WIDTH_WIDE, X86_DIR_REG);
		break;
	case 0x50: // MOVMSKPS/MOVMSKPD
		const(char) *m = void;
		switch (x86_0f_select(p)) {
		case X86_0F_NONE: m = "movmskps"; break;
		case X86_0F_66H: m = "movmskpd"; break;
		default: disasm_err(p); break main;
		}
		ubyte modrm = *p.addru8;
		++p.addrv;
		if ((modrm & RM_MOD) != RM_MOD_11) {
			disasm_err(p);
			break;
		}
		if (p.mode >= DisasmMode.File) {
			disasm_push_x8(p, modrm);
			disasm_push_str(p, m);
			disasm_push_reg(p,
				x86_modrm_reg(p, modrm, X86_WIDTH_WIDE));
			disasm_push_reg(p,
				x86_modrm_reg(p, modrm << 3, X86_WIDTH_XMM));
		}
		break;
	case 0x51: // SQRTPS/SQRTPD/SQRTSD/SQRTSS
		const(char) *m = void;
		switch (x86_0f_select(p)) {
		case X86_0F_NONE: m = "sqrtps"; break;
		case X86_0F_66H: m = "sqrtpd"; break;
		case X86_0F_F2H: m = "sqrtsd"; break;
		case X86_0F_F3H: m = "sqrtss"; break;
		default: disasm_err(p); break main;
		}
		if (p.mode >= DisasmMode.File)
			disasm_push_str(p, m);
		x86_modrm(p, X86_WIDTH_XMM, X86_DIR_REG);
		break;
	case 0x52: // RSQRTPS/RSQRTSS
		const(char) *m = void;
		switch (x86_0f_select(p)) {
		case X86_0F_NONE: m = "rsqrtps"; break;
		case X86_0F_F3H: m = "rsqrtss"; break;
		default: disasm_err(p); break main;
		}
		if (p.mode >= DisasmMode.File)
			disasm_push_str(p, m);
		x86_modrm(p, X86_WIDTH_XMM, X86_DIR_REG);
		break;
	case 0x53: // RCPPS/RCPSS
		const(char) *m = void;
		switch (x86_0f_select(p)) {
		case X86_0F_NONE: m = "rcpps"; break;
		case X86_0F_F3H: m = "rcpss"; break;
		default: disasm_err(p); break main;
		}
		if (p.mode >= DisasmMode.File)
			disasm_push_str(p, m);
		x86_modrm(p, X86_WIDTH_XMM, X86_DIR_REG);
		break;
	case 0x54: // ANDPS/ANDPD
		const(char) *m = void;
		switch (x86_0f_select(p)) {
		case X86_0F_NONE: m = "andps"; break;
		case X86_0F_66H: m = "andpd"; break;
		default: disasm_err(p); break main;
		}
		if (p.mode >= DisasmMode.File)
			disasm_push_str(p, m);
		x86_modrm(p, X86_WIDTH_XMM, X86_DIR_REG);
		break;
	case 0x55: // ANDNPS/ANDNPD
		const(char) *m = void;
		switch (x86_0f_select(p)) {
		case X86_0F_NONE: m = "andnps"; break;
		case X86_0F_66H: m = "andnpd"; break;
		default: disasm_err(p); break main;
		}
		if (p.mode >= DisasmMode.File)
			disasm_push_str(p, m);
		x86_modrm(p, X86_WIDTH_XMM, X86_DIR_REG);
		break;
	case 0x56: // ORPS/ORPD
		const(char) *m = void;
		switch (x86_0f_select(p)) {
		case X86_0F_NONE: m = "orps"; break;
		case X86_0F_66H: m = "orpd"; break;
		default: disasm_err(p); break main;
		}
		if (p.mode >= DisasmMode.File)
			disasm_push_str(p, m);
		x86_modrm(p, X86_WIDTH_XMM, X86_DIR_REG);
		break;
	case 0x57: // XORPS/XORPD
		const(char) *m = void;
		switch (x86_0f_select(p)) {
		case X86_0F_NONE: m = "xorps"; break;
		case X86_0F_66H: m = "xorpd"; break;
		default: disasm_err(p); break main;
		}
		if (p.mode >= DisasmMode.File)
			disasm_push_str(p, m);
		x86_modrm(p, X86_WIDTH_XMM, X86_DIR_REG);
		break;
	case 0x58: // ADDPS/ADDPD/ADDSD/ADDSS
		const(char) *m = void;
		switch (x86_0f_select(p)) {
		case X86_0F_NONE: m = "addps"; break;
		case X86_0F_66H: m = "addpd"; break;
		case X86_0F_F2H: m = "addsd"; break;
		case X86_0F_F3H: m = "addss"; break;
		default: disasm_err(p); break main;
		}
		if (p.mode >= DisasmMode.File)
			disasm_push_str(p, m);
		x86_modrm(p, X86_WIDTH_XMM, X86_DIR_REG);
		break;
	case 0x59: // MULPS/MULPD/MULSD/MULSS
		const(char) *m = void;
		switch (x86_0f_select(p)) {
		case X86_0F_NONE: m = "mulps"; break;
		case X86_0F_66H: m = "mulpd"; break;
		case X86_0F_F2H: m = "mulsd"; break;
		case X86_0F_F3H: m = "mulss"; break;
		default: disasm_err(p); break main;
		}
		if (p.mode >= DisasmMode.File)
			disasm_push_str(p, m);
		x86_modrm(p, X86_WIDTH_XMM, X86_DIR_REG);
		break;
	case 0x5A: // CVTPS2PD/CVTPD2PS/CVTSD2SS/CVTSS2SD
		const(char) *m = void;
		switch (x86_0f_select(p)) {
		case X86_0F_NONE: m = "cvtps2pd"; break;
		case X86_0F_66H: m = "cvtpd2ps"; break;
		case X86_0F_F2H: m = "cvtsd2ss"; break;
		case X86_0F_F3H: m = "cvtss2sd"; break;
		default: disasm_err(p); break main;
		}
		if (p.mode >= DisasmMode.File)
			disasm_push_str(p, m);
		x86_modrm(p, X86_WIDTH_XMM, X86_DIR_REG);
		break;
	case 0x5B: // CVTDQ2PS/CVTPS2DQ/CVTTPS2DQ
		const(char) *m = void;
		switch (x86_0f_select(p)) {
		case X86_0F_NONE: m = "cvtdq2ps"; break;
		case X86_0F_66H: m = "cvtps2dq"; break;
		case X86_0F_F3H: m = "cvttps2dq"; break;
		default: disasm_err(p); break main;
		}
		if (p.mode >= DisasmMode.File)
			disasm_push_str(p, m);
		x86_modrm(p, X86_WIDTH_XMM, X86_DIR_REG);
		break;
	case 0x5C: // SUBPS/SUBPD/SUBSD/SUBSS
		const(char) *m = void;
		switch (x86_0f_select(p)) {
		case X86_0F_NONE: m = "subps"; break;
		case X86_0F_66H: m = "subpd"; break;
		case X86_0F_F2H: m = "subsd"; break;
		case X86_0F_F3H: m = "subss"; break;
		default: disasm_err(p); break main;
		}
		if (p.mode >= DisasmMode.File)
			disasm_push_str(p, m);
		x86_modrm(p, X86_WIDTH_XMM, X86_DIR_REG);
		break;
	case 0x5D: // MINPS/MINPD/MINSD/MINSS
		const(char) *m = void;
		switch (x86_0f_select(p)) {
		case X86_0F_NONE: m = "minps"; break;
		case X86_0F_66H: m = "minpd"; break;
		case X86_0F_F2H: m = "minsd"; break;
		case X86_0F_F3H: m = "minss"; break;
		default: disasm_err(p); break main;
		}
		if (p.mode >= DisasmMode.File)
			disasm_push_str(p, m);
		x86_modrm(p, X86_WIDTH_XMM, X86_DIR_REG);
		break;
	case 0x5E: // DIVPS/DIVPD/DIVSD/DIVSS
		const(char) *m = void;
		switch (x86_0f_select(p)) {
		case X86_0F_NONE: m = "divps"; break;
		case X86_0F_66H: m = "divpd"; break;
		case X86_0F_F2H: m = "divsd"; break;
		case X86_0F_F3H: m = "divss"; break;
		default: disasm_err(p); break main;
		}
		if (p.mode >= DisasmMode.File)
			disasm_push_str(p, m);
		x86_modrm(p, X86_WIDTH_XMM, X86_DIR_REG);
		break;
	case 0x5F: // MAXPS/MAXPD/MAXSS/MAXSD
		const(char) *m = void;
		switch (x86_0f_select(p)) {
		case X86_0F_NONE: m = "maxps"; break;
		case X86_0F_66H: m = "maxpd"; break;
		case X86_0F_F2H: m = "maxss"; break;
		case X86_0F_F3H: m = "maxsd"; break;
		default: disasm_err(p); break main;
		}
		if (p.mode >= DisasmMode.File)
			disasm_push_str(p, m);
		x86_modrm(p, X86_WIDTH_XMM, X86_DIR_REG);
		break;
	case 0xA2: // CPUID
		if (p.mode >= DisasmMode.File)
			disasm_push_str(p, "cpuid");
		break;
	default:
		disasm_err(p);
	}
}

void x86_0f_38h(ref disasm_params_t params) {
	
}

void x86_0f_3Ah(ref disasm_params_t params) {
	
}

enum PrefixReg {
	None, CS, DS, ES, FS, GS, SS
}

enum : ubyte {
	RM_MOD_00 =   0,	/// MOD 00, Memory Mode, no displacement
	RM_MOD_01 =  64,	/// MOD 01, Memory Mode, 8-bit displacement
	RM_MOD_10 = 128,	/// MOD 10, Memory Mode, 16-bit displacement
	RM_MOD_11 = 192,	/// MOD 11, Register Mode
	RM_MOD = RM_MOD_11,	/// Used for masking the MOD bits (11 000 000)

	RM_REG_000 =  0,	/// AL/AX
	RM_REG_001 =  8,	/// CL/CX
	RM_REG_010 = 16,	/// DL/DX
	RM_REG_011 = 24,	/// BL/BX
	RM_REG_100 = 32,	/// AH/SP
	RM_REG_101 = 40,	/// CH/BP
	RM_REG_110 = 48,	/// DH/SI
	RM_REG_111 = 56,	/// BH/DI
	RM_REG = RM_REG_111,	/// Used for masking the REG bits (00 111 000)

	RM_RM_000 = 0,	/// R/M 000 bits
	RM_RM_001 = 1,	/// R/M 001 bits
	RM_RM_010 = 2,	/// R/M 010 bits
	RM_RM_011 = 3,	/// R/M 011 bits
	RM_RM_100 = 4,	/// R/M 100 bits
	RM_RM_101 = 5,	/// R/M 101 bits
	RM_RM_110 = 6,	/// R/M 110 bits
	RM_RM_111 = 7,	/// R/M 111 bits
	RM_RM = RM_RM_111,	/// Used for masking the R/M bits (00 000 111)

	SIB_SCALE_00 = RM_MOD_00,	/// SCALE 00, *1
	SIB_SCALE_01 = RM_MOD_01,	/// SCALE 01, *2
	SIB_SCALE_10 = RM_MOD_10,	/// SCALE 10, *4
	SIB_SCALE_11 = RM_MOD_11,	/// SCALE 11, *8
	SIB_SCALE = SIB_SCALE_11,	/// Scale filter

	SIB_INDEX_000 = RM_REG_000,	/// INDEX 000, EAX
	SIB_INDEX_001 = RM_REG_001,	/// INDEX 001, ECX
	SIB_INDEX_010 = RM_REG_010,	/// INDEX 010, EDX
	SIB_INDEX_011 = RM_REG_011,	/// INDEX 011, EBX
	SIB_INDEX_100 = RM_REG_100,	/// INDEX 100, (special override)
	SIB_INDEX_101 = RM_REG_101,	/// INDEX 101, EBP
	SIB_INDEX_110 = RM_REG_110,	/// INDEX 110, ESI
	SIB_INDEX_111 = RM_REG_111,	/// INDEX 111, EDI
	SIB_INDEX = RM_REG,	/// Index filter

	SIB_BASE_000 = RM_RM_000,	/// BASE 000, EAX
	SIB_BASE_001 = RM_RM_001,	/// BASE 001, ECX
	SIB_BASE_010 = RM_RM_010,	/// BASE 010, EDX
	SIB_BASE_011 = RM_RM_011,	/// BASE 011, EBX
	SIB_BASE_100 = RM_RM_100,	/// BASE 100, ESP
	SIB_BASE_101 = RM_RM_101,	/// BASE 101, (special override)
	SIB_BASE_110 = RM_RM_110,	/// BASE 110, ESI
	SIB_BASE_111 = RM_RM_111,	/// BASE 111, EDI
	SIB_BASE = RM_RM,	/// Base filter
}

// Prefix combos for 0F
package enum {
	X86_0F_NONE,
	X86_0F_66H,
	X86_0F_F2H,
	X86_0F_F3H,
	X86_0F_F266H,
}

// ModR/M register width
package enum {
	X86_WIDTH_NONE,	/// 8/16-bit registers
	X86_WIDTH_WIDE,	/// 32/64-bit extended registers (i386/amd64)
	X86_WIDTH_MM,	/// 80-bit MM registers (MMX)
	X86_WIDTH_XMM,	/// 128-bit XMM registers (SSE)
	X86_WIDTH_YMM,	/// 256-bit YMM registers (AVX)
	X86_WIDTH_ZMM,	/// 512-bit ZMM registers (AVX-512)
}
// ModR/M Direction
package enum {
	X86_DIR_MEM,	/// Destination: Memory, Source: REG
	X86_DIR_REG	/// Destination: REG, Source: Memory
}

/// (Internal) Function to determine if opcode has WIDE bit set
/// Params: op = Opcode
int X86_OP_WIDE(int op) { return op & 1; }
/// (Internal) Function to determine if opcode has DIRECTION bit set
/// Params: op = Opcode
int X86_OP_DIR(int op)  { return op & 2; }

/// (Internal) Fetch variable 32-bit immediate, affected by operand prefix.
/// Then if it's the case, fetch and push a 16-bit immediate instead.
/// Modifies memory pointer.
/// Params: p = disassembler structure
void x86_vu32imm(ref disasm_params_t p) {
	if (p.x86.pf_operand) { // 16-bit
		if (p.mode >= DisasmMode.File) {
			disasm_push_x16(p, *p.addru16);
			disasm_push_imm(p, *p.addru16);
		}
		p.addrv += 2;
	} else { // Normal mode 32-bit
		if (p.mode >= DisasmMode.File) {
			disasm_push_x32(p, *p.addru32);
			disasm_push_imm(p, *p.addru32);
		}
		p.addrv += 4;
	}
}

/// (Internal) Fetch variable 32-bit of memory type, affected by address prefix.
/// Then if it's the case, fetch and push a 16-bit memory type instead.
/// Does not account for SEGREG. Modifies memory pointer.
/// Params: p = disassembler structure
void x86_vu32mem(ref disasm_params_t p) {
	if (p.x86.pf_address) { // 16-bit
		if (p.mode >= DisasmMode.File) {
			disasm_push_x16(p, *p.addru16);
			disasm_push_mem(p, *p.addru16);
		}
		p.addrv += 2;
	} else { // Normal mode 32-bit
		if (p.mode >= DisasmMode.File) {
			disasm_push_x32(p, *p.addru32);
			disasm_push_mem(p, *p.addru32);
		}
		p.addrv += 4;
	}
}

/// (Internal) Returns a number depending on the set prefixes for the 2-byte
/// instructions (0FH). Useful for a switch per-instruction. Does not check
/// for errors. Unconfirmed with the official order it's supposed to have.
///
/// Enumeration mapping
/// X86_0F_NONE  (0): No prefixes
/// X86_0F_66H   (1): 66H
/// X86_0F_F2H   (2): F2H
/// X86_0F_F3H   (3): F3H
/// X86_0F_F266H (4): 66H+F2H
///
/// Params: p = Disassembler parameters
///
/// Returns: Selection number (see Enumeration mapping)
package
int x86_0f_select(ref disasm_params_t p) {
	switch (p.x86.group1) {
	case 0xF2: return p.x86.pf_operand ? X86_0F_F266H : X86_0F_F2H;
	case 0xF3: return X86_0F_F3H;
	default:   return p.x86.pf_operand ? X86_0F_66H : X86_0F_NONE;
	}
}

/// (Internal) Return a segment register depending on its opcode.
/// Returns an empty string if unset.
/// Params: segreg = Byte opcode
/// Returns: Segment register string
const(char) *x86_segstr(int segreg) {
	const(char) *s = void;
	with (PrefixReg)
	switch (segreg) {
	case CS: s = "cs:"; break;
	case DS: s = "ds:"; break;
	case ES: s = "es:"; break;
	case FS: s = "fs:"; break;
	case GS: s = "gs:"; break;
	case SS: s = "ss:"; break;
	default: s = ""; break;
	}
	return s;
}

const(char) *x87_ststr(ref disasm_params_t p, int index) {
	const(char) *st = void;
	with (DisasmSyntax)
	switch (p.style) {
	case Att:
		switch (index) {
		case 0: st = "%st"; break;
		case 1: st = "%st(1)"; break;
		case 2: st = "%st(2)"; break;
		case 3: st = "%st(3)"; break;
		case 4: st = "%st(4)"; break;
		case 5: st = "%st(5)"; break;
		case 6: st = "%st(6)"; break;
		case 7: st = "%st(7)"; break;
		default: st = "%st(?)";
		}
		break;
	case Nasm:
		switch (index) {
		case 0: st = "st0"; break;
		case 1: st = "st1"; break;
		case 2: st = "st2"; break;
		case 3: st = "st3"; break;
		case 4: st = "st4"; break;
		case 5: st = "st5"; break;
		case 6: st = "st6"; break;
		case 7: st = "st7"; break;
		default: st = "st?";
		}
		break;
	default:
		switch (index) {
		case 0: st = "st"; break;
		case 1: st = "st(1)"; break;
		case 2: st = "st(2)"; break;
		case 3: st = "st(3)"; break;
		case 4: st = "st(4)"; break;
		case 5: st = "st(5)"; break;
		case 6: st = "st(6)"; break;
		case 7: st = "st(7)"; break;
		default: st = "st(?)";
		}
	}
	return st;
}

/// (Internal) Process a ModR/M byte automatically.
///
/// This function calls x86_modrm_rm and disasm_push_reg depending on the
/// direction flag. If non-zero (X86_DIR_REG), the reg field is processed
/// first; Otherwise vice versa (X86_DIR_MEM).
///
/// Params:
/// 	p = Disassembler parameters
/// 	width = Register width, see X86_WIDTH_* enumerations
/// 	direction = If set, the registers are the target
void x86_modrm(ref disasm_params_t p, int width, int direction) {
	// 11 111 111
	// || ||| +++- RM
	// || +++----- REG
	// ++--------- MODE
	ubyte modrm = *p.addru8;
	++p.addrv;

	if (direction)
		goto L_REG;

L_RM:
	// Memory regs are only general registers
	x86_modrm_rm(p, modrm, width);
	if (direction) return;

L_REG:
	if (p.mode >= DisasmMode.File)
		disasm_push_reg(p, x86_modrm_reg(p, modrm, width));
	if (direction) goto L_RM;
}

const(char) *x86_modrm_reg(ref disasm_params_t p, int modrm, int width) {
	modrm &= RM_REG;
	//TODO: size_t r = modrm >> 3; // reg index for reg string arrays

	const(char) *reg = void;

	switch (width) {
	case X86_WIDTH_WIDE:
		switch (modrm) {
		case RM_REG_000: reg = "eax"; break;
		case RM_REG_001: reg = "ecx"; break;
		case RM_REG_010: reg = "edx"; break;
		case RM_REG_011: reg = "ebx"; break;
		case RM_REG_100: reg = "esp"; break;
		case RM_REG_101: reg = "ebp"; break;
		case RM_REG_110: reg = "esi"; break;
		case RM_REG_111: reg = "edi"; break;
		default:
		}
		break;
	case X86_WIDTH_MM:
		switch (modrm) {
		case RM_REG_000: reg = "mm0"; break;
		case RM_REG_001: reg = "mm1"; break;
		case RM_REG_010: reg = "mm2"; break;
		case RM_REG_011: reg = "mm3"; break;
		case RM_REG_100: reg = "mm4"; break;
		case RM_REG_101: reg = "mm5"; break;
		case RM_REG_110: reg = "mm6"; break;
		case RM_REG_111: reg = "mm7"; break;
		default:
		}
		break;
	case X86_WIDTH_XMM:
		switch (modrm) {
		case RM_REG_000: reg = "xmm0"; break;
		case RM_REG_001: reg = "xmm1"; break;
		case RM_REG_010: reg = "xmm2"; break;
		case RM_REG_011: reg = "xmm3"; break;
		case RM_REG_100: reg = "xmm4"; break;
		case RM_REG_101: reg = "xmm5"; break;
		case RM_REG_110: reg = "xmm6"; break;
		case RM_REG_111: reg = "xmm7"; break;
		default:
		}
		break;
	default: // X86_MODRM_NONE
		if (p.x86.pf_operand)
			switch (modrm) {
			case RM_REG_000: reg = "ax"; break;
			case RM_REG_001: reg = "cx"; break;
			case RM_REG_010: reg = "dx"; break;
			case RM_REG_011: reg = "bx"; break;
			case RM_REG_100: reg = "sp"; break;
			case RM_REG_101: reg = "bp"; break;
			case RM_REG_110: reg = "si"; break;
			case RM_REG_111: reg = "di"; break;
			default:
			}
		else
			switch (modrm) {
			case RM_REG_000: reg = "al"; break;
			case RM_REG_001: reg = "cl"; break;
			case RM_REG_010: reg = "dl"; break;
			case RM_REG_011: reg = "bl"; break;
			case RM_REG_100: reg = "ah"; break;
			case RM_REG_101: reg = "ch"; break;
			case RM_REG_110: reg = "dh"; break;
			case RM_REG_111: reg = "dl"; break;
			default:
			}
		break;
	}

	return reg;
}

/// (Internal) Process the R/M field automatically
///
/// Params:
/// 	p = Disasm params
/// 	modrm = Modrm byte
/// 	width = Register width
void x86_modrm_rm(ref disasm_params_t p, ubyte modrm, int width) {
	if (p.mode >= DisasmMode.File)
		disasm_push_x8(p, modrm);

	// SIB mode
	if ((modrm & RM_RM) == RM_RM_100 && (modrm & RM_MOD) != RM_MOD_11) {
		x86_sib(p, modrm);
	} else { // ModR/M mode
		// If mode non-reg, R/M field is wide reg as per operating mode
		if ((modrm & RM_MOD) != RM_MOD_11)
			width = X86_WIDTH_WIDE;

		/// segreg for memspec
		const(char) *seg = x86_segstr(p.x86.segreg);
		/// reg for memspec, not operation width!
		const(char) *reg = x86_modrm_reg(p, modrm << 3, width);

		switch (modrm & RM_MOD) {
		case RM_MOD_00:	// Memory Mode, no displacement
			if (p.mode >= DisasmMode.File)
				disasm_push_memsegreg(p, seg, reg);
			break;
		case RM_MOD_01:	// Memory Mode, 8-bit displacement
			if (p.mode >= DisasmMode.File) {
				disasm_push_x8(p, *p.addru8);
				disasm_push_memsegregimm(p, seg, reg, *p.addri8);
			}
			++p.addrv;
			break;
		case RM_MOD_10:	// Memory Mode, 32-bit displacement
			if (p.mode >= DisasmMode.File) {
				disasm_push_x32(p, *p.addru32);
				disasm_push_memsegregimm(p, seg, reg, *p.addri32);
			}
			p.addrv += 4;
			break;
		case RM_MOD_11:	// Register mode
			if (p.mode >= DisasmMode.File) {
				disasm_push_reg(p, reg);
			}
			break;
		default: // Never reached
		}
	}
}

void x86_sib(ref disasm_params_t p, ubyte modrm) {
	// 11 111 111
	// || ||| +++- BASE
	// || +++----- INDEX
	// ++--------- SCALE
	ubyte sib = *p.addru8;
	++p.addrv;
	int scale = 1 << (sib >> 6); // 2 ^ (0b11_000_000 >> 6)

	const(char)* base = void, index = void, seg = void;

	if (p.mode >= DisasmMode.File) {
		disasm_push_x8(p, sib);
		seg = x86_segstr(p.x86.segreg);
	}

	switch (modrm & RM_MOD) { // Mode
	case RM_MOD_00:
		if ((sib & SIB_BASE) == SIB_BASE_101) { // INDEX * SCALE + D32
			if (p.mode >= DisasmMode.File) {
				disasm_push_x32(p, *p.addru32);
				if ((sib & SIB_INDEX) == SIB_INDEX_100)
					disasm_push_x86_sib_mod00_index100_base101(p,
						seg, *p.addru32);
				else
					disasm_push_x86_sib_mod00_base101(p, seg,
						x86_modrm_reg(p, sib, X86_WIDTH_WIDE),
						scale, *p.addru32);
			}
			p.addrv += 4;
		} else { // BASE32 + INDEX * SCALE
			if (p.mode < DisasmMode.File) return;
			base = x86_modrm_reg(p, sib << 3, X86_WIDTH_WIDE);
			if ((sib & SIB_INDEX) == SIB_INDEX_100)
				disasm_push_x86_sib_mod00_index100(p, seg, base);
			else
				disasm_push_x86_sib_mod00(p, seg, base,
					x86_modrm_reg(p, sib, X86_WIDTH_WIDE),
					scale);
		}
		return;
	case RM_MOD_01:
		if ((sib & SIB_INDEX) == SIB_INDEX_100) { // B32 + D8
			if (p.mode >= DisasmMode.File) {
				disasm_push_x8(p, *p.addru8);
				disasm_push_x86_sib_mod01_index100(p,
					seg,
					x86_modrm_reg(p, sib << 3, X86_WIDTH_WIDE),
					*p.addru8);
			}
			++p.addrv;
		} else { // BASE8 + INDEX * SCALE + DISP32
			if (p.mode >= DisasmMode.File) {
				disasm_push_x32(p, *p.addru32);
				base = x86_modrm_reg(p, sib << 3, X86_WIDTH_NONE);
				index = x86_modrm_reg(p, sib, X86_WIDTH_WIDE);
				disasm_push_x86_sib_mod01(p,
					seg, base, index, scale, *p.addru32);
			}
			p.addrv += 4;
		}
		break;
	case RM_MOD_10:
		if (p.mode >= DisasmMode.File) {
			disasm_push_x32(p, *p.addru32);
			base = x86_modrm_reg(p, sib << 3, X86_WIDTH_WIDE);
			if ((sib & SIB_INDEX) == SIB_INDEX_100) { // BASE32 + DISP32
				disasm_push_x86_sib_mod01_index100(p,
				seg, base, *p.addru32);
			} else { // BASE32 + INDEX * SCALE + DISP32
				index = x86_modrm_reg(p, sib, X86_WIDTH_WIDE);
				disasm_push_x86_sib_mod01(p,
					seg, base, index, scale, *p.addru32);
			}
		}
		p.addrv += 4;
		break;
	default: // never
	}
}
