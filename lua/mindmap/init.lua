-- Item
local prototype = require("mindmap.prototype")

local excerpt = require("mindmap.excerpt")

local card = require("mindmap.card")
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

local lggr = M.Logger:new({
	id = string.format("log %s", os.date("%Y-%m-%d %H:%M:%S")),
	log_level = "DEBUG",
	show_in_nvim = true,
})
lggr:info(lggr.type, "Init mindmap.nvim logger.")

local card_db = database.Database:new({
	id = "card_db",
	sub_item_class = mindmap.Mindmap,
})
lggr:info(card_db.type, "Init card database.")

local excerpt_db = mindnode.Mindnode:new({
	id = "excerpt_db",
	sub_item_class = excerpt.Excerpt,
})
lggr:info(card_db.type, "Init excerpt database.")

--------------------
-- Excerpt Functions
--------------------

function M.create_excerpt_using_latest_visual_selection()
	local xpt = excerpt.Excerpt.create_using_latest_visual_selection()
	excerpt_db.excerpts[#excerpt_db.excerpts + 1] = xpt

	lggr:log("[Function] Create excerpt using latest visual selection.", "info")
end

function M.show_unused_excerpt_ids()
	excerpt_db.excerpts:trigger("show_id")

	lggr:log("[Function] Show unused excerpt IDs.", "info")
end

--------------------
-- Mindnode Functions
--------------------

function M.add_last_created_excerpt_to_nearest_mindnode()
	-- Get mindmap
	local mindmap_id = ts_misc.get_buf_mindmap_id(0, true)
	local mmp = card_db.mindmaps.find(mindmap.Mindmap, mindmap_id, true)
	-- Get mindnode
	local mindnode_id = ts_misc.get_nearest_heading_node_id(true)
	local mnd = mmp.mindnodes.find(mindnode.Mindnode, mindnode_id, true)
	-- Add excerpt
	-- TODO: Use pop function.
	mnd.excerpts:add(excerpt_db.excerpts[#excerpt_db.excerpts])
	excerpt_db.excerpts[#excerpt_db.excerpts] = nil

	lggr:log("[Function] Add last created excerpt to nearest mindnode.", "info")
end

--------------------
-- Mindmap Functions
--------------------

function M.save_mindmap_in_current_buf()
	local mindmap_id = ts_misc.get_buf_mindmap_id(0, false)
	print(mindmap_id)
	if mindmap_id then
		card_db.mindmaps[mindmap_id]:save()
		lggr:log("[Function] Save mindmap <" .. mindmap_id .. ">.", "info")
	else
		lggr:log("[Function] Current buffer is not a mindmap buffer. Abort saving.", "warn")
	end
end

function M.load_mindmap_in_current_buf()
	local mindmap_id = ts_misc.get_buf_mindmap_id(0, false)
	if mindmap_id then
		card_db.mindmaps[mindmap_id] = prototype.SimpleDatabase:new({
			db_path = misc.get_current_proj_path() .. "/" .. ".mindmap",
		})
		card_db.mindmaps[mindmap_id]:load()
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
