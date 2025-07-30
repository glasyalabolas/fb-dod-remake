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
