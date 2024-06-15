local utils = require("mindmap.utils")

---@class ExcerptNode : PrototypeNode
---@field data.start_row integer Start row of the excerpt.
---@field data.start_col integer Start column of the excerpt.
---@field data.end_row integer End row of the excerpt.
---@field data.end_col integer End column of the excerpt.
---@field get_content fun(self: ExcerptNode, edge_type: EdgeType): string[], string[] Get the content of the node.
---@field create_using_latest_visual_selection fun(cls: table, self: HeadingNode, id: NodeID): ExcerptNode Create a new excerpt node using the latest visual selection.
local ExcerptNode = {
	data = {
		start_row = 0,
		end_row = 0,
		start_col = 0,
		end_col = 0,
	},
	ins_methods = {},
	cls_methods = {},
}

--------------------
-- Instance methods
--------------------

---Get the content of the node.
---@param self HeadingNode The node.
---@param edge_type EdgeType Type of the edge.
---@return string[] front ,string[] back Content of the node.
---@diagnostic disable-next-line: unused-local
function ExcerptNode.ins_methods.get_content(self, edge_type)
	local abs_proj_path = utils.get_file_info()[4]
	local abs_file_path = utils.get_abs_path(self.rel_file_path, abs_proj_path)

	local excerpt = utils.get_file_content(
		abs_file_path .. "/" .. self.file_name,
		self.data.start_row,
		self.data.end_row,
		self.data.start_col,
		self.data.end_col
	)

	return excerpt, excerpt
end

--------------------
-- Class methods
--------------------

---Create a new excerpt node using the latest visual selection.
---@param cls table The class.
---@param self HeadingNode The node.
---@param id NodeID ID of the node.
---@return ExcerptNode _ The created node.
---@diagnostic disable-next-line: unused-local
function ExcerptNode.cls_methods.create_using_latest_visual_selection(cls, self, id)
	-- FIXME: The first call will return { 0, 0 } for both marks
	local start_row = vim.api.nvim_buf_get_mark(0, "<")[1]
	local start_col = vim.api.nvim_buf_get_mark(0, "<")[2]
	local end_row = vim.api.nvim_buf_get_mark(0, ">")[1]
	local end_col = vim.api.nvim_buf_get_mark(0, ">")[2]

	local file_name, _, rel_file_path, _ = unpack(utils.get_file_info())
	return cls:new(id, file_name, rel_file_path, {
		start_row = start_row,
		start_col = start_col,
		end_row = end_row,
		end_col = end_col,
	})
end

--------------------

return ExcerptNode
