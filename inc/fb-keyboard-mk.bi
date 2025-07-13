#ifndef __FB_KEYBOARD_MK__
#define __FB_KEYBOARD_MK__

namespace Fb
  type KeyboardInput
    public:
      declare constructor()
      declare constructor(as integer)
      declare destructor()
      
      declare function pressed(as long) as boolean
      declare function released(as long) as boolean
      declare function held(as long, as double = 0.0) as boolean
      declare function repeated(as long, as double = 0.0) as boolean
      
    private:
      enum KeyState
        None
        Pressed               = 1 shl 0
        AlreadyPressed        = 1 shl 1
        Released              = 1 shl 2
        ReleasedInitialized   = 1 shl 3
        Held                  = 1 shl 4
        HeldInitialized       = 1 shl 5
        Repeated              = 1 shl 6
        RepeatedInitialized   = 1 shl 7
      end enum
      
      '' These will store the bitflags for the key states
      as ubyte _
        _state(any), _
        _prevState(any)
      
      '' Caches when a key started being held/repeated
      as double _
        _heldStartTime(any), _
        _repeatedStartTime(any)
      
    '' Set and clear flags
    #define SETF(_c_, _f_) _c_ or= (_f_)
    #define CLRF(_c_, _f_) _c_ = _c_ and not (_f_)
    
    '' Check flags
    #define ISSET(_c_, _f_) cbool(_c_ and (_f_))
  end type
  
  constructor KeyboardInput()
    constructor(128)
  end constructor
  
  constructor KeyboardInput(aNumberOfKeys as integer)
    dim as integer keys = iif(aNumberOfKeys < 128, 128, aNumberOfKeys)
    
    redim _state(0 to keys - 1)
    redim _prevState(0 to keys - 1)
    redim _heldStartTime(0 to keys - 1)
    redim _repeatedStartTime(0 to keys - 1)
  end constructor
  
  destructor KeyboardInput()
  end destructor
  
  /'
    Returns whether or not a key was pressed.
    
    'Pressed' in this context means that the method will return 'true'
    *once* upon a key press. If you press and hold the key, it will
    not report 'true' until you release the key and press it again.
  '/
  function KeyboardInput.pressed(sc as long) as boolean
    if (multiKey(sc) ) then
      _prevState(sc) = _state(sc)
      
      if (cbool(_prevState(sc) = KeyState.None) orElse _
        not ISSET(_prevState(sc), KeyState.Pressed)) then
        
        SETF(_state(sc), KeyState.Pressed)
      end if
    else
      CLRF(_state(sc), KeyState.Pressed)
    end if
    
    return not ISSET(_prevState(sc), KeyState.Pressed) andAlso _
      ISSET(_state(sc), KeyState.Pressed)
  end function
  
  /'
    Returns whether or not a key was released.
    
    'Released' means that a key has to be pressed and then released for
    this method to return 'true' once, just like the 'pressed()' method
    above.
  '/
  function KeyboardInput.released(sc as long) as boolean
    if (not multiKey(sc)) then
      _prevState(sc) = _state(sc)
      
      if (not ISSET(_prevState(sc), KeyState.ReleasedInitialized) andAlso _
        not ISSET(_state(sc), KeyState.ReleasedInitialized)) then
        
        SETF(_state(sc), KeyState.ReleasedInitialized)
      end if
      
      SETF(_state(sc), KeyState.Released)
    else
      CLRF(_state(sc), KeyState.Released)
    end if
    
    return ISSET(_state(sc), KeyState.Released) andAlso _
      not ISSET(_prevState(sc), KeyState.Released) andAlso _
      ISSET(_state(sc), KeyState.ReleasedInitialized) andAlso _
      ISSET(_prevState(sc), KeyState.ReleasedInitialized)
  end function
  
  /'
    Returns whether or not a key is being held.
    
    'Held' means that the key was pressed and is being held pressed, so the
    method behaves pretty much like a call to 'multiKey()', if the 'interval'
    parameter is unspecified.
    
    If an interval is indeed specified, then the method will report the 'held'
    status up to the specified interval, then it will stop reporting 'true'
    until the key is released and held again.
    
    Both this and the 'released()' method expect their intervals to be expressed
    in milliseconds.
  '/
  function KeyboardInput.held(sc as long, interval as double = 0.0) as boolean
    if (multiKey(sc)) then
      _prevState(sc) = _state(sc)
    
      if (not ISSET(_prevState(sc), KeyState.HeldInitialized) andAlso _
        not ISSET(_state(sc), KeyState.HeldInitialized)) then
        
        SETF(_state(sc), KeyState.HeldInitialized)
        _heldStartTime(sc) = timer()
      end if
      
      if (ISSET(_prevState(sc), KeyState.Held) orElse _
        ISSET(_prevState(sc), KeyState.HeldInitialized)) then
        
        SETF(_state(sc), KeyState.Held)
        
        dim as double elapsed = (timer() - _heldStartTime(sc)) * 1000.0
        
        if (interval > 0.0 andAlso elapsed >= interval) then
          CLRF(_state(sc), KeyState.Held)
        end if
      end if
    else
      CLRF(_state(sc), KeyState.Held)
      CLRF(_state(sc), KeyState.HeldInitialized)
    end if
    
    return ISSET(_prevState(sc), KeyState.Held) andAlso _
      ISSET(_state(sc), KeyState.Held)
  end function
  
  /'
    Returns whether or not a key is being repeated.
    
    'Repeated' means that the method will intermittently report the 'true'
    status once 'interval' milliseconds have passed. It can be understood
    as the autofire functionality of some game controllers: you specify the
    speed of the repetition using the 'interval' parameter.
    
    Bear in mind, however, that the *first* repetition will be reported
    AFTER one interval has elapsed. In other words, the reported pattern is 
    [pause] [repeat] [pause] instead of [repeat] [pause] [repeat].
    
    If no interval is specified, the method behaves like a call to
    'multiKey()'.
  '/
  function KeyboardInput.repeated(sc as long, interval as double = 0.0) as boolean  
    dim as boolean isPressed = multiKey(sc)
    
    if (isPressed) then
      _prevState(sc) = _state(sc)
    
      if (not ISSET(_prevState(sc), KeyState.RepeatedInitialized) andAlso _
        not ISSET(_state(sc), KeyState.RepeatedInitialized)) then
        
        SETF(_state(sc), KeyState.RepeatedInitialized)
        _repeatedStartTime(sc) = timer()
      end if
      
      if (ISSET(_prevState(sc), KeyState.Repeated) orElse _
        ISSET(_prevState(sc), KeyState.RepeatedInitialized)) then
        
        CLRF(_state(sc), KeyState.Repeated)
        
        dim as double elapsed = (timer() - _repeatedStartTime(sc)) * 1000.0
        
        if (interval > 0.0) then
          if (elapsed >= interval) then
            SETF(_state(sc), KeyState.Repeated)
            CLRF(_state(sc), KeyState.RepeatedInitialized)
          end if
        else
          return isPressed
        end if
      end if
    else
      CLRF(_state(sc), KeyState.Repeated)
      CLRF(_state(sc), KeyState.RepeatedInitialized)
    end if
    
    return not ISSET(_prevState(sc), KeyState.Repeated) andAlso _
      ISSET(_state(sc), KeyState.Repeated)
  end function
  
  #undef SETF
  #undef CLRF
  #undef ISSET
end namespace

#endif
