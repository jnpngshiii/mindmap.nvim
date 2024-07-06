local logger = require("logger").register_plugin("mindmap"):register_source("Edge.Simple")

local BaseEdge = require("mindmap.base.BaseEdge")

--------------------
-- Class SimpleEdge
--------------------

---@class SimpleEdge : BaseEdge
local SimpleEdge = {}
SimpleEdge.__index = SimpleEdge
setmetatable(SimpleEdge, BaseEdge)

function SimpleEdge:new(...)
  local ins = BaseEdge:new(...)
  setmetatable(ins, SimpleEdge)

  return ins
end

--------------------

return SimpleEdge
