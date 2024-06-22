local utils = {}

--------------------
-- Helper functions
--------------------

---Match all patterns in the content.
---@param content string|string[]
---@param pattern string
---@return string[] _
function utils.match_pattern(content, pattern)
	local match_list = {}

	if type(content) == "table" then
		for _, c in ipairs(content) do
			local sub_match_list = utils.match_pattern(c, pattern)
			for _, sub_match in ipairs(sub_match_list) do
				table.insert(match_list, sub_match)
			end
		end
	else
		for part in string.gmatch(content, pattern) do
			table.insert(match_list, part)
		end
	end

	return match_list
end

---Split a string using the given separator.
---@param str string
---@param sep string
---@return table _
function utils.split_string(str, sep)
	local parts = {}
	for part in string.gmatch(str, "([^" .. sep .. "]+)") do
		table.insert(parts, part)
	end
	return parts
end

---Get the indent of a line.
---@param bufnr integer Buffer number.
---@param line_num integer Line number.
---@return string indent Indent of the line.
function utils.get_indent(bufnr, line_num)
	local line = vim.api.nvim_buf_get_lines(bufnr, line_num - 1, line_num, false)[1]
	local indent = line:match("^[%*%s]*"):gsub("[%*%s]", " ")
	return indent or ""
end

---Add virtual text in the given buffer in the given namespace.
---@param bufnr integer Buffer number.
---@param namespace number Namespace.
---@param line_num integer Line number.
---@param text string|string[] Text to be added as virtual text.
---@param text_type? string Type of the virtual text. Default: "Comment".
---@return nil _ This function does not return anything.
function utils.add_virtual_text(bufnr, namespace, line_num, text, text_type)
	if type(text) == "string" then
		text = { text }
	end

	local indent = utils.get_indent(bufnr, line_num)

	local virt_text = {}
	for _, t in ipairs(text) do
		table.insert(virt_text, { indent .. t, text_type or "Comment" })
	end

	vim.api.nvim_buf_set_extmark(bufnr, namespace, line_num - 1, -1, {
		-- TODO: use argument for virt_text_pos
		virt_text_pos = "overlay",
		virt_lines = {
			virt_text,
		},
		hl_mode = "combine",
	})
end

---Clear virtual text in the given buffer in the given namespace.
---@param bufnr integer Buffer number.
---@param namespace number Namespace.
---@param start_row? integer Start of range of lines to clear
---@param end_row? integer End of range of lines to clear (exclusive) or -1 to clear to end of buffer.
---@return nil _ This function does not return anything.
function utils.clear_virtual_text(bufnr, namespace, start_row, end_row)
	vim.api.nvim_buf_clear_namespace(bufnr, namespace, start_row or 0, end_row or -1)
end

---Convert relative path (target_path) to absolute path according to reference path (reference_path).
---Example: get_abs_path("../a/b", "/c/d") -> "/c/a/b"
---@param target_path string A path to be converted to an absolute path.
---@param reference_path string A reference path.
---@return string _
function utils.get_abs_path(target_path, reference_path)
	local target_path_parts = utils.split_string(target_path, "/")
	local reference_path_parts = utils.split_string(reference_path, "/")

	for _, part in ipairs(target_path_parts) do
		if part == ".." then
			table.remove(reference_path_parts)
		else
			table.insert(reference_path_parts, part)
		end
	end

	-- TODO: fix this workaround
	if string.sub(reference_path, 1, 1) == "/" then
		return "/" .. table.concat(reference_path_parts, "/")
	end

	return table.concat(reference_path_parts, "/")
end

---Convert absolute path (target_path) to relative path according to reference path (reference_path).
---Example: get_rel_path("/a/b/c", "/a/b/d") -> "../c"
---@param target_path string A path to be converted to a relative path.
---@param reference_path string A reference path.
---@return string _
function utils.get_rel_path(target_path, reference_path)
	local target_parts = utils.split_string(target_path, "/")
	local reference_parts = utils.split_string(reference_path, "/")
	local rel_path = {}

	while #target_parts > 0 and #reference_parts > 0 and target_parts[1] == reference_parts[1] do
		table.remove(target_parts, 1)
		table.remove(reference_parts, 1)
	end

	for _ = 1, #reference_parts do
		table.insert(rel_path, "..")
	end
	for _, part in ipairs(target_parts) do
		table.insert(rel_path, part)
	end

	return table.concat(rel_path, "/")
end

---Get the information of a buffer or a file.
---@param bufnr_or_file_path? integer|string Buffer number or file path of the file to be parsed.
---@return string[] _ { file_name, abs_file_path, rel_file_path, proj_path }
function utils.get_file_info(bufnr_or_file_path)
	bufnr_or_file_path = bufnr_or_file_path or 0

	local file_path
	if type(bufnr_or_file_path) == "string" then
		file_path = bufnr_or_file_path
	elseif type(bufnr_or_file_path) == "number" then
		file_path = vim.api.nvim_buf_get_name(bufnr_or_file_path)
	end

	local proj_path = vim.fn.fnamemodify(vim.trim(vim.fn.system("git rev-parse --show-toplevel")), ":p")
	--Remove "/" at the end
	proj_path = string.sub(proj_path, 1, -2)

	local file_name = vim.fs.basename(file_path)
	local abs_file_path = vim.fs.dirname(file_path)
	local rel_file_path = utils.get_rel_path(abs_file_path, proj_path)

	return { file_name, abs_file_path, rel_file_path, proj_path }
end

---Get the content of a buffer or a file.
---@param bufnr_or_file_path? integer|string Buffer number or file path of the file to be parsed.
---@param start_row? integer The start row of the range to be read.
---@param end_row? integer The end row of the range to be read.
---@param start_col? integer The start column of the range to be read.
---@param end_col? integer The end column of the range to be read.
---@return string[] _ { line1, line2, ... }
function utils.get_file_content(bufnr_or_file_path, start_row, end_row, start_col, end_col)
	bufnr_or_file_path = bufnr_or_file_path or 0

	local file_path
	if type(bufnr_or_file_path) == "string" then
		file_path = bufnr_or_file_path
	elseif type(bufnr_or_file_path) == "number" then
		file_path = vim.api.nvim_buf_get_name(bufnr_or_file_path)
	end

	local file = io.open(file_path, "r")
	if not file then
		return {}
	end

	local content = {}
	for line in file:lines() do
		table.insert(content, line)
	end
	file:close()

	start_row = start_row or 1 -- If not provided, start from the first row
	end_row = end_row or #content -- If not provided, end at the last row
	start_col = start_col or 0 -- If not provided, start from the first symbol of the line
	end_col = end_col or #content[end_row] -- If not provided, end at the last symbol of the line

	local range_content = {}
	for i = start_row, end_row do
		if i == start_row then
			table.insert(range_content, content[i]:sub(start_col + 1))
		elseif i == end_row then
			table.insert(range_content, content[i]:sub(1, end_col))
		else
			table.insert(range_content, content[i])
		end
	end

	return range_content
end

---Get the buffer number from the buffer number or file path.
---@param bufnr_or_file_path? integer|string Buffer number or file path. Default: 0.
---@param create_buf_if_not_exist? boolean|string Create a new buffer if the buffer does not exist, and how to create it. Can be nil, true, false, "h" or "v". Default: nil.
---@return integer bufnr, boolean is_temp_buf Buffer number and whether it is a temp buffer.
function utils.get_bufnr(bufnr_or_file_path, create_buf_if_not_exist)
	local bufnr = vim.fn.bufnr(bufnr_or_file_path or 0)
	local is_temp_buf = false

	if bufnr == -1 and create_buf_if_not_exist and type(bufnr_or_file_path) == "string" then
		local ok, content = pcall(vim.fn.readfile, bufnr_or_file_path)

		if ok then
			bufnr = vim.api.nvim_create_buf(false, true)
			vim.api.nvim_buf_set_lines(bufnr, 0, -1, true, content)

			if create_buf_if_not_exist == "h" then
				vim.cmd("new")
			elseif create_buf_if_not_exist == "v" then
				vim.cmd("vnew")
			else
				is_temp_buf = true
			end

			vim.api.nvim_win_set_buf(0, bufnr)
		else
			vim.notify('Failed to read file: "' .. bufnr_or_file_path .. '".', vim.log.levels.ERROR)
		end
	end

	return bufnr, is_temp_buf
end

---Remove fields that are not string, number, or boolean in a table.
---@param tbl table
---@return table _
function utils.remove_table_fields(tbl)
	local proccessed_tbl = tbl
	for k, v in pairs(proccessed_tbl) do
		if type(v) == "table" then
			utils.remove_table_fields(v)
		elseif type(v) ~= "string" and type(v) ~= "number" and type(v) ~= "boolean" then
			tbl[k] = nil
		end
	end
	return proccessed_tbl
end

---Limit the length of a string or a list of strings.
---@param str_or_list string|string[] String or list of strings to be limited.
---@param limitation integer Maximum length of each string.
---@return string[] _ The limited list of strings.
function utils.limit_string_length(str_or_list, limitation)
	local str
	if type(str_or_list) == "table" then
		str = table.concat(str_or_list, " ") -- TODO: chinese?
	elseif type(str_or_list) == "string" then
		str = str_or_list
	else
		return {}
	end

	local result = {}
	local start_index = 1
	local str_length = string.len(str)

	while start_index <= str_length do
		local end_index = start_index + limitation - 1
		if end_index > str_length then
			end_index = str_length
		end

		local substring = string.sub(str, start_index, end_index)
		table.insert(result, substring)

		start_index = end_index + 1
	end

	return result
end

---Get the latest visual selection.
---@return table _ { start_row, start_col, end_row, end_col }
function utils.get_latest_visual_selection()
	-- FIXME: The first call will return { 0, 0 } for both marks
	local start_row = vim.api.nvim_buf_get_mark(0, "<")[1]
	local start_col = vim.api.nvim_buf_get_mark(0, "<")[2]
	local end_row = vim.api.nvim_buf_get_mark(0, ">")[1]
	local end_col = vim.api.nvim_buf_get_mark(0, ">")[2]

	return {
		start_row = start_row,
		start_col = start_col,
		end_row = end_row,
		end_col = end_col,
	}
end

---Create a closure.
---@param func function Function to be wrapped.
---@param ... any Arguments to be passed to the function.
---@return function _ The closure.
function utils.create_closure(func, ...)
	local args = { ... }
	return function()
		return func(unpack(args))
	end
end

--------------------
-- Deprecated functions
--------------------

--------------------

return utils
