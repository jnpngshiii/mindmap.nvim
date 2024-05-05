local M = {}

--------------------
-- Path
--------------------

---@return string
function M.get_current_file_dir()
	return vim.fs.dirname(vim.api.nvim_buf_get_name(0))
end

---@return string
function M.get_current_file_name()
	return vim.fs.basename(vim.api.nvim_buf_get_name(0))
end

---@param path string
---@return string[]
function M.split_path(path)
	local path_parts = {}
	for part in string.gmatch(path, "[^/]+") do
		table.insert(path_parts, part)
	end
	return path_parts
end

---@param path_parts string[]
---@return string
function M.merge_path(path_parts)
	return table.concat(path_parts, "/")
end

--- Convert relative path (target_path) to absolute path according to reference path (reference_path).
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

	vim.api.nvim_out_write("target_path: " .. target_path .. "\n")
	vim.api.nvim_out_write("reference_path: " .. reference_path .. "\n")
	vim.api.nvim_out_write("rel_path: " .. M.merge_path(rel_path) .. "\n")
	return M.merge_path(rel_path)
end

-- local a = M.get_rel_path("/a/b/c", "/a/b/d")
-- print(a)

---@param path string
---@return string[]
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

function M.get_cursor_line_context(row)
	-- Buf is 0 because cursor is in the current buffer.
	local context = vim.api.nvim_buf_get_lines(0, row - 1, row, false)[1]
	return context
end

--- Open a file and return its content as a list of lines.
---@param path string
function M.get_lines_from_file(path)
	local file = io.open(path, "r")
	if not file then
		vim.api.nvim_out_write("Error: Cannot open file in " .. path .. ".\n")
		return {}
	end

	local line_list = {}
	for line in file:lines() do
		table.insert(line_list, line)
	end
	file:close()
	return line_list
end

--------------------
-- Helper
--------------------

--- Check if a value is in a table.
---@generic T
---@param target T
---@param list T[]
---@return boolean
function M.value_is_in_table(target, list)
	for _, value in ipairs(list) do
		if value == target then
			return true
		end
	end
	return false
end

--- Match all patterns in the context.
---@param context string|string[]
---@param pattern string
---@return string[]
function M.match_pattern(context, pattern)
	local match_list = {}

	if type(context) == "table" then
		for _, c in ipairs(context) do
			local sub_match_list = M.pattern_parse(c, pattern)
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

function M.split_string(str, sep)
	local parts = {}
	for part in string.gmatch(str, "([^" .. sep .. "]+)") do
		table.insert(parts, part)
	end
	return parts
end

--------------------

return M
