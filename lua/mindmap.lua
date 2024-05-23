local node_class = require("mindmap.graph.node.init")
local edge_class = require("mindmap.graph.edge.init")
local graph_class = require("mindmap.graph.init")
local database_class = require("mindmap.database")

local utils = require("mindmap.utils")
local misc = require("mindmap.misc")
local ts_misc = require("mindmap.ts_misc")

local M = {}
-- Return M if this file is a module.
-- Return Class if this file is a class.
-- Return manually if this file is a init.

--------------------
-- Init
--------------------

local plugin_config = {
	log_level = "INFO",
	show_log_in_nvim = true,
}

local plugin_database = database_class["Database"]:new()

--------------------
-- Functions
--------------------

function M.MindmapTest()
	local graph = graph_class["Graph"]:new()

	local node1 = node_class["ExcerptNode"]:new("file_name", "rel_file_path")
	local node2 = node_class["ExcerptNode"]:new("file_name", "rel_file_path")
	local node3 = node_class["ExcerptNode"]:new("file_name", "rel_file_path")
	graph:add_node(node1)
	graph:add_node(node2)
	graph:add_node(node3)

	local edge1 = edge_class["SelfLoopEdge"]:new(node1.id)
	local edge2 = edge_class["SelfLoopEdge"]:new(node2.id)
	local edge3 = edge_class["SelfLoopEdge"]:new(node3.id)
	graph:add_edge(edge1)
	graph:add_edge(edge2)
	graph:add_edge(edge3)

	graph:remove_edge(edge1.id)

	graph:remove_node(node2.id)

	-- graph:to_card(edge3.id)

	graph:save()
end

function M.MindmapAddTheLatestVisualSelectionAsAnExcerptNodeToGraph()
	local created_excerpt_node = node_class["ExcerptNode"].create_using_latest_visual_selection()

	local found_graph = plugin_database:find_graph(
		misc.get_current_proj_path(),
		plugin_config.log_level,
		plugin_config.show_log_in_nvim
	)
	found_graph:add_node(created_excerpt_node)

	-- lggr:info("function", "Create excerpt using latest visual selection.")
end

function M.MindmapAddTheNearestHeadingAsAnHeandingNodeToGraph()
	local nearest_heading = ts_misc.get_nearest_heading_node()

	local file_name = misc.get_current_file_name()
	local abs_file_path = vim.api.nvim_buf_get_name(0)
	local abs_proj_path = misc.get_current_proj_path()
	local rel_file_path = misc.get_rel_path(abs_file_path, abs_proj_path)
	local created_heading_node = node_class["HeadingNode"]:new(file_name, rel_file_path)

	local nearest_heading_title = ts_misc.get_title_and_content_node(nearest_heading)[1]
	ts_misc.replace_node_text(
		ts_misc.get_node_text(nearest_heading_title) .. " %" .. created_heading_node.id .. "%",
		nearest_heading
	)
end

--------------------

M.test = utils.test

return M
