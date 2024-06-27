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
---@field _rel_file_dir string Relative directory to the project directory of the file where the node is from.
---Optional fields:
---@field _data table Data of the node. Subclasses should put their own data in this field.
---@field _cache table Cache of the node.
---@field _cache.abs_file_path string See: `BaseNode:get_abs_path`.
---@field _created_at integer Creation time of the node in UNIX timestamp format.
---@field _state string State of the node. Can be "active", "removed", or "archived". Default: `"active"`.
---@field _version integer Version of the node.
local BaseNode = {}
BaseNode.__index = BaseNode

local base_node_version = 11
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
-- v11: Add `check_health` method.

----------
-- Basic Method
----------

---Create a new node.
---If the node has `check_health` method, it will be called automatically.
---Mandatory fields:
---@param _type NodeType Type of the node.
---@param _id NodeID ID of the node.
---@param _file_name string Name of the file where the node is from.
---@param _rel_file_dir string Relative directory to the project directory of the file where the node is from.
---Optional fields:
---@param _data? table Data of the node. Subclasses should put their own data in this field.
---@param _cache? table Cache of the node.
---@param _created_at? integer Creation time of the node in UNIX timestamp format.
---@param _state? string State of the node. Default is "active". Can be "active", "removed", or "archived".
---@param _version? integer Version of the node.
---@return BaseNode? base_node The created node, or nil if check health failed.
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
		_type = _type,
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

	if base_node.check_health then
		local issues = base_node:check_health()
		if #issues > 0 then
			vim.notify(
				"[BaseNode] Health check failed:\n" .. table.concat(issues, "\n") .. "\nReturn nil.",
				vim.log.levels.WARN
			)
			return nil
		end
	end

	return base_node
end

---Basic health check for node.
---Subclasses should override this method.
---@return string[] issues List of issues. Empty if the node is healthy.
function BaseNode:check_health()
	local issues = {}

	-- Check mandatory fields
	if type(self._type) ~= "string" then
		table.insert(issues, "Invalid `_type`: expected `string`, got `" .. type(self._type) .. "`;")
	end
	if type(self._id) ~= "number" then
		table.insert(issues, "Invalid `_id`: expected `number`, got `" .. type(self._id) .. "`;")
	end
	if type(self._file_name) ~= "string" then
		table.insert(issues, "Invalid `_file_name`: expected `string`, got `" .. type(self._file_name) .. "`;")
	end
	if type(self._rel_file_dir) ~= "string" then
		table.insert(issues, "Invalid `_rel_file_dir`: expected `string`, got `" .. type(self._rel_file_dir) .. "`;")
	end

	-- Check optional fields
	if type(self._data) ~= "table" then
		table.insert(issues, "Invalid `_data`: expected `table` or `nil`, got `" .. type(self._data) .. "`;")
	end
	if type(self._cache) ~= "table" then
		table.insert(issues, "Invalid `_cache`: expected `table` or `nil`, got `" .. type(self._cache) .. "`;")
	end
	if type(self._created_at) ~= "number" then
		table.insert(
			issues,
			"Invalid `_created_at`: expected `number` or `nil`, got `" .. type(self._created_at) .. "`;"
		)
	end
	if type(self._state) ~= "string" then
		table.insert(issues, "Invalid `_state`: expected `string` or `nil`, got `" .. type(self._state) .. "`;")
	end
	if type(self._version) ~= "number" then
		table.insert(issues, "Invalid `_version`: expected `number` or `nil`, got `" .. type(self._version) .. "`;")
	end

	return issues
end

---Get the absolute path of the file where the node is from.
---@return string abs_file_path The absolute path of the file.
function BaseNode:get_abs_path()
	if self._cache.abs_file_path then
		return self._cache.abs_file_path
	end

	local abs_file_path = utils.get_abs_path(self._rel_file_dir, ({ utils.get_file_info() })[4])
		.. "/"
		.. self._file_name

	self._cache.abs_file_path = abs_file_path
	return abs_file_path
end

---@abstract
---Get the content of the node.
---@param edge_type? EdgeType Type of the edge.
---@return string[] front, string[] back Content of the node.
---@diagnostic disable-next-line: unused-local
function BaseNode:get_content(edge_type)
	vim.notify("[BaseNode] Method `get_content` is not implemented.")
	return {}, {}
end

----------
-- Graph Method
-- TODO: How to remove these methods?
----------

---@abstract
---Handle the node before adding it to the graph.
---@param ... any Additional arguments.
---@return nil
---@diagnostic disable-next-line: unused-vararg
function BaseNode:before_add_into_graph(...)
	-- vim.notify("[BaseNode] Method `before_add_into_graph` is not implemented.")
end

---@abstract
---Handle the node after adding it to the graph.
---@param ... any Additional arguments.
---@return nil
---@diagnostic disable-next-line: unused-vararg
function BaseNode:after_add_into_graph(...)
	-- vim.notify("[BaseNode] Method `after_add_into_graph` is not implemented.")
end

---@abstract
---Handle the node before removing it from the graph.
---@param ... any Additional arguments.
---@return nil
---@diagnostic disable-next-line: unused-vararg
function BaseNode:before_remove_from_graph(...)
	-- vim.notify("[BaseNode] Method `before_remove_from_graph` is not implemented.")
end

---@abstract
---Handle the node after removing it from the graph.
---@param ... any Additional arguments.
---@return nil
---@diagnostic disable-next-line: unused-vararg
function BaseNode:after_remove_from_graph(...)
	-- vim.notify("[BaseNode] Method `after_remove_from_graph` is not implemented.")
end

--------------------

return BaseNode
