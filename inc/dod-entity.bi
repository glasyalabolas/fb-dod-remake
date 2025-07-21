type as GEntity GEntity_
type as GItem GItem_
type as GPlayer GPlayer_
type as GMonster GMonster_
type as Minimap Minimap_
type as MapRoom MapRoom_
type as MapTile MapTile_

type as sub(as GEntity_ ptr) entity_render_func
type as sub(as GEntity_ ptr, as Minimap_ ptr) entity_minimap_render_func
type as sub(as GEntity_ ptr) entity_destroy_func
type as sub(as GEntity_ ptr) entity_tick_func
type as sub(as GEntity_ ptr) entity_init_func
type as sub(as GEntity_ ptr, as MapTile_ ptr) entity_wall_bump_func
type as sub(as GEntity_ ptr) entity_leave_tile_func
type as sub(as GEntity_ ptr) entity_leave_room_func
type as sub(as GEntity_ ptr, as MapRoom_ ptr) entity_enter_room_func
type as sub(as GEntity_ ptr, as GEntity_ ptr) entity_pickup_func
type as sub(as GEntity_ ptr, as GEntity_ ptr) entity_defend_func
type as sub(as GEntity_ ptr, as GEntity_ ptr) entity_killed_func

'' These functions return true if they generate a tick
type as function(as GEntity_ ptr, as long, as long) as boolean entity_enter_tile_func
type as function(as GEntity_ ptr, as long, as long) as boolean entity_move_func
type as function(as GEntity_ ptr) as boolean entity_process_func

'' Collide functions return true if they need to block the entity's movement
type as function(as GEntity_ ptr, as GEntity_ ptr) as boolean entity_collide_func

enum ENTITY_TYPE
  ENTITY_PLAYER
  ENTITY_MONSTER
  ENTITY_GENERATOR
  ENTITY_ITEM
  ENTITY_TRAP
end enum

enum ENTITY_FLAGS
  EFLAG_NONE
  EFLAG_BLOCKS_MOVEMENT = 1 shl 0
end enum

type GEntity
  as string name
  as long x, y
  as long tileId
  as ENTITY_TYPE gtype
  as ENTITY_FLAGS flags
  as MapRoom_ ptr room
  as boolean shownOnMap
  
  union
    type
      as GItem_ ptr item
    end type
    type
      as GPlayer_ ptr player
    end type
    type
      as GMonster_ ptr monster
    end type
  end union
  
  as entity_init_func onInit
  as entity_process_func onProcess
  as entity_tick_func onTick
  as entity_render_func onRender
  as entity_minimap_render_func onMinimapRender
  as entity_move_func onMove
  as entity_wall_bump_func onWallBump
  as entity_destroy_func onDestroy
  as entity_leave_tile_func onLeaveTile
  as entity_enter_tile_func onEnterTile
  as entity_enter_room_func onEnterRoom
  as entity_leave_room_func onLeaveRoom
  as entity_collide_func onCollide
  as entity_pickup_func onPickup
  as entity_defend_func onDefend
  as entity_killed_func onKilled
end type

sub entity_destroy(e as GEntity ptr)
  if (e->onDestroy) then
    e->onDestroy(e)
  end if
  
  delete(e)
end sub
