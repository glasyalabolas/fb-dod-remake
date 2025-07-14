#include once "fbgfx.bi"
#include once "crt.bi"
#include once "file.bi"

#define TRANSPARENT rgba(0, 0, 0, 0)

#ifndef loadBMP
  function loadBMP(path as const string) as Fb.Image ptr
    #define __BM_WINDOWS__ &h4D42
    
    type __BITMAPFILEHEADER__ field = 1
      as ushort id
      as ulong size
      as ubyte reserved(0 to 3)
      as ulong offset
    end type
    
    type __BITMAPINFOHEADER__ field = 1
      as ulong size
      as long width
      as long height
      as ushort planes
      as ushort bpp
      as ulong compression_method
      as ulong image_size
      as ulong h_res
      as ulong v_res
      as ulong color_palette_num
      as ulong colors_used
    end type
    
    dim as any ptr img = 0
    
    if (fileExists(path)) then
      dim as __BITMAPFILEHEADER__ header 
      dim as __BITMAPINFOHEADER__ info
      
      dim as long f = freeFile()
      
      open path for binary as f
        get #f, , header
        get #f, sizeof( header ) + 1, info
      close(f)
      
      '' Check if the file is indeed a Windows bitmap
      if (header.id = __BM_WINDOWS__) then
        img = imageCreate(info.width, abs(info.height))
        bload(path, img)
      end if
    end if
    
    return img
  end function
#endif

function image_pixels(img as Fb.Image ptr) as ulong ptr
  return cast(ulong ptr, cast(ubyte ptr, img) + sizeof(Fb.Image))
end function

function image_pitchInPixels(img as Fb.Image ptr) as long
  return img->pitch \ sizeof(ulong)
end function

function image_copy(src as Fb.Image ptr) as Fb.Image ptr
  dim as Fb.Image ptr dst = imageCreate(src->width, src->height, TRANSPARENT)
  
  dim as ulong ptr dstPixels = image_pixels(dst)
  dim as ulong ptr srcPixels = image_pixels(src)
  
  memcpy(dstPixels, srcPixels, src->height * src->pitch)
  
  return dst
end function

function image_equals(src as Fb.Image ptr, dst as Fb.Image ptr) as boolean
  if (src->width <> dst->width orElse src->height <> dst->height) then
    return false
  end if
  
  dim as ulong ptr srcPixels = image_pixels(src)
  dim as ulong ptr dstPixels = image_pixels(dst)
  dim as long pitch = image_pitchInPixels(src)
  
  for y as integer = 0 to src->height - 1
    for x as integer = 0 to src->width - 1
      if (srcPixels[y * src->height + x] <> dstPixels[y * dst->height + x]) then
        return false
      end if
    next
  next
  
  return true
end function

function image_empty(src as Fb.Image ptr) as boolean
  dim as ulong ptr srcPixels = image_pixels(src)
  dim as long pitch = image_pitchInPixels(src)
  
  for y as integer = 0 to src->height - 1
    for x as integer = 0 to src->width - 1
      if (srcPixels[y * src->height + x] <> rgba(0, 0, 0, 0)) then
        return false
      end if
    next
  next
  
  return true
end function

function image_resize(src as Fb.Image ptr, newW as long, newH as long) as Fb.Image ptr
  dim as Fb.Image ptr dst = imageCreate(newW, newH, TRANSPARENT)
  
  dim as long spitch = image_pitchInPixels(src)
  dim as long dpitch = image_pitchInPixels(dst)
  
  dim as long _
    x_ratio = ((src->width shl 16 ) \ dst->width) + 1, _
    y_ratio = ((src->height shl 16 ) \ dst->height) + 1
  
  var srcPx = image_pixels(src)
  var dstPx = image_pixels(dst)
  
  for y as integer = 0 to dst->height - 1
    for x as integer = 0 to dst->width - 1
      dstPx[y * dpitch + x] = srcPx[((y * y_ratio) shr 16) * spitch + ((x * x_ratio) shr 16)]
    next
  next
  
  return dst
end function

'' Loads an image, resized to the specified size
function image_load overload(fileName as string, w as long, h as long) as Fb.Image ptr
  var tile = loadBMP(fileName)
  dim as Fb.Image ptr result
  
  if (tile) then
    result = image_resize(tile, w, h)
    imageDestroy(tile)
  end if
  
  return result
end function

'' Loads an image, original size
function image_load overload(fileName as string) as Fb.Image ptr
  var tile = loadBMP(fileName)
  
  return tile
end function
