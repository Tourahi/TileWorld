Camera = assert require "Camera"
Input = assert require "Input"
Leak = assert require "Leak"

Tiler = assert require "Tiler"
M = assert require 'moon'
export Dump = M.p

rec = {
  x: 10,
  y: 10
}

cwd = (...)\gsub('%.Tiler$', '') .. "."


with love
  .load = ->
    print cwd
    export t = Tiler "tests/level1.lua"
    export input = Input!
    export width = love.graphics.getWidth!
    export height = love.graphics.getHeight!

    export camera = Camera width/2 + 50, height/2 + 50, height
    camera\setDeadzone 40, height/2 - 40, width - 80, 80
    camera\setFollowStyle('TOPDOWN')
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
    t\update dt
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
    t\draw!


