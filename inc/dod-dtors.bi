sub map_destroy(m as Map ptr)
  var n = m->entities.first
  
  do while (n)
    dim as GEntity ptr e = n->item
    
    entity_destroy(e)
    n = n->forward
  loop
  
  delete(m)
end sub
