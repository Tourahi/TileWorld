local Shake = assert(require("Shake"))
local csnap
csnap = function(v, x)
  return math.ceil(v / x) * x - x / 2
end
local lerp
lerp = function(a, b, x)
  return a + (b - a) * x
end
local Camera
do
  local _class_0
  local _base_0 = {
    attach = function(self)
      local Graphics = love.graphics
      Graphics.push()
      Graphics.translate(self.w / 2, self.h / 2)
      Graphics.scale(self.scale)
      Graphics.rotate(self.rot)
      return Graphics.translate(-self.x, -self.y)
    end,
    detach = function(self)
      local Graphics = love.graphics
      return Graphics.pop()
    end,
    move = function(self, dx, dy)
      self.x, self.y = self.x + dx, self.y + dy
    end,
    toWorldCoords = function(self, x, y)
      local c, s = math.cos(self.rot), math.sin(self.rot)
      x, y = (x - self.w / 2) / self.scale, (y - self.h / 2) / self.scale
      x, y = c * x - s * y, s * x + c * y
      return x + self.x, y + self.y
    end,
    toCameraCoords = function(self, x, y)
      local c, s = math.cos(self.rot), math.sin(self.rot)
      x, y = x - self.x, y - self.y
      x, y = c * x - s * y, s * x + c * y
      return x * self.scale + self.w / 2, y * self.scale + self.h / 2
    end,
    getMousePosition = function(self)
      local m = love.mouse
      return self:toWorldCoords(m.getPosition())
    end,
    shake = function(self, intensity, dur, freq, axes)
      if axes == nil then
        axes = 'XY'
      end
      axes = string.upper(axes)
      if string.find(axes, 'X') then
        table.insert(self.horiShakes, Shake(intensity, freq, dur * 1000))
      end
      if string.find(axes, 'X') then
        return table.insert(self.vertiShakes, Shake(intensity, freq, dur * 1000))
      end
    end,
    setDeadzone = function(self, x, y, w, h)
      self.deadzone = true
      self.deadzoneX = x
      self.deadzoneY = y
      self.deadzoneW = w
      self.deadzoneH = h
    end,
    update = function(self, dt)
      self.mx, self.my = self:getMousePosition()
      if self.flashing then
        self.flashTimer = self.flashTimer + dt
        if self.flashTimer > self.flashDuration then
          self.flashTimer = 0
          self.flashing = false
        end
      end
      if self.fading then
        self.fadeTimer = self.fadeTimer + dt
        self.fadeColor = {
          lerp(self.baseFadeColor[1], self.targetFadeColor[1], self.fadeTimer / self.fadeDur),
          lerp(self.baseFadeColor[2], self.targetFadeColor[2], self.fadeTimer / self.fadeDur),
          lerp(self.baseFadeColor[3], self.targetFadeColor[3], self.fadeTimer / self.fadeDur),
          lerp(self.baseFadeColor[4], self.targetFadeColor[4], self.fadeTimer / self.fadeDur)
        }
        if self.fadeTimer > self.fadeDur then
          self.fadeTimer = 0
          self.fading = false
          if self.fadeAction then
            self:fadeAction()
          end
        end
      end
      local horiShakeAmount, vertiShakeAmount = 0, 0
      for i = #self.horiShakes, 1, -1 do
        self.horiShakes[i]:update(dt)
        horiShakeAmount = horiShakeAmount + self.horiShakes[i]:getAmplitude()
        if not self.horiShakes[i]:isShaking() then
          table.remove(self.horiShakes, i)
        end
      end
      for i = #self.vertiShakes, 1, -1 do
        self.vertiShakes[i]:update(dt)
        vertiShakeAmount = vertiShakeAmount + self.vertiShakes[i]:getAmplitude()
        if not self.vertiShakes[i]:isShaking() then
          table.remove(self.vertiShakes, i)
        end
      end
      self.x, self.y = self.x - self.lastHoriShakeAmount, self.y - self.lastVertiShakeAmount
      self:move(horiShakeAmount, vertiShakeAmount)
      self.lastHoriShakeAmount, self.lastVertiShakeAmount = horiShakeAmount, vertiShakeAmount
      if not self.targetX and not self.targetY then
        return 
      end
      if self.followStyle == 'LOCKON' then
        local w, h = self.w / 16, self.w / 16
        self:setDeadzone((self.w - w) / 2, (self.h - h) / 2, w, h)
      elseif self.followStyle == 'PLATFORMER' then
        local w, h = self.w / 8, self.w / 3
        self:setDeadzone((self.w - w) / 2, (self.h - h) / 2 - h * 0.25, w, h)
      elseif self.followStyle == 'TOPDOWN' then
        local s = math.max(self.w, self.h) / 4
        self:setDeadzone((self.w - s) / 2, (self.h - s) / 2, s, s)
      elseif self.followStyle == 'TOPDOWN_TIGHT' then
        local s = math.max(self.w, self.h) / 8
        self:setDeadzone((self.w - s) / 2, (self.h - s) / 2, s, s)
      elseif self.followStyle == 'SCREEN_BY_SCREEN' then
        self:setDeadzone(0, 0, 0, 0)
      elseif self.followStyle == 'NO_DEADZONE' then
        self.deadzone = nil
      end
      if not self.deadzone then
        self.x, self.y = self.targetX, self.targetY
        if self.bound then
          self.x = math.min(math.max(self.x, self.boundsMinX + self.w / 2), self.boundsMaxX - self.w / 2)
          self.y = math.min(math.max(self.y, self.boundsMinY + self.h / 2), self.boundsMaxY - self.h / 2)
        end
        return 
      end
      local dx1, dy1, dx2, dy2 = self.deadzoneX, self.deadzoneY, self.deadzoneX + self.deadzoneW, self.deadzoneY + self.deadzoneH
      local scrollX, scrollY = 0, 0
      local targetX, targetY = self:toCameraCoords(self.targetX, self.targetY)
      local x, y = self:toCameraCoords(self.x, self.y)
      if self.followStyle == 'SCREEN_BY_SCREEN' then
        if self.bound then
          if self.x > self.boundsMinX + self.w / 2 and targetX < 0 then
            self.screenX = csnap(self.screenX - self.w / self.scale, self.w / self.scale)
          end
          if self.x < self.boundsMaxX - self.w / 2 and targetX >= self.w then
            self.screenX = csnap(self.screenX + self.w / self.scale, self.w / self.scale)
          end
          if self.y > self.boundsMinY + self.h / 2 and targetY < 0 then
            self.screenY = csnap(self.screenY - self.h / self.scale, self.h / self.scale)
          end
          if self.y < self.boundsMaxY - self.h / 2 and targetY >= self.h then
            self.screenY = csnap(self.screenY + self.h / self.scale, self.h / self.scale)
          end
        else
          if targetX < 0 then
            self.screenX = csnap(self.screenX - self.w / self.scale, self.w / self.scale)
          end
          if targetX >= self.w then
            self.screenX = csnap(self.screenX + self.w / self.scale, self.w / self.scale)
          end
          if targetY < 0 then
            self.screenY = csnap(self.screenY - self.h / self.scale, self.h / self.scale)
          end
          if targetY >= self.h then
            self.screenY = csnap(self.screenY + self.h / self.scale, self.h / self.scale)
          end
        end
        self.x = lerp(self.x, self.screenX, self.followLerpX)
        self.y = lerp(self.y, self.screenY, self.followLerpY)
        if self.bound then
          self.x = math.min(math.max(self.x, self.boundsMinX + self.w / 2), self.boundsMaxX - self.w / 2)
          self.y = math.min(math.max(self.y, self.boundsMinY + self.h / 2), self.boundsMaxY - self.h / 2)
        end
      else
        if targetX < x + (dx1 + dx2 - x) then
          local d = targetX - dx1
          if d < 0 then
            scrollX = d
          end
        end
        if targetX > x - (dx1 + dx2 - x) then
          local d = targetX - dx2
          if d > 0 then
            scrollX = d
          end
        end
        if targetY < y + (dy1 + dy2 - y) then
          local d = targetY - dy1
          if d < 0 then
            scrollY = d
          end
        end
        if targetY > y - (dy1 + dy2 - y) then
          local d = targetY - dy2
          if d > 0 then
            scrollY = d
          end
        end
        if not self.lastTargetX and not self.lastTargetY then
          self.lastTargetX, self.lastTargetY = self.targetX, self.targetY
        end
        scrollX = scrollX + ((self.targetX - self.lastTargetX) * self.followLeadX)
        scrollY = scrollY + ((self.targetY - self.lastTargetY) * self.followLeadY)
        self.lastTargetX, self.lastTargetY = self.targetX, self.targetY
        self.x = lerp(self.x, self.x + scrollX, self.followLerpX)
        self.y = lerp(self.y, self.y + scrollY, self.followLerpY)
        if self.bound then
          self.x = math.min(math.max(self.x, self.boundsMinX + self.w / 2), self.boundsMaxX - self.w / 2)
          self.y = math.min(math.max(self.y, self.boundsMinY + self.h / 2), self.boundsMaxY - self.h / 2)
        end
      end
    end,
    draw = function(self)
      local Graphics = love.graphics
      if self.drawDeadzone and self.deadzone then
        local n = Graphics.getLineWidth()
        Graphics.setLineWidth(2)
        Graphics.line(self.deadzoneX - 1, self.deadzoneY, self.deadzoneX + 6, self.deadzoneY)
        Graphics.line(self.deadzoneX, self.deadzoneY, self.deadzoneX, self.deadzoneY + 6)
        Graphics.line(self.deadzoneX - 1, self.deadzoneY + self.deadzoneH, self.deadzoneX + 6, self.deadzoneY + self.deadzoneH)
        Graphics.line(self.deadzoneX, self.deadzoneY + self.deadzoneH, self.deadzoneX, self.deadzoneY + self.deadzoneH - 6)
        Graphics.line(self.deadzoneX + self.deadzoneW + 1, self.deadzoneY + self.deadzoneH, self.deadzoneX + self.deadzoneW - 6, self.deadzoneY + self.deadzoneH)
        Graphics.line(self.deadzoneX + self.deadzoneW, self.deadzoneY + self.deadzoneH, self.deadzoneX + self.deadzoneW, self.deadzoneY + self.deadzoneH - 6)
        Graphics.line(self.deadzoneX + self.deadzoneW + 1, self.deadzoneY, self.deadzoneX + self.deadzoneW - 6, self.deadzoneY)
        Graphics.line(self.deadzoneX + self.deadzoneW, self.deadzoneY, self.deadzoneX + self.deadzoneW, self.deadzoneY + 6)
        Graphics.setLineWidth(n)
      end
      if self.flashing then
        local r, g, b, a = Graphics.getColor()
        Graphics.setColor(self.flashColor)
        Graphics.rectangle('fill', 0, 0, self.w, self.h)
        Graphics.setColor(r, g, b, a)
      end
      local r, g, b, a = Graphics.getColor()
      Graphics.setColor(self.fadeColor)
      Graphics.rectangle('fill', 0, 0, self.w, self.h)
      return Graphics.setColor(r, g, b, a)
    end,
    follow = function(self, x, y)
      self.targetX, self.targetY = x, y
    end,
    setBounds = function(self, x, y, w, h)
      self.bound = true
      self.boundsMinX = x
      self.boundsMinY = y
      self.boundsMaxX = x + w
      self.boundsMaxY = y + h
    end,
    setFollowStyle = function(self, fs)
      self.followStyle = fs
    end,
    setFollowLerp = function(self, x, y)
      self.followLerpX = x
      self.followLerpY = y or x
    end,
    setFollowLead = function(self, x, y)
      self.followLeadX = x
      self.followLeadY = y or x
    end,
    flash = function(self, dur, color)
      self.flashDuration = dur
      self.flashColor = color or self.flashColor
      self.flashTimer = 0
      self.flashing = true
    end,
    fade = function(self, dur, color, action)
      self.fadeDur = dur
      self.baseFadeColor = self.fadeColor
      self.targetFadeColor = color
      self.fadeTimer = 0
      self.fadeAction = action
      self.fading = true
    end
  }
  _base_0.__index = _base_0
  _class_0 = setmetatable({
    __init = function(self, x, y, w, h, scale, rot)
      local Graphics = love.graphics
      self.x = x or (w or Graphics.getWidth() / 2)
      self.y = x or (h or Graphics.getHeight() / 2)
      self.mx = self.x
      self.my = self.y
      self.screenX = self.x
      self.screenY = self.y
      self.w = w or Graphics.getWidth()
      self.h = h or Graphics.getHeight()
      self.scale = scale or 1
      self.rot = rot or 0
      self.horiShakes = { }
      self.vertiShakes = { }
      self.targetX = nil
      self.targetY = nil
      self.scrollX = 0
      self.scrollY = 0
      self.lastTargetX = nil
      self.lastTargetY = nil
      self.followLerpX = 1
      self.followLerpY = 1
      self.followLeadX = 0
      self.followLeadY = 0
      self.followStyle = nil
      self.deadzone = nil
      self.deadzoneX = 0
      self.deadzoneY = 0
      self.deadzoneW = 0
      self.deadzoneH = 0
      self.bound = nil
      self.boundsMinX = 0
      self.boundsMinY = 0
      self.boundsMaxX = 0
      self.boundsMaxY = 0
      self.drawDeadzone = false
      self.flashDuration = 1
      self.flashTimer = 0
      self.flashColor = {
        0,
        0,
        0,
        1
      }
      self.flashing = false
      self.lastHoriShakeAmount = 0
      self.lastVertiShakeAmount = 0
      self.fadeDur = 1
      self.fadeTimer = 1
      self.fadeColor = {
        0,
        0,
        0,
        0
      }
      self.baseFadeColor = {
        0,
        0,
        0,
        1
      }
      self.targetFadeColor = {
        0,
        0,
        0,
        1
      }
      self.fadeAction = nil
      self.fading = false
    end,
    __base = _base_0,
    __name = "Camera"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  Camera = _class_0
end
return Camera
