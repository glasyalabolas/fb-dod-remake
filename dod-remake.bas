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
#include once "inc/dod-base-hooks.bi"
#include once "inc/dod-items.bi"
#include once "inc/dod-player.bi"

#include once "inc/dod-item-hooks.bi"
#include once "inc/dod-dtors.bi"

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

dim as single scale = Game.tileViewSize / Game.tileSize

sprites_get(male_sprites(), "res/player-male.png", Game.tileSize, scale)
sprites_get(female_sprites(), "res/player-female.png", Game.tileSize, scale)
sprites_get(tiles(), "res/tiles-2.png", Game.tileSize, scale)
sprites_get(items(), "res/items.png", Game.tileSize, scale)

init_item_defs(@items(0))

mp.tileset = @tiles(0)
mp.tileCount = ARRAY_ELEMENTS(tiles)

map_init(m, @mp)
rooms_init(m)

map_add_entity(m, item_create(ITEM_HEALTH_POTION, rng(1, Game.viewWidth - 2), rng(2, Game.viewHeight - 2)), rng(0, m->w - 1), rng(0, m->h - 1))
map_add_entity(m, item_create(ITEM_SCROLL, rng(1, Game.viewWidth - 2), rng(2, Game.viewHeight - 2)), rng(0, m->w - 1), rng(0, m->h - 1))
map_add_entity(m, item_create(ITEM_MAP, rng(1, Game.viewWidth - 2), rng(2, Game.viewHeight - 2)), rng(0, m->w - 1), rng(0, m->h - 1))

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
