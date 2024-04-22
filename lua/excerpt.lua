local M = {}

--------------------
-- MISC
--------------------

local function getRelativePath(basePath, targetPath)
	local baseParts = {}
	local targetParts = {}

	for part in string.gmatch(basePath, "[^/]+") do
		table.insert(baseParts, part)
	end

	for part in string.gmatch(targetPath, "[^/]+") do
		table.insert(targetParts, part)
	end

	local i = 1
	while baseParts[i] == targetParts[i] and baseParts[i] ~= nil and targetParts[i] ~= nil do
		i = i + 1
	end

	local relativePath = ""
	for j = i, #baseParts do
		relativePath = relativePath .. "../"
	end

	for j = i, #targetParts do
		relativePath = relativePath .. targetParts[j] .. "/"
	end

	return relativePath
end

--------------------
-- MAIN
--------------------

M.sr_info_table = {}

M.saveVisualSelection = function(range_start, range_end)
	-- 如果未提供范围，则使用默认范围 '<,'>，表示选中的部分
	range_start = range_start or "<"
	range_end = range_end or ">"

	-- 获取选中部分的起始和结束位置
	local cursor_pos1 = vim.api.nvim_buf_get_mark(0, range_start)
	local cursor_pos2 = vim.api.nvim_buf_get_mark(0, range_end)

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

	-- 获取当前 buffer 的文件路径
	local file_path = vim.api.nvim_buf_get_name(0)

	-- 保存选中部分的信息
	M.sr_info_table = {
		file_path = file_path,
		start_row = start_line,
		start_col = start_col,
		end_row = end_line,
		end_col = end_col,
	}

	vim.api.nvim_out_write("Visual selection saved.\n")
end

M.appendSavedVisualSelection = function()
	local start_row = M.sr_info_table.start_row
	local start_col = M.sr_info_table.start_col
	local end_row = M.sr_info_table.end_row
	local end_col = M.sr_info_table.end_col
	local file_path = M.sr_info_table.file_path

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

	M.sr_info_table.file_path = getRelativePath(vim.api.nvim_buf_get_name(0), M.sr_info_table.file_path)
	local sr_info = table.concat({
		M.sr_info_table.file_path,
		M.sr_info_table.start_row,
		M.sr_info_table.start_col,
		M.sr_info_table.end_row,
		M.sr_info_table.end_col,
	}, "::")

	local cursor_pos = vim.api.nvim_win_get_cursor(0)
	local cursor_line = vim.api.nvim_buf_get_lines(0, cursor_pos[1] - 1, cursor_pos[1], false)[1]
	local new_cursor_line = string.gsub(cursor_line, "$", " " .. "%" .. sr_info)
	vim.api.nvim_buf_set_lines(0, cursor_pos[1] - 1, cursor_pos[1], false, { new_cursor_line })

	-- 提取选中的文本
	local selected_lines = {}
	for i = start_row, end_row do
		if i == start_row then
			-- 如果是起始行，从起始列开始提取
			table.insert(selected_lines, lines[i]:sub(start_col + 1))
		elseif i == end_row then
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

M.getSavedVisualSelection = function() end

return M
