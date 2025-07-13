'' Here, <who> can be safely assumed to be the player if only the player is
'' allowed to pick up items
sub health_potion_pickup(e as GEntity ptr, who as GEntity ptr)
  debug("Picked up a health potion")
  who->player->potions += 1
  
  item_dispose(e)
end sub

sub scroll_pickup(e as GEntity ptr, who as GEntity ptr)
  debug("Picked up a magic scroll")
  who->player->scrolls += 1
  
  item_dispose(e)
end sub

sub map_pickup(e as GEntity ptr, who as GEntity ptr)
  debug("Picked up a map")
  
  var m = e->room->map
  
  for y as integer = 0 to m->h - 1
    for x as integer = 0 to m->w - 1
      FLAG_SET(m->cell(x, y).flags, CELL_VISITED)
    next
  next
  
  item_dispose(e)
end sub
