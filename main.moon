csnap = (v, x) ->
  math.ceil(v/x) * x

rsnam = (v, x) ->
  math.floor(v/x) * x


with love
  .load = ->
    x = 10
    xw = 50
    print csnap(x, xw)
    print rsnam(5, 10)
