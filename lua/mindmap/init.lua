local node_class = require("mindmap.graph.node.init")
local edge_class = require("mindmap.graph.edge.init")
local graph_class = require("mindmap.graph.init")
local database_class = require("mindmap.database")

local utils = require("mindmap.utils")
local ts_utils = require("mindmap.ts_utils")

local M = {}
-- Return M if this file is a module.
-- Return Class if this file is a class.
-- Return manually if this file is a init.

--------------------
-- Init plugin
--------------------

local plugin_config = {
	log_level = "INFO",
	show_log_in_nvim = true,
}

local plugin_database = database_class["Database"]:new()

--------------------
-- User functions
--------------------

function M.MindmapAddTheLatestVisualSelectionAsAnExcerptNodeToGraph()
	local created_excerpt_node = node_class["ExcerptNode"].create_using_latest_visual_selection()

	local found_graph =
		plugin_database:find_graph(utils.get_file_info()[4], plugin_config.log_level, plugin_config.show_log_in_nvim)
	found_graph:add_node(created_excerpt_node)
end

function M.MindmapAddTheNearestHeadingAsAnHeadingNodeToGraph()
	local file_name, _, rel_file_path, _ = unpack(utils.get_file_info())
	local created_heading_node = node_class["HeadingNode"]:new(file_name, rel_file_path)

	local nearest_heading = ts_utils.get_nearest_heading_node()
	if not nearest_heading then
		vim.notify_once("Do not find the nearest heading node. Abort adding the heading node.", vim.log.levels.WARN)
		return
	end

	local nearest_heading_title_node, _, _ = ts_utils.get_sub_nodes(nearest_heading)
	if not nearest_heading_title_node then
		vim.notify_once(
			"Do not find the nearest heading title node. Abort adding the heading node.",
			vim.log.levels.WARN
		)
		return
	end

	local found_graph =
		plugin_database:find_graph(utils.get_file_info()[4], plugin_config.log_level, plugin_config.show_log_in_nvim)
	found_graph:add_node(created_heading_node)

	local _, _, node_text = ts_utils.get_heading_node_info(nearest_heading_title_node, 0)
	ts_utils.replace_node_text(
		node_text .. " %" .. string.format("%08d", #found_graph.nodes) .. "%",
		nearest_heading_title_node,
		0
	)
end

function M.MindmapAddSelfLoopContentEdgeToNearestHeadingNode()
	local nearest_heading = ts_utils.get_nearest_heading_node()
	if not nearest_heading then
		vim.notify_once(
			"Do not find the nearest heading node. Abort adding the self loop content edge.",
			vim.log.levels.WARN
		)
		return
	end

	local id, _, _ = ts_utils.get_heading_node_info(nearest_heading, 0)
	if not id then
		vim.notify_once(
			"Do not find the nearest heading id. Add the nearest heading node to the graph first.",
			vim.log.levels.WARN
		)
		M.MindmapAddTheNearestHeadingAsAnHeadingNodeToGraph()
		id, _, _ = ts_utils.get_heading_node_info(nearest_heading, 0)
	end

	local created_self_loop_content_edge = edge_class["SelfLoopContentEdge"]:new(id)
	local found_graph =
		plugin_database:find_graph(utils.get_file_info()[4], plugin_config.log_level, plugin_config.show_log_in_nvim)
	found_graph:add_edge(created_self_loop_content_edge)

	local front, back, _, _, _, _, _ = found_graph:get_card_info_from_edge(#found_graph.edges)
	for _, text in ipairs(front) do
		print(text)
	end
	for _, text in ipairs(back) do
		print(text)
	end
end

function M.MindmapSaveAllMindmapsInDatabase()
	for _, graph in pairs(plugin_database.cache) do
		graph:save()
	end
end

--------------------
-- Debug functions
--------------------

function M.MindmapTest()
	local pth = utils.get_file_info()[4]
	local graph = graph_class["Graph"].load(pth)
	local node = graph.nodes[1]
	-- graph:add_node(node)
	-- graph:save()
end

--------------------

return M
