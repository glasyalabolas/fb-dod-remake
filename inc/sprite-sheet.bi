#include once "image.bi"

sub sprite_add(sprites() as Fb.Image ptr, spr as Fb.Image ptr)
  redim preserve sprites(0 to ubound(sprites) + 1)
  sprites(ubound(sprites)) = spr
end sub

function sprite_remove overload(sprites() as Fb.Image ptr, index as integer) as Fb.Image ptr
  var removed = sprites(index)
  
  sprites(index) = sprites(ubound(sprites))
  redim preserve sprites(0 to ubound(sprites) - 1)
  
  return removed
end function

sub sprite_remove(sprites() as Fb.Image ptr, sprite as Fb.Image ptr)
  dim as Fb.Image ptr removed
  
  for i as integer = 0 to ubound(sprites)
    if (sprites(i) = sprite) then
      removed = sprite_remove(sprites(), i)
      exit for
    end if
  next
  
  if (removed) then
    imageDestroy(removed)
  end if
end sub

sub rip_sheet(sheet as Fb.Image ptr, sprites() as Fb.Image ptr, sprW as long, sprH as long)
  dim as long rows = sheet->height \ sprH
  dim as long cols = sheet->width \ sprW
  
  for r as integer = 0 to rows - 1
    for c as integer = 0 to cols - 1
      var sprite = imageCreate(sprW, sprH, rgba(0, 0, 0, 0))
      
      put sprite, (0, 0), sheet, (c * sprW, r * sprH) - (c * sprW + sprW - 1, r * sprH + sprH - 1), alpha
      
      if (not image_empty(sprite)) then
        sprite_add(sprites(), sprite)
      end if
    next
  next
end sub

sub sprite_remove_duplicates(sprites() as Fb.Image ptr)
  dim as Fb.Image ptr duplicates()
  
  for i as integer = 0 to ubound(sprites)
    for k as integer = i + 1 to ubound(sprites)
      if (image_equals(sprites(i), sprites(k))) then
        dim as boolean found
        
        for j as integer = 0 to ubound(duplicates)
          if (sprites(i) = duplicates(j)) then
            found = true
            exit for
          end if
        next
        
        if (not found) then
          redim preserve duplicates(0 to ubound(duplicates) + 1)
          duplicates(ubound(duplicates)) = sprites(k)
        end if
      end if
    next
  next
  
  for i as integer = 0 to ubound(duplicates)
    sprite_remove(sprites(), duplicates(i))
  next
end sub

sub sprites_get(sprites() as Fb.Image ptr, filename as string, tileSize as long, scale as single = 1.0)
  var sheet = loadBMP(filename)
  
  if (sheet) then
    var scaledSheet = image_resize(sheet, sheet->width * scale, sheet->height * scale)
    
    rip_sheet(scaledSheet, sprites(), tileSize * scale, tileSize * scale)
    
    imageDestroy(sheet)
    imageDestroy(scaledSheet)
  end if
end sub

sub sprites_destroy(sprites() as Fb.Image ptr)
  for i as integer = 0 to ubound(sprites)
    imageDestroy(sprites(i))
    sprites(i) = 0
  next
end sub
