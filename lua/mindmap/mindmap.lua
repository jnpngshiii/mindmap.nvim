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

---Create a new mindmap object.
---@param tbl? table Table used to create the item.
---@param sub_item_class? SimpleItem Class of the sub items. Default: Mindnode.
---@return table
function M.Mindmap:new(tbl, sub_item_class)
	tbl = tbl or {}
	tbl.type = "mindmap"
	tbl = prototype.SimpleItem:new(tbl, sub_item_class or mindnode.Mindnode)

	setmetatable(tbl, self)
	self.__index = self

	return tbl
end

----------
-- Class Method
----------

--------------------

return M
