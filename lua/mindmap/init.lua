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
	excerpt_db.add(xpt)

	lggr:info("function", " Create excerpt using latest visual selection.")
end

function M.show_unused_excerpt_ids()
	excerpt_db.excerpts:trigger("show_id")

	lggr:info("function", " Show unused excerpt IDs.")
end

--------------------
-- Mindnode Functions
--------------------

function M.add_last_created_excerpt_to_nearest_mindnode()
	-- Get mindmap
	local mindmap_id = ts_misc.get_buf_mindmap_id(0, true)
	local mmp = card_db.sub_items.find(mindmap.Mindmap, mindmap_id, true)
	-- Get mindnode
	local mindnode_id = ts_misc.get_nearest_heading_node_id(true)
	local mnd = mmp.mindnodes.find(mindnode.Mindnode, mindnode_id, true)
	-- Add excerpt
	-- TODO: Use pop function.
	mnd.excerpts:add(excerpt_db.excerpts[#excerpt_db.excerpts])
	excerpt_db.excerpts[#excerpt_db.excerpts] = nil

	lggr:info("function", " Add last created excerpt to nearest mindnode.")
end

--------------------
-- Mindmap Functions
--------------------

function M.save_mindmap_in_current_buf()
	local mindmap_id = ts_misc.get_buf_mindmap_id(0, false)
	if mindmap_id then
		card_db.sub_items[mindmap_id]:save()
		lggr:info("function", " Save mindmap <" .. mindmap_id .. ">.")
	else
		lggr:warn("function", " Current buffer is not a mindmap buffer. Abort saving.")
	end
end

function M.load_mindmap_in_current_buf()
	local mindmap_id = ts_misc.get_buf_mindmap_id(0, false)
	if mindmap_id then
		card_db:add(mindmap.Mindmap:new({
			id = mindmap_id,
		}))
		lggr:info("function", " Load mindmap <" .. mindmap_id .. ">.")
	else
		lggr:warn("function", " Current buffer is not a mindmap buffer. Abort loading.")
	end
end

--------------------

return M
