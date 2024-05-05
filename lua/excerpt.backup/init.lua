local class_database = require("excerpt.class_database")
local class_excerpt = require("excerpt.class_excerpt")
local class_lineparser = require("excerpt.class_lineparser")

local M = {}

M.excerpt_database = class_database.ExcerptDatabase:init()

M.save_lastest_excerpts_to_current_file = function()
	local cursor_line_num = vim.api.nvim_win_get_cursor(0)[1]
	local cursor_file_path = vim.api.nvim_buf_get_name(0)
	local line_parser = class_lineparser.ExcerptLineParser:new(
		cursor_file_path,
		cursor_line_num,
		"<[^:]+::[^:]+::[^:]+::[^:]+::[^:]>",
		"::"
	)
	-- vim.api.nvim_out_write(#M.excerpt_database.cache)
	-- line_parser:add_excerpts(M.excerpt_database:pop(#M.excerpt_database.cache))
	line_parser:add_excerpt(M.excerpt_database:pop(1))
end

return M
