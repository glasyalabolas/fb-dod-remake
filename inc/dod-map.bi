enum MAP_CELL_FLAGS
  CELL_UNVISITED
  CELL_VISITED   = 1 shl 0
  CELL_DISPLAYED = 1 shl 1
end enum

enum DOOR_ALIGNMENT
  DOOR_LEFT
  DOOR_CENTER
  DOOR_RIGHT
end enum

type as MapCell MapCell_
type as MapParams MapParams_
type as Map Map_
type as GEntity GEntity_
type as DistanceField DistanceField_

enum MAP_TILE_FLAGS
  TILE_NONE
  TILE_IMPASSABLE     = 1 shl 0
  TILE_DOOR           = 1 shl 1
  TILE_UNSPRUNG_TRAP  = 1 shl 3
  TILE_FLOOR          = 1 shl 4
  TILE_WALL_TOP       = 1 shl 5
  TILE_WALL           = 1 shl 6
end enum

type MapTile
  as long x, y
  as long back, backVariation
  as long front
  as MAP_TILE_FLAGS flags
  as MapCell_ ptr cell
end type

type MapRoom
  as long w, h
  as MapTile tile(any, any)
  as MapCell_ ptr cell
  as Map_ ptr map
  as DistanceField_ ptr distanceField
  
  as Fb.LinkedList entities
end type

type MapCell
  as long x, y
  as MapCell ptr north, south, west, east
  as DOOR_ALIGNMENT northA, southA, westA, eastA
  as MAP_CELL_FLAGS flags
  as Map_ ptr map
  as GEntity ptr entity
  
  as MapRoom room
  
  as long iter
end type

type TilesetInfo
  as long _floorTile
  as long _topWallTile
  as long _bottomWallTile
  
  as long ptr tileSize
end type

type Map
  as MapCell cell(any, any)
  as long w, h
  as long level
  as ulong ticks
  as double currentTick
  as double tickInterval
  as MapParams_ ptr params
  
  as Fb.LinkedList entities
  as Tileset ptr _tileset
  
  static as TilesetInfo tileInfo
  static as Fb.Image ptr ptr tileset
end type

static as TilesetInfo Map.tileInfo
static as Fb.Image ptr ptr Map.tileset = 0

type MapParams
  as long w, h
  as long level
  as long ptr viewWidth
  as long ptr viewHeight
  as long ptr tileSize
  as double tickInterval
  
  as Tileset ptr _tileset
  
  as Fb.Image ptr ptr tileset
  as long tileCount
end type

function map_inside(m as Map ptr, x as long, y as long) as boolean
  return x >= 0 andAlso x <= m->w - 1 andAlso y >= 0 andAlso y <= m->h - 1
end function

function room_inside(r as MapRoom ptr, x as long, y as long) as boolean
  return x >= 0 andAlso x <= r->w - 1 andAlso y >= 0 andAlso y <= r->h - 1
end function

function map_create(params as MapParams ptr) as Map ptr
  var m = new Map
  
  m->params = params
  m->level = params->level
  m->w = params->w + (m->level / 2)
  m->h = params->h + (m->level / 2)
  m->tickInterval = params->tickInterval
  
  redim m->cell(0 to m->w - 1, 0 to m->h - 1)
  
  for y as integer = 0 to m->h - 1
    for x as integer = 0 to m->w - 1
      m->cell(x, y).x = x
      m->cell(x, y).y = y
      m->cell(x, y).map = m
      
      var room = @(m->cell(x, y).room)
      
      room->w = *params->viewWidth
      room->h = *params->viewHeight
      room->map = m
      
      redim (room->tile)(0 to room->w - 1, 0 to room->h - 1)
      
      for ry as integer = 0 to room->h - 1
        for rx as integer = 0 to room->w - 1
          room->tile(rx, ry).x = rx
          room->tile(rx, ry).y = ry
        next
      next
      
      room->cell = @m->cell(x, y)
    next
  next
    
  return m
end function

sub map_clear(m as Map ptr)
  for y as integer = 0 to m->h - 1
    for x as integer = 0 to m->w - 1
      with m->cell(x, y)
        .north = 0
        .south = 0
        .west = 0
        .east = 0
      end with
    next
  next
end sub

function map_getDoorPos(alignment as DOOR_ALIGNMENT, roomSize as long, doorSize as long) as long
  select case as const (alignment)
    case DOOR_LEFT
      return 1
    case DOOR_CENTER
      return (roomSize - doorSize) \ 2
    case DOOR_RIGHT
      return roomSize - doorSize - 1
  end select
end function

sub map_init(m as Map ptr, params as MapParams ptr)
  var rooms = new Fb.LinkedList()
  
  for y as integer = 0 to m->h - 1
    for x as integer = 0 to m->w - 1
      rooms->addLast(@m->cell(x, y))
    next
  next
  
  m->_tileset = params->_tileset
  
  '' Create a random floor layout
  list_shuffle(rooms)
  
  dim as MapCell ptr current
  dim as long iter
  
  current = rooms->removeFirst()
  current->iter += 1
  iter = current->iter
  
  do while (rooms->count > 0)
    current = rooms->removeFirst()
    
    '' Process neighbors of the current iteration, wrapping around the map
    var neighbors = new Fb.LinkedList()
    
    dim as long north = wrap(current->y - 1, 0, m->h)
    dim as long south = wrap(current->y + 1, 0, m->h)
    dim as long west = wrap(current->x - 1, 0, m->w)
    dim as long east = wrap(current->x + 1, 0, m->w)
    
    if (m->cell(current->x, north).iter = iter) then
      neighbors->addLast(@m->cell(current->x, north))
    end if

    if (m->cell(current->x, south).iter = iter) then
      neighbors->addLast(@m->cell(current->x, south))
    end if
    
    if (m->cell(west, current->y).iter = iter) then
      neighbors->addLast(@m->cell(west, current->y))
    end if
    
    if (m->cell(east, current->y).iter = iter) then
      neighbors->addLast(@m->cell(east, current->y))
    end if
    
    if (neighbors->count > 0) then
      '' Connect neighboring cells at random
      current->iter = iter
      dim as MapCell ptr neighbor = (*neighbors)[rng(0, neighbors->count - 1)]
      
      '' North room
      if (neighbor->x = current->x andAlso neighbor->y = north) then
        dim as long doorAlignment = rng(DOOR_LEFT, DOOR_RIGHT)
        
        neighbor->south = current
        neighbor->southA = doorAlignment
        current->north = neighbor
        current->northA = doorAlignment
      end if
      
      '' South room
      if (neighbor->x = current->x andAlso neighbor->y = south) then
        dim as long doorAlignment = rng(DOOR_LEFT, DOOR_RIGHT)
        
        neighbor->north = current
        neighbor->northA = doorAlignment
        current->south = neighbor
        current->southA = doorAlignment
      end if
      
      '' West room
      if (neighbor->x = west andAlso neighbor->y = current->y) then
        dim as long doorAlignment = rng(DOOR_LEFT, DOOR_RIGHT)
        
        neighbor->east = current
        neighbor->eastA = doorAlignment
        current->west = neighbor
        current->westA = doorAlignment
      end if
      
      '' East room
      if (neighbor->x = east andAlso neighbor->y = current->y) then
        dim as long doorAlignment = rng(DOOR_LEFT, DOOR_RIGHT)
        
        neighbor->west = current
        neighbor->westA = doorAlignment
        current->east = neighbor
        current->eastA = doorAlignment
      end if
    else
      '' Not a neighbor of the current iteration; re-add for further processing
      rooms->addLast(current)
    end if
    
    delete(neighbors)
  loop
  
  delete(rooms)
  
  '' Pick the tileset at random
  m->tileset = params->tileset
  
  with m->tileInfo
    ._floorTile = rng(0, ubound(m->_tileset->floors))
    ._bottomWallTile = rng(0, ubound(m->_tileset->walls))
    ._topWallTile = rng(0, ubound(m->_tileset->wallTops))
    
    .tileSize = params->tileSize
  end with
end sub

declare sub room_add_entity(as MapRoom ptr, as GEntity ptr)
  
sub map_remove_entity(m as Map ptr, e as GEntity ptr)
  list_removeItem(@m->entities, e)
end sub

sub map_tick(m as Map ptr)
  m->ticks += 1
  
  var n = m->entities.first
  
  do while (n)
    dim as GEntity ptr e = n->item
    
    if (e->onTick) then
      e->onTick(e)
    end if
    
    n = n->forward
  loop
  
  m->currentTick = timer()
end sub

sub map_process(m as Map ptr)
  dim as boolean tick
  
  var n = m->entities.first
  
  do while (n)
    dim as GEntity ptr e = n->item
    
    if (e->onProcess) then
      tick = tick orElse e->onProcess(e)
    end if
    
    n = n->forward
  loop
  
  dim as double elapsed = timer() - m->currentTick
  
  if (elapsed > m->tickInterval orElse tick) then
    map_tick(m)
  end if
end sub

sub map_reveal(m as Map ptr)
  for y as integer = 0 to m->h - 1
    for x as integer = 0 to m->w - 1
      FLAG_SET(m->cell(x, y).flags, CELL_DISPLAYED)
    next
  next
end sub

function map_cell_door_count(m as Map ptr, x as long, y as long) as long
  dim as long count
  
  count += iif(m->cell(x, y).north, 1, 0)
  count += iif(m->cell(x, y).south, 1, 0)
  count += iif(m->cell(x, y).west, 1, 0)
  count += iif(m->cell(x, y).east, 1, 0)
  
  return count
end function

function map_get_cells overload(m as Map ptr, doors as long) as Fb.LinkedList ptr
  var cells = new Fb.LinkedList()
  
  for y as integer = 0 to m->h - 1
    for x as integer = 0 to m->w - 1
      if (map_cell_door_count(m, x, y) = doors) then
        cells->addLast(@(m->cell(x, y)))
      end if
    next
  next
  
  return cells
end function
