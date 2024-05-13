local card = require("mindmap.card")
local excerpt = require("mindmap.excerpt")

---@alias card.Card Card
---@alias excerpt.Excerpt Excerpt

local M = {}

--------------------
-- Class Mindnode
--------------------

---@class Mindnode
---@field mindnode_id string ID of the mindnode. Example: "mnode-01234567890-0123".
---@field excerpt_table table<string, Excerpt> Excerpts in the mindnode.
---@field card_table table<string, Card> Cards in the mindnode.
M.Mindnode = {
	mindnode_id = "",
	excerpt_table = {},
	card_table = {},
}

----------
-- Instance Method
----------

---@param obj table?
---@return table
function M.Mindnode:new(obj)
	obj = obj or {}
	obj.mindnode_id = obj.mindnode_id or self.mindnode_id
	obj.excerpt_table = obj.excerpt_table or self.excerpt_table
	obj.card_table = obj.card_table or self.card_table

	setmetatable(obj, self)
	self.__index = self

	return obj
end

----------
-- Class Method
----------

--------------------

return M
