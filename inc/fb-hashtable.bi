#ifndef __FB_HASHTABLE__
#define __FB_HASHTABLE__

#include once "fb-linkedlist.bi"

namespace Fb
  type HashTableEntry
    declare constructor(as string, as any ptr)
    declare constructor(as integer, as any ptr)
    
    declare destructor()
    
    as string key
    as integer int_key
    as any ptr value
  end type
  
  constructor HashTableEntry(k as string, v as any ptr)
    key = k
    value = v
  end constructor
  
  constructor HashTableEntry(k as integer, v as any ptr)
    int_key = k
    value = v
  end constructor
  
  destructor HashTableEntry() : end destructor
  
  '' 64 bit hashing function
  '' https://github.com/lemire/Code-used-on-Daniel-Lemire-s-blog/blob/master/2018/08/15/src/main/java/me/lemire/microbenchmarks/algorithms/HashFast.java
  function int_hash(x as longint) as ulongint
    static as ulongint a1 = &h65d200ce55b19ad8ULL
    static as ulongint b1 = &h4f2162926e40c299ULL
    static as ulongint c1 = &h162dd799029970f8ULL
    static as ulongint a2 = &h68b665e6872bd1f4ULL
    static as ulongint b2 = &hb6cfcf9d79b51db2ULL
    static as ulongint c2 = &h7a2b92ae912898c2ULL
    
    dim as ulong low = x, high = x shr 32
    
    return( ( a1 * low + b1 * high + c1 ) shr 32 ) or _
          ( ( a2 * low + b2 * high + c2 ) and &hFFFFFFFF00000000ULL )
  end function
  
  '' Fast string hashing function
  '' tmc
  function str_hash(value as string) as ulong
    #define ROT(a, b) ((a shl b) or (a shr (32 - b)))
    
    dim as zstring ptr strp = strPtr(value)
    dim as integer _
      l = len(value), _
      extra_bytes = l and 3
    
    l shr= 2
    
    dim as ulong hash = &hdeadbeef
    
    do while(l)
      hash += *cast(ulong ptr, strp)
      strp += 4
      hash = (hash shl 5) - hash
      hash xor= ROT(hash, 19)
      l -= 1
    loop
    
    if(extra_bytes) then
      select case as const(extra_bytes)
        case 3
          hash xor= *cast(ulong ptr, strp) and &hffffff
        case 2
          hash xor= *cast(ulong ptr, strp) and &hffff
        case 1
          hash xor= *strp
      end select
      
      hash = (hash shl 5) - hash
      hash xor= rot(hash, 19)
    end if
    
    hash += ROT(hash, 2)
    hash xor= ROT(hash, 27)
    hash += ROT(hash, 16)
    
    return hash
  end function
  
  '' Hash table
  type HashTable
    public:
      declare constructor()
      declare constructor(as integer)
      declare destructor()
      
      declare operator [](as string) as any ptr
      declare operator [](as integer) as any ptr
      
      declare property size() as integer
      declare property count() as integer
      
      declare function containsKey(as string) as boolean
      declare function containsKey(as integer) as boolean
      
      declare sub getKeys(a() as string)
      declare sub getValues(a() as any ptr)
      
      declare function add( as string, as any ptr ) as any ptr
      declare function add( as integer, as any ptr ) as any ptr
      declare function remove( as string ) as any ptr
      declare function remove( as integer ) as any ptr
      
      declare function clear() byref as HashTable
      declare function find( as string ) as any ptr
      declare function find( as integer ) as any ptr
      declare function findEntry( as string ) as HashTableEntry ptr
      declare function findEntry( as integer ) as HashTableEntry ptr
      declare function findBucket( as string ) as LinkedList ptr
      declare function findBucket( as integer ) as LinkedList ptr
      
    private:
      declare sub _dispose( as integer, as LinkedList ptr ptr ) 
      declare sub _setResizeThresholds( as integer, as single, as single )
      declare sub _addEntry( as HashTableEntry ptr, as LinkedList ptr ptr, as integer )
      declare function _removeEntry( as string ) as HashTableEntry ptr
      declare function _removeEntry( as integer ) as HashTableEntry ptr
      declare sub _rehash( as integer )
      
      as LinkedList ptr ptr _hashTable
      
      as integer _
        _count, _
        _size, _
        _initialSize, _
        _maxThreshold, _
        _minThreshold
      
      static as const single _
        LOWER_THRESHOLD, _
        UPPER_THRESHOLD
  end type
  
  dim as const single _
    HashTable.LOWER_THRESHOLD = 0.55f, _
    HashTable.UPPER_THRESHOLD = 0.85f
  
  constructor HashTable()
    constructor( 256 )
  end constructor
  
  constructor HashTable( aSize as integer )
    _initialSize = iif( aSize < 32, 32, aSize )
    _size = _initialSize
    
    _hashTable = callocate( _size, sizeof( LinkedList ptr ) )
    
    _setResizeThresholds( _initialSize, LOWER_THRESHOLD, UPPER_THRESHOLD )
  end constructor
  
  destructor HashTable()
    _dispose( _size, _hashTable )
    
    deallocate( _hashTable )
  end destructor
  
  operator HashTable.[] ( k as string ) as any ptr
    var e = findEntry( k )
    return( iif( e <> 0, e->value, 0 ) )
  end operator
  
  operator HashTable.[] ( k as integer ) as any ptr
    var e = findEntry( k )
    return( iif( e <> 0, e->value, 0 ) )
  end operator
  
  property HashTable.count() as integer
    return( _count )
  end property
  
  property HashTable.size() as integer
    return( _size )
  end property
  
  sub HashTable._dispose( s as integer, ht as LinkedList ptr ptr )
    for i as integer = 0 to s - 1
      if( ht[ i ] <> 0 ) then
        do while( ht[ i ]->count > 0 )
          delete( cast( HashTableEntry ptr, ht[ i ]->removeLast() ) )
        loop
        
        delete( ht[ i ] )
        ht[ i ] = 0
      end if
    next
  end sub
  
  sub HashTable._setResizeThresholds( _
    newSize as integer, lower as single, upper as single )
    
    newSize = iif( newSize < _initialSize, _
	    _initialSize, newSize )
    
    dim as integer previous = newSize shr 1
    
    previous = iif( previous < _initialSize, 0, previous )
    
    _minThreshold = int( previous * lower )
    _maxThreshold = int( newSize * upper )
  end sub
  
  sub HashTable._rehash( newSize as integer )
    _setResizeThresholds( newSize, LOWER_THRESHOLD, UPPER_THRESHOLD )
    
    dim as LinkedList ptr ptr _
      newTable = callocate( newSize, sizeof( LinkedList ptr ) )
    
    _count = 0
    
    for i as integer = 0 to _size - 1
      var bucket = _hashTable[ i ]
      
      if( bucket <> 0 ) then
        var n = bucket->first
        
        do while( n <> 0 )
          _addEntry( n->item, newTable, newSize )
          
          n->item = 0
          n = n->forward
        loop
      end if
    next
    
    _dispose( _size, _hashTable )
    deallocate( _hashTable )
    
    _size = newSize
    _hashTable = newTable
  end sub
  
  function HashTable.findBucket( k as string ) as LinkedList ptr
    return( _hashTable[ str_hash( k ) mod _size ] )
  end function
  
  function HashTable.findBucket( k as integer ) as LinkedList ptr
    return( _hashTable[ int_hash( k ) mod _size ] )
  end function
  
  function HashTable.findEntry( k as string ) as HashTableEntry ptr
    dim as HashTableEntry ptr e = 0
    
    var bucket = findBucket( k )
    
    if( bucket <> 0 ) then
      var n = bucket->last
      
      do while( n <> 0 )
        if( cast( HashTableEntry ptr, n->item )->key = k ) then
          e = n->item
          exit do
        end if
        
        n = n->backward
      loop
    end if
    
    return( e )
  end function
  
  function HashTable.findEntry( k as integer ) as HashTableEntry ptr
    dim as HashTableEntry ptr e = 0
    
    var bucket = findBucket( k )
    
    if( bucket <> 0 ) then
      var n = bucket->last
      
      do while( n <> 0 )
        if( cast( HashTableEntry ptr, n->item )->int_key = k ) then
          e = n->item
          exit do
        end if
        
        n = n->backward
      loop
    end if
    
    return( e )
  end function
  
  function HashTable.clear() byref as HashTable
    _dispose( _size, _hashTable )
    
    _size = _initialSize
    _count = 0
    
    _setResizeThresholds( _initialSize, LOWER_THRESHOLD, UPPER_THRESHOLD )
    
    return( this )
  end function
  
  function HashTable.containsKey( k as string ) as boolean
    return( findEntry( k ) <> 0 )
  end function
  
  function HashTable.containsKey( k as integer ) as boolean
    return( findEntry( k ) <> 0 )
  end function
  
  sub HashTable.getKeys( a() as string )
    redim a( 0 to _count - 1 )
    
    dim as integer item
    
    for i as integer = 0 to _size - 1
      if( _hashTable[ i ] <> 0 ) then
        var n = _hashTable[ i ]->last
        
        for j as integer = 0 to _hashTable[ i ]->count - 1
          a( item ) = cast( HashTableEntry ptr, n->item )->key
          item += 1
          
          n = n->backward
        next
      end if
    next
  end sub
  
  sub HashTable.getValues( a() as any ptr )
    redim a( 0 to _count - 1 )
    
    dim as integer item
    
    for i as integer = 0 to _size - 1
      if( _hashTable[ i ] <> 0 ) then
        var n = _hashTable[ i ]->last
        
        for j as integer = 0 to _hashTable[ i ]->count - 1
          a( item ) = cast( HashTableEntry ptr, n->item )->value
          item += 1
          
          n = n->backward
        next
      end if
    next
  end sub
  
  function HashTable.find( k as string ) as any ptr
    var e = findEntry( k )
    return( iif( e <> 0, e->value, 0 ) )
  end function
  
  function HashTable.find( k as integer ) as any ptr
    var e = findEntry( k )
    return( iif( e <> 0, e->value, 0 ) )
  end function
  
  sub HashTable._addEntry( _
    e as HashTableEntry ptr, ht as LinkedList ptr ptr, s as integer )
    
    dim as ulong bucket = iif( e->int_key, int_hash( e->int_key ), str_hash( e->key ) ) mod s
    
    if( ht[ bucket ] = 0 ) then
      ht[ bucket ] = new LinkedList()
      ht[ bucket ]->addLast( e )
    else
      ht[ bucket ]->addLast( e )
    end if
    
    _count += 1
  end sub
  
  function HashTable.add( k as string, v as any ptr ) as any ptr
    _addEntry( new HashTableEntry( k, v ), _hashTable, _size )
    
    if( _count > _maxThreshold ) then
      _rehash( _size shl 1 )
    end if
    
    return( v )
  end function
  
  function HashTable.add( k as integer, v as any ptr ) as any ptr
    _addEntry( new HashTableEntry( k, v ), _hashTable, _size )
    
    if( _count > _maxThreshold ) then
      _rehash( _size shl 1 )
    end if
    
    return( v )
  end function
  
  function HashTable._removeEntry( k as string ) as HashTableEntry ptr
    var bucket = findBucket( k )
    
    dim as HashTableEntry ptr e = 0
    
    if( bucket <> 0 ) then
      var n = bucket->last
      
      do while( n <> 0 )
        if( cast( HashTableEntry ptr, n->item )->key = k ) then
          e = bucket->remove( n )
          
          _count -= 1
          
          if( _count < _minThreshold ) then
            _rehash( _size shr 1 )
          end if
          
          exit do
        end if
        
        n = n->backward
      loop
    end if
    
    return( e )
  end function
  
  function HashTable._removeEntry( k as integer ) as HashTableEntry ptr
    var bucket = findBucket( k )
    
    dim as HashTableEntry ptr e = 0
    
    if( bucket <> 0 ) then
      var n = bucket->last
      
      do while( n <> 0 )
        if( cast( HashTableEntry ptr, n->item )->int_key = k ) then
          e = bucket->remove( n )
          
          _count -= 1
          
          if( _count < _minThreshold ) then
            _rehash( _size shr 1 )
          end if
          
          exit do
        end if
        
        n = n->backward
      loop
    end if
    
    return( e )
  end function
  
  function HashTable.remove( k as string ) as any ptr
    var bucket = findBucket( k )
    
    dim as any ptr item
    
    if( bucket <> 0 ) then
      var n = bucket->last
      
      do while( n <> 0 )
        if( cast( HashTableEntry ptr, n->item )->key = k ) then
          dim as HashTableEntry ptr e = bucket->remove( n )
          
          item = e->value
          delete( e )
          
          _count -= 1
          
          if( _count < _minThreshold ) then
            _rehash( _size shr 1 )
          end if
          
          exit do
        end if
        
        n = n->backward
      loop
    end if
    
    return( item )
  end function
  
  function HashTable.remove( k as integer ) as any ptr
    var bucket = findBucket( k )
    
    dim as any ptr item
    
    if( bucket <> 0 ) then
      var n = bucket->last
      
      do while( n <> 0 )
        if( cast( HashTableEntry ptr, n->item )->int_key = k ) then
          dim as HashTableEntry ptr e = bucket->remove( n )
          
          item = e->value
          delete( e )
          
          _count -= 1
          
          if( _count < _minThreshold ) then
            _rehash( _size shr 1 )
          end if
          
          exit do
        end if
        
        n = n->backward
      loop
    end if
    
    return( item )
  end function
end namespace

#endif
