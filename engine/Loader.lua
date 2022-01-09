local la, lf, lg = love.audio, love.filesystem, love.graphics
local newSound
newSound = function(path)
  assert(type(path) == 'string', "The path must be a <string>. [newSound]")
  local info = lf.getInfo(path, 'file')
  return la.newSource(path, (info and info.size and info.size < 5e5) and 'static' or 'stream')
end
local newFont
newFont = function(path)
  assert(type(path) == 'string', "The path must be a <string>. [newFont]")
  return function(size)
    return lg.newFont(path, size)
  end
end
local loadFile
loadFile = function(path)
  assert(type(path) == 'string', "The path must be a <string>. [loadFile]")
  return lf.load(path)()
end
local tmerge
tmerge = function(target, src, ...)
  if target == nil then
    target = nil
  end
  if src == nil then
    src = nil
  end
  if target == nil or src == nil then
    return target
  end
  for k, v in pairs(src) do
    target[k] = v
  end
  return tmerge(target, ...)
end
local removeExt
removeExt = function(key)
  return key:gsub('%..-$', '')
end
local getExt
getExt = function(file)
  return file:match("[^.]+$")
end
local _loaders = {
  lua = lf and loadFile,
  png = lg and lg.newImage,
  jpg = lg and lg.newImage,
  jpeg = lg and lg.newImage,
  dds = lg and lg.newImage,
  ogv = lg and lg.newVideo,
  glsl = lg and lg.newShader,
  mp3 = la and newSound,
  ogg = la and newSound,
  wav = la and newSound,
  flac = la and newSound,
  txt = lf and lf.read,
  ttf = lg and newFont,
  otf = lg and newFont,
  fnt = lg and lg.newFont
}
local _processors = { }
local _extProcessors = { }
local Loader
do
  local _class_0
  local _base_0 = {
    load = function(self, dir, tab, rec)
      if rec == nil then
        rec = false
      end
      for _, f in ipairs(lf.getDirectoryItems(dir)) do
        local key = removeExt(f)
        local ext = getExt(f)
        local path = (dir .. '/' .. f):gsub('^/+', '')
        if lf.getInfo(path).type == 'file' then
          for extension, loader in pairs(_loaders) do
            if extension == ext then
              local asset = loader(path)
              rawset(tab, key, asset)
              for pt, proc in pairs(_processors) do
                if path:match(pt) then
                  proc(asset, path, self)
                end
              end
              for ext, proc in pairs(_extProcessors) do
                if ext == extension then
                  proc(asset, path, self)
                end
              end
            end
          end
        elseif lf.getInfo(path).type == 'directory' and rec then
          rawset(tab, f, { })
          self:load(dir .. '/' .. f, tab[f], rec, self.depth)
        end
      end
    end
  }
  _base_0.__index = _base_0
  _class_0 = setmetatable({
    __init = function(self, c, rec)
      if c == nil then
        c = nil
      end
      if type(c) == 'string' then
        self.path = c
        c = nil
      else
        self.path = c.dir
      end
      rawset(self, self.path, { })
      if c then
        _loaders = tmerge({ }, _loaders, c.loaders)
        _processors = tmerge({ }, { }, c.processors)
        _extProcessors = tmerge({ }, { }, c.extProcessors)
      else
        _processors = { }
        _extProcessors = { }
      end
      return self:load(self.path, self[self.path], rec)
    end,
    __base = _base_0,
    __name = "Loader"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  Loader = _class_0
  return _class_0
end
