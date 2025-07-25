'' General purpose utilities
#include once "inc/utils.bi"
#include once "inc/rng.bi"
#include once "inc/math.bi"
#include once "inc/fb-linkedlist.bi"
#include once "inc/list-op.bi"
#include once "inc/fb-mouse-gm.bi"
#include once "inc/fb-keyboard-mk.bi"
#include once "inc/sprite-sheet.bi"

'' Game specific code
#include once "inc/dod-font.bi"
#include once "inc/dod-messagebox.bi"

'' Global settings
const as ulong MSG_COLOR_DAMAGE = rgb(231, 76, 60)
const as ulong MSG_COLOR_HIT = rgb(230, 126, 34)
const as ulong MSG_COLOR_GOOD = rgb(52, 152, 219)
const as ulong MSG_COLOR_BAD = rgb(22, 160, 133)
const as ulong MSG_COLOR_TREASURE = rgb(241, 196, 15)

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
  static as GMessageBox ptr _messageBox
end type

static as Fb.KeyboardInput Game.keyboard = Fb.KeyboardInput()
static as Fb.MouseInput Game.mouse = Fb.MouseInput()
static as long Game.tileSize = 32           '' Tile size on the sprite sheet
static as long Game.tileViewSize = 48       '' Tile size on the view
static as long Game.viewWidth = 17          '' Number of horizontal tiles on view
static as long Game.viewHeight = 19         '' Number of vertical tiles on view
static as long Game.statusPanelSize = 400   '' Size of the side bar that displays status
static as long Game.statusPanelMargin = 10  '' Margin of the elements on the side bar
static as double Game.keySpeed = 100.0      '' Key repeat speed, in milliseconds
static as GMessageBox ptr Game._messageBox  '' Message box for all game messages

sub game_init()
  Game._messageBox = messagebox_create(10, Game.statusPanelSize - Game.statusPanelMargin * 2)
  messagebox_set_font(Game._messageBox, font_load("res/game.fnt"))
end sub

sub game_deinit()
  messagebox_destroy(Game._messageBox)
end sub

sub game_message(text as string, clr as ulong = rgb(255, 255, 255))
  message(Game._messageBox, text, clr)
end sub

#include once "inc/dod-tileset.bi"
#include once "inc/dod-entity.bi"
#include once "inc/dod-map.bi"
#include once "inc/dod-minimap.bi"
#include once "inc/dod-distance-field.bi"
#include once "inc/dod-room.bi"
#include once "inc/dod-pathing.bi"
#include once "inc/dod-base-hooks.bi"
#include once "inc/dod-items.bi"
#include once "inc/dod-player.bi"
#include once "inc/dod-monster.bi"

#include once "inc/dod-item-hooks.bi"
#include once "inc/dod-monster-hooks.bi"
#include once "inc/dod-player-hooks.bi"

#include once "inc/dod-dtors.bi"

sub map_add_entity(m as Map ptr, e as GEntity ptr, x as long, y as long)
  room_add_entity(@(m->cell(x, y).room), e)
  debug("map_add_entity: " & e->name)
  
  select case as const (e->gtype)
    case ENTITY_PLAYER
      m->entities.addFirst(e)
    
    case ENTITY_ITEM
      if (m->entities.count = 0) then
        m->entities.addLast(e)
      else
        m->entities.addAfter(m->entities.first, e)
      end if
      
      if (e->shownOnMap) then
        m->cell(x, y).entity = e
      end if
    
    case ENTITY_MONSTER
      e->monster->level = m->level
      m->entities.addLast(e)
      
    case else
      m->entities.addLast(e)
  end select
  
  if (e->onInit) then
    e->onInit(e)
  end if
end sub

sub distance_field_render(df as DistanceField ptr, ts as long)
  for y as integer = 0 to df->h - 1
    for x as integer = 0 to df->w - 1
      dim as long x0 = x * ts, y0 = y * ts
      dim as long x1 = x0 + ts - 1, y1 = y0 + ts - 1
      
      dim as ulong clr = rgb(0, 0, 0)
      
      if (df->cell(x, y).flags and DF_IMPASSABLE) then
        clr = rgb(255, 0, 0)
      end if
      
      if (df->cell(x, y).flags and DF_ENTITY) then
        clr = rgb(0, 255, 255)
      end if
      
      line(x0, y0) - (x1, y1), clr, b
      
'      draw string(x0 + 5, y0 + 5), str(df->cell(x, y).cost), rgb(0, 0, 0)
'      draw string(x0 + 4, y0 + 4), str(df->cell(x, y).cost), rgb(0, 192, 192)
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

game_init()

'' Create map
dim as MapParams mp

with mp
  .w = 4 : .h = 4
  .level = 1
  .viewWidth = @Game.viewWidth
  .viewHeight = @Game.viewHeight
  .tileSize = @Game.tileViewSize
  .tickInterval = 1.5
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
  .blinkTime = 0.5
end with

dim as Fb.Image ptr male_sprites()
dim as Fb.Image ptr female_sprites()
dim as Fb.Image ptr tiles()
dim as Fb.Image ptr items()
dim as Fb.Image ptr monsters()

dim as single scale = Game.tileViewSize / Game.tileSize

'' Load tileset
dim as Tileset tileset

tileset_get_tiles(tileset.floors(), "res/floor/", "floor-*.bmp", Game.tileSize, scale)
tileset_get_tiles(tileset.walls(), "res/wall/", "wall-*.bmp", Game.tileSize, scale)
tileset_get_tiles(tileset.wallTops(), "res/wall-top/", "walltop-*.bmp", Game.tileSize, scale)

'for i as integer = 0 to ubound(tileset.floors)
'  for j as integer = 0 to ubound(tileset.floors(i).tile)
'    put(j * tileset.floors(i).tile(j)->width, i * tileset.floors(i).tile(j)->height), tileset.floors(i).tile(j), alpha
'  next
'next

'sleep()

sprites_get(male_sprites(), "res/player-male.bmp", Game.tileSize, scale)
sprites_get(female_sprites(), "res/player-female.bmp", Game.tileSize, scale)
sprites_get(tiles(), "res/tiles-2.bmp", Game.tileSize, scale)
sprites_get(items(), "res/items.bmp", Game.tileSize, scale)
sprites_get(monsters(), "res/monsters.bmp", Game.tileSize, scale)

mp.tileset = @tiles(0)
mp.tileCount = ARRAY_ELEMENTS(tiles)
mp._tileset = @tileset

items_init(@items(0))
monsters_init(@monsters(0))

map_init(m, @mp)
rooms_init(m)

map_add_entity(m, item_create(ITEM_HEALTH_POTION, rng(2, Game.viewWidth - 2), rng(2, Game.viewHeight - 3)), rng(0, m->w - 1), rng(0, m->h - 1))
map_add_entity(m, item_create(ITEM_SCROLL, rng(2, Game.viewWidth - 2), rng(2, Game.viewHeight - 3)), rng(0, m->w - 1), rng(0, m->h - 1))
map_add_entity(m, item_create(ITEM_MAP, rng(2, Game.viewWidth - 2), rng(2, Game.viewHeight - 3)), rng(0, m->w - 1), rng(0, m->h - 1))
map_add_entity(m, item_create(ITEM_KEY, rng(2, Game.viewWidth - 2), rng(2, Game.viewHeight - 3)), rng(0, m->w - 1), rng(0, m->h - 1))

map_add_entity(m, monster_create(MONSTER_VAMPIRE, 4, 4), 0, 0)
'map_add_entity(m, monster_create(MONSTER_CRYSTAL_SCORPION, 8, 4), 0, 0)
'map_add_entity(m, monster_create(MONSTER_BLACK_ANT, 4, 8), 0, 0)
'map_add_entity(m, monster_create(MONSTER_NINJA, 8, 8), 0, 0)

'map_add_entity(m, monster_create(MONSTER_VAMPIRE, 5, 4), 0, 0)
'map_add_entity(m, monster_create(MONSTER_CRYSTAL_SCORPION, 9, 4), 0, 0)
'map_add_entity(m, monster_create(MONSTER_BLACK_ANT, 3, 8), 0, 0)
'map_add_entity(m, monster_create(MONSTER_NINJA, 9, 8), 0, 0)

var player = player_create(@female_sprites(0), 1, Game.viewWidth / 2, Game.viewHeight / 2)

map_add_entity(m, player, 0, 0)

dim as long minimapPosX = Game.viewWidth * Game.tileViewSize + Game.statusPanelMargin
dim as long minimapPosY = Game.statusPanelMargin
dim as long messageBoxPosX = minimapPosX
dim as long messageBoxPosY = Game.viewHeight * Game.tileViewSize - Game._messageBox->maxRows * Game._messageBox->font->h - Game.statusPanelMargin

dim as long mx, my
dim as MapRoom ptr room = player->room

m->currentTick = timer()
minimap_init(@minimap)

map_reveal(m)

do
  minimap_process(@minimap)
  map_process(m)
  
  Game.mouse.move(mx, my)
  
  dim as long cellX = -1, cellY = -1
  dim as long tileX = -1, tileY = -1
  
  if (mx >= minimapPosX andAlso mx <= minimapPosX + minimap.buffer->width - 1) then
    cellX = (mx - minimapPosX) \ minimap.cellSize
  end if
  
  if (my >= minimapPosY andAlso my <= minimapPosY + minimap.buffer->height - 1) then
    cellY = (my - minimapPosY) \ minimap.cellSize
  end if
  
  if (mx >= 0 andAlso mx <= Game.viewWidth * Game.tileViewSize - 1) then
    tileX = mx \ Game.tileViewSize
  end if
  
  if (my >= 0 andAlso my <= Game.viewHeight * Game.tileViewSize - 1) then
    tileY = mY \ Game.tileViewSize
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
    messagebox_render(Game._messageBox, messageBoxPosX, messageBoxPosY)
    
    room_render(room)
    
    'distance_field_render(room->distanceField, Game.tileViewSize)
    
    if (cellX <> -1 andAlso cellY <> -1) then
      ? map_cell_door_count(m, cellX, cellY)
    end if
    
    var cells = map_get_cells(m, 2)
    
    var n = cells->first
    
    do while (n)
      dim as MapCell ptr cell = n->item
      
      dim as long x0 = minimapPosX + cell->x * minimap.cellSize, y0 = minimapPosY + cell->y * minimap.cellSize
      dim as long x1 = x0 + minimap.cellSize - 1, y1 = y0 + minimap.cellSize - 1
      
      line(x0, y0) - (x1, y1), rgb(255, 255, 0), b
      
      n = n->forward
    loop
    
    delete(cells)
    
'    if (tileX <> -1 andAlso tileY <> -1) then
'      ? room_door_count(@m->cell(tileX, tileY).room)
'    end if
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

tileset_destroy(@tileset)

game_deinit()