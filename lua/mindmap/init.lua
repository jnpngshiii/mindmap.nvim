local nts_utils = require("nvim-treesitter.ts_utils")

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
---@field keymap_prefix string Prefix of the keymap. Default: "<localleader>m".
---@field enable_default_keymap boolean Enable default keymap. Default: true.
---@field enable_default_autocmd boolean Enable default atuocmd. Default: true.
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
	keymap_prefix = "<localleader>m",
	enable_default_keymap = true,
	enable_default_autocmd = true,
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

---Find nodes and its corresponding tree-sitter nodes in the given location.
---@param location string|TSNode Location to find nodes. Location must be `nearest`, `telescope` or `buffer`.
---@return table<NodeID, PrototypeNode> nodes, table<NodeID, TSNode> ts_nodes Found nodes and its corresponding tree-sitter nodes.
local function find_heading_nodes(graph, location)
	if location ~= "nearest" and location ~= "telescope" and location ~= "buffer" then
		vim.notify(
			"[find_nodes] Invalid location `" .. location .. "`. Location must be `nearest`, `telescope` or `buffer`.",
			vim.log.levels.ERROR
		)
	end

	local found_ts_nodes
	if location == "nearest" then
		local current_node = nts_utils.get_node_at_cursor()
		while current_node and not current_node:type():match("^heading%d$") do
			current_node = current_node:parent()
		end

		if current_node then
			local title_node, _, _ = M.parse_heading_node(current_node)
			local title_node_text = vim.treesitter.get_node_text(title_node, 0)
			found_ts_nodes = { tonumber(string.match(title_node_text, "%d%d%d%d%d%d%d%d")), current_node }
		else
			-- TODO: auto add
			found_ts_nodes = {}
		end
	elseif location == "telescope" then
		-- TODO: implement this
		vim.notify("[find_nodes] Location `telescope` is not implemented yet.", vim.log.levels.ERROR)
	elseif location == "buffer" then
		found_ts_nodes = ts_utils.get_heading_node()
	end

	local found_nodes = {}
	for id, _ in pairs(found_ts_nodes) do
		if graph.nodes[id].state == "active" then
			found_nodes[id] = graph.nodes[id]
		end
	end

	return found_nodes, found_ts_nodes
end

function M.setup(user_config)
	user_config = user_config or {}

	plugin_config = vim.tbl_extend("force", plugin_config, user_config)
end

--------------------
-- User functions
--------------------

----------
-- MindmapAdd
----------

-- TODO: Merge into `MindmapAdd`
function M.MindmapAddVisualSelectionAsExcerptNode()
	local found_graph = find_graph()
	local created_excerpt_node =
		found_graph.node_sub_cls["ExcerptNode"]:create_using_latest_visual_selection(#found_graph.nodes + 1)

	found_graph:add_node(created_excerpt_node)
end

vim.api.nvim_create_user_command("MindmapAddVisualSelectionAsExcerptNode", function()
	M.MindmapAddVisualSelectionAsExcerptNode()
end, {
	nargs = 0,
})

if plugin_config.enable_default_keymap then
	vim.api.nvim_set_keymap(
		"v",
		"E",
		"<cmd>MindmapAddVisualSelectionAsExcerptNode<cr>",
		{ noremap = true, silent = true, desc = "Add visual selection as excerpt node" }
	)
end

---@param edge_type string
---@param from_node_type string
---@param to_node_type? string
function M.MindmapAddEdge(edge_type, from_node_type, to_node_type)
	local found_graph = find_graph()
	if not found_graph.edge_sub_cls[edge_type] then
		vim.notify("[MindmapAdd] Invalid `edge_type`. Type must register in graph first.", vim.log.levels.ERROR)
	end
	if
		from_node_type ~= "lastest"
		and from_node_type ~= "nearest"
		and from_node_type ~= "telescope"
		and from_node_type ~= "buffer"
	then
		vim.notify(
			"[MindmapAdd] Invalid `from_node_type`. Type must be `lastest`, `nearest`, `telescope` or `buffer`.",
			vim.log.levels.ERROR
		)
		return
	end
	if
		to_node_type
		and to_node_type ~= "lastest"
		and to_node_type ~= "nearest"
		and to_node_type ~= "telescope"
		and to_node_type ~= "buffer"
	then
		vim.notify(
			"[MindmapAdd] Invalid `to_node_type`. Type must be nil, `lastest`, `nearest`, `telescope` or `buffer`.",
			vim.log.levels.ERROR
		)
		return
	end

	local from_nodes
	if from_node_type == "lastest" then
		from_nodes = { #found_graph.nodes, found_graph.nodes[#found_graph.nodes] }
	else
		from_nodes, _ = find_heading_nodes(found_graph, from_node_type)
	end

	local to_nodes
	if to_node_type == "lastest" then
		to_nodes = { #found_graph.nodes, found_graph.nodes[#found_graph.nodes] }
	else
		to_nodes, _ = find_heading_nodes(found_graph, to_node_type)
	end

	for _, from_node in pairs(from_nodes) do
		for _, to_node in pairs(to_nodes) do
			local created_edge =
				found_graph.edge_sub_cls[edge_type]:new(#found_graph.edges + 1, from_node.id, to_node.id)
			found_graph:add_edge(created_edge)
		end
	end
end

vim.api.nvim_create_user_command("MindmapAddEdge", function(arg)
	M.MindmapAddEdge(arg.fargs[1], arg.fargs[2], arg.fargs[3])
end, {
	nargs = "*",
	---@diagnostic disable-next-line: unused-local
	complete = function(arg_lead, cmd_line, cursor_pos)
		if cursor_pos == 15 then
			return { "lastest", "nearest", "telescope", "buffer" }
		else
			local tbl = {}
			for _, edge_cls_type in plugin_config.edge_sub_cls_info do
				table.insert(tbl, edge_cls_type)
			end
		end
	end,
})

if plugin_config.enable_default_keymap then
	vim.api.nvim_set_keymap(
		"n",
		plugin_config.keymap_prefix .. "aln",
		"<cmd>MindmapAdd SimpleEdge lastest nearest<cr>",
		{ noremap = true, silent = true, desc = "Add SimpleEdge from lastest node to nearest node" }
	)
	vim.api.nvim_set_keymap(
		"n",
		plugin_config.keymap_prefix .. "ann",
		"<cmd>MindmapAdd SelfLoopSubheadingEdge nearest nearest<cr>",
		{ noremap = true, silent = true, desc = "Add SelfLoopSubheadingEdge from nearest node to nearest node" }
	)
	vim.api.nvim_set_keymap(
		"n",
		plugin_config.keymap_prefix .. "anN",
		"<cmd>MindmapAdd SelfLoopContentEdge nearest nearest<cr>",
		{ noremap = true, silent = true, desc = "Add SelfLoopContentEdge from nearest node to nearest node" }
	)
end

----------
-- MindmapRemove
----------

function M.MindmapRemove(location, node_or_edge_type)
	node_or_edge_type = node_or_edge_type or ""

	local found_graph = find_graph()
	local nodes, ts_nodes = find_nodes(location)

	if node_or_edge_type == "node" or found_graph.node_sub_cls[node_or_edge_type] then
		for id, ts_node in pairs(ts_nodes) do
			local node = nodes[id]

			if node_or_edge_type == "node" or node.type == node_or_edge_type then
				-- First, remove the node from the graph
				found_graph:remove_node(id)

				-- Second, remove the node id from the text
				local ts_node_title, _, _ = ts_utils.get_sub_nodes(ts_node)
				local node_text = vim.treesitter.get_node_text(ts_node_title, 0)
				ts_utils.replace_node_text(
					string.gsub(node_text, " %%" .. string.format("%08d", id) .. "%%", ""),
					ts_node_title,
					0
				)
			end
		end
	elseif node_or_edge_type == "edge" or found_graph.edge_sub_cls[node_or_edge_type] then
		for _, node in pairs(nodes) do
			for _, edge_id in ipairs(node.incoming_edge_ids) do
				local edge = found_graph.edges[edge_id]
				if node_or_edge_type == "edge" or edge.type == node_or_edge_type then
					found_graph:remove_edge(edge_id)
				end
			end
			-- TODO: Don not handle outgoing edge here.
			for _, edge_id in ipairs(node.outcoming_edge_ids) do
				local edge = found_graph.edges[edge_id]
				if node_or_edge_type == "edge" or edge.type == node_or_edge_type then
					found_graph:remove_edge(edge_id)
				end
			end
		end
	else
		vim.notify(
			"[MindmapRemove] Invalid type `" .. node_or_edge_type .. "`. Type must register in graph first.",
			vim.log.levels.WARN
		)
		return
	end
end

vim.api.nvim_create_user_command("MindmapRemove", function(arg)
	M.MindmapRemove(arg.fargs[1], arg.fargs[2])
end, {
	nargs = "*",
	---@diagnostic disable-next-line: unused-local
	complete = function(arg_lead, cmd_line, cursor_pos)
		if cursor_pos == 14 then
			return { "nearest", "buffer", "*graph", "*telescope" }
		else
			return { "node", "edge" }
		end
	end,
})

if plugin_config.enable_default_keymap then
	vim.api.nvim_set_keymap(
		"n",
		plugin_config.keymap_prefix .. "rn",
		"<cmd>MindmapRemove nearest node<cr>",
		{ noremap = true, silent = true, desc = "Remove nearest node" }
	)
	vim.api.nvim_set_keymap(
		"n",
		plugin_config.keymap_prefix .. "rN",
		"<cmd>MindmapRemove buffer node<cr>",
		{ noremap = true, silent = true, desc = "Remove buffer node" }
	)
	vim.api.nvim_set_keymap(
		"n",
		plugin_config.keymap_prefix .. "re",
		"<cmd>MindmapRemove nearest edge<cr>",
		{ noremap = true, silent = true, desc = "Remove nearest edge" }
	)
	vim.api.nvim_set_keymap(
		"n",
		plugin_config.keymap_prefix .. "rE",
		"<cmd>MindmapRemove buffer edge<cr>",
		{ noremap = true, silent = true, desc = "Remove buffer edge" }
	)
end

----------
-- MindmapShow
----------

function M.MindmapShow(location, show_type)
	if show_type ~= "card_back" and show_type ~= "excerpt" and show_type ~= "sp_info" then
		vim.notify(
			"[MindmapShow] Invalid `type`. Type must be `card_back`, `excerpt` or `sp_info`.",
			vim.log.levels.ERROR
		)
		return
	end

	local found_graph = find_graph()
	local _, ts_nodes = find_nodes(location)

	for id, ts_node in pairs(ts_nodes) do
		-- Avoid duplicate virtual text
		M.MindmapClean(ts_node, show_type)

		local line_num, _, _, _ = ts_node:range()
		line_num = line_num + 1

		for index, incoming_edge_id in ipairs(found_graph.nodes[id].incoming_edge_ids) do
			if show_type == "card_back" then
				local incoming_edge = found_graph.edges[incoming_edge_id]
				local from_node = found_graph.nodes[incoming_edge.from_node_id]
				local _, back = from_node:get_content(incoming_edge.type)

				local text = index .. ": " .. back[1]
				utils.add_virtual_text(0, find_namespace(show_type), line_num, text)
			end

			if show_type == "excerpt" then
				local incoming_edge = found_graph.edges[incoming_edge_id]
				local from_node = found_graph.nodes[incoming_edge.from_node_id]
				if from_node.type == "ExcerptNode" then
					local _, back = from_node:get_content(incoming_edge.type)

					local text = "│ " .. table.concat(back, " ")
					utils.add_virtual_text(0, find_namespace(show_type), line_num, text)
				end
			end

			if show_type == "sp_info" then
				local front, back, created_at, updated_at, due_at, ease, interval =
					found_graph:get_sp_info_from_edge(incoming_edge_id)

				local text = string.format("Due at: %d, Ease: %d, Int: %d", due_at, ease, interval)
				utils.add_virtual_text(0, find_namespace(show_type), line_num, text)
			end
		end
	end
end

vim.api.nvim_create_user_command("MindmapShow", function(arg)
	M.MindmapShow(arg.fargs[1], arg.fargs[2])
end, {
	nargs = "*",
	---@diagnostic disable-next-line: unused-local
	complete = function(arg_lead, cmd_line, cursor_pos)
		if cursor_pos == 12 then
			return { "nearest", "buffer", "*graph", "*telescope" }
		else
			return { "card_back", "excerpt", "sp_info" }
		end
	end,
})

if plugin_config.enable_default_keymap then
	vim.api.nvim_set_keymap(
		"n",
		plugin_config.keymap_prefix .. "sc",
		"<cmd>MindmapShow nearest card_back<cr>",
		{ noremap = true, silent = true, desc = "Show nearest card back" }
	)
	vim.api.nvim_set_keymap(
		"n",
		plugin_config.keymap_prefix .. "sC",
		"<cmd>MindmapShow buffer card_back<cr>",
		{ noremap = true, silent = true, desc = "Show buffer card back" }
	)
	vim.api.nvim_set_keymap(
		"n",
		plugin_config.keymap_prefix .. "se",
		"<cmd>MindmapShow nearest excerpt<cr>",
		{ noremap = true, silent = true, desc = "Show nearest excerpt" }
	)
	vim.api.nvim_set_keymap(
		"n",
		plugin_config.keymap_prefix .. "sE",
		"<cmd>MindmapShow buffer excerpt<cr>",
		{ noremap = true, silent = true, desc = "Show buffer excerpt" }
	)
	vim.api.nvim_set_keymap(
		"n",
		plugin_config.keymap_prefix .. "ss",
		"<cmd>MindmapShow nearest sp_info<cr>",
		{ noremap = true, silent = true, desc = "Show nearest sp info" }
	)
	vim.api.nvim_set_keymap(
		"n",
		plugin_config.keymap_prefix .. "sS",
		"<cmd>MindmapShow buffer sp_info<cr>",
		{ noremap = true, silent = true, desc = "Show buffer sp info" }
	)
end

----------
-- MindmapClean
----------

function M.MindmapClean(location, clean_type)
	if clean_type ~= "card_back" and clean_type ~= "excerpt" and clean_type ~= "sp_info" then
		vim.notify(
			"[MindmapClean] Invalid `type`. Type must be `card_back`, `excerpt` or `sp_info`.",
			vim.log.levels.ERROR
		)
		return
	end

	local _, ts_nodes = find_nodes(location)

	for _, ts_node in pairs(ts_nodes) do
		local start_row, _, _, _ = ts_node:range()
		utils.clear_virtual_text(0, find_namespace(clean_type), start_row, start_row + 1)
	end
end

vim.api.nvim_create_user_command("MindmapClean", function(arg)
	M.MindmapClean(arg.fargs[1], arg.fargs[2])
end, {
	nargs = "*",
	---@diagnostic disable-next-line: unused-local
	complete = function(arg_lead, cmd_line, cursor_pos)
		if cursor_pos == 13 then
			return { "nearest", "buffer", "*graph", "*telescope" }
		else
			return { "card_back", "excerpt", "sp_info" }
		end
	end,
})

if plugin_config.enable_default_keymap then
	vim.api.nvim_set_keymap(
		"n",
		plugin_config.keymap_prefix .. "cc",
		"<cmd>MindmapClean nearest card_back<cr>",
		{ noremap = true, silent = true, desc = "Clean nearest card back" }
	)
	vim.api.nvim_set_keymap(
		"n",
		plugin_config.keymap_prefix .. "cC",
		"<cmd>MindmapClean buffer card_back<cr>",
		{ noremap = true, silent = true, desc = "Clean buffer card back" }
	)
	vim.api.nvim_set_keymap(
		"n",
		plugin_config.keymap_prefix .. "ce",
		"<cmd>MindmapClean nearest excerpt<cr>",
		{ noremap = true, silent = true, desc = "Clean nearest excerpt" }
	)
	vim.api.nvim_set_keymap(
		"n",
		plugin_config.keymap_prefix .. "cE",
		"<cmd>MindmapClean buffer excerpt<cr>",
		{ noremap = true, silent = true, desc = "Clean buffer excerpt" }
	)
	vim.api.nvim_set_keymap(
		"n",
		plugin_config.keymap_prefix .. "cs",
		"<cmd>MindmapClean nearest sp_info<cr>",
		{ noremap = true, silent = true, desc = "Clean nearest sp info" }
	)
	vim.api.nvim_set_keymap(
		"n",
		plugin_config.keymap_prefix .. "cS",
		"<cmd>MindmapClean buffer sp_info<cr>",
		{ noremap = true, silent = true, desc = "Clean buffer sp info" }
	)
end

----------
-- MindmapSave
----------

function M.MindmapSave(save_type)
	if save_type ~= "buffer" and save_type ~= "all" then
		vim.notify("[MindmapSave] Invalid `type`. Type must be `buffer` or `all`.", vim.log.levels.ERROR)
		return
	end

	if save_type == "all" then
		for _, graph in pairs(plugin_database.graphs) do
			graph:save()
		end
	end

	if save_type == "buffer" then
		local found_graph = find_graph()
		found_graph:save()
	end
end

vim.api.nvim_create_user_command("MindmapSave", function(arg)
	M.MindmapSave(arg.fargs[1])
end, {
	nargs = "*",
	---@diagnostic disable-next-line: unused-local
	complete = function(arg_lead, cmd_line, cursor_pos)
		return { "buffer", "all" }
	end,
})

if plugin_config.enable_default_autocmd then
	vim.api.nvim_create_autocmd("VimLeave", {
		callback = function()
			M.MindmapSave("all")
		end,
	})
end

----------
-- MindmapTest
----------

function M.MindmapTest()
	local graph = find_graph()

	graph:save()
end

vim.api.nvim_create_user_command("MindmapTest", function()
	M.MindmapTest()
end, {
	nargs = "*",
	complete = function() end,
})

--------------------

return M
