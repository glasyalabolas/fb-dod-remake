#ifndef __GAME_RNG__
#define __GAME_RNG__

function rng overload(aMin as long, aMax as long) as long
  return int(rnd() * ((aMax + 1) - aMin) + aMin)
end function

function rng(aMin as double, aMax as double) as double
  return rnd() * (aMax - aMin) + aMin
end function

'' Returns a random number that's either -1 or 1
private function rngn() as long
  return 1 + (-2 and (cint(rnd()) = 0))
end function

'' Returns a random number, biased by a power function with exponent p
'' p > 1 -> tendency to low values
'' p < 1 -> tendency to high values
'' p = 1 -> evenly distributed
'' The bias to the 'high' end of the distribution is *much* sharper than the
'' bias for the 'low' end
function rng_bias overload(low as double, high as double, p as double) as double
  return low + (high - low) * (rnd() ^ p)
end function

function rng_bias(low as long, high as long, p as double) as long
  return int(low + ((high + 1)- low) * (rnd() ^ p))
end function

#endif
