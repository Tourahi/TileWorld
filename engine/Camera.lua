local csnap
csnap = function(v, x)
  return math.ceil(v / x) * x - x / 2
end
local lerp
lerp = function(a, b, x)
  return a + (b - a) * x
end
local clamp
clamp = function(x, minX, maxX)
  return x < minX and minX or (x > maxX and maxX or x)
end
local Camera
do
  local _class_0
  local _base_0 = {
    getVisibleArea = function(self, scale)
      local min, abs = math.min, math.abs
      scale = scale or self.scale
      local sin, cos = abs(self.sin), abs(self.cos)
      local w, h = self.w / scale, self.h / scale
      w, h = cos * w + sin * h, sin * w + cos * h
      return min(w, self.worldW), min(h, self.worldH)
    end,
    setWorld = function(self, l, t, w, h)
      self.worldL, self.worldT, self.worldW, self.worldH = l, t, (w - (w - self.mapW)) - l, (h - (h - self.mapH)) - t
      return self:adjustPosition()
    end,
    adjustPosition = function(self)
      local worldL, worldT, worldW, worldH = self.worldL, self.worldT, self.worldW, self.worldH
      local w, h = self:getVisibleArea()
      local wc, hc = w * 0.5, h * 0.5
      local left, right = worldL + wc, worldL + worldW - wc
      local top, bottom = worldT + hc, worldT + worldH - hc
      self.x, self.y = clamp(self.x, left, right), clamp(self.y, top, bottom)
    end,
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
      if self.followStyle == 'LOCKED' then
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
        self:adjustPosition()
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
        self.screenX = clamp(self.screenX, (self.w / self.scale) / 2, self.w)
        self.screenY = clamp(self.screenY, (self.h / self.scale) / 2, self.h)
        self.x = lerp(self.x, self.screenX, self.followLerpX)
        self.y = lerp(self.y, self.screenY, self.followLerpY)
        return self:adjustPosition()
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
        return self:adjustPosition()
      end
    end,
    draw = function(self)
      local Graphics = love.graphics
      if self.drawDeadzone and self.deadzone then
        local n = Graphics.getLineWidth()
        Graphics.setLineWidth(4)
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
    setBounds = function(self, mapL, mapT, mapW, mapH)
      self.worldL, self.worldT, self.worldW, self.worldH = mapL, mapT, mapW, mapH
    end,
    cornerTransform = function(self, x, y)
      local scale, sin, cos = self.scale, self.sin, self.cos
      x, y = x - self.x, y - self.y
      x, y = -cos * x + sin * y, -sin * x - cos * y
      return self.x - (x / scale + self.l), self.y - (y / scale + self.t)
    end,
    getVisibleCorners = function(self)
      local x, y, w2, h2 = self.x, self.y, self.w2, self.h2
      local x1, y1 = self:cornerTransform(x - w2, y - h2)
      local x2, y2 = self:cornerTransform(x + w2, y - h2)
      local x3, y3 = self:cornerTransform(x + w2, y + h2)
      local x4, y4 = self:cornerTransform(x - w2, y + h2)
      return x1, y1, x2, y2, x3, y3, x4, y4
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
    adjustScale = function(self)
      local worldW, worldH = self.worldW, self.worldH
      local rw, rh = self:getVisibleArea(1)
      local sx, sy = rw / worldW, rh / worldH
      local rscale = math.max(sx, sy)
      self.scale = math.max(self.scale, rscale)
    end,
    setAngle = function(self, angle)
      self.rot = angle
      self.cos, self.sin = math.cos(angle), math.sin(angle)
      self:adjustScale()
      return self:adjustPosition()
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
    end,
    setScale = function(self, s)
      self.scale = s
    end,
    getWindow = function(self)
      return self.l, self.t, self.w, self.h
    end,
    getVisible = function(self)
      local w, h = self:getVisibleArea()
      return self.x - w * 0.5, self.y - h * 0.5, w, h
    end,
    attachC = function(self, canvas, callback)
      if canvas == nil then
        canvas = self.canvas
      end
      local Graphics = love.graphics
      local _canvas = Graphics.getCanvas()
      local sx, sy, sw, sh = Graphics.getScissor()
      Graphics.setScissor(self:getWindow())
      Graphics.setCanvas(canvas)
      Graphics.clear()
      Graphics.push()
      Graphics.origin()
      Graphics.translate(math.floor(self.w / 2 or 0), math.floor(self.h / 2 or 0))
      Graphics.scale(self.scale)
      Graphics.rotate(self.rot)
      Graphics.translate(-self.x, -self.y)
      if callback then
        callback()
      end
      Graphics.pop()
      Graphics.push()
      Graphics.origin()
      Graphics.setCanvas(_canvas)
      Graphics.draw(canvas)
      Graphics.pop()
      return Graphics.setScissor(sx, sy, sw, sh)
    end
  }
  _base_0.__index = _base_0
  _class_0 = setmetatable({
    __init = function(self, l, t, w, h, scale, rot, mapW, mapH)
      local Graphics = love.graphics
      local windowW, windowH = Graphics.getWidth(), Graphics.getHeight()
      self.x = w or Graphics.getWidth() / 2
      self.mapW = mapW
      self.mapH = mapH
      self.y = h or Graphics.getHeight() / 2
      self.mx = self.x
      self.my = self.y
      self.screenX = self.x
      self.screenY = self.y
      self.w = w or Graphics.getWidth()
      self.h = h or Graphics.getHeight()
      self.l = l or 0
      self.t = t or 0
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
      self.sin = math.sin(0)
      self.cos = math.cos(0)
      self:setWorld(self.l, self.t, self.w, self.h)
      self.deadzone = nil
      self.deadzoneX = 0
      self.deadzoneY = 0
      self.deadzoneW = 0
      self.deadzoneH = 0
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
      self.canvas = Graphics.newCanvas(self.w, self.h)
      return self.canvas:setFilter("nearest", "nearest")
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
  return _class_0
end
