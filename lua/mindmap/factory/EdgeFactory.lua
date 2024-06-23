local BaseFactory = require("mindmap.factory.BaseFactory")

--------------------
-- Class EdgeFactory
--------------------

---@class EdgeFactory : BaseFactory
local EdgeFactory = {}
EdgeFactory.__index = EdgeFactory
setmetatable(EdgeFactory, BaseFactory)

---Convert a edge to a table.
---@param edge BaseEdge The edge to be converted.
---@return table _ The converted table.
function EdgeFactory:to_table(edge)
	return {
		id = edge.id,
		from_node_id = edge.from_node_id,
		to_node_id = edge.to_node_id,
		--
		data = edge.data,
		type = edge.type,
		tag = edge.tag,
		state = edge.state,
		version = edge.version,
		created_at = edge.created_at,
		updated_at = edge.updated_at,
		due_at = edge.due_at,
		ease = edge.ease,
		interval = edge.interval,
		answer_count = edge.answer_count,
		ease_count = edge.ease_count,
		again_count = edge.again_count,
	}
end

---Convert a table to a edge.
---@param registered_type string Which registered type the table should be converted to.
---@param tbl table The table to be converted.
---@return BaseEdge? _ The converted edge.
function EdgeFactory:from_table(registered_type, tbl)
	local registered_cls = self:get_registered_class(registered_type)
	if not registered_cls then
		vim.notify("[EdgeFactory] Type `" .. registered_type .. "` is not registered. Aborte converting.", vim.log.levels.ERROR)
		return
	end

	return registered_cls:new(
		tbl.id,
		tbl.from_node_id,
		tbl.to_node_id,
		--
		tbl.data,
		tbl.type,
		tbl.tag,
		tbl.state,
		tbl.version,
		tbl.created_at,
		tbl.updated_at,
		tbl.due_at,
		tbl.ease,
		tbl.interval,
		tbl.answer_count,
		tbl.ease_count,
		tbl.again_count
	)
end

--------------------

return EdgeFactory
