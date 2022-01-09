sqrt, cos, sin, atan2 = math.sqrt, math.cos, math.sin, math.atan2
min, max = math.min, math.max
rand = love.math.random
pi = math.pi
inf = math.huge

class Vector2D
  new: (x = 0, y = 0) =>
    assert('number' == type(x) and 'number' == type(y),
      'x and y must be numbers.')
    @x = x
    @y = y
    
  @zero: ->
    return Vector2D!

  @one: ->
    return Vector2D 1, 1

  @positiveInfinity: ->
    return Vector2D inf, inf  

  @negativeInfinity: ->
    return Vector2D -inf, -inf  

  @up: ->
    return Vector2D 0, 1

  @down: ->
    return Vector2D 0, -1

  @right: ->
    return Vector2D 1, 0

  @left: ->
    return Vector2D -1, 0

  @isvector: (v) ->
    v.__class == Vector2D
  
  clone: =>
    Vector2D @x, @y
  
  unpack: =>
    @x, @y

  __tostring: =>
    "("..tonumber(@x)..","..tonumber(@y)..")"
  
  __add: (a, b) ->
    assert( Vector2D.isvector(a) and Vector2D.isvector(b), "Wrong argument types <Vector2D> expected. [Add]" )
    Vector2D a.x+b.x, a.y+b.y
  
  __sub: (a, b) ->
    assert( Vector2D.isvector(a) and Vector2D.isvector(b), "Wrong argument types <Vector2D> expected. [Sub]" )
    Vector2D a.x-b.x, a.y-b.y

  __mul: (a, b) ->
    if type(a) == 'number'
      Vector2D a*b.x, a*b.y
    elseif type(b) == 'number'
      Vector2D b*a.x, b*a.y
    else
      assert( Vector2D.isvector(a) and Vector2D.isvector(b), "Wrong argument types <Vector2D> expected. [Mul]" )
      a.x*b.x + a.y*b.y -- Dot product

  __div: (a, b) ->
    assert( Vector2D.isvector(a) and type(b) == 'number', "Wrong argument types <Vector2D, number> expected. [Div]" )
    assert(b ~= 0, "Division by 0 is undefined. [Div]")
    Vector2D a.x/b, a.y/b

  __eq: (a, b) ->
    a.x == b.x and a.y == b.y
    
  __lt: (a, b) ->
    a.x < b.x or (a.x == b.x and a.y < b.y)

  __le: (a, b) ->
    a.x <= b.x and a.y <= b.y

  __unm: (a) ->
    Vector2D -a.x, -a.y

  len: =>
    sqrt(@x * @x + @y * @y) 

  len2: =>
    @x * @x + @y * @y

  magnitude: =>
    @len!

  overwrite: (v) =>
    assert( Vector2D.isvector(v), "Wrong argument types <Vector2D> expected. [Overwrite]" )
    @x = v.x
    @y = v.y

  normalize: =>
    mag = @magnitude!
    if mag ~= 0
      @overwrite self / mag

  norm: =>
    mag = @magnitude!
    if mag ~= 0
      return self / mag

  clamp: (Min, Max) =>
    assert( Vector2D.isvector(Min) and Vector2D.isvector(Max), "Wrong argument types <Vector2D> expected. [Clamp]" )
    @x = min(max(@x, Min.x), Max.x)
    @y = min(max(@y, Min.y), Max.y)

  clampX: (Min, Max) =>
    assert( Vector2D.isvector(Min) and Vector2D.isvector(Max), "Wrong argument types <Vector2D> expected. [clampX]" )
    @x = min(max(@x, Min.x), Max.x)

  clampY: (Min, Max) =>
    assert( Vector2D.isvector(Min) and Vector2D.isvector(Max), "Wrong argument types <Vector2D> expected. [clampY]" )
    @y = min(max(@y, Min.y), Max.y)

  parmul: (a, b) =>
    assert( Vector2D.isvector(a) and Vector2D.isvector(b), "Wrong argument types <Vector2D> expected. [Parmul]" )
    Vector2D a.x*b.x, a.y*b.y

  toPolar: =>
    Vector2D atan2(@x, @y), @len!

  dist: (a, b) =>
    assert( Vector2D.isvector(a) and Vector2D.isvector(b), "Wrong argument types <Vector2D> expected. [Dist]" )
    dx = a.x - b.x
    dy = a.y - b.y
    sqrt(dx*dx + dy*dy)

  dist2: (a, b) =>
    assert( Vector2D.isvector(a) and Vector2D.isvector(b), "Wrong argument types <Vector2D> expected. [Dist2]" )
    dx = a.x - b.x
    dy = a.y - b.y
    dx*dx + dy*dy
  
  rotate: (phi) =>
    c, s = cos(phi), sin(phi)
    @x, @y = c * @x - s * @y, s * @x + c * @y
    self

  rot: (phi) =>
    c, s = cos(phi), sin(phi)
    Vector2D c * @x - s * @y, s * @x + c * @y

  perpendicular: =>
    Vector2D -@y, @x

  projectOn: (v) =>
    assert( Vector2D.isvector(v), "Wrong argument types <Vector2D> expected. [ProjectOn]" )
    s = (@x * v.x + @y * v.y) / (v.x * v.x + v.y * v.y)
    Vector2D s * v.x - @x, s * v.y - @y

  mirrorOn: (v) =>
    assert( Vector2D.isvector(v), "Wrong argument types <Vector2D> expected. [MirrorOn]" )
    s = 2 * (@x * v.x + @y * v.y) / (v.x * v.x + v.y * v.y)
    Vector2D s * v.x - @x, s * v.y - @y

  cross: (v) =>
    assert( Vector2D.isvector(v), "Wrong argument types <Vector2D> expected. [Cross]" )
    @x * v.y - @y * v.x -- parallelogram_area

  heading: =>
    -atan2 @y, @x

  -- t: theta
  @fromAngle: (t) ->
    Vector2D cos(t), -sin(t)

  @random: =>
    t = rand! * pi * 2
    Vector2D.fromAngle t

Vector2D
