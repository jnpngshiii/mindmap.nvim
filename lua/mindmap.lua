local node_class = require("mindmap.graph.node.init")
local edge_class = require("mindmap.graph.edge.init")
local graph_class = require("mindmap.graph.init")
local database_class = require("mindmap.database")
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

--------------------

return M
