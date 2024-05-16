local prototype = require("mindmap.prototype")
local card = require("mindmap.card")

local M = {}

--------------------
-- Class Mindnode
--------------------

---@class Mindnode : SimpleItem
M.Mindnode = prototype.SimpleItem:new()

----------
-- Instance Method
----------

---Create a new mindnode object.
---@param tbl? table Table used to create the item.
---@param sub_item_class? SimpleItem Class of the sub items. Default: Card.
---@return table
function M.Mindnode:new(tbl, sub_item_class)
	tbl = tbl or {}
	tbl.type = "mindnode"
	tbl = prototype.SimpleItem:new(tbl, sub_item_class or card.Card)

	setmetatable(tbl, self)
	self.__index = self

	return tbl
end

----------
-- Class Method
----------

--------------------

return M
