type GPlayer
  as long HP, maxHP
  as long XP, nextLevel
  as long level
  as long swordLevel, armorLevel, shieldLevel
  as long potions, scrolls
  as long tileId
  as double lastPress
  
  static as Fb.Image ptr ptr tileset
end type

static as Fb.Image ptr ptr GPlayer.tileset

