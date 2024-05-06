local M = {}

--------------------
-- Path
--------------------

--- Return the directory of the current project.
--- This function is only available in a git repository.
---@return string
function M.get_current_proj_path()
	return vim.fn.fnamemodify(vim.trim(vim.fn.system("git rev-parse --show-toplevel")), ":p")
end

--- Return the directory of the current file.
--- Example: "/a/b/c.txt" -> "/a/b"
---@return string
function M.get_current_file_dir()
	return vim.fs.dirname(vim.api.nvim_buf_get_name(0))
end

--- Return the name of the current file.
--- Example: "/a/b/c.txt" -> "c.txt"
---@return string
function M.get_current_file_name()
	return vim.fs.basename(vim.api.nvim_buf_get_name(0))
end

--- Split a path into path parts using "/".
---@param path string
---@return string[]
function M.split_path(path)
	local path_parts = {}
	for part in string.gmatch(path, "[^/]+") do
		table.insert(path_parts, part)
	end
	return path_parts
end

--- Merge path parts into a path using "/".
---@param path_parts string[]
---@return string
function M.merge_path(path_parts)
	return table.concat(path_parts, "/")
end

--- Convert relative path (target_path) to absolute path according to reference path (reference_path).
--- Example: get_abs_path("../a/b", "/c/d") -> "/c/a/b"
---@param target_path string A path to be converted to an absolute path.
---@param reference_path string A reference path.
---@return string
function M.get_abs_path(target_path, reference_path)
	local target_path_parts = M.split_path(target_path)
	local reference_path_parts = M.split_path(reference_path)

	for _, part in ipairs(target_path_parts) do
		if part == ".." then
			table.remove(reference_path_parts)
		else
			table.insert(reference_path_parts, part)
		end
	end

	return M.merge_path(reference_path_parts)
end

--- Convert absolute path (target_path) to relative path according to reference path (reference_path).
--- Example: get_rel_path("/a/b/c", "/a/b/d") -> "../c"
---@param target_path string A path to be converted to a relative path.
---@param reference_path string A reference path.
---@return string
function M.get_rel_path(target_path, reference_path)
	local target_parts = M.split_path(target_path)
	local reference_parts = M.split_path(reference_path)
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

	return M.merge_path(rel_path)
end

--- Get the extension of a file.
--- Example: "a/b/c.txt" -> "txt"
---@param path string
---@return string
function M.get_ext(path)
	local path_parts = {}
	for part in string.gmatch(path, "[^\\.]+") do
		table.insert(path_parts, part)
	end
	return path_parts[#path_parts]
end

--------------------
-- Read file
--------------------

--- Parse current line.
---@return string[]
function M.parse_current_line()
	local file_dir = M.get_current_file_dir()
	local file_name = M.get_current_file_name()
	local row = vim.api.nvim_win_get_cursor(0)[1]
	local col = vim.api.nvim_win_get_cursor(0)[2]
	local context = vim.api.nvim_buf_get_lines(0, row - 1, row, false)[1]
	return { file_dir, file_name, row, col, context }
end

--- Read lines from a file.
---@param path string
---@return string[]
function M.read_lines_from_file(path)
	local file = io.open(path, "r")
	if not file then
		vim.api.nvim_out_write("Cannot open file in " .. path .. ".\n")
		return {}
	end

	local line_list = {}
	for line in file:lines() do
		table.insert(line_list, line)
	end
	file:close()
	return line_list
end

--- Get the context defined by start position and end position.
---@return  string[]
function M.get_context(file_path, start_row, start_col, end_row, end_col)
	local line_list = M.read_lines_from_file(file_path)
	local context_list = {}
	for i = start_row, end_row do
		if i == start_row then
			table.insert(context_list, line_list[i]:sub(start_col + 1))
		elseif i == end_row then
			table.insert(context_list, line_list[i]:sub(1, end_col))
		else
			table.insert(context_list, line_list[i])
		end
	end
	return context_list
end

--------------------
-- Helper
--------------------

--- Check whether a index is in a table.
---@param index number|string
---@param tbl table
---@return boolean
function M.check_table_index(index, tbl)
	for k, _ in ipairs(tbl) do
		if k == index then
			return true
		end
	end

	return false
end

--- Remove fields that are not string, number, or boolean in a table.
--- This function is recursive.
---@param tbl table
---@return table
function M.remove_table_field(tbl)
	local proccessed_tbl = tbl
	for k, v in pairs(proccessed_tbl) do
		if type(v) == "table" then
			M.remove_table_field(v)
		elseif type(v) ~= "string" and type(v) ~= "number" and type(v) ~= "boolean" then
			tbl[k] = nil
		end
	end
	return proccessed_tbl
end

--- Match all patterns in the context.
---@param context string|string[]
---@param pattern string
---@return string[]
function M.match_pattern(context, pattern)
	local match_list = {}

	if type(context) == "table" then
		for _, c in ipairs(context) do
			local sub_match_list = M.match_pattern(c, pattern)
			for _, sub_match in ipairs(sub_match_list) do
				table.insert(match_list, sub_match)
			end
		end
	else
		for part in string.gmatch(context, pattern) do
			table.insert(match_list, part)
		end
	end

	return match_list
end

-- local context = "aa bb cc dd"
-- local context = { context, context }
-- local pattern = "[^ ]+"
-- local output = M.match_pattern(context, pattern)
-- for _, s in ipairs(output) do
-- 	print(s)
-- end

--- Split a string using a separator.
---@param str string
---@param sep string
---@return table
function M.split_string(str, sep)
	local parts = {}
	for part in string.gmatch(str, "([^" .. sep .. "]+)") do
		table.insert(parts, part)
	end
	return parts
end

-- local str = "a,b,c"
-- local sep = ","
-- local output = M.split_string(str, sep)
-- for _, s in ipairs(output) do
-- 	print(s)
-- end

--------------------

return M
