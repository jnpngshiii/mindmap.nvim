local M = {}

--------------------
-- Read file
--------------------

---Parse current line.
---@return string[]
function M.parse_current_line()
	local file_dir = M.get_current_file_dir()
	local file_name = M.get_current_file_name()
	local row = vim.api.nvim_win_get_cursor(0)[1]
	local col = vim.api.nvim_win_get_cursor(0)[2]
	local content = vim.api.nvim_buf_get_lines(0, row - 1, row, false)[1]
	return { file_dir, file_name, row, col, content }
end

--------------------
-- Helper
--------------------

--------------------

return M
