local class_database = require("excerpt.class_database")
local class_excerpt = require("excerpt.class_excerpt")
local misc = require("excerpt.misc")

local M = {}

M.excerpt_database = class_database.Database:init()

function M.save_latest_visual_selection_to_database()
	local excerpt_item = class_excerpt.ExcerptItem.create_using_latest_visual_selection()
	M.excerpt_database:add(excerpt_item)
end

function M.show_all_excerpts_in_database()
	M.excerpt_database:trigger("show_in_nvim_out_write")
end

return M
