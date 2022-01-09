local Timer = {};

Timer.ticks = function(frames)
  return frames;
end

local tick = function(self, owner, dt)
  self.time = self.time + (1 * dt);

  if self.time >= self.duration then
    self:onDone(owner);
  end
end

Timer.create = function(duration, onDone)
  local obj = {};

  obj.time = 0;
  obj.duration = duration;
  obj.onDone = onDone;

  obj.tick = tick;

  return obj;
end

return Timer;
