local logger = require("logger").register_plugin("mindmap"):register_source("Node.Heading")

local BaseNode = require("mindmap.base.BaseNode")
local utils = require("mindmap.utils")
local ts_utils = require("mindmap.ts_utils")

--------------------
-- Class HeadingNode
--------------------

---@class HeadingNode : BaseNode
---@field _cache.ts_node userdata|nil See: `HeadingNode:get_ts_node`.
---@field _cache.ts_node_bufnr number|nil See: `HeadingNode:get_ts_node`.
local HeadingNode = {}
HeadingNode.__index = HeadingNode
setmetatable(HeadingNode, BaseNode)

function HeadingNode:new(...)
  local ins = BaseNode:new(...)
  setmetatable(ins, HeadingNode)

  return ins
end

----------
-- Basic Method
----------

---Get the treesitter node of the `HeadingNode`.
---@param bufnr? number The buffer number.
---@return TSNode? ts_node The treesitter node.
function HeadingNode:get_ts_node(bufnr)
  bufnr = bufnr or self._cache.ts_node_bufnr

  if self._cache.ts_node and type(self._cache.ts_node) == "userdata" then
    return self._cache.ts_node
  end

  local heading_node = ts_utils.get_heading_nodes(string.format("%08d", self._id), bufnr)[self._id]
  if not heading_node then
    logger.error({
      content = "retrieve treesitter node failed",
      cause = "node not found",
      extra_info = { id = self._id },
    })
    error("retrieve treesitter node failed")
  end

  self._cache.ts_node = heading_node
  self._cache.ts_node_bufnr = bufnr
  return heading_node
end

---Get the content of the node.
---@param edge_type EdgeType Type of the edge.
---@return string[] front, string[] back Content of the node.
function HeadingNode:get_content(edge_type)
  local _f = function(bufnr)
    local ts_node = self:get_ts_node(bufnr)
    if not ts_node then
      logger.warn({
        content = "retrieve treesitter node failed",
        cause = "node not found",
        extra_info = { id = self._id },
      })
      return { "No treesitter node found." }, { "No treesitter node found." }
    end
    local title_node, content_node, sub_heading_nodes = ts_utils.parse_heading_node(ts_node)
    if not title_node then
      logger.warn({
        content = "parse heading node failed",
        cause = "title node not found",
        extra_info = { id = self._id },
      })
      return { "No title node found." }, { "No title node found." }
    end

    local front = utils.split_string(vim.treesitter.get_node_text(title_node, bufnr), "\n")
    local back = {}

    if content_node and edge_type == "SelfLoopContentEdge" then
      back = utils.split_string(vim.treesitter.get_node_text(content_node, bufnr), "\n")
    elseif sub_heading_nodes and edge_type == "SelfLoopSubheadingEdge" then
      for _, sub_heading_node in ipairs(sub_heading_nodes) do
        table.insert(back, utils.split_string(vim.treesitter.get_node_text(sub_heading_node, bufnr), "\n"))
      end
    else
      back = { "No back found." }
    end

    return front, back
  end

  ---@diagnostic disable-next-line: return-type-mismatch, missing-return-value
  return utils.with_temp_bufnr(self:get_abs_path(), _f)
end

----------
-- Graph Method
----------

---Handle the node after adding it to the graph.
---@return nil
function HeadingNode:after_add_into_graph()
  local _f = function(bufnr)
    local ts_node = self:get_ts_node(bufnr)
    if not ts_node then
      logger.error({
        content = "add node to graph failed",
        cause = "treesitter node not found",
        extra_info = { id = self._id },
      })
      error("add node to graph failed")
    end
    local ts_node_title, _, _ = ts_utils.parse_heading_node(ts_node)
    if not ts_node_title then
      logger.error({
        content = "add node to graph failed",
        cause = "title node not found",
        extra_info = { id = self._id },
      })
      error("add node to graph failed")
    end

    local node_text = vim.treesitter.get_node_text(ts_node_title, bufnr)
    local success, err = pcall(
      ts_utils.replace_node_text,
      string.gsub(node_text, "$", " %%" .. string.format("%08d", self._id) .. "%%"),
      ts_node_title,
      self._cache.ts_node_bufnr
    )
    if not success then
      logger.error({ content = "update node text failed", cause = err, extra_info = { id = self._id } })
    else
      logger.info({ content = "add node to graph succeeded", extra_info = { id = self._id } })
    end
  end

  return utils.with_temp_bufnr(self:get_abs_path(), _f)
end

---Handle the node before removing it from the graph.
---@return nil
function HeadingNode:before_remove_from_graph()
  local _f = function(bufnr)
    local ts_node = self:get_ts_node(bufnr)
    if not ts_node then
      logger.error({
        content = "remove node from graph failed",
        cause = "treesitter node not found",
        extra_info = { id = self._id },
      })
      error("remove node from graph failed")
    end
    local ts_node_title, _, _ = ts_utils.parse_heading_node(ts_node)
    if not ts_node_title then
      logger.error({
        content = "remove node from graph failed",
        cause = "title node not found",
        extra_info = { id = self._id },
      })
      error("remove node from graph failed")
    end

    local node_text = vim.treesitter.get_node_text(ts_node_title, bufnr)
    local success, err = pcall(
      ts_utils.replace_node_text,
      string.gsub(node_text, " %%" .. string.format("%08d", self._id) .. "%%", ""),
      ts_node_title,
      self._cache.ts_node_bufnr
    )
    if not success then
      logger.error({ content = "update node text failed", cause = err, extra_info = { id = self._id } })
    else
      logger.info({ content = "remove node from graph succeeded", extra_info = { id = self._id } })
    end
  end

  return utils.with_temp_bufnr(self:get_abs_path(), _f)
end

--------------------

return HeadingNode
