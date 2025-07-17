#include once "dod-font.bi"

type GMessageBoxLine
  as string text
  as ulong color
end type

type GMessageBox
  as long maxRows
  as long colWidth
  as BMFont ptr font
  as Fb.LinkedList lines
end type

function messagebox_create(maxRows as long, colWidth as long) as GMessageBox ptr
  var mb = new GMessageBox
  
  mb->maxRows = maxRows
  mb->colWidth = colWidth
  
  return mb
end function

sub messagebox_destroy(mb as GMessageBox ptr)
  do while (mb->lines.count > 0)
    delete(cptr(GMessageBoxLine ptr, mb->lines.removeFirst()))
  loop
  
  if (mb->font) then
    font_destroy(mb->font)
  end if
  
  delete(mb)
end sub

sub messagebox_set_font(mb as GMessageBox ptr, f as BMFont ptr)
  if (mb->font <> 0) then
    font_destroy(mb->font)
  end if
  
  mb->font = f
end sub

sub message(mb as GMessageBox ptr, msg as string, clr as ulong)
  dim as string lines()
  
  font_text_wrap(lines(), mb->font, msg, mb->colWidth)
  
  for i as integer = 0 to ubound(lines)
    var newLine = new GMessageBoxLine
    
    newLine->text = lines(i)
    newLine->color = clr
    
    mb->lines.addLast(newLine)
  next
  
  do while (mb->lines.count > mb->maxRows)
    delete(cptr(GMessageBoxLine ptr, mb->lines.removeFirst()))
  loop
end sub

sub messagebox_render(mb as GMessageBox ptr, x as long, y as long, buffer as Fb.Image ptr = 0)
  #define __R__(c) (culng( c ) shr 16 and 255)
  #define __G__(c) (culng( c ) shr  8 and 255)
  #define __B__(c) (culng( c )        and 255)
  #define __min__(_a_, _b_) iif(_a_ < _b_, _a_, _b_)
  
  dim as long minAlpha = 32
  dim as long alphaInc = (255 - minAlpha) \ mb->maxRows
  dim as long count = mb->lines.count
  
  var n = mb->lines.first
  
  do while (n)
    dim as GMessageBoxLine ptr tline = n->item
    'dim as long a = __min__(minAlpha + (count + 1 ) * alphaInc, 255)
    dim as long a = __min__(255 - (count * alphaInc), 255)
    
    dim as ulong clr = rgba( _
      __R__(tline->color), __G__(tline->color), __B__(tline->color), a)
    
    font_text_render(mb->font, tline->text, x, y, clr, buffer)
    
    y += mb->font->h
    n = n->forward
    count -= 1
  loop
end sub
