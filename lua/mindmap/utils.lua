local logger = require("mindmap.Logger"):register_source("Plugin.Utils")

local utils = {}

--------------------
-- String Function
--------------------

---Split a string using the given separator.
---@param str string The string to split.
---@param sep string The separator to use.
---@return table parts The table of split parts.
function utils.split_string(str, sep)
	local parts = {}
	for part in string.gmatch(str, "([^" .. sep .. "]+)") do
		table.insert(parts, part)
	end
	return parts
end

---Limit the length of a string or a list of strings.
---@param str_or_list string|string[] String or list of strings to be limited.
---@param limitation integer Maximum length of each string.
---@return string[] limited_list The limited list of strings.
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

---@deprecated
---Match all patterns in the content.
---@param content string|string[] The content to search in.
---@param pattern string The pattern to match.
---@return string[] matched_list List of all matched patterns.
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

---Get the indent of a line.
---@param bufnr integer Buffer number.
---@param line_num integer Line number.
---@return string indent Indent of the line.
function utils.get_indent(bufnr, line_num)
	local line = vim.api.nvim_buf_get_lines(bufnr, line_num - 1, line_num, false)[1]
	local indent = line:match("^[%*%s]*"):gsub("[%*%s]", " ")
	return indent or ""
end

--------------------
-- File Function
--------------------

---Convert relative path (target_path) to absolute path according to reference path (reference_path).
---Example:
---  ```
---  local _s = get_abs_path("../a/b", "/c/d")
---  print(_s) -- "/c/a/b"
---  ```
---@param target_path string A path to be converted to an absolute path.
---@param reference_path string A reference path.
---@return string abs_path The resulting absolute path.
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
---Example:
---  ```
---  local _s = get_rel_path("/a/b/c", "/a/b/d")
---  print(_s) -- "../c"
---  ```
---@param target_path string A path to be converted to a relative path.
---@param reference_path string A reference path.
---@return string rel_path The resulting relative path.
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
---@return string file_name, string abs_file_path, string rel_file_path, string proj_path Information of the file.
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

	return file_name, abs_file_path, rel_file_path, proj_path
end

---Get the content of a buffer or a file.
---@param bufnr_or_file_path? integer|string Buffer number or file path of the file to be parsed.
---@param start_row? integer The start row of the range to be read.
---@param end_row? integer The end row of the range to be read.
---@param start_col? integer The start column of the range to be read.
---@param end_col? integer The end column of the range to be read.
---@return string[] content { line1, line2, ... }
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

--------------------
-- Neovim Function
--------------------

---Get the latest visual selection.
---@return number start_row, number start_col, number end_row, number end_col The positions of the latest visual selection.
function utils.get_latest_visual_selection()
	-- FIXME: The first call will return { 0, 0 } for both marks
	local start_row, start_col = unpack(vim.api.nvim_buf_get_mark(0, "<"))
	local end_row, end_col = unpack(vim.api.nvim_buf_get_mark(0, ">"))

	return start_row, start_col, end_row, end_col
end

---Execute a function with an existing or temporary buffer and automatically clean up if necessary.
---Example:
---  ```
---  local func_needs_temp_bufnr = function(bufnr, str1, str2)
---    -- Do some stuff...
---    return str1, str2
---  end
---  local _s1, _s2 = utils.with_temp_bufnr(file_path, func_needs_temp_bufnr, "Hello", "World")
---  print(_s1) -- "Hello"
---  print(_s2) -- "World"
---  ```
---@param file_path string File path to check or read into a temporary buffer.
---@param callback function Function to execute with the buffer. Receives buffer number as the first argument.
---@param ... any Arguments to be passed to the callback function.
---@return any result The result of the callback function.
function utils.with_temp_bufnr(file_path, callback, ...)
	local bufnr = vim.fn.bufnr(file_path)
	local is_temp_buf = false

	if bufnr == -1 then
		bufnr = vim.api.nvim_create_buf(false, true)
		is_temp_buf = true

		local ok, content = pcall(vim.fn.readfile, file_path)
		if not ok then
			logger.error("Failed to read file: `" .. file_path .. "`.")
			vim.api.nvim_buf_delete(bufnr, { force = true })
			return
		end

		vim.api.nvim_buf_set_lines(bufnr, 0, -1, true, content)
	end

	local result = { callback(bufnr, ...) }

	if is_temp_buf then
		vim.api.nvim_buf_delete(bufnr, { force = true })
	end

	return unpack(result)
end

---Add virtual text in the given buffer in the given namespace.
---@param bufnr integer Buffer number.
---@param namespace number Namespace.
---@param line_num integer Line number.
---@param text string|string[] Text to be added as virtual text.
---@param text_type? string Type of the virtual text. Default: `"Comment"`.
---@return nil
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
---@param start_row? integer Start of range of lines to clear. Default: `0`.
---@param end_row? integer End of range of lines to clear (exclusive) or -1 to clear to end of buffer. Default: `-1`.
---@return nil
function utils.clear_virtual_text(bufnr, namespace, start_row, end_row)
	vim.api.nvim_buf_clear_namespace(bufnr, namespace, start_row or 0, end_row or -1)
end

--------------------
-- Other Function
--------------------

---Remove fields that are not string, number, or boolean in a table.
---@param tbl table The table to process.
---@return table processed_tbl The processed table with removed fields.
function utils.remove_table_fields(tbl)
	local processed_tbl = tbl
	for k, v in pairs(processed_tbl) do
		if type(v) == "table" then
			utils.remove_table_fields(v)
		elseif type(v) ~= "string" and type(v) ~= "number" and type(v) ~= "boolean" then
			tbl[k] = nil
		end
	end
	return processed_tbl
end

---@deprecated
---Create a closure.
---@param func function Function to be wrapped.
---@param ... any Arguments to be passed to the function.
---@return function closure The closure.
function utils.create_closure(func, ...)
	local args = { ... }
	return function()
		return func(unpack(args))
	end
end

---Process items in parallel using multiple coroutines.
---@param iterator table The table or list to iterate over.
---@param func function The function to apply to each item in the iterator.
---It should accept two parameters:
---  key: The key of the current item in the iterator.
---  value: The value of the current item in the iterator.
---It should return a value to be stored in the results table,
---or nil if no result should be stored for this item.
---@param thread_num? integer The number of coroutines to use for parallel processing. Default: `3`.
---@return table results A table containing the results of processing each item.
---The keys in this table correspond to the keys in the input iterator.
function utils.pfor(iterator, func, thread_num)
	thread_num = thread_num or 3

	local results = {}
	local function worker(start_index)
		local index = 0
		for key, value in pairs(iterator) do
			index = index + 1
			if index % thread_num == start_index - 1 then
				local result = func(key, value)
				if result ~= nil then
					results[key] = result
				end
			end
		end
	end

	local threads = {}
	for i = 1, thread_num do
		threads[i] = coroutine.create(function()
			worker(i)
		end)
	end

	for _, thread in ipairs(threads) do
		coroutine.resume(thread)
	end

	return results
end

--------------------

return utils
