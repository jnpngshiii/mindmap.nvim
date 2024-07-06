local logger = require("logger").register_plugin("mindmap"):register_source("Factory.Alg")

local BaseFactory = require("mindmap.base.BaseFactory")

--------------------
-- Class AlgFactory
--------------------

---@class AlgFactory : BaseFactory
local AlgFactory = {}
AlgFactory.__index = AlgFactory
setmetatable(AlgFactory, BaseFactory)

---Create a new factory.
---@param base_cls table Base class of the factory. Registered classes should inherit from this class.
---@return AlgFactory factory The created factory.
function AlgFactory:new(base_cls)
  local factory = {
    base_cls = base_cls,
    registered_cls = {},
  }
  setmetatable(factory, AlgFactory)

  return factory
end

--------------------

return AlgFactory
