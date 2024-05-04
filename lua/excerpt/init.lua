local class = require("excerpt.class")

local M = {}

M.database = class.Database:init()

--- Create excerpt using the latest visual selection.
function M.create_excerpt_using_visual_selection()
	local base_dir = vim.fs.dirname(vim.api.nvim_buf_get_name(0))
	local base_name = vim.fs.basename(vim.api.nvim_buf_get_name(0))
	local start_row = vim.api.nvim_buf_get_mark(0, "<")[1]
	local start_col = vim.api.nvim_buf_get_mark(0, "<")[2]
	local end_row = vim.api.nvim_buf_get_mark(0, ">")[1]
	local end_col = vim.api.nvim_buf_get_mark(0, ">")[2]

	local start_position = class.Position:new(base_dir, base_name, start_row, start_col)
	local end_position = class.Position:new(base_dir, base_name, end_row, end_col)
	local visual_selection_excerpt = class.Excerpt:new(start_position, end_position)
	M.database:add(visual_selection_excerpt)

	vim.api.nvim_out_write("Create excerpt using the latest visual selection.\n")
end

return M
