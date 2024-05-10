local class_excerpt = require("excerpt.class_excerpt")
local class_log = require("excerpt.class_log")
local misc = require("excerpt.misc")

local M = {}

--------------------
-- Init
--------------------

local excerpt_database = class_excerpt.ExcerptDatabase:init({
	json_path = vim.fn.stdpath("data") .. "/excerpt.json",
	logger = class_log.Logger:init({
		log_path = vim.fn.stdpath("data") .. "/excerpt.log",
	}),
})

excerpt_database:load()
excerpt_database:log("[Database] Load database.", "info")

--------------------
-- Private Functions
--------------------

local function find_all_excerpts_in_current_line()
	excerpt_database:log("[Function] Find all excerpts in current line.", "info")

	local current_line_content = misc.parse_current_line()[5]
	local matched_timestamp = misc.match_pattern(current_line_content, "excerpt%d%d%d%d%d%d%d%d%d%d")

	excerpt_database:log("    Matched timestamp: " .. table.concat(matched_timestamp, ", "), "info")

	return excerpt_database:find(matched_timestamp)
end

--------------------
-- Public Functions
--------------------

function M.create_excerpt_using_latest_visual_selection()
	excerpt_database:log("[Function] Create excerpt using latest visual selection.", "info")

	local excerpt_item = class_excerpt.ExcerptItem.create_using_latest_visual_selection()
	excerpt_database:add(excerpt_item)
	excerpt_database:save()
end

function M.show_all_excerpts_in_current_line()
	excerpt_database:log("[Function] Show all excerpts in current line.", "info")

	local matched_excerpts = find_all_excerpts_in_current_line()
	excerpt_database.trigger(matched_excerpts, "show_in_nvim_out_write")
end

function M.show_all_excerpts_in_database()
	excerpt_database:log("[Function] Show all excerpts in database.", "info")

	excerpt_database.trigger(excerpt_database.cache, "show_in_nvim_out_write")
end

function M.append_lastest_excerpt_to_current_line()
	excerpt_database:log("[Function] Append latest excerpt to current line.", "info")

	local line = vim.api.nvim_win_get_cursor(0)[1]
	local current_line_content = misc.parse_current_line()[5]

	local max_id = "excerpt0000000000"
	for id, _ in pairs(excerpt_database.cache) do
		if id > max_id then
			max_id = id
		end
	end

	local new_line_content = current_line_content .. " " .. max_id
	vim.api.nvim_buf_set_lines(0, line - 1, line, false, { new_line_content })
end

function M.show_log()
	excerpt_database.logger:show_all()
end

--------------------

return M