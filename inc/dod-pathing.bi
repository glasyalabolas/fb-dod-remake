type DistanceFieldCell
  as long x, y
  as long distance
  as long iter
end type

type DistanceField
  as long w, h
  as DistanceFieldCell cell(any, any)
end type

function distance_field_create(room as MapRoom ptr) as DistanceField ptr
  var dfield = new DistanceField
  
  redim (dfield->cell)(0 to room->w - 1, 0 to room->h - 1)
  
  dfield->w = room->w
  dfield->h = room->h
  
  return dfield
end function

#define LARGE_DISTANCE 999

sub distance_field_compute(dfield as DistanceField ptr, room as MapRoom ptr, targetX as long, targetY as long)
  var openList = new Fb.LinkedList()
  
  var endCell = @(dfield->cell(targetX, targetY))
  
  dim as long iter = endCell->iter + 1
  
  endCell->x = targetX
  endCell->y = targetY
  endCell->distance = 0
  
  openList->addFirst(endCell)
  
  do while (openList->count > 0)
    dim as DistanceFieldCell ptr current = openList->removeFirst()
    
    current->iter = iter
    
    for y as integer = current->y - 1 to current->y + 1
      for x as integer = current->x - 1 to current->x + 1
        if (x <> 0 orElse y <> 0) then
          if (room_inside(room, x, y)) then
            if (dfield->cell(x, y).iter <> iter) then
              if (not FLAG_ISSET(room->tile(x, y).flags, TILE_IMPASSABLE)) then
                dfield->cell(x, y).distance = current->distance + 1
                
                dfield->cell(x, y).x = x
                dfield->cell(x, y).y = y
                
                openList->addLast(@(dfield->cell(x, y)))
              end if
            end if
          end if
        end if
      next
    next
  loop
  
  delete(openList)
end sub

sub distance_field_destroy(dfield as DistanceField ptr)
  delete(dfield)
end sub
