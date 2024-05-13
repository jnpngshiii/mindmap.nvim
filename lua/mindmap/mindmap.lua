local mindnode = require("mindmap.mindnode")

---@alias mindnode.Mindnode Mindnode

local M = {}

--------------------
-- Class Mindnode
--------------------

---@class Mindnode
---@field mindmap_id string ID of the mindnode. Example: "mmap-01234567890-0123".
---@field mindnode_table table<string, Mindnode> Mindnodes in the mindmap.
M.Mindmap = {
	mindmap_id = "",
	mindnode_table = {},
}

----------
-- Instance Method
----------

---@param obj table?
---@return table
function M.Mindmap:new(obj)
	obj = obj or {}
	obj.mindmap_id = obj.mindmap_id or self.mindmap_id
	obj.mindnode_table = obj.mindnode_table or self.mindnode_table

	setmetatable(obj, self)
	self.__index = self

	return obj
end

----------
-- Class Method
----------

--------------------

return M
