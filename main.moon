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

    export camera = Camera 0, 0, t.width * t.tilewidth, t.height * t.tileheight
    --export camera = Camera.new 0, 0, t.width * t.tilewidth, t.height * t.tileheight

    camera\setScale 2


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
      rec.x += 500 *dt
    if input\down "left"
      rec.x -= 500 *dt
    if input\down "up"
      rec.y -= 500 *dt
    if input\down "down"
      rec.y += 500 *dt
    if input\pressed 's'
      camera\shake(8, 1, 60)
    if input\pressed 'l'
      Leak.report!
    Graphics = love.graphics

    w = Graphics.getWidth!
    h = Graphics.getHeight!
    mapw = t.width * t.tilewidth
    maph = t.height * t.tileheight

    camera\follow rec.x, rec.y
    camera\update dt





  .draw = ->
    camera\draw ->
      t\drawLayers!
      love.graphics.rectangle "fill", rec.x, rec.y, 6, 6

    --camera\attachC t\getCanvas!, ->
      --t\drawLayer t.layers["world"]
      --love.graphics.rectangle "fill", rec.x, rec.y, 6, 6
    --camera\draw!

  .run = ->
    if love.load
      love.load(love.arg.parseGameArguments(arg), arg)

    -- We don't want the first frame's dt to include time taken by love.load.
    if love.timer
      love.timer.step!

    dt = 0
    fixedDt = 1/60
    acc = 0
    -- Main loop time.
    return () ->
      -- Process events.
      if love.event
        love.event.pump!
        for name, a,b,c,d,e,f in love.event.poll!
          if name == "quit"
            if not love.quit or not love.quit!
              return a or 0
          love.handlers[name] a,b,c,d,e,f

      -- Update dt, as we'll be passing it to update
      if love.timer
        dt = love.timer.step!
      -- Call update and draw
      acc += dt
      while acc >= fixedDt
        if love.update
          love.update fixedDt
        acc -= fixedDt

      if love.graphics and love.graphics.isActive!
        love.graphics.origin!
        love.graphics.clear love.graphics.getBackgroundColor!

        if love.draw
          love.draw!

        love.graphics.present!

      if love.timer
        love.timer.sleep 0.001


