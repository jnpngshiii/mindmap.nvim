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

---@param tbl? table Table used to create the item.
---@param sub_item_class? SimpleItem Class of the sub items.
---@return table
function M.Database:new(tbl, sub_item_class)
	tbl = tbl or {}
	tbl.type = "database"
	tbl = prototype.SimpleItem:new(tbl, sub_item_class)

	setmetatable(tbl, self)
	self.__index = self

	return tbl
end

----------
-- Class Method
----------

--------------------

return M
