#include once "fbgfx.bi"
#include once "utils.bi"
#include once "rng.bi"
#include once "sprite-sheet.bi"

type Tiles
  as Fb.Image ptr tile(any)
end type

type Tileset
  as Tiles floors(any)
  as Tiles walls(any)
  as Tiles wallTops(any)
end type

sub tileset_destroy(ts as Tileset ptr)
  for i as integer = 0 to ubound(ts->floors)
    sprites_destroy(ts->floors(i).tile())
  next
  
  for i as integer = 0 to ubound(ts->walls)
    sprites_destroy(ts->walls(i).tile())
  next
  
  for i as integer = 0 to ubound(ts->wallTops)
    sprites_destroy(ts->wallTops(i).tile())
  next
end sub

sub tileset_get_tiles(ts() as Tiles, folder as string, pattern as string, tileSize as long, scale as single = 1.0)
  dim as string tiles()
  get_files(tiles(), folder, pattern)
  
  redim ts(0 to ubound(tiles))
  
  for i as integer = 0 to ubound(ts)
    sprites_get(ts(i).tile(), folder & tiles(i), tileSize, scale)
  next
end sub
