local prototype = require("mindmap.prototype")
local mindnode = require("mindmap.mindnode")

local M = {}

--------------------
-- Class Mindmap
--------------------

---@class Mindmap : SimpleItem
M.Mindmap = prototype.SimpleItem:new()

----------
-- Instance Method
----------

---@param tbl table?
---@return table
function M.Mindmap:new(tbl)
	tbl = tbl or {}
	tbl.type = "mindmap"
	tbl = prototype.SimpleItem:new(tbl, mindnode.Mindnode)

	tbl.created_at = tbl.created_at or tonumber(os.time())
	tbl.updated_at = tbl.updated_at or tonumber(os.time())

	setmetatable(tbl, self)
	self.__index = self

	return tbl
end

----------
-- Class Method
----------

--------------------

return M
