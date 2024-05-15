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
M.Mindmap = {
	mindnodes = prototype.SimpleDatabase:new(),
}

----------
-- Instance Method
----------

---@param obj table?
---@return table
function M.Mindmap:new(obj)
	obj = obj or {}

	obj.id = "mmp-" .. misc.get_unique_id()
	obj.created_at = tonumber(os.time())
	obj.updated_at = tonumber(os.time())

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
