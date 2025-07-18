sub paint_wall(room as MapRoom ptr, x as long, y as long)
  var tileInfo = @(room->cell->map->tileInfo)
  var tileset = room->cell->map->_tileset
  
  if (room_inside(room, x, y) andAlso room_inside(room, x, y + 1)) then
    if (not FLAG_ISSET(room->tile(x, y).flags, TILE_DOOR) andAlso not FLAG_ISSET(room->tile(x, y + 1).flags, TILE_DOOR)) then
      with room->tile(x, y)
        .back = tileInfo->_topWallTile
        .backVariation = rng(0, ubound(tileset->wallTops(tileInfo->_topWallTile).tile))
        FLAG_SET(.flags, TILE_IMPASSABLE or TILE_WALL_TOP)
        FLAG_CLEAR(.flags, TILE_FLOOR or TILE_WALL)
      end with
      
      with room->tile(x, y + 1)
        .back = tileInfo->_bottomWallTile
        .backVariation = rng(0, ubound(tileset->walls(tileInfo->_bottomWallTile).tile))
        FLAG_SET(.flags, TILE_IMPASSABLE or TILE_WALL)
        FLAG_CLEAR(.flags, TILE_FLOOR or TILE_WALL_TOP)
      end with
    end if
  end if
end sub

sub paint_floor(room as MapRoom ptr, x as long, y as long)
  var tileInfo = @(room->cell->map->tileInfo)
  var tileset = room->cell->map->_tileset
  
  if (room_inside(room, x, y)) then
    with room->tile(x, y)
      .back = tileInfo->_floorTile
      .backVariation = rng(0, ubound(tileset->floors(tileInfo->_floorTile).tile))
      .flags = 0
      FLAG_SET(.flags, TILE_FLOOR)
    end with
  end if
end sub

sub paint_door(room as MapRoom ptr, x as long, y as long)
  var tileInfo = @(room->cell->map->tileInfo)
  
  if (room_inside(room, x, y)) then
    with room->tile(x, y)
      .back = tileInfo->_floorTile
      FLAG_SET(.flags, TILE_DOOR)
      FLAG_CLEAR(.flags, TILE_WALL or TILE_WALL_TOP)
    end with
  end if
end sub

sub room_create(room as MapRoom ptr)
  var tileInfo = @(room->cell->map->tileInfo)
  
  '' Paint floor
  for y as integer = 0 to room->h - 1
    for x as integer = 0 to room->w - 1
      paint_floor(room, x, y)
    next
  next
  
  '' Paint doors
  dim as long doorSize = 5
  
  if (room->cell->north) then
    dim as long doorPos = map_getDoorPos(room->cell->northA, room->w, doorSize)
    
    for x as integer = doorPos to doorPos + doorSize - 1
      paint_door(room, x, 0)
    next
  end if
  
  if (room->cell->south) then
    dim as long doorPos = map_getDoorPos(room->cell->southA, room->w, doorSize)
    
    for x as integer = doorPos to doorPos + doorSize - 1
      paint_door(room, x, room->h - 1)
    next
  end if
  
  if (room->cell->west) then
    dim as long doorPos = map_getDoorPos(room->cell->westA, room->h, doorSize)
    doorPos += iif(room->cell->westA = DOOR_LEFT, 1, iif(room->cell->westA = DOOR_RIGHT, -1, 0))
    
    for y as integer = doorPos to doorPos + doorSize - 1
      paint_door(room, 0, y)
    next
  end if
  
  if (room->cell->east) then
    dim as long doorPos = map_getDoorPos(room->cell->eastA, room->h, doorSize)
    doorPos += iif(room->cell->eastA = DOOR_LEFT, 1, iif(room->cell->eastA = DOOR_RIGHT, -1, 0))
    
    for y as integer = doorPos to doorPos + doorSize - 1
      paint_door(room, room->w - 1, y)
    next
  end if
  
  '' Paint room walls
  for x as integer = 0 to room->w - 1
    paint_wall(room, x, 0)
    paint_wall(room, x, room->h - 2)
  next
  
  for y as integer = 1 to room->h - 2
    paint_wall(room, 0, y)
    paint_wall(room, room->w - 1, y)
  next
end sub

sub rooms_init(m as Map ptr)
  for y as integer = 0 to m->h - 1
    for x as integer = 0 to m->w - 1
      room_create(@(m->cell(x, y).room))
    next
  next
end sub

sub room_render(room as MapRoom ptr)
  var m = room->cell->map
  dim as long tileSize = *(m->tileInfo.tileSize)
  
  for y as integer = 0 to room->h - 1
    for x as integer = 0 to room->w - 1
      dim as long x0 = x * tileSize, y0 = y * tileSize
      dim as long x1 = x0 + tileSize - 1, y1 = y0 + tileSize - 1
      
      with room->tile(x, y)
        if (FLAG_ISSET(.flags, TILE_FLOOR)) then
          put(x * tileSize, y * tileSize), m->_tileset->floors(.back).tile(.backVariation), pset
        end if
        
        if (FLAG_ISSET(.flags, TILE_WALL_TOP)) then
          put(x * tileSize, y * tileSize), m->_tileset->wallTops(.back).tile(.backVariation), pset
        end if
        
        if (FLAG_ISSET(.flags, TILE_WALL)) then
          put(x * tileSize, y * tileSize), m->_tileset->walls(.back).tile(.backVariation), pset
        end if
        
        if (FLAG_ISSET(room->tile(x, y).flags, TILE_IMPASSABLE)) then
          'line(x0, y0) - (x1, y1), rgb(255, 0, 0), b
        end if
      end with
    next
  next
  
  '' Render the entities in the room
  var n = room->entities.last
  
  do while (n)
    dim as GEntity ptr e = n->item
    
    if (e->onRender) then
      e->onRender(e)
    end if
    
    n = n->backward
  loop
end sub

sub room_add_entity(room as MapRoom ptr, e as GEntity ptr)
  select case as const (e->gtype)
    case ENTITY_PLAYER
      room->entities.addFirst(e)
      
    case ENTITY_ITEM
      if (room->entities.count = 0) then
        room->entities.addLast(e)
      else
        room->entities.addAfter(room->entities.first, e)
      end if
    
    case else
      room->entities.addLast(e)
  end select
  
  e->room = room
end sub

sub room_remove_entity(room as MapRoom ptr, e as GEntity ptr)
  list_removeItem(@(room->entities), e)
  e->room = 0
end sub

'' Returns whether or not a room has any entity in the specified location
function room_has_entity(room as MapRoom ptr, x as long, y as long) as boolean
  var n = room->entities.first
  
  do while (n)
    dim as GEntity ptr e = n->item
    
    if (e->x = x andAlso e->y = y) then
      return true
    end if
    
    n = n->forward
  loop
  
  return false
end function
