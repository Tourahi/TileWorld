local sqrt, cos, sin, atan2 = math.sqrt, math.cos, math.sin, math.atan2
local min, max = math.min, math.max
local rand = love.math.random
local pi = math.pi
local inf = math.huge
local Vector2D
do
  local _class_0
  local _base_0 = {
    clone = function(self)
      return Vector2D(self.x, self.y)
    end,
    unpack = function(self)
      return self.x, self.y
    end,
    __tostring = function(self)
      return "(" .. tonumber(self.x) .. "," .. tonumber(self.y) .. ")"
    end,
    __add = function(a, b)
      assert(Vector2D.isvector(a) and Vector2D.isvector(b), "Wrong argument types <Vector2D> expected. [Add]")
      return Vector2D(a.x + b.x, a.y + b.y)
    end,
    __sub = function(a, b)
      assert(Vector2D.isvector(a) and Vector2D.isvector(b), "Wrong argument types <Vector2D> expected. [Sub]")
      return Vector2D(a.x - b.x, a.y - b.y)
    end,
    __mul = function(a, b)
      if type(a) == 'number' then
        return Vector2D(a * b.x, a * b.y)
      elseif type(b) == 'number' then
        return Vector2D(b * a.x, b * a.y)
      else
        assert(Vector2D.isvector(a) and Vector2D.isvector(b), "Wrong argument types <Vector2D> expected. [Mul]")
        return a.x * b.x + a.y * b.y
      end
    end,
    __div = function(a, b)
      assert(Vector2D.isvector(a) and type(b) == 'number', "Wrong argument types <Vector2D, number> expected. [Div]")
      assert(b ~= 0, "Division by 0 is undefined. [Div]")
      return Vector2D(a.x / b, a.y / b)
    end,
    __eq = function(a, b)
      return a.x == b.x and a.y == b.y
    end,
    __lt = function(a, b)
      return a.x < b.x or (a.x == b.x and a.y < b.y)
    end,
    __le = function(a, b)
      return a.x <= b.x and a.y <= b.y
    end,
    __unm = function(a)
      return Vector2D(-a.x, -a.y)
    end,
    len = function(self)
      return sqrt(self.x * self.x + self.y * self.y)
    end,
    len2 = function(self)
      return self.x * self.x + self.y * self.y
    end,
    magnitude = function(self)
      return self:len()
    end,
    overwrite = function(self, v)
      assert(Vector2D.isvector(v), "Wrong argument types <Vector2D> expected. [Overwrite]")
      self.x = v.x
      self.y = v.y
    end,
    normalize = function(self)
      local mag = self:magnitude()
      if mag ~= 0 then
        return self:overwrite(self / mag)
      end
    end,
    norm = function(self)
      local mag = self:magnitude()
      if mag ~= 0 then
        return self / mag
      end
    end,
    clamp = function(self, Min, Max)
      assert(Vector2D.isvector(Min) and Vector2D.isvector(Max), "Wrong argument types <Vector2D> expected. [Clamp]")
      self.x = min(max(self.x, Min.x), Max.x)
      self.y = min(max(self.y, Min.y), Max.y)
    end,
    clampX = function(self, Min, Max)
      assert(Vector2D.isvector(Min) and Vector2D.isvector(Max), "Wrong argument types <Vector2D> expected. [clampX]")
      self.x = min(max(self.x, Min.x), Max.x)
    end,
    clampY = function(self, Min, Max)
      assert(Vector2D.isvector(Min) and Vector2D.isvector(Max), "Wrong argument types <Vector2D> expected. [clampY]")
      self.y = min(max(self.y, Min.y), Max.y)
    end,
    parmul = function(self, a, b)
      assert(Vector2D.isvector(a) and Vector2D.isvector(b), "Wrong argument types <Vector2D> expected. [Parmul]")
      return Vector2D(a.x * b.x, a.y * b.y)
    end,
    toPolar = function(self)
      return Vector2D(atan2(self.x, self.y), self:len())
    end,
    dist = function(self, a, b)
      assert(Vector2D.isvector(a) and Vector2D.isvector(b), "Wrong argument types <Vector2D> expected. [Dist]")
      local dx = a.x - b.x
      local dy = a.y - b.y
      return sqrt(dx * dx + dy * dy)
    end,
    dist2 = function(self, a, b)
      assert(Vector2D.isvector(a) and Vector2D.isvector(b), "Wrong argument types <Vector2D> expected. [Dist2]")
      local dx = a.x - b.x
      local dy = a.y - b.y
      return dx * dx + dy * dy
    end,
    rotate = function(self, phi)
      local c, s = cos(phi), sin(phi)
      self.x, self.y = c * self.x - s * self.y, s * self.x + c * self.y
      return self
    end,
    rot = function(self, phi)
      local c, s = cos(phi), sin(phi)
      return Vector2D(c * self.x - s * self.y, s * self.x + c * self.y)
    end,
    perpendicular = function(self)
      return Vector2D(-self.y, self.x)
    end,
    projectOn = function(self, v)
      assert(Vector2D.isvector(v), "Wrong argument types <Vector2D> expected. [ProjectOn]")
      local s = (self.x * v.x + self.y * v.y) / (v.x * v.x + v.y * v.y)
      return Vector2D(s * v.x - self.x, s * v.y - self.y)
    end,
    mirrorOn = function(self, v)
      assert(Vector2D.isvector(v), "Wrong argument types <Vector2D> expected. [MirrorOn]")
      local s = 2 * (self.x * v.x + self.y * v.y) / (v.x * v.x + v.y * v.y)
      return Vector2D(s * v.x - self.x, s * v.y - self.y)
    end,
    cross = function(self, v)
      assert(Vector2D.isvector(v), "Wrong argument types <Vector2D> expected. [Cross]")
      return self.x * v.y - self.y * v.x
    end,
    heading = function(self)
      return -atan2(self.y, self.x)
    end
  }
  _base_0.__index = _base_0
  _class_0 = setmetatable({
    __init = function(self, x, y)
      if x == nil then
        x = 0
      end
      if y == nil then
        y = 0
      end
      assert('number' == type(x) and 'number' == type(y), 'x and y must be numbers.')
      self.x = x
      self.y = y
    end,
    __base = _base_0,
    __name = "Vector2D"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  local self = _class_0
  self.zero = function()
    return Vector2D()
  end
  self.one = function()
    return Vector2D(1, 1)
  end
  self.positiveInfinity = function()
    return Vector2D(inf, inf)
  end
  self.negativeInfinity = function()
    return Vector2D(-inf, -inf)
  end
  self.up = function()
    return Vector2D(0, 1)
  end
  self.down = function()
    return Vector2D(0, -1)
  end
  self.right = function()
    return Vector2D(1, 0)
  end
  self.left = function()
    return Vector2D(-1, 0)
  end
  self.isvector = function(v)
    return v.__class == Vector2D
  end
  self.fromAngle = function(t)
    return Vector2D(cos(t), -sin(t))
  end
  self.random = function(self)
    local t = rand() * pi * 2
    return Vector2D.fromAngle(t)
  end
  Vector2D = _class_0
end
return Vector2D
