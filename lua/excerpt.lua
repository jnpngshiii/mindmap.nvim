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
	while baseParts[i] == targetParts[i] and baseParts[i] do
		i = i + 1
	end

	local relativePath = ""
	for j = i, #baseParts do
		relativePath = relativePath .. "../"
	end

	relativePath = relativePath .. table.concat(targetParts, "/", i)

	return relativePath:sub(4, -1)
end

--------------------
-- MAIN
--------------------

M.excerpt_info_table = {}

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

	-- 保存选中部分的信息
	M.excerpt_info_table = {
		file_path = vim.api.nvim_buf_get_name(0),
		start_row = start_line,
		start_col = start_col,
		end_row = end_line,
		end_col = end_col,
	}

	vim.api.nvim_out_write("Visual selection saved.\n")
end

M.appendSavedVisualSelection = function()
	M.excerpt_info_table.file_path = getRelativePath(vim.api.nvim_buf_get_name(0), M.excerpt_info_table.file_path)
	local excerpt_info = table.concat({
		M.excerpt_info_table.file_path,
		M.excerpt_info_table.start_row,
		M.excerpt_info_table.start_col,
		M.excerpt_info_table.end_row,
		M.excerpt_info_table.end_col,
	}, "::")

	local currrent_cursor = vim.api.nvim_win_get_cursor(0)
	local current_line = vim.api.nvim_buf_get_lines(0, currrent_cursor[1] - 1, currrent_cursor[1], false)[1]

	local new_cursor_line = string.gsub(current_line, "$", " " .. "%% <<" .. excerpt_info .. ">> %%")

	vim.api.nvim_buf_set_lines(0, currrent_cursor[1] - 1, currrent_cursor[1], false, { new_cursor_line })
end

M.getSavedVisualSelection = function()
	local currrent_cursor = vim.api.nvim_win_get_cursor(0)
	local current_line = vim.api.nvim_buf_get_lines(0, currrent_cursor[1] - 1, currrent_cursor[1], false)[1]

	local excerpt_info = {}
	local excerpt_info_regex = "<<([^>]*)>>"
	for info in current_line:gmatch(excerpt_info_regex) do
		local excerpt_info_slice = {}
		local excerpt_info_slice_regex = "([^::]+)"
		for slice in info:gmatch(excerpt_info_slice_regex) do
			table.insert(excerpt_info_slice, slice)
		end
		table.insert(excerpt_info, excerpt_info_slice)
	end

	local file_path = excerpt_info[1][1]
	local start_row = excerpt_info[1][2]
	local start_col = excerpt_info[1][3]
	local end_row = excerpt_info[1][4]
	local end_col = excerpt_info[1][5]

	-- for i, v in ipairs(excerpt_info[1]) do
	-- 	vim.api.nvim_out_write(v .. "\n")
	-- end

	local file = io.open(file_path, "r")
	if not file then
		vim.api.nvim_out_write("Error: Cannot open file.\n")
		return
	end

	local lines = {}
	for line in file:lines() do
		table.insert(lines, line)
	end
	file:close()

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

return M
