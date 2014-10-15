#ifndef _HSAILDEVICEINFO_H_
#define _HSAILDEVICEINFO_H_
#include <string>
namespace llvm
{
  class HSAILDevice;
  class HSAILSubtarget;
  namespace HSAILDeviceInfo
  {
    // Each Capabilities can be executed using a hardware instruction,
    // emulated with a sequence of software instructions, or not
    // supported at all.
    enum ExecutionMode {
      Unsupported = 0, // Unsupported feature on the card(Default value)
      Software, // This is the execution mode that is set if the
      // feature is emulated in software
      Hardware  // This execution mode is set if the feature exists
        // natively in hardware
    };

    // Any changes to this needs to have a corresponding update to the
    // twiki page GPUMetadataABI
    enum Caps {
      ConstantMem      = 0x8,  // Constant/CB memory.
      LocalMem         = 0x9,  // Local/LDS memory.
      PrivateMem       = 0xA,  // Scratch/Private/Stack memory.
      RegionMem        = 0xB,  // OCL GDS Memory Extension.
      // Debug mode implies that no hardware features or optimizations
      // are performned and that all memory access go through a single
      // uav(Arena on HD5XXX/HD6XXX and Raw on HD4XXX).
      Debug            = 0x12, // Debug mode is enabled.
      // If more capabilities are required, then
      // this number needs to be increased.
      // All capabilities must come before this
      // number.
      MaxNumberCapabilities = 0x20
    };

    extern bool is64bit;
  } // namespace HSAILDeviceInfo
  llvm::HSAILDevice*
    getDeviceFromName(const std::string &name, llvm::HSAILSubtarget *ptr, bool is64bit = false, bool is64on32bit = false);
} // namespace llvm
#endif // _HSAILDEVICEINFO_H_
