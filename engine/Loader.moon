-- Assets loader
-- Based on cargo.lua
-- improved and adapted to use moonscript class system.
la, lf, lg = love.audio, love.filesystem, love.graphics

newSound = (path) ->
  assert type(path) == 'string', "The path must be a <string>. [newSound]"
  info = lf.getInfo path, 'file'
  la.newSource path, (info and info.size and info.size < 5e5) and 'static' or 'stream'

newFont = (path) ->
  assert type(path) == 'string', "The path must be a <string>. [newFont]"
  return (size) ->
    lg.newFont path, size

loadFile = (path) ->
  assert type(path) == 'string', "The path must be a <string>. [loadFile]"
  lf.load(path)!

tmerge = (target = nil, src = nil, ...) ->
  if target == nil or src == nil
    return target
  for k, v in pairs(src) do target[k] = v
  tmerge target, ...

removeExt = (key) ->
  return key\gsub '%..-$', ''

getExt = (file) ->
  return file\match("[^.]+$")

_loaders = {
  lua: lf and loadFile
  png: lg and lg.newImage
  jpg: lg and lg.newImage
  jpeg: lg and lg.newImage
  dds: lg and lg.newImage
  ogv: lg and lg.newVideo
  glsl: lg and lg.newShader
  mp3: la and newSound
  ogg: la and newSound
  wav: la and newSound
  flac: la and newSound
  txt: lf and lf.read
  ttf: lg and newFont
  otf: lg and newFont
  fnt: lg and lg.newFont
}

_processors = {}
_extProcessors = {}

class Loader
  -- c: config
  new: (c = nil, rec) =>
    if type(c) == 'string'
      @path = c
      c = nil
    else
      @path = c.dir

    rawset self, @path, {}

    if c
      _loaders = tmerge {}, _loaders, c.loaders
      _processors = tmerge {}, {}, c.processors
      _extProcessors = tmerge {}, {}, c.extProcessors
    else
      _processors = {}
      _extProcessors = {}

    @load @path, self[@path], rec

  load: (dir, tab, rec = false) =>
    for _, f in ipairs lf.getDirectoryItems dir
      key = removeExt(f)
      ext = getExt(f)
      path = (dir .. '/' .. f)\gsub '^/+', ''
      if lf.getInfo(path).type == 'file'
        for extension, loader in pairs _loaders
          if extension == ext
            asset = loader(path)
            rawset tab, key, asset
            for pt, proc in pairs _processors
              if path\match pt
                proc asset, path, self
            for ext, proc in pairs _extProcessors
              if ext == extension
                proc asset, path, self
      elseif lf.getInfo(path).type == 'directory' and rec
        rawset tab, f, {}
        @load dir..'/'..f, tab[f], rec, @depth
