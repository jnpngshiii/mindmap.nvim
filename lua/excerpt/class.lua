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

---@param start_position Position Start position of the excerpt.
---@param end_position Position End position of the excerpt.
function M.Excerpt:new(start_position, end_position)
	local obj = {}

	setmetatable(obj, self)
	self.__index = self

	obj.start_position = start_position
	obj.end_position = end_position

	return obj
end

--- Get the context defined by start_position and end_position.
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

--------------------
-- Class Database
--------------------

---@class Database
---@field cache Excerpt[]
M.Database = {
	cache = {},
}

function M.Database:init()
	local obj = {}

	setmetatable(obj, self)
	self.__index = self

	-- TODO: Initialize with the data from the file.
	obj.cache = {}

	return obj
end

--- Add an excerpt to the database.
---@param excerpt Excerpt
---@return nil
function M.Database:add(excerpt)
	self.cache[#self.cache + 1] = excerpt

	vim.api.nvim_out_write("Add an excerpt to the database.\n")
end

--- Add an excerpt to the database using the latest visual selection.
---@return nil
function M.Database.add_using_visual_selection()
	local path = vim.api.nvim_buf_get_name(0)
	local start_row = vim.api.nvim_buf_get_mark(0, "<")[1]
	local start_col = vim.api.nvim_buf_get_mark(0, "<")[2]
	local end_row = vim.api.nvim_buf_get_mark(0, ">")[1]
	local end_col = vim.api.nvim_buf_get_mark(0, ">")[2]

	local start_position = M.Position:new(path, start_row, start_col)
	local end_position = M.Position:new(path, end_row, end_col)
	local visual_selection_excerpt = M.Excerpt:new(start_position, end_position)

	M.Database:add(visual_selection_excerpt)
end

--- Show the context of an excerpt in the database.
---@param index number
---@return nil
function M.Database:show(index)
	if 0 < index and index <= #self.cache then
		local content = self.cache[index]:get_context()
		vim.api.nvim_out_write(table.concat(content, "\n"))
	else
		vim.api.nvim_out_write("No excerpt found.\n")
	end
end

--- Show the context of the lastest excerpt in the database.
---@return nil
function M.Database:show_lastest()
	M.Database:show(#self.cache)
end

--------------------
-- Class LineParser
--------------------

---@class LineParser
M.LineParser = {
	file_dir = "",
	file_name = "",
	file_ext = "",
	row = 0,
}

function M.LineParser:new(file_path, row)
	local obj = {}

	setmetatable(obj, self)
	self.__index = self

	obj.file_dir = vim.fs.dirname(file_path)
	obj.file_name = vim.fs.basename(file_path)
	obj.file_ext = vim.fn.fnamemodify(file_path, ":e")

	return obj
end

--------------------

return M
