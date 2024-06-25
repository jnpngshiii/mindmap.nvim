-- nvim-treesitter:
local nts_utils = require("nvim-treesitter.ts_utils")
-- telescope:
local actions = require("telescope.actions")
local finders = require("telescope.finders")
local pickers = require("telescope.pickers")
local sorters = require("telescope.sorters")

-- Factory:
local NodeFactory = require("mindmap.factory.NodeFactory")
local EdgeFactory = require("mindmap.factory.EdgeFactory")
local AlgFactory = require("mindmap.factory.AlgFactory")
-- Node:
local BaseNode = require("mindmap.node.BaseNode")
local SimpleNode = require("mindmap.node.SimpleNode")
local HeadingNode = require("mindmap.node.HeadingNode")
local ExcerptNode = require("mindmap.node.ExcerptNode")
-- Edge:
local BaseEdge = require("mindmap.edge.BaseEdge")
local SimpleEdge = require("mindmap.edge.SimpleEdge")
local SelfLoopContentEdge = require("mindmap.edge.SelfLoopContentEdge")
local SelfLoopSubheadingEdge = require("mindmap.edge.SelfLoopSubheadingEdge")
-- Alg:
local BaseAlg = require("mindmap.alg.BaseAlg")
local AnkiAlg = require("mindmap.alg.AnkiAlg")
local SimpleAlg = require("mindmap.alg.SimpleAlg")
local SM2Alg = require("mindmap.alg.SM2Alg")
-- Logger:
local Logger = require("mindmap.graph.Logger")
-- Graph:
local Graph = require("mindmap.graph.Graph")
-- Utils:
local utils = require("mindmap.utils")
local ts_utils = require("mindmap.ts_utils")

local plugin = {}

--------------------
-- Class plugin.config
--------------------

---@class plugin.config
---Node:
---@field base_node BaseNode Base node class.
---@field node_factory NodeFactory Factory of the node.
---Edge:
---@field base_edge BaseEdge Base edge class.
---@field edge_factory EdgeFactory Factory of the edge.
---Alg:
---@field base_alg BaseAlg Base algorithm class.
---@field alg_factory AlgFactory Factory of the algorithm.
---@field alg_type string Type of the algorithm. Default: `"SimpleAlg"`.
---Logger:
---@field log_level string Log level of the graph. Default: `"INFO"`.
---@field show_log_in_nvim boolean Show log in Neovim. Default: `true`.
---Behavior configuration:
---  Default behavior:
---@field enable_default_keymap boolean Enable default keymap. Default: `true`.
---@field keymap_prefix string Prefix of the keymap. Default: `"<localleader>m"`.
---@field enable_shorten_keymap boolean Enable shorten keymap. Default: `false`.
---@field shorten_keymap_prefix string Prefix of the shorten keymap. Default: `"m"`.
---@field enable_default_autocmd boolean Enable default autocmd. Default: `true`.
---@field undo_redo_limit integer Maximum number of undo and redo operations. Default: `3`.
---@field thread_num integer Number of threads to use. Default: `3`.
---  Automatic behavior:
---@field show_excerpt_after_add boolean Show excerpt after adding a node.
---@field show_excerpt_after_bfread boolean Show excerpt after reading a buffer.
plugin.config = {
	-- Node:
	base_node = BaseNode,
	node_factory = NodeFactory,
	-- Edge:
	base_edge = BaseEdge,
	edge_factory = EdgeFactory,
	-- Alg:
	base_alg = BaseAlg,
	alg_factory = AlgFactory,
	alg_type = "SimpleAlg",
	-- Logger:
	log_level = "INFO",
	show_log_in_nvim = true,
	-- Behavior configuration:
	--   Default behavior:
	enable_default_keymap = true,
	keymap_prefix = "<localleader>m",
	enable_shorten_keymap = false,
	shorten_keymap_prefix = "m",
	enable_default_autocmd = true,
	--   Automatic behavior:
	show_excerpt_after_add = true,
	show_excerpt_after_bfread = true,
}

--------------------
-- Class plugin.cache
--------------------

---@class plugin.cache
---@field graphs table<string, Graph> Graphs of different repos.
---@field namespaces table<string, integer> Namespaces of different virtual texts.
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
---@return integer namespace_id Found or created namespace ID.
function plugin.find_namespace(namespace)
	if not plugin.cache.namespaces[namespace] then
		plugin.cache.namespaces[namespace] = vim.api.nvim_create_namespace("mindmap_" .. namespace)
	end

	return plugin.cache.namespaces[namespace]
end

---Find the registered graph using `save_dir` and return it.
---If the graph does not exist, create it first.
---@param save_dir? string Dir to load and save the graph. The graph will be saved in `{self.save_dir}/.mindmap.json`. Default: `{current_project_path}`.
---@return Graph found_graph Found or created graph.
function plugin.find_graph(save_dir)
	save_dir = save_dir or unpack({ utils.get_file_info() })[4]

	if not plugin.cache.graphs[save_dir] then
		local node_factory = plugin.config.node_factory:new(plugin.config.base_node)
		node_factory:register("SimpleNode", SimpleNode)
		node_factory:register("HeadingNode", HeadingNode)
		node_factory:register("ExcerptNode", ExcerptNode)
		local edge_factory = plugin.config.edge_factory:new(plugin.config.base_edge)
		edge_factory:register("SimpleEdge", SimpleEdge)
		edge_factory:register("SelfLoopContentEdge", SelfLoopContentEdge)
		edge_factory:register("SelfLoopSubheadingEdge", SelfLoopSubheadingEdge)
		local alg_factory = plugin.config.alg_factory:new(plugin.config.base_alg)
		alg_factory:register("SimpleAlg", SimpleAlg)
		alg_factory:register("SM2Alg", SM2Alg)
		alg_factory:register("AnkiAlg", AnkiAlg)
		local logger = Logger:new(plugin.config.log_level, plugin.config.show_log_in_nvim)

		local created_graph = Graph:new(
			save_dir,
			---@diagnostic disable-next-line: param-type-mismatch
			node_factory,
			---@diagnostic disable-next-line: param-type-mismatch
			edge_factory,
			---@diagnostic disable-next-line: param-type-mismatch
			alg_factory:create(plugin.config.alg_type),
			logger,
			plugin.config.undo_redo_limit,
			plugin.config.thread_num
		)
		plugin.cache.graphs[created_graph.save_dir] = created_graph
	end

	return plugin.cache.graphs[save_dir]
end

---Find `HeadingNode`s in the given location.
---@param graph Graph The graph to search in.
---@param location string|TSNode Location to find nodes. Location must be TSNode, "latest", "nearest", "telescope" or "buffer".
---@return table<NodeID, BaseNode> found_nodes The found nodes.
function plugin.find_heading_nodes(graph, location)
	if
		type(location) ~= "userdata"
		and location ~= "latest"
		and location ~= "nearest"
		and location ~= "telescope"
		and location ~= "buffer"
	then
		vim.notify(
			string.format(
				"[Func] Invalid location `%s`. Location must be TSNode, `latest`, `nearest`, `telescope` or `buffer`",
				location
			),
			vim.log.levels.ERROR
		)
		return {}
	end

	if type(location) == "userdata" then
		local title_ts_node, _, _ = ts_utils.parse_heading_node(location)
		if not title_ts_node then
			vim.notify(
				"[Func] Cannot find the title treesitter node of the given treesitter node. Abort finding.",
				vim.log.levels.ERROR
			)
			return {}
		end

		local title_ts_node_text = vim.treesitter.get_node_text(title_ts_node, 0)
		local id = tonumber(string.match(title_ts_node_text, "%d%d%d%d%d%d%d%d"))
		if not id then
			vim.notify(
				"[Func] Cannot find the ID of the given node. Automatically add it to the graph.",
				vim.log.levels.WARN
			)

			id = #graph.nodes + 1
			local file_name, _, rel_file_path, _ = utils.get_file_info()
			graph:add_node("HeadingNode", id, file_name, rel_file_path, {}, { ts_node = location })
		end
		if graph.nodes[id]._state ~= "active" then
			return {}
		end

		return { [id] = graph.nodes[id] }
	end

	if location == "latest" then
		local latest_node = graph.nodes[#graph.nodes]
		if not latest_node._state ~= "active" then
			return {}
		end

		return latest_node
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

		-- TODO: Implement telescope functionality
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
