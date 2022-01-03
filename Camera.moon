Shake = assert require "Shake"


class Camera
  new: (x, y, w, h, scale, rot) =>
    Graphics = love.graphics
    @x = x or (w or Graphics.getWidth! / 2)
    @y = x or (h or Graphics.getHeight! / 2)
    @mx = @x
    @my = @y
    @screenX = @x
    @screenY = @y
    @w = w or Graphics.getWidth!
    @h = h or Graphics.getHeight!
    @scale = scale or 1
    @rot = rot or 0














-- Utils
csnap = (v, x) -> math.ceil(v/x) * x - x/2
lerp = (a, b, x) -> a + (b - a) * x



--lerp
