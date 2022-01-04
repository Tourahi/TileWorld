Camera = assert require "Camera"
Input = assert require "Input"
Leak = assert require "Leak"
Tiler = assert require "Tiler"

rec = {
  x: 10,
  y: 10
}

cwd = (...)\gsub('%.Tiler$', '') .. "."


with love
  .load = ->
    print cwd
    t = Tiler "tests/ortho.lua", { "Camera" }
    export input = Input!
    export camera = t.Camera!
    camera\setFollowStyle('LOCKON')
    camera\setFollowLerp(0.2)
    camera\setFollowLead(0)
    input\bindArr {
      'right': 'right'
      'left': 'left'
      'up': 'up'
      'down': 'down'
      'f2': 'f2'
      'f4': 'f4'
      'l': 'l'
      's': 's'
      'return': 'enter'
      'escape': 'escape'
    }

  .update = (dt) ->
    if input\down "right"
      rec.x += 10
    if input\down "left"
      rec.x -= 10
    if input\down "up"
      rec.y -= 10
    if input\down "down"
      rec.y += 10
    if input\pressed 's'
      camera\shake(8, 1, 60)
    if input\pressed 'l'
      Leak.report!
    camera\update dt
    camera\follow rec.x, rec.y

  .draw = ->
    Graphics = love.graphics
    camera\attach!
    Graphics.rectangle 'fill', rec.x, rec.y, 20, 20
    Graphics.rectangle 'fill', 50, 50, 20, 20
    camera\detach!
    camera\draw!

