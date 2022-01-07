Shake = assert require "Shake"


-- Utils
csnap = (v, x) -> math.ceil(v/x) * x - x/2
lerp = (a, b, x) -> a + (b - a) * x
clamp = (x, minX, maxX) -> x < minX and minX or (x>maxX and maxX or x)

assertNum = (val, name) ->
  if type(val) ~= 'number'
    error name .. " must be a number (was: " .. tostring(val) .. ")"

assertPosNum = (val, name) ->
  if type(val) ~= 'number' or val <=0
    error name .. " must be a positive number (was: " .. tostring(val) ..")"

checkAABB = (l,t,w,h) ->
  assertNum l, "l"
  assertNum t, "t"
  assertPosNum w, "w"
  assertPosNum h, "h"

class Camera
  new: (l, t, w, h, scale = 1, angle = 0) =>
    Graphics = love.graphics
    windowW, windowH = Graphics.getWidth!, Graphics.getHeight!

    @x = 0
    @y = 0
    @l = 0
    @t = 0
    @w = windowW
    @h = windowH
    @wc = windowW * 0.5
    @hc = windowH * 0.5
    @scale = scale -- Default : 1
    @angle = angle
    @sin = math.sin 0
    @cos = math.cos 0

    -- Following a target
    @targetX = nil
    @targetY = nil
    @scrollX = 0
    @scrollY = 0
    @lastTargetX = nil
    @lastTargetY = nil

    @setWorld l, t, w, h

    -- Dead zone
    @deadzone = nil

    -- Screen by Screen
    @screenX  = l or (w or Graphics.getWidth!)/2
    @screenY  = t or (h or Graphics.getHeight!)/2



    -- Effects
      -- lerp
    @followLerpX = 1
    @followLerpY = 1
      -- lead
    @followLeadX = 0
    @followLeadY = 0
      -- flash
    @flashDuration = 1
    @flashTimer = 0
    @flashColor = {0, 0, 0, 1}
    @flashing = false
      -- shake
    @horiShakes = {}
    @vertiShakes = {}
    @lastHoriShakeAmount = 0
    @lastVertiShakeAmount = 0
      -- fade
    @fadeDur = 1
    @fadeTimer = 1
    @fadeColor = {0, 0, 0, 0}

  getVisibleArea: (scale) =>
    min, abs = math.min, math.abs
    scale = scale or @scale
    sin, cos = abs(@sin), abs(@cos)
    w, h = @w / scale, @h / scale
    w, h = cos*w + sin*h, sin*w + cos*h
    min(w, @worldW), min(h, @worldH)

  adjustPosition: =>
    worldL, worldT, worldW, worldH = @worldL, @worldT, @worldW, @worldH
    w, h = @getVisibleArea!
    wc, hc = w*0.5, h*0.5

    left, right  = worldL + wc, worldL + worldW - wc
    top,  bottom = worldT + hc, worldT + worldH - hc

    @scrollX, @scrollY = clamp(@scrollX, left, right), clamp(@scrollY, top, bottom)


  setWorld: (l,t,w,h) =>
    checkAABB l,t,w,h
    @worldL, @worldT, @worldW, @worldH = l,t,w,h
    @adjustPosition!

  setWindow: (l,t,w,h) =>
    checkAABB l,t,w,h
    @l, @t, @w, @h, @wc, @hc = l,t,w,h, w*0.5, h*0.5
    @adjustPosition!

  getVisible: =>
    w, h = @getVisibleArea!
    @x - w*0.5, @y - h*0.5, w, h

  follow: (x, y) =>
    assertNum x, "x"
    assertNum y, "x"

    @scrollX, @scrollY = x, y
    @adjustPosition!

  adjustScale: =>
    max = math.max
    worldW, worldH = @worldW, @worldH
    rw, rh = @getVisibleArea 1

    sx, sy = rw/worldW, rh/worldH
    rscale = max sx, sy

    @scale = max @scale, rscale

  setScale: (scale) =>
    assertNum scale, "scale"
    @scale = scale

    @adjustScale!
    @adjustPosition!

  toWorldCoords: (x, y) =>
    c, s = math.cos(@angle), math.sin(@angle)
    x, y = (x - @w/2)/@scale, (y - @h/2)/@scale
    x, y = c*x - s*y, s*x + c*y
    x + @scrollX, y + @scrollY

  getMousePosition: =>
    m = love.mouse
    @toWorldCoords m.getPosition!

  move: (dx, dy) =>
    @scrollX, @scrollY = @scrollX + dx, @scrollY + dy

  shake: (intensity, dur, freq, axes = 'XY') =>
    axes = string.upper axes

    if string.find(axes, 'X')
      table.insert @horiShakes, Shake(intensity, freq,dur * 1000)
    if string.find(axes, 'X')
      table.insert @vertiShakes, Shake(intensity, freq,dur * 1000)

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

    @scrollX, @scrollY = @scrollX - @lastHoriShakeAmount, @scrollY - @lastVertiShakeAmount
    @move horiShakeAmount, vertiShakeAmount
    @lastHoriShakeAmount, @lastVertiShakeAmount = horiShakeAmount, vertiShakeAmount

    if @deadzone == nil
      @x, @y = @scrollX, @scrollY


  setDeadzone: (x, y, w, h) =>
      @deadzone = true
      @deadzoneX = x
      @deadzoneY = y
      @deadzoneW = w
      @deadzoneH = h

  attach: (f) =>
    clip = nil
    Graphics = love.graphics
    sx, sy, sw, sh = Graphics.getScissor!


    if clip then Graphics.setScissor @x, @y, @w, @h


    Graphics.push!
    scale = @scale
    Graphics.scale scale
    -- print @wc, @l, scale,@hc, @t
    Graphics.translate((@wc + @l) / scale, (@hc+@t) / scale)
    Graphics.rotate -@angle
    Graphics.translate -@x, -@y

    f @getVisible!

    Graphics.pop!

    if clip then Graphics.setScissor sx, sy, sw, sh

  flash: (dur, color) =>
    @flashDuration = dur
    @flashColor = color or @flashColor
    @flashTimer = 0
    @flashing = true

  draw: =>
    Graphics = love.graphics
    if @drawDeadzone and @deadzone
      n = Graphics.getLineWidth!
      Graphics.setLineWidth 2
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

-- return
Camera
