enum ITEM_TYPE
  ITEM_MAP
  ITEM_HEALTH_POTION
  ITEM_SCROLL
  ITEM_KEY
  ITEM_SWORD
  ITEM_ARMOR
  ITEM_SHIELD
  ITEM_COIN
  
  ITEM_LAST
end enum

type GItem
  as string name
  as ITEM_TYPE gtype
  as ulong minimap_render_color
  as long tileId
  as boolean shownOnMap
  
  as entity_minimap_render_func onMinimapRender
  as entity_pickup_func onPickup
  
  static as GItem ITEM_DEF(any)
  static as Fb.Image ptr ptr tileset
end type

static as GItem GItem.ITEM_DEF(any)
static as Fb.Image ptr ptr GItem.tileset

sub item_render(e as GEntity ptr)
  dim as long tileSize = *(e->room->cell->map->tileInfo.tileSize)
  
  put(e->x * tileSize, e->y * tileSize), e->item->tileset[e->tileId], alpha
end sub

sub item_minimap_render(e as GEntity ptr, p as Minimap ptr)
  dim as ulong itmColor = e->item->minimap_render_color
  dim as long size = p->cellSize \ 3
  dim as long x0 = e->room->cell->x * p->cellSize + size, y0 = e->room->cell->y * p->cellSize + size
  dim as long x1 = x0 + size - 1, y1 = y0 + size - 1
  
  line p->buffer, (x0, y0) - (x1, y1), itmColor, bf
end sub

'' Should be called after the item applied its effects to remove it from the
'' map and dispose of it
sub item_dispose(e as GEntity ptr)
  '' Remove it from the minimap display if it's there
  if (e->room->cell->entity = e) then
    e->room->cell->entity = 0
  end if
  
  map_remove_entity(e->room->map, e)
  room_remove_entity(e->room, e)
  
  entity_destroy(e)
end sub

'' Only the player can pick up items
'' Returns false as it does not block movement
function item_collide(e as GEntity ptr, who as GEntity ptr) as boolean
  if (who->gtype = ENTITY_PLAYER) then
    if (e->onPickup) then
      e->onPickup(e, who)
    end if
  end if
  
  return false
end function

'' These will be defined after the player has been defined
declare sub health_potion_pickup(as GEntity ptr, as GEntity ptr)
declare sub scroll_pickup(as GEntity ptr, as GEntity ptr)
declare sub map_pickup(as GEntity ptr, as GEntity ptr)
declare sub key_pickup(as GEntity ptr, as GEntity ptr)

sub items_init(tileset as Fb.Image ptr ptr)
  redim GItem.ITEM_DEF(0 to ITEM_LAST - 1)
  GItem.tileset = tileset
  
  with GItem.ITEM_DEF(ITEM_MAP)
    .name = "Floor Map"
    .gtype = ITEM_MAP
    .onMinimapRender = @item_minimap_render
    .onPickup = @map_pickup
    .minimap_render_color = rgb(127, 127, 127)
    .tileId = 3
    .shownOnMap = true
  end with
  
  with GItem.ITEM_DEF(ITEM_HEALTH_POTION)
    .name = "Health Potion"
    .gtype = ITEM_HEALTH_POTION
    .minimap_render_color = rgb(0, 0, 255)
    .tileId = 4
    .onMinimapRender = @item_minimap_render
    .onPickup = @health_potion_pickup
    .shownOnMap = true
  end with
  
  with GItem.ITEM_DEF(ITEM_SCROLL)
    .name = "Magic Scroll"
    .gtype = ITEM_SCROLL
    .onMinimapRender = @item_minimap_render
    .onPickup = @scroll_pickup
    .minimap_render_color = rgb(255, 127, 127)
    .tileId = 7
    .shownOnMap = true
  end with
  
  with GItem.ITEM_DEF(ITEM_KEY)
    .name = "Key"
    .gtype = ITEM_KEY
    .onMinimapRender = @item_minimap_render
    .minimap_render_color = rgb(127, 63, 31)
    .onPickup = @key_pickup
    .tileId = 6
    .shownOnMap = true
  end with
  
  with GItem.ITEM_DEF(ITEM_SWORD)
    .name = "Sword"
    .gtype = ITEM_SWORD
    .onMinimapRender = @item_minimap_render
    .minimap_render_color = rgb(0, 255, 0)
    .tileId = 0
    .shownOnMap = true
  end with
  
  with GItem.ITEM_DEF(ITEM_ARMOR)
    .name = "Armor"
    .gtype = ITEM_ARMOR
    .onMinimapRender = @item_minimap_render
    .minimap_render_color = rgb(0, 255, 0)
    .tileId = 1
    .shownOnMap = true
  end with
  
  with GItem.ITEM_DEF(ITEM_SHIELD)
    .name = "Shield"
    .gtype = ITEM_SHIELD
    .onMinimapRender = @item_minimap_render
    .minimap_render_color = rgb(0, 255, 0)
    .tileId = 2
    .shownOnMap = true
  end with
  
  with GItem.ITEM_DEF(ITEM_COIN)
    .name = "Gold Coin"
    .gtype = ITEM_COIN
    .tileId = 8
  end with
end sub

function item_create(what as ITEM_TYPE, x as long, y as long) as GEntity ptr
  var e = new GEntity
  
  e->gtype = ENTITY_ITEM
  e->item = @GItem.ITEM_DEF(what)
  e->name = e->item->name
  e->x = x
  e->y = y
  e->tileId = GItem.ITEM_DEF(what).tileId
  e->shownOnMap = e->item->shownOnMap
  e->onRender = @item_render
  e->onMinimapRender = e->item->onMinimapRender
  e->onCollide = @item_collide
  e->onPickup = e->item->onPickup
  
  return e
end function
