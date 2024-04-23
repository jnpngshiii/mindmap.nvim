local M = {}

-- TODO:
-- [ ] 优化 getRelativePath
-- [ ] 优化 saveVisualSelection 的工作流
-- [ ] 让抓取以浮动窗口的形式展示
-- [ ] 优化一行中多个摘录的处理
-- [ ] 允许为不同类型的文件自动添加不同类型的注释
-- [ ] 允许跳转打开
-- [ ] 允许快捷复制
-- [ ] 允许快捷删除
-- [ ] 允许高亮打开
-- [ ] 集成 telescope

M.config = {
	regex = "!![^!]+![^!]+![^!]+![^!]+![^!]+!!",
}

--------------------
-- MISC
--------------------

---@param regex string
---@param processer function
---@param fallbacker function
---@return nil
M.processCurrentLine = function(regex, processer, fallbacker)
	local cursor_row = vim.api.nvim_win_get_cursor(0)[1]
	local line_text = vim.api.nvim_buf_get_lines(0, cursor_row - 1, cursor_row, false)[1]
	local processed_line_text = line_text

	for matched_text in string.gmatch(line_text, regex) do
		local prcessed_text = processer(matched_text)
		processed_line_text = string.gsub(processed_line_text, matched_text, prcessed_text, 1)
	end

	if processed_line_text ~= line_text then
		vim.api.nvim_buf_set_lines(0, cursor_row - 1, cursor_row, false, { processed_line_text })
	else
		vim.api.nvim_buf_set_lines(0, cursor_row - 1, cursor_row, false, { fallbacker(line_text) })
	end
end

M.processer1 = function(text)
	return string.upper(text)
end

local function getRelativePath(basePath, targetPath)
	local baseParts = {}
	for part in string.gmatch(basePath, "[^/]+") do
		table.insert(baseParts, part)
	end

	local targetParts = {}
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

local function getAbsolutePath(currentPath, relativePath)
	currentPath = string.gsub(currentPath, "[^/]*$", "", 1)

	local function countOccurrences(inputString, pattern)
		local count = 0
		for _ in inputString:gmatch(pattern) do
			count = count + 1
		end
		return count
	end

	local occurrences = countOccurrences(relativePath, "%.%.")
	currentPath = string.gsub(currentPath, "[^/]*/$", "", occurrences)
	-- vim.api.nvim_out_write("currentPath: " .. currentPath .. "\n")
	relativePath = string.gsub(relativePath, "^%.%./", "", occurrences)
	-- vim.api.nvim_out_write("relativePath: " .. relativePath .. "\n")

	return currentPath .. relativePath
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

	-- 打开文件
	local abs_file_path = getAbsolutePath(vim.api.nvim_buf_get_name(0), file_path)
	local file = io.open(abs_file_path, "r")
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
	vim.api.nvim_out_write(concatenated_lines .. "\n")
end

return M
