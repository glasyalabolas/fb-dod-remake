type GPlayer
  as long HP, maxHP
  as long XP, nextLevel
  as long level
  as long swordLevel, armorLevel, shieldLevel
  as long potions, scrolls
  as long tileId
  as double lastPress
  
  static as Fb.Image ptr ptr tileset
end type

static as Fb.Image ptr ptr GPlayer.tileset

sub player_destroy(e as GEntity ptr)
  delete(e->player)
end sub

sub player_minimap_render(e as GEntity ptr, p as Minimap ptr)
  dim as long size = p->cellSize \ 3
  dim as long x0 = e->room->cell->x * p->cellSize + size, y0 = e->room->cell->y * p->cellSize + size
  dim as long x1 = x0 + size - 1, y1 = y0 + size - 1
  
  line p->buffer, (x0, y0) - (x1, y1), rgb(255, 255, 255)
  line p->buffer, (x0, y0 + 1) - (x1, y1 + 1), rgb(0, 0, 0)
  line p->buffer, (x0, y1) - (x1, y0), rgb(255, 255, 255)
  line p->buffer, (x0, y1 + 1) - (x1, y0 + 1), rgb(0, 0, 0)
end sub

sub player_render(e as GEntity ptr)
  dim as long tileSize = *(e->room->cell->map->tileInfo.tileSize)
  
  put(e->x * tileSize, e->y * tileSize), e->player->tileset[e->player->tileId], alpha
end sub

sub player_init(e as GEntity ptr)
  debug("player_init")
  
  e->player->lastPress = timer()
  FLAG_SET(e->room->cell->flags, CELL_VISITED)
  
'  if (e->room->distanceField = 0) then
'    debug("  flowfield_create")
'    e->room->distanceField = distance_field_create(e->room)
'  end if
end sub

function player_process(e as GEntity ptr) as boolean
  dim as long dx, dy
  dim as boolean pressed, tick
  
  with Game.keyboard
    if (.pressed(Fb.SC_UP)) then
      dy -= 1
      pressed = true
    end if
    
    if (.pressed(Fb.SC_DOWN)) then
      dy += 1
      pressed = true
    end if
    
    if (.pressed(Fb.SC_LEFT)) then
      dx -= 1
      pressed = true
    end if
    
    if (.pressed(Fb.SC_RIGHT)) then
      dx += 1
      pressed = true
    end if
    
    if (.held(Fb.SC_UP)) then
     dy -= 1
    end if
    
    if (.held(Fb.SC_DOWN)) then
      dy += 1
    end if
    
    if (.held(Fb.SC_LEFT)) then
      dx -= 1
    end if
    
    if (.held(Fb.SC_RIGHT)) then
      dx += 1
    end if
  end with
  
  dim as double elapsed = (timer() - e->player->lastPress) * 1000.0
  
  if (elapsed > Game.keySpeed orElse pressed) then
    if (dx <> 0 orElse dy <> 0) then
      tick = e->onMove(e, dx, dy)
    end if
    
    e->player->lastPress = timer()
  end if
  
  return tick
end function

sub player_wall_bump(e as GEntity ptr, tile as MapTile ptr)
  debug("Bumped a wall at: " & tile->x & ", " & tile->y)
end sub

'function player_enter_tile(e as GEntity ptr, newX as long, newY as long) as boolean
'  dim as boolean tick
  
'  '' Check if we would collide against other entities
'  var n = e->room->entities.first
  
'  dim as boolean blocked
  
'  do while (n)
'    dim as GEntity ptr other = n->item
    
'    if (other->x = newX andAlso other->y = newY) then
'      if (other->onCollide) then
'        blocked = other->onCollide(other, e)
'      end if
'      exit do
'    end if
    
'    n = n->forward
'  loop
  
'  if (not blocked) then
'    e->x = newX
'    e->y = newY
    
'    tick = true
'  end if
  
'  return tick
'end function

sub player_enter_room(e as GEntity ptr, newRoom as MapRoom ptr)
  entity_enter_room(e, newRoom)
  FLAG_SET(e->room->cell->flags, CELL_VISITED)
  
'  if (newRoom->distanceField = 0) then
'    newRoom->distanceField = distance_field_create(newRoom)
'  end if
end sub

function player_collide(e as GEntity ptr, who as GEntity ptr) as boolean
  if (who->gtype = ENTITY_MONSTER) then
    debug("Holy shit I'm being attacked!")
    return true
  end if
  
  return false
end function

function player_enter_tile(e as GEntity ptr, newX as long, newY as long) as boolean
  dim as boolean tick = entity_enter_tile(e, newX, newY)
  
  if (tick) then
    debug("player_enter_tile")
    'distance_field_compute(e->room->distanceField, e->room, e->x, e->y)
  end if
  
  return tick
end function

function player_create(tiles as Fb.Image ptr ptr, tileId as long, x as long, y as long) as GEntity ptr
  var e = new GEntity
  var player = new GPlayer
  
  player->tileset = tiles
  player->tileId = tileId
  
  e->name = "Player"
  e->gtype = ENTITY_PLAYER
  e->x = x
  e->y = y
  e->player = player
  
  e->onInit = @player_init
  e->onDestroy = @player_destroy
  e->onProcess = @player_process
  e->onMove = @entity_move
  e->onRender = @player_render
  e->onMinimapRender = @player_minimap_render
  e->onWallBump = @player_wall_bump
  e->onLeaveTile = @entity_leave_tile
  e->onEnterTile = @player_enter_tile
  e->onLeaveRoom = @entity_leave_room
  e->onEnterRoom = @player_enter_room
  e->onCollide = @player_collide
  
  return e
end function

