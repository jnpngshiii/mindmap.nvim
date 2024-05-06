local class_excerpt = require("excerpt.class_excerpt")

local M = {}

local excerpt_database = class_excerpt.ExcerptDatabase:init()

function M.save_latest_visual_selection_to_database()
	local excerpt_item = class_excerpt.ExcerptItem.create_using_latest_visual_selection()
	excerpt_database:add(excerpt_item)
end

function M.show_all_excerpts_in_database()
	excerpt_database:trigger("show_in_nvim_out_write")
end

function M.save_all_excerpts_in_database()
	excerpt_database:save()
end

return M
