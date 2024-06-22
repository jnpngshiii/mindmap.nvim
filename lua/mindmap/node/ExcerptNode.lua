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
function ExcerptNode:get_content(edge_type)
	if self.cache.get_content then
		return self.cache.get_content.front, self.cache.get_content.back
	end
	local front, back = {}, {}

	local excerpt = utils.get_file_content(
		self:get_abs_path(),
		self.data.start_row,
		self.data.end_row,
		self.data.start_col,
		self.data.end_col
	)
	front, back = excerpt, excerpt

	if not self.cache.get_content then
		self.cache.get_content = { front = front, back = back }
	end

	return front, back
end

--------------------

return ExcerptNode
