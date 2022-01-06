Camera = assert require "Camera"
Input = assert require "Input"
Leak = assert require "Leak"

Tiler = assert require "Tiler"
M = assert require 'moon'
export Dump = M.p

rec = {
  x: 100,
  y: 100
}

cwd = (...)\gsub('%.Tiler$', '') .. "."


with love
  .load = ->
    print cwd
    export t = Tiler "tests/level2.lua"
    export input = Input!
    export width = love.graphics.getWidth!
    export height = love.graphics.getHeight!

    export camera = Camera!

    camera\setFollowStyle('PLATFORMER')
    camera\setFollowLerp(0.2)
    camera\setScale 3



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
    t\update dt
    if input\down "right"
      rec.x += 300 * dt
    if input\down "left"
      rec.x -= 300 * dt
    if input\down "up"
      rec.y -= 300 * dt
    if input\down "down"
      rec.y += 300 * dt
    if input\pressed 's'
      camera\shake(8, 1, 60)
    if input\pressed 'l'
      Leak.report!
    camera\update dt
    camera\follow rec.x, rec.y




  .draw = ->
    --camera\attach!
    --t\drawLayers!
    --love.graphics.rectangle "fill", rec.x, rec.y, 6, 6
    --camera\detach!

    camera\attachC t\getCanvas!, ->
      t\drawLayers!
      love.graphics.rectangle "fill", rec.x, rec.y, 6, 6


