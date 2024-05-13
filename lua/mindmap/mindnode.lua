local card = require("mindmap.card")
local excerpt = require("mindmap.excerpt")

---@alias card.Card Card
---@alias excerpt.Excerpt Excerpt

local M = {}

--------------------
-- Class Mindnode
--------------------

---@class Mindnode
---@field mnode_id string ID of the mindnode. Example: "mnode-01234567890-0123".
---@field excerpt_list Excerpt[] List of excerpts in the mindnode.
---@field card_list Card[] List of cards in the mindnode.
M.Mindnode = {
	mnode_id = "",
	excerpt_list = {},
	card_list = {},
}

----------
-- Instance Method
----------

---@param obj table?
---@return table
function M.Mindnode:new(obj)
	obj = obj or {}
	obj.mnode_id = obj.mnode_id or self.mnode_id
	obj.excerpt_list = obj.excerpt_list or self.excerpt_list
	obj.card_list = obj.card_list or self.card_list

	setmetatable(obj, self)
	self.__index = self

	return obj
end

----------
-- Class Method
----------

--------------------

return M
