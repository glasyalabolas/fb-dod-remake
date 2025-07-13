#include once "fbgfx.bi"
#include once "crt.bi"

#define TRANSPARENT rgba(0, 0, 0, 0)

#ifndef loadTGA
  '' Loads a TGA image info a Fb.Image buffer.
  '' Currently this only loads 32-bit *uncompressed* TGA files.		
  function loadTGA( aPath as const string ) as Fb.Image ptr
    '' TGA file format header
    type __TGAHeader__ field = 1
      as ubyte _
        idLength, _
        colorMapType, _
        dataTypeCode
      as short _
        colorMapOrigin, _
        colorMapLength
      as ubyte _
        colorMapDepth
      as short _
        x_origin, _
        y_origin, _
        width, _
        height
      as ubyte _
        bitsPerPixel, _
        imageDescriptor
    end type
    
    dim as long fileHandle = freeFile()
    
    dim as Fb.Image ptr image
    
    '' Open file
    dim as integer result = open( aPath for binary access read as fileHandle )
    
    if( result = 0 ) then
      '' Retrieve header
      dim as __TGAHeader__ h
      
      get #fileHandle, , h
      
      if( h.dataTypeCode = 2 andAlso h.bitsPerPixel = 32 ) then
        '' Create the image
        image = imageCreate( h.width, h.height, rgba( 0, 0, 0, 0 ) )
        
        '' Pointer to pixel data				
        dim as ulong ptr pix = cptr( ulong ptr, image ) + sizeof( Fb.Image ) \ sizeof( ulong )
        
        '' Get size of padding, as FB aligns the width of its images
        '' to the paragraph (16 bytes) boundary.
        dim as integer padd = image->pitch \ sizeof( ulong )
        
        '' Allocate temporary buffer to hold pixel data
        dim as ulong ptr buffer = allocate( ( h.width * h.height ) * sizeof( ulong ) )
        
        '' Read pixel data from file
        get #fileHandle, , *buffer, h.width * h.height
        
        close( fileHandle )
        
        '' Load pixel data onto image
        for y as integer = 0 to h.height - 1
          for x as integer = 0 to h.width - 1
            dim as integer yy = iif( h.y_origin = 0, ( h.height - 1 ) - y, y )
            
            pix[ yy * padd + x ] = buffer[ y * h.width + x ]
          next
        next
        
        deallocate( buffer )
      else
        ? "Unknown file format!"
      end if
    else
      ? "Error opening file!"
    end if
    
    return( image )
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
  var tile = loadTGA(fileName)
  dim as Fb.Image ptr result
  
  if (tile) then
    result = image_resize(tile, w, h)
    imageDestroy(tile)
  end if
  
  return result
end function

'' Loads an image, original size
function image_load overload(fileName as string) as Fb.Image ptr
  var tile = loadTGA(fileName)
  
  return tile
end function
