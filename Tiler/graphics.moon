lg = _G.love.graphics

graphics = {
  isCreated: lg and true or false
}

graphics.newSpriteBatch = (...) ->
	if graphics.isCreated then
		return lg.newSpriteBatch(...)



graphics.newCanvas = (...) ->
	if graphics.isCreated then
		return lg.newCanvas(...)



graphics.newImage = (...) ->
	if graphics.isCreated then
		return lg.newImage(...)



graphics.newQuad = (...) ->
	if graphics.isCreated then
		return lg.newQuad(...)



graphics.getCanvas = (...) ->
	if graphics.isCreated then
		return lg.getCanvas(...)



graphics.setCanvas = (...) ->
	if graphics.isCreated then
		return lg.setCanvas(...)



graphics.clear = (...) ->
	if graphics.isCreated then
		return lg.clear(...)



graphics.push = (...) ->
	if graphics.isCreated then
		return lg.push(...)



graphics.origin = (...) ->
	if graphics.isCreated then
		return lg.origin(...)



graphics.scale = (...) ->
	if graphics.isCreated then
		return lg.scale(...)



graphics.translate = (...) ->
	if graphics.isCreated then
		return lg.translate(...)



graphics.pop = (...) ->
	if graphics.isCreated then
		return lg.pop(...)



graphics.draw = (...) ->
	if graphics.isCreated then
		return lg.draw(...)



graphics.rectangle = (...) ->
	if graphics.isCreated then
		return lg.rectangle(...)



graphics.getColor = (...) ->
	if graphics.isCreated then
		return lg.getColor(...)



graphics.setColor = (...) ->
	if graphics.isCreated then
		return lg.setColor(...)



graphics.line = (...) ->
	if graphics.isCreated then
		return lg.line(...)



graphics.polygon = (...) ->
	if graphics.isCreated then
		return lg.polygon(...)



graphics.points = (...) ->
	if graphics.isCreated then
		return lg.points(...)



graphics.getWidth = () ->
	if graphics.isCreated then
		return lg.getWidth!
	return 0


graphics.getHeight = () ->
	if graphics.isCreated then
		return lg.getHeight!
	return 0

graphics
