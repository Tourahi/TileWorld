

enum = (names, offset = 1) ->
  objects = {}
  size = 0
  for i, name in pairs names
    id = i + offset - 1
    obj = {
      id: id
      r_id: i
      name: name
    }

    objects[name] = obj
    objects[id] = obj
    size += 1
  
  objects.start  = offset
  objects.end  = offset + size - 1
  objects.size = size

  








return enum