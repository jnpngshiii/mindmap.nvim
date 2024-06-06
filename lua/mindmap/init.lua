local Database = require("mindmap.database.init")

local utils = require("mindmap.utils")
local ts_utils = require("mindmap.ts_utils")

local M = {}

--------------------
-- Init plugin
--------------------

local plugin_config = {
	log_level = "INFO",
	show_log_in_nvim = true,
}

local plugin_database = Database:new()

--------------------
-- User functions
--------------------

----------
-- Node
----------

function M.MindmapAddVisualSelectionAsExcerptNode()
	local found_graph =
		plugin_database:find_graph(utils.get_file_info()[4], plugin_config.log_level, plugin_config.show_log_in_nvim)
	local created_excerpt_node = found_graph.node_class["ExcerptNode"].create_using_latest_visual_selection()

	found_graph:add_node(created_excerpt_node)
end

function M.MindmapAddNearestHeadingAsHeadingNode()
	local found_graph =
		plugin_database:find_graph(utils.get_file_info()[4], plugin_config.log_level, plugin_config.show_log_in_nvim)

	local nearest_heading = ts_utils.get_nearest_heading_node()
	if not nearest_heading then
		return
	end

	-- Avoid adding the same heading node
	local id, _, _ = ts_utils.get_heading_node_info(nearest_heading, 0)
	if id then
		return
	end

	local nearest_heading_title_node, _, _ = ts_utils.get_sub_nodes(nearest_heading)
	if not nearest_heading_title_node then
		return
	end

	local file_name, _, rel_file_path, _ = unpack(utils.get_file_info())
	local created_heading_node = found_graph.node_class["HeadingNode"]:new(file_name, rel_file_path)

	-- TODO: move this to the node class
	local _, _, node_text = ts_utils.get_heading_node_info(nearest_heading_title_node, 0)
	ts_utils.replace_node_text(
		node_text .. " %" .. string.format("%08d", #found_graph.nodes + 1) .. "%",
		nearest_heading_title_node,
		0
	)

	found_graph:add_node(created_heading_node)
end

-- function M.MindmapRemoveNearestHeadingNode()
-- 	local nearest_heading = ts_utils.get_nearest_heading_node()
-- 	if not nearest_heading then
-- 		return
-- 	end
-- 	local id, _, _ = ts_utils.get_heading_node_info(nearest_heading, 0)
-- 	if not id then
-- 		vim.notify("Do not find the nearest heading title node. Abort removing the heading node.", vim.log.levels.WARN)
-- 		return
-- 	end
--
-- 	local found_graph =
-- 		plugin_database:find_graph(utils.get_file_info()[4], plugin_config.log_level, plugin_config.show_log_in_nvim)
-- 	found_graph:remove_node(id)
--
-- 	local nearest_heading_title_node, _, _ = ts_utils.get_sub_nodes(nearest_heading)
-- 	if not nearest_heading_title_node then
-- 		return
-- 	end
--
-- 	local _, _, node_text = ts_utils.get_heading_node_info(nearest_heading_title_node, 0)
-- 	ts_utils.replace_node_text(
-- 		string.gsub(node_text, " %" .. string.format("%08d", id) .. "%", ""),
-- 		nearest_heading_title_node,
-- 		0
-- 	)
-- end

----------
-- Edge
----------

function M.MindmapAddSimpleEdgeFromLatestAddedNodeToNearestHeadingNode()
	local found_graph =
		plugin_database:find_graph(utils.get_file_info()[4], plugin_config.log_level, plugin_config.show_log_in_nvim)

	local nearest_heading = ts_utils.get_nearest_heading_node()
	if not nearest_heading then
		return
	end

	local id, _, _ = ts_utils.get_heading_node_info(nearest_heading, 0)
	if not id then
		M.MindmapAddNearestHeadingAsHeadingNode()
		id, _, _ = ts_utils.get_heading_node_info(nearest_heading, 0)
		if not id then
			return
		end
	end

	local created_simple_edge = found_graph.edge_class["SimpleEdge"]:new(#found_graph.nodes - 1, id)
	found_graph:add_edge(created_simple_edge)
end

function M.MindmapAddSelfLoopContentEdgeFromNearestHeadingNodeToItself()
	local found_graph =
		plugin_database:find_graph(utils.get_file_info()[4], plugin_config.log_level, plugin_config.show_log_in_nvim)

	local nearest_heading = ts_utils.get_nearest_heading_node()
	if not nearest_heading then
		return
	end

	local id, _, _ = ts_utils.get_heading_node_info(nearest_heading, 0)
	if not id then
		M.MindmapAddTheNearestHeadingAsAnHeadingNodeToGraph()
		id, _, _ = ts_utils.get_heading_node_info(nearest_heading, 0)
		if not id then
			return
		end
	end

	local created_self_loop_content_edge = found_graph.edge_class["SelfLoopContentEdge"]:new(id, id)
	found_graph:add_edge(created_self_loop_content_edge)
end

function M.MindmapAddSelfLoopSubheadingEdgeFromNearestHeadingNodeToItself()
	local found_graph =
		plugin_database:find_graph(utils.get_file_info()[4], plugin_config.log_level, plugin_config.show_log_in_nvim)

	local nearest_heading = ts_utils.get_nearest_heading_node()
	if not nearest_heading then
		return
	end

	local id, _, _ = ts_utils.get_heading_node_info(nearest_heading, 0)
	if not id then
		M.MindmapAddNearestHeadingAsHeadingNode()
		id, _, _ = ts_utils.get_heading_node_info(nearest_heading, 0)
		if not id then
			return
		end
	end

	local created_self_loop_subheading_edge = found_graph.edge_class["SelfLoopSubheadingEdge"]:new(id, id)
	found_graph:add_edge(created_self_loop_subheading_edge)
end

----------
-- Database
----------

function M.MindmapSaveAllMindmaps()
	for _, graph in pairs(plugin_database.cache) do
		graph:save()
	end
end

--------------------
-- Debug functions
--------------------

function M.MindmapTest()
	local graph =
		plugin_database:find_graph(utils.get_file_info()[4], plugin_config.log_level, plugin_config.show_log_in_nvim)

	graph:save()
end

--------------------

return M
