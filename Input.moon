import insert from table
import remove from table
import timer from love
import keyboard from love
import mouse from love

callbacks = {
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

keyToButton = {
  mouse1: '1',
  mouse2: '2',
  mouse3: '3',
  mouse4: '4',
  mouse5: '5'
}

buttonToKey = {
  [1]: 'mouse1',
  [2]: 'mouse2',
  [3]: 'mouse3',
  [4]: 'mouse4',
  [5]: 'mouse5',
  ['l']: 'mouse1',
  ['r']: 'mouse2',
  ['m']: 'mouse3',
  ['x1']: 'mouse4',
  ['x2']: 'mouse5'
}

copy = (t) ->
  out = {}
  for k, v in pairs t
    out[k] = v
  out

getTableKeys = (tab) ->
  keyset = {}
  for k,v in pairs(tab)
    keyset[#keyset + 1] = k
  keyset

class Input
  new: =>
    @state = {}
    @binds = {}
    @functions = {}
    @prevState = {}
    @repeatState = {}
    @sequences = {}

    -- register callback
    oldCallbacks = {}
    emptyF = -> return
    for _, f in ipairs callbacks
      oldCallbacks[f] = love[f] or emptyF
      love[f] = (...) ->
        oldCallbacks[f](...)
        if self[f]
          self[f](self, ...)

  bind: (key, action) =>
    if type(action) == 'function'
      @functions[key] = action
      return
    if not @binds[action]
      @binds[action] = {}

    insert @binds[action], key

  bindArr: (bs = nil) =>
    if bs == nil then return
    for k, a in pairs bs
      @bind k, a

  pressed: (action) =>
    if action
      for _, key in ipairs @binds[action]
        if @state[key] and not @prevState[key]
          return true
    else
      for _, key in ipairs(getTableKeys(@functions))
        if @state[key] and not @prevState[key]
          @functions[key]!


  released: (action) =>
    for _, key in ipairs(@binds[action])
      if @prevState[key] and not @state[key]
        return true

  sequence: (...) =>
    sequence = {...}
    if #sequence <= 1
      error("Use pressed if only checking one action.")
    if type(sequence[#sequence]) ~= 'string'
      error("The last argument must be an action :: string.")
    if #sequence % 2 == 0
      error("The number of arguments must be odd.")

    sequenceKey = ''
    for _, seq in ipairs sequence
      sequenceKey ..= tostring(seq)

    if not @sequences[sequenceKey]
      @sequences[sequenceKey] = {
        sequence: sequence,
        currentIdx: 1
      }
    else
      if @sequences[sequenceKey].currentIdx == 1
        action = @sequences[sequenceKey].sequence[@sequences[sequenceKey].currentIdx]
        for _, key in ipairs @binds[action]
          if @state[key] and not @prevState[key]
            @sequences[sequenceKey].lastPressed = timer.getTime!
            @sequences[sequenceKey].currentIdx += 1

      else
        delay = @sequences[sequenceKey].sequence[@sequences[sequenceKey].currentIdx]
        action = @sequences[sequenceKey].sequence[@sequences[sequenceKey].currentIdx + 1]
        if (timer.getTime! - @sequences[sequenceKey].lastPressed) > delay
          @sequences[sequenceKey] = nil
          return
        for _, key in ipairs @binds[action]
          if @state[key] and not @prevState[key]
            if (timer.getTime! - @sequences[sequenceKey].lastPressed) <= delay
              if @sequences[sequenceKey].currentIdx + 1 == #@sequences[sequenceKey].sequence
                @sequences[sequenceKey] = nil
                return true
              else
                @sequences[sequenceKey].lastPressed = timer.getTime!
                @sequences[sequenceKey].currentIdx += 2
            else
              @sequences[sequenceKey] = nil

  down: (action = nil, interval = nil, delay = nil) =>
    if action and interval and delay
      for _, key in ipairs @binds[action]
        if @state[key] and not @prevState[key]
          @repeatState[key] = {
            pressedTime: timer.getTime!,
            delay: 0,
            interval: interval,
            delayed: true
          }
          return true
        else if @state[key] and @prevState[key]
          return true


    if action and interval and not delay
      for _, key in ipairs @binds[action]
        if @state[key] and not @prevState[key]
          @repeatState[key] = {
            pressedTime: timer.getTime!,
            delay: 0,
            interval: interval,
            delayed: false
          }
          return true
        else if @state[key] and @prevState[key]
          return true

    if action and not interval and not delay
      for _, key in ipairs @binds[action]
        if keyboard.isDown(key) or mouse.isDown(keyToButton[key] or 0)
          return true


  unbind: (key) =>
    for action, keys in pairs @binds
      for i = #keys, 1, -1
        if key == @binds[action][i]
          remove @binds[action], i
    if @functions[key]
      @functions[key] = nil


  unbindAll:  =>
    @binds = {}
    @functions = {}

  update: =>
    @pressed!
    @prevState = copy @state
    @state['wheelup'] = false
    @state['wheeldown'] = false

    for k, v in pairs @repeatState
      if v
        v.pressed = false
        t = timer.getTime! - v.pressedTime
        if v.delayed
          if t > v.delay
            v.pressed = true
            v.pressedTime = timer.getTime!
            v.delayed = false
        else
          if t > v.interval
            v.pressed = true
            v.pressedTime = timer.getTime!

  keypressed: (key) =>
    @state[key] = true

  keyreleased: (key) =>
    @state[key] = false
    @repeatState[key] = false

  mousepressed: (x, y, button) =>
     @state[buttonToKey[button]] = true


  mousepressed: (x, y, button) =>
     @state[buttonToKey[button]] = false
     @repeatState[buttonToKey[button]] = false

  wheelmoved: (x, y) =>
    if y > 0
      @state['wheelup'] = true
    if y < 0
      @state['wheeldown'] = true
