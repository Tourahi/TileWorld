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
    @layers = {}

    gid = 1
    for i, tileset in ipairs @tilesets
      assert tileset.image, "Tile Collections are not supported."
      if Graphics.isCreated
        formattedPath = formatPath(@dir .. tileset.image)

        if not @cache[formattedPath]
          @fixTransparentColor tileset, formattedPath
          @cacheImage formattedPath, tileset.image -- TODO: formattedPath no needed ??
        else
          tileset.image = @cache[formattedPath]
      -- SetTiles
      gid = @setTiles i, tileset, gid

    layers = {}
    for _, layer in ipairs @layers
      @groupAppendToList layers, layer

    @layers = layers

    for _, layer in ipairs @layers
      @setLayer layer, path


  setLayer: (layer, path) =>
    Data = love.data
    if layer.encoding
      if layer.encoding == "base64"
        assert(require "ffi", "Compressed maps require LuaJIT FFI.\nPlease Switch your interperator to LuaJIT or your Tile Layer Format to \"CSV\".")
        fd = Data.decode "string", "base64", layer.data

        if not layer.compression
          layer.data = @getDecompresedData fd
        else
          assert(Data.decompress, "zlib and gzip compression require LOVE 11.0+.\nPlease set your Tile Layer Format to \"Base64 (uncompressed)\" or \"CSV\".")

          if layer.compression == "zlib"
            data = Data.decompress "string", "zlib", fd
            layer.data = @getDecompresedData data

          if layer.compression == "gzip"
            data = Data.decompress "string", "gzip", fd
            layer.data = @getDecompresedData data

    layer.x = (layer.x or 0) + layer.offsetx + @offsetX
    layer.y = (layer.y or 0) + layer.offsety + @offsetY

    layer.update = ->

    if layer.type == "tilelayer"
      @setTileData layer



  setTileData: (layer) =>
    if layer.chunks
      for _, chunk in ipairs layer.chunks
        @setTileData chunk
      return

    i = 1
    map = {}

    for y = 1, layer.height
      map[y] = {}
      for x = 1, layer.width
        gid = layer.data[i]

        if gid > 0
          map[y][x] = @tiles[gid] or @setFlippedGID(gid)

        i += 1
    layer.data = map

  groupAppendToList: (layers, layer) =>
    if layer.type == "group"
      for _, groupLayer in pairs layer.layers
        groupLayer.name = layer.name .. "." .. groupLayer.name
        groupLayer.visible = layer.visible
        groupLayer.opacity = layer.opacity * groupLayer.opacity
        groupLayer.offsetx = layer.offsetx + groupLayer.offsetx
        groupLayer.offsety = layer.offsety + groupLayer.offsety

        for key, property in pairs layer.properties
          if groupLayer.properties[key] == nil
            groupLayer.properties[key] = property
        @groupAppendToList layers, groupLayer
    else
      table.insert layers, layer

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

  getTiles: (imgW, tileW, margin, spacing) =>
    imgW -= margin
    n = 0

    while imgW >= tileW
      imgW -= tileW
      if n ~= 0 then imgW -= spacing
      if imgW >= 0 then n += 1
    n

  setTiles: (idx, tileset, gid) =>
    quad = Graphics.newQuad
    imgW = tileset.imagewidth
    imgH = tileset.imageheight
    tileW = tileset.tilewidth
    tileH = tileset.tileheight
    margin = tileset.margin
    spacing = tileset.spacing
    w = @getTiles imgW, tileW, margin, spacing -- Number of tiles Horizontal
    h = @getTiles imgH, tileH, margin, spacing -- Number of tiles Vertical

    for y = 1, h
      for x = 1, w
        id = gid - tileset.firstgid
        quadX = (x - 1) * tileW + margin + (x - 1) * spacing
        quadY = (y - 1) * tileH + margin + (y - 1) * spacing
        type = ""
        properties, terrain, animation, objectGroup

        for _, tile in pairs tileset.tiles
          if tile.id == id
            properties = tile.properties
            animation = tile.animation
            objectGroup = tile.objectGroup
            type = tile.type

            if tile.terrain
              terrain = {}
              for i = 1, #tile.terrain
                terrain[i] = tileset.terrains[tile.terrain[i] + 1]

        tile = {
          id: id
          gid: gid
          tileset: idx
          type: type
          quad: quad(quadX, quadY, tileW, tileH, imgW, imgH)
          properties: properties or {}
          terrain: terrain
          animation: animation
          objectGroup: objectGroup
          frame: 1
          time: 0
          width: tileW
          height: tileH
          sx: 1
          sy: 1
          r: 0
          offset: tileset.tileoffset
        }

        @tiles[gid] = tile
        gid += 1
    gid

  getDecompresedData: (data) =>
    ffi = require "ffi"
    d = {}
    decoded = ffi.cast "uint32_t*", data

    for i = 0, data\len! / ffi.sizeof "uint32_t"
      table.insert d, tonumber(decoded[i])
    d

  setFlippedGID: (gid) =>
    bit31   = 2147483648
    bit30   = 1073741824
    bit29   = 536870912
    flipX   = false
    flipY   = false
    flipD   = false
    realgid = gid

    if realgid >= bit31
      realgid -= bit31
      flipX = not flipX

    if realgid >= bit30
      realgid -= bit30
      flipY = not flipY

    if realgid >= bit29
      realgid -= bit29
      flipD = not flipD

    tile = @tiles[realgid]
    data = {
      id: tile.id,
      gid: gid,
      tileset: tile.tileset,
      frame: tile.frame,
      time: tile.time,
      width: tile.width,
      height: tile.height,
      offset: tile.offset,
      quad: tile.quad,
      properties: tile.properties,
      terrain: tile.terrain,
      animation: tile.animation,
      sx: tile.sx,
      sy: tile.sy,
      r: tile.r,
    }

    if flipX
      if flipY and flipD
        data.r  = math.rad(-90)
        data.sy = -1
      elseif flipY
        data.sx = -1
        data.sy = -1
      elseif flipD
        data.r = math.rad(90)
      else
        data.sx = -1
    elseif flipY
      if flipD
        data.r = math.rad(-90)
      else
        data.sy = -1
    elseif flipD
      data.r  = math.rad(90)
      data.sy = -1

    @tiles[gid] = data
    @tiles[gid]





