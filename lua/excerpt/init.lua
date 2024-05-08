local class_excerpt = require("excerpt.class_excerpt")
local class_log = require("excerpt.class_log")

local M = {}

-- TODO: Remove log here.
-- trigger log inside the class.function

local excerpt_database = class_excerpt.ExcerptDatabase:init({
	json_path = vim.fn.stdpath("data") .. "/excerpt.json",
	logger = class_log.Logger:init({
		log_path = vim.fn.stdpath("data") .. "/excerpt.log",
	}),
})

excerpt_database:load()
excerpt_database:log("[Database] Load database.", "info")

function M.save_latest_visual_selection_to_database()
	local excerpt_item = class_excerpt.ExcerptItem.create_using_latest_visual_selection()
	excerpt_database:add(excerpt_item)
	excerpt_database:log("[Database] Save latest visual selection to database.", "info")
end

function M.show_all_excerpts_in_database()
	excerpt_database:trigger("show_in_nvim_out_write")
	excerpt_database:log("[Database] Show all excerpts in database.", "info")
end

function M.save_all_excerpts_in_database()
	excerpt_database:save()
	excerpt_database:log("[Database] Save all excerpts in database.", "info")
end

return M
