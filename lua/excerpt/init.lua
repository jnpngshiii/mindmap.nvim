local class = require("excerpt.class")

local M = {}

--- Initialize database.
function M.init_database()
	return nil
end

M.database = M.init_database() or {}

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
	M.database[#M.database + 1] = visual_selection_excerpt

	vim.api.nvim_out_write("Create excerpt using the latest visual selection.\n")
end

function M.show_lastest_excerpt()
	local content = M.database[#M.database]:get_excerpt()
	vim.api.nvim_out_write(table.concat(content, "\n"))
end

return M
