cwd = (...)\gsub('%.Tiler$', '') .. "."
Graphics = assert require cwd .. 'graphics'

formatPath = (p) ->
  np_gen1,np_gen2  = '[^SEP]+SEP%.%.SEP?','SEP+%.?SEP'
  np_pat1, np_pat2 = np_gen1\gsub('SEP','/'), np_gen2\gsub('SEP','/')
  k = nil

  while k ~= 0
		p,k = p\gsub(np_pat2,'/',1)

  while k ~= 0
    p,k = p\gsub(np_pat1,'',1)

  if p == '' then p = '.'
  p

TRANSPARENT_COLOR = {}

hexToColor = (hex) ->
  if hex\sub(1, 1) == "#"
    hex = hex\sub 2
  {
    r: tonumber(hex\sub(1, 2), 16) / 255
    g: tonumber(hex\sub(3, 4), 16) / 255
    b: tonumber(hex\sub(5, 6), 16) / 255
  }

class Tiler
  new: (path, plugins, ox, oy) =>

    if path.__class ~= nil and path.__class == Tiler
      @ = path
      return

    @dir = ""
    ext = path\sub -4, -1
    assert ext == ".lua", string.format("Invalid file type: %s. File must be of type: lua.", ext)

    @dir = path\reverse!\find("[/\\]") or ""
    if @dir ~= ""
      @dir = path\sub 1, 1 + (#path - @dir)

    -- Loading the map data directly to the class
    --print path
    data = assert love.filesystem.load(path)!
    for k, v in pairs data
      if not @[k]
          @[k] = v

    -- Initialize members

    if type(plugins) == "table"
      @loadPlugins plugins

    @resize!
    @width = nil
    @height = nil
    @objects = {}
    @tiles = {}
    @tileInstances = {}
    @drawRange = {
      sx: 1
      sy: 1
      ex: @width
      ey: @height
    }
    @offsetX = ox or 0
    @offsetY = oy or 0
    @cache = {}
    @freeBatchSprites = {}
    setmetatable @freeBatchSprites, { __mode: 'k' }

    gid = 1
    for i, tileset in ipairs @tilesets
      assert tileset.image, "Tile Collections are not supported."
      if Graphics.isCreated
        formattedPath = formatPath(@dir .. tileset.image)

        if not @cache[formattedPath]
          -- FIX TRASPARENT COLOR
          @fixTransparentColor tileset, formattedPath
          @cacheImage formattedPath
        else
          tileset.image = @cache[formattedPath]
      -- SetTiles



  pixelFunc: (_, _, r, g, b, a) ->
    mask = TRANSPARENT_COLOR
    if r == mask.r and g == mask.g and b == mask.b
      r, g, b, 0
    r, g, b, a

  fixTransparentColor:(tileset, path) =>
    limage = love.image
    imageData = limage.newImageData path

    if tileset.transparentColor
      TRANSPARENT_COLOR = hexToColor tileset.transparentColor
      imageData\mapPixel @pixelFunc
      tileset.image = Graphics.newImage imageData

  cacheImage: (formattedPath, img) =>
    if type(img) ~= "userdata"
      img = Graphics.newImage formattedPath
    img\setFilter "nearest", "nearest"
    @cache[formattedPath] = img

  loadPlugins: (plugins) =>
    for _, p in ipairs plugins
      pmp = cwd .. 'plugins.' .. p -- plugin Module Path
      ok, pm = pcall require, pmp
      if ok
        if pm.__class ~= nil
          @[p] = pm
        else
          for k, f in pairs pm
            if not @[k]
              @[k] = f
      else
        print "Plugin ".. p .. " does not exist. Make sure you add it to the plugins folder."


  resize: (w, h) =>
    if Graphics.isCreated
      w = w or Graphics.getWidth!
      h = h or Graphics.getHeight!
      -- canvas creation
      @canvas = Graphics.newCanvas w, h
      @canvas\setFilter "nearest", "nearest"
