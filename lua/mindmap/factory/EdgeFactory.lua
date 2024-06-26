local BaseFactory = require("mindmap.factory.BaseFactory")

--------------------
-- Class EdgeFactory
--------------------

---@class EdgeFactory : BaseFactory
local EdgeFactory = {}
EdgeFactory.__index = EdgeFactory
setmetatable(EdgeFactory, BaseFactory)

---Convert an edge to a table.
---@param edge BaseEdge The edge to be converted.
---@return table edge_table The converted table.
function EdgeFactory:to_table(edge)
	return {
		_type = edge._type,
		_id = edge._id,
		_from = edge._from,
		_to = edge._to,
		--
		_data = edge._data,
		_cache = edge._cache,
		_created_at = edge._created_at,
		_updated_at = edge._updated_at,
		_due_at = edge._due_at,
		_ease = edge._ease,
		_interval = edge._interval,
		_answer_count = edge._answer_count,
		_ease_count = edge._ease_count,
		_again_count = edge._again_count,
		_state = edge._state,
		_version = edge._version,
	}
end

---Convert a table to an edge.
---@param registered_type string Which registered type the table should be converted to.
---@param tbl table The table to be converted.
---@return BaseEdge? edge The converted edge or nil if conversion fails.
function EdgeFactory:from_table(registered_type, tbl)
	local registered_cls = self:get_registered_class(registered_type)
	if not registered_cls then
		vim.notify(
			"[EdgeFactory] Type `" .. registered_type .. "` is not registered. Aborting conversion.",
			vim.log.levels.ERROR
		)
		return
	end

	return registered_cls:new(
		tbl._type,
		tbl._id,
		tbl._from,
		tbl._to,
		--
		tbl._data,
		tbl._cache,
		tbl._created_at,
		tbl._updated_at,
		tbl._due_at,
		tbl._ease,
		tbl._interval,
		tbl._answer_count,
		tbl._ease_count,
		tbl._again_count,
		tbl._state,
		tbl._version
	)
end

--------------------

return EdgeFactory
