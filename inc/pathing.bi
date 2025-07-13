#ifdef ZoneRoom
'' Returns a linked list of rooms containing a path, if it exists, from startRoom to
'' endRoom
function path_get(startRoom as ZoneRoom ptr, endRoom as ZoneRoom ptr) as Fb.LinkedList ptr
  var path = new Fb.LinkedList()
  var openList = new Fb.LinkedList()
  
  dim as long iter = endRoom->iter + 1
  
  endRoom->distance = 0
  
  openList->addFirst(endRoom)
  
  dim as ZoneRoom ptr current
  
  dim as boolean found
  
  do while (openList->count > 0)
    current = openList->removeFirst()
    
    current->iter = iter
    
    if (current = startRoom) then found = true
    
    '' Use DOORS for traversal; don't add locked doors
    var n = current->doors.first
    
    do while (n)
      dim as ZoneRoomDoor ptr door = n->item
      
      if (not door->locked) then
        if (door->nextRoom->iter <> iter) then
          door->nextRoom->distance = current->distance + 1
          openList->addLast(door->nextRoom)
        end if
      end if
      
      n = n->forward
    loop
  loop
  
  delete(openList)
  
  '' There is no path, other that the one we choose
  if (not found) then
    return(path)
  end if
  
  '' Traverse the path backwards and return it. Again, use DOORS for
  '' traversal
  current = startRoom
  
  path->addLast(current)
  
  do while (current <> endRoom)
    var n = current->doors.first
    
    do while (n)
      dim as ZoneRoomDoor ptr door = n->item
      
      if (door->nextRoom->distance < current->distance) then
        current = door->nextRoom
        path->addLast(current)
        
        exit do
      end if
      
      n = n->forward
    loop
  loop
  
  path->addLast(endRoom)
  
  return path
end function

#endif

#ifndef XY
  type XY
    as long x, y
  end type
#endif

sub dispose_XY(e as XY ptr)
  delete(e)
end sub

'' Returns a list of square cells of size <size> that intersect with a ray from
'' <x0, y0> to <x1, y1>
function traverse(size as long, x0 as single, y0 as single, x1 as single, y1 as single) as Fb.LinkedList ptr
  var result = new Fb.LinkedList()
  result->_disposeFunc = cptr(sub(as any ptr), @dispose_XY)
  
  dim as single _
    cs = 1.0f / size, _
    posX = x0 * cs, _
    posY = y0 * cs, _
    rayDirX = (x1 - x0), _
    rayDirY = (y1 - y0), _
    deltaDistX = iif(rayDirY = 0, 0, iif(rayDirX = 0, 1e8, abs(1.0f / rayDirX))), _
    deltaDistY = iif(rayDirX = 0, 0, iif(rayDirY = 0, 1e8, abs(1.0f / rayDirY)))
  
  dim as long _
    mapX = int(x0 * cs), _
    mapY = int(y0 * cs), _
    endX = int(x1 * cs), _
    endY = int(y1 * cs), _
    n = 1 + (abs(endX - mapX)) + (abs(endY - mapY))
  
  dim as long _
    stepX = iif(rayDirX < 0, -1, 1), _
    stepY = iif(rayDirY < 0, -1, 1)
  
  dim as single _
    sideDistX = iif(rayDirX < 0, (posX - mapX) * deltaDistX, (( mapX + 1) - posX) * deltaDistX), _
    sideDistY = iif(rayDirY < 0, (posY - mapY) * deltaDistY, (( mapY + 1) - posY) * deltaDistY)
  
  for i as integer = 0 to n - 1
    '' Add cell to list
    result->addLast(new XY(mapX, mapY))
    
    if (sideDistX < sideDistY) then
      sideDistX += deltaDistX
      mapX += stepX
    else
      sideDistY += deltaDistY
      mapY += stepY
    end if
  next
  
  return result
end function
