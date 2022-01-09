local base = MeowC.base
local class = require(base .. ".src.libs.30log");
local Event = require(base .. ".src.Core.Event");
local G_E = Event.getEvent;
local Box  = require(base .. ".src.Core.Box");
local Circle  = require(base .. ".src.Core.Circle");
local Timer = require(base .. ".src.Core.Timer");




-- Local functions
local _clipScissor = function(nx , ny, nw, nh)
    -- Apply a scissor to the current scissor (intersect the rects)
    local lg = love.graphics;
    local ox, oy, ow, oh = lg.getScissor();
    if ox then
        -- Intersect both rects
        nw = nx + nw;
        nh = ny + nh;
        nx, ny = math.max(nx, ox), math.max(ny, oy);
        nw = math.max(0, math.min(nw, ox + ow) - nx);
        nh = math.max(0, math.min(nh, oy + oh) - ny);
    end
    -- Set new scissor
    if(nw > 0 and nh > 0) then
      lg.setScissor(nx, ny, nw, nh);
    end
    -- Return old scissor
    return ox, oy, ow, oh;
end


local Control = class("Control", {
  x = 0,
  y = 0,
  anchorX = 0,
  anchorY = 0,
  width = 0,
  height = 0,
  depth = 0,
  children = {},
  parent = nil,
  visible = true,
  enabled = false,
  childrenEnabled = true,
  events = nil,
  sclip = false,
  requireConform = false,
  worldX = 0,
  worldY = 0,
  boundingBox = nil,
  timer = nil,
  onTimerDone = nil,
  radius = 0
});


Control.init = function(self, boxType)
    boxType = boxType or 'Box'
    self.events = Event()
    if (boxType == 'Box') then
      self.boundingBox = Box()
    elseif (boxType == 'Circle') then
      self.boundingBox = Circle()
    end
end

Control.update = function(self, dt)
  self:conform();
  if self.timer then self.timer:tick(self, dt) end
  self.events:dispatch(G_E("UI_UPDATE") ,dt);
  for _,v in ipairs(self.children) do
    v:update(dt);
  end
end

Control.draw = function(self)
  if not self.visible then return end
  self:clipBegin();
  self.events:dispatch(G_E("UI_DRAW"));
  for _,v in ipairs(self.children) do
    v:draw();
  end
  self:clipEnd();
end

Control.setClip = function(self, isClip)
  self.clip = isClip;
end

Control.isClipped = function(self)
  return self.clip;
end

Control.clipBegin = function(self)
  if self.clip then
    local box = self:getBoundingBox();
    local x, y = box.x, box.y;
    local w, h = box:getWidth(), box:getHeight();
    self.ox, self.oy, self.ow, self.oh = _clipScissor(x, y, w, h);
  end
end

Control.clipEnd = function(self)
  local lg = love.graphics;
  if self.clip then
    lg.setScissor(self.ox, self.oy, self.ow, self.oh);
  end
end

Control.needConforming = function(self)
  self.requireConform = true;
end

Control.localToGlobal = function(self, x, y)
  -- Return the global position (So we add also the parents position on the screen)
  x = (x or 0) + self.x;
  y = (y or 0) + self.y;

  if self.parent then
    x , y = self.parent:localToGlobal(x , y);
  end
  return x, y;
end

Control.globalToLocal = function(self, x, y)
  -- Return the local position (Local to the parent area)
  x = (x or 0) - self.x;
  y = (y or 0) - self.y;

  if self.parent then
    x , y = self.parent:localToGlobal(x , y);
  end
  return x, y;
end


Control.conform = function(self)
  if not self.requireConform then return end
  local x, y = self:localToGlobal();
  local w = self.width * self.anchorX;
  local h = self.height * self.anchorY;
  self.worldX = x - w;
  self.worldY = y - h;

  local box = self.boundingBox;
  if(box.name == 'Box') then
    box.x = self.worldX;
    box.y = self.worldY;
    box.width = self.worldX + self.width;
    box.height = self.worldY + self.height;
  elseif(box.name == 'Circle') then
    box.x = self.worldX;
    box.y = self.worldY;
    box.r = self.radius;
  end

  for _, v in ipairs(self.children) do
    v:needConforming();
    v:conform();
  end
  self.requireConform = false;
end

Control.setAnchor = function(self, x, y)
  self.anchorX = x;
  self.anchorY = y;
  self:needConforming();
end

Control.getAnchor = function(self)
  return self.anchorX, self.anchorY;
end

Control.setAnchorX = function(self, x)
  self.anchorX = x;
  self:needConforming();
end

Control.getAnchorX = function(self)
  return self.anchorX;
end

Control.setAnchorY = function(self, y)
  self.anchorY = y;
  self:needConforming();
end

Control.getAnchorY = function(self)
  return self.anchorY;
end

Control.setPos = function(self, x, y)
  self.x = x;
  self.y = y;
  self:needConforming();
  self.events:dispatch(G_E("UI_MOVE"));
end

Control.getPos = function(self)
  return self.x, self.y;
end

Control.setX = function(self, x)
  self.x = x;
  self:needConforming();
end

Control.getX = function(self)
  return self.x;
end

Control.setY = function(self, y)
  self.y = y;
  self:needConforming();
end

Control.setRadius = function(self, r)
  self.radius = r;
  self:needConforming();
end

Control.getRadius = function(self)
  return self.radius;
end

Control.getY = function(self)
  return self.y;
end

Control.setSize = function(self, width, height)
  self.width = width;
  self.height = height;
  self:needConforming();
end

Control.getSize = function(self)
  return self.width, self.height;
end

Control.setWidth = function(self, width)
  self.width = width;
  self:needConforming();
end

Control.getWidth = function(self)
  return self.width;
end

Control.setHeight = function(self, height)
  self.height = height;
  self:needConforming();
end

Control.getHeight = function(self)
  return self.height;
end

Control.getBoundingBox = function(self)
  return self.boundingBox;
end

Control.setParent = function(self, parent)
  self.parent = parent;
  self:needConforming();
end

Control.getParent = function(self)
  return self.parent;
end

Control.setEnabled = function(self, enabled)
  self.enabled = enabled;
end

Control.isEnabled = function(self)
  return self.enabled;
end

Control.setChildrenEnabled = function(self, enabled)
  self.childrenEnabled = enabled;
end

Control.isChildrenEnabled = function(self)
  return self.childrenEnabled;
end

Control.hitTest = function(self, x, y)
  if not self:getBoundingBox():contains(x, y) then return nil end
  if self.childrenEnabled then
    for i,v in ipairs(self.children) do
      local control = self.children[#self.children - i + 1];
      local hitControl = control:hitTest(x, y);
      if hitControl then
        return hitControl;
      end
    end
  end

  if self.enabled then -- The last child will run this
    return self;
  else
    return nil;
  end

end

Control.setDepth = function(self, depth)
  self.depth = depth;
  if self.parent then
    self.parent:sortChildren();
  end
end

Control.getDepth = function(self)
  return self.depth;
end

Control.addChild = function(self, child, depth)
  table.insert(self.children, child);
  child:setParent(self);
  if depth then
    child:setDepth(depth);
  end
  child.events:dispatch(G_E("UI_ON_ADD"));
end

Control.removeChild = function(self ,child)
  for i,v in ipairs(self.children) do
    if v == child then
      table.remove(self.children, i);
      child.events:dispatch(G_E("UI_ON_REMOVE"));
      break;
    end
  end
end

Control.dropChildren = function(self)
  self.children = {};
end

Control.disableChildren = function(self)
  for i,v in ipairs(self.children) do
    v:setEnabled(false);
  end
end

Control.enableChildren = function(self)
  for i,v in ipairs(self.children) do
    v:setEnabled(true);
  end
end

Control.sortChildren = function(self)
  table.sort(self.children, function(a, b)
    return a.depth < b.depth;
  end);
end

Control.getChildren = function(self)
  return self.children;
end

Control.setFocuse = function(self)
  local Manager = require("src.Core.Manager");
  Manager:getInstance():setFocuse(self);
end

Control.addTimer = function(self, duration, onDone)
  if not self.timer then
    self.onTimerDone = onDone;
    self.timer = Timer(Timer.ticks(duration), function(_, owner)
      owner:onTimerDone();
    end);
  end
end

Control.on = function(self, event, callback, target)
  local target = target or self;
  if event and callback then
    self.events:on(G_E(event), callback, target);
  end
end

return Control;
