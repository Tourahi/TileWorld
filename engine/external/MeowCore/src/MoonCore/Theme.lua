local base
base = MeowC.base
local File = assert(require(base .. '.src.MoonCore.File'))
local Json = assert(require(base .. '.src.libs.json'))
local PrettyJson = assert(require(base .. '.src.libs.prettycjson'))
local theme = { }
do
  theme.button = { }
  theme.scrollBar = { }
  theme.content = { }
  theme.checkBox = { }
  theme.progressBar = { }
  theme.editText = { }
  theme.container = { }
  theme.button.width = 80
  theme.button.height = 36
  theme.button.upColor = {
    57 / 255,
    69 / 255,
    82 / 255,
    1
  }
  theme.button.downColor = {
    30 / 255,
    35 / 255,
    41 / 255,
    1
  }
  theme.button.hoverColor = {
    71 / 255,
    87 / 255,
    103 / 255,
    1
  }
  theme.button.disableColor = {
    48 / 255,
    57 / 255,
    66 / 255,
    1
  }
  theme.button.strokeColor = {
    25 / 255,
    30 / 255,
    35 / 255,
    1
  }
  theme.button.stroke = 1
  theme.button.fontSize = 16
  theme.button.fontColor = {
    1,
    1,
    1,
    1
  }
  theme.button.iconDir = "left"
  theme.button.iconAndTextSpace = 8
  theme.scrollBar.upColor = {
    84 / 255,
    108 / 255,
    119 / 255,
    1
  }
  theme.scrollBar.hoverColor = {
    112 / 255,
    158 / 255,
    184 / 255,
    1
  }
  theme.scrollBar.downColor = {
    84 / 255,
    108 / 255,
    119 / 255,
    1
  }
  theme.scrollBar.backgroundColor = {
    47 / 255,
    59 / 255,
    69 / 255,
    1
  }
  theme.content.transparency = 1
  theme.content.backgroundColor = {
    31 / 255,
    36 / 255,
    43 / 255,
    1
  }
  theme.content.barSize = 14
  theme.content.strokeColor = {
    0.50196078431373,
    0.50196078431373,
    0.50196078431373,
    1
  }
  theme.content.stroke = 10
  theme.checkBox.upColor = {
    1,
    1,
    1,
    1
  }
  theme.checkBox.downColor = {
    0 / 255,
    150 / 255,
    224 / 255,
    1
  }
  theme.checkBox.hoverColor = {
    0 / 255,
    150 / 255,
    224 / 255,
    1
  }
  theme.checkBox.disableColor = {
    84 / 255,
    108 / 255,
    119 / 255,
    1
  }
  theme.checkBox.size = 16
  theme.progressBar.color = {
    57 / 255,
    104 / 255,
    149 / 255,
    1
  }
  theme.progressBar.backgroundColor = {
    47 / 255,
    59 / 255,
    69 / 255,
    1
  }
  theme.editText.backgroundColor = {
    255 / 255,
    255 / 255,
    255 / 255,
    1
  }
  theme.editText.focusStrokeColor = {
    57 / 255,
    104 / 255,
    149 / 255,
    1
  }
  theme.editText.unfocusStrokeColor = {
    41 / 255,
    50 / 255,
    59 / 255,
    1
  }
  theme.editText.cursorColor = {
    82 / 255,
    139 / 255,
    255 / 255,
    1
  }
  theme.editText.stroke = 1
end
local Theme
do
  local _class_0
  local _base_0 = {
    addProperty = function(self, name, value)
      if not self.properties[name] then
        self.properties[name] = value
      end
    end,
    getInstance = function(self)
      if self.instance == nil then
        self.instance = Theme()
      end
      return self.instance
    end,
    removeProperty = function(self, name)
      if not self.properties[name] then
        self.properties[name] = nil
      end
    end,
    setProperty = function(self, name, value)
      if self.properties[name] then
        self.properties[name] = value
      else
        return self:addProperty(name, value)
      end
    end,
    getProperty = function(self, name)
      if self.properties[name] then
        return self.properties[name]
      end
    end,
    saveThemeJson = function(self, path)
      local encoded = PrettyJson(self.properties)
      return File.writeFile(path, encoded)
    end,
    loadFromJson = function(self, path)
      if File.findFile(path) then
        local p = File.readFile(path)
        self.properties = Json.decode(p)
      end
    end
  }
  _base_0.__index = _base_0
  _class_0 = setmetatable({
    __init = function(self, path)
      self.properties = { }
      if path then
        self:loadFromJson(path)
      else
        self.properties = table.copy(theme)
      end
      self.instance = nil
    end,
    __base = _base_0,
    __name = "Theme"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  Theme = _class_0
end
return Theme
