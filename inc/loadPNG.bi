#ifdef __FB_64BIT__
  #ifdef __FB_LINUX__
    #libpath "inc/lin"
  #else
    #libpath "inc/win"
  #endif
  #inclib "loadPNG64"
#else
  #ifdef __FB_LINUX__
    #libpath "inc/lin"
  #else
    #libpath "inc/win"
  #endif
  #inclib "loadPNG32"
#endif

#include once "fbgfx.bi"

extern "C"
  declare function LoadPNG(filename as zstring ptr) as Fb.Image ptr
  declare function SavePNG(finename as zstring ptr, image as Fb.Image ptr) as long
end extern
