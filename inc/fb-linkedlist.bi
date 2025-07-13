#ifndef __FB_LINKEDLIST_BI__
#define __FB_LINKEDLIST_BI__

namespace Fb
  #ifndef FBNULL
    #define FBNULL 0
  #endif
  
  type LinkedListNode
    declare constructor()
    declare constructor( as any ptr )
    
    as LinkedListNode ptr forward, backward
    as any ptr item
  end type
  
  constructor LinkedListNode() : end constructor
  
  constructor LinkedListNode( anItem as any ptr )
    item = anItem
  end constructor
  
  '' (Doubly) Linked List
  type LinkedList
    public:
      declare constructor()
      declare destructor()
      
      declare operator [] ( as integer ) as any ptr
      
      declare property count() as integer
      declare property first() as LinkedListNode ptr
      declare property last() as LinkedListNode ptr
      
      declare sub clear( as sub( as any ptr ) = FBNULL )
      declare function findNode(as integer) as LinkedListNode ptr
      declare function addBefore( as LinkedListNode ptr, as any ptr ) as LinkedListNode ptr
      declare function addAfter( as LinkedListNode ptr, as any ptr ) as LinkedListNode ptr
      declare function addFirst( as any ptr ) as LinkedListNode ptr
      declare function addLast( as any ptr ) as LinkedListNode ptr
      declare function remove( as LinkedListNode ptr ) as any ptr
      declare function removeAt(index as integer) as any ptr
      declare function removeFirst() as any ptr
      declare function removeLast() as any ptr
      declare function swapNodes( as LinkedListNode ptr, as LinkedListNode ptr ) as boolean
      
      as sub(as any ptr) _disposeFunc
      
    private:
      as LinkedListNode ptr _first, _last
      as integer _count
  end type
  
  constructor LinkedList() : end constructor
  
  destructor LinkedList()
    clear(_disposeFunc)
  end destructor
  
  operator LinkedList.[]( index as integer ) as any ptr
    var n = _first
    
    for i as integer = 0 to _count - 1
      if( i = index ) then
        return( n->item )
      end if
      
      n = n->forward
    next
    
    return( FBNULL )
  end operator
  
  property LinkedList.count() as integer
    return( _count )
  end property
  
  property LinkedList.first() as LinkedListNode ptr
    return( _first )
  end property
  
  property LinkedList.last() as LinkedListNode ptr
    return( _last )
  end property
  
  sub LinkedList.clear( disposeFunc as sub(as any ptr) = FBNULL )
    if( disposeFunc <> FBNULL ) then
      do while( _count > 0 )
        disposeFunc( remove( _last ) )
      loop
    else
      do while( _count > 0 )
        remove( _last )
      loop
    end if
    
    _first = FBNULL
    _last = _first
  end sub
  
  function LinkedList.findNode(index as integer) as LinkedListNode ptr
    var n = _first
    
    for i as integer = 0 to _count - 1
      if (i = index) then return n
      
      n = n->forward
    next
    
    return FBNULL
  end function
  
  function LinkedList.addBefore( node as LinkedListNode ptr, item as any ptr ) as LinkedListNode ptr
    var newNode = new LinkedListNode( item )
    
    newNode->backward = node->backward
    newNode->forward = node
    
    if( node->backward = FBNULL ) then
      _first = newNode
    else
      node->backward->forward = newNode
    end if
    
    _count += 1
    node->backward = newNode
    
    return( newNode )
  end function
  
  function LinkedList.addAfter( node as LinkedListNode ptr, item as any ptr ) as LinkedListNode ptr
    var newNode = new LinkedListNode( item )
    
    newNode->backward = node
    newNode->forward = node->forward
    
    if( node->forward = FBNULL ) then
      _last = newNode
    else
      node->forward->backward = newNode
    end if
    
    _count += 1
    node->forward = newNode
    
    return( newNode )
  end function
  
  function LinkedList.addFirst( item as any ptr ) as LinkedListNode ptr
    if( _first = FBNULL ) then
      var newNode = new LinkedListNode( item )
      
      _first = newNode
      _last = newNode
      
      newNode->backward = FBNULL
      newNode->forward = FBNULL
      
      _count += 1
      
      return( newNode )
    end if
    
    return( addBefore( _first, item ) )
  end function
  
  function LinkedList.addLast( item as any ptr ) as LinkedListNode ptr
    return( iif( _last = FBNULL, addFirst( item ), addAfter( _last, item ) ) )
  end function
  
  function LinkedList.remove( node as LinkedListNode ptr ) as any ptr
    dim as any ptr item = FBNULL
    
    if( node <> FBNULL andAlso _count > 0 ) then
      if( node->backward = FBNULL ) then
        _first = node->forward
      else
        node->backward->forward = node->forward
      end if
      
      if( node->forward = FBNULL ) then
        _last = node->backward
      else
        node->forward->backward = node->backward
      end if
      
      _count -= 1
      item = node->item
      
      delete( node )
    end if
    
    return( item )
  end function
  
  function LinkedList.removeAt(index as integer) as any ptr
    dim as any ptr item
    
    var n = _first
    
    for i as integer = 0 to _count - 1
      if (i = index) then
        item = remove(n)
        exit for
      end if
      
      n = n->forward
    next
    
    return item 
  end function
  
  function LinkedList.removeFirst() as any ptr
    return( remove( _first ) )
  end function
  
  function LinkedList.removeLast() as any ptr
    return( remove( _last ) )
  end function
  
  function LinkedList.swapNodes( a as LinkedListNode ptr, b as LinkedListNode ptr ) as boolean
    #define neighbors( _a_, _b_ ) ( ( _a_->forward = _b_ andAlso _b_->backward = _a_ ) orElse ( _a_->backward = _b_ andAlso _b_->forward = _a_ ) )
    #macro refresh( _n_ )
      if( _n_->backward <> FBNULL ) then
        _n_->backward->forward = _n_
      else
        _first = _n_
      end if
      
      if( _n_->forward <> FBNULL ) then
        _n_->forward->backward = _n_
      else
        _last = _n_
      end if
    #endmacro
    
    dim as LinkedListNode ptr swpa( 0 to 3 )
    
    if( a = b ) then return( false )
    if( a = FBNULL orElse b = FBNULL ) then return( false )
    
    if( b->forward = a ) then
      var tmp = a
      a = b
      b = tmp
    end if
    
    swpa( 0 ) = a->backward
    swpa( 1 ) = b->backward
    swpa( 2 ) = a->forward
    swpa( 3 ) = b->forward
    
    if( neighbors( a, b ) ) then
      a->backward = swpa( 2 )
      b->backward = swpa( 0 )
      a->forward  = swpa( 3 )
      b->forward  = swpa( 1 )
    else
      a->backward = swpa( 1 )
      b->backward = swpa( 0 )
      a->forward  = swpa( 3 )
      b->forward  = swpa( 2 )
    end if
    
    refresh( a )
    refresh( b )
    
    return( true )
  end function
end namespace

#endif
