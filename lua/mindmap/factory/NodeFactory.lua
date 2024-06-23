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
		type = node.type,
		id = node.id,
		file_name = node.file_name,
		rel_file_path = node.rel_file_path,
		--
		data = node.data,
		tag = node.tag,
		state = node.state,
		version = node.version,
		created_at = node.created_at,
		incoming_edge_ids = node.incoming_edge_ids,
		outcoming_edge_ids = node.outcoming_edge_ids,
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
		tbl.type,
		tbl.id,
		tbl.file_name,
		tbl.rel_file_path,
		--
		tbl.data,
		tbl.tag,
		tbl.state,
		tbl.version,
		tbl.created_at,
		tbl.incoming_edge_ids,
		tbl.outcoming_edge_ids
	)
end

--------------------

return NodeFactory
