local actions = require("telescope.actions")
local finders = require("telescope.finders")
local pickers = require("telescope.pickers")
local sorters = require("telescope.sorters")

local Graph = require("mindmap.graph.init")

local plugin = {}

--------------------
-- Class plugin.config
--------------------

---@class plugin.config
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
---@field alg_type string Type of the algorithm used in space repetition. Default to "SM2Alg".
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
---@field keymap_prefix string Prefix of the keymap. Default: "<localleader>m".
---@field enable_shorten_keymap boolean Enable shorten keymap. Default: false.
---@field shorten_keymap_prefix string Prefix of the shorten keymap. Default: "m".
---@field enable_default_autocmd boolean Enable default atuocmd. Default: true.
plugin.config = {
	-- Logger configuration:
	log_level = "INFO",
	show_log_in_nvim = true,
	-- Graph configuration:
	--   Node:
	default_node_type = "SimpleNode",
	node_prototype_cls = require("mindmap.graph.node.prototype_node"),
	node_sub_cls_info = {
		ExcerptNode = require("mindmap.graph.node.excerpt_node"),
		HeadingNode = require("mindmap.graph.node.heading_node"),
		SimpleNode = require("mindmap.graph.node.simple_node"),
	},
	default_node_ins_method = require("mindmap.graph.node.default_ins_method"),
	default_node_cls_method = require("mindmap.graph.node.default_cls_method"),
	--   Edge:
	default_edge_type = "SimpleEdge",
	edge_prototype_cls = require("mindmap.graph.edge.prototype_edge"),
	edge_sub_cls_info = {
		SelfLoopContentEdge = require("mindmap.graph.edge.self_loop_content_edge"),
		SelfLoopSubheadingEdge = require("mindmap.graph.edge.self_loop_subheading_edge"),
		SimpleEdge = require("mindmap.graph.edge.simple_edge"),
	},
	default_edge_ins_method = require("mindmap.graph.edge.default_ins_method"),
	default_edge_cls_method = require("mindmap.graph.edge.default_cls_method"),
	-- Space repetitionconfiguration:
	alg_type = "SimpleAlg", -- TODO: "SM2Alg"
	alg_prototype_cls = require("mindmap.graph.alg.prototype_alg"),
	alg_sub_cls_info = {
		AnkiAlg = require("mindmap.graph.alg.anki_alg"),
		SimpleAlg = require("mindmap.graph.alg.simple_alg"),
		SM2Alg = require("mindmap.graph.alg.sm2_alg"),
	},
	default_alg_ins_method = require("mindmap.graph.alg.default_ins_method"),
	default_alg_cls_method = require("mindmap.graph.alg.default_cls_method"),
	-- Behavior configuration:
	--   Automatic behavior:
	show_excerpt_after_add = true,
	--   Default behavior:
	enable_default_keymap = true,
	keymap_prefix = "<localleader>m",
	enable_shorten_keymap = false,
	shorten_keymap_prefix = "m",
	enable_default_autocmd = true,
}

--------------------
-- Class plugin.cache
--------------------

---@class plugin.cache
---@field graphs table<string, Graph> Graphs of different repo.
---@field namespaces table<string, integer> Namespaces of different virtual text.
plugin.cache = {
	graphs = {},
	namespaces = {},
}

--------------------
-- Functions
--------------------

---Find the registered namespace and return it.
---If the namespace does not exist, register it first.
---@param namespace string Namespace to find.
---@return integer namespace Found or created namespace.
function plugin.find_namespace(namespace)
	if not plugin.cache.namespaces[namespace] then
		plugin.cache.namespaces[namespace] = vim.api.nvim_create_namespace("mindmap_" .. namespace)
	end

	return plugin.cache.namespaces[namespace]
end

---Find the registered graph using `save_path` and return it.
---If the graph does not exist, create it first.
---@param save_path? string Save path of the graph to find.
---@return Graph graph Found or created graph.
function plugin.find_graph(save_path)
	save_path = save_path or utils.get_file_info()[4]
	if not plugin.cache.graphs[save_path] then
		local created_graph = Graph:new(
			save_path,
			--
			plugin.config.log_level,
			plugin.config.show_log_in_nvim,
			--
			plugin.config.default_node_type,
			plugin.config.node_prototype_cls,
			plugin.config.node_sub_cls_info,
			plugin.config.default_node_ins_method,
			plugin.config.default_node_cls_method,
			--
			plugin.config.default_edge_type,
			plugin.config.edge_prototype_cls,
			plugin.config.edge_sub_cls_info,
			plugin.config.default_edge_ins_method,
			plugin.config.default_edge_cls_method,
			--
			plugin.config.alg_type,
			plugin.config.alg_prototype_cls,
			plugin.config.alg_sub_cls_info,
			plugin.config.default_alg_ins_method,
			plugin.config.default_alg_cls_method
		)
		plugin.cache.graphs[created_graph.save_path] = created_graph
	end

	return plugin.cache.graphs[save_path]
end

---Find nodes and its corresponding tree-sitter nodes in the given location.
---@param location string|TSNode Location to find nodes. Location must be TSNode, "lastest", "nearest", "telescope" or "buffer".
---@return table<NodeID, PrototypeNode> nodes, table<NodeID, TSNode> ts_nodes Found nodes and its corresponding tree-sitter nodes.
function plugin.find_heading_nodes(graph, location)
	if
		type(location) ~= "userdata"
		and location ~= "lastest"
		and location ~= "nearest"
		and location ~= "telescope"
		and location ~= "buffer"
	then
		vim.notify(
			"[plugin.find_heading_nodes] Invalid location `"
				.. location
				.. '`. Location must be TSNode, "lastest", "nearest", "telescope" or "buffer"',
			vim.log.levels.ERROR
		)
		return {}, {}
	end

	if type(location) == "userdata" then
		local title_ts_node, _, _ = ts_utils.parse_heading_node(location)
		local title_ts_node_text = vim.treesitter.get_node_text(title_ts_node, 0)
		local nearest_node_id = tonumber(string.match(title_ts_node_text, "%d%d%d%d%d%d%d%d"))

		local nearest_node
		if nearest_node_id then
			nearest_node = graph.nodes[nearest_node_id]
		else
			-- TODO: auto add node if not exist
		end

		if nearest_node and nearest_node.state == "active" then
			return { [nearest_node.id] = nearest_node }, { [nearest_node.id] = location }
		else
			return {}, {}
		end
	end

	if location == "lastest" then
		-- The process here is a littel bit different.
		local lastest_node = graph.nodes[#graph.nodes]
		local lastest_ts_node

		if lastest_node.state == "active" then
			return { [lastest_node.id] = lastest_node }, { [lastest_node.id] = lastest_ts_node }
		else
			return {}, {}
		end
	end

	if location == "nearest" then
		local nearest_ts_node = nts_utils.get_node_at_cursor()
		while nearest_ts_node and not nearest_ts_node:type():match("^heading%d$") do
			nearest_ts_node = nearest_ts_node:parent()
		end

		if not nearest_ts_node then
			return {}, {}
		end

		local title_ts_node, _, _ = ts_utils.parse_heading_node(nearest_ts_node)
		local title_ts_node_text = vim.treesitter.get_node_text(title_ts_node, 0)
		local nearest_node_id = tonumber(string.match(title_ts_node_text, "%d%d%d%d%d%d%d%d"))

		local nearest_node
		if nearest_node_id then
			nearest_node = graph.nodes[nearest_node_id]
		else
			-- TODO: auto add node if not exist
		end

		if nearest_node and nearest_node.state == "active" then
			return { [nearest_node.id] = nearest_node }, { [nearest_node.id] = nearest_ts_node }
		else
			return {}, {}
		end
	end

	if location == "telescope" then
		local nodes = {}
		for _, node in pairs(graph.nodes) do
			if node.state == "active" then
				table.insert(nodes, {
					node.id,
					node.type,
					node:get_abs_path(),
					node:get_content()[1],
				})
			end
		end

		pickers
			.new({}, {
				prompt_title = "Select a node",
				finder = finders.new_table({
					results = nodes,
					entry_maker = function(entry)
						return {
							value = entry,
							display = string.format(
								"ID: %s | Type: %s | Path: %s | Content: %s",
								entry[1],
								entry[2],
								entry[3],
								entry[4]
							),
							ordinal = entry[1],
							path = entry[3],
							lnum = entry[1],
						}
					end,
				}),
			})
			:find()

		-- TODO: ...
	end

	if location == "buffer" then
		local found_ts_nodes = ts_utils.get_heading_node_in_buf()

		local found_nodes = {}
		for id, _ in pairs(found_ts_nodes or {}) do
			if graph.nodes[id].state == "active" then
				found_nodes[id] = graph.nodes[id]
			end
		end

		return found_nodes, found_ts_nodes
	end

	return {}, {}
end

--------------------

return plugin
