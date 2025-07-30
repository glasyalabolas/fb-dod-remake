function room_inside(r as MapRoom ptr, x as long, y as long) as boolean
  return x >= 0 andAlso x <= r->w - 1 andAlso y >= 0 andAlso y <= r->h - 1
end function

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
      
      room->distanceField->cell(x, y).flags = 0
      FLAG_SET(room->distanceField->cell(x, y).flags, DF_IMPASSABLE)
      
      with room->tile(x, y + 1)
        .back = tileInfo->_bottomWallTile
        .backVariation = rng(0, ubound(tileset->walls(tileInfo->_bottomWallTile).tile))
        FLAG_SET(.flags, TILE_IMPASSABLE or TILE_WALL)
        FLAG_CLEAR(.flags, TILE_FLOOR or TILE_WALL_TOP)
      end with
      
      room->distanceField->cell(x, y + 1).flags = 0
      FLAG_SET(room->distanceField->cell(x, y + 1).flags, DF_IMPASSABLE)
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
  
  room->distanceField = distance_field_create(room->w, room->h)
  
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
      
    case ENTITY_MONSTER
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

'' Returns the entity at x, y in the specified room, if there's any on that tile
function room_find_entity(room as MapRoom ptr, x as long, y as long) as GEntity ptr
  var n = room->entities.first
  
  do while (n)
    dim as GEntity ptr e = n->item
    
    if (e->x = x andAlso e->y = y) then
      return e
    end if
    
    n = n->forward
  loop
  
  return 0
end function

'' Returns whether or not a room has any entity in the specified location
function room_has_entity(room as MapRoom ptr, x as long, y as long) as boolean
  return room_find_entity(room, x, y) <> 0
end function

'' Return whether or not an entity can be placed in the room
'' NOTE: Be careful if the entity doesn't move, as they will overlap if you place
''   them on top of one another
function room_can_place_entity(room as MapRoom ptr, x as long, y as long) as boolean
  dim as boolean isFree = true
  
  var e = room_find_entity(room, x, y)
  
  if (e) then
    isFree = e->gtype = ENTITY_ITEM
  end if
  
  return isFree andAlso FLAG_ISSET(room->tile(x, y).flags, TILE_FLOOR)
end function

'' Returns an array containing the free tiles around the specified location where entities
'' can be placed
sub room_can_place_entities(room as MapRoom ptr, x as long, y as long, tiles() as MapTile ptr)
  for r as integer = -1 to 1
    for c as integer = -1 to 1
      if (c <> 0 orElse r <> 0) then
        if (room_inside(room, x + c, y + r)) then
          if (room_can_place_entity(room, x + c, y + r)) then
            ARRAY_ADD(tiles, @(room->tile(x + c, y + r)))
          end if
        end if
      end if
    next
  next
end sub

function room_get_rnd_tile(room as MapRoom ptr) as MapTile ptr
  dim as MapTile ptr tile
  
  do
    tile = @(room->tile(rng(1, room->w - 1), rng(2, room->h - 3)))
  loop until (room_can_place_entity(room, tile->x, tile->y))
  
  return tile
end function

sub room_destroy(room as MapRoom ptr)
  delete(room->distanceField)
end sub
