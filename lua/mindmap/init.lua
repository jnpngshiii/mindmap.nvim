local nts_utils = require("nvim-treesitter.ts_utils")

local plugin = require("mindmap.plugin")
local utils = require("mindmap.utils")
local ts_utils = require("mindmap.ts_utils")

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

	local found_graph = plugin.find_graph()

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

---@deprecated
-- TODO: Merge into `MindmapAdd`
function user_func.MindmapAddVisualSelectionAsExcerptNode()
	local found_graph = plugin.find_graph()
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

---@param from_node_location string
---@param edge_type string
---@param to_node_location? string
function user_func.MindmapAddEdge(from_node_location, edge_type, to_node_location)
	local found_graph = plugin.find_graph()
	if not found_graph.edge_sub_cls[edge_type] then
		vim.notify("[MindmapAdd] Invalid `edge_type`. Type must register in graph first.", vim.log.levels.ERROR)
		return
	end

	local from_nodes, _ = plugin.find_heading_nodes(found_graph, from_node_location)
	local to_nodes
	if to_node_location then
		to_nodes, _ = plugin.find_heading_nodes(found_graph, to_node_location)
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
			for _, edge_cls_type in pairs(plugin.config.edge_sub_cls_info) do
				table.insert(tbl, edge_cls_type)
			end
			return tbl
		else
			return { "lastest", "nearest", "-telescope", "buffer" }
		end
	end,
})

----------
-- MindmapRemove
----------

function user_func.MindmapRemove(location, node_or_edge_type)
	node_or_edge_type = node_or_edge_type or ""

	local found_graph = plugin.find_graph()
	local nodes, _ = plugin.find_heading_nodes(found_graph, location)

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

----------
-- MindmapSp
----------

function user_func.MindmapSp(location)
	local found_graph = plugin.find_graph()
	local heading_nodes, _ = plugin.find_heading_nodes(found_graph, location)

	vim.notify("Reviewing `" .. location .. "` start.")

	for _, node in pairs(heading_nodes) do
		for _, edge_id in ipairs(node.incoming_edge_ids) do
			if found_graph.edges[edge_id].due_at < tonumber(os.time()) then
				local status = found_graph:show_card(edge_id)
				if status == "quit" then
					break
				end
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

	local found_graph = plugin.find_graph()
	local _, ts_nodes = plugin.find_heading_nodes(found_graph, location)
	local screen_width = vim.api.nvim_win_get_width(0) - 20

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

				back[1] = string.format("* Card %s [%s]: %s", index, incoming_edge.type, back[1])
				back = utils.limit_string_length(back, screen_width)
				-- FIXME: wrong order
				for i = #back, 1, -1 do
					utils.add_virtual_text(0, plugin.find_namespace(show_type), line_num, back[i])
				end
			end

			if show_type == "excerpt" then
				local incoming_edge = found_graph.edges[incoming_edge_id]
				local from_node = found_graph.nodes[incoming_edge.from_node_id]
				if from_node.type == "ExcerptNode" then
					local _, back = from_node:get_content(incoming_edge.type)

					back[1] = string.format("%s: %s", index, back[1])
					back = utils.limit_string_length(back, screen_width)
					-- FIXME: wrong order
					for i = #back, 1, -1 do
						utils.add_virtual_text(0, plugin.find_namespace(show_type), line_num, "│ " .. back[i])
					end
				end
			end

			if show_type == "sp_info" then
				local front, back, created_at, updated_at, due_at, ease, interval, answer_count, ease_count, again_count =
					found_graph:get_sp_info_from_edge(incoming_edge_id)

				local text = string.format(
					"Due at: %s, Ease: %s, Interval: %s, Again: %s/%s",
					-- FIXME:
					os.date("%Y-%m-%d %H:%M:%S", due_at),
					ease,
					interval,
					again_count,
					answer_count
				)

				local text_type
				if due_at < tonumber(os.time()) then
					text_type = "Error"
				end

				utils.add_virtual_text(0, plugin.find_namespace(show_type), line_num, text, text_type)
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

	local _, ts_nodes = plugin.find_heading_nodes(plugin.find_graph(), location)

	for _, ts_node in pairs(ts_nodes) do
		local start_row, _, _, _ = ts_node:range()
		utils.clear_virtual_text(0, plugin.find_namespace(clean_type), start_row, start_row + 1)
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

----------
-- MindmapSave
----------

function user_func.MindmapSave(save_type)
	if save_type ~= "buffer" and save_type ~= "all" then
		vim.notify("[MindmapSave] Invalid `type`. Type must be `buffer` or `all`.", vim.log.levels.ERROR)
		return
	end

	if save_type == "all" then
		for _, graph in pairs(plugin.cache.graphs) do
			graph:save()
		end
	end

	if save_type == "buffer" then
		local found_graph = plugin.find_graph()
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

----------
-- MindmapTest
----------

if true then
	function user_func.MindmapTest()
		local graph = plugin.find_graph()
		plugin.find_heading_nodes(graph, "telescope")
	end

	vim.api.nvim_create_user_command("MindmapTest", function()
		user_func.MindmapTest()
	end, {
		nargs = "*",
		complete = function() end,
	})
end

--------------------

function user_func.setup(user_config)
	user_config = user_config or {}

	plugin.config = vim.tbl_extend("force", plugin.config, user_config)

	if plugin.config.enable_default_keymap then
		----------
		-- MindmapAdd
		----------

		vim.api.nvim_set_keymap(
			"n",
			plugin.config.keymap_prefix .. "An",
			"<cmd>MindmapAddNearestHeadingAsHeadingNode<cr>",
			{ noremap = true, silent = true, desc = "Add nearest heading as heading node" }
		)
		vim.api.nvim_set_keymap(
			"n",
			plugin.config.keymap_prefix .. "Ae",
			"<cmd>MindmapAddVisualSelectionAsExcerptNode<cr>",
			{ noremap = true, silent = true, desc = "Add visual selection as excerpt node" }
		)
		vim.api.nvim_set_keymap(
			"v",
			"E",
			"<cmd>MindmapAddVisualSelectionAsExcerptNode<cr>",
			{ noremap = true, silent = true, desc = "Add visual selection as excerpt node" }
		)
		vim.api.nvim_set_keymap(
			"n",
			plugin.config.keymap_prefix .. "aln",
			"<cmd>MindmapAddEdge lastest SimpleEdge nearest<cr>",
			{ noremap = true, silent = true, desc = "Add SimpleEdge from lastest node to nearest node" }
		)
		vim.api.nvim_set_keymap(
			"n",
			plugin.config.keymap_prefix .. "ann",
			"<cmd>MindmapAddEdge nearest SelfLoopSubheadingEdge nearest<cr>",
			{ noremap = true, silent = true, desc = "Add SelfLoopSubheadingEdge from nearest node to nearest node" }
		)
		vim.api.nvim_set_keymap(
			"n",
			plugin.config.keymap_prefix .. "anN",
			"<cmd>MindmapAddEdge nearest SelfLoopContentEdge nearest<cr>",
			{ noremap = true, silent = true, desc = "Add SelfLoopContentEdge from nearest node to nearest node" }
		)

		----------
		-- MindmapRemove
		----------

		vim.api.nvim_set_keymap(
			"n",
			plugin.config.keymap_prefix .. "rn",
			"<cmd>MindmapRemove nearest node<cr>",
			{ noremap = true, silent = true, desc = "Remove nearest node" }
		)
		vim.api.nvim_set_keymap(
			"n",
			plugin.config.keymap_prefix .. "rN",
			"<cmd>MindmapRemove buffer node<cr>",
			{ noremap = true, silent = true, desc = "Remove buffer node" }
		)
		vim.api.nvim_set_keymap(
			"n",
			plugin.config.keymap_prefix .. "re",
			"<cmd>MindmapRemove nearest edge<cr>",
			{ noremap = true, silent = true, desc = "Remove nearest edge" }
		)
		vim.api.nvim_set_keymap(
			"n",
			plugin.config.keymap_prefix .. "rE",
			"<cmd>MindmapRemove buffer edge<cr>",
			{ noremap = true, silent = true, desc = "Remove buffer edge" }
		)

		----------
		-- MindmapSp
		----------

		vim.api.nvim_set_keymap(
			"n",
			plugin.config.keymap_prefix .. "sl",
			"<cmd>MindmapSp lastest<cr>",
			{ noremap = true, silent = true, desc = "Review lastest edge" }
		)
		vim.api.nvim_set_keymap(
			"n",
			plugin.config.keymap_prefix .. "sn",
			"<cmd>MindmapSp nearest<cr>",
			{ noremap = true, silent = true, desc = "Review nearest edge" }
		)
		vim.api.nvim_set_keymap(
			"n",
			plugin.config.keymap_prefix .. "st",
			"<cmd>MindmapSp telescope<cr>",
			{ noremap = true, silent = true, desc = "Review telescope edge" }
		)
		vim.api.nvim_set_keymap(
			"n",
			plugin.config.keymap_prefix .. "sb",
			"<cmd>MindmapSp buffer<cr>",
			{ noremap = true, silent = true, desc = "Review buffer edge" }
		)
		vim.api.nvim_set_keymap(
			"n",
			plugin.config.keymap_prefix .. "sg",
			"<cmd>MindmapSp graph<cr>",
			{ noremap = true, silent = true, desc = "Review graph edge" }
		)

		----------
		-- MindmapDisplay
		----------

		vim.api.nvim_set_keymap(
			"n",
			plugin.config.keymap_prefix .. "dc",
			"<cmd>MindmapDisplay nearest card_back<cr>",
			{ noremap = true, silent = true, desc = "Display nearest card back" }
		)
		vim.api.nvim_set_keymap(
			"n",
			plugin.config.keymap_prefix .. "dC",
			"<cmd>MindmapDisplay buffer card_back<cr>",
			{ noremap = true, silent = true, desc = "Display buffer card back" }
		)
		vim.api.nvim_set_keymap(
			"n",
			plugin.config.keymap_prefix .. "de",
			"<cmd>MindmapDisplay nearest excerpt<cr>",
			{ noremap = true, silent = true, desc = "Display nearest excerpt" }
		)
		vim.api.nvim_set_keymap(
			"n",
			plugin.config.keymap_prefix .. "dE",
			"<cmd>MindmapDisplay buffer excerpt<cr>",
			{ noremap = true, silent = true, desc = "Display buffer excerpt" }
		)
		vim.api.nvim_set_keymap(
			"n",
			plugin.config.keymap_prefix .. "ds",
			"<cmd>MindmapDisplay nearest sp_info<cr>",
			{ noremap = true, silent = true, desc = "Display nearest sp info" }
		)
		vim.api.nvim_set_keymap(
			"n",
			plugin.config.keymap_prefix .. "dS",
			"<cmd>MindmapDisplay buffer sp_info<cr>",
			{ noremap = true, silent = true, desc = "Display buffer sp info" }
		)

		----------
		-- MindmapClean
		----------

		vim.api.nvim_set_keymap(
			"n",
			plugin.config.keymap_prefix .. "cc",
			"<cmd>MindmapClean nearest card_back<cr>",
			{ noremap = true, silent = true, desc = "Clean nearest card back" }
		)
		vim.api.nvim_set_keymap(
			"n",
			plugin.config.keymap_prefix .. "cC",
			"<cmd>MindmapClean buffer card_back<cr>",
			{ noremap = true, silent = true, desc = "Clean buffer card back" }
		)
		vim.api.nvim_set_keymap(
			"n",
			plugin.config.keymap_prefix .. "ce",
			"<cmd>MindmapClean nearest excerpt<cr>",
			{ noremap = true, silent = true, desc = "Clean nearest excerpt" }
		)
		vim.api.nvim_set_keymap(
			"n",
			plugin.config.keymap_prefix .. "cE",
			"<cmd>MindmapClean buffer excerpt<cr>",
			{ noremap = true, silent = true, desc = "Clean buffer excerpt" }
		)
		vim.api.nvim_set_keymap(
			"n",
			plugin.config.keymap_prefix .. "cs",
			"<cmd>MindmapClean nearest sp_info<cr>",
			{ noremap = true, silent = true, desc = "Clean nearest sp info" }
		)
		vim.api.nvim_set_keymap(
			"n",
			plugin.config.keymap_prefix .. "cS",
			"<cmd>MindmapClean buffer sp_info<cr>",
			{ noremap = true, silent = true, desc = "Clean buffer sp info" }
		)
	end

	if plugin.config.enable_shorten_keymap then
		if plugin.config.shorten_keymap_prefix == "m" then
			vim.api.nvim_set_keymap("n", "M", "m", { noremap = true })
		end

		----------
		-- MindmapAdd
		----------

		-- Add and Remove
		-- Link and Unlink

		vim.api.nvim_set_keymap(
			"n",
			plugin.config.shorten_keymap_prefix .. "a",
			"<cmd>MindmapAddNearestHeadingAsHeadingNode<cr>",
			{ noremap = true, silent = true, desc = "Add nearest heading as heading node" }
		)

		vim.api.nvim_set_keymap(
			"n",
			plugin.config.shorten_keymap_prefix .. "l", -- link
			"<cmd>MindmapAddEdge lastest SimpleEdge nearest<cr>",
			{ noremap = true, silent = true, desc = "Add SimpleEdge from lastest node to nearest node" }
		)
		vim.api.nvim_set_keymap(
			"n",
			plugin.config.shorten_keymap_prefix .. "e",
			"<cmd>MindmapAddNearestHeadingAsHeadingNode<cr> | <cmd>MindmapAddEdge nearest SelfLoopSubheadingEdge nearest<cr>",
			{ noremap = true, silent = true, desc = "Add SelfLoopSubheadingEdge from nearest node to nearest node" }
		)
		vim.api.nvim_set_keymap(
			"n",
			plugin.config.shorten_keymap_prefix .. "E",
			"<cmd>MindmapAddNearestHeadingAsHeadingNode<cr> | <cmd>MindmapAddEdge nearest SelfLoopContentEdge nearest<cr>",
			{ noremap = true, silent = true, desc = "Add SelfLoopContentEdge from nearest node to nearest node" }
		)

		----------
		-- MindmapRemove
		----------

		vim.api.nvim_set_keymap(
			"n",
			plugin.config.shorten_keymap_prefix .. "r",
			"<cmd>MindmapRemove nearest node<cr>",
			{ noremap = true, silent = true, desc = "Remove nearest node" }
		)

		----------
		-- MindmapSp
		----------

		vim.api.nvim_set_keymap(
			"n",
			plugin.config.shorten_keymap_prefix .. "s",
			"<cmd>MindmapSp buffer<cr>",
			{ noremap = true, silent = true, desc = "Review buffer edge" }
		)
	end

	if plugin.config.enable_default_autocmd then
		vim.api.nvim_create_autocmd("VimLeave", {
			callback = function()
				user_func.MindmapSave("all")
			end,
		})
	end
end

--------------------

return user_func
