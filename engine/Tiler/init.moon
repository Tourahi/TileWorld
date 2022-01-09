cwd = (...)\gsub('%.engine$', '') .. "."
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

convertIsometricToScreen = (map, x, y) =>
  mapW    = map.width
  tileW   = map.tilewidth
  tileH   = map.tileheight
  tileX   = x / tileH
  tileY   = y / tileH
  offsetX = mapW * tileW / 2
  return (tileX - tileY) * tileW / 2 + offsetX, (tileX + tileY) * tileH / 2

rotateVertex = (map, vertex, x, y, cos, sin, oy) ->
  if map.orientation == "isometric"
    x, y               = convertIsometricToScreen(map, x, y)
    vertex.x, vertex.y = convertIsometricToScreen(map, vertex.x, vertex.y)

  vertex.x = vertex.x - x
  vertex.y = vertex.y - y

  return x + cos * vertex.x - sin * vertex.y, y + sin * vertex.x + cos * vertex.y - (oy or 0)


compensate = (tile, tileX, tileY, tileW, tileH) ->
  compx = 0
  compy = 0

  if tile.sx < 0 then compx = tileW
  if tile.sy < 0 then compy = tileH

  if tile.r > 0
    tileX = tileX + tileH - compy
    tileY = tileY + tileH + compx - tileW
  elseif tile.r < 0
    tileX = tileX + compy
    tileY = tileY - compx + tileH
  else
    tileX = tileX + compx
    tileY = tileY + compy

  tileX, tileY


convertEllipseToPolygon = (x, y, w, h, max_segments) ->
  ceil = math.ceil
  cos  = math.cos
  sin  = math.sin

  calc_segments = (segments) ->
    vdist = (a, b) ->
      c = {
				x: a.x - b.x,
				y: a.y - b.y,
			}

      c.x * c.x + c.y * c.y


    segments = segments or 64
    vertices = {}

    v = { 1, 2, ceil(segments/4-1), ceil(segments/4) }

    local m
    if love and love.physics
      m = love.physics.getMeter!
    else
      m = 32

    for _, i in ipairs(v)
      angle = (i / segments) * math.pi * 2
      px    = x + w / 2 + cos(angle) * w / 2
      py    = y + h / 2 + sin(angle) * h / 2
      table.insert(vertices, { x: px / m, y: py / m })

    dist1 = vdist(vertices[1], vertices[2])
    dist2 = vdist(vertices[3], vertices[4])

    -- Box2D threshold
    if dist1 < 0.0025 or dist2 < 0.0025
      calc_segments(segments-2)
    segments


  segments = calc_segments(max_segments)
  vertices = {}

  table.insert vertices, { x: x + w / 2, y: y + h / 2 }

  for i = 0, segments
    angle = (i / segments) * math.pi * 2
    px    = x + w / 2 + cos(angle) * w / 2
    py    = y + h / 2 + sin(angle) * h / 2

    table.insert(vertices, { x: px, y: py })

  vertices



-- TILER CLASS


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
    @objects = {}
    @tiles = {}
    @tileInstances = {}
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
      @setSpriteBatches layer
      layer.draw = -> @drawTileLayer layer
    elseif layer.type == "objectgroup"
      @setObjectData layer
      @setObjectCoordinates layer
      @setObjectSpriteBatches layer
      layer.draw = -> @drawObjectLayer layer
    elseif layer.type == "imagelayer"
      layer.draw = -> @drawImageLayer layer

      if layer.image ~= "" then
        formattedPath = formatPath(@dir .. layer.image)
        if not @cache[formattedPath] then
          @cacheImage(formattedPath)

        layer.image  = @cache[formattedPath]
        layer.width  = layer.image\getWidth!
        layer.height = layer.image\getHeight!

    @layers[layer.name] = layer


  setObjectSpriteBatches: (layer) =>
    newBatch = Graphics.newSpriteBatch
    batches  = {}

    if layer.draworder == "topdown"
      table.sort(layer.objects, (a, b) ->
        a.y + a.height < b.y + b.height
      )

    for _, object in ipairs(layer.objects)
      if object.gid
        tile    = @tiles[object.gid] or self\setFlippedGID(object.gid)
        tileset = tile.tileset
        image   = @tilesets[tileset].image

        batches[tileset] = batches[tileset] or newBatch(image)

        sx = object.width  / tile.width
        sy = object.height / tile.height

        -- Tiled rotates around bottom left corner, where love2D rotates around top left corner
        ox = 0
        oy = tile.height

        batch = batches[tileset]
        tileX = object.x + tile.offset.x
        tileY = object.y + tile.offset.y
        tileR = math.rad(object.rotation)

        -- Compensation for scale/rotation shift
        if tile.sx == -1
          tileX = tileX + object.width

          if tileR ~= 0
            tileX = tileX - object.width
            ox = ox + tile.width



        if tile.sy == -1
          tileY = tileY - object.height

          if tileR ~= 0
            tileY = tileY + object.width
            oy = oy - tile.width

        instance = {
          id: batch\add(tile.quad, tileX, tileY, tileR, tile.sx * sx, tile.sy * sy, ox, oy),
          batch: batch,
          layer: layer,
          gid: tile.gid,
          x: tileX,
          y: tileY - oy,
          r: tileR,
          oy: oy
        }

        @tileInstances[tile.gid] = @tileInstances[tile.gid] or {}
        table.insert(@tileInstances[tile.gid], instance)

    layer.batches = batches


  getLayerTilePosition: (layer, tile, x, y) =>
    tileW = @tilewidth
    tileH = @tileheight
    local tileX, tileY

    if @orientation == "orthogonal"
      tileset = @tilesets[tile.tileset]
      tileX = (x - 1) * tileW + tile.offset.x
      tileY = (y - 0) * tileH + tile.offset.y - tileset.tileheight
      tileX, tileY = compensate(tile, tileX, tileY, tileW, tileH)
    elseif @orientation == "isometric"
      tileX = (x - y) * (tileW / 2) + tile.offset.x + layer.width * tileW / 2 - @tilewidth / 2
      tileY = (x + y - 2) * (tileH / 2) + tile.offset.y
    else
      sideLen = @hexsidelength or 0
      if @staggeraxis == "y"
        if @staggerindex == "odd"
          if y % 2 == 0
            tileX = (x - 1) * tileW + tileW / 2 + tile.offset.x
          else
            tileX = (x - 1) * tileW + tile.offset.x
        else
          if y % 2 == 0
            tileX = (x - 1) * tileW + tile.offset.x
          else
            tileX = (x - 1) * tileW + tileW / 2 + tile.offset.x

        rowH = tileH - (tileH - sideLen) / 2
        tileY = (y - 1) * rowH + tile.offset.y
      else
        if @staggerindex == "odd"
          if x % 2 == 0
            tileY = (y - 1) * tileH + tileH / 2 + tile.offset.y
          else
            tileY = (y - 1) * tileH + tile.offset.y
        else
          if x % 2 == 0
            tileY = (y - 1) * tileH + tile.offset.y
          else
            tileY = (y - 1) * tileH + tileH / 2 + tile.offset.y

        colW = tileW - (tileW - sideLen) / 2
        tileX = (x - 1) * colW + tile.offset.x

    tileX, tileY


  setSpriteBatches: (layer) =>
    if layer.chunks
      for _, chunk in ipairs(layer.chunks)
        @setBatches(layer, chunk)
      return

    @setBatches layer


  addNewLayerTile: (layer, chunk, tile, x, y) =>
    tileset = tile.tileset
    img = @tilesets[tileset].image
    local batches, size

    if chunk
      batches = chunk.batches
      size = chunk.width * chunk.height
    else
      batches = layer.batches
      size = layer.width * layer.height

    batches[tileset] = batches[tileset] or Graphics.newSpriteBatch img, size

    batch = batches[tileset]
    tileX, tileY = @getLayerTilePosition layer, tile, x, y

    instance = {
      layer: layer
      chunk: chunk
      gid: tile.gid
      x: tileX
      y: tileY
      r: tile.r
      oy: 0
    }

    if batch
      instance.batch = batch
      instance.id = batch\add tile.quad, tileX, tileY, tile.r, tile.sx, tile.sy

    @tileInstances[tile.gid] = @tileInstances[tile.gid] or {}
    table.insert @tileInstances[tile.gid], instance

  setBatches: (layer, chunk) =>
    if chunk
      chunk.batches = {}
    else
      layer.batches = {}

    if @orientation == "orthogonal" or @orientation == "isometric"
      offsetX = chunk and chunk.x or 0
      offsetY = chunk and chunk.y or 0

      startX = 1
      startY = 1
      endX = chunk and chunk.width or layer.width
      endY = chunk and chunk.height or layer.height
      incX = 1
      incY = 1

      -- Oder of adding tiles to sprite batch
      if @renderorder == "right-up"
        startY, endY, incY = endY, startY, -1
      elseif @renderorder == "left-down"
        startX, endX, incX = endX, startX, -1
      elseif @renderorder == "left-up"
        startX, endX, incX = endX, startX, -1
        startY, endY, incY = endY, startY, -1

      for y = startY, endY, incY
        for x = startX, endX, incX
          local tile
          if chunk
            tile = chunk.data[y][x]
          else
            tile = layer.data[y][x]

          if tile
            @addNewLayerTile layer, chunk, tile, x + offsetX, y + offsetY
    else
      if @staggeraxis == "y"
        for y = 1, (chunk and chunk.height or layer.height)
          for x = 1, (chunk and chunk.width or layer.width)
            local tile
            if chunk
              tile = chunk.data[y][x]
            else
              tile = layer.data[y][x]

            if tile
              @addNewLayerTile layer, chunk, tile, x, y
      else
        i = 0
        local _x

        if @staggerindex == "odd"
          _x = 1
        else
          _x = 2

        floor = math.floor
        -- print chunk.width, layer.width
        while i < (chunk and chunk.width * chunk.height or layer.width * layer.height)
          for _y = 1, (chunk and chunk.height or layer.height) + 0.5, 0.5
            y = floor _y

            for x = _x, (chunk and chunk.width or layer.width), 2
              i += 1

              local tile
              if chunk
                tile = chunk.data[y][x]
              else
                tile = layer.data[y][x]

              if tile
                @addNewLayerTile layer, chunk, tile, x, y

              if _x == 1
                _x = 2
              else
                _x = 1


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
    tileset.image = Graphics.newImage imageData

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
        local properties, terrain, animation, objectGroup

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

  setObjectCoordinates: (layer) =>
    for _, object in ipairs(layer.objects)
      x   = layer.x + object.x
      y   = layer.y + object.y
      w   = object.width
      h   = object.height
      cos = math.cos(math.rad(object.rotation))
      sin = math.sin(math.rad(object.rotation))

      if object.shape == "rectangle" and not object.gid
        object.rectangle = {}

        vertices = {
          { x: x,     y: y     }
          { x: x + w, y: y     }
          { x: x + w, y: y + h }
          { x: x,     y: y + h }
        }

        for _, vertex in ipairs(vertices)
          vertex.x, vertex.y = rotateVertex(self, vertex, x, y, cos, sin)
          table.insert(object.rectangle, { x: vertex.x, y: vertex.y })

      elseif object.shape == "ellipse"
        object.ellipse = {}
        vertices = convertEllipseToPolygon(x, y, w, h)

        for _, vertex in ipairs(vertices)
          vertex.x, vertex.y = rotateVertex(self, vertex, x, y, cos, sin)
          table.insert(object.ellipse, { x: vertex.x, y: vertex.y })

      elseif object.shape == "polygon"
        for _, vertex in ipairs(object.polygon)
          vertex.x           = vertex.x + x
          vertex.y           = vertex.y + y
          vertex.x, vertex.y = rotateVertex(self, vertex, x, y, cos, sin)

      elseif object.shape == "polyline"
        for _, vertex in ipairs(object.polyline)
          vertex.x           = vertex.x + x
          vertex.y           = vertex.y + y
          vertex.x, vertex.y = rotateVertex(self, vertex, x, y, cos, sin)


  setObjectData: (layer) =>
    for _, object in ipairs(layer.objects)
      object.layer            = layer
      @objects[object.id] = object

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


  drawLayer: (layer) =>
    r,g,b,a = Graphics.getColor()
    Graphics.setColor(r, g, b, a * layer.opacity)
    layer\draw!
    Graphics.setColor(r,g,b,a)

  drawTileLayer: (layer) =>
    if type(layer) == "string" or type(layer) == "number"
		  layer = @layers[layer]
    assert(layer.type == "tilelayer", "Invalid layer type: " .. layer.type .. ". Layer must be of type: tilelayer")

    if layer.chunks
      for _, chunk in ipairs(layer.chunks)
        for _, batch in pairs(chunk.batches)
          Graphics.draw batch, 0, 0
      return

    floor = math.floor
    for _, batch in pairs(layer.batches)
      Graphics.draw(batch, floor(layer.x), floor(layer.y))


  drawObjectLayer: (layer) =>
    if type(layer) == "string" or type(layer) == "number"
		  layer = @layers[layer]

    assert(layer.type == "objectgroup", "Invalid layer type: " .. layer.type .. ". Layer must be of type: objectgroup")

    line  = { 160, 160, 160, 255 * layer.opacity       }
    fill  = { 160, 160, 160, 255 * layer.opacity * 0.5 }
    r,g,b,a = Graphics.getColor()
    reset = {   r,   g,   b,   a * layer.opacity       }

    sortVertices = (obj) ->
      vertex = {}
      for _, v in ipairs(obj)
        table.insert(vertex, v.x)
        table.insert(vertex, v.y)

      vertex


    drawShape = (obj, shape) ->
      vertex = sortVertices(obj)

      if shape == "polyline"
        Graphics.setColor(line)
        Graphics.line(vertex)
        return
      elseif shape == "polygon"
        Graphics.setColor(fill)
        if not love.math.isConvex(vertex)
          triangles = love.math.triangulate(vertex)
          for _, triangle in ipairs(triangles)
            Graphics.polygon("fill", triangle)
        else
          Graphics.polygon("fill", vertex)
      else
        Graphics.setColor(fill)
        Graphics.polygon("fill", vertex)

      Graphics.setColor(line)
      Graphics.polygon("line", vertex)

    for _, object in ipairs(layer.objects)
      if object.visible
        if object.shape == "rectangle" and not object.gid
          drawShape(object.rectangle, "rectangle")
        elseif object.shape == "ellipse"
          drawShape(object.ellipse, "ellipse")
        elseif object.shape == "polygon"
          drawShape(object.polygon, "polygon")
        elseif object.shape == "polyline"
          drawShape(object.polyline, "polyline")
        elseif object.shape == "point"
          Graphics.points(object.x, object.y)

    Graphics.setColor(reset)
    for _, batch in pairs(layer.batches)
      Graphics.draw(batch, 0, 0)

    Graphics.setColor(r,g,b,a)


  drawImageLayer: (layer) =>
    if type(layer) == "string" or type(layer) == "number"
      layer = @layers[layer]

    assert(layer.type == "imagelayer", "Invalid layer type: " .. layer.type .. ". Layer must be of type: imagelayer")

    if layer.image ~= ""
      Graphics.draw(layer.image, layer.x, layer.y)


  update: (dt) =>
    for _, tile in pairs @tiles
      update = false

      if tile.animation
        tile.time += dt * 1000
        while tile.time > tonumber(tile.animation[tile.frame].duration)
          update = true
          tile.time -= tonumber(tile.animation[tile.frame].duration)
          tile.frame += 1

          if tile.frame > #tile.animation then tile.frame = 1

        if update and @tileInstances[tile.gid]
          for _, j in pairs @tileInstances[tile.gid]
            t = @tiles[tonumber(tile.animation[tile.frame].tileid) + @tilesets[tile.tileset].firstgid]
            j.bash\set j.id, t.quad, j.x, j.y, j.r, tile.sx, tile.sy, 0, j.oy

    for _, layer in ipairs @layers
      layer\update dt

  draw: (tx, ty, sx, sy) =>
    cCanvas = Graphics.getCanvas!
    Graphics.setCanvas @canvas
    Graphics.clear!

    Graphics.push!
    Graphics.origin!
    Graphics.translate(math.floor(tx or 0), math.floor(ty or 0))

    for _, layer in ipairs @layers
      if layer.visible and layer.opacity > 0
        @drawLayer layer

    Graphics.pop!

    Graphics.push!
    Graphics.origin!
    Graphics.scale(sx or 1, sy or sx or 1)

    Graphics.setCanvas cCanvas
    Graphics.draw @canvas

    Graphics.pop!

  getCanvas: =>
    @canvas

  -- Use this for drawing if you are usign a camera
  drawLayers: =>
    for _, layer in ipairs @layers
          if layer.visible and layer.opacity > 0
            @drawLayer layer

  addCustomLayer: (name, idx = @layers + 1) =>
    layer = {
      type: "customlayer"
      name: name
      visible: true
      opacity: 1
      properties: {}
    }

    layer.draw = ->
    layer.update = ->

    table.insert @layers, idx, layer
    @layers[name] = @layers[idx]

    layer

  convertToCustomLayer: (idx) =>
    layer = assert @layers[idx], "Layer not found: " .. idx

    layer.type     = "customlayer"
    layer.x        = nil
    layer.y        = nil
    layer.width    = nil
    layer.height   = nil
    layer.encoding = nil
    layer.data     = nil
    layer.chunks   = nil
    layer.objects  = nil
    layer.image    = nil

    layer.draw = ->
    layer.update = ->

    layer

  removeLayer: (idx) =>
    layer = assert @layers[idx], "Layer not found: " .. idx

    if type(idx) == "string"
      for i, l in ipairs @layers
        if l.name == idx
          table.remove(@layers, i)
          @layers[idx] = nil
          break

      name = @layers[idx].name
      table.remove(@layers, idx)
      @layers[name] = nil

    if layer.batches
	  	for _, batch in pairs(layer.batches)
			  @freeBatchSprites[batch] = nil

    if layer.chunks
      for _, chunk in ipairs layer.chunks
        for _, batch in pairs chunk.batches
          @freeBatchSprites[batch] = nil

    if layer.type == "tilelayer"
      for _, tiles in pairs @tileInstances
        for i = #tiles, 1, -1
          tile = tiles[i]
          if tile.layer == layer
            table.remove(tiles, i)

    if layer.objects
      for i, object in pairs @objects
        if object.layer == layer
          @objects[i] = nil


  getLayerProperties: (layer) =>
    l = @layers[layer]

    if not l
      return {}

    l.properties

  getTileProperties: (layer, x, y) =>
    tile = @layers[layer].data[y][x]

    if not tile
      return {}

    tile.properties

  swapTile: (instance, tile) =>

    if instance.batch
      if tile
        instance.batch\set(
          instance.id,
          tile.quad,
          instance.x,
          instance.y,
          tile.r,
          tile.sx,
          tile.sy
        )
      else
        instance.batch\set(
          instance.id,
          instance.x,
          instance.y,
          0,
          0)

        @freeBatchSprites[instance.batch] = @freeBatchSprites[instance.batch] or {}
        table.insert(@freeBatchSprites[instance.batch], instance)


    for i, ins in ipairs(@tileInstances[instance.gid])
      if ins.batch == instance.batch and ins.id == instance.id
        table.remove(@tileInstances[instance.gid], i)
        break

    if tile
      @tileInstances[tile.gid] = @tileInstances[tile.gid] or {}

      freeBatchSprites = @freeBatchSprites[instance.batch]
      local newInstance
      if freeBatchSprites and #freeBatchSprites > 0 then
        newInstance = freeBatchSprites[#freeBatchSprites]
        freeBatchSprites[#freeBatchSprites] = nil
      else
        newInstance = {}

      newInstance.layer = instance.layer
      newInstance.batch = instance.batch
      newInstance.id    = instance.id
      newInstance.gid   = tile.gid or 0
      newInstance.x     = instance.x
      newInstance.y     = instance.y
      newInstance.r     = tile.r or 0
      newInstance.oy    = tile.r ~= 0 and tile.height or 0
      table.insert(@tileInstances[tile.gid], newInstance)

  setLayerTile: (layer, x, y, gid) =>
    layer = @layers[layer]

    layer.data[y] = layer.data[y] or {}
    tile = layer.data[y][x]
    local instance

    if tile
      tileX, tileY =  @getLayerTilePosition(layer, tile, x, y)
      for _, inst in pairs @tileInstances[tile.gid]
        if inst.x == tileX and inst.y == tileY
          instance = inst
          break

    if tile == @tiles[gid]
		  return

    tile = @tiles[gid]

    if instance
      @swapTile instance, tile
    else
      @addNewLayerTile layer, tile, x, y

    layer.data[y][x] = tile


  convertTileToPixel: (x,y) =>
    ceil = math.ceil
    if @orientation == "orthogonal"
      tileW = @tilewidth
      tileH = @tileheight
      return x * tileW, y * tileH

    elseif @orientation == "isometric"
      mapH    = @height
      tileW   = @tilewidth
      tileH   = @tileheight
      offsetX = mapH * tileW / 2
      return (x - y) * tileW / 2 + offsetX, (x + y) * tileH / 2

    elseif @orientation == "staggered" or @orientation     == "hexagonal"
      tileW   = @tilewidth
      tileH   = @tileheight
      sideLen = @hexsidelength or 0

      if @staggeraxis == "x"
        return x * tileW, ceil(y) * (tileH + sideLen) + (ceil(y) % 2 == 0 and tileH or 0)
      else
        return ceil(x) * (tileW + sideLen) + (ceil(x) % 2 == 0 and tileW or 0), y * tileH

  convertPixelToTile: (x, y) =>

    floor = math.floor
    ceil = math.ceil
    if @orientation == "orthogonal"
      tileW = @tilewidth
      tileH = @tileheight
      return x / tileW, y / tileH
    elseif @orientation == "isometric"
      mapH    = @height
      tileW   = @tilewidth
      tileH   = @tileheight
      offsetX = mapH * tileW / 2
      return y / tileH + (x - offsetX) / tileW, y / tileH - (x - offsetX) / tileW
    elseif @orientation == "staggered"
      staggerX = @staggeraxis  == "x"
      even     = @staggerindex == "even"

      topLeft = (x, y) ->
        if staggerX
          if ceil(x) % 2 == 1 and even
            return x - 1, y
          else
            return x - 1, y - 1
        else
          if ceil(y) % 2 == 1 and even
            return x, y - 1
          else
            return x - 1, y - 1

      topRight = (x, y) ->
        if staggerX then
          if ceil(x) % 2 == 1 and even
            return x + 1, y
          else
            return x + 1, y - 1
        else
          if ceil(y) % 2 == 1 and even
            return x + 1, y - 1
          else
            return x, y - 1

      bottomLeft = (x, y) ->
        if staggerX then
          if ceil(x) % 2 == 1 and even
            return x - 1, y + 1
          else
            return x - 1, y
        else
          if ceil(y) % 2 == 1 and even
            return x, y + 1
          else
            return x - 1, y + 1


      bottomRight = (x, y) ->
        if staggerX then
          if ceil(x) % 2 == 1 and even
            return x + 1, y + 1
          else
            return x + 1, y
        else
          if ceil(y) % 2 == 1 and even
            return x + 1, y + 1
          else
            return x, y + 1

      tileW = @tilewidth
      tileH = @tileheight

      if staggerX
        x = x - (even and tileW / 2 or 0)
      else
        y = y - (even and tileH / 2 or 0)

      halfH      = tileH / 2
      ratio      = tileH / tileW
      referenceX = ceil(x / tileW)
      referenceY = ceil(y / tileH)
      relativeX  = x - referenceX * tileW
      relativeY  = y - referenceY * tileH

      if (halfH - relativeX * ratio > relativeY)
        return topLeft(referenceX, referenceY)
      elseif (-halfH + relativeX * ratio > relativeY)
        return topRight(referenceX, referenceY)
      elseif (halfH + relativeX * ratio < relativeY)
        return bottomLeft(referenceX, referenceY)
      elseif (halfH * 3 - relativeX * ratio < relativeY)
        return bottomRight(referenceX, referenceY)

      return referenceX, referenceY
    elseif @orientation == "hexagonal"
      staggerX  = @staggeraxis  == "x"
      even      = @staggerindex == "even"
      tileW     = @tilewidth
      tileH     = @tileheight
      sideLenX  = 0
      sideLenY  = 0

      colW       = tileW / 2
      rowH       = tileH / 2

      if staggerX
        sideLenX = @hexsidelength
        x = x - (even and tileW or (tileW - sideLenX) / 2)
        colW = colW - (colW  - sideLenX / 2) / 2
      else
        sideLenY = @hexsidelength
        y = y - (even and tileH or (tileH - sideLenY) / 2)
        rowH = rowH - (rowH  - sideLenY / 2) / 2


      referenceX = ceil(x) / (colW * 2)
      referenceY = ceil(y) / (rowH * 2)

      -- If in staggered line, then shift reference by 0.5 of other axes
      if staggerX then
        if (floor(referenceX) % 2 == 0) == even
          referenceY = referenceY - 0.5
      else
        if (floor(referenceY) % 2 == 0) == even
          referenceX = referenceX - 0.5

      relativeX  = x - referenceX * colW * 2
      relativeY  = y - referenceY * rowH * 2
      local centers

      if staggerX
        left    = sideLenX / 2
        centerX = left + colW
        centerY = tileH / 2

        centers = {
          { x: left,           y: centerY        },
          { x: centerX,        y: centerY - rowH },
          { x: centerX,        y: centerY + rowH },
          { x: centerX + colW, y: centerY        },
        }
      else
        top     = sideLenY / 2
        centerX = tileW / 2
        centerY = top + rowH

        centers = {
          { x: centerX,        y: top },
          { x: centerX - colW, y: centerY },
          { x: centerX + colW, y: centerY },
          { x: centerX,        y: centerY + rowH }
        }


      nearest = 0
      minDist = math.huge

      len2 = (ax, ay) ->
        return ax * ax + ay * ay

      for i = 1, 4
        dc = len2(centers[i].x - relativeX, centers[i].y - relativeY)

        if dc < minDist
          minDist = dc
          nearest = i

      offsetsStaggerX = {
        { x: 1, y:  1 },
        { x: 2, y:  0 },
        { x: 2, y:  1 },
        { x: 3, y:  1 },
      }

      offsetsStaggerY = {
        { x:  1, y: 1 },
        { x:  0, y: 2 },
        { x:  1, y: 2 },
        { x:  1, y: 3 },
      }

      offsets = staggerX and offsetsStaggerX or offsetsStaggerY

      return referenceX + offsets[nearest].x, referenceY + offsets[nearest].y

Tiler
