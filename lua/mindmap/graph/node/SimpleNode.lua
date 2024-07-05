local logger = require("logger").register_plugin("mindmap"):register_source("Node.Simple")

local BaseNode = require("mindmap.base.BaseNode")

--------------------
-- Class SimpleNode
--------------------

---@class SimpleNode : BaseNode
local SimpleNode = {}
SimpleNode.__index = SimpleNode
setmetatable(SimpleNode, BaseNode)

function SimpleNode:new(...)
  local ins = BaseNode:new(...)
  setmetatable(ins, SimpleNode)

  return ins
end

--------------------

return SimpleNode
