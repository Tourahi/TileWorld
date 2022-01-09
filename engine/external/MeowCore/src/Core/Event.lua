local base = MeowC.base
local class = require(base .. ".src.libs.30log");

local Event = class("Event", {
  handlers = {}
});

local _events = {
  UI_MOUSE_DOWN = "mouseDown",
  UI_MOUSE_UP = "mouseUp",
  UI_MOUSE_MOVE = "mouseMove",
  UI_MOUSE_ENTER = "mouseEnter",
  UI_MOUSE_LEAVE = "mouseLeave",
  UI_WHELL_MOVE = "whellMove",
  UI_CLICK = "click",

  UI_DB_CLICK = "dbClick",
  UI_FOCUS = "focus",
  UI_UN_FOCUS = "unFocus",

  UI_KEY_DOWN = "keyDown",
  UI_KEY_UP = "keyUp",

  UI_TEXT_INPUT = "textInput",
  UI_TEXT_CHANGE = "textChange",

  UI_UPDATE = "update",
  UI_DRAW = "draw",
  UI_MOVE = "move",
  UI_ON_ADD = "onAdd",
  UI_ON_REMOVE = "onRemove",

  UI_ON_SCROLL = "onScroll",
  UI_ON_SELECT = "onSelect",

  TIMER_DONE = "onTimerDone"
}

Event.init = function(self)
  self.handlers = {};
end


Event.dispatch = function(self, name, ...)
  local handler = self.handlers[name]
  if not handler then
      return false
  end

  for _,v in ipairs(handler) do
    local handlr = v;
    if v.callback then
      if v.target then
        if v.callback(v.target, ...) then
            return true
        end
      else
        if v.callback(...) then
            return true
        end
      end
    end
  end

  return false
end

Event.on = function(self, name, callback, target)
  if not self.handlers[name] then
    self.handlers[name] = {};
  end
  local handler = {
    name = name .. #self.handlers[name],
    callback = callback,
    target = target
  }
  table.insert(self.handlers[name], handler);
  return handler;
end

Event.remove = function(self, event, handlerName)
  if self.handlers[_events[event]] == nil then
    return
  end
  for i,v in ipairs(self.handlers[_events[event]]) do
    if v.name == handlerName then
      table.remove(self.handlers[_events[event]], i);
      return
    end
  end
end


Event.drop = function(self)
  self.handlers = {};
end


Event.getEvent = function(Ename)
  return _events[Ename];
end



return Event;
