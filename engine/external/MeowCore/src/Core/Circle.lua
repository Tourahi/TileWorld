local sqrt = math.sqrt
local base = MeowC.base;
local class = require(base .. ".src.libs.30log");


local pointToPointSqr = function(x1, y1, x2, y2)
  local dx, dy = x2 - x1, y2 - y1;
  return dx*dx + dy*dy;
end

local pointToPointDist = function(x1, y1, x2, y2)
  return sqrt(pointToPointSqr(x1, y1, x2, y2));
end


local Circle = class("Circle", {
  x = 0,
  y = 0,
  r = 0
});

Circle.init = function(self, x, y, radius)
  self.x = x or 0;
  self.y = y or 0;
  self.r = radius or 0;
end



Circle.contains = function(self, x, y)
  if pointToPointDist(self.x, self.y, x, y) < self.r then
    return true;
  else
    return false;
  end
end

Circle.getPosition = function(self)
  return self.x, self.y;
end

Circle.getX = function(self)
  return self.x;
end

Circle.getY = function(self)
  return self.y;
end


Circle.getRadius =  function(self)
  return self.r;
end

Circle.getSize = function(self)
  return self.r - self.x,self.r - self.y;
end


Circle.getWidth =  function(self)
  return self:getRadius() - self.x;
end


Circle.getHeight = function(self)
  return self:getRadius() - self.y;
end

return Circle;
