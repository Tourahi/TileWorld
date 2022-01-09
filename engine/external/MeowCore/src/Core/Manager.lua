local base = MeowC.base;
local class  = require(base .. ".src.libs.30log");
local Root = require(base .. ".src.Core.Root");
local Event = require(base .. ".src.Core.Event");
local G_E = Event.getEvent;


local Manager = class("Manager", {
  rootCtrl = nil,
  hoverCtrl = nil,
  focusCtrl = nil,
  holdCtrl = nil,
  lastClickCtrl = nil,
  lastClickTime = love.timer.getTime()
});

local callbacks = {
  'update',
  'draw',
  'mousemoved',
  'mousepressed',
  'mousereleased',
  'keypressed',
  'keyreleased',
  'wheelmoved',
  'textinput'
}



Manager.init = function(self)
  Manager.rootCtrl = self:createRootCtrl();
  Manager.rootCtrl:setEnabled(true);
end



Manager.getInstance = function()
  if not Manager.instance then
    Manager.instance = Manager();
  end
  return Manager.instance;
end

Manager.getInstanceRoot = function()
  if not Manager.instance then
    Manager.instance = Manager();
  end
  return Manager.instance:getRootCtrl();
end

Manager.createRootCtrl = function(self)
  local ctrl = Root:new();
  self.rootCtrl = ctrl;
  return ctrl;
end

Manager.getRootCtrl = function(self)
  return self.rootCtrl;
end

Manager.update = function(self, dt)
  MeowC.core.Flux.update(dt);
  if self.rootCtrl then
    return self.rootCtrl:update(dt);
  end
end

Manager.draw = function(self)
  if self.rootCtrl then
    return self.rootCtrl:draw();
  end
end

local function dispatch(ctrl, name, ...)
    ctrl.events:dispatch(name, ...);
end

Manager.mousemoved = function(self, x, y, dx, dy)
  if not self.rootCtrl then return end

  local hitCtrl = self.rootCtrl:hitTest(x, y);
  if hitCtrl ~= self.hoverCtrl then
      if self.hoverCtrl then
        dispatch(self.hoverCtrl, G_E("UI_MOUSE_LEAVE"));
      end

      self.hoverCtrl = hitCtrl;

      if hitCtrl then
        dispatch(hitCtrl, G_E("UI_MOUSE_ENTER"));
      end
  end

  if self.holdCtrl then
    dispatch(self.holdCtrl, G_E("UI_MOUSE_MOVE"), x, y, dx, dy)
  else
      if self.hoverCtrl then
        dispatch(self.hoverCtrl, G_E("UI_MOUSE_MOVE"), x, y, dx, dy)
      end
  end
end

Manager.setFocuse = function(self, ctrl)
  if self.focusCtrl == ctrl then
    return;
  end

  if self.focusCtrl then
     dispatch(self.focusCtrl, G_E("UI_UN_FOCUS"));
  end

  self.focusCtrl = ctrl;

  if self.focusCtrl then
     dispatch(self.focusCtrl, G_E("UI_FOCUS"));
  end
end

Manager.mousepressed = function(self, x, y, button, isTouch)
  if not self.rootCtrl then return end

  local hitCtrl = self.rootCtrl:hitTest(x, y);
  if hitCtrl then
    dispatch(hitCtrl, G_E("UI_MOUSE_DOWN"), x, y, button, isTouch );
    self.holdCtrl = hitCtrl;
  end
  self:setFocuse(hitCtrl);
end

Manager.mousereleased = function(self, x, y, button, isTouch)
  if self.holdCtrl then
    dispatch(self.holdCtrl, G_E("UI_MOUSE_UP"), x, y, button, isTouch);
    if self.rootCtrl then
      local hitCtrl = self.rootCtrl:hitTest(x, y);
      local timer = love.timer;
      if hitCtrl == self.holdCtrl then
        if self.lastClickCtrl and
           self.lastClickCtrl == self.holdCtrl and
           (timer.getTime() - self.lastClickTime <= 0.4) then
              dispatch(self.holdCtrl, G_E("UI_DB_CLICK"), self.holdCtrl, x, y);
              self.lastClickCtrl = nil;
              self.lastClickTime = 0;
        else
          dispatch(self.holdCtrl, G_E("UI_CLICK"), self.holdCtrl, x, y);
          self.lastClickCtrl = self.holdCtrl;
          self.lastClickTime = timer.getTime();
        end
      end
    end
    self.holdCtrl = nil
  end
end

Manager.wheelmoved = function(self, x, y)
  local mouse = love.mouse;
  local hitCtrl = self.rootCtrl:hitTest(mouse.getX(), mouse.getY());
  while hitCtrl do
    self:mousemoved(mouse.getX(), mouse.getY(), 0, 0);
    if hitCtrl.events:dispatch(G_E("UI_WHELL_MOVE"), x, y) then
      return;
    end
    hitCtrl = hitCtrl:getParent();
  end
end


Manager.keypressed = function(self, key, scancode, isrepeat)
    if self.focusCtrl then
        dispatch(self.focusCtrl, G_E("UI_KEY_DOWN"), key, scancode, isrepeat);
    end
end

Manager.keyreleased = function(self, key)
    if self.focusCtrl then
        dispatch(self.focusCtrl, G_E("UI_KEY_UP"), key);
    end
end

Manager.textinput = function(self, text)
    if self.focusCtrl then
        dispatch(self.focusCtrl, G_E("UI_TEXT_INPUT"), text);
    end
end


Manager.resize = function(self,w, h)
    self.rootCtrl:resize(w, h);
end


return Manager;
