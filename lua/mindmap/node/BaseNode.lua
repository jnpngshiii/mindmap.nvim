local utils = require("mindmap.utils")

--------------------
-- Class BaseNode
--------------------

---@alias NodeID integer
---@alias NodeType string

---@class BaseNode
---Mandatory fields:
---@field _type NodeType Type of the node.
---@field _id NodeID ID of the node.
---@field _file_name string Name of the file where the node is from.
---@field _rel_file_dir string Relative dir to the project dir of the file where the node is from.
---Optional fields:
---@field _data table Data of the node. Subclass should put there own data in this field.
---@field _cache table Cache of the node.
---@field _cache.abs_file_path string See: `BaseNode.get_abs_path`.
---@field _created_at integer Created time of the node in UNIX timestemp format.
---@field _state string State of the edge. Can be "active", "removed", and "archived". Default: "active".
---@field _version integer Version of the node.
local BaseNode = {}
BaseNode.__index = BaseNode

local base_node_version = 10
-- v0: Initial version.
-- v1: Add `tag` field.
-- v2: Remove `id` field.
-- v3: Make `type` field auto generated.
-- v4: Factory.
-- v5: Add `id` field and `state` field.
-- v6: Add `[before|after]_[add_into|remove_from]_graph` methods.
-- v7: Move `[from|to]_table` methods to `NodeFactory`.
-- v8: Rename to `BaseNode`.
-- v9: Remove `tag`, `incoming_edge_ids`, `outcoming_edge_ids` fields, and rename `rel_file_path` to `rel_file_dir`.
-- v10: Rename `field` to `_field`.

----------
-- Basic Method
----------

---Create a new node.
---Mandatory fields:
---@param _type NodeType Type of the node.
---@param _id NodeID ID of the node.
---@param _file_name string Name of the file where the node is from.
---@param _rel_file_dir string Relative dir to the project dir of the file where the node is from.
---Optional fields:
---@param _data? table Data of the node. Subclass should put there own data in this field.
---@param _cache? table of the node.
---@param _created_at? integer Created time of the node in UNIX timestemp format.
---@param _state? string State of the node. Default to "active". Can be "active", "removed", and "archived".
---@param _version? integer Version of the node.
---@return BaseNode _ The created node.
function BaseNode:new(
	_type,
	_id,
	_file_name,
	_rel_file_dir,
	--
	_data,
	_cache,
	_created_at,
	_state,
	_version
)
	local base_node = {
		_type = type,
		_id = _id,
		_file_name = _file_name,
		_rel_file_dir = _rel_file_dir,
		--
		_data = _data or {},
		_cache = _cache or {},
		_created_at = _created_at or tonumber(os.time()),
		_state = _state or "active",
		_version = _version or base_node_version,
	}
	base_node.__index = base_node
	setmetatable(base_node, BaseNode)

	return base_node
end

---Get the absolute path of the file where the node is from.
---@return string _ The absolute path of the file.
function BaseNode:get_abs_path()
	if self._cache.abs_file_path then
		return self._cache.abs_file_path
	end

	local abs_file_path = utils.get_abs_path(self._rel_file_dir, utils.get_file_info()[4]) .. "/" .. self._file_name

	self._cache.abs_file_path = abs_file_path
	return abs_file_path
end

---@abstract
---Get the content of the node.
---@param edge_type EdgeType Type of the edge.
---@return string[] front, string[] back Content of the node.
---@diagnostic disable-next-line: unused-local
function BaseNode:get_content(edge_type)
	vim.notify("[BaseNode] Method `get_content` is not implemented.")
	return {}, {}
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
	vim.notify("[BaseNode] Method `before_add_into_graph` is not implemented.")
end

---@abstract
---Handle the node after adding into the graph.
---@return nil _ This function does not return anything.
---@diagnostic disable-next-line: unused-vararg
function BaseNode:after_add_into_graph(...)
	vim.notify("[BaseNode] Method `after_add_into_graph` is not implemented.")
end

---@abstract
---Handle the node before removing from the graph.
---@return nil _ This function does not return anything.
---@diagnostic disable-next-line: unused-vararg
function BaseNode:before_remove_from_graph(...)
	vim.notify("[BaseNode] Method `before_remove_from_graph` is not implemented.")
end

---@abstract
---Handle the node after removing from the graph.
---@return nil _ This function does not return anything.
---@diagnostic disable-next-line: unused-vararg
function BaseNode:after_remove_from_graph(...)
	vim.notify("[BaseNode] Method `after_remove_from_graph` is not implemented.")
end

--------------------

return BaseNode
