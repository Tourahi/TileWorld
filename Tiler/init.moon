cwd = (...)\gsub('%.Tiler$', '') .. "."

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

    -- Initialize members

    if type(plugins) == "table"
      @loadPlugins plugins

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

