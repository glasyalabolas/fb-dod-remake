#include once "fb-linkedlist.bi"

#ifndef rng
  function rng(aMin as long, aMax as long) as long
    return int(rnd() * ((aMax + 1) - aMin) + aMin)
  end function
#endif

function list_copy(l as Fb.LinkedList ptr) as Fb.LinkedList ptr
  var list = new Fb.LinkedList()
  
  var n = l->first
  
  do while (n)
    list->addLast(n->item)
    n = n->forward
  loop
  
  return list
end function

sub list_shuffle(l as Fb.LinkedList ptr)
  for i as integer = l->count - 1 to 1 step -1
    dim as integer j = rng(0, i)
    
    var n1 = l->findNode(i)
    var n2 = l->findNode(j)
    l->swapNodes(n1, n2)
  next
end sub

function list_contains(l as Fb.LinkedList ptr, item as any ptr) as boolean
  var n = l->first
  
  do while (n)
    if (n->item = item) then return true
    n = n->forward
  loop
  
  return false
end function

function list_removeItem(l as Fb.LinkedList ptr, item as any ptr) as boolean
  var n = l->first
  
  do while (n)
    if (n->item = item) then
      l->remove(n)
      return true
    end if
    
    n = n->forward
  loop
  
  return false
end function

sub list_add(l as Fb.LinkedList ptr, another as Fb.LinkedList ptr)
  var n = another->first
  
  do while (n)
    l->addLast(n->item)
    n = n->forward
  loop
end sub
