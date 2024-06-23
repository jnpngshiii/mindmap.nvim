local BaseFactory = require("mindmap.factory.BaseFactory")

--------------------
-- Class NodeFactory
--------------------

---@class NodeFactory : BaseFactory
local NodeFactory = {}
NodeFactory.__index = NodeFactory
setmetatable(NodeFactory, BaseFactory)

---Convert a node to a table.
---@param node BaseNode The node to be converted.
---@return table _ The converted table.
function NodeFactory:to_table(node)
	return {
		_type = node._type,
		_id = node._id,
		_file_name = node._file_name,
		_rel_file_dir = node._rel_file_dir,
		--
		_data = node._data,
		-- _cache = node._cache,
		_created_at = node._created_at,
		_state = node._state,
		_version = node._version,
	}
end

---Convert a table to a node.
---@param registered_type string Which registered type the table should be converted to.
---@param tbl table The table to be converted.
---@return BaseNode? _ The converted node.
function NodeFactory:from_table(registered_type, tbl)
	local registered_cls = self:get_registered_class(registered_type)
	if not registered_cls then
		vim.notify(
			"[EdgeFactory] Type `" .. registered_type .. "` is not registered. Aborte converting.",
			vim.log.levels.ERROR
		)
		return
	end

	return registered_cls:new(
		tbl._type,
		tbl._id,
		tbl._file_name,
		tbl._rel_file_dir,
		--
		tbl._data,
		{}, -- tbl._cache,
		tbl._created_at,
		tbl._state,
		tbl._version
	)
end

--------------------

return NodeFactory
