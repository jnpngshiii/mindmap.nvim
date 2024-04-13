local M = {}

M.getVisualSelection = function()
	local getMark = function(name)
		return vim.api.nvim_buf_get_mark(0, name)
	end

	local startPos = getMark("<")
	local endPos = getMark(">")

	local lines = vim.api.nvim_buf_get_lines(0, startPos[1] - 1, endPos[1], false)
	if #lines == 0 then
		return ""
	end

	lines[1] = lines[1]:sub(startPos[2] + 1)
	lines[#lines] = lines[#lines]:sub(1, endPos[2])

	-- 使用 table.concat 将表中的元素连接成一个字符串
	local concatenated_lines = table.concat(lines, "\n")

	vim.api.nvim_out_write("lines: " .. concatenated_lines .. "\n")
end

return M
