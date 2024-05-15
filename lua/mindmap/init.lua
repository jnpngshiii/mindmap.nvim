-- Item
local prototype = require("mindmap.prototype")
local card = require("mindmap.card")
local excerpt = require("mindmap.excerpt")
local mindnode = require("mindmap.mindnode")
local mindmap = require("mindmap.mindmap")
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

lggr:log("[Logger] Init mindmap logger.", "info")

-- There is no need to load all mindmaps into memory here,
-- load them on demand.
local mindmap_db = database.Database:new()

lggr:log("[Database] Init mindmap database.", "info")

-- Excerpt may not be connected to a mindnode immediately after it is created,
-- so we need to manage it.
-- For the sake of simplicity, there is no need to define a new class here,
-- just use the mindnode class that can manage excerpts.
local unused_excerpts_db = mindnode.Mindnode:new({
	id = "unused_xpt",
	type = "unused_xpt",
	excerpts = prototype.SimpleDatabase:new({
		db_path = misc.get_current_proj_path() .. "/" .. ".mindmap",
	}),
})
-- TODO: Optimize the following behavior.
unused_excerpts_db.excerpts:load()

lggr:log("[Database] Init unused excerpt database.", "info")

--------------------
-- Excerpt Functions
--------------------

function M.create_excerpt_using_latest_visual_selection()
	local xpt = excerpt.Excerpt.create_using_latest_visual_selection()
	unused_excerpts_db.excerpts[#unused_excerpts_db.excerpts + 1] = xpt

	lggr:log("[Function] Create excerpt using latest visual selection.", "info")
end

function M.show_unused_excerpt_ids()
	unused_excerpts_db.excerpts:trigger("show_id")

	lggr:log("[Function] Show unused excerpt IDs.", "info")
end

--------------------
-- Mindnode Functions
--------------------

function M.add_last_created_excerpt_to_nearest_mindnode()
	-- Get mindmap
	local mindmap_id = ts_misc.get_buf_mindmap_id(0, true)
	local mmp = mindmap_db.mindmaps:find(mindmap_id, true)
	-- Get mindnode
	local mindnode_id = ts_misc.get_nearest_heading_node_id(true)
	local mnd = mmp.mindnodes:find(mindnode_id, true)
	-- Add excerpt
	-- TODO: Use pop function.
	mnd.excerpts:add(unused_excerpts_db.excerpts[#unused_excerpts_db.excerpts])
	unused_excerpts_db.excerpts[#unused_excerpts_db.excerpts] = nil

	lggr:log("[Function] Add last created excerpt to nearest mindnode.", "info")
end

--------------------
-- Mindmap Functions
--------------------

function M.save_mindmap_in_current_buf()
	local mindmap_id = ts_misc.get_buf_mindmap_id(0, false)
	if mindmap_id then
		mindmap_db.mindmaps[mindmap_id]:save()
		lggr:log("[Function] Save mindmap <" .. mindmap_id .. ">.", "info")
	else
		lggr:log("[Function] Current buffer is not a mindmap buffer. Abort saving.", "warn")
	end
end

function M.load_mindmap_in_current_buf()
	local mindmap_id = ts_misc.get_buf_mindmap_id(0, false)
	if mindmap_id then
		mindmap_db.mindmaps[mindmap_id] = prototype.SimpleDatabase:new({
			db_path = misc.get_current_proj_path() .. "/" .. ".mindmap",
		})
		mindmap_db.mindmaps[mindmap_id]:load()
		lggr:log("[Function] Load mindmap <" .. mindmap_id .. ">.", "info")
	else
		lggr:log("[Function] Current buffer is not a mindmap buffer. Abort loading.", "warn")
	end
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
