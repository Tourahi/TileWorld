local cwd = (...):gsub('%.engine$', '') .. "."
local Graphics = assert(require(cwd .. 'graphics'))
local formatPath
formatPath = function(p)
  local np_gen1, np_gen2 = '[^SEP]+SEP%.%.SEP?', 'SEP+%.?SEP'
  local np_pat1, np_pat2 = np_gen1:gsub('SEP', '/'), np_gen2:gsub('SEP', '/')
  local k = nil
  while k ~= 0 do
    p, k = p:gsub(np_pat2, '/', 1)
  end
  while k ~= 0 do
    p, k = p:gsub(np_pat1, '', 1)
  end
  if p == '' then
    p = '.'
  end
  return p
end
local TRANSPARENT_COLOR = { }
local hexToColor
hexToColor = function(hex)
  if hex:sub(1, 1) == "#" then
    hex = hex:sub(2)
  end
  return {
    r = tonumber(hex:sub(1, 2), 16) / 255,
    g = tonumber(hex:sub(3, 4), 16) / 255,
    b = tonumber(hex:sub(5, 6), 16) / 255
  }
end
local convertIsometricToScreen
convertIsometricToScreen = function(self, map, x, y)
  local mapW = map.width
  local tileW = map.tilewidth
  local tileH = map.tileheight
  local tileX = x / tileH
  local tileY = y / tileH
  local offsetX = mapW * tileW / 2
  return (tileX - tileY) * tileW / 2 + offsetX, (tileX + tileY) * tileH / 2
end
local rotateVertex
rotateVertex = function(map, vertex, x, y, cos, sin, oy)
  if map.orientation == "isometric" then
    x, y = convertIsometricToScreen(map, x, y)
    vertex.x, vertex.y = convertIsometricToScreen(map, vertex.x, vertex.y)
  end
  vertex.x = vertex.x - x
  vertex.y = vertex.y - y
  return x + cos * vertex.x - sin * vertex.y, y + sin * vertex.x + cos * vertex.y - (oy or 0)
end
local compensate
compensate = function(tile, tileX, tileY, tileW, tileH)
  local compx = 0
  local compy = 0
  if tile.sx < 0 then
    compx = tileW
  end
  if tile.sy < 0 then
    compy = tileH
  end
  if tile.r > 0 then
    tileX = tileX + tileH - compy
    tileY = tileY + tileH + compx - tileW
  elseif tile.r < 0 then
    tileX = tileX + compy
    tileY = tileY - compx + tileH
  else
    tileX = tileX + compx
    tileY = tileY + compy
  end
  return tileX, tileY
end
local convertEllipseToPolygon
convertEllipseToPolygon = function(x, y, w, h, max_segments)
  local ceil = math.ceil
  local cos = math.cos
  local sin = math.sin
  local calc_segments
  calc_segments = function(segments)
    local vdist
    vdist = function(a, b)
      local c = {
        x = a.x - b.x,
        y = a.y - b.y
      }
      return c.x * c.x + c.y * c.y
    end
    segments = segments or 64
    local vertices = { }
    local v = {
      1,
      2,
      ceil(segments / 4 - 1),
      ceil(segments / 4)
    }
    local m
    if love and love.physics then
      m = love.physics.getMeter()
    else
      m = 32
    end
    for _, i in ipairs(v) do
      local angle = (i / segments) * math.pi * 2
      local px = x + w / 2 + cos(angle) * w / 2
      local py = y + h / 2 + sin(angle) * h / 2
      table.insert(vertices, {
        x = px / m,
        y = py / m
      })
    end
    local dist1 = vdist(vertices[1], vertices[2])
    local dist2 = vdist(vertices[3], vertices[4])
    if dist1 < 0.0025 or dist2 < 0.0025 then
      calc_segments(segments - 2)
    end
    return segments
  end
  local segments = calc_segments(max_segments)
  local vertices = { }
  table.insert(vertices, {
    x = x + w / 2,
    y = y + h / 2
  })
  for i = 0, segments do
    local angle = (i / segments) * math.pi * 2
    local px = x + w / 2 + cos(angle) * w / 2
    local py = y + h / 2 + sin(angle) * h / 2
    table.insert(vertices, {
      x = px,
      y = py
    })
  end
  return vertices
end
local Tiler
do
  local _class_0
  local _base_0 = {
    setLayer = function(self, layer, path)
      local Data = love.data
      if layer.encoding then
        if layer.encoding == "base64" then
          assert(require("ffi", "Compressed maps require LuaJIT FFI.\nPlease Switch your interperator to LuaJIT or your Tile Layer Format to \"CSV\"."))
          local fd = Data.decode("string", "base64", layer.data)
          if not layer.compression then
            layer.data = self:getDecompresedData(fd)
          else
            assert(Data.decompress, "zlib and gzip compression require LOVE 11.0+.\nPlease set your Tile Layer Format to \"Base64 (uncompressed)\" or \"CSV\".")
            if layer.compression == "zlib" then
              local data = Data.decompress("string", "zlib", fd)
              layer.data = self:getDecompresedData(data)
            end
            if layer.compression == "gzip" then
              local data = Data.decompress("string", "gzip", fd)
              layer.data = self:getDecompresedData(data)
            end
          end
        end
      end
      layer.x = (layer.x or 0) + layer.offsetx + self.offsetX
      layer.y = (layer.y or 0) + layer.offsety + self.offsetY
      layer.update = function() end
      if layer.type == "tilelayer" then
        self:setTileData(layer)
        self:setSpriteBatches(layer)
        layer.draw = function()
          return self:drawTileLayer(layer)
        end
      elseif layer.type == "objectgroup" then
        self:setObjectData(layer)
        self:setObjectCoordinates(layer)
        self:setObjectSpriteBatches(layer)
        layer.draw = function()
          return self:drawObjectLayer(layer)
        end
      elseif layer.type == "imagelayer" then
        layer.draw = function()
          return self:drawImageLayer(layer)
        end
        if layer.image ~= "" then
          local formattedPath = formatPath(self.dir .. layer.image)
          if not self.cache[formattedPath] then
            self:cacheImage(formattedPath)
          end
          layer.image = self.cache[formattedPath]
          layer.width = layer.image:getWidth()
          layer.height = layer.image:getHeight()
        end
      end
      self.layers[layer.name] = layer
    end,
    setObjectSpriteBatches = function(self, layer)
      local newBatch = Graphics.newSpriteBatch
      local batches = { }
      if layer.draworder == "topdown" then
        table.sort(layer.objects, function(a, b)
          return a.y + a.height < b.y + b.height
        end)
      end
      for _, object in ipairs(layer.objects) do
        if object.gid then
          local tile = self.tiles[object.gid] or self:setFlippedGID(object.gid)
          local tileset = tile.tileset
          local image = self.tilesets[tileset].image
          batches[tileset] = batches[tileset] or newBatch(image)
          local sx = object.width / tile.width
          local sy = object.height / tile.height
          local ox = 0
          local oy = tile.height
          local batch = batches[tileset]
          local tileX = object.x + tile.offset.x
          local tileY = object.y + tile.offset.y
          local tileR = math.rad(object.rotation)
          if tile.sx == -1 then
            tileX = tileX + object.width
            if tileR ~= 0 then
              tileX = tileX - object.width
              ox = ox + tile.width
            end
          end
          if tile.sy == -1 then
            tileY = tileY - object.height
            if tileR ~= 0 then
              tileY = tileY + object.width
              oy = oy - tile.width
            end
          end
          local instance = {
            id = batch:add(tile.quad, tileX, tileY, tileR, tile.sx * sx, tile.sy * sy, ox, oy),
            batch = batch,
            layer = layer,
            gid = tile.gid,
            x = tileX,
            y = tileY - oy,
            r = tileR,
            oy = oy
          }
          self.tileInstances[tile.gid] = self.tileInstances[tile.gid] or { }
          table.insert(self.tileInstances[tile.gid], instance)
        end
      end
      layer.batches = batches
    end,
    getLayerTilePosition = function(self, layer, tile, x, y)
      local tileW = self.tilewidth
      local tileH = self.tileheight
      local tileX, tileY
      if self.orientation == "orthogonal" then
        local tileset = self.tilesets[tile.tileset]
        tileX = (x - 1) * tileW + tile.offset.x
        tileY = (y - 0) * tileH + tile.offset.y - tileset.tileheight
        tileX, tileY = compensate(tile, tileX, tileY, tileW, tileH)
      elseif self.orientation == "isometric" then
        tileX = (x - y) * (tileW / 2) + tile.offset.x + layer.width * tileW / 2 - self.tilewidth / 2
        tileY = (x + y - 2) * (tileH / 2) + tile.offset.y
      else
        local sideLen = self.hexsidelength or 0
        if self.staggeraxis == "y" then
          if self.staggerindex == "odd" then
            if y % 2 == 0 then
              tileX = (x - 1) * tileW + tileW / 2 + tile.offset.x
            else
              tileX = (x - 1) * tileW + tile.offset.x
            end
          else
            if y % 2 == 0 then
              tileX = (x - 1) * tileW + tile.offset.x
            else
              tileX = (x - 1) * tileW + tileW / 2 + tile.offset.x
            end
          end
          local rowH = tileH - (tileH - sideLen) / 2
          tileY = (y - 1) * rowH + tile.offset.y
        else
          if self.staggerindex == "odd" then
            if x % 2 == 0 then
              tileY = (y - 1) * tileH + tileH / 2 + tile.offset.y
            else
              tileY = (y - 1) * tileH + tile.offset.y
            end
          else
            if x % 2 == 0 then
              tileY = (y - 1) * tileH + tile.offset.y
            else
              tileY = (y - 1) * tileH + tileH / 2 + tile.offset.y
            end
          end
          local colW = tileW - (tileW - sideLen) / 2
          tileX = (x - 1) * colW + tile.offset.x
        end
      end
      return tileX, tileY
    end,
    setSpriteBatches = function(self, layer)
      if layer.chunks then
        for _, chunk in ipairs(layer.chunks) do
          self:setBatches(layer, chunk)
        end
        return 
      end
      return self:setBatches(layer)
    end,
    addNewLayerTile = function(self, layer, chunk, tile, x, y)
      local tileset = tile.tileset
      local img = self.tilesets[tileset].image
      local batches, size
      if chunk then
        batches = chunk.batches
        size = chunk.width * chunk.height
      else
        batches = layer.batches
        size = layer.width * layer.height
      end
      batches[tileset] = batches[tileset] or Graphics.newSpriteBatch(img, size)
      local batch = batches[tileset]
      local tileX, tileY = self:getLayerTilePosition(layer, tile, x, y)
      local instance = {
        layer = layer,
        chunk = chunk,
        gid = tile.gid,
        x = tileX,
        y = tileY,
        r = tile.r,
        oy = 0
      }
      if batch then
        instance.batch = batch
        instance.id = batch:add(tile.quad, tileX, tileY, tile.r, tile.sx, tile.sy)
      end
      self.tileInstances[tile.gid] = self.tileInstances[tile.gid] or { }
      return table.insert(self.tileInstances[tile.gid], instance)
    end,
    setBatches = function(self, layer, chunk)
      if chunk then
        chunk.batches = { }
      else
        layer.batches = { }
      end
      if self.orientation == "orthogonal" or self.orientation == "isometric" then
        local offsetX = chunk and chunk.x or 0
        local offsetY = chunk and chunk.y or 0
        local startX = 1
        local startY = 1
        local endX = chunk and chunk.width or layer.width
        local endY = chunk and chunk.height or layer.height
        local incX = 1
        local incY = 1
        if self.renderorder == "right-up" then
          startY, endY, incY = endY, startY, -1
        elseif self.renderorder == "left-down" then
          startX, endX, incX = endX, startX, -1
        elseif self.renderorder == "left-up" then
          startX, endX, incX = endX, startX, -1
          startY, endY, incY = endY, startY, -1
        end
        for y = startY, endY, incY do
          for x = startX, endX, incX do
            local tile
            if chunk then
              tile = chunk.data[y][x]
            else
              tile = layer.data[y][x]
            end
            if tile then
              self:addNewLayerTile(layer, chunk, tile, x + offsetX, y + offsetY)
            end
          end
        end
      else
        if self.staggeraxis == "y" then
          for y = 1, (chunk and chunk.height or layer.height) do
            for x = 1, (chunk and chunk.width or layer.width) do
              local tile
              if chunk then
                tile = chunk.data[y][x]
              else
                tile = layer.data[y][x]
              end
              if tile then
                self:addNewLayerTile(layer, chunk, tile, x, y)
              end
            end
          end
        else
          local i = 0
          local _x
          if self.staggerindex == "odd" then
            _x = 1
          else
            _x = 2
          end
          local floor = math.floor
          while i < (chunk and chunk.width * chunk.height or layer.width * layer.height) do
            for _y = 1, (chunk and chunk.height or layer.height) + 0.5, 0.5 do
              local y = floor(_y)
              for x = _x, (chunk and chunk.width or layer.width), 2 do
                i = i + 1
                local tile
                if chunk then
                  tile = chunk.data[y][x]
                else
                  tile = layer.data[y][x]
                end
                if tile then
                  self:addNewLayerTile(layer, chunk, tile, x, y)
                end
                if _x == 1 then
                  _x = 2
                else
                  _x = 1
                end
              end
            end
          end
        end
      end
    end,
    setTileData = function(self, layer)
      if layer.chunks then
        for _, chunk in ipairs(layer.chunks) do
          self:setTileData(chunk)
        end
        return 
      end
      local i = 1
      local map = { }
      for y = 1, layer.height do
        map[y] = { }
        for x = 1, layer.width do
          local gid = layer.data[i]
          if gid > 0 then
            map[y][x] = self.tiles[gid] or self:setFlippedGID(gid)
          end
          i = i + 1
        end
      end
      layer.data = map
    end,
    groupAppendToList = function(self, layers, layer)
      if layer.type == "group" then
        for _, groupLayer in pairs(layer.layers) do
          groupLayer.name = layer.name .. "." .. groupLayer.name
          groupLayer.visible = layer.visible
          groupLayer.opacity = layer.opacity * groupLayer.opacity
          groupLayer.offsetx = layer.offsetx + groupLayer.offsetx
          groupLayer.offsety = layer.offsety + groupLayer.offsety
          for key, property in pairs(layer.properties) do
            if groupLayer.properties[key] == nil then
              groupLayer.properties[key] = property
            end
          end
          self:groupAppendToList(layers, groupLayer)
        end
      else
        return table.insert(layers, layer)
      end
    end,
    pixelFunc = function(_, _, r, g, b, a)
      local mask = TRANSPARENT_COLOR
      if r == mask.r and g == mask.g and b == mask.b then
        _ = r, g, b, 0
      end
      return r, g, b, a
    end,
    fixTransparentColor = function(self, tileset, path)
      local limage = love.image
      local imageData = limage.newImageData(path)
      tileset.image = Graphics.newImage(imageData)
      if tileset.transparentColor then
        TRANSPARENT_COLOR = hexToColor(tileset.transparentColor)
        imageData:mapPixel(self.pixelFunc)
        tileset.image = Graphics.newImage(imageData)
      end
    end,
    cacheImage = function(self, formattedPath, img)
      if type(img) ~= "userdata" then
        img = Graphics.newImage(formattedPath)
      end
      img:setFilter("nearest", "nearest")
      self.cache[formattedPath] = img
    end,
    loadPlugins = function(self, plugins)
      for _, p in ipairs(plugins) do
        local pmp = cwd .. 'plugins.' .. p
        local ok, pm = pcall(require, pmp)
        if ok then
          if pm.__class ~= nil then
            self[p] = pm
          else
            for k, f in pairs(pm) do
              if not self[k] then
                self[k] = f
              end
            end
          end
        else
          print("Plugin " .. p .. " does not exist. Make sure you add it to the plugins folder.")
        end
      end
    end,
    resize = function(self, w, h)
      if Graphics.isCreated then
        w = w or Graphics.getWidth()
        h = h or Graphics.getHeight()
        self.canvas = Graphics.newCanvas(w, h)
        return self.canvas:setFilter("nearest", "nearest")
      end
    end,
    getTiles = function(self, imgW, tileW, margin, spacing)
      imgW = imgW - margin
      local n = 0
      while imgW >= tileW do
        imgW = imgW - tileW
        if n ~= 0 then
          imgW = imgW - spacing
        end
        if imgW >= 0 then
          n = n + 1
        end
      end
      return n
    end,
    setTiles = function(self, idx, tileset, gid)
      local quad = Graphics.newQuad
      local imgW = tileset.imagewidth
      local imgH = tileset.imageheight
      local tileW = tileset.tilewidth
      local tileH = tileset.tileheight
      local margin = tileset.margin
      local spacing = tileset.spacing
      local w = self:getTiles(imgW, tileW, margin, spacing)
      local h = self:getTiles(imgH, tileH, margin, spacing)
      for y = 1, h do
        for x = 1, w do
          local id = gid - tileset.firstgid
          local quadX = (x - 1) * tileW + margin + (x - 1) * spacing
          local quadY = (y - 1) * tileH + margin + (y - 1) * spacing
          local type = ""
          local properties, terrain, animation, objectGroup
          for _, tile in pairs(tileset.tiles) do
            if tile.id == id then
              properties = tile.properties
              animation = tile.animation
              objectGroup = tile.objectGroup
              type = tile.type
              if tile.terrain then
                terrain = { }
                for i = 1, #tile.terrain do
                  terrain[i] = tileset.terrains[tile.terrain[i] + 1]
                end
              end
            end
          end
          local tile = {
            id = id,
            gid = gid,
            tileset = idx,
            type = type,
            quad = quad(quadX, quadY, tileW, tileH, imgW, imgH),
            properties = properties or { },
            terrain = terrain,
            animation = animation,
            objectGroup = objectGroup,
            frame = 1,
            time = 0,
            width = tileW,
            height = tileH,
            sx = 1,
            sy = 1,
            r = 0,
            offset = tileset.tileoffset
          }
          self.tiles[gid] = tile
          gid = gid + 1
        end
      end
      return gid
    end,
    getDecompresedData = function(self, data)
      local ffi = require("ffi")
      local d = { }
      local decoded = ffi.cast("uint32_t*", data)
      for i = 0, data:len() / ffi.sizeof("uint32_t") do
        table.insert(d, tonumber(decoded[i]))
      end
      return d
    end,
    setObjectCoordinates = function(self, layer)
      for _, object in ipairs(layer.objects) do
        local x = layer.x + object.x
        local y = layer.y + object.y
        local w = object.width
        local h = object.height
        local cos = math.cos(math.rad(object.rotation))
        local sin = math.sin(math.rad(object.rotation))
        if object.shape == "rectangle" and not object.gid then
          object.rectangle = { }
          local vertices = {
            {
              x = x,
              y = y
            },
            {
              x = x + w,
              y = y
            },
            {
              x = x + w,
              y = y + h
            },
            {
              x = x,
              y = y + h
            }
          }
          for _, vertex in ipairs(vertices) do
            vertex.x, vertex.y = rotateVertex(self, vertex, x, y, cos, sin)
            table.insert(object.rectangle, {
              x = vertex.x,
              y = vertex.y
            })
          end
        elseif object.shape == "ellipse" then
          object.ellipse = { }
          local vertices = convertEllipseToPolygon(x, y, w, h)
          for _, vertex in ipairs(vertices) do
            vertex.x, vertex.y = rotateVertex(self, vertex, x, y, cos, sin)
            table.insert(object.ellipse, {
              x = vertex.x,
              y = vertex.y
            })
          end
        elseif object.shape == "polygon" then
          for _, vertex in ipairs(object.polygon) do
            vertex.x = vertex.x + x
            vertex.y = vertex.y + y
            vertex.x, vertex.y = rotateVertex(self, vertex, x, y, cos, sin)
          end
        elseif object.shape == "polyline" then
          for _, vertex in ipairs(object.polyline) do
            vertex.x = vertex.x + x
            vertex.y = vertex.y + y
            vertex.x, vertex.y = rotateVertex(self, vertex, x, y, cos, sin)
          end
        end
      end
    end,
    setObjectData = function(self, layer)
      for _, object in ipairs(layer.objects) do
        object.layer = layer
        self.objects[object.id] = object
      end
    end,
    setFlippedGID = function(self, gid)
      local bit31 = 2147483648
      local bit30 = 1073741824
      local bit29 = 536870912
      local flipX = false
      local flipY = false
      local flipD = false
      local realgid = gid
      if realgid >= bit31 then
        realgid = realgid - bit31
        flipX = not flipX
      end
      if realgid >= bit30 then
        realgid = realgid - bit30
        flipY = not flipY
      end
      if realgid >= bit29 then
        realgid = realgid - bit29
        flipD = not flipD
      end
      local tile = self.tiles[realgid]
      local data = {
        id = tile.id,
        gid = gid,
        tileset = tile.tileset,
        frame = tile.frame,
        time = tile.time,
        width = tile.width,
        height = tile.height,
        offset = tile.offset,
        quad = tile.quad,
        properties = tile.properties,
        terrain = tile.terrain,
        animation = tile.animation,
        sx = tile.sx,
        sy = tile.sy,
        r = tile.r
      }
      if flipX then
        if flipY and flipD then
          data.r = math.rad(-90)
          data.sy = -1
        elseif flipY then
          data.sx = -1
          data.sy = -1
        elseif flipD then
          data.r = math.rad(90)
        else
          data.sx = -1
        end
      elseif flipY then
        if flipD then
          data.r = math.rad(-90)
        else
          data.sy = -1
        end
      elseif flipD then
        data.r = math.rad(90)
        data.sy = -1
      end
      self.tiles[gid] = data
      return self.tiles[gid]
    end,
    drawLayer = function(self, layer)
      local r, g, b, a = Graphics.getColor()
      Graphics.setColor(r, g, b, a * layer.opacity)
      layer:draw()
      return Graphics.setColor(r, g, b, a)
    end,
    drawTileLayer = function(self, layer)
      if type(layer) == "string" or type(layer) == "number" then
        layer = self.layers[layer]
      end
      assert(layer.type == "tilelayer", "Invalid layer type: " .. layer.type .. ". Layer must be of type: tilelayer")
      if layer.chunks then
        for _, chunk in ipairs(layer.chunks) do
          for _, batch in pairs(chunk.batches) do
            Graphics.draw(batch, 0, 0)
          end
        end
        return 
      end
      local floor = math.floor
      for _, batch in pairs(layer.batches) do
        Graphics.draw(batch, floor(layer.x), floor(layer.y))
      end
    end,
    drawObjectLayer = function(self, layer)
      if type(layer) == "string" or type(layer) == "number" then
        layer = self.layers[layer]
      end
      assert(layer.type == "objectgroup", "Invalid layer type: " .. layer.type .. ". Layer must be of type: objectgroup")
      local line = {
        160,
        160,
        160,
        255 * layer.opacity
      }
      local fill = {
        160,
        160,
        160,
        255 * layer.opacity * 0.5
      }
      local r, g, b, a = Graphics.getColor()
      local reset = {
        r,
        g,
        b,
        a * layer.opacity
      }
      local sortVertices
      sortVertices = function(obj)
        local vertex = { }
        for _, v in ipairs(obj) do
          table.insert(vertex, v.x)
          table.insert(vertex, v.y)
        end
        return vertex
      end
      local drawShape
      drawShape = function(obj, shape)
        local vertex = sortVertices(obj)
        if shape == "polyline" then
          Graphics.setColor(line)
          Graphics.line(vertex)
          return 
        elseif shape == "polygon" then
          Graphics.setColor(fill)
          if not love.math.isConvex(vertex) then
            local triangles = love.math.triangulate(vertex)
            for _, triangle in ipairs(triangles) do
              Graphics.polygon("fill", triangle)
            end
          else
            Graphics.polygon("fill", vertex)
          end
        else
          Graphics.setColor(fill)
          Graphics.polygon("fill", vertex)
        end
        Graphics.setColor(line)
        return Graphics.polygon("line", vertex)
      end
      for _, object in ipairs(layer.objects) do
        if object.visible then
          if object.shape == "rectangle" and not object.gid then
            drawShape(object.rectangle, "rectangle")
          elseif object.shape == "ellipse" then
            drawShape(object.ellipse, "ellipse")
          elseif object.shape == "polygon" then
            drawShape(object.polygon, "polygon")
          elseif object.shape == "polyline" then
            drawShape(object.polyline, "polyline")
          elseif object.shape == "point" then
            Graphics.points(object.x, object.y)
          end
        end
      end
      Graphics.setColor(reset)
      for _, batch in pairs(layer.batches) do
        Graphics.draw(batch, 0, 0)
      end
      return Graphics.setColor(r, g, b, a)
    end,
    drawImageLayer = function(self, layer)
      if type(layer) == "string" or type(layer) == "number" then
        layer = self.layers[layer]
      end
      assert(layer.type == "imagelayer", "Invalid layer type: " .. layer.type .. ". Layer must be of type: imagelayer")
      if layer.image ~= "" then
        return Graphics.draw(layer.image, layer.x, layer.y)
      end
    end,
    update = function(self, dt)
      for _, tile in pairs(self.tiles) do
        local update = false
        if tile.animation then
          tile.time = tile.time + (dt * 1000)
          while tile.time > tonumber(tile.animation[tile.frame].duration) do
            update = true
            tile.time = tile.time - tonumber(tile.animation[tile.frame].duration)
            tile.frame = tile.frame + 1
            if tile.frame > #tile.animation then
              tile.frame = 1
            end
          end
          if update and self.tileInstances[tile.gid] then
            for _, j in pairs(self.tileInstances[tile.gid]) do
              local t = self.tiles[tonumber(tile.animation[tile.frame].tileid) + self.tilesets[tile.tileset].firstgid]
              j.bash:set(j.id, t.quad, j.x, j.y, j.r, tile.sx, tile.sy, 0, j.oy)
            end
          end
        end
      end
      for _, layer in ipairs(self.layers) do
        layer:update(dt)
      end
    end,
    draw = function(self, tx, ty, sx, sy)
      local cCanvas = Graphics.getCanvas()
      Graphics.setCanvas(self.canvas)
      Graphics.clear()
      Graphics.push()
      Graphics.origin()
      Graphics.translate(math.floor(tx or 0), math.floor(ty or 0))
      for _, layer in ipairs(self.layers) do
        if layer.visible and layer.opacity > 0 then
          self:drawLayer(layer)
        end
      end
      Graphics.pop()
      Graphics.push()
      Graphics.origin()
      Graphics.scale(sx or 1, sy or sx or 1)
      Graphics.setCanvas(cCanvas)
      Graphics.draw(self.canvas)
      return Graphics.pop()
    end,
    getCanvas = function(self)
      return self.canvas
    end,
    drawLayers = function(self)
      for _, layer in ipairs(self.layers) do
        if layer.visible and layer.opacity > 0 then
          self:drawLayer(layer)
        end
      end
    end,
    addCustomLayer = function(self, name, idx)
      if idx == nil then
        idx = self.layers + 1
      end
      local layer = {
        type = "customlayer",
        name = name,
        visible = true,
        opacity = 1,
        properties = { }
      }
      layer.draw = function() end
      layer.update = function() end
      table.insert(self.layers, idx, layer)
      self.layers[name] = self.layers[idx]
      return layer
    end,
    convertToCustomLayer = function(self, idx)
      local layer = assert(self.layers[idx], "Layer not found: " .. idx)
      layer.type = "customlayer"
      layer.x = nil
      layer.y = nil
      layer.width = nil
      layer.height = nil
      layer.encoding = nil
      layer.data = nil
      layer.chunks = nil
      layer.objects = nil
      layer.image = nil
      layer.draw = function() end
      layer.update = function() end
      return layer
    end,
    removeLayer = function(self, idx)
      local layer = assert(self.layers[idx], "Layer not found: " .. idx)
      if type(idx) == "string" then
        for i, l in ipairs(self.layers) do
          if l.name == idx then
            table.remove(self.layers, i)
            self.layers[idx] = nil
            break
          end
        end
        local name = self.layers[idx].name
        table.remove(self.layers, idx)
        self.layers[name] = nil
      end
      if layer.batches then
        for _, batch in pairs(layer.batches) do
          self.freeBatchSprites[batch] = nil
        end
      end
      if layer.chunks then
        for _, chunk in ipairs(layer.chunks) do
          for _, batch in pairs(chunk.batches) do
            self.freeBatchSprites[batch] = nil
          end
        end
      end
      if layer.type == "tilelayer" then
        for _, tiles in pairs(self.tileInstances) do
          for i = #tiles, 1, -1 do
            local tile = tiles[i]
            if tile.layer == layer then
              table.remove(tiles, i)
            end
          end
        end
      end
      if layer.objects then
        for i, object in pairs(self.objects) do
          if object.layer == layer then
            self.objects[i] = nil
          end
        end
      end
    end,
    getLayerProperties = function(self, layer)
      local l = self.layers[layer]
      if not l then
        return { }
      end
      return l.properties
    end,
    getTileProperties = function(self, layer, x, y)
      local tile = self.layers[layer].data[y][x]
      if not tile then
        return { }
      end
      return tile.properties
    end,
    swapTile = function(self, instance, tile)
      if instance.batch then
        if tile then
          instance.batch:set(instance.id, tile.quad, instance.x, instance.y, tile.r, tile.sx, tile.sy)
        else
          instance.batch:set(instance.id, instance.x, instance.y, 0, 0)
          self.freeBatchSprites[instance.batch] = self.freeBatchSprites[instance.batch] or { }
          table.insert(self.freeBatchSprites[instance.batch], instance)
        end
      end
      for i, ins in ipairs(self.tileInstances[instance.gid]) do
        if ins.batch == instance.batch and ins.id == instance.id then
          table.remove(self.tileInstances[instance.gid], i)
          break
        end
      end
      if tile then
        self.tileInstances[tile.gid] = self.tileInstances[tile.gid] or { }
        local freeBatchSprites = self.freeBatchSprites[instance.batch]
        local newInstance
        if freeBatchSprites and #freeBatchSprites > 0 then
          newInstance = freeBatchSprites[#freeBatchSprites]
          freeBatchSprites[#freeBatchSprites] = nil
        else
          newInstance = { }
        end
        newInstance.layer = instance.layer
        newInstance.batch = instance.batch
        newInstance.id = instance.id
        newInstance.gid = tile.gid or 0
        newInstance.x = instance.x
        newInstance.y = instance.y
        newInstance.r = tile.r or 0
        newInstance.oy = tile.r ~= 0 and tile.height or 0
        return table.insert(self.tileInstances[tile.gid], newInstance)
      end
    end,
    setLayerTile = function(self, layer, x, y, gid)
      layer = self.layers[layer]
      layer.data[y] = layer.data[y] or { }
      local tile = layer.data[y][x]
      local instance
      if tile then
        local tileX, tileY = self:getLayerTilePosition(layer, tile, x, y)
        for _, inst in pairs(self.tileInstances[tile.gid]) do
          if inst.x == tileX and inst.y == tileY then
            instance = inst
            break
          end
        end
      end
      if tile == self.tiles[gid] then
        return 
      end
      tile = self.tiles[gid]
      if instance then
        self:swapTile(instance, tile)
      else
        self:addNewLayerTile(layer, tile, x, y)
      end
      layer.data[y][x] = tile
    end,
    convertTileToPixel = function(self, x, y)
      local ceil = math.ceil
      if self.orientation == "orthogonal" then
        local tileW = self.tilewidth
        local tileH = self.tileheight
        return x * tileW, y * tileH
      elseif self.orientation == "isometric" then
        local mapH = self.height
        local tileW = self.tilewidth
        local tileH = self.tileheight
        local offsetX = mapH * tileW / 2
        return (x - y) * tileW / 2 + offsetX, (x + y) * tileH / 2
      elseif self.orientation == "staggered" or self.orientation == "hexagonal" then
        local tileW = self.tilewidth
        local tileH = self.tileheight
        local sideLen = self.hexsidelength or 0
        if self.staggeraxis == "x" then
          return x * tileW, ceil(y) * (tileH + sideLen) + (ceil(y) % 2 == 0 and tileH or 0)
        else
          return ceil(x) * (tileW + sideLen) + (ceil(x) % 2 == 0 and tileW or 0), y * tileH
        end
      end
    end,
    convertPixelToTile = function(self, x, y)
      local floor = math.floor
      local ceil = math.ceil
      if self.orientation == "orthogonal" then
        local tileW = self.tilewidth
        local tileH = self.tileheight
        return x / tileW, y / tileH
      elseif self.orientation == "isometric" then
        local mapH = self.height
        local tileW = self.tilewidth
        local tileH = self.tileheight
        local offsetX = mapH * tileW / 2
        return y / tileH + (x - offsetX) / tileW, y / tileH - (x - offsetX) / tileW
      elseif self.orientation == "staggered" then
        local staggerX = self.staggeraxis == "x"
        local even = self.staggerindex == "even"
        local topLeft
        topLeft = function(x, y)
          if staggerX then
            if ceil(x) % 2 == 1 and even then
              return x - 1, y
            else
              return x - 1, y - 1
            end
          else
            if ceil(y) % 2 == 1 and even then
              return x, y - 1
            else
              return x - 1, y - 1
            end
          end
        end
        local topRight
        topRight = function(x, y)
          if staggerX then
            if ceil(x) % 2 == 1 and even then
              return x + 1, y
            else
              return x + 1, y - 1
            end
          else
            if ceil(y) % 2 == 1 and even then
              return x + 1, y - 1
            else
              return x, y - 1
            end
          end
        end
        local bottomLeft
        bottomLeft = function(x, y)
          if staggerX then
            if ceil(x) % 2 == 1 and even then
              return x - 1, y + 1
            else
              return x - 1, y
            end
          else
            if ceil(y) % 2 == 1 and even then
              return x, y + 1
            else
              return x - 1, y + 1
            end
          end
        end
        local bottomRight
        bottomRight = function(x, y)
          if staggerX then
            if ceil(x) % 2 == 1 and even then
              return x + 1, y + 1
            else
              return x + 1, y
            end
          else
            if ceil(y) % 2 == 1 and even then
              return x + 1, y + 1
            else
              return x, y + 1
            end
          end
        end
        local tileW = self.tilewidth
        local tileH = self.tileheight
        if staggerX then
          x = x - (even and tileW / 2 or 0)
        else
          y = y - (even and tileH / 2 or 0)
        end
        local halfH = tileH / 2
        local ratio = tileH / tileW
        local referenceX = ceil(x / tileW)
        local referenceY = ceil(y / tileH)
        local relativeX = x - referenceX * tileW
        local relativeY = y - referenceY * tileH
        if (halfH - relativeX * ratio > relativeY) then
          return topLeft(referenceX, referenceY)
        elseif (-halfH + relativeX * ratio > relativeY) then
          return topRight(referenceX, referenceY)
        elseif (halfH + relativeX * ratio < relativeY) then
          return bottomLeft(referenceX, referenceY)
        elseif (halfH * 3 - relativeX * ratio < relativeY) then
          return bottomRight(referenceX, referenceY)
        end
        return referenceX, referenceY
      elseif self.orientation == "hexagonal" then
        local staggerX = self.staggeraxis == "x"
        local even = self.staggerindex == "even"
        local tileW = self.tilewidth
        local tileH = self.tileheight
        local sideLenX = 0
        local sideLenY = 0
        local colW = tileW / 2
        local rowH = tileH / 2
        if staggerX then
          sideLenX = self.hexsidelength
          x = x - (even and tileW or (tileW - sideLenX) / 2)
          colW = colW - (colW - sideLenX / 2) / 2
        else
          sideLenY = self.hexsidelength
          y = y - (even and tileH or (tileH - sideLenY) / 2)
          rowH = rowH - (rowH - sideLenY / 2) / 2
        end
        local referenceX = ceil(x) / (colW * 2)
        local referenceY = ceil(y) / (rowH * 2)
        if staggerX then
          if (floor(referenceX) % 2 == 0) == even then
            referenceY = referenceY - 0.5
          end
        else
          if (floor(referenceY) % 2 == 0) == even then
            referenceX = referenceX - 0.5
          end
        end
        local relativeX = x - referenceX * colW * 2
        local relativeY = y - referenceY * rowH * 2
        local centers
        if staggerX then
          local left = sideLenX / 2
          local centerX = left + colW
          local centerY = tileH / 2
          centers = {
            {
              x = left,
              y = centerY
            },
            {
              x = centerX,
              y = centerY - rowH
            },
            {
              x = centerX,
              y = centerY + rowH
            },
            {
              x = centerX + colW,
              y = centerY
            }
          }
        else
          local top = sideLenY / 2
          local centerX = tileW / 2
          local centerY = top + rowH
          centers = {
            {
              x = centerX,
              y = top
            },
            {
              x = centerX - colW,
              y = centerY
            },
            {
              x = centerX + colW,
              y = centerY
            },
            {
              x = centerX,
              y = centerY + rowH
            }
          }
        end
        local nearest = 0
        local minDist = math.huge
        local len2
        len2 = function(ax, ay)
          return ax * ax + ay * ay
        end
        for i = 1, 4 do
          local dc = len2(centers[i].x - relativeX, centers[i].y - relativeY)
          if dc < minDist then
            minDist = dc
            nearest = i
          end
        end
        local offsetsStaggerX = {
          {
            x = 1,
            y = 1
          },
          {
            x = 2,
            y = 0
          },
          {
            x = 2,
            y = 1
          },
          {
            x = 3,
            y = 1
          }
        }
        local offsetsStaggerY = {
          {
            x = 1,
            y = 1
          },
          {
            x = 0,
            y = 2
          },
          {
            x = 1,
            y = 2
          },
          {
            x = 1,
            y = 3
          }
        }
        local offsets = staggerX and offsetsStaggerX or offsetsStaggerY
        return referenceX + offsets[nearest].x, referenceY + offsets[nearest].y
      end
    end
  }
  _base_0.__index = _base_0
  _class_0 = setmetatable({
    __init = function(self, path, plugins, ox, oy)
      if path.__class ~= nil and path.__class == Tiler then
        self = path
        return 
      end
      self.dir = ""
      local ext = path:sub(-4, -1)
      assert(ext == ".lua", string.format("Invalid file type: %s. File must be of type: lua.", ext))
      self.dir = path:reverse():find("[/\\]") or ""
      if self.dir ~= "" then
        self.dir = path:sub(1, 1 + (#path - self.dir))
      end
      local data = assert(love.filesystem.load(path)())
      for k, v in pairs(data) do
        if not self[k] then
          self[k] = v
        end
      end
      if type(plugins) == "table" then
        self:loadPlugins(plugins)
      end
      self:resize()
      self.objects = { }
      self.tiles = { }
      self.tileInstances = { }
      self.offsetX = ox or 0
      self.offsetY = oy or 0
      self.cache = { }
      self.freeBatchSprites = { }
      setmetatable(self.freeBatchSprites, {
        __mode = 'k'
      })
      local gid = 1
      for i, tileset in ipairs(self.tilesets) do
        assert(tileset.image, "Tile Collections are not supported.")
        if Graphics.isCreated then
          local formattedPath = formatPath(self.dir .. tileset.image)
          if not self.cache[formattedPath] then
            self:fixTransparentColor(tileset, formattedPath)
            self:cacheImage(formattedPath, tileset.image)
          else
            tileset.image = self.cache[formattedPath]
          end
        end
        gid = self:setTiles(i, tileset, gid)
      end
      local layers = { }
      for _, layer in ipairs(self.layers) do
        self:groupAppendToList(layers, layer)
      end
      self.layers = layers
      for _, layer in ipairs(self.layers) do
        self:setLayer(layer, path)
      end
    end,
    __base = _base_0,
    __name = "Tiler"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  Tiler = _class_0
end
return Tiler
