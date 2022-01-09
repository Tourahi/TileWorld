local enum
enum = function(names, offset)
  if offset == nil then
    offset = 1
  end
  local objects = { }
  local size = 0
  for i, name in pairs(names) do
    local id = i + offset - 1
    local obj = {
      id = id,
      r_id = i,
      name = name
    }
    objects[name] = obj
    objects[id] = obj
    size = size + 1
  end
  objects.start = offset
  objects["end"] = offset + size - 1
  objects.size = size
end
return enum
