/**
 * Object/image loader.
 *
 * The goal of the object/image loader is being able to obtain information
 * from obj/pdb/image files such as:
 * - Object Type;
 * - Machine architecture;
 * - Symbols;
 * - Debugging information (types, etc.);
 * - And a few extras for dumping purposes.
 *
 * Currently, the entire file is loaded in memory out of keeping the
 * implementation simple. Future could see MMI/O usage, or a pure "disk" mode.
 *
 * License: BSD 3-Clause
 */
module adbg.debugger.obj.loader;

import core.stdc.stdio;
import adbg.debugger.disasm.disasm : DisasmISA, adbg_dasm_endian; // ISA translation
import adbg.debugger.file.objs;
import adbg.os.err;

extern (C):

/*enum {	// adbg_obj_load flags
	/// Leave file in memory, used by dumper
	LOADER_MEM = 0x1000,
}*/

/*private enum {	// obj_info_t internal flags
	/// ISA is MSB
	LOADER_INTERNAL_MSB	= 0x0000_0001,
	/// Section info is loaded
	/// Internal buffer is allocated
	LOADER_INTERNAL_BUF_ALLOC	= 0x4000_0000,
	/// Structure is loaded included header
	LOADER_INTERNAL_OBJ_LOADED	= 0x8000_0000
}*/

/// File operation error code
enum ObjError {
	/// Operating was a success, so no error occurred
	None,
	/// File operation error (e.g. can't seek, can't read)
	FileOperation,
	/// Format not supported
	FormatUnsupported,
	/// Requested action/feature is not available
	Unavailable,
}

/// Loaded, or specified, executable/object format
enum ObjType {
	/// Mysterious file format
	Unknown,
	/// Mark Zbikowski format
	MZ,
	/// New Executable format
	NE,
	/// Linked Executable/LX format
	LE,
	/// Portable Executable format
	PE,
	/// Executable and Linkable Format
	ELF,
	/// Mach Object format
	MachO,
	/// Microsoft Program Database format
	PDB,
	/// Microsoft Debug format
	DBG,
}

/// Symbol entry
struct obj_symbol_t {
	size_t address;
	char *name;
}

/// Executable file information and headers
struct obj_info_t { align(1):
	//
	// File fields
	//

	union {
		void   *buf;	/// (Internal)
		char   *bufc8;	/// (Internal)
		ubyte  *bufu8;	/// (Internal)
		ushort *bufu16;	/// (Internal)
		uint   *bufu32;	/// (Internal)
		ulong  *bufu64;	/// (Internal)
	}
	/// File handle, used internally. Copied from supplied FILE structure.
	FILE *handle;
	/// File size.
	uint size;

	//
	// Object fields
	//

	/// File type, populated by the respective loading function.
	ObjType type;
	/// Image's ISA translated value for disasm
	DisasmISA isa;
	/// A copy of the original loading flags
	int oflags;
	/// Number of symbols loaded
//	uint nsymbols;
	/// Symbols table
//	obj_symbol_t *symbols;

	//
	// Object-specific pointers
	//

	union {
		PE_META pe;
	}

	//
	// Internals
	//

	/// Internal status (bits)
	/// 0: endian (0=little, 1=big)
	int internal;
	/// Offset to header data. PE uses this.
	int offset;
}

int adbg_obj_open(const(char*) path, obj_info_t *info, int flags) {
	info.handle = fopen(path, "rb");

	if (info.handle == null)
		return 1;

	return adbg_obj_load(info.handle, info, flags);
}

/// Load object from file handle.
///
/// Flags are used to indicate what to load. The function is responsible of
/// allocating data depending on the requested information. The headers
/// are always loaded.
///
/// NOTICE: For the moment being, the LOADER_FILE_MEM is default. No other
/// modes have been implemented.
///
/// If you see an executable image larger than 2 GiB, do let me know.
/// Params:
/// 	file = Opened FILE
/// 	info = obj_info_t structure
/// 	flags = Load options
/// Returns: OS error code or a FileError on error
int adbg_obj_load(FILE *file, obj_info_t *info, int flags) {
	import core.stdc.config : c_long;
	import core.stdc.stdlib : malloc;

	if (file == null)
		return ObjError.FileOperation;

	info.handle = file;
	info.oflags = flags;

	// File size

	if (fseek(info.handle, 0, SEEK_END))
		return ObjError.FileOperation;
	info.size = cast(uint)ftell(info.handle);
	if (info.size == 0xFFFF_FFFF) // -1
		return ObjError.FileOperation;
	if (fseek(info.handle, 0, SEEK_SET))
		return ObjError.FileOperation;

	// Allocate and read

	info.buf = malloc(info.size);
	if (info.buf == null)
		return ObjError.FileOperation;
	if (fread(info.buf, info.size, 1, info.handle) == 0)
		return ObjError.FileOperation;

	// Auto-detection

	file_sig_t sig = void; // for conveniance

	int e = void;
	switch (*cast(ushort*)info.buf) {
	case SIG_MZ:
		uint hdrloc = *cast(uint*)(info.buf + 0x3c);
		if (hdrloc == 0)
			return ObjError.FileOperation;
		if (hdrloc >= info.size - 4)
			return ObjError.FileOperation;
		sig.u32 = *cast(uint*)(info.buf + hdrloc);
		switch (sig.u16[0]) {
		case SIG_PE:
			if (sig.u16[1]) // "PE\0\0"
				return ObjError.FormatUnsupported;
			info.type = ObjType.PE;
			info.offset = hdrloc;
			e = adbg_obj_pe_load(info, flags);
			break;
		default: // MZ
			return ObjError.FormatUnsupported;
		}
		break;
	default:
		return ObjError.FormatUnsupported;
	}

	if (e) return e;

	info.internal = adbg_dasm_endian(info.isa);

	return ObjError.None;
}

//TODO: adbg_obj_unload
/*int adbg_obj_unload(obj_info_t *info) {
	
	return 0;
}*/

//ubyte* adbg_obj_load_section(const(char)* sname)

//TODO: adbg_obj_symbol_at_address
/*char* adbg_obj_symbol_at_address(obj_info_t *info, size_t address) {
	
	return null;
}*/

const(char) *adbg_obj_errmsg(ObjError err) {
	with (ObjError)
	final switch (err) {
	case None:	return "None";
	case FileOperation:	return "Could not read, seek, or write to file";
	case FormatUnsupported:	return "Unsupported format";
	case Unavailable:	return "Unavailable";
	}
}

private:

version (LittleEndian) {
	enum ushort SIG_MZ = 0x5A4D;	// "MZ"
	enum ushort SIG_PE = 0x4550;	// "PE"
	enum ushort SIG_ELF_L = 0x4C45; // "EL", low 2-byte
	enum ushort SIG_ELF_H = 0x7F46; // "F\x7F", high 2-byte
} else {
	enum ushort SIG_MZ = 0x4D5A;	// "MZ"
	enum ushort SIG_PE = 0x5045;	// "PE"
	enum ushort SIG_ELF_L = 0x454C; // "EL", low 2-byte
	enum ushort SIG_ELF_H = 0x467F; // "F\x7F", high 2-byte
}

struct file_sig_t { align(1):
	union {
		uint u32;
		char[4] c8;
		ushort[2] u16;
	}
}