////////////////////////////////////////////////////////////////////////////////
// image operations

let isImageInst=1 in {

// Image read
class ReadImage1D<string asm>
      : HSAILInst<(outs GPR32:$dst1, GPR32:$dst2,  GPR32:$dst3,  GPR32:$dst4),
                  (ins GPR64:$src1, GPR64:$src2, GPR32:$src3),
                  !strconcat(asm, 
                             "( $dst1, $dst2, $dst3, $dst4 ), "
                             "$src1, $src2, $src3"), []>;

class ReadImage2D<string asm>
      : HSAILInst<(outs GPR32:$dst1, GPR32:$dst2,  GPR32:$dst3,  GPR32:$dst4),
                  (ins GPR64:$src1, GPR64:$src2, GPR32:$src3, GPR32:$src4),
                  !strconcat(asm, 
                             "( $dst1, $dst2, $dst3, $dst4 ), "
                             "$src1, $src2, ( $src3, $src4 )"), []>;


class ReadImage3D<string asm>
      : HSAILInst<(outs GPR32:$dst1, GPR32:$dst2,  GPR32:$dst3,  GPR32:$dst4),
                  (ins GPR64:$src1, GPR64:$src2, GPR32:$src3, GPR32:$src4, GPR32:$src5),
                  !strconcat(asm, 
                             "( $dst1, $dst2, $dst3, $dst4 ), "
                             "$src1, $src2, ( $src3, $src4, $src5 )"), []>;

class ReadImage2DDepth<string asm>
      : HSAILInst<(outs GPR32:$dst),
                  (ins GPR64:$src1, GPR64:$src2, GPR32:$src3, GPR32:$src4),
                  !strconcat(asm,
                             "( $dst ), "
                             "$src1, $src2, ( $src3, $src4 )"), []>;

class ReadImage2DArrayDepth<string asm>
      : HSAILInst<(outs GPR32:$dst),
                  (ins GPR64:$src1, GPR64:$src2, GPR32:$src3, GPR32:$src4, GPR32:$src5),
                  !strconcat(asm,
                             "( $dst ), "
                             "$src1, $src2, ( $src3, $src4, $src5 )"), []>;

// read image 1d

def rd_imgf_1d_s32 : ReadImage1D<"rdimage_v4_1d_f32_roimg_s32">;
def rd_imgf_1d_f32 : ReadImage1D<"rdimage_v4_1d_f32_roimg_f32">;
def rd_imgi_1d_s32 : ReadImage1D<"rdimage_v4_1d_s32_roimg_s32">;
def rd_imgi_1d_f32 : ReadImage1D<"rdimage_v4_1d_s32_roimg_f32">;
def rd_imgui_1d_s32 : ReadImage1D<"rdimage_v4_1d_u32_roimg_s32">;
def rd_imgui_1d_f32 : ReadImage1D<"rdimage_v4_1d_u32_roimg_f32">;

// read image 1da

def rd_imgf_1da_s32 : ReadImage2D<"rdimage_v4_1da_f32_roimg_s32">;
def rd_imgf_1da_f32 : ReadImage2D<"rdimage_v4_1da_f32_roimg_f32">;
def rd_imgi_1da_s32 : ReadImage2D<"rdimage_v4_1da_s32_roimg_s32">;
def rd_imgi_1da_f32 : ReadImage2D<"rdimage_v4_1da_s32_roimg_f32">;
def rd_imgui_1da_s32 : ReadImage2D<"rdimage_v4_1da_u32_roimg_s32">;
def rd_imgui_1da_f32 : ReadImage2D<"rdimage_v4_1da_u32_roimg_f32">;

// read image 2d

def rd_imgf_2d_s32 : ReadImage2D<"rdimage_v4_2d_f32_roimg_s32">;
def rd_imgf_2d_f32 : ReadImage2D<"rdimage_v4_2d_f32_roimg_f32">;
def rd_imgi_2d_s32 : ReadImage2D<"rdimage_v4_2d_s32_roimg_s32">;
def rd_imgi_2d_f32 : ReadImage2D<"rdimage_v4_2d_s32_roimg_f32">;
def rd_imgui_2d_s32 : ReadImage2D<"rdimage_v4_2d_u32_roimg_s32">;
def rd_imgui_2d_f32 : ReadImage2D<"rdimage_v4_2d_u32_roimg_f32">;


// read image 2da

def rd_imgf_2da_s32 : ReadImage3D<"rdimage_v4_2da_f32_roimg_s32">;
def rd_imgf_2da_f32 : ReadImage3D<"rdimage_v4_2da_f32_roimg_f32">;
def rd_imgi_2da_s32 : ReadImage3D<"rdimage_v4_2da_s32_roimg_s32">;
def rd_imgi_2da_f32 : ReadImage3D<"rdimage_v4_2da_s32_roimg_f32">;
def rd_imgui_2da_s32 : ReadImage3D<"rdimage_v4_2da_u32_roimg_s32">;
def rd_imgui_2da_f32 : ReadImage3D<"rdimage_v4_2da_u32_roimg_f32">;

// read image 3d

def rd_imgf_3d_s32 : ReadImage3D<"rdimage_v4_3d_f32_roimg_s32">;
def rd_imgf_3d_f32 : ReadImage3D<"rdimage_v4_3d_f32_roimg_f32">;
def rd_imgi_3d_s32 : ReadImage3D<"rdimage_v4_3d_s32_roimg_s32">;
def rd_imgi_3d_f32 : ReadImage3D<"rdimage_v4_3d_s32_roimg_f32">;
def rd_imgui_3d_s32 : ReadImage3D<"rdimage_v4_3d_u32_roimg_s32">;
def rd_imgui_3d_f32 : ReadImage3D<"rdimage_v4_3d_u32_roimg_f32">;

// OpenCL 2.0 rd2ddepth

def rd_imgf_2ddepth_s32 : ReadImage2DDepth<"rdimage_2ddepth_f32_roimg_s32">;
def rd_imgf_2ddepth_f32 : ReadImage2DDepth<"rdimage_2ddepth_f32_roimg_f32">;

// OpenCL 2.0 rd2dadepth

def rd_imgf_2dadepth_s32 : ReadImage2DArrayDepth<"rdimage_2dadepth_f32_roimg_s32">;
def rd_imgf_2dadepth_f32 : ReadImage2DArrayDepth<"rdimage_2dadepth_f32_roimg_f32">;


// Image loads
class LoadImage1D<string asm>
      : HSAILInst<(outs GPR32:$dst1, GPR32:$dst2,  GPR32:$dst3,  GPR32:$dst4),
                  (ins GPR64:$src1, GPR32:$src2),
                  !strconcat(asm, 
                             "( $dst1, $dst2, $dst3, $dst4 ), "
                             "$src1, $src2"), []>;

class LoadImage2D<string asm>
      : HSAILInst<(outs GPR32:$dst1, GPR32:$dst2,  GPR32:$dst3,  GPR32:$dst4),
                  (ins GPR64:$src1, GPR32:$src2, GPR32:$src3),
                  !strconcat(asm, 
                             "( $dst1, $dst2, $dst3, $dst4 ), "
                             "$src1, ( $src2, $src3 )"), []>;

class LoadImage3D<string asm>
      : HSAILInst<(outs GPR32:$dst1, GPR32:$dst2,  GPR32:$dst3,  GPR32:$dst4),
                  (ins GPR64:$src1, GPR32:$src2, GPR32:$src3, GPR32:$src4),
                  !strconcat(asm, 
                             "( $dst1, $dst2, $dst3, $dst4 ), "
                             "$src1, ( $src2, $src3, $src4 )"), []>;

class LoadImage2DDepth<string asm>
      : HSAILInst<(outs GPR32:$dst),
                  (ins GPR64:$src1, GPR32:$src2, GPR32:$src3),
                  !strconcat(asm,
                             "( $dst ), "
                             "$src1, ( $src2, $src3 )"), []>;

class LoadImage2DArrayDepth<string asm>
      : HSAILInst<(outs GPR32:$dst),
                  (ins GPR64:$src1, GPR32:$src2, GPR32:$src3, GPR32:$src4),
                  !strconcat(asm,
                             "( $dst ), "
                             "$src1, ( $src2, $src3, $src4 )"), []>;

// load image 1d

def ld_imgf_1d_u32 : LoadImage1D<"ldimage_v4_1d_f32_rwimg_u32">;
def ld_imgi_1d_u32 : LoadImage1D<"ldimage_v4_1d_s32_rwimg_u32">;
def ld_imgui_1d_u32 : LoadImage1D<"ldimage_v4_1d_u32_rwimg_u32">;

// load image 1d buffer

def ld_imgf_1db_u32 : LoadImage1D<"ldimage_v4_1db_f32_rwimg_u32">;
def ld_imgi_1db_u32 : LoadImage1D<"ldimage_v4_1db_s32_rwimg_u32">;
def ld_imgui_1db_u32 : LoadImage1D<"ldimage_v4_1db_u32_rwimg_u32">;

// load image 1d array

def ld_imgf_1da_u32 : LoadImage2D<"ldimage_v4_1da_f32_rwimg_u32">;
def ld_imgi_1da_u32 : LoadImage2D<"ldimage_v4_1da_s32_rwimg_u32">;
def ld_imgui_1da_u32 : LoadImage2D<"ldimage_v4_1da_u32_rwimg_u32">;

// load image 2d

def ld_imgf_2d_u32 : LoadImage2D<"ldimage_v4_2d_f32_rwimg_u32">;
def ld_imgi_2d_u32 : LoadImage2D<"ldimage_v4_2d_s32_rwimg_u32">;
def ld_imgui_2d_u32 : LoadImage2D<"ldimage_v4_2d_u32_rwimg_u32">;

// load image 2d array

def ld_imgf_2da_u32 : LoadImage3D<"ldimage_v4_2da_f32_rwimg_u32">;
def ld_imgi_2da_u32 : LoadImage3D<"ldimage_v4_2da_s32_rwimg_u32">;
def ld_imgui_2da_u32 : LoadImage3D<"ldimage_v4_2da_u32_rwimg_u32">;

// load image 3d

def ld_imgf_3d_u32 : LoadImage3D<"ldimage_v4_3d_f32_rwimg_u32">;
def ld_imgi_3d_u32 : LoadImage3D<"ldimage_v4_3d_s32_rwimg_u32">;
def ld_imgui_3d_u32 : LoadImage3D<"ldimage_v4_3d_u32_rwimg_u32">;

// load image 2ddepth
def ld_imgf_2ddepth_u32 : LoadImage2DDepth<"ldimage_2ddepth_f32_rwimg_u32">;

// load image 2dadepth
def ld_imgf_2dadepth_u32 : LoadImage2DArrayDepth<"ldimage_2dadepth_f32_rwimg_u32">;

// Image store
class StImage1d<Intrinsic intr, string asm, ValueType ValTy, 
        ValueType CoordTy> :  HSAILInst<(outs),
        (ins GPR32:$src1, GPR32:$src2, GPR32:$src3, GPR32:$src4, 
          GPR64:$src5, GPR32:$src6),
        !strconcat(asm, "\t ( $src1, $src2, $src3, $src4 ), $src5, "
                        "$src6"),
        [(intr (ValTy GPR32:$src1), (ValTy GPR32:$src2), 
          (ValTy GPR32:$src3), (ValTy GPR32:$src4),
            (i64 GPR64:$src5), 
            (CoordTy GPR32:$src6))]>;

class StImage2d<Intrinsic intr, string asm, ValueType ValTy, 
        ValueType CoordTy> :  HSAILInst<(outs),
        (ins GPR32:$src1, GPR32:$src2, GPR32:$src3, GPR32:$src4, 
                GPR64:$src5, GPR32:$src6, GPR32:$src7),
        !strconcat(asm, "\t ( $src1, $src2, $src3, $src4 ), $src5, "
                        "( $src6, $src7 )"),
        [(intr (ValTy GPR32:$src1), (ValTy GPR32:$src2), 
          (ValTy GPR32:$src3), (ValTy GPR32:$src4),
            (i64 GPR64:$src5), 
            (CoordTy GPR32:$src6), (CoordTy GPR32:$src7))]>;

class StImage3d<Intrinsic intr, string asm, ValueType ValTy, 
        ValueType CoordTy> :  HSAILInst<(outs), 
        (ins GPR32:$src1, GPR32:$src2, GPR32:$src3, GPR32:$src4, 
          GPR64:$src5, 
          GPR32:$src6, GPR32:$src7, GPR32:$src8, GPR32:$src9),
        !strconcat(asm, "\t ( $src1, $src2, $src3, $src4 ), $src5, "
                        "( $src6, $src7, $src8, $src9 )"),
        [(intr (ValTy GPR32:$src1), (ValTy GPR32:$src2), 
          (ValTy GPR32:$src3), (ValTy GPR32:$src4),
            (i64 GPR64:$src5), 
            (CoordTy GPR32:$src6), (CoordTy GPR32:$src7),
            (CoordTy GPR32:$src8), (CoordTy GPR32:$src9))]>;

//image 2.0 2d depth
class StImage2dDepth<Intrinsic intr, string asm, ValueType ValTy,
        ValueType CoordTy> :  HSAILInst<(outs),
        (ins GPR32:$src1,
            GPR64:$src2, GPR32:$src3, GPR32:$src4),
        !strconcat(asm, "\t $src1, $src2, "
                        "( $src3, $src4 )"),
        [(intr (ValTy GPR32:$src1),
            (i64 GPR64:$src2),
            (CoordTy GPR32:$src3), (CoordTy GPR32:$src4))]>;

//image 2.0 2d array depth
class StImage2dArrayDepth<Intrinsic intr, string asm, ValueType ValTy,
        ValueType CoordTy> :  HSAILInst<(outs),
        (ins GPR32:$src1,
            GPR64:$src2,
			GPR32:$src3, GPR32:$src4, GPR32:$src5, GPR32:$src6),
        !strconcat(asm, "\t $src1, $src2, "
                        "( $src3, $src4, $src5, $src6 )"),
        [(intr (ValTy GPR32:$src1),
            (i64 GPR64:$src2),
            (CoordTy GPR32:$src3), (CoordTy GPR32:$src4),
			(CoordTy GPR32:$src5), (CoordTy GPR32:$src6))]>;

// store image 1d
def stimagef_1d_i32 : StImage1d<int_HSAIL_stimagef_1d_i32,
      "stimage_v4_1d_f32_rwimg_u32", f32, i32>;
def stimagei_1d_i32 : StImage1d<int_HSAIL_stimagei_1d_i32,
      "stimage_v4_1d_s32_rwimg_u32", i32, i32>;
def stimageui_1d_i32 : StImage1d<int_HSAIL_stimageui_1d_i32,
      "stimage_v4_1d_u32_rwimg_u32", i32, i32>;

// store image 1d array
def stimagef_1da_i32 : StImage2d<int_HSAIL_stimagef_1da_i32,
      "stimage_v4_1da_f32_rwimg_u32", f32, i32>;
def stimagei_1da_i32 : StImage2d<int_HSAIL_stimagei_1da_i32,
      "stimage_v4_1da_s32_rwimg_u32", i32, i32>;
def stimageui_1da_i32 : StImage2d<int_HSAIL_stimageui_1da_i32,
      "stimage_v4_1da_u32_rwimg_u32", i32, i32>;

// store image 1d buffer
def stimagef_1db_i32 : StImage1d<int_HSAIL_stimagef_1db_i32,
      "stimage_v4_1db_f32_rwimg_u32", f32, i32>;
def stimagei_1db_i32 : StImage1d<int_HSAIL_stimagei_1db_i32,
      "stimage_v4_1db_s32_rwimg_u32", i32, i32>;
def stimageui_1db_i32 : StImage1d<int_HSAIL_stimageui_1db_i32,
      "stimage_v4_1db_u32_rwimg_u32", i32, i32>;

// store image 2d
def stimagef_2d_i32 : StImage2d<int_HSAIL_stimagef_2d_i32,
      "stimage_v4_2d_f32_rwimg_u32", f32, i32>;
def stimagei_2d_i32 : StImage2d<int_HSAIL_stimagei_2d_i32,
      "stimage_v4_2d_s32_rwimg_u32", i32, i32>;
def stimageui_2d_i32 : StImage2d<int_HSAIL_stimageui_2d_i32,
      "stimage_v4_2d_u32_rwimg_u32", i32, i32>;

// store image 2d array
def stimagef_2da_i32 : StImage3d<int_HSAIL_stimagef_2da_i32,
      "stimage_v4_2da_f32_rwimg_u32", f32, i32>;
def stimagei_2da_i32 : StImage3d<int_HSAIL_stimagei_2da_i32,
      "stimage_v4_2da_s32_rwimg_u32", i32, i32>;
def stimageui_2da_i32 : StImage3d<int_HSAIL_stimageui_2da_i32,
      "stimage_v4_2da_u32_rwimg_u32", i32, i32>;

// store image 3d
def stimagef_3d_i32 : StImage3d<int_HSAIL_stimagef_3d_i32,
      "stimage_v4_3d_f32_rwimg_u32", f32, i32>;
def stimagei_3d_i32 : StImage3d<int_HSAIL_stimagei_3d_i32,
      "stimage_v4_3d_s32_rwimg_u32", i32, i32>;
def stimageui_3d_i32 : StImage3d<int_HSAIL_stimageui_3d_i32,
      "stimage_v4_3d_u32_rwimg_u32", i32, i32>;

// store image 2d depth
def stimagef_2ddepth_i32 : StImage2dDepth<int_HSAIL_stimagef_2ddepth_i32,
      "stimage_2ddepth_f32_rwimg_u32", f32, i32>;

// Store image 2d array depth
def stimagef_2dadepth_i32 : StImage2dArrayDepth<int_HSAIL_stimagef_2dadepth_i32,
      "stimage_2dadepth_f32_rwimg_u32", f32, i32>;

} // isImageInst end

// Query image
class QueryImage<Intrinsic intr, string asm> : HSAILInst<
        (outs GPR32:$dst), (ins GPR64:$src),
        !strconcat(asm, "\t $dst, $src"),
        [(set (i32 GPR32:$dst), (intr (i64 GPR64:$src)))]>;

def query_width_1d : QueryImage<int_HSAIL_query_width_1d,  "queryimage_1d_width_u32_rwimg">; 
def query_width_1db: QueryImage<int_HSAIL_query_width_1db, "queryimage_1db_width_u32_rwimg">;
def query_width_1da: QueryImage<int_HSAIL_query_width_1da, "queryimage_1da_width_u32_rwimg">;
def query_width_2d : QueryImage<int_HSAIL_query_width_2d,  "queryimage_2d_width_u32_rwimg">;
def query_width_2da: QueryImage<int_HSAIL_query_width_2da, "queryimage_2da_width_u32_rwimg">;
def query_width_3d : QueryImage<int_HSAIL_query_width_3d,  "queryimage_3d_width_u32_rwimg">;
def query_width_2ddepth  : QueryImage<int_HSAIL_query_width_2ddepth,  "queryimage_2ddepth_width_u32_rwimg">;
def query_width_2dadepth : QueryImage<int_HSAIL_query_width_2dadepth, "queryimage_2dadepth_width_u32_rwimg">;


def query_height_2d : QueryImage<int_HSAIL_query_height_2d,  "queryimage_2d_height_u32_rwimg">;
def query_height_2da: QueryImage<int_HSAIL_query_height_2da, "queryimage_2da_height_u32_rwimg">;
def query_height_3d : QueryImage<int_HSAIL_query_height_3d,  "queryimage_3d_height_u32_rwimg">;
def query_height_2ddepth  : QueryImage<int_HSAIL_query_height_2ddepth,  "queryimage_2ddepth_height_u32_rwimg">;
def query_height_2dadepth : QueryImage<int_HSAIL_query_height_2dadepth, "queryimage_2dadepth_height_u32_rwimg">;

def query_depth : QueryImage<int_HSAIL_query_depth_3d, "queryimage_3d_depth_u32_rwimg">;

def query_format_1d : QueryImage<int_HSAIL_query_format_1d,  "queryimage_1d_channeltype_u32_rwimg">; 
def query_format_1db: QueryImage<int_HSAIL_query_format_1db, "queryimage_1db_channeltype_u32_rwimg">;
def query_format_1da: QueryImage<int_HSAIL_query_format_1da, "queryimage_1da_channeltype_u32_rwimg">;
def query_format_2d : QueryImage<int_HSAIL_query_format_2d,  "queryimage_2d_channeltype_u32_rwimg">;
def query_format_2da: QueryImage<int_HSAIL_query_format_2da, "queryimage_2da_channeltype_u32_rwimg">;
def query_format_3d : QueryImage<int_HSAIL_query_format_3d,  "queryimage_3d_channeltype_u32_rwimg">;

def query_order_1d : QueryImage<int_HSAIL_query_order_1d,  "queryimage_1d_channelorder_u32_rwimg">; 
def query_order_1db: QueryImage<int_HSAIL_query_order_1db, "queryimage_1db_channelorder_u32_rwimg">;
def query_order_1da: QueryImage<int_HSAIL_query_order_1da, "queryimage_1da_channelorder_u32_rwimg">;
def query_order_2d : QueryImage<int_HSAIL_query_order_2d,  "queryimage_2d_channelorder_u32_rwimg">;
def query_order_2da: QueryImage<int_HSAIL_query_order_2da, "queryimage_2da_channelorder_u32_rwimg">;
def query_order_3d : QueryImage<int_HSAIL_query_order_3d,  "queryimage_3d_channelorder_u32_rwimg">;

def query_array_1da: QueryImage<int_HSAIL_query_array_1da, "queryimage_1da_array_u32_rwimg">;
def query_array_2da: QueryImage<int_HSAIL_query_array_2da, "queryimage_2da_array_u32_rwimg">;
def query_array_2dadepth : QueryImage<int_HSAIL_query_array_2dadepth, "queryimage_2dadepth_array_u32_rwimg">;

def query_channelorder_2ddepth  : QueryImage<int_HSAIL_query_channelorder_2ddepth,  "queryimage_2ddepth_channelorder_u32_rwimg">;
def query_channelorder_2dadepth : QueryImage<int_HSAIL_query_channelorder_2dadepth, "queryimage_2dadepth_channelorder_u32_rwimg">;

def query_channeltype_2ddepth  : QueryImage<int_HSAIL_query_channeltype_2ddepth,  "queryimage_2ddepth_channeltype_u32_rwimg">;
def query_channeltype_2dadepth : QueryImage<int_HSAIL_query_channeltype_2dadepth, "queryimage_2dadepth_channeltype_u32_rwimg">;

