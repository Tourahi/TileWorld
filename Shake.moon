import getTime from love.timer

random = (min, max) ->
    min, max = min or 0, max or 1
    return (min > max and (love.math.random()*(min - max) + max)) or (love.math.random()*(max - min) + min)

class Shake
  new: (amp, freq, dur)=>
    @amp = amp
    @freq = freq
    @dur = dur
    sample_count = (@dur/1000)*freq
    @samples = {}
    for i = 1, sample_count
      @samples[i] = random(-1, 1)

    @startTime = love.timer.getTime()*1000
    @t = 0
    @shaking = true

  update: (dt) =>
    @t = love.timer.getTime()*1000 - @startTime
    if @t > @dur
      @shaking = false

  getAmplitude: (t) =>
    if not t then
        if not @shaking
          return 0
        t = @t

    s = (t/1000)*@freq
    s0 = math.floor(s)
    s1 = s0 + 1
    k = @decay(t)
    @amp*(@noise(s0) + (s - s0)*(@noise(s1) - @noise(s0)))*k


  decay: (t) =>
    if t > @dur
      return 0
    return (@dur - t)/@dur

  noise: (s) =>
    if s >= #@samples
      return 0
    return @samples[s] or 0

  isShaking: =>
    @shaking


Shake
