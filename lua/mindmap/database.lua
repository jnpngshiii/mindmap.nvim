local prototype = require("mindmap.prototype")
local mindmap = require("mindmap.mindmap")

local M = {}

--------------------
-- Class Database
--------------------

---@class Database : SimpleItem
M.Database = prototype.SimpleItem:new()

----------
-- Instance Method
----------

---@param tbl table?
---@return table
function M.Database:new(tbl)
	tbl = tbl or {}
	tbl.type = "database"
	tbl = prototype.SimpleItem:new(tbl, mindmap.Mindmap)

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
