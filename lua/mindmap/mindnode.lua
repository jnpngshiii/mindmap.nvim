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

---@param tbl table?
---@return table
function M.Mindnode:new(tbl)
	tbl = tbl or {}
	tbl.type = "mindnode"
	tbl = prototype.SimpleItem:new(tbl, card.Card)

	setmetatable(tbl, self)
	self.__index = self

	return tbl
end

----------
-- Class Method
----------

--------------------

return M
