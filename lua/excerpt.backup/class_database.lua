local class_excerpt = require("excerpt.class_excerpt")

local M = {}

--------------------
-- Class Database
--------------------

---@class Database
---@generic T
---@field cache T[]
M.Database = {
	cache = {},
}

---@return table
function M.Database:init()
	local obj = {}

	setmetatable(obj, self)
	self.__index = self

	-- TODO: Initialize with the data from the file.
	obj.cache = {}

	return obj
end

--- Add an item to the database.
---@generic T
---@param item T
---@return nil
function M.Database:add(item)
	self.cache[#self.cache + 1] = item

	vim.api.nvim_out_write("Add an item to the database.\n")
end

--- Pop an item from the database.
---@generic T
---@param index number
---@return T
function M.Database:pop(index)
	if 1 <= index <= #self.cache then
		local poped_item = table.remove(self.cache, index)
		vim.api.nvim_out_write("Pop an item from the database.\n")
		return poped_item
	else
		vim.api.nvim_out_write("No item found.\n")
		return nil
	end
end

--- Remove an item from the database.
---@generic T
---@param index T
---@return nil
function M.Database:remove(index)
	if 1 <= index <= #self.cache then
		table.remove(self.cache, index)
		vim.api.nvim_out_write("Remove an item from the database.\n")
	else
		vim.api.nvim_out_write("No item found.\n")
	end
end

--------------------
-- Class ExcerptDatabase
--------------------

---@class ExcerptDatabase:Database
---@field cache Excerpt[]
M.ExcerptDatabase = {
	cache = {},
}

---@return table
function M.ExcerptDatabase:init()
	local obj = M.Database:init()

	setmetatable(obj, self)
	self.__index = self

	return obj
end

--- Add an item to the database using the latest visual selection.
---@return nil
function M.ExcerptDatabase:add_using_visual_selection()
	local path = vim.api.nvim_buf_get_name(0)
	local start_row = vim.api.nvim_buf_get_mark(0, "<")[1]
	local start_col = vim.api.nvim_buf_get_mark(0, "<")[2]
	local end_row = vim.api.nvim_buf_get_mark(0, ">")[1]
	local end_col = vim.api.nvim_buf_get_mark(0, ">")[2]

	local start_position = class_excerpt.Position:new(path, start_row, start_col)
	local end_position = class_excerpt.Position:new(path, end_row, end_col)
	local visual_selection_t = class_excerpt.Excerpt:new(start_position, end_position)

	self:add(visual_selection_t)
end

--- Show the context of an excerpt in the database.
---@param index number
---@return nil
function M.ExcerptDatabase:show(index)
	if 0 < index and index <= #self.cache then
		local content = self.cache[index]:get_context()
		vim.api.nvim_out_write(table.concat(content, "\n"))
	else
		vim.api.nvim_out_write("No item found.\n")
	end
end

--- Show the context of the lastest excerpt in the database.
---@return nil
function M.ExcerptDatabase:show_lastest()
	M.ExcerptDatabase:show(#self.cache)
end

--- Add an item to the database.
---@generic T
---@param item T
---@return nil
function M.ExcerptDatabase:add(item)
	self.cache[#self.cache + 1] = item

	vim.api.nvim_out_write("Add an item to the database.\n")
end

--- Pop an item from the database.
---@generic T
---@param index number
---@return T
function M.ExcerptDatabase:pop(index)
	-- if 1 <= index <= #self.cache then
	if true then
		local poped_item = table.remove(self.cache, index)
		vim.api.nvim_out_write("Pop an item from the database.\n")
		return poped_item
	else
		vim.api.nvim_out_write("No item found.\n")
		return nil
	end
end

--- Remove an item from the database.

--------------------

return M
