local prototype = require("mindmap.prototype")
local misc = require("mindmap.misc")

local M = {}

--------------------
-- Class Card
--------------------

---@class Card : SimpleItem
---@field due_at integer Due time of the card.
---@field ease integer Ease of the card.
---@field interval integer Interval of the card.
M.Card = {
	due_at = -1,
	ease = -1,
	interval = -1,
}

----------
-- Instance Method
----------

---@param obj table?
---@return table
function M.Card:new(obj)
	obj = obj or {}

	obj.id = "crd-" .. misc.get_unique_id()
	obj.created_at = tonumber(os.time())
	obj.updated_at = tonumber(os.time())

	setmetatable(obj, self)
	self.__index = self

	return obj
end

----------
-- Class Method
----------

--------------------

return M
