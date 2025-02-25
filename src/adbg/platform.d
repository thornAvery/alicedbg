/// Platform compilation information.
///
/// Authors: dd86k <dd@dax.moe>
/// Copyright: © dd86k <dd@dax.moe>
/// License: BSD-3-Clause-Clear
module adbg.platform;

import adbg.include.d.config : D_FEATURE_TARGETINFO;

//TODO: has feature xyz should be dynamic
//      e.g., capstone may not be available, but could be after installing it
//TODO: Consider having configuration info (e.g., library, shared object, exectuable (default), etc.)
//TODO: Consider having a build info string to avoid breakage
//      Versus functions/structures changing

// Other interesting versions:
// - DRuntime_Use_Libunwind

extern (C):

//
// ANCHOR Compile settings
//

//TODO: Move to config module?
//      Or their own appropriate modules

//NOTE: These should not be used directly and will likely be removed soon (v1)

/// Amount of pointers to allocate
enum ADBG_CLI_ARGV_ARRAY_COUNT	= 16;
/// Length of array for argv parsing
enum ADBG_CLI_ARGV_ARRAY_LENGTH	= ADBG_CLI_ARGV_ARRAY_COUNT * size_t.sizeof;
/// The maximum amount of breakpoints that the debugger can have.
enum ADBG_MAX_BREAKPOINTS	= 4;
/// Child stack size if USE_CLONE is specified.
enum ADBG_CHILD_STACK_SIZE	= 1024 * 1024 * 8;

//
// Constants
//

/// Library version.
enum ADBG_VERSION = "0.4.0";

debug enum __BUILDTYPE__ = "debug";	/// Library build type.
else  enum __BUILDTYPE__ = "release";	/// Ditto

version (SharedLib)
	/// Alicedbg configured build
	enum ADBG_CONFIG = "shared";
else version (StaticLib)
	/// Ditto
	enum ADBG_CONFIG = "static";
else
	/// Ditto
	enum ADBG_CONFIG = "executable";

//
// ANCHOR Endianness
//

version (LittleEndian) {
	enum PLATFORM_LSB = 1;	/// Set if target little-endian
	enum PLATFORM_MSB = 0;	/// Set if target big-endian
	enum TARGET_ENDIAN = "lsb";	/// Target endian name
} else {
	enum PLATFORM_LSB = 0;	/// Ditto
	enum PLATFORM_MSB = 1;	/// Ditto
	enum TARGET_ENDIAN = "msb";	/// Ditto
}

//
// ANCHOR Platform information
//

version (X86)
	enum TARGET_PLATFORM = "x86";	/// Platform string
else version (X86_64)
	enum TARGET_PLATFORM = "x86_64";	/// Ditto
else version (ARM_Thumb)
	enum TARGET_PLATFORM = "arm_t32";	/// Ditto
else version (ARM)
	enum TARGET_PLATFORM = "arm_a32";	/// Ditto
else version (AArch64)
	enum TARGET_PLATFORM = "arm_a64";	/// Ditto
else version (PPC)
	enum TARGET_PLATFORM = "powerpc";	/// Ditto
else version (PPC64)
	enum TARGET_PLATFORM = "powerpc64";	/// Ditto
else version (SPARC)
	enum TARGET_PLATFORM = "sparc";	/// Ditto
else version (SPARC64)
	enum TARGET_PLATFORM = "sparc64";	/// Ditto
else version (S390)
	enum TARGET_PLATFORM = "s390";	/// Ditto
else version (SystemZ)
	enum TARGET_PLATFORM = "systemz";	/// Ditto
else version (RISCV32)
	enum TARGET_PLATFORM = "riscv32";	/// Ditto
else version (RISCV64)
	enum TARGET_PLATFORM = "riscv64";	/// Ditto
else
	static assert(0, "Platform not supported.");

//
// ANCHOR OS string
//

version (Win64)
	enum TARGET_OS = "win64";	/// Platform OS string
else version (Win32)
	enum TARGET_OS = "win32";	/// Ditto
else version (linux)
	enum TARGET_OS = "linux";	/// Ditto
else version (OSX)
	enum TARGET_OS = "osx";	/// Ditto
else version (FreeBSD)
	enum TARGET_OS = "freebsd";	/// Ditto
else version (OpenBSD)
	enum TARGET_OS = "openbsd";	/// Ditto
else version (NetBSD)
	enum TARGET_OS = "netbsd";	/// Ditto
else version (DragonflyBSD)
	enum TARGET_OS = "dragonflybsd";	/// Ditto
else version (BSD)
	enum TARGET_OS = "bsd";	/// Ditto
else version (Solaris)
	enum TARGET_OS = "solaris";	/// Ditto
else version (AIX)
	enum TARGET_OS = "aix";	/// Ditto
else version (Hurd)
	enum TARGET_OS = "hurd";	/// 
else
	enum TARGET_OS = "unknown";	/// Ditto

//
// ANCHOR Environement string
//        Typically the C library, otherwise system wrappers.
//

version (MinGW)
	enum TARGET_ENV = "mingw";	/// Ditto
else version (Cygwin)
	enum TARGET_ENV = "cygwin";	/// Ditto
else version (CRuntime_DigitalMars)
	enum TARGET_ENV = "digitalmars";	/// Ditto
else version (CRuntime_Microsoft)
	enum TARGET_ENV = "mscvrt";	/// Ditto
else version (CRuntime_Bionic)
	enum TARGET_ENV = "bionic";	/// Platform environment string
else version (CRuntime_Musl)
	enum TARGET_ENV = "musl";	/// Ditto
else version (CRuntime_Glibc)
	enum TARGET_ENV = "glibc";	/// Ditto
else version (CRuntime_Newlib)
	enum TARGET_ENV = "newlib";	/// Ditto
else version (CRuntime_UClibc)
	enum TARGET_ENV = "uclibc";	/// Ditto
else version (CRuntime_WASI)	// WebAssembly
	enum TARGET_ENV = "wasi";	/// Ditto
else version (FreeStanding)
	enum TARGET_ENV = "freestanding";	/// Ditto
else
	enum TARGET_ENV = "unknown";	/// Ditto

/// Full target triple.
enum TARGET_TRIPLE = TARGET_PLATFORM ~ "-" ~ TARGET_OS ~ "-" ~ TARGET_ENV;

//
// ANCHOR Additional target information
//

static if (D_FEATURE_TARGETINFO) {
	/// Target object format string
	enum TARGET_OBJFMT = __traits(getTargetInfo, "objectFormat");
	
	/// Target float ABI string
	enum TARGET_FLTABI = __traits(getTargetInfo, "floatAbi");
	
	private enum __cppinfo = __traits(getTargetInfo, "cppRuntimeLibrary");
	/// Target C++ Runtime string
	enum TARGET_CPPRT = __cppinfo == null ? "none" : __cppinfo;
} else { // Legacy
	/// Target object format string
	enum TARGET_OBJFMT = "unknown";
	
	version (D_HardFloat)
		enum TARGET_FLTABI  = "hard";	/// Target float ABI string
	else version (D_SoftFloat)
		enum TARGET_FLTABI  = "soft";	/// Ditto
	else
		enum TARGET_FLTABI  = "unknown";	/// Ditto
	
	// NOTE: Deprecated CppRuntime values
	//       "CppRuntime_Gcc" and "CppRuntime_Clang" version identifiers are
	//       deprecated. They are now "CppRuntime_GNU" and "CppRuntime_LLVM"
	//       respectively.
	//
	//       Since the old version identifiers are deprecated (2.110), but
	//       newer than the "getTargetInfo" trait (2.083), the new versions
	//       will not be used here.
	//
	//       However, for clarity, their new names are reflected here.
	version (CppRuntime_Gcc)	// was "libstdc++"
		enum TARGET_CPPRT = "gnu";	/// Target C++ Runtime string
	else version (CppRuntime_Microsoft)	// was "libcmt"
		enum TARGET_CPPRT = "microsoft";	/// Ditto
	else version (CppRuntime_Clang)	// was "clang"
		enum TARGET_CPPRT = "llvm";	/// Ditto
	else version (CppRuntime_DigitalMars)	// was "dmc++"
		enum TARGET_CPPRT = "digitalmars";	/// Ditto
	else version (CppRuntime_Sun)
		enum TARGET_CPPRT = "sun";	/// Ditto
	else // assuming none
		enum TARGET_CPPRT = "none";	/// Ditto
}

version (PrintTargetInfo) {
	pragma(msg, "ADBG_VERSION     ", ADBG_VERSION);
	pragma(msg, "__BUILDTYPE__    ", __BUILDTYPE__);
	pragma(msg, "ADBG_CONFIG      ", ADBG_CONFIG);
	pragma(msg, "TARGET_PLATFORM  ", TARGET_PLATFORM);
	pragma(msg, "TARGET_OS        ", TARGET_OS);
	pragma(msg, "TARGET_ENV       ", TARGET_ENV);
	pragma(msg, "TARGET_CPPRT     ", TARGET_CPPRT);
	pragma(msg, "TARGET_OBJFMT    ", TARGET_OBJFMT);
	pragma(msg, "TARGET_FLTABI    ", TARGET_FLTABI);
}

//
// ANCHOR Other D flags
//

version (D_PIC) private enum PIC = " pic";
else            private enum PIC = "";
version (D_PIE) private enum PIE = " pie";
else            private enum PIE = "";
version (D_SIMD) private enum SIMD = " simd";
else             private enum SIMD = "";
version (D_AVX) private enum AVX = " avx";
else            private enum AVX = "";
version (D_AVX2) private enum AVX2 = " avx2";
else             private enum AVX2 = "";
version (D_NoBoundsChecks) private enum NoBoundsCheck = " nobounds";
else                       private enum NoBoundsCheck = "";

/// Misc. D flags
enum D_FEATURES = PIC~PIE~SIMD~AVX~AVX2~NoBoundsCheck;

//
// ANCHOR Info functions
//

/// Target information structure
struct adbg_build_info_t {
	const(char) *adbgver = ADBG_VERSION;	/// Library version.
	const(char) *build   = __BUILDTYPE__;	/// "debug" or "release".
	const(char) *config  = ADBG_CONFIG;	/// Configuration.
	const(char) *arch    = TARGET_PLATFORM;	/// Architecture.
	const(char) *os      = TARGET_OS;	/// Operating system.
	const(char) *env     = TARGET_ENV;	/// Target environment.
	const(char) *cpprt   = TARGET_CPPRT;	/// C++ runtime.
	const(char) *objfmt  = TARGET_OBJFMT;	/// Object format (e.g., coff).
	const(char) *fltabi  = TARGET_FLTABI;	/// Float ABI (hard or soft).
	const(char) *dflags  = D_FEATURES;	/// D compile features.
	const(char) *end     = null;	/// End of strings
}

/// Get compilation information structure.
/// Note: This can be interpreted as a null-terminated array of string pointers.
/// Returns: AdbgInfo structure pointer
export
immutable(adbg_build_info_t)* adbg_build_info() {
	static immutable adbg_build_info_t info;
	return &info;
}

// This adds the requirement for building DLLs with BetterC.
// See: https://learn.microsoft.com/en-us/windows/win32/dlls/dllmain
// NOTE: This library avoids the use of TLS whenever possible,
//       so the need of fixing up TLS entries for Win32 is not needed.
//       Typically, it is performed by druntime (core.sys.windows.dll).
// NOTE: TLSTable directory is not created for alicedbg.dll.
version (Windows)
version (SharedLib) {
import core.sys.windows.windef : HINSTANCE, BOOL, TRUE, FALSE, DWORD, LPVOID,
	DLL_PROCESS_DETACH, DLL_PROCESS_ATTACH, DLL_THREAD_ATTACH, DLL_THREAD_DETACH;
private
extern (Windows)
BOOL DllMain(HINSTANCE hInstance, DWORD fdwReason, LPVOID lpvReserved) {
	/*switch (dwReason) {
	case DLL_PROCESS_DETACH:
		// Do not do cleanup if process termination scenario
		if (lpvReserved)
			break;
		// Otherwise, perform any necessary cleanup.
		break;
	// Initialize once for each new process.
	// Return FALSE to fail DLL load.
	case DLL_PROCESS_ATTACH:
		return TRUE;
	case DLL_THREAD_ATTACH:
		break;
	case DLL_THREAD_DETACH:
		break;
	default: assert(false);
	}*/
	return TRUE;
}
}
