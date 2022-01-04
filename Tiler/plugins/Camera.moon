Shake = assert require "Shake"


-- Utils
csnap = (v, x) -> math.ceil(v/x) * x - x/2
lerp = (a, b, x) -> a + (b - a) * x

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
    @lastTargetY = nil
    @followLerpX = 1
    @followLerpY = 1
    @followLeadX = 0
    @followLeadY = 0
    @followStyle = nil
    @deadzone = nil
    @deadzoneX = 0
    @deadzoneY = 0
    @deadzoneW = 0
    @deadzoneH = 0
    @bound = nil
    @boundsMinX = 0
    @boundsMinY = 0
    @boundsMaxX = 0
    @boundsMaxY = 0
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
    if @followStyle == 'LOCKON'
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
      if @bound
        @x = math.min(math.max(@x, @boundsMinX + @w/2), @boundsMaxX - @w/2)
        @y = math.min(math.max(@y, @boundsMinY + @h/2), @boundsMaxY - @h/2)
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

      @x = lerp @x, @screenX, @followLerpX
      @y = lerp @y, @screenY, @followLerpY

      if @bound
        @x = math.min(math.max(@x, @boundsMinX + @w/2), @boundsMaxX - @w/2)
        @y = math.min(math.max(@y, @boundsMinY + @h/2), @boundsMaxY - @h/2)
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

      if @bound
        @x = math.min(math.max(@x, @boundsMinX + @w/2), @boundsMaxX - @w/2)
        @y = math.min(math.max(@y, @boundsMinY + @h/2), @boundsMaxY - @h/2)


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


  follow: (x, y) =>
    @targetX, @targetY = x, y

  setBounds: (x, y, w, h) =>
    @bound = true
    @boundsMinX = x
    @boundsMinY = y
    @boundsMaxX = x + w
    @boundsMaxY = y + h

  setFollowStyle: (fs) =>
    @followStyle = fs

  setFollowLerp: (x, y) =>
    @followLerpX = x
    @followLerpY = y or x

  setFollowLead: (x, y) =>
    @followLeadX = x
    @followLeadY = y or x

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




-- return
Camera
