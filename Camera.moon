Shake = assert require "Shake"


-- Utils
csnap = (v, x) -> math.ceil(v/x) * x - x/2
lerp = (a, b, x) -> a + (b - a) * x

class Camera
  new: (l, t, w, h, scale = 1, rot = 0) =>
    Graphics = love.graphics
    windowW, windowH = Graphics.getWidth!, Graphics.getHeight!

    @x = 0
    @y = 0
    @scale = scale -- Default : 1
    @rot = rot

    -- Dead zone
    @deadzone = nil

    -- Screen by Screen
    @screenX  = l or (w or Graphics.getWidth!)/2
    @screenY  = t or (h or Graphics.getHeight!)/2

    -- Following a target
    @targetX = nil
    @targetY = nil
    @scrollX = 0
    @scrollY = 0
    @lastTargetX = nil
    @lastTargetY = nil

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
    @lastHoriShakeAmount = 0
    @lastVertiShakeAmount = 0
      -- fade
    @fadeDur = 1
    @fadeTimer = 1
    @fadeColor = {0, 0, 0, 0}



-- return
Camera
