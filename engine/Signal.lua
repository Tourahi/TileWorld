local Signal
do
  local _class_0
  local _base_0 = {
    getInstance = function(self)
      if self.__class.instance == nil then
        self.__class.instance = Signal()
      end
      return self.__class.instance
    end,
    register = function(self, s, f)
      if f == nil then
        f = nil
      end
      if self.signals[s] == nil then
        self.signals[s] = { }
        if f ~= nil then
          self.signals[s][f] = { }
        end
      else
        self.signals[s][f] = { }
      end
    end,
    addSignals = function(self, ...)
      local signals = {
        ...
      }
      for s in pairs(signals) do
        self:register(signals[s])
      end
    end,
    bind = function(self, s, f)
      self:register(s, f)
      self.signals[s][f] = f
      return f
    end,
    emit = function(self, s, ...)
      assert(self.signals[s] ~= nil, "Signal " .. s .. " is not registred.")
      for f in pairs(self.signals[s]) do
        f(...)
      end
    end,
    emitRef = function(self, s, ref, ...)
      assert(self.signals[s] ~= nil, "Signal " .. s .. " is not registred.")
      for f in pairs(self.signals[s]) do
        if f == ref then
          f(...)
        end
      end
    end,
    unbind = function(self, s, ...)
      assert(self.signals[s] ~= nil, "Signal " .. s .. " is not registred.")
      local f = {
        ...
      }
      for i = 1, select('#', ...) do
        local ref = f[i]
        self.signals[s][ref] = nil
      end
    end,
    clear = function(self, s)
      assert(self.signals[s] ~= nil, "Signal " .. s .. " is not registred.")
      self.signals[s] = { }
    end,
    drop = function(self, s)
      assert(self.signals[s] ~= nil, "Signal " .. s .. " is not registred.")
      self.signals[s] = nil
    end,
    bindPattern = function(self, p, f)
      for s in pairs(self.signals) do
        if s:match(p) then
          self:bind(s, f)
        end
      end
      return f
    end,
    unbindPattern = function(self, p, ...)
      for s in pairs(self.signals) do
        if s:match(p) then
          self:unbind(s, ...)
        end
      end
    end,
    emitPattern = function(self, p, ...)
      for s in pairs(self.signals) do
        if s:match(p) then
          self:emit(s, ...)
        end
      end
    end,
    clearPattern = function(self, p)
      for s in pairs(self.signals) do
        if s:match(p) then
          self:clear(s)
        end
      end
    end,
    dropPattern = function(self, p)
      for s in pairs(self.signals) do
        if s:match(p) then
          self:drop(s)
        end
      end
    end
  }
  _base_0.__index = _base_0
  _class_0 = setmetatable({
    __init = function(self)
      self.signals = { }
    end,
    __base = _base_0,
    __name = "Signal"
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
  self.instance = nil
  Signal = _class_0
end
return Signal
