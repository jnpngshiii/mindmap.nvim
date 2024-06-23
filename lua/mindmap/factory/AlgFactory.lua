local BaseFactory = require("mindmap.factory.BaseFactory")

--------------------
-- Class AlgFactory
--------------------

---@class AlgFactory : BaseFactory
local AlgFactory = {}
AlgFactory.__index = AlgFactory
setmetatable(AlgFactory, BaseFactory)

--------------------

return AlgFactory
