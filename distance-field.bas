#include once "inc/rng.bi"
#include once "inc/fb-linkedlist.bi"

enum DF_FLAGS
  DF_NONE
  DF_IMPASSABLE = 1 shl 0
  DF_ENEMY      = 1 shl 1
end enum

type DistanceFieldCell
  as long cost
  as long iter
  
  as DF_FLAGS flags
end type

type DistanceField
  as long w, h
  as DistanceFieldCell cell(any, any)
end type

sub distance_field_reset(df as DistanceField ptr)
  for y as integer = 0 to df->h - 1
    for x as integer = 0 to df->w - 1
      df->cell(x, y).cost = 65535
    next
  next
end sub

function distance_field_create(w as long, h as long) as DistanceField ptr
  var df = new DistanceField
  
  redim (df->cell)(0 to w - 1, 0 to h - 1)
  
  df->w = w
  df->h = h
  
  return df
end function

sub render_distance_field(df as DistanceField ptr, ts as long)
  for y as integer = 0 to df->h - 1
    for x as integer = 0 to df->w - 1
      dim as long x0 = x * ts, y0 = y * ts
      dim as long x1 = x0 + ts - 1, y1 = y0 + ts - 1
      
      dim as ulong clr = rgb(214, 214, 214)
      
      if (df->cell(x, y).flags and DF_IMPASSABLE) then
        clr = rgb(32, 32, 32)
      end if
      
      if (df->cell(x, y).flags and DF_ENEMY) then
        clr = rgb(214, 0, 0)
      end if
      
      line(x0, y0) - (x1, y1), clr, bf
      
      draw string(x0 + 5, y0 + 5), str(df->cell(x, y).cost), rgb(0, 0, 0)
      draw string(x0 + 4, y0 + 4), str(df->cell(x, y).cost), rgb(0, 192, 192)
    next
  next
end sub

screenRes(800, 600, 32)

dim as long tileSize = 32

var df = distance_field_create(16, 16)

for x as integer = 0 to df->w - 1
  df->cell(x, 0).flags or= DF_IMPASSABLE
next

for y as integer = 0 to df->h shr 1
  df->cell(7, y).flags or= DF_IMPASSABLE
next

for i as integer = 1 to 10
  df->cell(rng(1, df->w - 1), rng(1, df->h - 1)).flags or= DF_IMPASSABLE
  df->cell(rng(1, df->w - 1), rng(1, df->h - 1)).flags or= DF_ENEMY
next

dim as long mx, my
dim as long cellX, cellY

do
  getMouse(mx, my)
  cellX = -1 : cellY = -1
  
  if (mx < df->w * tileSize andAlso my < df->h * tileSize) then
    cellX = mx \ tileSize
    cellY = my \ tileSize
  end if
  
  screenLock()
    cls()
    distance_field_reset(df)
    render_distance_field(df, tileSize)
    
    ? cellX, cellY
  screenUnlock()
  
  sleep(1, 1)
loop until(len(inkey()))

delete(df)
