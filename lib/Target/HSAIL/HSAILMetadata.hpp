//
// taken from hsa/compiler/lib/include/aclTypes.h
//

#ifndef _HSAIL_METADATA_HPP
#define _HSAIL_METADATA_HPP

typedef struct _md_arg_type_0_7 argType;
typedef struct _md_printf_fmt_0_7 printfFmt;

// Enumerations for the various argument types.
typedef enum argTypeEnum {
  ARG_TYPE_ERROR = 0,
  ARG_TYPE_SAMPLER = 1,
  ARG_TYPE_IMAGE = 2,
  ARG_TYPE_COUNTER = 3,
  ARG_TYPE_VALUE = 4,
  ARG_TYPE_POINTER = 5,
  ARG_TYPE_SEMAPHORE = 6,
  ARG_TYPE_QUEUE = 7, // enum for device enqueue
  ARG_TYPE_LAST = 8
} ArgType;

// Enumerations of the valid data types for pass by value and
// pass by pointer kernel arguments.
typedef enum dataTypeEnum {
  DATATYPE_ERROR = 0,
  DATATYPE_i1 = 1,
  DATATYPE_i8 = 2,
  DATATYPE_i16 = 3,
  DATATYPE_i32 = 4,
  DATATYPE_i64 = 5,
  DATATYPE_u8 = 6,
  DATATYPE_u16 = 7,
  DATATYPE_u32 = 8,
  DATATYPE_u64 = 9,
  DATATYPE_f16 = 10,
  DATATYPE_f32 = 11,
  DATATYPE_f64 = 12,
  DATATYPE_f80 = 13,
  DATATYPE_f128 = 14,
  DATATYPE_struct = 15,
  DATATYPE_union = 16,
  DATATYPE_event = 17,
  DATATYPE_opaque = 18,
  DATATYPE_unknown = 19,
  DATATYPE_LAST = 20
} ArgDataType;

// Enumerations of the valid memory types for pass by pointer
// kernel arguments
typedef enum memoryTypeEnum {
  PTR_MT_ERROR = 0,         // Error
  PTR_MT_GLOBAL = 1,        // global buffer
  PTR_MT_SCRATCH_EMU = 2,   // SW emulated private memory
  PTR_MT_LDS_EMU = 3,       // SW emulated local memory
  PTR_MT_UAV = 4,           // uniformed access vector memory
  PTR_MT_CONSTANT_EMU = 5,  // SW emulated constant memory
  PTR_MT_GDS_EMU = 6,       // SW emulated region memory
  PTR_MT_LDS = 7,           // HW local memory
  PTR_MT_SCRATCH = 8,       // HW private memory
  PTR_MT_CONSTANT = 9,      // HW constant memory
  PTR_MT_GDS = 10,          // HW region memory
  PTR_MT_UAV_SCRATCH = 11,  // SI and later HW private memory
  PTR_MT_UAV_CONSTANT = 12, // SI and later HW constant memory
  PTR_MT_LAST = 13
} MemoryType;

// Enumeration that specifies the various access types for a pointer/image.
typedef enum imageTypeEnum {
  ACCESS_TYPE_ERROR = 0,
  ACCESS_TYPE_RO = 1,
  ACCESS_TYPE_WO = 2,
  ACCESS_TYPE_RW = 3,
  ACCESS_TYPE_LAST = 4
} AccessType;

//! An enumeration that maps memory types to index values
//! An enumeration that maps Resource type to index values
typedef enum _rt_gpu_resource_type_rec {
  RT_RES_UAV = 0, // UAV resources
  RT_RES_PRI = 1, // Private resources
  RT_RES_LDS = 2, // LDS resources
  RT_RES_GDS = 3, // GDS resources
  RT_RES_CON = 4, // Constant resources
  RT_RES_LAST = 5
} aclGPUResource;

typedef enum _rt_gpu_mem_sizes {
  RT_MEM_HW_LOCAL = 0,
  RT_MEM_SW_LOCAL = 1,
  RT_MEM_HW_PRIVATE = 2,
  RT_MEM_SW_PRIVATE = 3,
  RT_MEM_HW_REGION = 4,
  RT_MEM_SW_REGION = 5,
  RT_MEM_LAST = 6
} aclGPUMemSizes;

typedef struct _md_arg_type_0_7 {
  size_t struct_size;
  size_t argNameSize;
  size_t typeStrSize;
  const char *argStr;
  const char *typeStr;
  union {
    struct { // Struct for sampler arguments
      unsigned ID;
      unsigned isKernelDefined;
      unsigned value;
    } sampler;
    struct { // Struct for image arguments
      unsigned resID;
      unsigned cbNum;
      unsigned cbOffset;
      AccessType type;
      bool is2D;
      bool is1D;
      bool isArray;
      bool isBuffer;
    } image;
    struct { // struct for atomic counter arguments
      unsigned is32bit;
      unsigned resID;
      unsigned cbNum;
      unsigned cbOffset;
    } counter;
    struct { // struct for semaphore arguments
      unsigned resID;
      unsigned cbNum;
      unsigned cbOffset;
    } sema;
    struct { // struct for pass by value arguments
      unsigned numElements;
      unsigned cbNum;
      unsigned cbOffset;
      ArgDataType data;
    } value;
    struct { // struct for pass by pointer arguments
      unsigned numElements;
      unsigned cbNum;
      unsigned cbOffset;
      unsigned bufNum;
      unsigned align;
      ArgDataType data;
      MemoryType memory;
      AccessType type;
      bool isVolatile;
      bool isRestrict;
      bool isPipe;
    } pointer;
  } arg;
  ArgType type;
  bool isConst;
} argType_0_7;

//! A structure that holds information for printf
// The format in memory of this structure is
// ------------
// | printfFmt|
// ------------
// |->argSizes|
// ------------
// |->fmrStr  |
// ------------

typedef struct _md_printf_fmt_0_7 {
  size_t struct_size;
  unsigned ID;
  size_t numSizes;
  size_t fmtStrSize;
  uint32_t *argSizes;
  const char *fmtStr;
} printfFmt_0_7;

//! A structure that holds the metadata in the RODATA section.
typedef struct _cl_metadata_0_7 {
  size_t struct_size; // This holds the size of the structure itself for
                      // versioning.
  size_t data_size; // This holds the size of all the memory allocated for this
                    // structure.
  uint32_t major, minor, revision, gpuCaps, funcID;
  uint32_t gpuRes[RT_RES_LAST];
  uint32_t wgs[3];
  uint32_t wrs[3];
  size_t kernelNameSize;
  size_t deviceNameSize;
  size_t mem[RT_MEM_LAST];
  size_t numArgs;
  size_t numPrintf;

  argType *args;
  printfFmt *printf;
  const char *kernelName;
  const char *deviceName;
  bool enqueue_kernel;
  uint32_t kernel_index;
} CLMetadata_0_7;

#endif // _HSAIL_METADATA_HPP
