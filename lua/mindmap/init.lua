local Graph = require("mindmap.graph.init")

local utils = require("mindmap.utils")
local ts_utils = require("mindmap.ts_utils")

local M = {}

--------------------
-- Init plugin
--------------------

---@class plugin_config
---Logger configuration:
---@field log_level string Log level of the plugin. Default to "INFO".
---@field show_log_in_nvim boolean Show log in nvim. Default to true.
---Other configuration:
---@field excerpt_namespace integer Namespace for excerpt nodes.
---@field sp_namespace integer Namespace for space repetition.
---@field node_prototype_cls PrototypeNode Node prototype class.
---@field edge_prototype_cls PrototypeEdge Edge prototype class.
---@field node_sub_cls PrototypeNode Node sub class.
---@field edge_sub_cls PrototypeEdge Edge sub class.
local plugin_config = {
	-- Logger configuration:
	log_level = "INFO",
	show_log_in_nvim = true,
	-- Other configuration:
	excerpt_namespace = vim.api.nvim_create_namespace("my_namespace"),
	sp_namespace = vim.api.nvim_create_namespace("my_namespace"),
	node_prototype_cls = require("mindmap.graph.node.node_prototype_cls"),
	edge_prototype_cls = require("mindmap.graph.edge.edge_prototype_cls"),
	node_sub_cls = require("mindmap.graph.node.node_sub_cls"),
	edge_sub_cls = require("mindmap.graph.edge.edge_sub_cls"),
}

---@class plugin_database
---@field cache table<string, Graph> Cache of graphs in different repos.
local plugin_database = {
	cache = {},
}

---Find a graph in the database using path.
---If not found, add a new graph to the database.
---@return Graph graph Found or created graph.
local function find_graph()
	local graph_save_path = utils.get_file_info()[4]

	if not plugin_database.cache[graph_save_path] then
		local created_graph = Graph:new(
			graph_save_path,
			--
			plugin_config.log_level,
			plugin_config.show_log_in_nvim,
			--
			plugin_config.node_prototype_cls,
			plugin_config.edge_prototype_cls,
			plugin_config.node_sub_cls,
			plugin_config.edge_sub_cls
		)
		plugin_database.cache[created_graph.save_path] = created_graph
	end

	return plugin_database.cache[graph_save_path]
end

--------------------
-- User functions
--------------------

----------
-- Node
----------

function M.MindmapAddVisualSelectionAsExcerptNode()
	local found_graph = find_graph()
	local created_excerpt_node =
		found_graph.node_class["ExcerptNode"]:create_using_latest_visual_selection(#found_graph.nodes + 1)

	found_graph:add_node(created_excerpt_node)
end

function M.MindmapAddNearestHeadingAsHeadingNode()
	local found_graph = find_graph()

	local nearest_heading = ts_utils.get_nearest_heading_node()
	if not nearest_heading then
		return
	end

	-- Avoid adding the same heading node
	local id, _, _ = ts_utils.get_heading_node_info(nearest_heading, 0)
	if id then
		return
	end

	local file_name, _, rel_file_path, _ = unpack(utils.get_file_info())
	local created_heading_node =
		found_graph.node_class["HeadingNode"]:new(#found_graph.nodes + 1, file_name, rel_file_path)

	-- TODO: move this to the node class
	local nearest_heading_title_node, _, _ = ts_utils.get_sub_nodes(nearest_heading)
	local _, _, node_text = ts_utils.get_heading_node_info(nearest_heading_title_node, 0)
	ts_utils.replace_node_text(
		node_text .. " %" .. string.format("%08d", #found_graph.nodes + 1) .. "%",
		nearest_heading_title_node,
		0
	)

	found_graph:add_node(created_heading_node)
end

function M.MindmapRemoveNearestHeadingNode()
	local found_graph = find_graph()

	local nearest_heading = ts_utils.get_nearest_heading_node()
	if not nearest_heading then
		return
	end

	local id, _, _ = ts_utils.get_heading_node_info(nearest_heading, 0)
	if not id then
		vim.notify("Do not find the nearest heading title node. Abort removing the heading node.", vim.log.levels.WARN)
		return
	end
	found_graph:remove_node(id)

	local nearest_heading_title_node, _, _ = ts_utils.get_sub_nodes(nearest_heading)
	local _, _, node_text = ts_utils.get_heading_node_info(nearest_heading_title_node, 0)
	ts_utils.replace_node_text(
		string.gsub(node_text, " %%" .. string.format("%08d", id) .. "%%", ""),
		nearest_heading_title_node,
		0
	)
end

----------
-- Edge
----------

---@param node? TSNode
---@param graph? Graph
function M.MindmapShowExcerpt(node, graph)
	node = node or ts_utils.get_nearest_heading_node()
	graph = graph or find_graph()

	local id
	local line_num
	if node then
		-- Avoid duplicate virtual text
		M.MindmapCleanExcerpt(node)

		id, _, _ = ts_utils.get_heading_node_info(node, 0)
		line_num, _, _, _ = node:range()
		line_num = line_num + 1

		-- If `id` is not nil, this `HeadingNode` is register in the `found_graph`.
		if id then
			for _, incoming_edge_id in ipairs(graph.nodes[id].incoming_edge_ids) do
				local incoming_edge = graph.edges[incoming_edge_id]
				local from_node = graph.nodes[incoming_edge.from_node_id]

				-- If `from_node.type` is `ExcerptNode`, add it to the list.
				-- TODO: exclude the `ExcerptNode` from the same file.
				if from_node.type == "ExcerptNode" then
					local text, _ = from_node:get_content(incoming_edge.type)

					text[1] = "Ex: " .. text[1]
					utils.add_virtual_text(0, plugin_config.excerpt_namespace, line_num, text)
				end
			end
		end
		-- EOIf id
	end
	-- EOIf node
end

function M.MindmapShowAllExcerpt()
	-- Avoid duplicate virtual text
	M.MindmapCleanAllExcerpt()

	local found_graph = find_graph()
	local heading_nodes_with_inline_comment = ts_utils.get_all_heading_nodes_with_inline_comment()

	for _, node in pairs(heading_nodes_with_inline_comment) do
		M.MindmapShowExcerpt(node, found_graph)
	end
end

---@param node? TSNode
function M.MindmapCleanExcerpt(node)
	node = node or ts_utils.get_nearest_heading_node()

	if node then
		local start_row, _, _, _ = node:range()
		utils.clear_virtual_text(0, plugin_config.excerpt_namespace, start_row, start_row + 1)
	end
end

function M.MindmapCleanAllExcerpt()
	utils.clear_virtual_text(0, plugin_config.excerpt_namespace)
end

-- TODO: Refactor this function
function M.MindmapAddEdgeFromLatestAddedNodeToNearestHeadingNode(edge_cls)
	local found_graph = find_graph()

	local nearest_heading = ts_utils.get_nearest_heading_node()
	if not nearest_heading then
		vim.notify("Can not find the nearest heading node. Abort adding edge.", vim.log.levels.WARN)
		return
	end

	local id, _, _ = ts_utils.get_heading_node_info(nearest_heading, 0)
	if not id then
		vim.notify("Nearest heading node is not a heading node. Add it as a `HeadingNode`.", vim.log.levels.INFO)
		M.MindmapAddNearestHeadingAsHeadingNode()
		id, _, _ = ts_utils.get_heading_node_info(nearest_heading, 0)
		if not id then
			vim.notify(
				"Can not add the nearest heading node as a `HeadingNode`. Abort adding edge.",
				vim.log.levels.WARN
			)
			return
		end
	end

	local created_simple_edge = found_graph.edge_class[edge_cls]:new(#found_graph.edges + 1, #found_graph.nodes - 1, id)
	found_graph:add_edge(created_simple_edge)

	local front, back = found_graph:get_sp_info_from_edge(#found_graph.edges)
	print("Front:")
	for _, v in ipairs(front) do
		print(v)
	end
	print("Back:")
	for _, v in ipairs(back) do
		print(v)
	end
end

function M.MindmapAddSimpleEdgeFromLatestAddedNodeToNearestHeadingNode()
	local found_graph = find_graph()

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

	local created_simple_edge = found_graph.edge_class["SimpleEdge"]:new(#found_graph.edges + 1, #found_graph.nodes, id)
	found_graph:add_edge(created_simple_edge)
end

function M.MindmapAddSelfLoopContentEdgeFromNearestHeadingNodeToItself()
	local found_graph = find_graph()

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

	local created_self_loop_content_edge =
		found_graph.edge_class["SelfLoopContentEdge"]:new(#found_graph.edges + 1, id, id)
	found_graph:add_edge(created_self_loop_content_edge)
end

function M.MindmapAddSelfLoopSubheadingEdgeFromNearestHeadingNodeToItself()
	local found_graph = find_graph()

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

	local created_self_loop_subheading_edge =
		found_graph.edge_class["SelfLoopSubheadingEdge"]:new(#found_graph.edges + 1, id, id)
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
	local graph = find_graph()

	graph:save()
end

--------------------

return M
