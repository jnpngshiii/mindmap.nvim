local logger = require("mindmap.Logger"):register_source("Node.Excerpt")

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
