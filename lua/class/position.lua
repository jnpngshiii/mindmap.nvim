local M = {}

--------------------

---@class Excerpt.Position
---@field row number
---@field col number
---@field abs_path string
Position = {
	row = 0,
	col = 0,
	abs_path = "",
	rel_path = "",
}

--------------------
-- Instance methods
--------------------

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
-- Class methods
--------------------

----------
-- Private
----------

---@param path string
---@return string[]
function Position._split_path(path)
	local path_parts = {}
	for part in string.gmatch(path, "[^/]+") do
		table.insert(path_parts, part)
	end
	return path_parts
end

---@param path_parts string[]
---@return string
function Position._merge_path(path_parts)
	return table.concat(path_parts, "/")
end

---@generic T
---@param target T
---@param list T[]
---@return boolean
function Position._is_in_table(target, list)
	for _, value in ipairs(list) do
		if value == target then
			return true
		end
	end
	return false
end

----------
-- Public
----------

---@param target_path string
---@param reference_path string
---@return string
function Position.get_abs_path(target_path, reference_path)
	local target_path_parts = Position._split_path(target_path)
	local reference_path_parts = Position._split_path(reference_path)

	for _, part in ipairs(target_path_parts) do
		if part == ".." then
			table.remove(reference_path_parts)
		else
			table.insert(reference_path_parts, part)
		end
	end

	return Position._merge_path(reference_path_parts)
end

---@param target_path string
---@param reference_path string
---@return string
function Position.get_rel_path(target_path, reference_path)
	local target_parts = Position._split_path(target_path)
	local reference_parts = Position._split_path(reference_path)
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

	return Position._merge_path(rel_path)
end

--------------------

-- local pos = Position:new("/home/jpshi/doc/lua", "this.file", 1, 2)
-- print(pos.row) -- 输出：1
-- print(pos.col) -- 输出：2
--
-- local abs_path = Position.get_abs_path("../../org/index.norg", "/home/jpshi/doc/lua")
-- print(abs_path) -- 输出："/home/jpshi/doc"

local basePath = "/home/user/documents"
local targetPath = "/home/user/downloads/file.txt"

print(Position.get_rel_path(targetPath, basePath))

return M
