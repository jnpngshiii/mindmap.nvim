local misc = require("excerpt.misc")

local M = {}

--------------------
-- Class Position
--------------------

---@class Position
---@field base_dir string Absolute path of the file.
---@field base_name string Name of the file.
---@field row number Position of the row.
---@field col number Position of the column.
M.Position = {
	base_dir = "",
	base_name = "",
	row = 0,
	col = 0,
}

---@param base_dir string Absolute path of the file.
---@param base_name string Name of the file.
---@param row number Position of the row.
---@param col number Position of the column.
function M.Position:new(base_dir, base_name, row, col)
	local obj = {}

	setmetatable(obj, self)
	self.__index = self

	obj.base_dir = base_dir
	obj.base_name = base_name
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
	start_position = M.Position:new("", "", 0, 0),
	end_position = M.Position:new("", "", 0, 0),
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
function M.Excerpt:get_context()
	local start_row = self.start_position.row
	local start_col = self.start_position.col
	local end_row = self.end_position.row
	local end_col = self.end_position.col
	local file_path = misc.merge_path({ self.start_position.base_dir, self.start_position.base_name })

	local line_list = misc.get_lines_from_file(file_path)
	local context = {}
	for i = start_row, end_row do
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

--- Add an excerpt to the cache.
---@param excerpt Excerpt
---@return nil
function M.Database:add(excerpt)
	self.cache[#self.cache + 1] = excerpt
end

--- Show the context of the lastest excerpt in the cache.
---@return nil
function M.Database:show_lastest()
	local content = self.cache[#self.cache]:get_context()
	vim.api.nvim_out_write(table.concat(content, "\n"))
end

--------------------
-- Class LineParser
--------------------

---@class LineParser
M.LineParser = {}

function M.LineParser:new()
	local obj = {}

	setmetatable(obj, self)
	self.__index = self

	return obj
end

--------------------

return M
