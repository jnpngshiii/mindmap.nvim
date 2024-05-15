local prototype = require("mindmap.prototype")
local card = require("mindmap.card")
local excerpt = require("mindmap.excerpt")
local mindnode = require("mindmap.mindnode")
local misc = require("mindmap.misc")

-- ---@alias prototype.SimpleDatabase SimpleDatabase
-- ---@alias card.Card Card
-- ---@alias excerpt.Excerpt Excerpt

local M = {}

--------------------
-- Class Mindmap
--------------------

---@class Mindmap : SimpleItem
---@field mindnodes SimpleDatabase Mindnodes in the mindmap.
M.Mindmap = prototype.SimpleItem:new({
	mindnodes = prototype.SimpleDatabase:new(),
})

----------
-- Instance Method
----------

---@param obj table?
---@return table
function M.Mindmap:new(obj)
	obj = obj or {}

	obj.id = obj.id or ("mmp-" .. misc.get_unique_id())
	obj.type = obj.type or "mmp"
	obj.created_at = obj.created_at or tonumber(os.time())
	obj.updated_at = obj.updated_at or tonumber(os.time())

  obj.mindnodes = obj.mindnodes or self.mindnodes
	if obj.mindnodes then
		for k, v in pairs(obj.mindnodes) do
			obj.mindnodes[k] = mindnode.Mindnode:new(v)
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
