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
    love.graphics.setDefaultFilter('nearest', 'nearest')

    export t = Tiler "tests/level2.lua"
    export input = Input!
    export width = love.graphics.getWidth!
    export height = love.graphics.getHeight!


    export camera = Camera 0, 0, nil, nil, 2, 0, t.width * t.tilewidth, t.height * t.tilewidth

    camera\setScale 2
    camera\setFollowStyle "LOCKED"
    camera\setFollowLerp 0.2
    camera.drawDeadzone = true

    input\bindArr {
      'right': 'right'
      'left': 'left'
      'up': 'up'
      'down': 'down'
      'f2': 'f2'
      'f4': 'f4'
      'l': 'l'
      's': 's'
      'f': 'f'
      'a': 'a'
      'b': 'b'
      'c': 'c'
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
    if input\pressed 'f'
      camera\flash(0.1, {1, 0, 0, 1})
    if input\pressed 's'
      camera\shake(8, 1, 60)
    if input\pressed 'a'
      camera\setFollowStyle "LOCKED"
    if input\pressed 'b'
      camera\setFollowStyle "PLATFORMER"
    if input\pressed 'c'
      camera\setFollowStyle "SCREEN_BY_SCREEN"
    if input\pressed 'l'
      Leak.report!
    Graphics = love.graphics



    camera\follow rec.x, rec.y
    camera\update dt


  .draw = ->
    Graphics = love.graphics
    camera\attachC nil, ->
      t\drawLayer t.layers["w"]
      t\drawLayer t.layers["sdq"]
      t\drawLayer t.layers["world"]
      love.graphics.rectangle "fill", rec.x, rec.y, 16, 16
    camera\draw!
    Graphics.setColor {1, 0, 0, 1}
    Graphics.printf "Camera Follow Style : " .. camera.followStyle, 20, 20, 10000
    Graphics.setColor {1, 1, 1, 1}




