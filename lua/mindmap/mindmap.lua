local mindnode = require("mindmap.mindnode")

---@alias mindnode.Mindnode Mindnode

local M = {}

--------------------
-- Class Mindmap
--------------------

---@class Mindmap
---@field mindmap_id string ID of the mindnode. Example: "mmap-01234567890-0123".
---@field mindnode_tbl table<string, Mindnode> Mindnodes in the mindmap.
M.Mindmap = {
	mindmap_id = "",
	mindnode_tbl = {},
}

----------
-- Instance Method
----------

---@param obj table?
---@return table
function M.Mindmap:new(obj)
	obj = obj or {}
	obj.mindmap_id = obj.mindmap_id or self.mindmap_id
	obj.mindnode_tbl = obj.mindnode_tbl or self.mindnode_tbl

	setmetatable(obj, self)
	self.__index = self

	return obj
end

----------
-- Class Method
----------

--------------------

return M
