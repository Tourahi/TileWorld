local Leak = { }
local globalTypeTable = nil
Leak.countAll = function(f)
  local seen = { }
  local countTable
  countTable = function(t)
    if seen[t] then
      return 
    end
    f(t)
    seen[t] = true
    for k, v in pairs(t) do
      if type(v) == "table" then
        countTable(v)
      elseif type(v) == "userdata" then
        f(v)
      end
    end
  end
  return countTable(_G)
end
Leak.typeCount = function()
  local counts = { }
  local enum
  enum = function(o)
    local t = Leak.typeName(o)
    counts[t] = (counts[t] or 0) + 1
  end
  Leak.countAll(enum)
  return counts
end
Leak.typeName = function(o)
  if globalTypeTable == nil then
    globalTypeTable = { }
    for k, v in pairs(_G) do
      globalTypeTable[v] = k
    end
    globalTypeTable[0] = "table"
  end
  return globalTypeTable[getmetatable(o) or 0] or "Unknown"
end
Leak.report = function(cb)
  if cb == nil then
    cb = nil
  end
  local counts = Leak.typeCount()
  if cb then
    print('--------------Object count-----------')
    for k, v in pairs(counts) do
      cb(k, v)
    end
    return print('-------------------------------------')
  else
    print('--------------Object count-----------')
    for k, v in pairs(counts) do
      print(k .. ' : ' .. v)
    end
    return print('-------------------------------------')
  end
end
return Leak
