#ifndef __GAME_MATH__
#define __GAME_MATH__

#include once "crt.bi"

const as single _
  C_PI = 4.0f * atn(1.0f), _
  C_TWOPI = 2.0f * C_PI, _
  C_DEGTORAD = C_PI / 180.0f, _
  C_RADTODEG = 180.0f / C_PI

#define rad(_a_) ((_a_) * C_DEGTORAD)
#define deg(_a_) ((_a_) * C_RADTODEG)

#ifndef max
  #define max(_a_, _b_) iif(_a_ > _b_, _a_, _b_)
#endif

#ifndef min
  #define min(_a_, _b_) iif(_a_ < _b_, _a_, _b_)
#endif

#ifndef fModf
  #define fModf(_n_, _d_) (n - int(n / d) * d)
#endif

#ifndef fWrap
  #define fWrap(_x_, _x_min_, _x_max_) (fModf(fModf((_x_ - _x_min_), (_x_max_ - _x_min_)) + (_x_max_ - _x_min_), (_x_max_ - _x_min_)) + _x_min_)
#endif

#ifndef wrap
  #define wrap(_x_, _x_min_, _x_max_) (((((_x_ - _x_min_) mod (_x_max_ - _x_min_)) + (_x_max_ - _x_min_)) mod (_x_max_ - _x_min_)) + _x_min_)
#endif

#ifndef clamp
  #define clamp(_v_, _a_, _b_) (iif(_v_ < _a_, _a_, iif(_v_ > _b_, _b_, _v_)))
#endif

'' Remaps a value from one range into another
private function remap( _
  x as single, start1 as single, end1 as single, start2 as single, end2 as single ) as single
  
  return (x - start1) * (end2 - start2) / (end1 - start1) + start2
end function

#endif
