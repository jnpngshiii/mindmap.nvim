local prototype = require("mindmap.prototype")
local misc = require("mindmap.misc")

local M = {}

--------------------
-- Class Excerpt
--------------------

---@class Excerpt : SimpleItem
---@field rel_file_path string Relative path to the project root of the file where the excerpt is from.
---@field file_name string Name of the file where the excerpt is from.
---@field start_row integer Start row of the excerpt.
---@field start_col integer Start column of the excerpt.
---@field end_row integer End row of the excerpt.
---@field end_col integer End column of the excerpt.
M.Excerpt = prototype.SimpleItem:new()

----------
-- Instance Method
----------

---Create a new excerpt object.
---@param tbl? table Table used to create the item.
---@param sub_item_class? SimpleItem Class of the sub items. Default: nil.
---@return table
function M.Excerpt:new(tbl, sub_item_class)
	tbl = tbl or {}
	tbl.type = "excerpt"
	tbl = prototype.SimpleItem:new(tbl, sub_item_class or nil)

	tbl.rel_file_path = tbl.rel_file_path or self.rel_file_path
	tbl.file_name = tbl.file_name or self.file_name
	tbl.start_row = tbl.start_row or self.start_row
	tbl.start_col = tbl.start_col or self.start_col
	tbl.end_row = tbl.end_row or self.end_row
	tbl.end_col = tbl.end_col or self.end_col

	setmetatable(tbl, self)
	self.__index = self

	return tbl
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
	print("b.created_at: " .. b.created_at)
end

return M
