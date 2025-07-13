#include once "crt.bi"

'' Number of elements in an array
#define ARRAY_ELEMENTS(_a_) (ubound(_a_) + 1)

'' Add element to array
#macro ARRAY_ADD(_a_, _e_)
  redim preserve _a_(0 to ubound(_a_) + 1)
  _a_(ubound(_a_)) = _e_
#endmacro

'' Add element to array if it's not present
#macro ARRAY_ADD_UNIQUE(_a_, _e_)
  scope
    dim as boolean __exists__
    
    for __i__ as integer = 0 to ARRAY_ELEMENTS(_a_) - 1
      if (_a_(__i__) = _e_) then
        __exists__ = true
        exit for
      end if
    next
    
    if (not __exists__) then
      redim preserve _a_(0 to ubound(_a_) + 1)
      _a_(ubound(_a_)) = _e_
    end if
  end scope
#endmacro

'' Remove element from array
#macro ARRAY_REMOVE(_a_, _i_)
  _a_(_i_) = _a_(ubound(_a_))
  redim preserve _a_(0 to ubound(_a_) - 1)
#endmacro

'' Macros to deal with flags
#define FLAG_SET(_c_, _f_) _c_ or= (_f_)
#define FLAG_CLEAR(_c_, _f_) _c_ = _c_ and not (_f_)
#define FLAG_ISSET(_c_, _f_) _c_ and (_f_)

'' Get color components from composite color
#define CLR_R(_c_) (culng(_c_) shr 16 and 255)
#define CLR_G(_c_) (culng(_c_) shr  8 and 255)
#define CLR_B(_c_) (culng(_c_)        and 255)
#define CLR_A(_c_) (culng(_c_) shr 24        )

'' For color blending
'' d = base, s = blend
'' a is usually the source/blend alpha
'function MinFast(a as ubyte, b as ubyte) as ubyte
'    return b xor ((a xor b) and (a < b))
'end function

'' Branchless max (Note: Relies on FB default TRUE = -1)
'function MaxFast(a as ubyte, b as ubyte) as ubyte
'    return a xor ((a xor b) and (a < b))
'end function

#define C_BLEND(_d_, _s_, _a_, _op_) _
  (_d_ + (_op_ * ((_d_ + (_a_ * ((_s_) - _d_)) shr 8) - _d_) shr 8))
#define CMIN(_a_, _b_) iif(_a_ < _b_, _a_, _b_)
#define CMAX(_a_, _b_) iif(_a_ > _b_, _a_, _b_)
'#define CMIN(_a_, _b_) (_b_ xor ((_a_ xor _b_) and (_a_ < _b_)))
'#define CMAX(_a_, _b_) (_a_ xor ((_a_ xor _b_) and (_a_ < _b_)))
#define CMUL(_a_, _b_) (((_a_) * (_b_)) shr 8)
#define CADD(_a_, _b_) (CMIN(255, _a_ + _b_))
#define CSUB(_a_, _b_) (CMAX(0, _a_ - _b_))

type XY
  as long x, y
end type

sub merge_sort(A as long ptr, B as long ptr, n as long)
  #define __min__(_a_, _b_) iif(_a_ < _b_, _a_, _b_)
  
  #macro __bottomUpMerge__(_A_, iLeft, iRight, iEnd, _B_)
    dim as integer _i_ = iLeft, _j_ = iRight
  
    for _k_ as integer = iLeft to iEnd - 1
      if (_i_ < iRight andAlso (_j_ >= iEnd orElse _A_[_i_] <= _A_[_j_])) then
        _B_[_k_] = _A_[_i_]
        _i_ += 1
      else
        _B_[_k_] = _A_[_j_]
        _j_ += 1
      end if
    next
  #endmacro
  
  dim as integer width_ = 1
  
  do while (width_ < n)
    dim as integer i = 0
    
    do while (i < n)
      __bottomUpMerge__(A, i, __min__(i + width_, n), __min__(i + 2 * width_, n), B)
      i += 2 * width_
    loop
    
    memcpy(A, B, n * sizeof(long))
    
    width_ *= 2
  loop
end sub

#ifndef debug
  sub debug(text as string = "")
    dim as integer fn = freeFile()
    
    open cons for output as fn
      ? #fn, text
    close(fn)
  end sub
#endif

#ifndef SetDPIAwareness
  sub SetDPIAwareness()
    #ifdef __FB_WIN32__
    
    debug "Setting DPI awareness status"
    dim as integer isDPIAware = FALSE
    dim shcoredll as any ptr
    dim SetProcessDpiAwareness as function(byval PROCESS_DPI_AWARENESS as long) as long
    dim SetProcessDpiAware as function() as long
    shcoredll=dylibload("shcore")
    if shcoredll then
        SetProcessDpiAwareness=DyLibSymbol(shcoredll,"SetProcessDpiAwareness")
        if SetProcessDpiAwareness then
            dim as long ret1=SetProcessDpiAwareness(2)
            if ret1 then
                debug "        DPI: SetProcessDPIAwareness() returned "& ret1
            else
                debug "        DPI: SetProcessDPIAwareness() returned "& ret1
                isDPIAware = TRUE
            end if
        else
            debug "        DPI : SetProcessDPIAwareness not found."
        end if
    else
        debug "        DPI: SHCORE is not available"
    end if
    if isDPIAware = FALSE then
        dim as boolean ret = SetProcessDPIAware()
        if ret then
            debug "        DPI: SetProcessDPIAware() returned "& ret
            isDPIAware = TRUE
        else
            debug "        DPI: SetProcessDPIAware() returned "& ret
        end if
    end if
    if isDPIAware then
        debug "    DPI awareness is ENABLED"
    else
        debug "    DPI awareness is not enabled"
    end if
  end sub
  
  #endif
#endif
