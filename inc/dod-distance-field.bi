#include once "fb-linkedlist.bi"
#include once "dod-entity.bi"

enum DF_FLAGS
  DF_NONE
  DF_IMPASSABLE = 1 shl 0
  DF_ENTITY     = 1 shl 1
end enum

type DistanceFieldCell
  as long x, y
  as long cost
  as long iter
  
  as DF_FLAGS flags
end type

type DistanceField
  as long w, h
  as DistanceFieldCell cell(any, any)
end type

sub distance_field_reset(df as DistanceField ptr, entities as Fb.LinkedList ptr)
  for y as integer = 0 to df->h - 1
    for x as integer = 0 to df->w - 1
      df->cell(x, y).cost = 65535
      FLAG_CLEAR(df->cell(x, y).flags, DF_ENTITY)
    next
  next
  
  var n = entities->first
  
  do while (n)
    dim as GEntity ptr entity = n->item
    
    if (entity->gtype <> ENTITY_PLAYER) then
      FLAG_SET(df->cell(entity->x, entity->y).flags, DF_ENTITY)
    end if
    
    n = n->forward
  loop
end sub

function distance_field_create(w as long, h as long) as DistanceField ptr
  var df = new DistanceField
  
  redim (df->cell)(0 to w - 1, 0 to h - 1)
  
  df->w = w
  df->h = h
  
  for y as integer = 0 to df->h - 1
    for x as integer = 0 to df->w - 1
      df->cell(x, y).x = x
      df->cell(x, y).y = y
    next
  next
  
  return df
end function

function distance_field_inside(df as DistanceField ptr, x as long, y as long) as boolean
  return x >= 0 andAlso x <= df->w - 1 andAlso y >= 0 andAlso y <= df->h - 1
end function

sub distance_field_compute(df as DistanceField ptr, entities as Fb.LinkedList ptr, startX as long, startY as long)
  static as Fb.LinkedList openList
  openList.clear()
  
  distance_field_reset(df, entities)
  
  for y as integer = -1 to 1
    for x as integer = -1 to 1
      if (distance_field_inside(df, startX + x, startY + y)) then
        if (not FLAG_ISSET(df->cell(startX + x, startY + y).flags, DF_IMPASSABLE) andAlso _
            not FLAG_ISSET(df->cell(startX + x, startY + y).flags, DF_ENTITY)) then
          
          df->cell(startX + x, startY + y).cost = 0
        end if
      end if
    next
  next
  
  var startCell = @(df->cell(startX, startY))
  
  startCell->cost = -1
  startCell->iter += 1
  
  dim as long iter = startCell->iter
  
  openList.addLast(startCell)
  
  do while (openList.count > 0)
    dim as DistanceFieldCell ptr cell = openList.removeFirst()
    
    for y as integer = -1 to 1
      for x as integer = -1 to 1
        if (distance_field_inside(df, cell->x + x, cell->y + y)) then
          var neighbor = @(df->cell(cell->x + x, cell->y + y))
          
          if (neighbor->iter <> iter) then
            if (not FLAG_ISSET(neighbor->flags, DF_IMPASSABLE) andAlso _
                not FLAG_ISSET(neighbor->flags, DF_ENTITY)) then
              
              if (cell->cost < neighbor->cost) then
                neighbor->cost = cell->cost + 1
                neighbor->iter = iter
                
                openList.addLast(neighbor)
              end if
            end if
          end if
        end if
      next
    next
  loop
end sub
