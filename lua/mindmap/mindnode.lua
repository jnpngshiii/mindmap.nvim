local prototype = require("mindmap.prototype")
local card = require("mindmap.card")
local excerpt = require("mindmap.excerpt")
local misc = require("mindmap.misc")

---@alias prototype.SimpleDatabase SimpleDatabase
---@alias card.Card Card
---@alias excerpt.Excerpt Excerpt

local M = {}

--------------------
-- Class Mindnode
--------------------

---@class Mindnode : SimpleItem
---@field excerpts SimpleDatabase Excerpts in the mindnode.
---@field cards SimpleDatabase Cards in the mindnode.
M.Mindnode = prototype.SimpleItem:new({
	excerpts = prototype.SimpleDatabase:new(),
	cards = prototype.SimpleDatabase:new(),
})

----------
-- Instance Method
----------

---@param obj table?
---@return table
function M.Mindnode:new(obj)
	obj = obj or {}

	obj.id = obj.id or ("mnd-" .. misc.get_unique_id())
	obj.type = obj.type or "mnd"
	obj.created_at = obj.created_at or tonumber(os.time())
	obj.updated_at = obj.updated_at or tonumber(os.time())

	obj.excerpts = obj.excerpts or self.excerpts
	if obj.excerpts then
		for k, v in pairs(obj.excerpts) do
			obj.excerpts[k] = excerpt.Excerpt:new(v)
		end
	end

	obj.cards = obj.cards or self.cards
	if obj.cards then
		for k, v in pairs(obj.cards) do
			obj.cards[k] = card.Card:new(v)
		end
	end

	setmetatable(obj, self)
	self.__index = self

	return obj
end

----------
-- Class Method
----------

--------------------

return M
