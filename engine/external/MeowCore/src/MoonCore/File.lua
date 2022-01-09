local readFile
readFile = function(file)
  local f = io.open(file, "r")
  if not (f) then
    return 
  end
  local output = f:read('*a')
  f:close()
  return output
end
local writeFile
writeFile = function(file, data, append)
  if append == nil then
    append = false
  end
  local f = { }
  if append then
    f = io.open(file, "a")
  else
    f = io.open(file, "w")
  end
  if not (f) then
    return 
  end
  f:write(data)
  f:close()
  return true
end
local findFile
findFile = function(path)
  local isFile
  isFile = function(fileName)
    local attributes
    attributes = require('lfs').attributes
    local f = attributes(fileName)
    if not (f and f.mode == 'file') then
      return false
    end
    return true
  end
  if isFile(path) then
    return path
  end
end
return {
  readFile = readFile,
  writeFile = writeFile,
  findFile = findFile
}
