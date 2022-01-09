local getTime
getTime = love.timer.getTime
local random
random = function(min, max)
  min, max = min or 0, max or 1
  return (min > max and (love.math.random() * (min - max) + max)) or (love.math.random() * (max - min) + min)
end
local Shake
do
  local _class_0
  local _base_0 = {
    update = function(self, dt)
      self.t = love.timer.getTime() * 1000 - self.startTime
      if self.t > self.dur then
        self.shaking = false
      end
    end,
    getAmplitude = function(self, t)
      if not t then
        if not self.shaking then
          return 0
        end
        t = self.t
      end
      local s = (t / 1000) * self.freq
      local s0 = math.floor(s)
      local s1 = s0 + 1
      local k = self:decay(t)
      return self.amp * (self:noise(s0) + (s - s0) * (self:noise(s1) - self:noise(s0))) * k
    end,
    decay = function(self, t)
      if t > self.dur then
        return 0
      end
      return (self.dur - t) / self.dur
    end,
    noise = function(self, s)
      if s >= #self.samples then
        return 0
      end
      return self.samples[s] or 0
    end,
    isShaking = function(self)
      return self.shaking
    end
  }
  _base_0.__index = _base_0
  _class_0 = setmetatable({
    __init = function(self, amp, freq, dur)
      self.amp = amp
      self.freq = freq
      self.dur = dur
      local sample_count = (self.dur / 1000) * freq
      self.samples = { }
      for i = 1, sample_count do
        self.samples[i] = random(-1, 1)
      end
      self.startTime = love.timer.getTime() * 1000
      self.t = 0
      self.shaking = true
    end,
    __base = _base_0,
    __name = "Shake"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  Shake = _class_0
end
return Shake
