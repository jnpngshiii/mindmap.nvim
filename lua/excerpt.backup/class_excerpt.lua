local misc = require("excerpt.misc")

local M = {}

--------------------
-- Class Position
--------------------

---@class Position
---@field file_dir string Directory of the file.
---@field file_name string Name of the file.
---@field row number Position of the row.
---@field col number Position of the column.
M.Position = {
	file_dir = "",
	file_name = "",
	row = 0,
	col = 0,
}

---@param file_path string Path of the file.
---@param row number Position of the row.
---@param col number Position of the column.
---@return table
function M.Position:new(file_path, row, col)
	local obj = {}

	setmetatable(obj, self)
	self.__index = self

	obj.file_dir = vim.fs.dirname(file_path)
	obj.file_name = vim.fs.basename(file_path)
	obj.row = row
	obj.col = col

	return obj
end

--------------------
-- Class Excerpt
--------------------

---@class Excerpt
---@field start_position Position Start position of the excerpt.
---@field end_position Position End position of the excerpt.
M.Excerpt = {
	start_position = M.Position:new("", 0, 0),
	end_position = M.Position:new("", 0, 0),
}

----------
-- Instance Method
----------

---@param start_position Position Start position of the excerpt.
---@param end_position Position End position of the excerpt.
---@return table
function M.Excerpt:new(start_position, end_position)
	local obj = {}

	setmetatable(obj, self)
	self.__index = self

	obj.start_position = start_position
	obj.end_position = end_position

	return obj
end

--- Get the context defined by start_position and end_position.
---@return  string[]
function M.Excerpt:get_context() -- FIXME:
	local start_row = self.start_position.row
	local start_col = self.start_position.col
	local end_row = self.end_position.row
	local end_col = self.end_position.col
	local file_path = misc.merge_path({ self.start_position.file_dir, self.start_position.file_name })

	local line_list = misc.get_lines_from_file(file_path)
	local context = {}
	for i = start_row, end_row + 1 do
		if i == start_row then
			table.insert(context, line_list[i]:sub(start_col + 1))
		elseif i == end_row then
			table.insert(context, line_list[i]:sub(1, end_col))
		else
			table.insert(context, line_list[i])
		end
	end
	return context
end

----------
-- Class Method
----------

--- Convert an excerpt to a string.
--- Note that the rel_file_path is relative to the current file.
---@param excerpt Excerpt Excerpt to be converted to a string.
---@param excerpt_info_seq string "{seq}"
---@return string "<rel_file_path{seq}start_row{seq}start_col{seq}end_row{seq}end_col>"
function M.Excerpt.get_excerpt_info(excerpt, excerpt_info_seq)
	return "<"
		.. table.concat({
			misc.merge_path({
				misc.get_rel_path(excerpt.start_position.file_dir, misc.get_current_file_dir()),
				excerpt.start_position.file_name,
			}),
			excerpt.start_position.row,
			excerpt.start_position.col,
			excerpt.end_position.row,
			excerpt.end_position.col,
		}, excerpt_info_seq)
		.. ">"
end

--- Convert a string to an excerpt.
--- Note that the rel_file_path is relative to the current file.
---@param excerpt_info string "<rel_file_path{seq}start_row{seq}start_col{seq}end_row{seq}end_col>"
---@param excerpt_info_seq string "{seq}"
---@return Excerpt Excerpt converted from the string.
function M.Excerpt.parser_excerpt_info(excerpt_info, excerpt_info_seq)
	-- remove < and > from info
	local info = excerpt_info:sub(2, -2)
	local info_list = misc.split_string(info, excerpt_info_seq)
	local start_position = M.Position:new(info_list[1], info_list[2], info_list[3])
	local end_position = M.Position:new(info_list[1], info_list[4], info_list[5])
	return M.Excerpt:new(start_position, end_position)
end

--------------------

return M
