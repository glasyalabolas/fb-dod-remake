sub generator_destroy(e as GEntity ptr)
  delete(e->generator)
end sub

sub generator_dispose(e as GEntity ptr)
  map_remove_entity(e->room->map, e)
  room_remove_entity(e->room, e)
  
  entity_destroy(e)
end sub

sub generator_render(e as GEntity ptr)
  dim as long tileSize = *(e->room->cell->map->tileInfo.tileSize)
  
  put(e->x * tileSize, e->y * tileSize), e->tileset[e->tileId], alpha
end sub

'' <e> is the entity killed, <who> is whoever killed it
sub generator_killed(e as GEntity ptr, who as GEntity ptr)
  if (who->gtype = ENTITY_PLAYER) then
    dim as long XPgain = 5
    
    game_message(who->name & " destroyed the generator and gains " & XPgain & " experience", MSG_COLOR_HIT)
    
    who->player->XP += XPgain
  end if
  
  generator_dispose(e)
end sub

sub generator_spawn_enemy(e as GEntity ptr)
  dim as MapTile ptr tiles()
  
  room_can_place_entities(e->room, e->x, e->y, tiles())
  
  if (ARRAY_ELEMENTS(tiles) > 0) then
    var tile = tiles(rng(0, ARRAY_ELEMENTS(tiles) - 1))
    
    map_add_entity(e->room->cell->map, monster_create( _
      e->generator->monsterType, tile->x, tile->y), e->room->cell->x, e->room->cell->y)
  end if
end sub

sub generator_tick(e as GEntity ptr)
  e->generator->elapsed -= 1
  
  debug("generator_elapsed: " & e->generator->elapsed)
  
  if (e->generator->elapsed <= 0) then
    generator_spawn_enemy(e)
    
    var player = map_get_player(e->room->map)
    
    if (player) then
      if (player->room = e->room) then
        e->generator->elapsed = e->generator->interval
      else
        e->generator->elapsed = e->generator->interval * 3
      end if
    end if
  end if
end sub

function generator_collide(e as GEntity ptr, who as GEntity ptr) as boolean
  if (who->gtype = ENTITY_PLAYER) then
    debug("Player is attacking generator!")
  end if
  
  return true
end function

'sub generators_init(tileset as Fb.Image ptr ptr)
'  GGenerator.tileset = tileset
'end sub

function generator_create(what as MONSTER_TYPE, x as long, y as long, interval as long) as GEntity ptr
  var e = new GEntity
  var g = new GGenerator
  
  e->x = x
  e->y = y
  e->tileId = 2
  e->tileset = GGenerator.tileset
  e->generator = g
  
  FLAG_SET(e->flags, EFLAG_BLOCKS_MOVEMENT)
  
  g->monsterType = what
  g->interval = interval
  g->elapsed = g->interval
  g->HP = 5
  
  e->onDestroy = @generator_destroy
  e->onRender = @generator_render
  e->onTick = @generator_tick
  e->onCollide = @generator_collide
  e->onKilled = @generator_killed
 
  return e
end function
