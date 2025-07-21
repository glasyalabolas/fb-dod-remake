#include once "fbgfx.bi"

type Minimap
  as long cellSize
  as ulong roomColor
  as ulong wallColor
  as ulong unvisitedColor
  
  as double blinkTime
  as double lastBlinkTime
  as boolean playerVisible
  
  as Fb.Image ptr buffer
  as Map ptr map
end type

sub minimap_init(p as Minimap ptr)
  p->lastBlinkTime = timer()
  p->playerVisible = true
end sub

sub minimap_process(p as Minimap ptr)
  dim as double elapsed = timer() - p->lastBlinkTime
  
  if (elapsed > p->blinkTime) then
    p->playerVisible xor= true
    p->lastBlinkTime = timer()
  end if
end sub

sub minimap_render(p as Minimap ptr)
  var m = p->map
  
  for y as integer = 0 to m->h - 1
    for x as integer = 0 to m->w - 1
      var cell = @m->cell(x, y)
      
      dim as long x0 = x * p->cellSize, y0 = y * p->cellSize
      dim as long x1 = x0 + p->cellSize - 1, y1 = y0 + p->cellSize - 1
      
      dim as ulong cellColor = iif(FLAG_ISSET(cell->flags, CELL_VISITED), p->roomColor, p->unvisitedColor)
      line p->buffer, (x0, y0) - (x1, y1), cellColor, bf
      
      if (FLAG_ISSET(cell->flags, CELL_DISPLAYED or CELL_VISITED)) then
        dim as long wx0 = x0, wy0 = y0
        dim as long wx1 = x1, wy1 = y1
        
        dim as long wallSize = 1
        
        for i as integer = 0 to wallSize - 1
          line p->buffer, (wx0, wy0) - (wx1, wy1), p->wallColor, b
          wx0 += 1 : wy0 += 1
          wx1 -= 1 : wy1 -= 1
        next
        
        dim as long doorSize = p->cellSize * 0.3
        dim as long doorPos
        
        if (cell->north) then
          doorPos = map_getDoorPos(cell->northA, p->cellSize, doorSize)
          line p->buffer, (x0 + doorPos, y0) - (x0 + doorPos + doorSize - 1, y0 + wallSize), cellColor, bf
        end if
        
        if (cell->south) then
          doorPos = map_getDoorPos(cell->southA, p->cellSize, doorSize)
          line p->buffer, (x0 + doorPos, y1 - wallSize) - (x0 + doorPos + doorSize - 1, y1), cellColor, bf
        end if
        
        if (cell->west) then
          doorPos = map_getDoorPos(cell->westA, p->cellSize, doorSize)
          line p->buffer, (x0, y0 + doorPos) - (x0 + wallSize, y0 + doorPos + doorSize - 1), cellColor, bf
        end if
        
        if (cell->east) then
          doorPos = map_getDoorPos(cell->eastA, p->cellSize, doorSize)
          line p->buffer, (x1 - wallSize, y0 + doorPos) - (x1, y0 + doorPos + doorSize - 1), cellColor, bf
        end if
        
        var e = cell->entity
        
        if (e) then
          if (e->onMinimapRender) then
            e->onMinimapRender(e, p)
          end if
        end if
      end if      
    next
  next
  
  '' Render player
  '' The player is assumed to be the first element on the list
  dim as GEntity ptr e = p->map->entities.first->item
  
  if (e) then
    if (e->onMinimapRender) then
      e->onMinimapRender(e, p)
    end if
  end if
end sub
