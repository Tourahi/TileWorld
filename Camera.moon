Shake = assert require "Shake"


class Camera
  new: (x, y, w, h, scale, rot) =>
    Graphics = love.graphics
    @x = x or (w or Graphics.getWidth! / 2)
    @y = x or (h or Graphics.getHeight! / 2)
    @mx = @x
    @my = @y
    @screenX = @x
    @screenY = @y
    @w = w or Graphics.getWidth!
    @h = h or Graphics.getHeight!
    @scale = scale or 1
    @rot = rot or 0
    @horiShakes = {}
    @vertiShakes = {}
    @targetX = nil
    @targetY = nil
    @scrollX = 0
    @scrollY = 0
    @lastTargetX = nil
    @lastTargetX = nil
    @followLerpX = 1
    @followLerpY = 1
    @followLeadX = 0
    @followLeadY = 0
    @deadZone = nil
    @bound = nil
    @drawDeadZone = false
    @flashDuration = 1
    @flashTimer = 0
    @flashColor = {0, 0, 0, 1}
    @lastHoriShakeAmount = 0
    @lastVertiShakeAmount = 0
    @fadeDur = 1
    @fadeTimer = 1
    @fadeColor = {0, 0, 0, 0}


  attach: =>
    Graphics = love.graphics
    Graphics.push!
    Graphics.translate @w/2, @h/2
    Graphics.scale @scale
    Graphics.rotate @rot
    Graphics.translate -@x, -@y

  detach: =>
    Graphics = love.graphics
    Graphics.pop!

  move: (dx, dy) =>
    @x, @y = @x + dx, @y + dy

  toWorldCoords: (x, y) =>
    c, s = math.cos(@rot), math.sin(@rot)
    x, y = (x - @w/2)/@scale, (y - @h/2)/@scale
    x, y = c*x - s*y, s*x + c*y
    x + @x, y + @y

  toCameraCoords: (x, y) =>
    c, s = math.cos(@rot), math.sin(@rot)
    x, y = x - @x, y - @y
    x, y = c*x - s*y, s*x + c*y
    x * @scale + @w/2, y * @scale + @h/2

  getMousePosition: =>
    m = love.mouse
    @toWorldCoords m.getPosition!

  shake: (intensity, dur, freq, axes) =>
    if not axes then axes = 'XY'
    axes = string.upper axes

    if string.find(axes, 'X')
      table.insert @horiShakes, Shake(intensity, freq,dur * 1000)
    if string.find(axes, 'X')
      table.insert @vertiShakes, Shake(intensity, freq,dur * 1000)

  update: (dt) =>









-- Utils
csnap = (v, x) -> math.ceil(v/x) * x - x/2
lerp = (a, b, x) -> a + (b - a) * x



--lerp
