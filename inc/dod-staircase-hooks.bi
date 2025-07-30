sub staircase_destroy(e as GEntity ptr)
  delete(e->staircase)
end sub

sub render_triangle( _
  x1 as long, y1 as long,_
  x2 as long, y2 as long, _
  x3 as long, y3 as long, _
  c as ulong, buffer as any ptr = 0 )
  
  if (y2 < y1) then swap y1, y2 : swap x1, x2 : end if
  if (y3 < y1) then swap y3, y1 : swap x3, x1 : end if
  if (y3 < y2) then swap y3, y2 : swap x3, x2 : end if
  
  dim as long _
    delta1 = iif(y2 - y1 <> 0, ((x2 - x1) shl 16) \ (y2 - y1), 0), _
    delta2 = iif(y3 - y2 <> 0, ((x3 - x2) shl 16) \ (y3 - y2), 0), _
    delta3 = iif(y1 - y3 <> 0, ((x1 - x3) shl 16) \ (y1 - y3), 0)
  
  '' Top half
  dim as long lx = x1 shl 16, rx = lx
  
  for y as integer = y1 to y2 - 1
    line buffer, (lx shr 16, y) - (rx shr 16, y), c 
    lx = lx + delta1 : rx = rx + delta3
  next
  
  '' Bottom half
  lx = x2 shl 16
  
  for y as integer = y2 to y3
    line buffer, (lx shr 16, y) - (rx shr 16, y), c 
    lx = lx + delta2 : rx = rx + delta3
  next
end sub

sub staircase_minimap_render(e as GEntity ptr, p as Minimap ptr)
  dim as ulong scColor = rgb(255, 255, 255)
  dim as long size = p->cellSize \ 3
  dim as long x0 = e->room->cell->x * p->cellSize + size, y0 = e->room->cell->y * p->cellSize + size
  dim as long x1 = x0 + size - 1, y1 = y0 + size - 1
  
  'line p->buffer, (x0, y0) - (x1, y1), scColor, bf
  
  if (e->staircase->stype = STAIRCASE_UP) then
    render_triangle(x0, y1, x0 + size * 0.5, y0, x1, y1, scColor, p->buffer)
  else
    render_triangle(x0, y0, x1, y0, x0 + size * 0.5, y1, scColor, p->buffer)
  end if
end sub

sub staircase_render(e as GEntity ptr)
  dim as long tileSize = *(e->room->cell->map->tileInfo.tileSize)
  
  put(e->x * tileSize, e->y * tileSize), e->tileset[e->tileId], alpha
end sub

function staircase_collide_up(e as GEntity ptr, who as GEntity ptr) as boolean
  debug("staircase_up")
  
  return false
end function

function staircase_collide_down(e as GEntity ptr, who as GEntity ptr) as boolean
  debug("staircase_down")
  
  return false
end function

function staircase_create(stype as STAIRCASE_TYPE, x as long, y as long) as GEntity ptr
  var e = new GEntity
  var s = new GStaircase
  
  s->stype = stype
  
  e->staircase = s
  e->gtype = ENTITY_STAIRCASE
  e->name = "Staircase " & iif(s->stype = STAIRCASE_UP, "up", "down")
  e->x = x
  e->y = y
  e->tileId = iif(s->stype = STAIRCASE_UP, 0, 1)
  e->tileset = GStaircase.tileset
  e->shownOnMap = true
  
  e->onDestroy = @staircase_destroy
  e->onRender = @staircase_render
  e->onMinimapRender = @staircase_minimap_render
  e->onCollide = iif(s->stype = STAIRCASE_UP, @staircase_collide_up, @staircase_collide_down)
  
  return e
end function
