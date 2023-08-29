/// PE32 file dumper
///
/// Authors: dd86k <dd@dax.moe>
/// Copyright: © dd86k <dd@dax.moe>
/// License: BSD-3-Clause
module dump.pe;

import core.stdc.stdlib : EXIT_SUCCESS, EXIT_FAILURE;
import adbg.v2.disassembler.core;
import adbg.v2.object.server;
import adbg.v2.object.machines : AdbgMachine;
import adbg.v2.object.format.pe;
import adbg.utils.date : ctime32;
import adbg.utils.uid, adbg.utils.bit;
import common, dumper;

extern (C):

/// Dump PE32 info to stdout.
/// Params: dump = Dump structure
/// Returns: Non-zero on error
int dump_pe(adbg_object_t *o, uint flags) {
	if (flags & DumpOpt.header) {
		if (dump_pe_hdr(o))
			return 1;
		
		// Anonymous objects would be here
		if (o.i.pe.header.SizeOfOptionalHeader) {
			dump_pe_opthdr(o);
			dump_pe_dirs(o);
		}
	}
	
	if (flags & DumpOpt.sections)
		dump_pe_sections(o);
	
	if (flags & DumpOpt.imports)
		dump_pe_imports(o);
	
	if (flags & DumpOpt.debug_)
		dump_pe_debug(o);
	
	if (flags & DumpOpt.disasm)
		dump_pe_disasm(o, flags);
	
	return EXIT_SUCCESS;
}

private:

// Returns true if the machine value is unknown
bool dump_pe_hdr(adbg_object_t *o) {
	dprint_header("Header");
	
	const(char) *str_mach = adbg_object_pe_machine_string(o.i.pe.header.Machine);
	
	if (str_mach == null)
		str_mach = "Unknown";
	
	with (o.i.pe.header) {
	dprint_x32("Machine", Machine, str_mach);
	dprint_u32("NumberOfSections", NumberOfSections);
	dprint_x32("TimeDateStamp", TimeDateStamp, ctime32(TimeDateStamp));
	dprint_x32("PointerToSymbolTable", PointerToSymbolTable);
	dprint_u32("NumberOfSymbols", NumberOfSymbols);
	dprint_u32("SizeOfOptionalHeader", SizeOfOptionalHeader);
	dprint_flags32("Characteristics", Characteristics,
		"RELOCS_STRIPPED".ptr,	PE_CHARACTERISTIC_RELOCS_STRIPPED,
		"EXECUTABLE_IMAGE".ptr,	PE_CHARACTERISTIC_EXECUTABLE_IMAGE,
		"LINE_NUMS_STRIPPED".ptr,	PE_CHARACTERISTIC_LINE_NUMS_STRIPPED,
		"LOCAL_SYMS_STRIPPED".ptr,	PE_CHARACTERISTIC_LOCAL_SYMS_STRIPPED,
		"AGGRESSIVE_WS_TRIM".ptr,	PE_CHARACTERISTIC_AGGRESSIVE_WS_TRIM,
		"LARGE_ADDRESS_AWARE".ptr,	PE_CHARACTERISTIC_LARGE_ADDRESS_AWARE,
		"16BIT_MACHINE".ptr,	PE_CHARACTERISTIC_16BIT_MACHINE,
		"BYTES_REVERSED_LO".ptr,	PE_CHARACTERISTIC_BYTES_REVERSED_LO,
		"32BIT_MACHINE".ptr,	PE_CHARACTERISTIC_32BIT_MACHINE,
		"DEBUG_STRIPPED".ptr,	PE_CHARACTERISTIC_DEBUG_STRIPPED,
		"REMOVABLE_RUN_FROM_SWAP".ptr,	PE_CHARACTERISTIC_REMOVABLE_RUN_FROM_SWAP,
		"NET_RUN_FROM_SWAP".ptr,	PE_CHARACTERISTIC_NET_RUN_FROM_SWAP,
		"SYSTEM".ptr,	PE_CHARACTERISTIC_SYSTEM,
		"DLL".ptr,	PE_CHARACTERISTIC_DLL,
		"UP_SYSTEM_ONLY".ptr,	PE_CHARACTERISTIC_UP_SYSTEM_ONLY,
		"BYTES_REVERSED_HI".ptr,	PE_CHARACTERISTIC_BYTES_REVERSED_HI,
		null);
	}
	
	return str_mach == null;
}

void dump_pe_opthdr(adbg_object_t *o) {
	dprint_header("Optional Header");
	
	// NOTE: Server already checks magic format
	const(char) *str_mag = adbg_object_pe_magic_string(o.i.pe.opt_header.Magic);
	const(char) *str_sys = adbg_object_pe_subsys_string(o.i.pe.opt_header.Subsystem);
	if (str_sys == null)
		str_sys = "Unknown";
	
	// Common in all magic formats
	with (o.i.pe.opt_header) {
	dprint_x16("Magic", Magic, str_mag);
	dprint_u8("MajorLinkerVersion", MajorLinkerVersion);
	dprint_u8("MinorLinkerVersion", MinorLinkerVersion);
	dprint_u32("SizeOfCode", SizeOfCode);
	dprint_u32("SizeOfInitializedData", SizeOfInitializedData);
	dprint_u32("SizeOfUninitializedData", SizeOfUninitializedData);
	dprint_x32("AddressOfEntryPoint", AddressOfEntryPoint);
	dprint_x32("BaseOfCode", BaseOfCode);
	}
	
	switch (o.i.pe.opt_header.Magic) {
	case PE_FMT_32: // 32
		with (o.i.pe.opt_header) {
		dprint_x32("BaseOfData", BaseOfData);
		dprint_x32("ImageBase", ImageBase);
		dprint_u32("SectionAlignment", SectionAlignment);
		dprint_u32("FileAlignment", FileAlignment);
		dprint_u16("MajorOperatingSystemVersion", MajorOperatingSystemVersion);
		dprint_u16("MinorOperatingSystemVersion", MinorOperatingSystemVersion);
		dprint_u16("MajorImageVersion", MajorImageVersion);
		dprint_u16("MinorImageVersion", MinorImageVersion);
		dprint_u16("MajorSubsystemVersion", MajorSubsystemVersion);
		dprint_u16("MinorSubsystemVersion", MinorSubsystemVersion);
		dprint_x32("Win32VersionValue", Win32VersionValue);
		dprint_u32("SizeOfImage", SizeOfImage);
		dprint_u32("SizeOfHeaders", SizeOfHeaders);
		dprint_x32("CheckSum", CheckSum);
		dprint_x16("Subsystem", Subsystem, str_sys);
		dump_pe_opthdr_dllcharacteristics(DllCharacteristics);
		dprint_x32("SizeOfStackReserve", SizeOfStackReserve);
		dprint_x32("SizeOfStackCommit", SizeOfStackCommit);
		dprint_x32("SizeOfHeapReserve", SizeOfHeapReserve);
		dprint_x32("SizeOfHeapCommit", SizeOfHeapCommit);
		dprint_x32("LoaderFlags", LoaderFlags);
		dprint_u32("NumberOfRvaAndSizes", NumberOfRvaAndSizes);
		}
		break;
	case PE_FMT_64: // 64
		with (o.i.pe.opt_header64) {
		dprint_x64("ImageBase", ImageBase);
		dprint_x32("SectionAlignment", SectionAlignment);
		dprint_x32("FileAlignment", FileAlignment);
		dprint_u16("MajorOperatingSystemVersion", MajorOperatingSystemVersion);
		dprint_u16("MinorOperatingSystemVersion", MinorOperatingSystemVersion);
		dprint_u16("MajorImageVersion", MajorImageVersion);
		dprint_u16("MinorImageVersion", MinorImageVersion);
		dprint_u16("MajorSubsystemVersion", MajorSubsystemVersion);
		dprint_u16("MinorSubsystemVersion", MinorSubsystemVersion);
		dprint_x32("Win32VersionValue", Win32VersionValue);
		dprint_u32("SizeOfImage", SizeOfImage);
		dprint_u32("SizeOfHeaders", SizeOfHeaders);
		dprint_x32("CheckSum", CheckSum);
		dprint_u32("Subsystem", Subsystem, str_sys);
		dprint_u64("SizeOfStackReserve", SizeOfStackReserve);
		dprint_u64("SizeOfStackCommit", SizeOfStackCommit);
		dprint_u64("SizeOfHeapReserve", SizeOfHeapReserve);
		dprint_u64("SizeOfHeapCommit", SizeOfHeapCommit);
		dprint_x32("LoaderFlags", LoaderFlags);
		dprint_u32("NumberOfRvaAndSizes", NumberOfRvaAndSizes);
		}
		break;
	case PE_FMT_ROM: // ROM has no flags/directories
		with (o.i.pe.opt_headerrom) {
		dprint_x32("BaseOfData", BaseOfData);
		dprint_x32("BaseOfBss", BaseOfBss);
		dprint_x32("GprMask", GprMask);
		dprint_x32("CprMask[0]", CprMask[0]);
		dprint_x32("CprMask[1]", CprMask[1]);
		dprint_x32("CprMask[2]", CprMask[2]);
		dprint_x32("CprMask[3]", CprMask[3]);
		dprint_x32("GpValue", GpValue);
		}
		break;
	default:
	}
}

void dump_pe_opthdr_dllcharacteristics(ushort DllCharacteristics) {
	dprint_flags16("DllCharacteristics", DllCharacteristics,
		"HIGH_ENTROPY_VA".ptr,	PE_DLLCHARACTERISTICS_HIGH_ENTROPY_VA,
		"DYNAMIC_BASE".ptr,	PE_DLLCHARACTERISTICS_DYNAMIC_BASE,
		"FORCE_INTEGRITY".ptr,	PE_DLLCHARACTERISTICS_FORCE_INTEGRITY,
		"NX_COMPAT".ptr,	PE_DLLCHARACTERISTICS_NX_COMPAT,
		"NO_ISOLATION".ptr,	PE_DLLCHARACTERISTICS_NO_ISOLATION,
		"NO_SEH".ptr,	PE_DLLCHARACTERISTICS_NO_SEH,
		"NO_BIND".ptr,	PE_DLLCHARACTERISTICS_NO_BIND,
		"APPCONTAINER".ptr,	PE_DLLCHARACTERISTICS_APPCONTAINER,
		"WDM_DRIVER".ptr,	PE_DLLCHARACTERISTICS_WDM_DRIVER,
		"GUARD_CF".ptr,	PE_DLLCHARACTERISTICS_GUARD_CF,
		"TERMINAL_SERVER_AWARE".ptr,	PE_DLLCHARACTERISTICS_TERMINAL_SERVER_AWARE,
		null);
}

void dump_pe_dirs(adbg_object_t *o) {
	dprint_columns("Directory", "RVA", "Size");
	
	// ROM
	if (o.i.pe.directory == null)
		return;
	
	with (o.i.pe.directory) {
	dprint_entry32("ExportTable", ExportTable.rva, ExportTable.size);
	dprint_entry32("ImportTable", ImportTable.rva, ImportTable.size);
	dprint_entry32("ResourceTable", ResourceTable.rva, ResourceTable.size);
	dprint_entry32("ExceptionTable", ExceptionTable.rva, ExceptionTable.size);
	dprint_entry32("CertificateTable", CertificateTable.rva, CertificateTable.size);
	dprint_entry32("BaseRelocationTable", BaseRelocationTable.rva, BaseRelocationTable.size);
	dprint_entry32("DebugDirectory", DebugDirectory.rva, DebugDirectory.size);
	dprint_entry32("ArchitectureData", ArchitectureData.rva, ArchitectureData.size);
	dprint_entry32("GlobalPtr", GlobalPtr.rva, GlobalPtr.size);
	dprint_entry32("TLSTable", TLSTable.rva, TLSTable.size);
	dprint_entry32("LoadConfigurationTable", LoadConfigurationTable.rva, LoadConfigurationTable.size);
	dprint_entry32("BoundImportTable", BoundImportTable.rva, BoundImportTable.size);
	dprint_entry32("ImportAddressTable", ImportAddressTable.rva, ImportAddressTable.size);
	dprint_entry32("DelayImport", DelayImport.rva, DelayImport.size);
	dprint_entry32("CLRHeader", CLRHeader.rva, CLRHeader.size);
	dprint_entry32("Reserved", Reserved.rva, Reserved.size);
	}
}

void dump_pe_sections(adbg_object_t *o) {
	dprint_header("Sections");
	
	for (ushort si; si < o.i.pe.header.NumberOfSections; ++si) {
		PE_SECTION_ENTRY *section = &o.i.pe.sections[si];
		
		with (section) {
		dprint_section(si + 1, Name.ptr, 8);
		dprint_x32("VirtualAddress", VirtualAddress);
		dprint_x32("VirtualSize", VirtualSize);
		dprint_x32("PointerToRawData", PointerToRawData);
		dprint_x32("SizeOfRawData", SizeOfRawData);
		dprint_x32("PointerToRelocations", PointerToRelocations);
		dprint_x32("PointerToLinenumbers", PointerToLinenumbers);
		dprint_u16("NumberOfRelocations", NumberOfRelocations);
		dprint_u16("NumberOfLinenumbers", NumberOfLinenumbers);
		//TODO: ALIGN_xBYTES with mask 0x00F00000
		//      0 == "ALIGN_DEFAULT(16)" seen under PEDUMP (1997)
		dprint_flags32("Characteristics", Characteristics,
			"TYPE_DSECT".ptr,	PE_SECTION_CHARACTERISTIC_TYPE_DSECT,
			"TYPE_NOLOAD".ptr,	PE_SECTION_CHARACTERISTIC_TYPE_NOLOAD,
			"TYPE_GROUP".ptr,	PE_SECTION_CHARACTERISTIC_TYPE_GROUP,
			"NO_PAD".ptr,	PE_SECTION_CHARACTERISTIC_NO_PAD,
			"TYPE_COPY".ptr,	PE_SECTION_CHARACTERISTIC_TYPE_COPY,
			"CODE".ptr,	PE_SECTION_CHARACTERISTIC_CODE,
			"INITIALIZED_DATA".ptr,	PE_SECTION_CHARACTERISTIC_INITIALIZED_DATA,
			"UNINITIALIZED_DATA".ptr,	PE_SECTION_CHARACTERISTIC_UNINITIALIZED_DATA,
			"LNK_OTHER".ptr,	PE_SECTION_CHARACTERISTIC_LNK_OTHER,
			"LNK_INFO".ptr,	PE_SECTION_CHARACTERISTIC_LNK_INFO,
			"LNK_REMOVE".ptr,	PE_SECTION_CHARACTERISTIC_LNK_REMOVE,
			"LNK_COMDAT".ptr,	PE_SECTION_CHARACTERISTIC_LNK_COMDAT,
			"MEM_PROTECTED".ptr,	PE_SECTION_CHARACTERISTIC_MEM_PROTECTED,
			"GPREL".ptr,	PE_SECTION_CHARACTERISTIC_GPREL,
			"MEM_PURGEABLE".ptr,	PE_SECTION_CHARACTERISTIC_MEM_PURGEABLE,
			"MEM_16BIT".ptr,	PE_SECTION_CHARACTERISTIC_MEM_16BIT,
			"MEM_LOCKED".ptr,	PE_SECTION_CHARACTERISTIC_MEM_LOCKED,
			"PRELOAD".ptr,	PE_SECTION_CHARACTERISTIC_PRELOAD,
			"LNK_NRELOC_OVFL".ptr,	PE_SECTION_CHARACTERISTIC_LNK_NRELOC_OVFL,
			"MEM_DISCARDABLE".ptr,	PE_SECTION_CHARACTERISTIC_MEM_DISCARDABLE,
			"MEM_NOT_CACHED".ptr,	PE_SECTION_CHARACTERISTIC_MEM_NOT_CACHED,
			"MEM_NOT_PAGED".ptr,	PE_SECTION_CHARACTERISTIC_MEM_NOT_PAGED,
			"MEM_SHARED".ptr,	PE_SECTION_CHARACTERISTIC_MEM_SHARED,
			"MEM_EXECUTE".ptr,	PE_SECTION_CHARACTERISTIC_MEM_EXECUTE,
			"MEM_READ".ptr,	PE_SECTION_CHARACTERISTIC_MEM_READ,
			"MEM_WRITE".ptr,	PE_SECTION_CHARACTERISTIC_MEM_WRITE,
			null);
		}
	}
}

/*void dump_pe_loadconfig(adbg_object_t *obj) {
	
	dump_h1("Load Configuration");
	
	if (obj.pe.loadconfig == null) { // LOAD_CONFIGURATION
		puts("No 
	}
		if (fseek(obj.handle, fo_loadcf, SEEK_SET))
			return EXIT_FAILURE;

		PE_LOAD_CONFIG_META lconf = void;
		char[32] lcbuffer = void;

		if (fread(&lconf, 4, 1, obj.handle) == 0)
			return EXIT_FAILURE;
		if (fread(&lconf.dir32.TimeDateStamp, lconf.dir32.Size, 1, obj.handle) == 0)
			return EXIT_FAILURE;

		if (strftime(cast(char*)lcbuffer, 32, "%c",
			localtime(cast(time_t*)&lconf.dir64.TimeDateStamp)) == 0) {
			const(char)* l = cast(char*)&lcbuffer;
			l = "strftime:err";
		}

		with (lconf.dir32)
		printf( // Same sizes/offsets
		"\n*\n* Load Config\n*\n\n"~
		"Size                            %08X\t(%u)\n"~
		"TimeDateStamp                   %08X\t(%s)\n"~
		"MajorVersion                    %04X\t(%u)\n"~
		"MinorVersion                    %04X\t(%u)\n"~
		"GlobalFlagsClear                %08X\n"~
		"GlobalFlagsSet                  %08X\n"~
		"CriticalSectionDefaultTimeout   %08X\n",
		Size, Size,
		TimeDateStamp, &lcbuffer,
		MajorVersion, lconf.dir32.MajorVersion,
		MinorVersion, lconf.dir32.MinorVersion,
		GlobalFlagsClear,
		GlobalFlagsSet,
		CriticalSectionDefaultTimeout);

		if (OptMagic != PE_FMT_64) { // 32
			with (lconf.dir32)
			printf(
			"DeCommitFreeBlockThreshold      %08X\n"~
			"DeCommitTotalBlockThreshold     %08X\n"~
			"LockPrefixTable                 %08X\n"~
			"MaximumAllocationSize           %08X\t(%u)\n"~
			"VirtualMemoryThreshold          %08X\n"~
			"ProcessHeapFlags                %08X\n"~
			"ProcessAffinityMask             %08X\n"~
			"CSDVersion                      %04X\n"~
			"Reserved1                       %04X\n"~
			"EditList                        %08X\n"~
			"SecurityCookie                  %08X\n",
			DeCommitFreeBlockThreshold,
			DeCommitTotalBlockThreshold,
			LockPrefixTable,
			MaximumAllocationSize, lconf.dir32.MaximumAllocationSize,
			VirtualMemoryThreshold,
			ProcessHeapFlags,
			ProcessAffinityMask,
			CSDVersion,
			Reserved1,
			EditList,
			SecurityCookie);

			if (lconf.dir32.Size <= PE_LOAD_CONFIG32_LIMIT_XP)
				goto L_LOADCFG_EXIT;

			with (lconf.dir32)
			printf(
			"SEHandlerTable                  %08X\n"~
			"SEHandlerCount                  %08X\n"~
			"GuardCFCheckFunctionPointer     %08X\n"~
			"GuardCFDispatchFunctionPointer  %08X\n"~
			"GuardCFFunctionTable            %08X\n"~
			"GuardCFFunctionCount            %08X\n"~
			"GuardFlags                      %08X\n",
			SEHandlerTable,
			SEHandlerCount,
			GuardCFCheckFunctionPointer,
			GuardCFDispatchFunctionPointer,
			GuardCFFunctionTable,
			GuardCFFunctionCount,
			GuardFlags);

			if (lconf.dir32.Size <= PE_LOAD_CONFIG32_LIMIT_VI)
				goto L_LOADCFG_EXIT;

			with (lconf.dir32)
			printf(
			"CodeIntegrity.Flags             %04X\n"~
			"CodeIntegrity.Catalog           %04X\n"~
			"CodeIntegrity.CatalogOffset     %08X\n"~
			"CodeIntegrity.Reserved          %08X\n"~
			"GuardAddressTakenIatEntryTable  %08X\n"~
			"GuardAddressTakenIatEntryCount  %08X\n"~
			"GuardLongJumpTargetTable        %08X\n"~
			"GuardLongJumpTargetCount        %08X\n",
			CodeIntegrity.Flags,
			CodeIntegrity.Catalog,
			CodeIntegrity.CatalogOffset,
			CodeIntegrity.Reserved,
			GuardAddressTakenIatEntryTable,
			GuardAddressTakenIatEntryCount,
			GuardLongJumpTargetTable,
			GuardLongJumpTargetCount);

			if (lconf.dir32.Size <= PE_LOAD_CONFIG32_LIMIT_8)
				goto L_LOADCFG_EXIT;

			with (lconf.dir32)
			printf(
			"DynamicValueRelocTable                    %08X\n"~
			"CHPEMetadataPointer                       %08X\n"~
			"GuardRFFailureRoutine                     %08X\n"~
			"GuardRFFailureRoutineFunctionPointer      %08X\n"~
			"DynamicValueRelocTableOffset              %08X\n"~
			"DynamicValueRelocTableSection             %04X\n"~
			"Reserved2                                 %04X\n"~
			"GuardRFVerifyStackPointerFunctionPointer  %08X\n"~
			"HotPatchTableOffset                       %08X\n"~
			"Reserved3                                 %08X\n"~
			"EnclaveConfigurationPointer               %08X\n"~
			"VolatileMetadataPointer                   %08X\n",
			DynamicValueRelocTable,
			CHPEMetadataPointer,
			GuardRFFailureRoutine,
			GuardRFFailureRoutineFunctionPointer,
			DynamicValueRelocTableOffset,
			DynamicValueRelocTableSection,
			Reserved2,
			GuardRFVerifyStackPointerFunctionPointer,
			HotPatchTableOffset,
			Reserved3,
			EnclaveConfigurationPointer,
			VolatileMetadataPointer);
		} else { // 64
			with (lconf.dir64)
			printf(
			"DeCommitFreeBlockThreshold      %016llX\n"~
			"DeCommitTotalBlockThreshold     %016llX\n"~
			"LockPrefixTable                 %016llX\n"~
			"MaximumAllocationSize           %016llX\t(%u)\n"~
			"VirtualMemoryThreshold          %016llX\n"~
			"ProcessAffinityMask             %016llX\n"~
			"ProcessHeapFlags                %08X\n"~
			"CSDVersion                      %04X\n"~
			"Reserved1                       %04X\n"~
			"EditList                        %016llX\n"~
			"SecurityCookie                  %016llX\n",
			DeCommitFreeBlockThreshold,
			DeCommitTotalBlockThreshold,
			LockPrefixTable,
			MaximumAllocationSize, MaximumAllocationSize,
			VirtualMemoryThreshold,
			ProcessAffinityMask,
			ProcessHeapFlags,
			CSDVersion,
			Reserved1,
			EditList,
			SecurityCookie);

			if (lconf.dir64.Size <= PE_LOAD_CONFIG64_LIMIT_XP)
				goto L_LOADCFG_EXIT;

			with (lconf.dir64)
			printf(
			"SEHandlerTable                  %016llX\n"~
			"SEHandlerCount                  %016llX\n"~
			"GuardCFCheckFunctionPointer     %016llX\n"~
			"GuardCFDispatchFunctionPointer  %016llX\n"~
			"GuardCFFunctionTable            %016llX\n"~
			"GuardCFFunctionCount            %016llX\n"~
			"GuardFlags                      %08X\n",
			SEHandlerTable,
			SEHandlerCount,
			GuardCFCheckFunctionPointer,
			GuardCFDispatchFunctionPointer,
			GuardCFFunctionTable,
			GuardCFFunctionCount,
			GuardFlags);

			if (lconf.dir64.Size <= PE_LOAD_CONFIG64_LIMIT_VI)
				goto L_LOADCFG_EXIT;

			with (lconf.dir64)
			printf(
			"CodeIntegrity.Flags             %04X\n"~
			"CodeIntegrity.Catalog           %04X\n"~
			"CodeIntegrity.CatalogOffset     %08X\n"~
			"CodeIntegrity.Reserved          %08X\n"~
			"GuardAddressTakenIatEntryTable  %016llX\n"~
			"GuardAddressTakenIatEntryCount  %016llX\n"~
			"GuardLongJumpTargetTable        %016llX\n"~
			"GuardLongJumpTargetCount        %016llX\n",
			CodeIntegrity.Flags,
			CodeIntegrity.Catalog,
			CodeIntegrity.CatalogOffset,
			CodeIntegrity.Reserved,
			GuardAddressTakenIatEntryTable,
			GuardAddressTakenIatEntryCount,
			GuardLongJumpTargetTable,
			GuardLongJumpTargetCount);

			if (lconf.dir64.Size <= PE_LOAD_CONFIG64_LIMIT_8)
				goto L_LOADCFG_EXIT;

			with (lconf.dir64)
			printf(
			"DynamicValueRelocTable                    %016llX\n"~
			"CHPEMetadataPointer                       %016llX\n"~
			"GuardRFFailureRoutine                     %016llX\n"~
			"GuardRFFailureRoutineFunctionPointer      %016llX\n"~
			"DynamicValueRelocTableOffset              %08X\n"~
			"DynamicValueRelocTableSection             %04X\n"~
			"Reserved2                                 %04X\n"~
			"GuardRFVerifyStackPointerFunctionPointer  %08X\n"~
			"HotPatchTableOffset                       %016llX\n"~
			"Reserved3                                 %08X\n"~
			"EnclaveConfigurationPointer               %016llX\n"~
			"VolatileMetadataPointer                   %016llX\n",
			DynamicValueRelocTable,
			CHPEMetadataPointer,
			GuardRFFailureRoutine,
			GuardRFFailureRoutineFunctionPointer,
			DynamicValueRelocTableOffset,
			DynamicValueRelocTableSection,
			Reserved2,
			GuardRFVerifyStackPointerFunctionPointer,
			HotPatchTableOffset,
			Reserved3,
			EnclaveConfigurationPointer,
			VolatileMetadataPointer);
		}
	}
}*/

// NOTE: FileOffset = Section.RawPtr + (Directory.RVA - Section.RVA)
void dump_pe_imports(adbg_object_t *o) {
	dprint_header("Imports");
	
	if (o.i.pe.imports == null)
		return;
	
	char* basename = cast(char*)o.i.pe.imports - o.i.pe.directory.ImportTable.rva;
	
	size_t count = o.i.pe.directory.ImportTable.size / PE_IMPORT_DESCRIPTOR.sizeof;
	for (size_t i; i < count; ++i) {
		PE_IMPORT_DESCRIPTOR *id = &o.i.pe.imports[i];
		
		if (id.Characteristics == 0)
			break;
		
		dprint_x32("Characteristics", id.Characteristics);
		dprint_x32("TimeDateStamp", id.TimeDateStamp);
		dprint_x32("ForwarderChain", id.ForwarderChain);
		// NOTE: 256 is a temporary maximum
		//       I think these are 0-terminated, but just in case
		dprint_x32s("Name", id.Name, basename + id.Name, 256);
		dprint_x32("FirstThunk", id.FirstThunk);
		
		dprint_columns("RVA", "Hint", "String");
		
		union lte_t {
			void *raw;
			PE_IMPORT_LTE32 *e32;
			PE_IMPORT_LTE64 *e64;
		}
		lte_t lte = void; lte.raw = basename + id.Characteristics;
		
		switch (o.i.pe.opt_header.Magic) {
		case PE_FMT_32:
			for (; lte.e32.val; ++lte.e32) {
				if (lte.e32.val >= 0x8000_0000) { // Ordinal
					dprint_x16("", lte.e32.num);
				} else { // RVA
					ushort *hint = cast(ushort*)(basename + lte.e32.rva);
					dprint_x16__i(lte.e32.rva, *hint, cast(char*)hint + 2);
				}
			}
			break;
		case PE_FMT_64:
			for (; lte.e64.val; ++lte.e64) {
				if (lte.e64.val >= 0x8000_0000_0000_0000) { // Ordinal
					dprint_x16("", lte.e32.num);
				} else { // RVA
					ushort *hint = cast(ushort*)(basename + lte.e64.rva);
					dprint_x16__i(lte.e64.rva, *hint, cast(char*)hint + 2);
				}
			}
			break;
		default:
		}
	}
}

void dump_pe_debug(adbg_object_t *o) {
	dprint_header("Debug");
	
	if (o.i.pe.debug_directory == null)
		return;
	
	size_t count = o.i.pe.directory.DebugDirectory.size / PE_DEBUG_DIRECTORY.sizeof;
	for (size_t i; i < count; ++i) {
		PE_DEBUG_DIRECTORY *id = &o.i.pe.debug_directory[i];
		
		dprint_x32("Characteristics", id.Characteristics);
		dprint_x32("TimeDateStamp", id.TimeDateStamp);
		dprint_u16("MajorVersion", id.MajorVersion);
		dprint_u16("MinorVersion", id.MinorVersion);
		dprint_u32("Type", id.Type, adbg_object_pe_debug_type_string(id.Type));
		dprint_u32("SizeOfData", id.SizeOfData);
		dprint_x32("AddressOfRawData", id.AddressOfRawData);
		dprint_x32("PointerToRawData", id.PointerToRawData);
		
		void *rawdata = o.buffer + id.PointerToRawData;
		if (rawdata >= o.buffer + o.file_size) {
			dprint_warn("PointerToRawData out of bounds");
			return;
		}
		
		switch (id.Type) {
		case PE_IMAGE_DEBUG_TYPE_CODEVIEW:
			//TODO: Check MajorVersion/MinorVersion
			//      For example, a modern D program use 0.0
			//      Probably meaningless
			
			uint sig = *cast(uint*)rawdata;
			switch (sig) {
			case CHAR32!"NB09": // PDB 2.0+ / CodeView 4.10
				dprint_x32("Signature", sig, "PDB 2.0+ / CodeView 4.10");
				goto L_DEBUG_PDB20;
			case CHAR32!"NB10": // PDB 2.0+
				dprint_x32("Signature", sig, "PDB 2.0+ / NB10");
				goto L_DEBUG_PDB20;
			case CHAR32!"NB11": // PDB 2.0+ / CodeView 5.0
				dprint_x32("Signature", sig, "PDB 2.0+ / CodeView 5.0");
L_DEBUG_PDB20:
				PE_DEBUG_DATA_CODEVIEW_PDB20* pdb =
					cast(PE_DEBUG_DATA_CODEVIEW_PDB20*)rawdata;
				dprint_x32("Offset", pdb.Offset);
				dprint_x32("Timestamp", pdb.Timestamp);
				dprint_u32("Age", pdb.Age);
				//TODO: Consider limiting to MAX_PATH or similar
				dprint_string("Path", pdb.Path.ptr);
				break;
			case CHAR32!"RSDS": // PDB 7.0 / CodeView 7.0
				PE_DEBUG_DATA_CODEVIEW_PDB70* pdb =
					cast(PE_DEBUG_DATA_CODEVIEW_PDB70*)rawdata;
				char[UID_TEXTLEN] guid = void;
				uid_text(pdb.PDB_GUID, guid, UID_GUID);
				dprint_x32("Signature", sig, "PDB 7.0 / CodeView 7.0");
				dprint_stringl("GUID", guid.ptr, UID_TEXTLEN);
				dprint_u32("Age", pdb.Age); // ctime32?
				//TODO: Consider limiting to MAX_PATH or similar
				dprint_string("Path", pdb.Path.ptr);
				break;
			default:
				dprint_x32("Signature", sig, "Unknown");
				break;
			}
			break;
		case PE_IMAGE_DEBUG_TYPE_MISC:
			// TODO: PE_IMAGE_DEBUG_TYPE_MISC. Used for separate .DBG files
			break;
		case PE_IMAGE_DEBUG_TYPE_FPO:
			// TODO: PE_IMAGE_DEBUG_TYPE_FPO
			break;
		case PE_IMAGE_DEBUG_TYPE_EX_DLLCHARACTERISTICS:
			// TODO: PE_IMAGE_DEBUG_TYPE_EX_DLLCHARACTERISTICS
			break;
		default:
		}
	}
}

void dump_pe_disasm(adbg_object_t *o, uint flags) {
	dprint_header("Disassembly");
	
	bool all = (flags & DumpOpt.disasm_all) != 0;
	ushort count = o.i.pe.header.NumberOfSections;
	for (ushort si; si < count; ++si) {
		PE_SECTION_ENTRY *entry = &o.i.pe.sections[si];
		
		if (all || entry.Characteristics & PE_SECTION_CHARACTERISTIC_MEM_EXECUTE) {
			dprint_disassemble_object(o, entry.Name.ptr, 8,
				o.buffer + entry.PointerToRawData, entry.SizeOfRawData,
				flags);
		}
	}
}