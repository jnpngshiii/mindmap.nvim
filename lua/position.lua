local M = {}

--------------------
-- Class Position
--------------------

---@class Excerpt.Position
---@field base_dir string Absolute path of the file.
---@field base_name string Name of the file.
---@field row number Position of the row.
---@field col number Position of the column.
Position = {
	base_dir = "",
	base_name = "",
	row = 0,
	col = 0,
}

---@param base_dir string Absolute path of the file.
---@param base_name string Name of the file.
---@param row number Position of the row.
---@param col number Position of the column.
function Position:new(base_dir, base_name, row, col)
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
-- Class Area
--------------------

---@class Excerpt.Area
---@field start_position Excerpt.Position Start position of the area.
---@field end_position Excerpt.Position End position of the area.
Area = {
	start_position = Position:new("", "", 0, 0),
	end_position = Position:new("", "", 0, 0),
}

---@param start_position Excerpt.Position Start position of the area.
---@param end_position Excerpt.Position End position of the area.
function Area:new(start_position, end_position)
	local obj = {}

	setmetatable(obj, self)
	self.__index = self

	obj.start_position = start_position
	obj.end_position = end_position

	return obj
end

--- Get the area defined by start_position and end_position.
function Area:get_area()
	local start_row = self.start_position.row
	local start_col = self.start_position.col
	local end_row = self.end_position.row
	local end_col = self.end_position.col
	local file_path = self.start_position.base_dir .. self.start_position.base_name
	local lines = M.read_file(file_path)

	local selected_lines = {}
	for i = start_row, end_row do
		if i == start_row then
			table.insert(selected_lines, lines[i]:sub(start_col + 1))
		elseif i == end_row then
			table.insert(selected_lines, lines[i]:sub(1, end_col))
		else
			table.insert(selected_lines, lines[i])
		end
	end
	return selected_lines
end

--------------------

return M
