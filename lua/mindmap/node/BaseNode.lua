local utils = require("mindmap.utils")

--------------------
-- Class BaseNode
--------------------

---@alias NodeID integer
---@alias NodeType string

---@class BaseNode
---Mandatory fields:
---@field id NodeID ID of the node.
---@field type NodeType Type of the node.
---@field file_name string Name of the file where the node is from.
---@field rel_file_path string Relative path to the project root of the file where the node is from.
---Optional fields:
---@field data table Data of the node. Subclass should put there own data in this field.
---@field tag table<string, string> Tag of the node. Experimental.
---@field state string State of the node. Default to "active". Can be "active", "removed", and "archived". Experimental.
---@field version integer Version of the node. Experimental.
---@field created_at integer Created time of the node in UNIX timestemp format.
---@field incoming_edge_ids EdgeID[] Ids of incoming edges to this node.
---@field outcoming_edge_ids EdgeID[] Ids of outcoming edges from this node.
---
---@field cache table<string, any> Cache of the node.
local BaseNode = {}
BaseNode.__index = BaseNode

local base_node_version = 8
-- v0: Initial version.
-- v1: Add `tag` field.
-- v2: Remove `id` field.
-- v3: Make `type` field auto generated.
-- v4: Factory.
-- v5: Add `id` field and `state` field.
-- v6: Add `[before|after]_[add_into|remove_from]_graph` methods.
-- v7: Move `[from|to]_table` methods to `NodeFactory`.
-- v8: Rename to `BaseNode`.

----------
-- Basic Method
----------

---Create a new node.
---@param type NodeType Type of the node.
---@param id NodeID ID of the node.
---@param file_name string Name of the file where the node is from.
---@param rel_file_path string Relative path to the project root of the file where the node is from.
---
---@param data? table Data of the node. Subclass should put there own data in this field.
---@param tag? table<string, string> Tag of the node.
---@param state? string State of the node. Default to "active". Can be "active", "removed", and "archived".
---@param version? integer Version of the node.
---@param created_at? integer Created time of the node in UNIX timestemp format.
---@param incoming_edge_ids? EdgeID[] Ids of incoming edges to this node.
---@param outcoming_edge_ids? EdgeID[] Ids of outcoming edges from this node.
---@return BaseNode _ The created node.
function BaseNode:new(
	type,
	id,
	file_name,
	rel_file_path,
	--
	data,
	tag,
	state,
	version,
	created_at,
	incoming_edge_ids,
	outcoming_edge_ids
)
	local base_node = {
		type = type,
		id = id,
		file_name = file_name,
		rel_file_path = rel_file_path,
		--
		data = data or {},
		tag = tag or {},
		state = state or "active",
		version = version or base_node_version,
		created_at = created_at or tonumber(os.time()),
		incoming_edge_ids = incoming_edge_ids or {},
		outcoming_edge_ids = outcoming_edge_ids or {},
		--
		cache = {},
	}
	base_node.__index = base_node
	setmetatable(base_node, BaseNode)

	return base_node
end

---Add incoming edge to the node.
---@param incoming_edge_id EdgeID ID of the incoming edge to be added.
---@return nil _ This function does not return anything.
function BaseNode:add_incoming_edge_id(incoming_edge_id)
	table.insert(self.incoming_edge_ids, incoming_edge_id)
end

---Remove incoming edge from the node.
---@param incoming_edge_id EdgeID ID of the incoming edge to be removed.
---@return nil _ This function does not return anything.
function BaseNode:remove_incoming_edge_id(incoming_edge_id)
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
function BaseNode:add_outcoming_edge_id(outcoming_edge_id)
	table.insert(self.outcoming_edge_ids, outcoming_edge_id)
end

---Remove outcoming edge from the node.
---@param outcoming_edge_id EdgeID ID of the outcoming edge to be removed.
---@return nil _ This function does not return anything.
function BaseNode:remove_outcoming_edge_id(outcoming_edge_id)
	for i = 1, #self.outcoming_edge_ids do
		if self.outcoming_edge_ids[i] == outcoming_edge_id then
			table.remove(self.outcoming_edge_ids, i)
			break
		end
	end
end

---Get the absolute path of the file where the node is from.
---@return string _ The absolute path of the file.
function BaseNode:get_abs_path()
	return utils.get_abs_path(self.rel_file_path, utils.get_file_info()[4]) .. "/" .. self.file_name
end

---@abstract
---Get the content of the node.
---@param edge_type EdgeType Type of the edge.
---@return string[] front, string[] back Content of the node.
---@diagnostic disable-next-line: unused-local
function BaseNode:get_content(edge_type)
	error("[BaseNode] Please implement function `get_content` in subclass.")
end

----------
-- Graph Method
-- TODO: How to remove there methods?
----------

---@abstract
---Handle the node before adding into the graph.
---@return nil _ This function does not return anything.
---@diagnostic disable-next-line: unused-vararg
function BaseNode:before_add_into_graph(...)
	-- error("[BaseNode] Please implement function `before_add_into_graph` in subclass.")
end

---@abstract
---Handle the node after adding into the graph.
---@return nil _ This function does not return anything.
---@diagnostic disable-next-line: unused-vararg
function BaseNode:after_add_into_graph(...)
	-- error("[BaseNode] Please implement function `after_add_into_graph` in subclass.")
end

---@abstract
---Handle the node before removing from the graph.
---@return nil _ This function does not return anything.
---@diagnostic disable-next-line: unused-vararg
function BaseNode:before_remove_from_graph(...)
	-- error("[BaseNode] Please implement function `before_remove_from_graph` in subclass.")
end

---@abstract
---Handle the node after removing from the graph.
---@return nil _ This function does not return anything.
---@diagnostic disable-next-line: unused-vararg
function BaseNode:after_remove_from_graph(...)
	-- error("[BaseNode] Please implement function `after_remove_from_graph` in subclass.")
end

--------------------

return BaseNode
