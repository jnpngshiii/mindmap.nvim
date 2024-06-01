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

function M.MindmapAddTheNearestHeadingAsAnHeandingNodeToGraph()
	local nearest_heading = ts_utils.get_nearest_heading_node()

	-- local file_name, _, rel_file_path, _ = table.unpack(utils.get_file_info())
	local file_name = utils.get_file_info()[1]
	local rel_file_path = utils.get_file_info()[3]
	local created_heading_node = node_class["HeadingNode"]:new(file_name, rel_file_path)

	local nearest_heading_title_node = ts_utils.get_title_and_content_node(nearest_heading)[1]
	ts_utils.replace_node_text(
		ts_utils.get_heading_node_info(nearest_heading_title_node)[3] .. " %" .. created_heading_node.id .. "%",
		nearest_heading_title_node
	)

	local found_graph =
		plugin_database:find_graph(utils.get_file_info()[4], plugin_config.log_level, plugin_config.show_log_in_nvim)
	found_graph:add_node(created_heading_node)
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

	local node = graph.nodes["1717227961-7088"]
	local output = node:get_content()
	print(table.concat(output.title, "\n"))
	print(table.concat(output.content, "\n"))
end

M.MindmapTest()

--------------------

return M
