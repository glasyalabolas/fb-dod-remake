enum STAIRCASE_TYPE
  STAIRCASE_UP
  STAIRCASE_DOWN
end enum

type GStaircase
  as STAIRCASE_TYPE stype
  
  static as Fb.Image ptr ptr tileset
end type

static as Fb.Image ptr ptr GStaircase.tileset
