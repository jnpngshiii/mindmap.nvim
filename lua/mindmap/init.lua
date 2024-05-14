-- Items in mindnode
local card = require("mindmap.card")
local excerpt = require("mindmap.excerpt")
-- Items in mindmap
local mindnode = require("mindmap.mindnode")
-- Items in database
local mindmap = require("mindmap.mindmap")
-- Database
local database = require("mindmap.database")
-- Logger
local logger = require("mindmap.logger")
-- Misc
local misc = require("mindmap.misc")
local ts_misc = require("mindmap.ts_misc")

local M = {}

--------------------
-- Init
--------------------

local lggr = logger.Logger:init({
	log_path = vim.fn.stdpath("data") .. "/mindmap.log",
})
lggr:log("[Database] Init mindmap logger.", "info")

local db = database.Database:init()
lggr:log("[Database] Init mindmap database.", "info")

--------------------
-- Excerpt Functions
--------------------

function M.create_excerpt_using_latest_visual_selection()
	-- Get mindmap
	local mindmap_id = ts_misc.get_buf_mindmap_id(0, true)
	local mmap = db:find_mindmap(mindmap_id, true)
	-- Get mindnode
	local mindnode_id = ts_misc.get_nearest_heading_node_id(true)
	local mnode = mmap:find_mindnode(mindnode_id, true)
	-- Add excerpt
	local xpt = excerpt.Excerpt.create_using_latest_visual_selection()
	mnode:add_excerpt(xpt)

	lggr:log("[Function] Create excerpt using latest visual selection.", "info")
end

--------------------
-- Mindmap Functions
--------------------

function M.save_mindmap_in_current_buf()
	local mindmap_id = ts_misc.get_buf_mindmap_id(0, false)
	if mindmap_id then
		db:save(mindmap_id)
		lggr:log("[Function] Save mindmap <" .. mindmap_id .. ">.", "info")
	else
		lggr:log("[Function] Current buffer is not a mindmap buffer. Abort saving.", "warn")
	end
	-- db:save()
	-- lggr:log("[Function] Save all mindmaps.", "info")
end

--------------------
-- Logger Functions
--------------------

function M.show_log_in_log_cache()
	lggr:show()

	lggr:log("[Function] Show logs in the log cache.", "info")
end

function M.show_log_in_log_file()
	lggr:show_all()

	lggr:log("[Function] Show logs in the log file.", "info")
end

--------------------

return M
