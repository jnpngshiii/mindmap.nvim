local utils = require("mindmap.utils")
local ts_utils = require("mindmap.ts_utils")

--------------------
-- Class PrototypeNode
--------------------

---@alias NodeID integer
---@alias NodeType string

---@class PrototypeNode
---Mandatory fields:
---@field id NodeID ID of the node.
---@field file_name string Name of the file where the node is from.
---@field rel_file_path string Relative path to the project root of the file where the node is from.
---Optional fields:
---@field data table Data of the node. Subclass should put there own data in this field.
---@field type NodeType Type of the node.
---@field tag table<string, string> Tag of the node. Experimental.
---@field state string State of the node. Default to "active". Can be "active", "removed", and "archived". Experimental.
---@field version integer Version of the node. Experimental.
---@field created_at integer Created time of the node in UNIX timestemp format.
---@field incoming_edge_ids EdgeID[] Ids of incoming edges to this node.
---@field outcoming_edge_ids EdgeID[] Ids of outcoming edges from this node.
---@field cache table<string, any> Cache of the node.
local PrototypeNode = {}

local prototype_node_version = 5
-- v0: Initial version.
-- v1: Add `tag` field.
-- v2: Remove `id` field.
-- v3: Make `type` field auto generated.
-- v4: Factory.
-- v5: Add `id` field and `state` field.

----------
-- Instance Method
----------

---Create a new node.
---@param id NodeID ID of the node.
---@param file_name string Name of the file where the node is from.
---@param rel_file_path string Relative path to the project root of the file where the node is from.
---
---@param data? table Data of the node. Subclass should put there own data in this field.
---@param type? NodeType Type of the node.
---@param tag? table<string, string> Tag of the node.
---@param state? string State of the node. Default to "active". Can be "active", "removed", and "archived".
---@param version? integer Version of the node.
---@param created_at? integer Created time of the node in UNIX timestemp format.
---@param incoming_edge_ids? EdgeID[] Ids of incoming edges to this node.
---@param outcoming_edge_ids? EdgeID[] Ids of outcoming edges from this node.
---@return PrototypeNode _ The created node.
function PrototypeNode:new(
	id,
	file_name,
	rel_file_path,
	--
	data,
	type,
	tag,
	state,
	version,
	created_at,
	incoming_edge_ids,
	outcoming_edge_ids
)
	local prototype_node = {
		id = id,
		file_name = file_name,
		rel_file_path = rel_file_path,
		--
		data = data or {},
		type = type or "PrototypeNode",
		tag = tag or {},
		state = state or "active",
		version = version or prototype_node_version,
		created_at = created_at or tonumber(os.time()),
		incoming_edge_ids = incoming_edge_ids or {},
		outcoming_edge_ids = outcoming_edge_ids or {},
		cache = {},
	}

	setmetatable(prototype_node, self)
	self.__index = self

	return prototype_node
end

---Add incoming edge to the node.
---@param incoming_edge_id EdgeID ID of the incoming edge to be added.
---@return nil _ This function does not return anything.
function PrototypeNode:add_incoming_edge_id(incoming_edge_id)
	table.insert(self.incoming_edge_ids, incoming_edge_id)
end

---Remove incoming edge from the node.
---@param incoming_edge_id EdgeID ID of the incoming edge to be removed.
---@return nil _ This function does not return anything.
function PrototypeNode:remove_incoming_edge_id(incoming_edge_id)
	for i = 1, #self.incoming_edge_ids do
		if self.incoming_edge_ids[i] == incoming_edge_id then
			table.remove(self.incoming_edge_ids, i)
			break
		end
	end
end

---Add outcoming edge to the node.
---@param outcoming_edge_id EdgeID ID of the outcoming edge to be added.
---@return nil _ This function does not return anything.
function PrototypeNode:add_outcoming_edge_id(outcoming_edge_id)
	table.insert(self.outcoming_edge_ids, outcoming_edge_id)
end

---Remove outcoming edge from the node.
---@param outcoming_edge_id EdgeID ID of the outcoming edge to be removed.
---@return nil _ This function does not return anything.
function PrototypeNode:remove_outcoming_edge_id(outcoming_edge_id)
	for i = 1, #self.outcoming_edge_ids do
		if self.outcoming_edge_ids[i] == outcoming_edge_id then
			table.remove(self.outcoming_edge_ids, i)
			break
		end
	end
end

---Get the absolute path of the file where the node is from.
function PrototypeNode:get_abs_path()
	return utils.get_abs_path(self.rel_file_path, utils.get_project_root()) .. "/" .. self.file_name
end

---Get the corresponding tree-sitter node of the node.
---@param create_buf_if_not_exist? boolean|string Create a new buffer if the buffer does not exist, and how to create it. Can be nil, true, false, "h" or "v". Default: nil.
---@return TSNode? ts_node, integer bufnr, boolean is_temp_buf The corresponding TS node, buffer number, and whether the buffer is a temp buffer.
function PrototypeNode:get_corresponding_ts_node(create_buf_if_not_exist)
	local abs_path = self:get_abs_path()
	local bufnr, is_temp_buf = utils.giiit_bufnr(abs_path, create_buf_if_not_exist)
	local ts_node = ts_utils.get_heading_node_by_id(self.id, bufnr)
	return ts_node, bufnr, is_temp_buf
end

---@abstract
---Get the content of the node.
---@param edge_type EdgeType Type of the edge.
---@return string[] front ,string[] back Content of the node.
---@diagnostic disable-next-line: unused-local
function PrototypeNode:get_content(edge_type)
	error("[PrototypeNode] Please implement function `get_content` in subclass.")
end

---@abstract
---Convert the node to a table.
---@diagnostic disable-next-line: unused-vararg
function PrototypeNode:to_table(...)
	error("[PrototypeNode] Please implement function `to_table` in subclass.")
end

---@abstract
---Convert the table to a node.
---@diagnostic disable-next-line: unused-vararg
function PrototypeNode:from_table(...)
	error("[PrototypeNode] Please implement function `to_table` in subclass.")
end

----------
-- Class Method
----------

--------------------

return PrototypeNode
