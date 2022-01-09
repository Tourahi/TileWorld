local insert
insert = table.insert
local remove
remove = table.remove
local timer
timer = love.timer
local keyboard
keyboard = love.keyboard
local mouse
mouse = love.mouse
local callbacks = {
  'keypressed',
  'keyreleased',
  'mousepressed',
  'mousereleased',
  'gamepadpressed',
  'gamepadreleased',
  'gamepadaxis',
  'wheelmoved',
  'update'
}
local keyToButton = {
  mouse1 = '1',
  mouse2 = '2',
  mouse3 = '3',
  mouse4 = '4',
  mouse5 = '5'
}
local buttonToKey = {
  [1] = 'mouse1',
  [2] = 'mouse2',
  [3] = 'mouse3',
  [4] = 'mouse4',
  [5] = 'mouse5',
  ['l'] = 'mouse1',
  ['r'] = 'mouse2',
  ['m'] = 'mouse3',
  ['x1'] = 'mouse4',
  ['x2'] = 'mouse5'
}
local copy
copy = function(t)
  local out = { }
  for k, v in pairs(t) do
    out[k] = v
  end
  return out
end
local getTableKeys
getTableKeys = function(tab)
  local keyset = { }
  for k, v in pairs(tab) do
    keyset[#keyset + 1] = k
  end
  return keyset
end
local Input
do
  local _class_0
  local _base_0 = {
    bind = function(self, key, action)
      if type(action) == 'function' then
        self.functions[key] = action
        return 
      end
      if not self.binds[action] then
        self.binds[action] = { }
      end
      return insert(self.binds[action], key)
    end,
    bindArr = function(self, bs)
      if bs == nil then
        bs = nil
      end
      if bs == nil then
        return 
      end
      for k, a in pairs(bs) do
        self:bind(k, a)
      end
    end,
    pressed = function(self, action)
      if action then
        for _, key in ipairs(self.binds[action]) do
          if self.state[key] and not self.prevState[key] then
            return true
          end
        end
      else
        for _, key in ipairs(getTableKeys(self.functions)) do
          if self.state[key] and not self.prevState[key] then
            self.functions[key]()
          end
        end
      end
    end,
    released = function(self, action)
      for _, key in ipairs(self.binds[action]) do
        if self.prevState[key] and not self.state[key] then
          return true
        end
      end
    end,
    sequence = function(self, ...)
      local sequence = {
        ...
      }
      if #sequence <= 1 then
        error("Use pressed if only checking one action.")
      end
      if type(sequence[#sequence]) ~= 'string' then
        error("The last argument must be an action :: string.")
      end
      if #sequence % 2 == 0 then
        error("The number of arguments must be odd.")
      end
      local sequenceKey = ''
      for _, seq in ipairs(sequence) do
        sequenceKey = sequenceKey .. tostring(seq)
      end
      if not self.sequences[sequenceKey] then
        self.sequences[sequenceKey] = {
          sequence = sequence,
          currentIdx = 1
        }
      else
        if self.sequences[sequenceKey].currentIdx == 1 then
          local action = self.sequences[sequenceKey].sequence[self.sequences[sequenceKey].currentIdx]
          for _, key in ipairs(self.binds[action]) do
            if self.state[key] and not self.prevState[key] then
              self.sequences[sequenceKey].lastPressed = timer.getTime()
              self.sequences[sequenceKey].currentIdx = self.sequences[sequenceKey].currentIdx + 1
            end
          end
        else
          local delay = self.sequences[sequenceKey].sequence[self.sequences[sequenceKey].currentIdx]
          local action = self.sequences[sequenceKey].sequence[self.sequences[sequenceKey].currentIdx + 1]
          if (timer.getTime() - self.sequences[sequenceKey].lastPressed) > delay then
            self.sequences[sequenceKey] = nil
            return 
          end
          for _, key in ipairs(self.binds[action]) do
            if self.state[key] and not self.prevState[key] then
              if (timer.getTime() - self.sequences[sequenceKey].lastPressed) <= delay then
                if self.sequences[sequenceKey].currentIdx + 1 == #self.sequences[sequenceKey].sequence then
                  self.sequences[sequenceKey] = nil
                  return true
                else
                  self.sequences[sequenceKey].lastPressed = timer.getTime()
                  self.sequences[sequenceKey].currentIdx = self.sequences[sequenceKey].currentIdx + 2
                end
              else
                self.sequences[sequenceKey] = nil
              end
            end
          end
        end
      end
    end,
    down = function(self, action, interval, delay)
      if action == nil then
        action = nil
      end
      if interval == nil then
        interval = nil
      end
      if delay == nil then
        delay = nil
      end
      if action and interval and delay then
        for _, key in ipairs(self.binds[action]) do
          if self.state[key] and not self.prevState[key] then
            self.repeatState[key] = {
              pressedTime = timer.getTime(),
              delay = 0,
              interval = interval,
              delayed = true
            }
            return true
          else
            if self.state[key] and self.prevState[key] then
              return true
            end
          end
        end
      end
      if action and interval and not delay then
        for _, key in ipairs(self.binds[action]) do
          if self.state[key] and not self.prevState[key] then
            self.repeatState[key] = {
              pressedTime = timer.getTime(),
              delay = 0,
              interval = interval,
              delayed = false
            }
            return true
          else
            if self.state[key] and self.prevState[key] then
              return true
            end
          end
        end
      end
      if action and not interval and not delay then
        for _, key in ipairs(self.binds[action]) do
          if keyboard.isDown(key) or mouse.isDown(keyToButton[key] or 0) then
            return true
          end
        end
      end
    end,
    unbind = function(self, key)
      for action, keys in pairs(self.binds) do
        for i = #keys, 1, -1 do
          if key == self.binds[action][i] then
            remove(self.binds[action], i)
          end
        end
      end
      if self.functions[key] then
        self.functions[key] = nil
      end
    end,
    unbindAll = function(self)
      self.binds = { }
      self.functions = { }
    end,
    update = function(self)
      self:pressed()
      self.prevState = copy(self.state)
      self.state['wheelup'] = false
      self.state['wheeldown'] = false
      for k, v in pairs(self.repeatState) do
        if v then
          v.pressed = false
          local t = timer.getTime() - v.pressedTime
          if v.delayed then
            if t > v.delay then
              v.pressed = true
              v.pressedTime = timer.getTime()
              v.delayed = false
            end
          else
            if t > v.interval then
              v.pressed = true
              v.pressedTime = timer.getTime()
            end
          end
        end
      end
    end,
    keypressed = function(self, key)
      self.state[key] = true
    end,
    keyreleased = function(self, key)
      self.state[key] = false
      self.repeatState[key] = false
    end,
    mousepressed = function(self, x, y, button)
      self.state[buttonToKey[button]] = true
    end,
    mousepressed = function(self, x, y, button)
      self.state[buttonToKey[button]] = false
      self.repeatState[buttonToKey[button]] = false
    end,
    wheelmoved = function(self, x, y)
      if y > 0 then
        self.state['wheelup'] = true
      end
      if y < 0 then
        self.state['wheeldown'] = true
      end
    end
  }
  _base_0.__index = _base_0
  _class_0 = setmetatable({
    __init = function(self)
      self.state = { }
      self.binds = { }
      self.functions = { }
      self.prevState = { }
      self.repeatState = { }
      self.sequences = { }
      local oldCallbacks = { }
      local emptyF
      emptyF = function() end
      for _, f in ipairs(callbacks) do
        oldCallbacks[f] = love[f] or emptyF
        love[f] = function(...)
          oldCallbacks[f](...)
          if self[f] then
            return self[f](self, ...)
          end
        end
      end
    end,
    __base = _base_0,
    __name = "Input"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  Input = _class_0
  return _class_0
end
