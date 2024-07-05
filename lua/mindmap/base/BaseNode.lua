local logger = require("logger").register_plugin("mindmap"):register_source("Base.Node")

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

  base_node:upgrade()
  base_node:check_health()

  return base_node
end

---Upgrade the node to the latest version.
---To support version upgrades, implement functions named `upgrade_to_vX`
---where `X` is the version to upgrade to. Each function should only upgrade
---the node by one version.
---Example:
---  ```lua
---  ---Upgrade the item to version 11.
---  ---Return nothing if the upgrade succeeds.
---  ---Raise an error if the upgrade fails.
---  function BaseNode:upgrade_to_v11(self)
---    if self._version > 11 then
---      error("Cannot upgrade to version 11 from higher version " .. self._version)
---    end
---
---    self._new_field = "default_value"
---  end
---  ```
---For multi-version upgrades (e.g., v8 to v11), this function will
---sequentially call the appropriate upgrade functions (v8 to v9,
---v9 to v10, v10 to v11) in order. If an intermediate upgrade
---function is missing, the version number will be forcibly updated
---without any changes to the node's data.
---@return nil
function BaseNode:upgrade()
  local current_version = self._version
  local latest_version = base_node_version

  while current_version < latest_version do
    local next_version = current_version + 1
    local upgrade_func = self["upgrade_to_v" .. next_version]
    if upgrade_func then
      local ok, result = pcall(upgrade_func, self)
      if not ok then
        logger.error({
          content = "upgrade version failed",
          cause = result,
          extra_info = { from_version = current_version, to_version = next_version },
        })
      else
        logger.info({
          content = "upgrade version succeeded",
          extra_info = { from_version = current_version, to_version = next_version },
        })
      end
    else
      logger.warn({
        content = "upgrade version skipped",
        cause = "missing upgrade function",
        action = "version forcibly updated",
        extra_info = { from_version = current_version, to_version = next_version },
      })
    end

    self._version = next_version
    current_version = next_version
  end
end

---Basic health check for node.
---Subclasses should override this method.
---@return nil
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
    table.insert(issues, "Invalid `_created_at`: expected `number` or `nil`, got `" .. type(self._created_at) .. "`;")
  end
  if type(self._state) ~= "string" then
    table.insert(issues, "Invalid `_state`: expected `string` or `nil`, got `" .. type(self._state) .. "`;")
  end
  if type(self._version) ~= "number" then
    table.insert(issues, "Invalid `_version`: expected `number` or `nil`, got `" .. type(self._version) .. "`;")
  end

  if #issues ~= 0 then
    logger.error({ content = "health check failed", extra_info = { issues = issues } })
    error("health check failed")
  end
end

---Get the absolute path of the file where the node is from.
---@return string abs_file_path The absolute path of the file.
function BaseNode:get_abs_path()
  if self._cache.abs_file_path then
    return self._cache.abs_file_path
  end

  local abs_file_path = utils.get_abs_path(self._rel_file_dir, ({ utils.get_file_info() })[4]) .. "/" .. self._file_name

  self._cache.abs_file_path = abs_file_path
  return abs_file_path
end

---@abstract
---Get the content of the node.
---@param edge_type? EdgeType Type of the edge.
---@return string[] front, string[] back Content of the node.
---@diagnostic disable-next-line: unused-local
function BaseNode:get_content(edge_type)
  logger.warn({ content = "method 'get_content' not implemented", action = "operation skipped" })
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
  -- logger.warn({ content = "method 'before_add_into_graph' not implemented", action = "operation skipped" })
end

---@abstract
---Handle the node after adding it to the graph.
---@param ... any Additional arguments.
---@return nil
---@diagnostic disable-next-line: unused-vararg
function BaseNode:after_add_into_graph(...)
  -- logger.warn({ content = "method 'after_add_into_graph' not implemented", action = "operation skipped" })
end

---@abstract
---Handle the node before removing it from the graph.
---@param ... any Additional arguments.
---@return nil
---@diagnostic disable-next-line: unused-vararg
function BaseNode:before_remove_from_graph(...)
  -- logger.warn({ content = "method 'before_remove_from_graph' not implemented", action = "operation skipped" })
end

---@abstract
---Handle the node after removing it from the graph.
---@param ... any Additional arguments.
---@return nil
---@diagnostic disable-next-line: unused-vararg
function BaseNode:after_remove_from_graph(...)
  -- logger.warn({ content = "method 'after_remove_from_graph' not implemented", action = "operation skipped" })
end

--------------------

return BaseNode
