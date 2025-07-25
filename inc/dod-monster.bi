enum MONSTER_TYPE
  MONSTER_VAMPIRE
  MONSTER_CRYSTAL_SCORPION
  MONSTER_BLACK_ANT
  MONSTER_NINJA
  
  MONSTER_LAST
end enum

type as sub(as GEntity ptr, as GEntity ptr) monster_melee_func

type GMonster
  as string name
  as long HP, maxHP
  as long att, def
  as long level
  as long XP
  as long tileId
  
  as monster_melee_func onMelee
  
  static as Fb.Image ptr ptr tileset
  static as GMonster MONSTER_DEF(any)
end type

static as GMonster GMonster.MONSTER_DEF(any)
static as Fb.Image ptr ptr GMonster.tileset

sub monster_dispose(e as GEntity ptr)
  map_remove_entity(e->room->map, e)
  room_remove_entity(e->room, e)
  
  entity_destroy(e)
end sub
