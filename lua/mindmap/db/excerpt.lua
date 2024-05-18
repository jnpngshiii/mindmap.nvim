local Node = require("mindmap.db.node")
local misc = require("mindmap.misc")

--------------------
-- Class Excerpt
--------------------

---@class Excerpt : Node
---@field start_row integer Start row of the excerpt.
---@field start_col integer Start column of the excerpt.
---@field end_row integer End row of the excerpt.
---@field end_col integer End column of the excerpt.
local Excerpt = Node:new("excerpt", "", "") -- TODO: Needs improvement.

----------
-- Instance method
----------

---Create a new excerpt.
---@return Excerpt|Node
---@param rel_file_path string Relative path to the project root of the file where the excerpt is from.
---@param file_name string Name of the file where the excerpt is from.
---@param start_row integer Start row of the excerpt.
---@param start_col integer Start column of the excerpt.
---@param end_row integer End row of the excerpt.
---@param end_col integer End column of the excerpt.
function Excerpt:new(rel_file_path, file_name, start_row, start_col, end_row, end_col)
	local data = {
		start_row = start_row,
		start_col = start_col,
		end_row = end_row,
		end_col = end_col,
	}

	local excerpt = Node:new("excerpt", rel_file_path, file_name, data)

	setmetatable(excerpt, self)
	self.__index = self

	return excerpt
end

function Excerpt.excerpt_test()
	print("Excerpt test")
end

----------
-- Class method
----------

---Create a new Excerpt using the latest visual selection.
---@return Excerpt|Node
function Excerpt.create_using_latest_visual_selection()
	local abs_file_path = vim.api.nvim_buf_get_name(0)
	local abs_proj_path = misc.get_current_proj_path()

	local rel_file_path = misc.get_rel_path(abs_file_path, abs_proj_path)
	local file_name = misc.get_current_file_name()
	local start_row = vim.api.nvim_buf_get_mark(0, "<")[1]
	local start_col = vim.api.nvim_buf_get_mark(0, "<")[2]
	local end_row = vim.api.nvim_buf_get_mark(0, ">")[1]
	local end_col = vim.api.nvim_buf_get_mark(0, ">")[2]

	return Excerpt:new(rel_file_path, file_name, start_row, start_col, end_row, end_col)
end

--------------------

if false then
	local excerpt = Excerpt:new("rel_file_path", "file_name", 1, 2, 3, 4)
	excerpt:node_test()
	excerpt:excerpt_test()
end

return Excerpt
