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

---@param tbl table?
---@return table
function M.Card:new(tbl)
	tbl = tbl or {}
	tbl.type = "card"
	tbl = prototype.SimpleItem:new(tbl, prototype.SimpleItem)

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
