local class_database = require("excerpt.class_database")
local misc = require("excerpt.misc")

local M = {}

--------------------
-- Class ExcerptItem
--------------------

---@class ExcerptItem:Item
---@field path_to_root string Relative path to the project root of the file where the excerpt is from.
---@field file_name string Name of the file where the excerpt is from.
---@field start_row number Start row of the excerpt.
---@field start_col number Start column of the excerpt.
---@field end_row number End row of the excerpt.
---@field end_col number End column of the excerpt.
---@field content string[] Content list per line of the excerpt.
M.ExcerptItem = class_database.Item:new({
	path_to_root = "",
	file_name = "",
	start_row = 0,
	start_col = 0,
	end_row = 0,
	end_col = 0,
	content = "",
})

----------
-- Class Method
----------

--- Create a new ExcerptItem using the latest visual selection.
---@return ExcerptItem
function M.ExcerptItem.create_using_latest_visual_selection()
	local file_path = vim.api.nvim_buf_get_name(0)
	local proj_root = misc.get_current_proj_path()
	local path_to_root = misc.get_rel_path(file_path, proj_root)
	local file_name = misc.get_current_file_name()
	local start_row = vim.api.nvim_buf_get_mark(0, "<")[1]
	local start_col = vim.api.nvim_buf_get_mark(0, "<")[2]
	local end_row = vim.api.nvim_buf_get_mark(0, ">")[1]
	local end_col = vim.api.nvim_buf_get_mark(0, ">")[2]
	local content = misc.get_context(file_path, start_row, start_col, end_row, end_col)

	return M.ExcerptItem:new({
		path_to_root = path_to_root,
		file_name = file_name,
		start_row = start_row,
		start_col = start_col,
		end_row = end_row,
		end_col = end_col,
		content = content,
	})
end

----------
-- Instance Method
----------

function M.ExcerptItem:show_in_nvim_out_write()
	local info = "path_to_root: " .. self.path_to_root .. "\n"
	info = info .. "file_name: " .. self.file_name .. "\n"
	info = info .. "start_row: " .. self.start_row .. "\n"
	info = info .. "start_col: " .. self.start_col .. "\n"
	info = info .. "end_row: " .. self.end_row .. "\n"
	info = info .. "end_col: " .. self.end_col .. "\n"
	info = info .. "content:\n" .. table.concat(self.content, "\n") .. "\n\n"
	vim.api.nvim_out_write(info)
end

--------------------
-- Class Database
--------------------

----------
-- Class Method
----------

----------
-- Instance Method
----------

--------------------

return M
