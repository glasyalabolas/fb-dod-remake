#ifndef __FB_MOUSE_GM__
#define __FB_MOUSE_GM__

#include once "fbgfx.bi"

namespace Fb
  /'
    02/12/2025
      Fixed crash when requesting state for the middle mouse button (&h10). For fbgfx flags, you need
      at least 10 slots for buttons (even though not all of them are used).
  '/
  type MouseInput
    public:
      declare constructor()
      declare constructor(as long)
      declare destructor()
      
      declare function move(byref as long = -1, byref as long = -1) as boolean
      declare function pressed(as long) as boolean
      declare function released(as long) as boolean
      declare function held(as long, as double = 0.0d) as boolean
      declare function repeated(as long, as double = 0.0d) as boolean
      declare function drag(as long, byref as boolean = false, _
        byref as long = 0, byref as long = 0) as boolean
      declare function drop(as long, byref as long = -1, byref as long = -1) as boolean
      
    private:
      enum ButtonState
        None
        Pressed               = 1 shl 0
        AlreadyPressed        = 1 shl 1
        Released              = 1 shl 2
        ReleasedInitialized   = 1 shl 3
        Held                  = 1 shl 4
        HeldInitialized       = 1 shl 5
        Repeated              = 1 shl 6
        RepeatedInitialized   = 1 shl 7
        Dragging              = 1 shl 8
        AlreadyDragging       = 1 shl 9
      end enum
      
      '' The bitflags for the button states
      as ulong _
        _state(any), _
        _prevState(any)
      
      as long _
        _mx, _my, _
        _sx, _sy, _
        _ex, _ey, _
        _pmx, _pmy, _
        _pwheel, _
        _wheel
      
      '' Caches when a button started being held/repeated
      as double _
        _heldStartTime(any), _
        _repeatedStartTime(any)
      
      '' Set and clear flags
      #define SETF(_c_, _f_) _c_ or= (_f_)
      #define CLRF(_c_, _f_) _c_ = _c_ and not (_f_)
      
      '' Check flags
      #define ISSET(_c_, _f_) cbool(_c_ and (_f_))
      
      '' Push state
      #define PUSH_STATE(_mb_) _prevState(_mb_) = _state(_mb_)
      
      '' To query the mouse status
      #macro GETMOUSESTATUS(_result_, _b_)
        dim as long _x_, _y_, _b_, _wheel_, _result_
        _result_ = getMouse(_x_, _y_, _wheel_, _b_)
        _pmx = _mx : _pmy = _my
        _mx = _x_ : _my = _y_
      #endmacro
  end type
  
  constructor MouseInput()
    constructor(10)
  end constructor
  
  constructor MouseInput(buttons as long)
    buttons = iif(buttons < 1, 1, buttons)
    
    redim _state(0 to buttons - 1)
    redim _prevState(0 to buttons - 1)
    redim _heldStartTime(0 to buttons - 1)
    redim _repeatedStartTime(0 to buttons - 1)
  end constructor
  
  destructor MouseInput()
  
  end destructor
  
  function MouseInput.move(byref x as long = -1, byref y as long = -1) as boolean
    GETMOUSESTATUS(result, buttons)
    
    x = _mx : y = _my
    
    return result = 0 andAlso cbool(_pmx <> _mx orElse _pmy <> _my)
  end function
  
  /'
    Returns whether or not a button was pressed.
    
    'Pressed' in this context means that the method will return 'true'
    *once* upon a button press. If you press and hold the button, it will
    not report 'true' until you release the button and press it again.
  '/
  function MouseInput.pressed(mb as long) as boolean
    GETMOUSESTATUS(result, buttons)
    
    if (result = 0 andAlso (buttons and mb)) then
      PUSH_STATE(mb)
      
      if (cbool(_prevState(mb) = ButtonState.None) orElse _
        not ISSET(_prevState(mb), ButtonState.Pressed)) then
        
        SETF(_state(mb), ButtonState.Pressed)
      end if
    else
      CLRF(_state(mb), ButtonState.Pressed)
    end if
    
    return not ISSET(_prevState(mb), ButtonState.Pressed) andAlso _
      ISSET(_state(mb), ButtonState.Pressed)
  end function
  
  /'
    Returns whether or not a mouse button was released.
    
    'Released' means that a button has to be pressed and then released for
    this method to return 'true' once, just like the 'pressed()' method
    above.
  '/
  function MouseInput.released(mb as long) as boolean
    GETMOUSESTATUS(result, buttons)
    
    if (result = 0 andAlso ((buttons and mb) = 0)) then
      PUSH_STATE(mb)
      
      if (not ISSET(_prevState(mb), ButtonState.ReleasedInitialized) andAlso _
        not ISSET(_state(mb), ButtonState.ReleasedInitialized)) then
        
        SETF(_state(mb), ButtonState.ReleasedInitialized)
      end if
      
      SETF(_state(mb), ButtonState.Released)
    else
      CLRF(_state(mb), ButtonState.Released)
    end if
    
    return ISSET(_state(mb), ButtonState.Released) andAlso _
      not ISSET(_prevState(mb), ButtonState.Released) andAlso _
      ISSET(_state(mb), ButtonState.ReleasedInitialized) andAlso _
      ISSET(_prevState(mb), ButtonState.ReleasedInitialized)
  end function
  
  /'
    Returns whether or not a mouse button is being held.
    
    'Held' means that the button was pressed and is being held pressed, so the
    method behaves pretty much like a call to 'multiKey()', if the 'interval'
    parameter is unspecified.
    
    If an interval is indeed specified, then the method will report the 'held'
    status up to the specified interval, then it will stop reporting 'true'
    until the button is released and held again.
    
    Both this and the 'released()' method expect their intervals to be expressed
    in milliseconds.
  '/
  function MouseInput.held(mb as long, interval as double = 0.0d) as boolean
    GETMOUSESTATUS(result, buttons)
    
    if (result = 0 andAlso (buttons and mb)) then
      PUSH_STATE(mb)
      
      if (not ISSET(_prevState(mb), ButtonState.HeldInitialized) andAlso _
        not ISSET(_state(mb), ButtonState.HeldInitialized)) then
        
        SETF(_state(mb), ButtonState.HeldInitialized)
        _heldStartTime(mb) = timer()
      end if
      
      if (ISSET(_prevState(mb), ButtonState.Held) orElse _
        ISSET(_prevState(mb), ButtonState.HeldInitialized)) then
        
        SETF(_state(mb), ButtonState.Held)
        
        dim as double elapsed = (timer() - _heldStartTime(mb)) * 1000.0
        
        if (interval > 0.0 andAlso elapsed >= interval) then
          CLRF(_state(mb), ButtonState.Held)
        end if
      end if
    else
      CLRF(_state(mb), ButtonState.Held)
      CLRF(_state(mb), ButtonState.HeldInitialized)
    end if
    
    return ISSET(_prevState(mb), ButtonState.Held) andAlso _
      ISSET(_state(mb), ButtonState.Held)
  end function
  
  /'
    Returns whether or not a mouse button is being repeated.
    
    'Repeated' means that the method will intermittently report the 'true'
    status once 'interval' milliseconds have passed. It can be understood
    as the autofire functionality of some game controllers: you specify the
    speed of the repetition using the 'interval' parameter.
    
    Bear in mind, however, that the *first* repetition will be reported
    AFTER one interval has elapsed. In other words, the reported pattern is 
    [pause] [repeat] [pause] instead of [repeat] [pause] [repeat].
    
    If no interval is specified, the method behaves like a call to
    'held()'.
  '/
  function MouseInput.repeated(mb as long, interval as double = 0.0d) as boolean
    GETMOUSESTATUS(result, buttons)
    
    dim as boolean isPressed = result = 0 andAlso buttons and mb
    
    if (isPressed) then
      PUSH_STATE(mb)
      
      if (not ISSET(_prevState(mb), ButtonState.RepeatedInitialized) andAlso _
        not ISSET(_state(mb), ButtonState.RepeatedInitialized)) then
        
        SETF(_state(mb), ButtonState.RepeatedInitialized)
        _repeatedStartTime(mb) = timer()
      end if
      
      if (ISSET(_prevState(mb), ButtonState.Repeated) orElse _
        ISSET(_prevState(mb), ButtonState.RepeatedInitialized)) then
        
        CLRF(_state(mb), ButtonState.Repeated)
        
        dim as double elapsed = (timer() - _repeatedStartTime(mb)) * 1000.0
        
        if (interval > 0.0) then
          if (elapsed >= interval) then
            SETF(_state(mb), ButtonState.Repeated)
            CLRF(_state(mb), ButtonState.RepeatedInitialized)
          end if
        else
          return isPressed
        end if
      end if
    else
      CLRF(_state(mb), ButtonState.Repeated)
      CLRF(_state(mb), ButtonState.RepeatedInitialized)
    end if
    
    return not ISSET(_prevState(mb), ButtonState.Repeated) andAlso _
      ISSET(_state(mb), ButtonState.Repeated)
  end function
  
  function MouseInput.drag(mb as long, byref dragStarted as boolean = false, _
    byref dx as long = 0, byref dy as long = 0) as boolean
    
    GETMOUSESTATUS(result, buttons)
    
    if (result = 0 andAlso (buttons and mb)) then
      PUSH_STATE(mb)
      
      if (cbool(_prevState(mb) = ButtonState.None) orElse _
        not ISSET(_prevState(mb), ButtonState.AlreadyDragging)) then
        
        SETF(_state(mb), ButtonState.AlreadyDragging)
        
        _sx = _mx : _sy = _my
        
        dragStarted = true
        
        return true
      elseif (ISSET(_state(mb), ButtonState.AlreadyDragging)) then
        SETF(_state(mb), ButtonState.Dragging)
        
        dx = _mx - _sx : dy = _my - _sy
      end if
    else
      CLRF(_state(mb), ButtonState.Dragging)
      CLRF(_state(mb), ButtonState.AlreadyDragging)
      
      _ex = _mx : _ey = _my
      _sx = 0 : _sy = 0
    end if
    
    return ISSET(_prevState(mb), ButtonState.AlreadyDragging) andAlso _
      ISSET(_state(mb), ButtonState.Dragging)
  end function
  
  function MouseInput.drop(mb as long, byref dx as long = -1, byref dy as long = -1) as boolean
    dx = _ex : dy = _ey
    
    dim as boolean hasDropped = ISSET(_prevState(mb), ButtonState.Dragging) andAlso _
      (not ISSET(_state(mb), ButtonState.Dragging))
     
    PUSH_STATE(mb)
    
    return hasDropped
  end function
  
  #undef SETF
  #undef CLRF
  #undef ISSET
  #undef PUSH_STATE
  #undef GETMOUSESTATUS
end namespace
#endif
