local card = require("mindmap.card")
local excerpt = require("mindmap.excerpt")
local misc = require("mindmap.misc")

---@alias card.Card Card
---@alias excerpt.Excerpt Excerpt

local M = {}

--------------------
-- Class Mindnode
--------------------

---@class Mindnode
---@field mindnode_id string ID of the mindnode. Example: "mnode-01234567890-0123".
---@field excerpt_tbl table<string, Excerpt> Excerpts in the mindnode.
---@field card_tbl table<string, Card> Cards in the mindnode.
M.Mindnode = {
	mindnode_id = "",
	excerpt_tbl = {},
	card_tbl = {},
}

----------
-- Instance Method
----------

---@param obj table?
---@return table
function M.Mindnode:new(obj)
	obj = obj or {}

	local mindnode_id = "mnode-" .. misc.get_unique_id()
	obj.mindnode_id = obj.mindnode_id or mindnode_id or self.mindnode_id

	obj.excerpt_tbl = obj.excerpt_tbl or self.excerpt_tbl
	if obj.excerpt_tbl then
		for k, v in pairs(obj.excerpt_tbl) do
			obj.excerpt_tbl[k] = excerpt.Excerpt:new(v)
		end
	end

	obj.card_tbl = obj.card_tbl or self.card_tbl
	if obj.card_tbl then
		for k, v in pairs(obj.card_tbl) do
			obj.card_tbl[k] = card.Card:new(v)
		end
	end

	setmetatable(obj, self)
	self.__index = self

	return obj
end

---Add an excerpt to the mindnode.
---@param xpt Excerpt Excerpt to be added.
---@return nil
function M.Mindnode:add_excerpt(xpt)
	self.excerpt_tbl[xpt.id] = xpt
end

---Add a card to the mindnode.
---@param crd Card Card to be added.
---@return nil
function M.Mindnode:add_card(crd)
	self.card_tbl[crd.id] = crd
end

---Find an excerpt in the mindnode.
---If the excerpt is not found and register_if_not is true, then generate, register and return a new excerpt.
---@param id string ID of the excerpt to be found.
---@param register_if_not boolean Register a new excerpt if not found.
---@return Excerpt|nil
function M.Mindnode:find_excerpt(id, register_if_not)
	local found_excerpt = self.excerpt_tbl[id]
	if not found_excerpt and register_if_not then
		found_excerpt = excerpt.Excerpt:new({ excerpt_id = id })
		self.excerpt_tbl[id] = found_excerpt
	end
	return found_excerpt
end

---Find a card in the mindnode.
---If the card is not found and register_if_not is true, then generate, register and return a new card.
---@param id string ID of the card to be found.
---@param register_if_not boolean Register a new card if not found.
---@return Card|nil
function M.Mindnode:find_card(id, register_if_not)
	local found_card = self.card_tbl[id]
	if not found_card and register_if_not then
		found_card = card.Card:new({ card_id = id })
		self.card_tbl[id] = found_card
	end
	return found_card
end

----------
-- Class Method
----------

--------------------

return M
