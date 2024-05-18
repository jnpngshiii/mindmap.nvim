local misc = require("mindmap.misc")

---@class Node
---
---@field id string Node ID.
---@field type string Node type. Default: "node". This field is reserved for future use.
---
---@field created_at integer Node created time.
---@field data table Data of the node. This field is reserved for future use.
---
---@field from_edge_ids string[] Edge IDs from this node.
---@field to_edge_ids string[] Edge IDs to this node.
local Node = {}

--------------------
-- Instance Method
--------------------

---Create a new node.
---@param id? string Node ID.
---@param type? string Node type. Default: "node".
---@param created_at? integer Node created time.
---@param data? table Data of the node. Subclass should put there own data in this field.
---@param from_edge_ids? string[] Edge IDs from this node.
---@param to_edge_ids? string[] Edge IDs to this node.
function Node:new(id, type, created_at, data, from_edge_ids, to_edge_ids)
	local node = {
		id = id or misc.get_unique_id(),
		type = type or "node",

		created_at = created_at or tonumber(os.time()),
		data = data or {},

		from_edge_ids = from_edge_ids or {},
		to_edge_ids = to_edge_ids or {},
	}

	setmetatable(node, Node)
	self.__index = self

	return node
end

---Add "from" edge to node.
---@param from_edge_id string "From" edge to add.
function Node:add_from_edge(from_edge_id)
	table.insert(self.from_edge_ids, from_edge_id)
end

---Add "to" edge to node.
---@param to_edge_id string "To" edge ID to add.
---@return nil
function Node:add_to_edge(to_edge_id)
	table.insert(self.to_edge_ids, to_edge_id)
end

---Get content of the node.
---Subclass should implement this method.
function Node:content()
	error("Not implemented")
end

--------------------
-- Class Method
--------------------

---Convert node to table.
---@param node Node Node to convert.
---@return table
function Node.to_table(node)
	return {
		id = node.id,
		type = node.type,
		created_at = node.created_at,
		data = node.data,
		from_edge_ids = node.from_edge_ids,
		to_edge_ids = node.to_edge_ids,
	}
end

---Convert table to node.
---@param table table Table to convert.
---@return Node
function Node.from_table(table)
	return Node:new(table.id, table.type, table.created_at, table.data, table.from_edge_ids, table.to_edge_ids)
end

--------------------

return Node
