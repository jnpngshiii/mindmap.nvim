local plugin = require("mindmap.plugin")
local utils = require("mindmap.utils")
local ts_utils = require("mindmap.ts_utils")

--------------------
-- User functions
--------------------

local user_func = {}

----------
-- MindmapAdd (Node)
----------

function user_func.MindmapAdd(location, node_type)
	local found_graph = plugin.find_graph()
	local _, found_ts_nodes = plugin.find_heading_nodes(found_graph, location)

	-- Transaction --

	found_graph:begin_operation()

	for _, ts_node in pairs(found_ts_nodes) do
		-- Pre action --
		-- TODO: This action is manage by `node:before_add_into_graph(self)`,
		-- which is auto called by `graph:add_node(node)`.
		-- Avoid adding the same heading node
		local title_node, _, _ = ts_utils.parse_heading_node(ts_node)
		local id = tonumber(string.match(vim.treesitter.get_node_text(title_node, 0), "%d%d%d%d%d%d%d%d"))

		-- Add node --
		if not id then
			local file_name, _, rel_file_path, _ = unpack(utils.get_file_info())
			local created_heading_node =
				-- TODO: how to use ...?
				found_graph.node_factory:create(node_type, #found_graph.nodes + 1, file_name, rel_file_path)
			created_heading_node.cache.ts_node = nearest_heading_ts_node
			created_heading_node.cache.ts_node_bufnr = vim.api.nvim_get_current_buf()
			found_graph:add_node(created_heading_node)
		else
			vim.notify(
				"[Func] Treesitter node is already a heading node with id `" .. id .. "`. Abort adding.",
				vim.log.levels.WARN
			)
		end

		-- Post action --
		-- This action is manage by `node:after_add_into_graph(self)`,
		-- which is auto called by `graph:add_node(node)`.
	end

	-- Transaction --

	found_graph:end_operation()
end

vim.api.nvim_create_user_command("MindmapAdd", function(arg)
	user_func.MindmapAdd(arg.fargs[1], arg.fargs[2])
end, {
	nargs = "*",
	---@diagnostic disable-next-line: unused-local
	complete = function(arg_lead, cmd_line, cursor_pos)
		if cursor_pos == 14 then
			return { "lastest", "nearest", "-telescope", "buffer" }
		else
			return plugin.found_graph.node_factory:get_registered_types()
		end
	end,
})

---@deprecated
-- TODO: Merge into `MindmapAdd`
function user_func.MindmapAddVisualSelectionAsExcerptNode()
	local found_graph = plugin.find_graph()

	-- Transaction --

	found_graph:begin_operation()

	-- Add node --

	local visual_selection_range = unpack(utils.get_latest_visual_selection())
	local file_name, _, rel_file_path, _ = unpack(utils.get_file_info())
	local created_excerpt_node = found_graph.node_factory:create(
		"ExcerptNode",
		#found_graph.nodes + 1,
		file_name,
		rel_file_path,
		visual_selection_range
	)
	found_graph:add_node(created_excerpt_node)

	-- Transaction --

	found_graph:end_operation()
end

vim.api.nvim_create_user_command("MindmapAddVisualSelectionAsExcerptNode", function()
	vim.api.nvim_input("<Esc>")
	user_func.MindmapAddVisualSelectionAsExcerptNode()
end, {
	nargs = 0,
})

----------
-- MindmapRemove (Node)
----------

function user_func.MindmapRemove(location, node_type)
	local found_graph = plugin.find_graph()
	found_graph:begin_operation()

	if node_type and found_graph.node_factory:get_registered_class(node_type) then
		vim.notify(
			"[MindmapRemove] Invalid type `" .. node_type .. "`. Type must register in graph first.",
			vim.log.levels.WARN
		)
		found_graph:end_operation()
		return
	end

	local nodes, _ = plugin.find_heading_nodes(found_graph, location)
	for id, node in pairs(nodes) do
		if not node_type or node.type == node_type then
			found_graph:remove_node(id)
		end
	end

	found_graph:end_operation()
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
			return {}
		end
	end,
})

----------
-- MindmapLink (Edge)
----------

---@param from_node_location string
---@param edge_type string
---@param to_node_location? string
function user_func.MindmapLink(from_node_location, edge_type, to_node_location)
	local found_graph = plugin.find_graph()
	found_graph:begin_operation()

	if not found_graph.edge_factory:get_registered_class(edge_type) then
		vim.notify("[MindmapLink] Invalid `edge_type`. Type must register in graph first.", vim.log.levels.ERROR)
		found_graph:end_operation()
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
			local created_edge = found_graph.edge_factory
				:get_registered_class(edge_type)
				:new(#found_graph.edges + 1, from_node.id, to_node.id)
			found_graph:add_edge(created_edge)
		end
	end

	found_graph:end_operation()
end

vim.api.nvim_create_user_command("MindmapLink", function(arg)
	user_func.MindmapLink(arg.fargs[1], arg.fargs[2], arg.fargs[3])
end, {
	nargs = "*",
	---@diagnostic disable-next-line: unused-local
	complete = function(arg_lead, cmd_line, cursor_pos)
		if cursor_pos == 15 then
			return plugin.found_graph.edge_factory:get_registered_types()
		else
			return { "lastest", "nearest", "-telescope", "buffer" }
		end
	end,
})

----------
-- MindmapUnlink (Edge)
----------

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
	found_graph:begin_operation()

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

	found_graph:end_operation()
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

	local found_graph = plugin.find_graph()
	found_graph:begin_operation()

	local _, ts_nodes = plugin.find_heading_nodes(found_graph, location)

	for _, ts_node in pairs(ts_nodes) do
		local start_row, _, _, _ = ts_node:range()
		utils.clear_virtual_text(0, plugin.find_namespace(clean_type), start_row, start_row + 1)
	end

	found_graph:end_operation()
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
-- MindmapUndo
----------

function user_func.MindmapUndo()
	local found_graph = plugin.find_graph()
	found_graph:undo()
end

vim.api.nvim_create_user_command("MindmapUndo", function()
	user_func.MindmapUndo()
end, {
	nargs = 0,
})

----------
-- MindmapRedo
----------

function user_func.MindmapRedo()
	local found_graph = plugin.find_graph()
	found_graph:redo()
end

vim.api.nvim_create_user_command("MindmapRedo", function()
	user_func.MindmapRedo()
end, {
	nargs = 0,
})

----------
-- MindmapReview
----------

function user_func.MindmapReview(location)
	local found_graph = plugin.find_graph()
	local heading_nodes, _ = plugin.find_heading_nodes(found_graph, location)

	vim.notify("Reviewing `" .. location .. "` start.")

	for _, node in pairs(heading_nodes) do
		for _, edge_id in ipairs(node.incoming_edge_ids) do
			if found_graph.edges[edge_id].due_at < tonumber(os.time()) then
				local status = found_graph:show_card(edge_id)
				if status == "quit" then
					vim.notify("Reviewing `" .. location .. "` end.")
					return
				end
			end
		end
	end

	vim.notify("Reviewing `" .. location .. "` end.")
end

vim.api.nvim_create_user_command("MindmapReview", function(arg)
	user_func.MindmapReview(arg.fargs[1])
end, {
	nargs = "*",
	---@diagnostic disable-next-line: unused-local
	complete = function(arg_lead, cmd_line, cursor_pos)
		return { "lastest", "nearest", "-telescope", "buffer", "-graph" }
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
		-- MindmapAdd (Node)
		----------

		vim.api.nvim_set_keymap(
			"n",
			plugin.config.keymap_prefix .. "an",
			"<cmd>MindmapAdd nearest HeadingNode<cr>",
			{ noremap = true, silent = true, desc = "Add nearest heading as heading node" }
		)
		vim.api.nvim_set_keymap(
			"n",
			plugin.config.keymap_prefix .. "ae",
			"<cmd>MindmapAddVisualSelectionAsExcerptNode<cr>",
			{ noremap = true, silent = true, desc = "Add visual selection as excerpt node" }
		)
		vim.api.nvim_set_keymap(
			"v",
			"E",
			"<cmd>MindmapAddVisualSelectionAsExcerptNode<cr>",
			{ noremap = true, silent = true, desc = "Add visual selection as excerpt node" }
		)

		----------
		-- MindmapRemove (Node)
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
		-- MindmapLink (Edge)
		----------

		vim.api.nvim_set_keymap(
			"n",
			plugin.config.keymap_prefix .. "lln",
			"<cmd>MindmapLink lastest SimpleEdge nearest<cr>",
			{ noremap = true, silent = true, desc = "Add SimpleEdge from lastest node to nearest node" }
		)
		vim.api.nvim_set_keymap(
			"n",
			plugin.config.keymap_prefix .. "lnn",
			"<cmd>MindmapLink nearest SelfLoopSubheadingEdge nearest<cr>",
			{ noremap = true, silent = true, desc = "Add SelfLoopSubheadingEdge from nearest node to nearest node" }
		)
		vim.api.nvim_set_keymap(
			"n",
			plugin.config.keymap_prefix .. "lnN",
			"<cmd>MindmapLink nearest SelfLoopContentEdge nearest<cr>",
			{ noremap = true, silent = true, desc = "Add SelfLoopContentEdge from nearest node to nearest node" }
		)

		----------
		-- MindmapUnlink (Edge)
		----------

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

		----------
		-- MindmapUndo
		----------

		----------
		-- MindmapRedo
		----------

		----------
		-- MindmapReview
		----------

		vim.api.nvim_set_keymap(
			"n",
			plugin.config.keymap_prefix .. "sl",
			"<cmd>MindmapReview lastest<cr>",
			{ noremap = true, silent = true, desc = "Review lastest edge" }
		)
		vim.api.nvim_set_keymap(
			"n",
			plugin.config.keymap_prefix .. "sn",
			"<cmd>MindmapReview nearest<cr>",
			{ noremap = true, silent = true, desc = "Review nearest edge" }
		)
		vim.api.nvim_set_keymap(
			"n",
			plugin.config.keymap_prefix .. "st",
			"<cmd>MindmapReview telescope<cr>",
			{ noremap = true, silent = true, desc = "Review telescope edge" }
		)
		vim.api.nvim_set_keymap(
			"n",
			plugin.config.keymap_prefix .. "sb",
			"<cmd>MindmapReview buffer<cr>",
			{ noremap = true, silent = true, desc = "Review buffer edge" }
		)
		vim.api.nvim_set_keymap(
			"n",
			plugin.config.keymap_prefix .. "sg",
			"<cmd>MindmapReview graph<cr>",
			{ noremap = true, silent = true, desc = "Review graph edge" }
		)

		----------
		-- MindmapSave
		----------

		----------
		-- MindmapTest
		----------
	end

	if plugin.config.enable_shorten_keymap then
		vim.notify("[Mindmap.nvim] Shorten keymap is enabled.")

		if plugin.config.shorten_keymap_prefix == "m" then
			vim.api.nvim_set_keymap("n", "M", "m", { noremap = true })
			-- vim.api.nvim_set_keymap("n", "m", "M", { noremap = true })
		end

		----------
		-- MindmapAdd (Node)
		----------

		vim.api.nvim_set_keymap(
			"n",
			plugin.config.shorten_keymap_prefix .. "a",
			"<cmd>MindmapAdd nearest HeadingNode<cr>",
			{ noremap = true, silent = true, desc = "Add nearest heading as heading node" }
		)

		----------
		-- MindmapRemove (Node)
		----------

		vim.api.nvim_set_keymap(
			"n",
			plugin.config.shorten_keymap_prefix .. "r",
			"<cmd>MindmapRemove nearest node<cr>",
			{ noremap = true, silent = true, desc = "Remove nearest node" }
		)

		----------
		-- MindmapLink (Edge)
		----------

		vim.api.nvim_set_keymap(
			"n",
			plugin.config.shorten_keymap_prefix .. "l", -- link
			"<cmd>MindmapLink lastest SimpleEdge nearest<cr>",
			{ noremap = true, silent = true, desc = "Add SimpleEdge from lastest node to nearest node" }
		)
		vim.api.nvim_set_keymap(
			"n",
			plugin.config.shorten_keymap_prefix .. "s",
			"<cmd>MindmapAdd nearest HeadingNode<cr> | <cmd>MindmapLink nearest SelfLoopSubheadingEdge nearest<cr>",
			{ noremap = true, silent = true, desc = "Add SelfLoopSubheadingEdge from nearest node to nearest node" }
		)
		vim.api.nvim_set_keymap(
			"n",
			plugin.config.shorten_keymap_prefix .. "S",
			"<cmd>MindmapAdd nearest HeadingNode<cr> | <cmd>MindmapLink nearest SelfLoopContentEdge nearest<cr>",
			{ noremap = true, silent = true, desc = "Add SelfLoopContentEdge from nearest node to nearest node" }
		)

		----------
		-- MindmapUnlink (Edge)
		----------

		----------
		-- MindmapDisplay
		----------

		vim.api.nvim_set_keymap(
			"n",
			plugin.config.shorten_keymap_prefix .. "d",
			"<cmd>MindmapDisplay buffer excerpt<cr>",
			{ noremap = true, silent = true, desc = "Display buffer excerpt" }
		)

		----------
		-- MindmapClean
		----------

		vim.api.nvim_set_keymap(
			"n",
			plugin.config.shorten_keymap_prefix .. "c",
			"<cmd>MindmapClean buffer excerpt<cr>",
			{ noremap = true, silent = true, desc = "Clean buffer excerpt" }
		)

		----------
		-- MindmapUndo
		----------

		vim.api.nvim_set_keymap(
			"n",
			plugin.config.shorten_keymap_prefix .. "U",
			"<cmd>MindmapUndo<cr>",
			{ noremap = true, silent = true, desc = "Undo" }
		)

		----------
		-- MindmapRedo
		----------

		vim.api.nvim_set_keymap(
			"n",
			plugin.config.shorten_keymap_prefix .. "R",
			"<cmd>MindmapRedo<cr>",
			{ noremap = true, silent = true, desc = "Redo" }
		)

		----------
		-- MindmapReview
		----------

		vim.api.nvim_set_keymap(
			"n",
			plugin.config.shorten_keymap_prefix .. "r",
			"<cmd>MindmapReview buffer<cr>",
			{ noremap = true, silent = true, desc = "Review buffer edge" }
		)

		----------
		-- MindmapSave
		----------

		----------
		-- MindmapTest
		----------
	end

	if plugin.config.enable_default_autocmd then
		----------
		-- MindmapSave
		----------

		vim.api.nvim_create_autocmd("VimLeave", {
			callback = function()
				user_func.MindmapSave("all")
			end,
		})

		----------
		-- MindmapTest
		----------
	end
end

--------------------

require("mindmap.experiment.queries.init")

return user_func
