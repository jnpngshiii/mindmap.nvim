local logger = require("mindmap.Logger"):register_source("Node.Heading")

local utils = require("mindmap.utils")
local ts_utils = require("mindmap.ts_utils")

--------------------
-- Class HeadingNode
--------------------

---@class HeadingNode : BaseNode
---@field _cache.ts_node userdata|nil See: `HeadingNode:get_ts_node`.
---@field _cache.ts_node_bufnr number|nil See: `HeadingNode:get_ts_node`.
local HeadingNode = {}

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
    logger.error("Cannot find the treesitter node with id: `" .. self._id .. "`. Aborting retrieval.")
    return
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
      return { "No treesitter node found." }, { "No treesitter node found." }
    end
    local title_node, content_node, sub_heading_nodes = ts_utils.parse_heading_node(ts_node)
    if not title_node then
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
      logger.error("Cannot find the treesitter node. Failed to call `after_add_into_graph`.")
      return
    end
    local ts_node_title, _, _ = ts_utils.parse_heading_node(ts_node)
    if not ts_node_title then
      logger.error("Cannot find the title node. Failed to call `after_add_into_graph`.")
      return
    end

    local node_text = vim.treesitter.get_node_text(ts_node_title, bufnr)
    ts_utils.replace_node_text(
      string.gsub(node_text, "$", " %%" .. string.format("%08d", self._id) .. "%%"),
      ts_node_title,
      self._cache.ts_node_bufnr
    )
  end

  ---@diagnostic disable-next-line: return-type-mismatch
  return utils.with_temp_bufnr(self:get_abs_path(), _f)
end

---Handle the node before removing it from the graph.
---@return nil
function HeadingNode:before_remove_from_graph()
  local _f = function(bufnr)
    local ts_node = self:get_ts_node(bufnr)
    if not ts_node then
      logger.error("Cannot find the treesitter node. Failed to call `before_remove_from_graph`.")
      return
    end
    local ts_node_title, _, _ = ts_utils.parse_heading_node(ts_node)
    if not ts_node_title then
      logger.error("Cannot find the title node. Failed to call `before_remove_from_graph`.")
      return
    end

    local node_text = vim.treesitter.get_node_text(ts_node_title, bufnr)
    ts_utils.replace_node_text(
      string.gsub(node_text, " %%" .. string.format("%08d", self._id) .. "%%", ""),
      ts_node_title,
      self._cache.ts_node_bufnr
    )
  end

  ---@diagnostic disable-next-line: return-type-mismatch
  return utils.with_temp_bufnr(self:get_abs_path(), _f)
end

--------------------

return HeadingNode
