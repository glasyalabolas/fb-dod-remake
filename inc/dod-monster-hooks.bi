sub monster_destroy(e as GEntity ptr)
  delete(e->monster)
end sub

sub monster_render(e as GEntity ptr)
  dim as long tileSize = *(e->room->cell->map->tileInfo.tileSize)
  
  put(e->x * tileSize, e->y * tileSize), e->monster->tileset[e->tileId], alpha
end sub

sub monsters_init(tileset as Fb.Image ptr ptr)
  redim GMonster.MONSTER_DEF(0 to MONSTER_LAST - 1)
  GMonster.tileset = tileset
  
  with GMonster.MONSTER_DEF(MONSTER_VAMPIRE)
    .name = "Vampire"
    .HP = 5
    .maxHP = 5
    .att = 1
    .def = 1
    .XP = 10
    .tileId = 0
  end with
  
  with GMonster.MONSTER_DEF(MONSTER_CRYSTAL_SCORPION)
    .name = "Crystal Scorpion"
    .HP = 5
    .maxHP = 5
    .att = 1
    .def = 1
    .XP = 10
    .tileId = 1
  end with
  
  with GMonster.MONSTER_DEF(MONSTER_BLACK_ANT)
    .name = "Black Ant"
    .HP = 5
    .maxHP = 5
    .att = 1
    .def = 1
    .XP = 10
    .tileId = 2
  end with
  
  with GMonster.MONSTER_DEF(MONSTER_NINJA)
    .name = "Ninja"
    .HP = 5
    .maxHP = 5
    .att = 1
    .def = 1
    .XP = 10
    .tileId = 3
  end with
end sub

function monster_move_random(e as GEntity ptr) as XY
  return type <XY>(rngn(), rngn())
end function

function monster_move_path(e as GEntity ptr) as XY
  var df = e->room->distanceField
  
  dim as DistanceFieldCell ptr cell = @df->cell(e->x, e->y)
  
  for y as integer = -1 to 1
    for x as integer = -1 to 1
        dim as long cx = e->x + x, cy = e->y + y
        
        if (distance_field_inside(df, cx, cy)) then
          if (not FLAG_ISSET(df->cell(cx, cy).flags, DF_ENTITY) andAlso _
              not FLAG_ISSET(df->cell(cx, cy).flags, DF_IMPASSABLE)) then
            
            if (df->cell(cx, cy).cost < cell->cost) then
              cell = @df->cell(cx, cy)
            end if
          end if
        end if
    next
  next
  
  '' Move entity towards target
  if (cell->x <> e->x orElse cell->y <> e->y) then
    return type <XY>(cell->x - e->x, cell->y - e->y)
  end if
  
  '' Entity did not move because there was no path
  return type <XY>(0, 0)
end function

'' <e> is the entity killed, <who> is whoever killed it
sub monster_killed(e as GEntity ptr, who as GEntity ptr)
  if (who->gtype = ENTITY_PLAYER) then
    dim as long XPgain = e->monster->XP
    
    game_message(who->name & " kills " & e->name & " and gains " & XPgain & " experience", MSG_COLOR_HIT)
    
    who->player->XP += XPgain
  end if
  
  monster_dispose(e)
end sub

'' <who> is the entity that is attacking the monster <e>
sub monster_defend(e as GEntity ptr, who as GEntity ptr)
  if (who->gtype = ENTITY_PLAYER) then
    dim as long damage = who->player->swordLevel
    
    e->monster->HP -= damage
    
    game_message(who->name & " attacks " & e->name & " and does " & damage & " damage!", MSG_COLOR_HIT)
    
    if (e->monster->HP <= 0) then
      monster_killed(e, who)
    end if  
  end if
end sub

'' <e> is the entity that <who> is attacking
sub monster_melee(e as GEntity ptr, who as GEntity ptr)
  if (e->gtype = ENTITY_PLAYER) then
    game_message(who->name & " is attacking " & e->name, MSG_COLOR_DAMAGE)
  end if
end sub

sub monster_tick(e as GEntity ptr)
  '' Is player in the room?
  dim as GEntity ptr target = e->room->entities.first->item
  dim as XY delta
  
  if (target->gtype = ENTITY_PLAYER) then
    '' If player is in the room, chase it...
    delta = monster_move_path(e)
    
    '' ...unless there's no path, then flail around waiting for your turn
    if (delta.x = 0 andAlso delta.y = 0) then
      delta = monster_move_random(e)
    end if
  else
    '' Otherwise, just wander around
    delta = monster_move_random(e)
  end if
  
  FLAG_CLEAR(e->room->distanceField->cell(e->x, e->y).flags, DF_ENTITY)

  entity_move(e, delta.x, delta.y)
  
  FLAG_SET(e->room->distanceField->cell(e->x, e->y).flags, DF_ENTITY)
end sub

function monster_collide(e as GEntity ptr, who as GEntity ptr) as boolean
  select case as const (who->gtype)
    case ENTITY_PLAYER
      if (e->onDefend) then
        e->onDefend(e, who)
      end if
      
      return true
    
    case ENTITY_MONSTER
      debug("Collided with another dumbass")
      return true
    
    case ENTITY_GENERATOR
      return true
  end select
  
  return false
end function

function monster_create(what as MONSTER_TYPE, x as long, y as long) as GEntity ptr
  var e = new GEntity
  var m = new GMonster
  
  e->gtype = ENTITY_MONSTER
  e->x = x
  e->y = y
  
  FLAG_SET(e->flags, EFLAG_BLOCKS_MOVEMENT)
  
  with GMonster.MONSTER_DEF(what)
    e->name = .name
    e->tileId = .tileId
    
    m->HP = .HP
    m->maxHP = .maxHP
    m->att = .att
    m->def = .def
    m->XP = .XP
  end with
  
  e->monster = m
  e->monster->onMelee = @monster_melee
  
  e->onDestroy = @monster_destroy
  e->onRender = @monster_render
  e->onTick = @monster_tick
  e->onLeaveTile = @entity_leave_tile
  e->onEnterTile = @entity_enter_tile
  e->onLeaveRoom = @entity_leave_room
  e->onEnterRoom = @entity_enter_room
  e->onCollide = @monster_collide
  e->onDefend = @monster_defend
  e->onKilled = @monster_killed
  
  return e
end function
