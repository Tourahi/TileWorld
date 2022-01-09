-- Utils
csnap = (v, x) -> math.ceil(v/x) * x - x/2
lerp = (a, b, x) -> a + (b - a) * x
clamp = (x, minX, maxX) -> x < minX and minX or (x>maxX and maxX or x)

class Camera
  new: (l, t, w, h, scale, rot, mapW, mapH) =>
    Graphics = love.graphics
    windowW, windowH = Graphics.getWidth!, Graphics.getHeight!
    @x = w or Graphics.getWidth! / 2

    @mapW = mapW
    @mapH = mapH

    @y = h or Graphics.getHeight! / 2
    @mx = @x
    @my = @y
    @screenX = @x
    @screenY = @y
    @w = w or Graphics.getWidth!
    @h = h or Graphics.getHeight!
    @l = l or 0
    @t = t or 0
    @scale = scale or 1
    @rot = rot or 0
    @horiShakes = {}
    @vertiShakes = {}
    @targetX = nil
    @targetY = nil
    @scrollX = 0
    @scrollY = 0
    @lastTargetX = nil
    @lastTargetY = nil
    @followLerpX = 1
    @followLerpY = 1
    @followLeadX = 0
    @followLeadY = 0
    @followStyle = nil
    @sin = math.sin 0
    @cos = math.cos 0

    @setWorld @l, @t, @w, @h

    @deadzone = nil
    @deadzoneX = 0
    @deadzoneY = 0
    @deadzoneW = 0
    @deadzoneH = 0
    @drawDeadzone = false
    @flashDuration = 1
    @flashTimer = 0
    @flashColor = {0, 0, 0, 1}
    @flashing = false
    @lastHoriShakeAmount = 0
    @lastVertiShakeAmount = 0
    @fadeDur = 1
    @fadeTimer = 1
    @fadeColor = {0, 0, 0, 0}
    @baseFadeColor = {0, 0, 0, 1}
    @targetFadeColor = {0, 0, 0, 1}
    @fadeAction = nil
    @fading = false

    @canvas = Graphics.newCanvas @w, @h
    @canvas\setFilter "nearest", "nearest"


  getVisibleArea: (scale) =>
    min, abs = math.min, math.abs
    scale = scale or @scale
    sin, cos = abs(@sin), abs(@cos)
    w, h = @w / scale, @h / scale
    w, h = cos*w + sin*h, sin*w + cos*h
    min(w, @worldW), min(h, @worldH)

  setWorld: (l,t,w,h) =>
    @worldL, @worldT, @worldW, @worldH = l,t,(w - (w - @mapW)) - l,(h - (h - @mapH)) - t
    @adjustPosition!

  adjustPosition: =>
    worldL, worldT, worldW, worldH = @worldL, @worldT, @worldW, @worldH
    w, h = @getVisibleArea!
    wc, hc = w*0.5, h*0.5


    left, right  = worldL + wc, worldL + worldW - wc
    top,  bottom = worldT + hc, worldT + worldH - hc

    @x, @y = clamp(@x, left, right), clamp(@y, top, bottom)


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

  shake: (intensity, dur, freq, axes = 'XY') =>
    axes = string.upper axes
    if string.find(axes, 'X')
      table.insert @horiShakes, Shake(intensity, freq,dur * 1000)
    if string.find(axes, 'X')
      table.insert @vertiShakes, Shake(intensity, freq,dur * 1000)

  setDeadzone: (x, y, w, h) =>
    @deadzone = true
    @deadzoneX = x
    @deadzoneY = y
    @deadzoneW = w
    @deadzoneH = h

  update: (dt) =>
    @mx, @my = @getMousePosition!
    -- Flash
    if @flashing
      @flashTimer = @flashTimer + dt
      if @flashTimer > @flashDuration
        @flashTimer = 0
        @flashing = false
    -- Fade
    if @fading
      @fadeTimer = @fadeTimer + dt
      @fadeColor = {
        lerp(@baseFadeColor[1], @targetFadeColor[1], @fadeTimer/@fadeDur),
        lerp(@baseFadeColor[2], @targetFadeColor[2], @fadeTimer/@fadeDur),
        lerp(@baseFadeColor[3], @targetFadeColor[3], @fadeTimer/@fadeDur),
        lerp(@baseFadeColor[4], @targetFadeColor[4], @fadeTimer/@fadeDur),
      }
      if @fadeTimer > @fadeDur
        @fadeTimer = 0
        @fading = false
        if @fadeAction then @fadeAction!

    -- Shake Horizontal
    horiShakeAmount, vertiShakeAmount = 0, 0
    for i = #@horiShakes, 1, -1 do
      @horiShakes[i]\update dt
      horiShakeAmount += @horiShakes[i]\getAmplitude!
      if not @horiShakes[i]\isShaking! then table.remove(@horiShakes, i)
    -- Shake Vertical
    for i = #@vertiShakes, 1, -1 do
      @vertiShakes[i]\update dt
      vertiShakeAmount += @vertiShakes[i]\getAmplitude!
      if not @vertiShakes[i]\isShaking! then table.remove(@vertiShakes, i)
    @x, @y = @x - @lastHoriShakeAmount, @y - @lastVertiShakeAmount
    @move horiShakeAmount, vertiShakeAmount
    @lastHoriShakeAmount, @lastVertiShakeAmount = horiShakeAmount, vertiShakeAmount

    -- Follow
    if not @targetX and not @targetY then return
    -- Set follow Style
    if @followStyle == 'LOCKED'
      w, h = @w/16, @w/16
      @setDeadzone (@w - w)/2, (@h - h)/2, w, h
    elseif @followStyle == 'PLATFORMER'
      w, h = @w/8, @w/3
      @setDeadzone (@w - w)/2, (@h - h)/2 - h*0.25, w, h
    elseif @followStyle == 'TOPDOWN'
      s = math.max(@w, @h)/4
      @setDeadzone (@w - s)/2, (@h - s)/2, s, s
    elseif @followStyle == 'TOPDOWN_TIGHT'
      s = math.max(@w, @h)/8
      @setDeadzone (@w - s)/2, (@h - s)/2, s, s
    elseif @followStyle == 'SCREEN_BY_SCREEN'
      @setDeadzone 0, 0, 0, 0
    elseif @followStyle == 'NO_DEADZONE'
      @deadzone = nil

    if not @deadzone
      @x, @y = @targetX, @targetY

      @adjustPosition!
      return

    dx1, dy1, dx2, dy2 = @deadzoneX, @deadzoneY, @deadzoneX + @deadzoneW, @deadzoneY + @deadzoneH
    scrollX, scrollY = 0, 0
    targetX, targetY = @toCameraCoords @targetX, @targetY
    x, y = @toCameraCoords @x, @y

    if @followStyle == 'SCREEN_BY_SCREEN'
      if @bound
        if @x > @boundsMinX + @w/2 and targetX < 0
          @screenX = csnap(@screenX - @w/@scale, @w/@scale)
        if @x < @boundsMaxX - @w/2 and targetX >= @w
          @screenX = csnap(@screenX + @w/@scale, @w/@scale)
        if @y > @boundsMinY + @h/2 and targetY < 0
          @screenY = csnap(@screenY - @h/@scale, @h/@scale)
        if @y < @boundsMaxY - @h/2 and targetY >= @h
          @screenY = csnap(@screenY + @h/@scale, @h/@scale)
      else
        if targetX < 0
          @screenX = csnap(@screenX - @w/@scale, @w/@scale)
        if targetX >= @w
          @screenX = csnap(@screenX + @w/@scale, @w/@scale)
        if targetY < 0
          @screenY = csnap(@screenY - @h/@scale, @h/@scale)
        if targetY >= @h
          @screenY = csnap(@screenY + @h/@scale, @h/@scale)

      @screenX = clamp @screenX, (@w/@scale) / 2, @w
      @screenY = clamp @screenY, (@h/@scale) / 2, @h

      @x = lerp @x, @screenX, @followLerpX
      @y = lerp @y, @screenY, @followLerpY

      @adjustPosition!


    else
      if targetX < x + (dx1 + dx2 - x)
        d = targetX - dx1
        if d < 0 then scrollX = d
      if targetX > x - (dx1 + dx2 - x)
        d = targetX - dx2
        if d > 0 then scrollX = d
      if targetY < y + (dy1 + dy2 - y)
        d = targetY - dy1
        if d < 0 then scrollY = d
      if targetY > y - (dy1 + dy2 - y)
        d = targetY - dy2
        if d > 0 then scrollY = d

      if not @lastTargetX and not @lastTargetY
        @lastTargetX, @lastTargetY = @targetX, @targetY

      scrollX += (@targetX - @lastTargetX) * @followLeadX
      scrollY += (@targetY - @lastTargetY) * @followLeadY

      @lastTargetX, @lastTargetY = @targetX, @targetY
      @x = lerp(@x, @x + scrollX, @followLerpX)
      @y = lerp(@y, @y + scrollY, @followLerpY)

      @adjustPosition!


  draw: =>
    Graphics = love.graphics

    if @drawDeadzone and @deadzone
      n = Graphics.getLineWidth!
      Graphics.setLineWidth 4
      Graphics.line @deadzoneX - 1, @deadzoneY, @deadzoneX + 6, @deadzoneY
      Graphics.line @deadzoneX, @deadzoneY, @deadzoneX, @deadzoneY + 6
      Graphics.line @deadzoneX - 1, @deadzoneY + @deadzoneH, @deadzoneX + 6, @deadzoneY + @deadzoneH
      Graphics.line @deadzoneX, @deadzoneY + @deadzoneH, @deadzoneX, @deadzoneY + @deadzoneH - 6
      Graphics.line @deadzoneX + @deadzoneW + 1, @deadzoneY + @deadzoneH, @deadzoneX + @deadzoneW - 6, @deadzoneY + @deadzoneH
      Graphics.line @deadzoneX + @deadzoneW, @deadzoneY + @deadzoneH, @deadzoneX + @deadzoneW, @deadzoneY + @deadzoneH - 6
      Graphics.line @deadzoneX + @deadzoneW + 1, @deadzoneY, @deadzoneX + @deadzoneW - 6, @deadzoneY
      Graphics.line @deadzoneX + @deadzoneW, @deadzoneY, @deadzoneX + @deadzoneW, @deadzoneY + 6
      Graphics.setLineWidth n

    if @flashing
      r, g, b, a = Graphics.getColor!
      Graphics.setColor @flashColor
      Graphics.rectangle 'fill', 0, 0, @w, @h
      Graphics.setColor r, g, b, a

    r, g, b, a = Graphics.getColor!
    Graphics.setColor @fadeColor
    Graphics.rectangle 'fill', 0, 0, @w, @h
    Graphics.setColor r, g, b, a


  follow: (x, y) =>
    @targetX, @targetY = x, y


  -- map: Tiled map
  setBounds: (mapL, mapT, mapW, mapH)=>
    @worldL, @worldT, @worldW, @worldH = mapL, mapT, mapW, mapH


  cornerTransform: (x, y) =>
    scale, sin, cos = @scale, @sin, @cos
    x,y = x - @x, y - @y
    x,y = -cos*x + sin*y, -sin*x - cos*y
    @x - (x/scale + @l), @y - (y/scale + @t)

  getVisibleCorners: =>
    x,y,w2,h2 = @x, @y, @w2, @h2

    x1,y1 = @cornerTransform x-w2,y-h2
    x2,y2 = @cornerTransform x+w2,y-h2
    x3,y3 = @cornerTransform x+w2,y+h2
    x4,y4 = @cornerTransform x-w2,y+h2

    x1,y1,x2,y2,x3,y3,x4,y4

  setFollowStyle: (fs) =>
    @followStyle = fs

  setFollowLerp: (x, y) =>
    @followLerpX = x
    @followLerpY = y or x

  setFollowLead: (x, y) =>
    @followLeadX = x
    @followLeadY = y or x

  adjustScale: =>
    worldW, worldH = @worldW, @worldH
    rw, rh = @getVisibleArea 1

    sx, sy = rw/worldW, rh/worldH
    rscale = math.max sx, sy
    @scale = math.max @scale, rscale


  setAngle: (angle) =>
    @rot = angle
    @cos, @sin = math.cos(angle), math.sin(angle)
    @adjustScale!
    @adjustPosition!

  flash: (dur, color) =>
    @flashDuration = dur
    @flashColor = color or @flashColor
    @flashTimer = 0
    @flashing = true

  fade: (dur, color, action) =>
    @fadeDur = dur
    @baseFadeColor = @fadeColor
    @targetFadeColor = color
    @fadeTimer = 0
    @fadeAction = action
    @fading = true

  setScale: (s) =>
    @scale = s

  getWindow: =>
    @l, @t, @w, @h

  getVisible: =>
    w,h = @getVisibleArea!
    @x - w*0.5, @y - h*0.5, w, h


  attachC: (canvas = @canvas, callback) =>
    Graphics = love.graphics
    _canvas = Graphics.getCanvas!
    sx, sy, sw, sh = Graphics.getScissor!
    Graphics.setScissor @getWindow!


    Graphics.setCanvas canvas
    Graphics.clear!

    Graphics.push!
    Graphics.origin!
    Graphics.translate math.floor(@w/2 or 0), math.floor(@h/2 or 0)
    Graphics.scale @scale
    Graphics.rotate @rot
    Graphics.translate -@x, -@y


    if callback
      callback!

    Graphics.pop!

    Graphics.push!
    Graphics.origin!

    Graphics.setCanvas _canvas
    Graphics.draw canvas

    Graphics.pop!

    Graphics.setScissor sx, sy, sw, sh
