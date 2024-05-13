local misc = require("mindmap.misc")

local M = {}

--------------------
-- Class Excerpt
--------------------

---@class Excerpt
---@field rel_file_path string Relative path to the project root of the file where the excerpt is from.
---@field file_name string Name of the file where the excerpt is from.
---@field start_row number Start row of the excerpt.
---@field start_col number Start column of the excerpt.
---@field end_row number End row of the excerpt.
---@field end_col number End column of the excerpt.
---@field content string[] Content of the excerpt.
M.Excerpt = {
	rel_file_path = "",
	file_name = "",
	start_row = -1,
	start_col = -1,
	end_row = -1,
	end_col = -1,
	content = {},
}

----------
-- Instance Method
----------

---@param obj table?
---@return table
function M.Excerpt:new(obj)
	obj = obj or {}
	obj.rel_file_path = obj.rel_file_path or self.rel_file_path
	obj.file_name = obj.file_name or self.file_name
	obj.start_row = obj.start_row or self.start_row
	obj.start_col = obj.start_col or self.start_col
	obj.end_row = obj.end_row or self.end_row
	obj.end_col = obj.end_col or self.end_col
	obj.content = obj.content or self.content

	setmetatable(obj, self)
	self.__index = self

	return obj
end

---Check health of an Excerpt.
---@return boolean
function M.Excerpt:check_health()
	if
		self.rel_file_path == ""
		or self.file_name == ""
		or self.start_row == -1
		or self.start_col == -1
		or self.end_row == -1
		or self.end_col == -1
		or self.content == {}
	then
		return false
	else
		return true
	end
end

---Show info of an Excerpt in nvim_out_write.
---@return nil
function M.Excerpt:show_in_nvim_out_write()
	local info = ""
	info = info .. "===== Excerpt Start =====" .. "\n"
	info = info .. "rel_file_path: " .. self.rel_file_path .. "\n"
	info = info .. "file_name: " .. self.file_name .. "\n"
	info = info .. "start_row: " .. self.start_row .. "\n"
	info = info .. "start_col: " .. self.start_col .. "\n"
	info = info .. "end_row: " .. self.end_row .. "\n"
	info = info .. "end_col: " .. self.end_col .. "\n"
	info = info .. "content:\n" .. table.concat(self.content, "\n") .. "\n"
	info = info .. "=====  Excerpt End  =====" .. "\n"
	vim.api.nvim_out_write(info)
end

----------
-- Class Method
----------

---Create a new Excerpt using the latest visual selection.
---@return Excerpt
function M.Excerpt.create_using_latest_visual_selection()
	local abs_file_path = vim.api.nvim_buf_get_name(0)
	local abs_proj_path = misc.get_current_proj_path()

	local rel_file_path = misc.get_rel_file_path(abs_file_path, abs_proj_path)
	local file_name = misc.get_current_file_name()
	local start_row = vim.api.nvim_buf_get_mark(0, "<")[1]
	local start_col = vim.api.nvim_buf_get_mark(0, "<")[2]
	local end_row = vim.api.nvim_buf_get_mark(0, ">")[1]
	local end_col = vim.api.nvim_buf_get_mark(0, ">")[2]
	local content = misc.get_content(abs_file_path, start_row, start_col, end_row, end_col)

	return M.Excerpt:new({
		rel_file_path = rel_file_path,
		file_name = file_name,
		start_row = start_row,
		start_col = start_col,
		end_row = end_row,
		end_col = end_col,
		content = content,
	})
end

--------------------

return M
