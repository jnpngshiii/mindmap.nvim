local logger = require("logger").register_plugin("mindmap"):register_source("Edge.SelfLoop")

local BaseEdge = require("mindmap.base.BaseEdge")

--------------------
-- Class SelfLoopEdge
--------------------

---@class SelfLoopEdge : BaseEdge
local SelfLoopEdge = {}
SelfLoopEdge.__index = SelfLoopEdge
setmetatable(SelfLoopEdge, BaseEdge)

function SelfLoopEdge:new(...)
  local ins = BaseEdge:new(...)
  setmetatable(ins, SelfLoopEdge)

  return ins
end

--------------------

return SelfLoopEdge
