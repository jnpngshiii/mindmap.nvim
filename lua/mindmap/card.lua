local prototype = require("mindmap.prototype")

local M = {}

--------------------
-- Class Card
--------------------

---@class Card : SimpleItem
---@field due_at integer Due time of the card.
---@field ease integer Ease of the card.
---@field interval integer Interval of the card.
M.Card = prototype.SimpleItem:new()

----------
-- Instance Method
----------

---Create a new card object.
---@param tbl? table Table used to create the item.
---@param sub_item_class? SimpleItem Class of the sub items. Default: nil.
---@return table
function M.Card:new(tbl, sub_item_class)
	tbl = tbl or {}
	tbl.type = "card"
	tbl = prototype.SimpleItem:new(tbl, sub_item_class or nil)

	tbl.due_at = tbl.due_at or 0
	tbl.ease = tbl.ease or 250
	tbl.interval = tbl.interval or 1 -- TODO: Needs investigation.

	setmetatable(tbl, self)
	self.__index = self

	return tbl
end

----------
-- Class Method
----------

--------------------

return M
