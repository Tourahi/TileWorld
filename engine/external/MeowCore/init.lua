MeowC = { }
do
  MeowC.base = (...)
  MeowC.core = {
    Box = assert(require(MeowC.base .. ".src.Core.Box")),
    Control = assert(require(MeowC.base .. ".src.Core.Control")),
    Event = assert(require(MeowC.base .. ".src.Core.Event")),
    Manager = assert(require(MeowC.base .. ".src.Core.Manager")),
    Root = assert(require(MeowC.base .. ".src.Core.Root")),
    Timer = assert(require(MeowC.base .. ".src.Core.Timer")),
    Theme = assert(require(MeowC.base .. ".src.MoonCore.Theme")),
    File = assert(require(MeowC.base .. ".src.MoonCore.File")),
    Flux = assert(require(MeowC.base .. ".src.libs.flux")),
    Colors = assert(require(MeowC.base .. ".src.MoonCore.Colors"))
  }
  MeowC.info = {
    author = "Tourahi Amine",
    catui = "https://github.com/wilhantian/catui",
    loveVersion = "11.3",
    stage = "Alpha"
  }
end
return assert(require(MeowC.base .. ".src.libs.utils"))
