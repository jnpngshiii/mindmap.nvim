---@alias NodeID integer
---@alias NodeType string

--------------------
-- Class PrototypeNode
--------------------

---@class PrototypeNode
---Must provide fields in all node classes:
---@field type NodeType Type of the node.
---@field file_name string Name of the file where the node is from.
---@field rel_file_path string Relative path to the project root of the file where the node is from.
---Must provide Fields in some edge classes: subclass should put there own field in this field.
---@field data table Data of the node.
---Auto generated and updated fields:
---@field tag string[] Tag of the node.
---@field version integer Version of the node. Auto generated and updated.
---@field created_at integer Created time of the node in UNIX timestemp format. Auto generated.
---@field incoming_edge_ids table<EdgeID, EdgeID> IDs of incoming edges to this node. Auto generated and updated.
---@field outcoming_edge_ids table<EdgeID, EdgeID> IDs of outcoming edges from this node. Auto generated and updated.
---@field cache table Cache of the node. Save temporary data to avoid recalculation. Auto generated and updated.
local PrototypeNode = {}

local prototype_node_version = 0.2
-- v0.0: Initial version.
-- v0.1: Add `tag` field.
-- v0.2: Remove `id` field.

--------------------
-- Instance Method
--------------------

---Create a new node.
---@param type NodeType Type of the node.
---@param file_name string Name of the file where the node is from.
---@param rel_file_path string Relative path to the project root of the file where the node is from.
---
---@param data? table Data of the node. Subclass should put there own data in this field.
---
---@param tag? string[] Tag of the node.
---@param version? integer Version of the node.
---@param created_at? integer Created time of the node in Unix timestamp format.
---@param incoming_edge_ids? table<EdgeID, EdgeID> IDs of incoming edges to this node.
---@param outcoming_edge_ids? table<EdgeID, EdgeID> IDs of outcoming edges from this node.
---@return PrototypeNode _ The created node.
function PrototypeNode:new(
	type,
	file_name,
	rel_file_path,

	data,

	tag,
	version,
	created_at,
	incoming_edge_ids,
	outcoming_edge_ids
)
	local node = {
		type = type,
		file_name = file_name,
		rel_file_path = rel_file_path,

		data = data or {},

		tag = tag or {},
		created_at = created_at or tonumber(os.time()),
		incoming_edge_ids = incoming_edge_ids or {},
		outcoming_edge_ids = outcoming_edge_ids or {},
		version = version or prototype_node_version,
		cache = {},
	}

	setmetatable(node, self)
	self.__index = self

	return node
end

---Add incoming edge to the node.
---@param incoming_edge_id EdgeID ID of the incoming edge to be added.
---@return nil _ This function does not return anything.
function PrototypeNode:add_incoming_edge_id(incoming_edge_id)
	self.incoming_edge_ids[incoming_edge_id] = incoming_edge_id
end

---Remove incoming edge from the node.
---@param incoming_edge_id EdgeID ID of the incoming edge to be removed.
---@return nil _ This function does not return anything.
function PrototypeNode:remove_incoming_edge_id(incoming_edge_id)
	self.incoming_edge_ids[incoming_edge_id] = nil
end

---Add outcoming edge to the node.
---@param outcoming_edge_id EdgeID ID of the outcoming edge to be added.
---@return nil _ This function does not return anything.
function PrototypeNode:add_outcoming_edge_id(outcoming_edge_id)
	self.outcoming_edge_ids[outcoming_edge_id] = outcoming_edge_id
end

---Remove outcoming edge from the node.
---@param outcoming_edge_id EdgeID ID of the outcoming edge to be removed.
---@return nil _ This function does not return anything.
function PrototypeNode:remove_outcoming_edge_id(outcoming_edge_id)
	self.outcoming_edge_ids[outcoming_edge_id] = nil
end

---@abstract
---Get the content of the node.
---@return table _ Content of the node.
function PrototypeNode:get_content()
	error("[PrototypeNode] Please implement function `get_content` in subclass.")
end

--------------------
-- Class Method
--------------------

---Convert a node to a table.
---@param node PrototypeNode Node to be converted.
---@return table _ The converted table.
function PrototypeNode.to_table(node)
	return {
		type = node.type,
		file_name = node.file_name,
		rel_file_path = node.rel_file_path,

		data = node.data,

		tag = node.tag,
		version = node.version,
		created_at = node.created_at,
		incoming_edge_ids = node.incoming_edge_ids,
		outcoming_edge_ids = node.outcoming_edge_ids,
	}
end

---@abstract
---Convert a table to a node.
---@param table table Table to be converted.
---@return PrototypeNode _ The converted node.
function PrototypeNode.from_table(table)
	error("[PrototypeNode] Please implement function `from_table` in subclass.")
end

--------------------

return PrototypeNode
