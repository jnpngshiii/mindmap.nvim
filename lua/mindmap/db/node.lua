local misc = require("mindmap.misc")

---@alias ID string

---@class Node
---
---@field type string Type of the node.
---@field incoming_edge_ids table<ID, ID> IDs of incoming edges to this node.
---@field outcoming_edge_ids table<ID, ID> IDs of outcoming edges from this node.
---@field data table Data of the node. Subclass should put there own data in this field.
---@field id string ID of the node.
---@field created_at integer Created time of the node.
local Node = {}

--------------------
-- Instance Method
--------------------

---Create a new node.
---@param type string Type of the node.
---@param incoming_edge_ids? table<ID, ID> IDs of incoming edges to this node.
---@param outcoming_edge_ids? table<ID, ID> IDs of outcoming edges from this node.
---@param data? table Data of the node. Subclass should put there own data in this field.
---@param id? ID ID of the node.
---@param created_at? integer Created time of the node.
---@return Node
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

---Add incoming edge to the node.
---@param incoming_edge_id ID ID of the incoming edge to add.
---@return nil
function Node:add_incoming_edge_id(incoming_edge_id)
	self.incoming_edge_ids[incoming_edge_id] = incoming_edge_id
end

---Remove incoming edge from the node.
---@param incoming_edge_id ID ID of the incoming edge to remove.
---@return nil
function Node:remove_incoming_edge_id(incoming_edge_id)
	self.incoming_edge_ids[incoming_edge_id] = nil
end

---Add outcoming edge to the node.
---@param outcoming_edge_id ID ID of the outcoming edge to add.
---@return nil
function Node:add_outcoming_edge_id(outcoming_edge_id)
	self.outcoming_edge_ids[outcoming_edge_id] = outcoming_edge_id
end

---Remove outcoming edge from the node.
---@param outcoming_edge_id ID ID of the outcoming edge to remove.
---@return nil
function Node:remove_outcoming_edge_id(outcoming_edge_id)
	self.outcoming_edge_ids[outcoming_edge_id] = nil
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
