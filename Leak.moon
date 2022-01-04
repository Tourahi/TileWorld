Leak = {}

globalTypeTable = nil

Leak.countAll = (f) ->
  seen = {}
  countTable = (t) ->
    if seen[t] then return
    f(t)
    seen[t] = true
    for k, v in pairs t
      if type(v) == "table"
        countTable v
      elseif type(v) == "userdata"
        f(v)
  countTable _G

Leak.typeCount = ->
  counts = {}
  enum = (o) ->
    t = Leak.typeName o
    counts[t] = (counts[t] or 0) + 1
  Leak.countAll enum
  counts
    

Leak.typeName = (o) ->
  if globalTypeTable == nil
    globalTypeTable = {}
    for k, v in pairs _G
      globalTypeTable[v] = k
    globalTypeTable[0] = "table"
  globalTypeTable[getmetatable(o) or 0] or "Unknown"


Leak.report = (cb = nil) ->
  counts = Leak.typeCount!
  if cb
    print '--------------Object count-----------'
    for k, v in pairs counts 
      cb k, v
    print '-------------------------------------'
  else
    print '--------------Object count-----------'
    for k, v in pairs counts 
      print k .. ' : ' .. v
    print '-------------------------------------'

Leak