local misc = require("mindmap.misc")

---@class Node
---
---@field type string Type of the node.
---@field incoming_edge_ids string[] IDs of incoming edges to this node.
---@field outcoming_edge_ids string[] IDs of outcoming edges from this node.
---@field data table Data of the node. Subclass should put there own data in this field.
---@field id string ID of the node.
---@field created_at integer Created time of the node.
local Node = {}

--------------------
-- Instance Method
--------------------

---Create a new node.
---@param type string Type of the node.
---@param incoming_edge_ids? string[] IDs of incoming edges to this node.
---@param outcoming_edge_ids? string[] IDs of outcoming edges from this node.
---@param data? table Data of the node. Subclass should put there own data in this field.
---@param id? string ID of the node.
---@param created_at? integer Created time of the node.
function Node:new(type, incoming_edge_ids, outcoming_edge_ids, data, id, created_at)
	local node = {
		type = type,
		incoming_edge_ids = incoming_edge_ids or {},
		outcoming_edge_ids = outcoming_edge_ids or {},
		data = data or {},
		id = id or misc.get_unique_id(),
		created_at = created_at or tonumber(os.time()),
	}

	setmetatable(node, Node)
	self.__index = self

	return node
end

---Add incoming edge to node.
---@param incoming_edge_id string ID of the incoming edge to add.
---@return nil
function Node:add_from_edge(incoming_edge_id)
	table.insert(self.incoming_edge_ids, incoming_edge_id)
end

---Add outcoming edge to node.
---@param outcoming_edge_id string ID of the outcoming edge to add.
---@return nil
function Node:add_to_edge(outcoming_edge_id)
	table.insert(self.outcoming_edge_ids, outcoming_edge_id)
end

---@abstract
---Get content of the node.
---Subclass should implement this method.
function Node:content()
	error("[Node] Please implement this method in subclass.")
end

--------------------
-- Class Method
--------------------

---Convert a node to a table.
---@param node Node Node to be converted.
---@return table
function Node.to_table(node)
	return {
		type = node.type,
		incoming_edge_ids = node.incoming_edge_ids,
		outcoming_edge_ids = node.outcoming_edge_ids,
		data = node.data,
		id = node.id,
		created_at = node.created_at,
	}
end

---Convert a table to a node.
---@param table table Table to be converted.
---@return Node
function Node.from_table(table)
	return Node:new(
		table.type,
		table.incoming_edge_ids,
		table.outcoming_edge_ids,
		table.data,
		table.id,
		table.created_at
	)
end

--------------------

return Node
