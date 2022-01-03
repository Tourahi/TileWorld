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











-- Utils
csnap = (v, x) -> math.ceil(v/x) * x - x/2
lerp = (a, b, x) -> a + (b - a) * x



--lerp
