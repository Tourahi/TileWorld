local base = MeowC.base;
local class = require(base .. ".src.libs.30log");

local Box = class("Box", {
  x = 0,
  y = 0,
  width = 0,
  height = 0,
});

Box.init = function(self, x, y, width, height)
  self.x = x or 0;
  self.y = y or 0;
  self.width = width or 0;
  self.height = height or 0;
end

Box.contains = function(self, x, y)
  if x < self.x or x >= self.width or y < self.y or y >= self.height then
    return false;
  end
  return true;
end

Box.getPosition = function(self)
  return self.x, self.y;
end

Box.getX = function(self)
  return self.x;
end

Box.getY = function(self)
  return self.y;
end

Box.getSize = function(self)
  return self.width - self.x,self.height - self.y;
end


Box.setSize = function(self, w, h)
  self.width = w;
  self.height = h;
end

Box.getWidth =  function(self)
  return self.width - self.x;
end


Box.getHeight = function(self)
  return self.height - self.y;
end

return Box;
