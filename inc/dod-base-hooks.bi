sub entity_leave_tile(e as GEntity ptr)
  'debug("entity_leave_tile")
end sub

function entity_enter_tile(e as GEntity ptr, tx as long, ty as long) as boolean
  debug("Entity " & e->name & " at " & e->x & ", " & e->y & " entering tile at " & tx & ", " & ty)
  
  return false
end function

sub entity_leave_room(e as GEntity ptr)
  debug("entity_leave_room")
  room_remove_entity(e->room, e)
end sub

sub entity_enter_room(e as GEntity ptr, newRoom as MapRoom ptr)
  debug("entity_enter_room")
  room_add_entity(newRoom, e)
end sub

function entity_move(e as GEntity ptr, dx as long, dy as long) as boolean
  dim as long newX = e->x + dx, newY = e->y + dy
  dim as boolean tick
  
  '' Check if we will bump into a wall
  dim as boolean bumped
  
  if (room_inside(e->room, newX, e->y)) then
    if (FLAG_ISSET(e->room->tile(newX, e->y).flags, TILE_IMPASSABLE)) then
      e->onWallBump(e, @(e->room->tile(newX, e->y)))
      newX = e->x
      bumped = true
    end if
  end if
  
  if (room_inside(e->room, e->x, newY)) then
    if (FLAG_ISSET(e->room->tile(e->x, newY).flags, TILE_IMPASSABLE)) then
      e->onWallBump(e, @(e->room->tile(e->x, newY)))
      newY = e->y
      bumped = true
    end if
  end if
  
  '' The previous checks allow for nice 'sliding' on walls, but we still
  '' need to do this check for diagonals; otherwise we get diagonal penetration
  if (not bumped andAlso room_inside(e->room, newX, newY)) then
    if (FLAG_ISSET(e->room->tile(newX, newY).flags, TILE_IMPASSABLE)) then
      e->onWallBump(e, @(e->room->tile(newX, newY)))
      newX = e->x
      newY = e->y
    end if
  end if
  
  dim as MapRoom ptr newRoom
  
  '' Check if the entity left the room
  '' From the north
  if (newY < 0) then
    newRoom = @(e->room->cell->north->room)
    newY += e->room->h
  end if
  
  '' From the south
  if (newY > e->room->h - 1) then
    newRoom = @(e->room->cell->south->room)
    newY -= e->room->h
  end if
  
  '' From the west
  if (newX < 0) then
    newRoom = @(e->room->cell->west->room)
    newX += e->room->w
  end if
  
  '' From the east
  if (newX > e->room->w - 1) then
    newRoom = @(e->room->cell->east->room)
    newX -= e->room->w
  end if
  
  if (newX <> e->x orElse newY <> e->y) then
    if (e->onLeaveTile) then
      e->onLeaveTile(e)
    end if
    
    if (newRoom) then
      'TODO: Check if the entity would bump against another on the next room and cancel movement if appropriate
      if (e->onLeaveRoom) then
        e->onLeaveRoom(e)
      end if
      
      if (e->onEnterRoom) then
        e->onEnterRoom(e, newRoom)
      end if
    end if
    
    if (e->onEnterTile) then
      tick = e->onEnterTile(e, newX, newY)
    end if
  end if
  
  return tick
end function
