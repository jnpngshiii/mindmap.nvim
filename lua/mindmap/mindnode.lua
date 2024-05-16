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
		id = "test_mindnode",
	})

	local card_1 = card.Card:new({
		id = "test_card_1",
	})
	mn:add(card_1)

	local simple_item_1_1 = prototype.SimpleItem:new({
		id = "test_simple_item_1_1",
	})
	card_1:add(simple_item_1_1)

	local simple_item_1_2 = prototype.SimpleItem:new({
		id = "test_simple_item_1_2",
	})
	card_1:add(simple_item_1_2)

	local card_2 = card.Card:new({
		id = "test_card_2",
	})
	mn:add(card_2)

	local simple_item_2_1 = prototype.SimpleItem:new({
		id = "test_simple_item_2_1",
	})
	card_2:add(simple_item_2_1)

	mn:save()
end

return M
