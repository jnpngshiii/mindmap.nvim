local Graph = require("mindmap.graph.init")

local utils = require("mindmap.utils")
local ts_utils = require("mindmap.ts_utils")

local M = {}

--------------------
-- Init plugin
--------------------

---@class plugin_config
---Logger configuration:
---@field log_level string Log level of the graph. Default: "INFO".
---@field show_log_in_nvim boolean Show log in Neovim. Default: true.
---Graph configuration:
---  Node:
---@field default_node_type string Default type of the node. Default: "SimpleNode".
---@field node_prototype_cls PrototypeNode Prototype of the node. Used to create sub node classes. Must have a `new` method and a `data` field.
---@field node_sub_cls_info table<NodeType, table> Information of the sub node classes. Must have `data`, `ins_methods` and `cls_methods` fields.
---@field default_node_ins_method table<string, function> Default instance method for all nodes. Example: `foo(self, ...)`.
---@field default_node_cls_method table<string, function> Default class method for all nodes. Example: `foo(cls, self, ...)`.
---  Edge:
---@field default_edge_type string Default type of the edge. Default: "SimpleEdge".
---@field edge_prototype_cls PrototypeEdge Prototype of the edge. Used to create sub edge classes. Must have a `new` method and a `data` field.
---@field edge_sub_cls_info table<EdgeType, table> Information of the sub node classes. Must have `data`, `ins_methods` and `cls_methods` fields.
---@field default_edge_ins_method table<string, function> Default instance method for all edges. Example: `bar(self, ...)`.
---@field default_edge_cls_method table<string, function> Default class method for all edges. Example: `bar(cls, self, ...)`.
---Space repetition configuration:
---@field alg_type string Type of the algorithm used in space repetition. Default to "sm-2".
---@field alg_prototype_cls PrototypeAlg Prototype of the algorithm. Used to create sub algorithm classes. Must have a `new` method and a `data` field.
---@field alg_sub_cls_info table<AlgType, PrototypeAlg> Information of the sub algorithm classes. Must have `data`, `ins_methods` and `cls_methods` fields.
---@field default_alg_ins_method table<string, function> Default instance method for all algorithms. Example: `baz(self, ...)`.
---@field default_alg_cls_method table<string, function> Default class method for all algorithms. Example: `baz(cls, self, ...)`.
---Behavior configuration:
---  Automatic behavior:
---@field show_excerpt_after_add boolean Show excerpt after adding a node. Default: true.
---@field show_excerpt_after_bfread boolean ...
---@field show_sp_info_after_bfread boolean ...
---  Default behavior:
---@field enable_default_keymap boolean Enable default keymap. Default: true.
local plugin_config = {
	-- Logger configuration:
	log_level = "INFO",
	show_log_in_nvim = true,
	-- Graph configuration:
	--   Node:
	default_node_type = "SimpleNode",
	node_prototype_cls = require("mindmap.graph.node.node_prototype_cls"),
	node_sub_cls_info = require("mindmap.graph.node.node_sub_cls_info"),
	default_node_ins_method = require("mindmap.graph.node.node_ins_method"),
	default_node_cls_method = require("mindmap.graph.node.node_cls_method"),
	--   Edge:
	default_edge_type = "SimpleEdge",
	edge_prototype_cls = require("mindmap.graph.edge.edge_prototype_cls"),
	edge_sub_cls_info = require("mindmap.graph.edge.edge_sub_cls_info"),
	default_edge_ins_method = require("mindmap.graph.edge.edge_ins_method"),
	default_edge_cls_method = require("mindmap.graph.edge.edge_cls_method"),
	-- Space repetitionconfiguration:
	alg_type = "sm-2",
	alg_prototype_cls = require("mindmap.graph.alg.alg_prototype_cls"),
	alg_sub_cls_info = require("mindmap.graph.alg.alg_sub_cls_info"),
	default_alg_ins_method = require("mindmap.graph.alg.alg_ins_method"),
	default_alg_cls_method = require("mindmap.graph.alg.alg_cls_method"),
	-- Behavior configuration:
	--   Automatic behavior:
	show_excerpt_after_add = true,
	--   Default behavior:
	enable_default_keymap = true,
}

---@class plugin_database
---@field graphs table<string, Graph> Graphs of different repo.
---@field namespaces table<string, integer> Namespaces of different virtual text.
local plugin_database = {
	graphs = {},
	namespaces = {},
}

---Find the registered namespace and return it.
---If the namespace does not exist, register it first.
---@param namespace string Namespace to find.
---@return integer namespace Found or created namespace.
local function find_namespace(namespace)
	if not plugin_database.namespaces[namespace] then
		plugin_database.namespaces[namespace] = vim.api.nvim_create_namespace("mindmap_" .. namespace)
	end

	return plugin_database.namespaces[namespace]
end

---Find the registered graph using `save_path` and return it.
---If the graph does not exist, create it first.
---@param save_path? string Save path of the graph to find.
---@return Graph graph Found or created graph.
local function find_graph(save_path)
	save_path = save_path or utils.get_file_info()[4]
	if not plugin_database.graphs[save_path] then
		local created_graph = Graph:new(
			save_path,
			--
			plugin_config.log_level,
			plugin_config.show_log_in_nvim,
			--
			plugin_config.default_node_type,
			plugin_config.node_prototype_cls,
			plugin_config.node_sub_cls_info,
			plugin_config.default_node_ins_method,
			plugin_config.default_node_cls_method,
			--
			plugin_config.default_edge_type,
			plugin_config.edge_prototype_cls,
			plugin_config.edge_sub_cls_info,
			plugin_config.default_edge_ins_method,
			plugin_config.default_edge_cls_method,
			--
			plugin_config.alg_type,
			plugin_config.alg_prototype_cls,
			plugin_config.alg_sub_cls_info,
			plugin_config.default_alg_ins_method,
			plugin_config.default_alg_cls_method
		)
		plugin_database.graphs[created_graph.save_path] = created_graph
	end

	return plugin_database.graphs[save_path]
end

---Find nodes and tree-sitter nodes in the given location.
---@param location string|TSNode Location to find nodes. Location must be `nearest`, `buffer`, `graph` or `telescope`.
---@return table<NodeID, PrototypeNode> nodes, table<NodeID, TSNode> ts_nodes Found nodes and tree-sitter nodes.
local function find_nodes(location)
	local found_graph = find_graph()
	local ts_nodes

	if type(location) == "userdata" then
		-- TODO: allow multiple locations
		ts_nodes = { location }
	elseif location == "nearest" then
		local nearest_heading = ts_utils.get_nearest_heading_node()
		local id, _, _ = ts_utils.get_heading_node_info(nearest_heading, 0)
		-- TODO: remove auto add behavior
		if not id then
			local file_name, _, rel_file_path, _ = unpack(utils.get_file_info())
			local created_heading_node =
				found_graph.node_sub_cls["HeadingNode"]:new(#found_graph.nodes + 1, file_name, rel_file_path)

			local nearest_heading_title_node, _, _ = ts_utils.get_sub_nodes(nearest_heading)
			local node_text = vim.treesitter.get_node_text(nearest_heading_title_node, 0)
			ts_utils.replace_node_text(
				node_text .. " %" .. string.format("%08d", #found_graph.nodes + 1) .. "%",
				nearest_heading_title_node,
				0
			)

			found_graph:add_node(created_heading_node)
		end

		ts_nodes = { nearest_heading }
	elseif location == "buffer" then
		ts_nodes = ts_utils.get_all_heading_nodes_with_inline_comment()
	elseif location == "graph" then
		-- TODO: implement this
		vim.notify("[find_nodes] Location `graph` is not implemented yet.", vim.log.levels.ERROR)
	elseif location == "telescope" then
		-- TODO: implement this
		vim.notify("[find_nodes] Location `telescope` is not implemented yet.", vim.log.levels.ERROR)
	else
		vim.notify(
			"[find_nodes] Invalid location `"
				.. location
				.. "`. Location must be `nearest`, `buffer`, `graph` or `telescope`.",
			vim.log.levels.ERROR
		)
	end

	local output_nodes = {}
	local output_ts_nodes = {}
	for _, ts_node in pairs(ts_nodes) do
		local id, _, _ = ts_utils.get_heading_node_info(ts_node, 0)
		if id then
			output_nodes[id] = found_graph.nodes[id]
			output_ts_nodes[id] = ts_node
		end
	end

	return output_nodes, output_ts_nodes
end

function M.setup(user_config)
	plugin_config = vim.tbl_extend("force", plugin_config, user_config)
end

--------------------
-- User functions
--------------------

function M.MindmapShow(location, type)
	if type ~= "card_back" and type ~= "excerpt" and type ~= "sp_info" then
		vim.notify(
			"[MindmapShow] Invalid `type`. Type must be `card_back`, `excerpt` or `sp_info`.",
			vim.log.levels.ERROR
		)
		return
	end

	local graph = find_graph()
	local _, ts_nodes = find_nodes(location)

	for id, ts_node in pairs(ts_nodes) do
		-- Avoid duplicate virtual text
		M.MindmapClean(ts_node, type)

		local line_num, _, _, _ = ts_node:range()
		line_num = line_num + 1

		for index, incoming_edge_id in ipairs(graph.nodes[id].incoming_edge_ids) do
			if type == "card_back" then
				local incoming_edge = graph.edges[incoming_edge_id]
				local from_node = graph.nodes[incoming_edge.from_node_id]
				local _, back = from_node:get_content(incoming_edge.type)

				local text = index .. ": " .. back[1]
				utils.add_virtual_text(0, find_namespace(type), line_num, text)
			end

			if type == "excerpt" then
				local incoming_edge = graph.edges[incoming_edge_id]
				local from_node = graph.nodes[incoming_edge.from_node_id]
				if from_node.type == "ExcerptNode" then
					local _, back = from_node:get_content(incoming_edge.type)

					local text = "│ " .. table.concat(back, " ")
					utils.add_virtual_text(0, find_namespace(type), line_num, text)
				end
			end

			if type == "sp_info" then
				local front, back, created_at, updated_at, due_at, ease, interval =
					graph:get_sp_info_from_edge(incoming_edge_id)

				local text = string.format("Due at: %d, Ease: %d, Int: %d", due_at, ease, interval)
				utils.add_virtual_text(0, find_namespace(type), line_num, text)
			end
		end
	end
end

function M.MindmapClean(location, type)
	if type ~= "card_back" and type ~= "excerpt" and type ~= "sp_info" then
		vim.notify(
			"[MindmapClean] Invalid `type`. Type must be `card_back`, `excerpt` or `sp_info`.",
			vim.log.levels.ERROR
		)
		return
	end

	local _, ts_nodes = find_nodes(location)

	for _, ts_node in pairs(ts_nodes) do
		local start_row, _, _, _ = ts_node:range()
		utils.clear_virtual_text(0, find_namespace(type), start_row, start_row + 1)
	end
end

function M.MindmapSave(type)
	if type ~= "buffer" and type ~= "all" then
		vim.notify("[MindmapSave] Invalid `type`. Type must be `buffer` or `all`.", vim.log.levels.ERROR)
		return
	end

	if type == "all" then
		for _, graph in pairs(plugin_database.graphs) do
			graph:save()
		end
	end

	if type == "buffer" then
		local found_graph = find_graph()
		found_graph:save()
	end
end

--------------------
-- Debug functions
--------------------

function M.MindmapTest()
	local graph = find_graph()

	graph:save()
end

----------
-- Node
----------

function M.MindmapAddVisualSelectionAsExcerptNode()
	local found_graph = find_graph()
	local created_excerpt_node =
		found_graph.node_sub_cls["ExcerptNode"]:create_using_latest_visual_selection(#found_graph.nodes + 1)

	found_graph:add_node(created_excerpt_node)
end

function M.MindmapAddNearestHeadingAsHeadingNode()
	find_nodes("nearest")
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

	local created_simple_edge =
		found_graph.edge_sub_cls["SimpleEdge"]:new(#found_graph.edges + 1, #found_graph.nodes, id)
	found_graph:add_edge(created_simple_edge)

	if plugin_config.show_excerpt_after_add and found_graph.nodes[#found_graph.nodes].type == "ExcerptNode" then
		M.MindmapShowExcerpt(nearest_heading)
	end
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
		found_graph.edge_sub_cls["SelfLoopContentEdge"]:new(#found_graph.edges + 1, id, id)
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
		found_graph.edge_sub_cls["SelfLoopSubheadingEdge"]:new(#found_graph.edges + 1, id, id)
	found_graph:add_edge(created_self_loop_subheading_edge)
end

--------------------

return M
