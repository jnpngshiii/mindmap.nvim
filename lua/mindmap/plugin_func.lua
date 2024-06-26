-- nvim-treesitter:
local nts_utils = require("nvim-treesitter.ts_utils")
-- telescope:
local actions = require("telescope.actions")
local finders = require("telescope.finders")
local pickers = require("telescope.pickers")
local sorters = require("telescope.sorters")

-- Node:
local SimpleNode = require("mindmap.node.SimpleNode")
local HeadingNode = require("mindmap.node.HeadingNode")
local ExcerptNode = require("mindmap.node.ExcerptNode")
-- Edge:
local SimpleEdge = require("mindmap.edge.SimpleEdge")
local SelfLoopContentEdge = require("mindmap.edge.SelfLoopContentEdge")
local SelfLoopSubheadingEdge = require("mindmap.edge.SelfLoopSubheadingEdge")
-- Alg:
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
-- Plugin data:
local plugin_data = require("mindmap.plugin_data")

local plugin_func = {}

--------------------

---Find the registered namespace and return it.
---If the namespace does not exist, register it first.
---@param namespace string Namespace to find.
---@return integer namespace_id Found or created namespace ID.
function plugin_func.find_namespace(namespace)
	if not plugin_data.cache.namespaces[namespace] then
		plugin_data.cache.namespaces[namespace] = vim.api.nvim_create_namespace("mindmap_" .. namespace)
	end

	return plugin_data.cache.namespaces[namespace]
end

---Find the registered graph using `save_dir` and return it.
---If the graph does not exist, create it first.
---@param save_dir? string Dir to load and save the graph. The graph will be saved in `{self.save_dir}/.mindmap.json`. Default: `{current_project_path}`.
---@return Graph found_graph Found or created graph.
function plugin_func.find_graph(save_dir)
	save_dir = save_dir or unpack({ utils.get_file_info() })[4]

	if not plugin_data.cache.graphs[save_dir] then
		local node_factory = plugin_data.config.node_factory:new(plugin_data.config.base_node)
		node_factory:register("SimpleNode", SimpleNode)
		node_factory:register("HeadingNode", HeadingNode)
		node_factory:register("ExcerptNode", ExcerptNode)
		local edge_factory = plugin_data.config.edge_factory:new(plugin_data.config.base_edge)
		edge_factory:register("SimpleEdge", SimpleEdge)
		edge_factory:register("SelfLoopContentEdge", SelfLoopContentEdge)
		edge_factory:register("SelfLoopSubheadingEdge", SelfLoopSubheadingEdge)
		local alg_factory = plugin_data.config.alg_factory:new(plugin_data.config.base_alg)
		alg_factory:register("SimpleAlg", SimpleAlg)
		alg_factory:register("SM2Alg", SM2Alg)
		alg_factory:register("AnkiAlg", AnkiAlg)
		local logger = Logger:new(plugin_data.config.log_level, plugin_data.config.show_log_in_nvim)

		local created_graph = Graph:new(
			save_dir,
			---@diagnostic disable-next-line: param-type-mismatch
			node_factory,
			---@diagnostic disable-next-line: param-type-mismatch
			edge_factory,
			---@diagnostic disable-next-line: param-type-mismatch
			alg_factory:create(plugin_data.config.alg_type),
			logger,
			plugin_data.config.undo_redo_limit,
			plugin_data.config.thread_num
		)
		plugin_data.cache.graphs[created_graph.save_dir] = created_graph
	end

	return plugin_data.cache.graphs[save_dir]
end

---Find `HeadingNode`s in the given location.
---@param graph Graph The graph to search in.
---@param location string|TSNode Location to find nodes. Location must be TSNode, "latest", "nearest", "telescope" or "buffer".
---@param force_add? boolean Whether to force add the node if the ID is not found. Default: `false`.
---@param id_regex? string Regex pattern to match the ID of the node. Default: `"%d%d%d%d%d%d%d%d"`.
---@return table<NodeID, BaseNode> found_nodes The found nodes.
function plugin_func.find_heading_nodes(graph, location, force_add, id_regex)
	local valid_locations = { latest = true, nearest = true, telescope = true, buffer = true }
	if type(location) ~= "userdata" and not valid_locations[location] then
		graph.logger:error(
			"[Func]",
			string.format(
				"Invalid location `%s`. Must be TSNode, `latest`, `nearest`, `telescope` or `buffer`",
				location
			)
		)
		return {}
	end
	id_regex = id_regex or "%d%d%d%d%d%d%d%d"
	force_add = force_add and (id_regex == "%d%d%d%d%d%d%d%d")

	-- Helper function to process a single node
	local function process_node(ts_node)
		local title_ts_node, _, _ = ts_utils.parse_heading_node(ts_node)
		if not title_ts_node then
			graph.logger:debug("[Func]", "Cannot find the title treesitter node. Skipping.")
			return nil
		end

		local title_text = vim.treesitter.get_node_text(title_ts_node, 0)
		local id = tonumber(string.match(title_text, id_regex))

		if not id then
			if not force_add then
				graph.logger:debug("[Func]", "Cannot find the node ID. Skipping.")
				return nil
			end

			id = #graph.nodes + 1
			local file_name, _, rel_file_path = utils.get_file_info()
			local ok, node = graph:add_node("HeadingNode", id, file_name, rel_file_path, {}, { ts_node = ts_node })
			if not ok or not node then
				graph.logger:error("[Func]", "Cannot force add a new node. Skipping.")
				return nil
			end

			return node
		end

		local node = graph.nodes[id]
		return (node and node._state == "active") and node or nil
	end

	-- Handle different location types
	if type(location) == "userdata" then
		local node = process_node(location)
		return node and { [node._id] = node } or {}
	elseif location == "latest" then
		local latest_node = graph.nodes[#graph.nodes]
		return (latest_node and latest_node._state == "active") and { [latest_node._id] = latest_node } or {}
	elseif location == "nearest" then
		local nearest_ts_node = nts_utils.get_node_at_cursor()
		while nearest_ts_node and not nearest_ts_node:type():match("^heading%d$") do
			nearest_ts_node = nearest_ts_node:parent()
		end
		if not nearest_ts_node then
			graph.logger:error("[Func]", "Cannot find the nearest heading treesitter node.")
			return {}
		end
		local node = process_node(nearest_ts_node)
		return node and { [node._id] = node } or {}
	elseif location == "telescope" then
		-- TODO: Implement telescope functionality
		graph.logger:warn("[Func]", "Telescope functionality not yet implemented.")
		return {}
	elseif location == "buffer" then
		local found_nodes = {}
		for id, ts_node in pairs(ts_utils.get_heading_nodes()) do
			local node = process_node(ts_node)
			if node then
				found_nodes[id] = node
			end
		end

		return found_nodes
	end

	return {}
end

--------------------

return plugin_func
