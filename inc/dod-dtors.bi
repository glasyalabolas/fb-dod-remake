sub map_destroy(m as Map ptr)
  var n = m->entities.first
  
  do while (n)
    dim as GEntity ptr e = n->item
    
    entity_destroy(e)
    n = n->forward
  loop
  
  for y as integer = 0 to m->h - 1
    for x as integer = 0 to m->w - 1
      room_destroy(@(m->cell(x, y).room))
    next
  next
  
  delete(m)
end sub
