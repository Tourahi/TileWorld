local lg = _G.love.graphics
local graphics = {
  isCreated = lg and true or false
}
graphics.newSpriteBatch = function(...)
  if graphics.isCreated then
    return lg.newSpriteBatch(...)
  end
end
graphics.newCanvas = function(...)
  if graphics.isCreated then
    return lg.newCanvas(...)
  end
end
graphics.newImage = function(...)
  if graphics.isCreated then
    return lg.newImage(...)
  end
end
graphics.newQuad = function(...)
  if graphics.isCreated then
    return lg.newQuad(...)
  end
end
graphics.getCanvas = function(...)
  if graphics.isCreated then
    return lg.getCanvas(...)
  end
end
graphics.setCanvas = function(...)
  if graphics.isCreated then
    return lg.setCanvas(...)
  end
end
graphics.clear = function(...)
  if graphics.isCreated then
    return lg.clear(...)
  end
end
graphics.push = function(...)
  if graphics.isCreated then
    return lg.push(...)
  end
end
graphics.origin = function(...)
  if graphics.isCreated then
    return lg.origin(...)
  end
end
graphics.scale = function(...)
  if graphics.isCreated then
    return lg.scale(...)
  end
end
graphics.translate = function(...)
  if graphics.isCreated then
    return lg.translate(...)
  end
end
graphics.pop = function(...)
  if graphics.isCreated then
    return lg.pop(...)
  end
end
graphics.draw = function(...)
  if graphics.isCreated then
    return lg.draw(...)
  end
end
graphics.rectangle = function(...)
  if graphics.isCreated then
    return lg.rectangle(...)
  end
end
graphics.getColor = function(...)
  if graphics.isCreated then
    return lg.getColor(...)
  end
end
graphics.setColor = function(...)
  if graphics.isCreated then
    return lg.setColor(...)
  end
end
graphics.line = function(...)
  if graphics.isCreated then
    return lg.line(...)
  end
end
graphics.polygon = function(...)
  if graphics.isCreated then
    return lg.polygon(...)
  end
end
graphics.points = function(...)
  if graphics.isCreated then
    return lg.points(...)
  end
end
graphics.getWidth = function()
  if graphics.isCreated then
    return lg.getWidth()
  end
  return 0
end
graphics.getHeight = function()
  if graphics.isCreated then
    return lg.getHeight()
  end
  return 0
end
return graphics
