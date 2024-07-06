local logger = require("logger").register_plugin("mindmap"):register_source("Edge.Children")

local BaseEdge = require("mindmap.base.BaseEdge")

--------------------
-- Class ChildrenEdge
--------------------

---@class ChildrenEdge : BaseEdge
local ChildrenEdge = {}
ChildrenEdge.__index = ChildrenEdge
setmetatable(ChildrenEdge, BaseEdge)

function ChildrenEdge:new(...)
  local ins = BaseEdge:new(...)
  setmetatable(ins, ChildrenEdge)

  return ins
end

--------------------

return ChildrenEdge
