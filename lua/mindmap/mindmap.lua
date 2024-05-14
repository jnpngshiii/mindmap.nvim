local mindnode = require("mindmap.mindnode")
local misc = require("mindmap.misc")

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

	local mindmap_id = "mmap-" .. misc.get_unique_id()
	obj.mindmap_id = obj.mindmap_id or mindmap_id or self.mindmap_id

	obj.mindnode_tbl = obj.mindnode_tbl or self.mindnode_tbl
	if obj.mindnode_tbl then
		for k, v in pairs(obj.mindnode_tbl) do
			obj.mindnode_tbl[k] = mindnode.Mindnode:new(v)
		end
	end

	setmetatable(obj, self)
	self.__index = self

	return obj
end

---Add a mindnode to the mindmap.
---@param mnode Mindnode to be added.
---@return nil
function M.Mindmap:add_mindnode(mnode)
	self.mindnode_tbl[mnode.mindnode_id] = mnode
end

---Find a mindnode in the mindmap.
---If the mindnode is not found and register_if_not is true, then generate, register and return a new mindnode.
---@param id string ID of the mindnode to be found.
---@param register_if_not boolean Register a new mindnode if not found.
---@return Mindnode|nil
function M.Mindmap:find_mindnode(id, register_if_not)
	local found_mindnode = self.mindnode_tbl[id]
	if not found_mindnode and register_if_not then
		found_mindnode = mindnode.Mindnode:new({ mindnode_id = id })
		self.mindnode_tbl[id] = found_mindnode
	end
	return found_mindnode
end

----------
-- Class Method
----------

--------------------

return M
