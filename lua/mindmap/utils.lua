local M = {}

--------------------
-- Helper functions
--------------------

---Match all patterns in the content.
---@param content string|string[]
---@param pattern string
---@return string[] _
function M.match_pattern(content, pattern)
	local match_list = {}

	if type(content) == "table" then
		for _, c in ipairs(content) do
			local sub_match_list = M.match_pattern(c, pattern)
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

---Split a string using a separator.
---@param str string
---@param sep string
---@return table _
function M.split_string(str, sep)
	local parts = {}
	for part in string.gmatch(str, "([^" .. sep .. "]+)") do
		table.insert(parts, part)
	end
	return parts
end

---Convert relative path (target_path) to absolute path according to reference path (reference_path).
---Example: get_abs_path("../a/b", "/c/d") -> "/c/a/b"
---@param target_path string A path to be converted to an absolute path.
---@param reference_path string A reference path.
---@return string _
function M.get_abs_path(target_path, reference_path)
	local target_path_parts = M.split_string(target_path, "/")
	local reference_path_parts = M.split_string(reference_path, "/")

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
function M.get_rel_path(target_path, reference_path)
	local target_parts = M.split_string(target_path, "/")
	local reference_parts = M.split_string(reference_path, "/")
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
function M.get_file_info(bufnr_or_file_path)
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
	local rel_file_path = M.get_rel_path(abs_file_path, proj_path)

	return { file_name, abs_file_path, rel_file_path, proj_path }
end

---Get the content of a buffer or a file.
---@param bufnr_or_file_path? integer|string Buffer number or file path of the file to be parsed.
---@param start_row? integer The start row of the range to be read.
---@param end_row? integer The end row of the range to be read.
---@param start_col? integer The start column of the range to be read.
---@param end_col? integer The end column of the range to be read.
---@return string[] _ { line1, line2, ... }
function M.get_file_content(bufnr_or_file_path, start_row, end_row, start_col, end_col)
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

---Get the buffer number, or get the temp buffer number.
---@param bufnr_or_file_path? integer|string Buffer number or file path.
---@return integer bufnr, boolean is_temp_buf Buffer number and whether it is a temp buffer. Default: 0, false.
function M.get_bufnr(bufnr_or_file_path)
	if type(bufnr_or_file_path) == "number" then
		return bufnr_or_file_path, false
	elseif type(bufnr_or_file_path) == "string" then
		local bufnr = vim.fn.bufnr(bufnr_or_file_path)
		if bufnr == -1 then
			local content = vim.fn.readfile(bufnr_or_file_path)
			local temp_bufnr = vim.api.nvim_create_buf(false, true)
			vim.api.nvim_buf_set_lines(temp_bufnr, 0, -1, false, content)

			return temp_bufnr, true
		end

		return bufnr, false
	end

	return 0, false
end

---Remove fields that are not string, number, or boolean in a table.
---@param tbl table
---@return table _
function M.remove_table_fields(tbl)
	local proccessed_tbl = tbl
	for k, v in pairs(proccessed_tbl) do
		if type(v) == "table" then
			M.remove_table_fields(v)
		elseif type(v) ~= "string" and type(v) ~= "number" and type(v) ~= "boolean" then
			tbl[k] = nil
		end
	end
	return proccessed_tbl
end

--------------------
-- Deprecated functions
--------------------

--------------------

return M
