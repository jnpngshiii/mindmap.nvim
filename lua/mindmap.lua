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

local lggr = logger.Logger:new({
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

local unused_excerpt_db = mindnode.Mindnode:new({
	id = "unused_excerpt_db",
	sub_item_class = excerpt.Excerpt,
})
lggr:info(card_db.type, "Init unused excerpt database.")

--------------------
-- Excerpt Functions
--------------------

function M.create_excerpt_using_latest_visual_selection()
	local created_excerpt = excerpt.Excerpt.create_using_latest_visual_selection()
	unused_excerpt_db:add(created_excerpt)
	-- unused_excerpt_db.last = created_excerpt.id

	lggr:info("function", "Create excerpt using latest visual selection.")
end

function M.show_unused_excerpt_ids()
	unused_excerpt_db:trigger("show_id")

	lggr:info("function", "Show unused excerpt IDs.")
end

--------------------
-- Mindnode Functions
--------------------

function M.add_last_created_excerpt_to_nearest_mindnode()
	-- Get mindmap
	local mindmap_id = ts_misc.get_buf_mindmap_id(0, true)
	local found_mindmap = card_db:find(mindmap_id, true, mindmap.Mindmap)
	-- Get mindnode
	local mindnode_id = ts_misc.get_nearest_heading_node_id(true)
	local found_mindnode = found_mindmap:find(mindnode_id, true, mindnode.Mindnode)
	-- Add excerpt
	local biggest_id = unused_excerpt_db:find_biggest_id()
	local last_created_excerpt = unused_excerpt_db:pop(biggest_id)
	found_mindnode:add(last_created_excerpt)

	lggr:info("function", "Add last created excerpt to nearest mindnode.")
end

--------------------
-- Mindmap Functions
--------------------

function M.save_mindmap_in_current_buf()
	local mindmap_id = ts_misc.get_buf_mindmap_id(0, false)
	if mindmap_id then
		card_db.sub_items[mindmap_id]:save()
		lggr:info("function", "Save mindmap <" .. mindmap_id .. ">.")
	else
		lggr:warn("function", "Current buffer is not a mindmap buffer. Abort saving.")
	end
end

function M.load_mindmap_in_current_buf()
	local mindmap_id = ts_misc.get_buf_mindmap_id(0, false)
	if mindmap_id then
		card_db:add(mindmap.Mindmap:new({
			id = mindmap_id,
		}))
		lggr:info("function", "Load mindmap <" .. mindmap_id .. ">.")
	else
		lggr:warn("function", "Current buffer is not a mindmap buffer. Abort loading.")
	end
end

--------------------

return M
