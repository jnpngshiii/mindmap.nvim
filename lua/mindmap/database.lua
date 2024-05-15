local prototype = require("mindmap.prototype")
local mindmap = require("mindmap.mindmap")
local excerpt = require("mindmap.excerpt")
local misc = require("mindmap.misc")

local M = {}

--------------------
-- Class Dababase
--------------------

---@class Mindnode : SimpleItem
---@field mindmaps SimpleDatabase All mindmaps.
---@field unused_excerpts SimpleDatabase Used excerpts.
M.Mindnode = prototype.SimpleItem:new({
	mindmaps = prototype.SimpleDatabase:new(),
	unused_excerpts = prototype.SimpleDatabase:new(),
})

----------
-- Instance Method
----------

---@param obj table?
---@return table
function M.Dababase:new(obj)
	obj = obj or {}

	obj.id = obj.id or ("db-" .. misc.get_unique_id())
	obj.type = obj.type or "db"
	obj.created_at = obj.created_at or tonumber(os.time())
	obj.updated_at = obj.updated_at or tonumber(os.time())

	obj.mindmaps = obj.mindmaps or self.mindmaps
	if obj.mindmaps then
		for k, v in pairs(obj.mindmaps) do
			obj.mindmaps[k] = mindmap.Mindmap:new(v)
		end
	end

	obj.unused_excerpts = obj.unused_excerpts or self.unused_excerpts
	if obj.unused_excerpts then
		for k, v in pairs(obj.unused_excerpts) do
			obj.unused_excerpts[k] = excerpt.Excerpt:new(v)
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
