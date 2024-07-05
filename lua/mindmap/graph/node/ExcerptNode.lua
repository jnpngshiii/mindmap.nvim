local logger = require("logger").register_plugin("mindmap"):register_source("Node.Excerpt")

local BaseNode = require("mindmap.base.BaseNode")
local utils = require("mindmap.utils")

--------------------
-- Class ExcerptNode
--------------------

---@class ExcerptNode : BaseNode
---@field data.start_row integer Start row of the excerpt.
---@field data.start_col integer Start column of the excerpt.
---@field data.end_row integer End row of the excerpt.
---@field data.end_col integer End column of the excerpt.
local ExcerptNode = {}
ExcerptNode.__index = ExcerptNode
setmetatable(ExcerptNode, BaseNode)

function ExcerptNode:new(...)
  local ins = BaseNode:new(...)
  setmetatable(ins, ExcerptNode)

  return ins
end

----------
-- Basic Method
----------

---Get the content of the node.
---@param edge_type EdgeType Type of the edge.
---@return string[] front, string[] back Content of the node.
---@diagnostic disable-next-line: unused-local
function ExcerptNode:get_content(edge_type)
  local front, back = {}, {}

  local excerpt = utils.get_file_content(
    self:get_abs_path(),
    self._data.start_row,
    self._data.end_row,
    self._data.start_col,
    self._data.end_col
  )
  front, back = excerpt, excerpt

  return front, back
end

--------------------

return ExcerptNode
