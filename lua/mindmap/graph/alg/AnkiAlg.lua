local logger = require("logger").register_plugin("mindmap"):register_source("Alg.Anki")

local BaseAlg = require("mindmap.base.BaseAlg")

--------------------
-- Class AnkiAlg
--------------------

---@class AnkiAlg : BaseAlg
local AnkiAlg = {}
AnkiAlg.__index = AnkiAlg
setmetatable(AnkiAlg, BaseAlg)

function AnkiAlg:new(...)
  local ins = BaseAlg:new(...)
  setmetatable(ins, AnkiAlg)

  return ins
end

--------------------

return AnkiAlg
