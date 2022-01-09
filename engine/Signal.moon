-- singleton
class Signal 
  @instance = nil
  new: =>
    @signals = {}

  getInstance: =>
    if @@instance == nil
     @@instance = Signal!
    @@instance

  register: (s, f = nil) =>
    if @signals[s] == nil
      @signals[s] = {}
      if f ~= nil
        @signals[s][f] = {}
    else
      @signals[s][f] = {}

  addSignals: (...) =>
    signals = {...}
    for s in pairs signals
      @register signals[s]

  -- bind a function to a signal
  bind: (s, f) =>
    @register s, f      
    @signals[s][f] = f
    f

  -- emit a signal
  emit: (s, ...) =>
    assert @signals[s] ~= nil, "Signal "..s.." is not registred."
    for f in pairs @signals[s]
      f ...

  -- emit a signal to a func referance
  -- basically only that function will react to the signal emission.
  emitRef: (s, ref, ...) =>
    assert @signals[s] ~= nil, "Signal "..s.." is not registred."
    for f in pairs @signals[s]
      if f == ref 
        f ...

  -- unbind a function from a signal 
  unbind: (s, ...)=>
    assert @signals[s] ~= nil, "Signal "..s.." is not registred."
    f = {...}
    for i = 1, select '#', ...
      ref = f[i]
      @signals[s][ref] = nil

  clear: (s) =>
    assert @signals[s] ~= nil, "Signal "..s.." is not registred."
    @signals[s] = {}

  drop: (s) =>
    assert @signals[s] ~= nil, "Signal "..s.." is not registred."
    @signals[s] = nil

  -- bind a function to every signal that matches the pattern
  -- INFO : it does not create the signal if it does not exist
  bindPattern: (p, f) =>
    for s in pairs @signals
      if s\match p
        @bind s, f
    f

  -- unbind a function from every signal that matches the pattern
  unbindPattern: (p, ...) =>
    for s in pairs @signals
      if s\match p
        @unbind s, ...

  emitPattern: (p, ...) =>
    for s in pairs @signals
      if s\match p
        @emit s, ...

  clearPattern: (p) =>
    for s in pairs @signals
      if s\match p
        @clear s

  dropPattern: (p) =>
    for s in pairs @signals
      if s\match p
        @drop s

Signal