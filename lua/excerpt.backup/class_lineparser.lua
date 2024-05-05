local misc = require("excerpt.misc")
local class_excerpt = require("excerpt.class_excerpt")

local M = {}

--------------------
-- Class LineParser
--------------------

---@class LineParser
---@field file_dir string Directory of the file.
---@field file_name string Name of the file.
---@field file_ext string Extension of the file.
---@field line_num number Number of the line.
---@field line_context string Context of the line.
---@field line_comment string Comment of the line.
---@field comment_pattern table Comment pattern of the file extension.
M.LineParser = {
	file_dir = "",
	file_name = "",
	file_ext = "",
	line_num = 0,
	line_context = "",
	line_comment = "",

	comment_pattern = {
		["lua"] = { "--" },
		["norg"] = { "%", "%" },
	},
}

---@param file_path string Path of the file.
---@param line_num number Number of the line.
---@return table
function M.LineParser:new(file_path, line_num)
	local obj = {}

	setmetatable(obj, self)
	self.__index = self

	obj.file_dir = vim.fs.dirname(file_path)
	obj.file_name = vim.fs.basename(file_path)
	obj.file_ext = misc.get_ext(file_path)
	vim.api.nvim_out_write(obj.file_ext)

	obj.line_num = line_num
	obj.line_context = misc.get_lines_from_file(file_path)[line_num]
	obj.line_comment =
		misc.match_pattern(self.line_context, M.LineParser.comment_pattern_helper(self.comment_pattern[obj.file_ext]))

	return obj
end

--- Add a comment to the line.
---@param comment string
---@return nil
function M.LineParser:add_comment(comment)
	if self.line_comment == "" then
		self.line_context = self.line_context
			.. " "
			.. M.LineParser.comment_pattern_helper(self.comment_pattern[self.file_ext], comment)
	else
		self.line_context = self.line_context .. " " .. comment
	end
	vim.api.nvim_buf_set_text(0, self.line_num - 1, self.line_num, false, { self.line_context })
end

-- if comment is nil,
-- return a comment pattern;
-- else,
-- return a processed comment.
---@param pattern string[] Comment pattern of the file extension.
---@param context string? Context of the comment.
---@return string
function M.LineParser.comment_pattern_helper(pattern, context)
	context = context or ".+"

	local result = pattern[1] .. context
	-- some languages have a comment pattern like "--[[", "--]]",
	-- so we need to add the second pattern.
	if #pattern == 2 then
		result = result .. pattern[2]
	end

	return result
end

--------------------
-- Class ExcerptLineParser
--------------------

---@class ExcerptLineParser:LineParser
---@field excerpt_info_pattern string Pattern of the excerpt information.
---@field excerpt_info_seq string Sequence of the excerpt information.
---@field excerpt_info_list table List of the excerpt information.
---@field excerpt table Excerpt object.
M.ExcerptLineParser = {
	file_dir = "",
	file_name = "",
	file_ext = "",
	line_num = 0,
	line_context = "",
	line_comment = "",

	comment_pattern = {
		["lua"] = { "--" },
		["norg"] = { "%", "%" },
	},

	excerpt_info_pattern = "",
	excerpt_info_seq = "",
	excerpt_info_list = {},
	excerpt = {},
}

---@param file_path string Path of the file.
---@param line_num number Number of the line.
---@param excerpt_info_pattern string Pattern of the excerpt information.
---@param excerpt_info_seq string Sequence of the excerpt information.
---@return table
function M.ExcerptLineParser:new(file_path, line_num, excerpt_info_pattern, excerpt_info_seq)
	local obj = M.LineParser:new(file_path, line_num)

	setmetatable(obj, self)
	self.__index = self

	obj.excerpt_info_pattern = excerpt_info_pattern
	obj.excerpt_info_seq = excerpt_info_seq
	obj.excerpt_info_list = misc.match_pattern(self.line_comment, excerpt_info_pattern)

	for _, info in ipairs(obj.excerpt_info_list) do
		obj.excerpt.append(M.Excerpt.parser_excerpt_info(info, obj.excerpt_info_seq))
	end

	return obj
end

function M.ExcerptLineParser:add_excerpt(excerpt)
	-- FIXME:
	-- self.excerpt_info_list.append(class_excerpt.Excerpt.get_excerpt_info(excerpt, self.excerpt_info_seq))
	-- self.excerpt.append(excerpt)
	self:add_comment(class_excerpt.Excerpt.get_excerpt_info(excerpt, self.excerpt_info_seq))
end

--- Add a comment to the line.
---@param comment string
---@return nil
function M.ExcerptLineParser:add_comment(comment)
	if self.line_comment == "" then
		self.line_context = self.line_context
			.. " "
			.. M.LineParser.comment_pattern_helper(self.comment_pattern[self.file_ext], comment)
	else
		self.line_context = self.line_context .. " " .. comment
	end
	vim.api.nvim_buf_set_lines(0, self.line_num - 1, self.line_num, false, { self.line_context })
end

--------------------

return M
