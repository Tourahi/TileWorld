


csnap = (v, x) ->
  math.ceil(v/x) * x - x/2


with love
  .load = ->
    print csnap(10, 2)
