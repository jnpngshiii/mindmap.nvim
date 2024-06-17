local nts_utils = require("nvim-treesitter.ts_utils")
local actions = require("telescope.actions")
local finders = require("telescope.finders")
local pickers = require("telescope.pickers")
local sorters = require("telescope.sorters")

local Graph = require("mindmap.graph.init")
local plugin_data = require("mindmap.plugin_data")
local utils = require("mindmap.utils")
local ts_utils = require("mindmap.ts_utils")

--------------------
-- Local functions
--------------------

---Find the registered namespace and return it.
---If the namespace does not exist, register it first.
---@param namespace string Namespace to find.
---@return integer namespace Found or created namespace.
local function find_namespace(namespace)
	if not plugin_data.cache.namespaces[namespace] then
		plugin_data.cache.namespaces[namespace] = vim.api.nvim_create_namespace("mindmap_" .. namespace)
	end

	return plugin_data.cache.namespaces[namespace]
end

---Find the registered graph using `save_path` and return it.
---If the graph does not exist, create it first.
---@param save_path? string Save path of the graph to find.
---@return Graph graph Found or created graph.
local function find_graph(save_path)
	save_path = save_path or utils.get_file_info()[4]
	if not plugin_data.cache.graphs[save_path] then
		local created_graph = Graph:new(
			save_path,
			--
			plugin_data.config.log_level,
			plugin_data.config.show_log_in_nvim,
			--
			plugin_data.config.default_node_type,
			plugin_data.config.node_prototype_cls,
			plugin_data.config.node_sub_cls_info,
			plugin_data.config.default_node_ins_method,
			plugin_data.config.default_node_cls_method,
			--
			plugin_data.config.default_edge_type,
			plugin_data.config.edge_prototype_cls,
			plugin_data.config.edge_sub_cls_info,
			plugin_data.config.default_edge_ins_method,
			plugin_data.config.default_edge_cls_method,
			--
			plugin_data.config.alg_type,
			plugin_data.config.alg_prototype_cls,
			plugin_data.config.alg_sub_cls_info,
			plugin_data.config.default_alg_ins_method,
			plugin_data.config.default_alg_cls_method
		)
		plugin_data.cache.graphs[created_graph.save_path] = created_graph
	end

	return plugin_data.cache.graphs[save_path]
end

---Find nodes and its corresponding tree-sitter nodes in the given location.
---@param location string|TSNode Location to find nodes. Location must be TSNode, "lastest", "nearest", "telescope" or "buffer".
---@return table<NodeID, PrototypeNode> nodes, table<NodeID, TSNode> ts_nodes Found nodes and its corresponding tree-sitter nodes.
local function find_heading_nodes(graph, location)
	if
		type(location) ~= "userdata"
		and location ~= "lastest"
		and location ~= "nearest"
		and location ~= "telescope"
		and location ~= "buffer"
	then
		vim.notify(
			"[find_heading_nodes] Invalid location `"
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
-- User functions
--------------------

local user_func = {}

----------
-- MindmapAdd
----------

---@deprecated
-- TODO: Merge into `MindmapAdd`
function user_func.MindmapAddNearestHeadingAsHeadingNode()
	-- Get graph --

	local found_graph = find_graph()

	-- Get tree-sitter node --

	local nearest_heading_ts_node = nts_utils.get_node_at_cursor()
	while nearest_heading_ts_node and not nearest_heading_ts_node:type():match("^heading%d$") do
		nearest_heading_ts_node = nearest_heading_ts_node:parent()
	end
	if not nearest_heading_ts_node then
		return
	end

	-- Pre action --

	-- Avoid adding the same heading node
	local title_node, _, _ = ts_utils.parse_heading_node(nearest_heading_ts_node)
	local id = tonumber(string.match(vim.treesitter.get_node_text(title_node, 0), "%d%d%d%d%d%d%d%d"))
	if id then
		return
	end

	-- Add node --

	local file_name, _, rel_file_path, _ = unpack(utils.get_file_info())
	local created_heading_node =
		found_graph.node_sub_cls["HeadingNode"]:new(#found_graph.nodes + 1, file_name, rel_file_path)
	created_heading_node.cache.ts_node = nearest_heading_ts_node
	created_heading_node.cache.ts_node_bufnr = vim.api.nvim_get_current_buf()

	found_graph:add_node(created_heading_node)

	-- Post action --
	-- This action is manage by `node:after_add_into_graph(self)`,
	-- which is auto called by `graph:add_node(node)`.
end

vim.api.nvim_create_user_command("MindmapAddNearestHeadingAsHeadingNode", function()
	user_func.MindmapAddNearestHeadingAsHeadingNode()
end, {
	nargs = 0,
})

if plugin_data.config.enable_default_keymap then
	vim.api.nvim_set_keymap(
		"n",
		plugin_data.config.keymap_prefix .. "An",
		"<cmd>MindmapAddNearestHeadingAsHeadingNode<cr>",
		{ noremap = true, silent = true, desc = "Add nearest heading as heading node" }
	)
end

---@deprecated
-- TODO: Merge into `MindmapAdd`
function user_func.MindmapAddVisualSelectionAsExcerptNode()
	local found_graph = find_graph()
	local created_excerpt_node =
		found_graph.node_sub_cls["ExcerptNode"]:create_using_latest_visual_selection(#found_graph.nodes + 1)

	found_graph:add_node(created_excerpt_node)
end

vim.api.nvim_create_user_command("MindmapAddVisualSelectionAsExcerptNode", function()
	vim.api.nvim_input("<Esc>")
	user_func.MindmapAddVisualSelectionAsExcerptNode()
end, {
	nargs = 0,
})

if plugin_data.config.enable_default_keymap then
	vim.api.nvim_set_keymap(
		"n",
		plugin_data.config.keymap_prefix .. "Ae",
		"<cmd>MindmapAddVisualSelectionAsExcerptNode<cr>",
		{ noremap = true, silent = true, desc = "Add visual selection as excerpt node" }
	)
	vim.api.nvim_set_keymap(
		"v",
		"E",
		"<cmd>MindmapAddVisualSelectionAsExcerptNode<cr>",
		{ noremap = true, silent = true, desc = "Add visual selection as excerpt node" }
	)
end

---@param from_node_location string
---@param edge_type string
---@param to_node_location? string
function user_func.MindmapAddEdge(from_node_location, edge_type, to_node_location)
	local found_graph = find_graph()
	if not found_graph.edge_sub_cls[edge_type] then
		vim.notify("[MindmapAdd] Invalid `edge_type`. Type must register in graph first.", vim.log.levels.ERROR)
		return
	end

	local from_nodes, _ = find_heading_nodes(found_graph, from_node_location)
	local to_nodes
	if to_node_location then
		to_nodes, _ = find_heading_nodes(found_graph, to_node_location)
	else
		to_nodes = from_nodes
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
	user_func.MindmapAddEdge(arg.fargs[1], arg.fargs[2], arg.fargs[3])
end, {
	nargs = "*",
	---@diagnostic disable-next-line: unused-local
	complete = function(arg_lead, cmd_line, cursor_pos)
		if cursor_pos == 15 then
			-- FIXME: nil
			local tbl = {}
			for _, edge_cls_type in pairs(plugin_data.config.edge_sub_cls_info) do
				table.insert(tbl, edge_cls_type)
			end
			return tbl
		else
			return { "lastest", "nearest", "-telescope", "buffer" }
		end
	end,
})

if plugin_data.config.enable_default_keymap then
	vim.api.nvim_set_keymap(
		"n",
		plugin_data.config.keymap_prefix .. "aln",
		"<cmd>MindmapAddEdge lastest SimpleEdge nearest<cr>",
		{ noremap = true, silent = true, desc = "Add SimpleEdge from lastest node to nearest node" }
	)
	vim.api.nvim_set_keymap(
		"n",
		plugin_data.config.keymap_prefix .. "ann",
		"<cmd>MindmapAddEdge nearest SelfLoopSubheadingEdge nearest<cr>",
		{ noremap = true, silent = true, desc = "Add SelfLoopSubheadingEdge from nearest node to nearest node" }
	)
	vim.api.nvim_set_keymap(
		"n",
		plugin_data.config.keymap_prefix .. "anN",
		"<cmd>MindmapAddEdge nearest SelfLoopContentEdge nearest<cr>",
		{ noremap = true, silent = true, desc = "Add SelfLoopContentEdge from nearest node to nearest node" }
	)
end

----------
-- MindmapRemove
----------

function user_func.MindmapRemove(location, node_or_edge_type)
	node_or_edge_type = node_or_edge_type or ""

	local found_graph = find_graph()
	local nodes, _ = find_heading_nodes(found_graph, location)

	if node_or_edge_type == "node" or found_graph.node_sub_cls[node_or_edge_type] then
		for id, node in pairs(nodes) do
			if node_or_edge_type == "node" or node.type == node_or_edge_type then
				found_graph:remove_node(id)
			end
		end
	end

	if node_or_edge_type == "edge" or found_graph.edge_sub_cls[node_or_edge_type] then
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
	end

	vim.notify(
		"[MindmapRemove] Invalid type `" .. node_or_edge_type .. "`. Type must register in graph first.",
		vim.log.levels.WARN
	)
end

vim.api.nvim_create_user_command("MindmapRemove", function(arg)
	user_func.MindmapRemove(arg.fargs[1], arg.fargs[2])
end, {
	nargs = "*",
	---@diagnostic disable-next-line: unused-local
	complete = function(arg_lead, cmd_line, cursor_pos)
		if cursor_pos == 14 then
			return { "lastest", "nearest", "-telescope", "buffer" }
		else
			return { "node", "edge" }
		end
	end,
})

if plugin_data.config.enable_default_keymap then
	vim.api.nvim_set_keymap(
		"n",
		plugin_data.config.keymap_prefix .. "rn",
		"<cmd>MindmapRemove nearest node<cr>",
		{ noremap = true, silent = true, desc = "Remove nearest node" }
	)
	vim.api.nvim_set_keymap(
		"n",
		plugin_data.config.keymap_prefix .. "rN",
		"<cmd>MindmapRemove buffer node<cr>",
		{ noremap = true, silent = true, desc = "Remove buffer node" }
	)
	vim.api.nvim_set_keymap(
		"n",
		plugin_data.config.keymap_prefix .. "re",
		"<cmd>MindmapRemove nearest edge<cr>",
		{ noremap = true, silent = true, desc = "Remove nearest edge" }
	)
	vim.api.nvim_set_keymap(
		"n",
		plugin_data.config.keymap_prefix .. "rE",
		"<cmd>MindmapRemove buffer edge<cr>",
		{ noremap = true, silent = true, desc = "Remove buffer edge" }
	)
end

----------
-- MindmapSp
----------

function user_func.MindmapSp(location)
	local found_graph = find_graph()
	local heading_nodes, _ = find_heading_nodes(found_graph, location)

	vim.notify("Reviewing `" .. location .. "` start.")

	for _, node in pairs(heading_nodes) do
		for _, edge_id in ipairs(node.incoming_edge_ids) do
			if found_graph.edges[edge_id].due_at < tonumber(os.time()) then
				found_graph:show_card(edge_id)
			end
		end
		-- TODO: review outgoing edge here?
		for _, edge_id in ipairs(node.outcoming_edge_ids) do
			if found_graph.edges[edge_id].due_at < tonumber(os.time()) then
				found_graph:show_card(edge_id)
			end
		end
	end

	vim.notify("Reviewing `" .. location .. "` end.")
end

vim.api.nvim_create_user_command("MindmapSp", function(arg)
	user_func.MindmapSp(arg.fargs[1])
end, {
	nargs = "*",
	---@diagnostic disable-next-line: unused-local
	complete = function(arg_lead, cmd_line, cursor_pos)
		return { "lastest", "nearest", "-telescope", "buffer", "-graph" }
	end,
})

if plugin_data.config.enable_default_keymap then
	vim.api.nvim_set_keymap(
		"n",
		plugin_data.config.keymap_prefix .. "sl",
		"<cmd>MindmapSp lastest<cr>",
		{ noremap = true, silent = true, desc = "Review lastest edge" }
	)
	vim.api.nvim_set_keymap(
		"n",
		plugin_data.config.keymap_prefix .. "sn",
		"<cmd>MindmapSp nearest<cr>",
		{ noremap = true, silent = true, desc = "Review nearest edge" }
	)
	vim.api.nvim_set_keymap(
		"n",
		plugin_data.config.keymap_prefix .. "st",
		"<cmd>MindmapSp telescope<cr>",
		{ noremap = true, silent = true, desc = "Review telescope edge" }
	)
	vim.api.nvim_set_keymap(
		"n",
		plugin_data.config.keymap_prefix .. "sb",
		"<cmd>MindmapSp buffer<cr>",
		{ noremap = true, silent = true, desc = "Review buffer edge" }
	)
	vim.api.nvim_set_keymap(
		"n",
		plugin_data.config.keymap_prefix .. "sg",
		"<cmd>MindmapSp graph<cr>",
		{ noremap = true, silent = true, desc = "Review graph edge" }
	)
end

----------
-- MindmapDisplay
----------

function user_func.MindmapDisplay(location, show_type)
	if show_type ~= "card_back" and show_type ~= "excerpt" and show_type ~= "sp_info" then
		vim.notify(
			"[MindmapDisplay] Invalid `type`. Type must be `card_back`, `excerpt` or `sp_info`.",
			vim.log.levels.ERROR
		)
		return
	end

	local found_graph = find_graph()
	local _, ts_nodes = find_heading_nodes(found_graph, location)

	for id, ts_node in pairs(ts_nodes) do
		-- Avoid duplicate virtual text
		user_func.MindmapClean(ts_node, show_type)

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

vim.api.nvim_create_user_command("MindmapDisplay", function(arg)
	user_func.MindmapDisplay(arg.fargs[1], arg.fargs[2])
end, {
	nargs = "*",
	---@diagnostic disable-next-line: unused-local
	complete = function(arg_lead, cmd_line, cursor_pos)
		if cursor_pos == 12 then
			return { "lastest", "nearest", "-telescope", "buffer" }
		else
			return { "card_back", "excerpt", "sp_info" }
		end
	end,
})

if plugin_data.config.enable_default_keymap then
	vim.api.nvim_set_keymap(
		"n",
		plugin_data.config.keymap_prefix .. "dc",
		"<cmd>MindmapDisplay nearest card_back<cr>",
		{ noremap = true, silent = true, desc = "Display nearest card back" }
	)
	vim.api.nvim_set_keymap(
		"n",
		plugin_data.config.keymap_prefix .. "dC",
		"<cmd>MindmapDisplay buffer card_back<cr>",
		{ noremap = true, silent = true, desc = "Display buffer card back" }
	)
	vim.api.nvim_set_keymap(
		"n",
		plugin_data.config.keymap_prefix .. "de",
		"<cmd>MindmapDisplay nearest excerpt<cr>",
		{ noremap = true, silent = true, desc = "Display nearest excerpt" }
	)
	vim.api.nvim_set_keymap(
		"n",
		plugin_data.config.keymap_prefix .. "dE",
		"<cmd>MindmapDisplay buffer excerpt<cr>",
		{ noremap = true, silent = true, desc = "Display buffer excerpt" }
	)
	vim.api.nvim_set_keymap(
		"n",
		plugin_data.config.keymap_prefix .. "ds",
		"<cmd>MindmapDisplay nearest sp_info<cr>",
		{ noremap = true, silent = true, desc = "Display nearest sp info" }
	)
	vim.api.nvim_set_keymap(
		"n",
		plugin_data.config.keymap_prefix .. "dS",
		"<cmd>MindmapDisplay buffer sp_info<cr>",
		{ noremap = true, silent = true, desc = "Display buffer sp info" }
	)
end

----------
-- MindmapClean
----------

function user_func.MindmapClean(location, clean_type)
	if clean_type ~= "card_back" and clean_type ~= "excerpt" and clean_type ~= "sp_info" then
		vim.notify(
			"[MindmapClean] Invalid `type`. Type must be `card_back`, `excerpt` or `sp_info`.",
			vim.log.levels.ERROR
		)
		return
	end

	local _, ts_nodes = find_heading_nodes(find_graph(), location)

	for _, ts_node in pairs(ts_nodes) do
		local start_row, _, _, _ = ts_node:range()
		utils.clear_virtual_text(0, find_namespace(clean_type), start_row, start_row + 1)
	end
end

vim.api.nvim_create_user_command("MindmapClean", function(arg)
	user_func.MindmapClean(arg.fargs[1], arg.fargs[2])
end, {
	nargs = "*",
	---@diagnostic disable-next-line: unused-local
	complete = function(arg_lead, cmd_line, cursor_pos)
		if cursor_pos == 13 then
			return { "lastest", "nearest", "-telescope", "buffer" }
		else
			return { "card_back", "excerpt", "sp_info" }
		end
	end,
})

if plugin_data.config.enable_default_keymap then
	vim.api.nvim_set_keymap(
		"n",
		plugin_data.config.keymap_prefix .. "cc",
		"<cmd>MindmapClean nearest card_back<cr>",
		{ noremap = true, silent = true, desc = "Clean nearest card back" }
	)
	vim.api.nvim_set_keymap(
		"n",
		plugin_data.config.keymap_prefix .. "cC",
		"<cmd>MindmapClean buffer card_back<cr>",
		{ noremap = true, silent = true, desc = "Clean buffer card back" }
	)
	vim.api.nvim_set_keymap(
		"n",
		plugin_data.config.keymap_prefix .. "ce",
		"<cmd>MindmapClean nearest excerpt<cr>",
		{ noremap = true, silent = true, desc = "Clean nearest excerpt" }
	)
	vim.api.nvim_set_keymap(
		"n",
		plugin_data.config.keymap_prefix .. "cE",
		"<cmd>MindmapClean buffer excerpt<cr>",
		{ noremap = true, silent = true, desc = "Clean buffer excerpt" }
	)
	vim.api.nvim_set_keymap(
		"n",
		plugin_data.config.keymap_prefix .. "cs",
		"<cmd>MindmapClean nearest sp_info<cr>",
		{ noremap = true, silent = true, desc = "Clean nearest sp info" }
	)
	vim.api.nvim_set_keymap(
		"n",
		plugin_data.config.keymap_prefix .. "cS",
		"<cmd>MindmapClean buffer sp_info<cr>",
		{ noremap = true, silent = true, desc = "Clean buffer sp info" }
	)
end

----------
-- MindmapSave
----------

function user_func.MindmapSave(save_type)
	if save_type ~= "buffer" and save_type ~= "all" then
		vim.notify("[MindmapSave] Invalid `type`. Type must be `buffer` or `all`.", vim.log.levels.ERROR)
		return
	end

	if save_type == "all" then
		for _, graph in pairs(plugin_data.cache.graphs) do
			graph:save()
		end
	end

	if save_type == "buffer" then
		local found_graph = find_graph()
		found_graph:save()
	end
end

vim.api.nvim_create_user_command("MindmapSave", function(arg)
	user_func.MindmapSave(arg.fargs[1])
end, {
	nargs = "*",
	---@diagnostic disable-next-line: unused-local
	complete = function(arg_lead, cmd_line, cursor_pos)
		return { "buffer", "all" }
	end,
})

if plugin_data.config.enable_default_autocmd then
	vim.api.nvim_create_autocmd("VimLeave", {
		callback = function()
			user_func.MindmapSave("all")
		end,
	})
end

----------
-- MindmapTest
----------

if true then
	function user_func.MindmapTest()
		local graph = find_graph()
		find_heading_nodes(graph, "telescope")
	end

	vim.api.nvim_create_user_command("MindmapTest", function()
		user_func.MindmapTest()
	end, {
		nargs = "*",
		complete = function() end,
	})
end

--------------------

return user_func
