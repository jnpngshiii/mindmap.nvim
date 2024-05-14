local prototype = require("mindmap.prototype")
local misc = require("mindmap.misc")

local M = {}

--------------------
-- Class Excerpt
--------------------

---@class Excerpt : SimpleItem
---@field rel_file_path string Relative path to the project root of the file where the excerpt is from.
---@field file_name string Name of the file where the excerpt is from.
---@field start_row number Start row of the excerpt.
---@field start_col number Start column of the excerpt.
---@field end_row number End row of the excerpt.
---@field end_col number End column of the excerpt.
M.Excerpt = prototype.SimpleItem:new({
	rel_file_path = "",
	file_name = "",
	start_row = -1,
	start_col = -1,
	end_row = -1,
	end_col = -1,
})

----------
-- Instance Method
----------

---@param obj table?
---@return table
function M.Excerpt:new(obj)
	obj = obj or {}

	obj.id = "xpt-" .. misc.get_unique_id()
	obj.created_at = tonumber(os.time())
	obj.updated_at = tonumber(os.time())

	setmetatable(obj, self)
	self.__index = self

	return obj
end

----------
-- Class Method
----------

---Create a new Excerpt using the latest visual selection.
---@return Excerpt
function M.Excerpt.create_using_latest_visual_selection()
	local abs_file_path = vim.api.nvim_buf_get_name(0)
	local abs_proj_path = misc.get_current_proj_path()

	local rel_file_path = misc.get_rel_path(abs_file_path, abs_proj_path)
	local file_name = misc.get_current_file_name()
	local start_row = vim.api.nvim_buf_get_mark(0, "<")[1]
	local start_col = vim.api.nvim_buf_get_mark(0, "<")[2]
	local end_row = vim.api.nvim_buf_get_mark(0, ">")[1]
	local end_col = vim.api.nvim_buf_get_mark(0, ">")[2]

	return M.Excerpt:new({
		rel_file_path = rel_file_path,
		file_name = file_name,
		start_row = start_row,
		start_col = start_col,
		end_row = end_row,
		end_col = end_col,
	})
end

--------------------

if false then
	local a = M.Excerpt:new()
	local b = M.Excerpt:new()

	print("a.id: " .. a.id)
	print("b.id: " .. b.id)
	print("a.created_at: " .. a.created_at)

	--- Sleep for 1 second
	os.execute("sleep 2")

	print("b.created_at: " .. b.created_at)
end

return M
