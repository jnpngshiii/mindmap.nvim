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
M.Card = prototype.SimpleItem:new({
	due_at = -1,
	ease = -1,
	interval = -1,
})

----------
-- Instance Method
----------

---@param obj table?
---@return table
function M.Card:new(obj)
	obj = obj or {}

	obj.id = obj.id or ("crd-" .. misc.get_unique_id())
	obj.type = obj.type or "crd"
	obj.created_at = obj.created_at or tonumber(os.time())
	obj.updated_at = obj.updated_at or tonumber(os.time())
  obj.due_at = obj.due_at or self.due_at
  obj.ease = obj.ease or self.ease
  obj.interval = obj.interval or self.interval

	setmetatable(obj, self)
	self.__index = self

	return obj
end

----------
-- Class Method
----------

--------------------

return M
