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

if true then
	local mn = M.Mindnode:new({
		id = "0000",
	})

	local card_1 = M.Card:new({})
	mn:add(card_1)

	local card_2 = M.Card:new({})
	mn:add(card_2)

	mn:save()
end

return M
