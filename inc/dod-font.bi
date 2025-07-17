#include once "fbgfx.bi"

type BMFontGlyph
  as long w
  as ubyte ptr data
end type

type BMFont
  as long h
  as BMFontGlyph glyph(33 to 127)
end type

function font_create() as BMFont ptr
  return new BMFont
end function

sub font_destroy(f as BMFont ptr)
  for i as integer = 33 to 127
    if (f->glyph(i).data) then
      deallocate(f->glyph(i).data)
    end if
  next
  
  delete(f)
end sub
    
function font_load(filename as string) as BMFont ptr
  var fnt = font_create()

  dim as long fh = freeFile()

  open filename for binary access read as fh
    get #fh, , fnt->h
    
    for i as integer = 33 to 127
      get #fh, , fnt->glyph(i).w
      
      fnt->glyph(i).data = allocate(fnt->glyph(i).w * fnt->h)
      
      get #fh, , *(fnt->glyph(i).data), fnt->glyph(i).w * fnt->h
    next
  close(fh)
  
  return fnt
end function

sub font_render_glyph( _
  f as BMFont ptr, idx as long, x as long, y as long, fcolor as ulong, dstBuffer as Fb.Image ptr = 0, opacity as ulong = 256 )
  
  #define __min__(_a_, _b_) iif(_a_ < _b_, _a_, _b_)
  #define __max__(_a_, _b_) iif(_a_ > _b_, _a_, _b_)
  #define __R__(c) (culng( c ) shr 16 and 255)
  #define __G__(c) (culng( c ) shr  8 and 255)
  #define __B__(c) (culng( c )        and 255)
  #define __A__(c) (culng( c ) shr 24        )  
  
  dim as ulong ptr dstp
  dim as long dstStride, dstWidth, dstHeight
  
  if (dstBuffer) then
    '' Blitting to a buffer
    dstp = cptr(ulong ptr, cptr(ubyte ptr, dstBuffer) + sizeof(Fb.Image))
    dstStride = dstBuffer->pitch shr 2'\ sizeof(ulong)
    dstWidth = dstBuffer->width
    dstHeight = dstBuffer->height
  else
    '' Blitting to the screen
    dstp = cptr(ulong ptr, screenptr())
    
    dim as long scW, scH
    screenInfo(scW, scH)
    
    dstStride = scW
    dstWidth = scW
    dstHeight = scH
  end if
  
  dim as ubyte ptr srcp = f->glyph(idx).data
  dim as long srcStride = f->glyph(idx).w
  
  dim as long srcW = f->glyph(idx).w, srcH = f->h
  
  dim as integer _
    dstStartX = __max__(0,  x), dstStartY = __max__(0,  y), _
    srcStartX = __max__(0, -x), srcStartY = __max__(0, -y), _
    srcEndX = __min__(srcW - 1, ((dstWidth - 1) - (x + srcW - 1)) + srcW - 1), _
    srcEndY = __min__(srcH - 1, ((dstHeight - 1) - (y + srcH - 1)) + srcH - 1)
  
  if (dstBuffer = 0) then
    screenLock()
  end if
  
  dim as long dstOffX = dstStartX - srcStartX
  dim as long dstOffY = dstStartY - srcStartY
  
  #define src_r __R__(srcc)
  #define src_g __G__(srcc)
  #define src_b __B__(srcc)
  #define src_a __A__(srcc)
  
  #define dst_r __R__(dstc)
  #define dst_g __G__(dstc)
  #define dst_b __B__(dstc)
  #define dst_a __A__(dstc)
  
  dim as long dstpx, srcpx
  dim as ulong dstc, srcc
  
  for yy as integer = srcStartY to srcEndY
    for xx as integer = srcStartX to srcEndX
      dstpx = (dstOffY + yy) * dstStride + (dstOffX + xx)
      srcpx = yy * srcStride + xx
      dstc = dstp[ dstpx ]
      srcc = rgba(__R__(fcolor), __G__(fcolor), __B__(fcolor), (__A__(fcolor) * srcp[srcpx]) shr 8)
      
      dstp[dstpx] = rgba( _
        dst_r + (opacity * ((dst_r + (src_a * (src_r - dst_r)) shr 8) - dst_r) shr 8), _
        dst_g + (opacity * ((dst_g + (src_a * (src_g - dst_g)) shr 8) - dst_g) shr 8), _
        dst_b + (opacity * ((dst_b + (src_a * (src_b - dst_b)) shr 8) - dst_b) shr 8), _
        dst_a + (opacity * ((src_a * (256 - dst_a)) shr 8) shr 8))
    next
  next
  
  if (dstBuffer = 0) then
    screenUnlock()
  end if
end sub

sub font_text_render(f as BMFont ptr, text as string, x as long, y as long, clr as ulong, buffer as Fb.Image ptr = 0)
  for i as integer = 0 to len(text) - 1
    if (text[i] >= 33) then
      font_render_glyph(f, text[i], x, y, clr, buffer)
      x += f->glyph(text[i]).w
    else
      x += f->h shr 1
    end if
  next
end sub

'' Returns the width of the string, in pixels, for the specified text
function font_text_measure(f as BMFont ptr, text as string) as integer
  dim as long w
  
  for i as integer = 0 to len(text) - 1
    if (text[i] >= 33) then
      w += f->glyph(text[i]).w
    else
      w += f->h shr 1
    end if
  next
  
  return w
end function

'' Returns how many chars can fit into the specified width in pixels
function font_measure_chars(f as BMFont ptr, text as string, w as long, startPos as integer = 0) as integer
  if (startPos > len(text)) then return 0
  
  dim as integer textLen = font_text_measure(f, text)
  dim as integer charPos = 0
  dim as integer curLen = 0
  
  if (textLen > w) then
    for i as integer = startPos to len(text) - 1
      if (text[i] >= 33) then
        curLen += f->glyph(text[i]).w
      else
        curLen += f->h shr 1
      end if
      
      if (curLen > w) then
        if (text[i - 1] >= 33) then
          curLen -= f->glyph(text[i - 1]).w
        else
          curLen -= f->h shr 1
        end if
        
        charPos -= 1
        exit for
      end if
      
      charPos += 1
    next
    
    return charPos + 1
  end if
  
  return len(text)
end function

sub font_text_wrap(lines() as string, f as BMFont ptr, text as string, w as long)
  #ifndef ARRAY_ADD
    #macro ARRAY_ADD(_a_, _e_)
      redim preserve _a_(0 to ubound(_a_) + 1)
      _a_(ubound(_a_)) = _e_
    #endmacro
  #endif
  
  #define IS_WHITESPACE(_c_) (_c_ = 13 or _c_ = 10 or _c_ = 32 or _c_ = 9)
  dim as string sep = chr(13, 10, 9, 32)
  
  dim as string st = trim(text)
  dim as long startPos = 1
  
  do while (startPos < len(st))
    dim as string curLine = mid(st, startPos, font_measure_chars(f, st, w, startPos - 1))
    dim as integer sepPos
    
    if (len(curLine) andAlso startPos + len(curLine) < len(st)) then
      if (not IS_WHITESPACE(curLine[len(curLine) - 1])) then
        sepPos = inStrRev(curLine, any sep)
        
        if (sepPos <> 0) then
          curLine = mid(curLine, 1, sepPos)
        end if
      end if
    end if
    
    ARRAY_ADD(lines, curLine)
    
    startPos += len(curLine)
  loop
end sub
