local M = {}

M.selection = {}

M.saveVisualSelection = function()
	local cursor_pos1 = vim.api.nvim_buf_get_mark(0, "<")
	local cursor_pos2 = vim.api.nvim_buf_get_mark(0, ">")

	local start_line = math.min(cursor_pos1[1], cursor_pos2[1])
	local end_line = math.max(cursor_pos1[1], cursor_pos2[1])
	local start_col, end_col

	if start_line == cursor_pos1[1] then
		start_col = cursor_pos1[2]
		end_col = cursor_pos2[2]
	else
		start_col = cursor_pos2[2]
		end_col = cursor_pos1[2]
	end

	local file_path = vim.api.nvim_buf_get_name(0) -- 获取当前 buffer 的文件路径

	M.selection = {
		start_line = start_line,
		start_col = start_col,
		end_line = end_line,
		end_col = end_col,
		file_path = file_path, -- 将文件路径保存在 selection 表中
	}

	if file_path == nil then
		vim.api.nvim_out_write("Error: Cannot get file path.\n")
	else
		vim.api.nvim_out_write("Visual selection saved.\n")
		vim.api.nvim_out_write("Start line: " .. start_line .. "\n")
		vim.api.nvim_out_write("Start column: " .. start_col .. "\n")
		vim.api.nvim_out_write("End line: " .. end_line .. "\n")
		vim.api.nvim_out_write("End column: " .. end_col .. "\n")
		vim.api.nvim_out_write("File path: " .. file_path .. "\n")
	end
end

M.getSavedVisualSelection = function()
	local start_line = M.selection.start_line
	local start_col = M.selection.start_col
	local end_line = M.selection.end_line
	local end_col = M.selection.end_col
	local file_path = M.selection.file_path

	local lines = {}
	local file = io.open(file_path, "r")
	if not file then
		vim.api.nvim_out_write("Error: Cannot open file.\n")
		return
	end
	for line in file:lines() do
		table.insert(lines, line)
	end
	file:close()

	-- 提取选中的文本
	local selected_lines = {}
	for i = start_line, end_line do
		if i == start_line then
			-- 如果是起始行，从起始列开始提取
			table.insert(selected_lines, lines[i]:sub(start_col + 1))
		elseif i == end_line then
			-- 如果是结束行，提取到结束列
			table.insert(selected_lines, lines[i]:sub(1, end_col))
		else
			-- 如果是中间行，提取整行
			table.insert(selected_lines, lines[i])
		end
	end

	-- 输出选中的文本
	local concatenated_lines = table.concat(selected_lines, "\n")
	vim.api.nvim_out_write("Selected text:\n" .. concatenated_lines .. "\n")
end

return M
