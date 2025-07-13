'' General purpose utilities
#include once "inc/sprite-sheet.bi"
#include once "inc/utils.bi"
#include once "inc/rng.bi"
#include once "inc/math.bi"
#include once "inc/fb-linkedlist.bi"
#include once "inc/list-op.bi"
#include once "inc/fb-mouse-gm.bi"
#include once "inc/fb-keyboard-mk.bi"

'' Global settings
type Game extends Object
  static as Fb.KeyboardInput keyboard
  static as Fb.MouseInput mouse
  static as long tileSize
  static as long tileViewSize
  static as long viewWidth
  static as long viewHeight
  static as long statusPanelSize
  static as long statusPanelMargin
  
  static as double keySpeed
end type

static as Fb.KeyboardInput Game.keyboard = Fb.KeyboardInput()
static as Fb.MouseInput Game.mouse = Fb.MouseInput()
static as long Game.tileSize = 32           '' Tile size on the sprite sheet
static as long Game.tileViewSize = 48       '' Tile size on the view
static as long Game.viewWidth = 17          '' Number of horizontal tiles on view
static as long Game.viewHeight = 19         '' Number of vertical tiles on view
static as long Game.statusPanelSize = 300   '' Size of the side bar that displays status
static as long Game.statusPanelMargin = 10  '' Margin of the elements on the side bar
static as double Game.keySpeed = 100.0      '' Key repeat speed, in milliseconds

'' Game specific code
#include once "inc/dod-entity.bi"
#include once "inc/dod-map.bi"
#include once "inc/dod-minimap.bi"
#include once "inc/dod-room.bi"
#include once "inc/dod-pathing.bi"
#include once "inc/dod-base-hooks.bi"
#include once "inc/dod-items.bi"
#include once "inc/dod-player.bi"
#include once "inc/dod-monster.bi"

#include once "inc/dod-item-hooks.bi"
#include once "inc/dod-dtors.bi"

sub distance_field_render(dfield as DistanceField ptr, tileSize as long)
  for y as integer = 0 to dfield->h - 1
    for x as integer = 0 to dfield->w - 1  
      dim as long x0 = x * tileSize, y0 = y * tileSize
      dim as long x1 = x0 + tileSize - 1, y1 = y0 + tileSize - 1
      
      draw string (x0 + 6, y0 + 6), str(dfield->cell(x, y).distance), rgb(0, 0, 0)
      draw string (x0 + 5, y0 + 5), str(dfield->cell(x, y).distance), rgb(255, 255, 255)
    next
  next
end sub

'' First level (4x4 = 16 cells)
'' 4 Monster generators
'' 2 Potions
'' 1 Scroll
'' 1 Treasure
'' 1 Armor, Shield and Sword
'' Several coins scattered

SetDPIAwareness()

screenRes( _
  Game.viewWidth * Game.tileViewSize + Game.statusPanelSize, Game.viewHeight * Game.tileViewSize, 32, , Fb.GFX_ALPHA_PRIMITIVES)

randomize()

'' Create map
dim as MapParams mp

with mp
  .w = 4 : .h = 4
  .level = 1
  .viewWidth = @Game.viewWidth
  .viewHeight = @Game.viewHeight
  .tileSize = @Game.tileViewSize
end with

var m = map_create(@mp)

'' Prepare minimap
dim as Minimap minimap

with minimap
  .cellSize = (Game.statusPanelSize - Game.statusPanelMargin * 2) \ m->w
  .roomColor = rgb(32, 32, 32)
  .wallColor = rgb(255, 0, 0)
  .unvisitedColor = rgb(0, 0, 0)
  .buffer = imageCreate(m->w * .cellSize, m->h * .cellSize)
  .map = m
end with

dim as Fb.Image ptr male_sprites()
dim as Fb.Image ptr female_sprites()
dim as Fb.Image ptr tiles()
dim as Fb.Image ptr items()
dim as Fb.Image ptr monsters()

dim as single scale = Game.tileViewSize / Game.tileSize

sprites_get(male_sprites(), "res/player-male.tga", Game.tileSize, scale)
sprites_get(female_sprites(), "res/player-female.tga", Game.tileSize, scale)
sprites_get(tiles(), "res/tiles-2.tga", Game.tileSize, scale)
sprites_get(items(), "res/items.tga", Game.tileSize, scale)
sprites_get(monsters(), "res/monsters.tga", Game.tileSize, scale)

mp.tileset = @tiles(0)
mp.tileCount = ARRAY_ELEMENTS(tiles)

items_init(@items(0))
monsters_init(@monsters(0))

map_init(m, @mp)
rooms_init(m)

map_add_entity(m, item_create(ITEM_HEALTH_POTION, rng(2, Game.viewWidth - 2), rng(2, Game.viewHeight - 3)), rng(0, m->w - 1), rng(0, m->h - 1))
map_add_entity(m, item_create(ITEM_SCROLL, rng(2, Game.viewWidth - 2), rng(2, Game.viewHeight - 3)), rng(0, m->w - 1), rng(0, m->h - 1))
map_add_entity(m, item_create(ITEM_MAP, rng(2, Game.viewWidth - 2), rng(2, Game.viewHeight - 3)), rng(0, m->w - 1), rng(0, m->h - 1))

map_add_entity(m, monster_create(MONSTER_VAMPIRE, 4, 4), 0, 0)
map_add_entity(m, monster_create(MONSTER_CRYSTAL_SCORPION, 8, 4), 0, 0)

var player = player_create(@female_sprites(0), 1, Game.viewWidth / 2, Game.viewHeight / 2)

map_add_entity(m, player, 0, 0)

dim as long minimapPosX = Game.viewWidth * Game.tileViewSize + Game.statusPanelMargin
dim as long minimapPosY = Game.statusPanelMargin

dim as long mx, my
dim as MapRoom ptr room = player->room

m->currentTick = timer()

do
  map_process(m)
  Game.mouse.move(mx, my)
  
  dim as long cellX = -1, cellY = -1
  
  if (mx >= minimapPosX andAlso mx <= minimapPosX + minimap.buffer->width - 1) then
    cellX = (mx - minimapPosX) \ minimap.cellSize
  end if
  
  if (my >= minimapPosY andAlso my <= minimapPosY + minimap.buffer->height - 1) then
    cellY = (my - minimapPosY) \ minimap.cellSize
  end if
  
  if (map_inside(m, cellX, cellY)) then
    room = @(m->cell(cellX, cellY).room)
  else
    room = player->room
  end if
  
  minimap_render(@minimap)
  
  screenLock()
    cls()
    put(minimapPosX, minimapPosY), minimap.buffer, pset
    
    room_render(room)
    'distance_field_render(room->distanceField, Game.tileViewSize)
    
    '? "Cell: " & cellX & ", " & cellY
  screenUnlock()
  
  sleep(1, 1)
loop until(Game.keyboard.pressed(Fb.SC_ESCAPE))

map_destroy(m)
imageDestroy(minimap.buffer)

sprites_destroy(male_sprites())
sprites_destroy(female_sprites())
sprites_destroy(tiles())
sprites_destroy(items())
sprites_destroy(monsters())
