local nts_utils = require("nvim-treesitter.ts_utils")

local plugin_func = require("mindmap.plugin_func")
local utils = require("mindmap.utils")
local ts_utils = require("mindmap.ts_utils")

--------------------

local user_func = {}

----------
-- MindmapAdd (a)
----------

---Add the nearest heading as a HeadingNode to the graph.
---@return nil
function user_func.MindmapAddNearestHeadingAsHeadingNode()
	local graph = plugin_func.find_graph()

	graph:transact(function()
		local file_name, _, rel_file_dir = utils.get_file_info()
		local ts_node = nts_utils.get_node_at_cursor()
		while ts_node and not ts_node:type():match("^heading%d$") do
			ts_node = ts_node:parent()
		end
		if not ts_node then
			graph.logger:error(
				"[MindmapAddNearestHeadingAsHeadingNode]",
				"Cannot find the treesitter node of the nearest heading."
			)
			return
		end

		local new_node = graph.node_factory:create("HeadingNode", #graph.nodes + 1, file_name, rel_file_dir, {}, {
			ts_node = ts_node,
		})

		graph:add_node(new_node)
	end, "Add Nearest Heading As Heading Node")
end

vim.api.nvim_create_user_command("MindmapAddNearestHeadingAsHeadingNode", function()
	user_func.MindmapAddNearestHeadingAsHeadingNode()
end, {
	nargs = 0,
	desc = "Add the nearest heading as a HeadingNode to the graph",
})

---Add the current visual selection as an ExcerptNode to the graph.
---@return nil
function user_func.MindmapAddVisualSelectionAsExcerptNode()
	local graph = plugin_func.find_graph()

	graph:transact(function()
		local file_name, _, rel_file_dir = utils.get_file_info()
		local start_row, start_col, end_row, end_col = utils.get_visual_selection_range()

		local new_node = graph.node_factory:create("ExcerptNode", #graph.nodes + 1, file_name, rel_file_dir, {
			start_row = start_row,
			start_col = start_col,
			end_row = end_row,
			end_col = end_col,
		})

		graph:add_node(new_node)
	end, "Add Visual Selection As Excerpt Node")
end

vim.api.nvim_create_user_command("MindmapAddVisualSelectionAsExcerptNode", function()
	vim.api.nvim_input("<Esc>")
	user_func.MindmapAddVisualSelectionAsExcerptNode()
end, {
	nargs = 0,
	desc = "Add the current visual selection as an ExcerptNode to the graph",
})

----------
-- MindmapRemove (r)
----------

---Remove nodes from the graph based on specified criteria.
---@param criteria table A table of criteria to match nodes against for removal.
---@return nil
function user_func.MindmapRemove(criteria)
	local graph = plugin_func.find_graph()

	graph:transact(function()
		local default_criteria = {
			{ "_state", "active" },
		}
		criteria = vim.tbl_extend("force", default_criteria, criteria or {})

		local items = graph:find_nodes(criteria)
		for id, _ in pairs(items) do
			graph:remove_node(id)
		end
	end, "Remove Nodes")
end

vim.api.nvim_create_user_command("MindmapRemove", function(opts)
	local args = opts.fargs
	local criteria = {}

	local i = 1
	while i <= #args do
		if i + 1 <= #args then
			local key = args[i]
			local value = args[i + 1]

			if value:sub(1, 1) == '"' and value:sub(-1) == '"' then
				local quoted_str = value:sub(2, -2)

				if quoted_str:sub(1, 8) == "function" then
					local func, _ = loadstring("return " .. quoted_str)
					if func then
						criteria[key] = func()
					else
						vim.notify("Invalid Lua function for key `" .. key .. "`.", vim.log.levels.ERROR)
						return
					end
				else
					criteria[key] = quoted_str
				end
			else
				criteria[key] = value
			end

			i = i + 2
		else
			vim.notify("Odd number of arguments. Key `" .. args[i] .. "` has no value.", vim.log.levels.ERROR)
			return
		end
	end

	user_func.MindmapRemove(criteria)
end, {
	nargs = "+",
	---@diagnostic disable-next-line: unused-local
	complete = function(arg_lead, cmd_line, cursor_pos)
		return {
			"_type",
			"_id",
			"_file_name",
			"_rel_file_dir",
			--
			"_data",
			"_cache",
			"_created_at",
			"_state",
			"_version",
		}
	end,
	desc = "Remove nodes from graph based on specified criteria",
})

----------
-- MindmapLink (l)
----------

---Link nodes in the graph.
---@param from_node_location string Location of the source node(s).
---@param edge_type string Type of the edge to create.
---@param to_node_location? string Location of the target node(s). If nil, links to the source node(s).
function user_func.MindmapLink(from_node_location, edge_type, to_node_location)
	local graph = plugin_func.find_graph()

	graph:transact(function()
		if not graph.edge_factory:get_registered_class(edge_type) then
			graph.logger:error(
				"[MindmapLink]",
				string.format("Invalid edge type `%s`. Type must be registered in graph first.", edge_type)
			)
			return
		end

		local from_nodes = plugin_func.find_heading_nodes(graph, from_node_location)
		local to_nodes = to_node_location and plugin_func.find_heading_nodes(graph, to_node_location) or from_nodes

		for _, from_node in pairs(from_nodes) do
			for _, to_node in pairs(to_nodes) do
				local new_edge = graph.edge_factory:create(edge_type, #graph.edges + 1, from_node._id, to_node._id)
				graph:add_edge(new_edge)
			end
		end
	end, "Link Nodes")
end

vim.api.nvim_create_user_command("MindmapLink", function(opts)
	user_func.MindmapLink(opts.fargs[1], opts.fargs[2], opts.fargs[3])
end, {
	nargs = "+",
	---@diagnostic disable-next-line: unused-local
	complete = function(arg_lead, cmd_line, cursor_pos)
		local graph = plugin_func.find_graph()
		if cursor_pos == 12 then
			return graph.edge_factory:get_registered_types()
		else -- Autocomplete for node locations
			return { "latest", "nearest", "telescope", "buffer" }
		end
	end,
})

----------
-- MindmapUnlink (u)
----------

---Remove edges from the graph based on specified criteria.
---@param criteria table A table of criteria to match edges against for removal.
---@return nil
function user_func.MindmapUnlink(criteria)
	local graph = plugin_func.find_graph()

	graph:transact(function()
		local default_criteria = {
			{ "_state", "active" },
		}
		criteria = vim.tbl_extend("force", default_criteria, criteria or {})

		local items = graph:find_edges(criteria)
		for id, _ in pairs(items) do
			graph:remove_edge(id)
		end
	end, "Unlink Nodes")
end

vim.api.nvim_create_user_command("MindmapUnlink", function(opts)
	local args = opts.fargs
	local criteria = {}

	local i = 1
	while i <= #args do
		if i + 1 <= #args then
			local key = args[i]
			local value = args[i + 1]

			if value:sub(1, 1) == '"' and value:sub(-1) == '"' then
				local quoted_str = value:sub(2, -2)

				if quoted_str:sub(1, 8) == "function" then
					local func, _ = loadstring("return " .. quoted_str)
					if func then
						criteria[key] = func()
					else
						vim.notify("Invalid Lua function for key `" .. key .. "`.", vim.log.levels.ERROR)
						return
					end
				else
					criteria[key] = quoted_str
				end
			else
				criteria[key] = value
			end

			i = i + 2
		else
			vim.notify("Odd number of arguments. Key `" .. args[i] .. "` has no value.", vim.log.levels.ERROR)
			return
		end
	end

	user_func.MindmapUnlink(criteria)
end, {
	nargs = "+",
	---@diagnostic disable-next-line: unused-local
	complete = function(arg_lead, cmd_line, cursor_pos)
		return {
			"_type",
			"_id",
			"_from",
			"_to",
			--
			"_data",
			"_cache",
			"_created_at",
			"_updated_at",
			"_due_at",
			"_ease",
			"_interval",
			"_answer_count",
			"_ease_count",
			"_again_count",
			"_state",
			"_version",
		}
	end,
	desc = "Remove edges from graph based on specified criteria",
})

----------
-- MindmapDisplay (d)
----------

---Display information for nodes in the graph.
---@param location string Location of the nodes to display information for.
---@param show_type string Type of information to display. Can be "card_back", "excerpt", or "sp_info".
function user_func.MindmapDisplay(location, show_type)
	if not vim.tbl_contains({ "card_back", "excerpt", "sp_info" }, show_type) then
		vim.notify(
			"[MindmapDisplay] Invalid show_type `"
				.. show_type
				.. "`. Must be one of `card_back`, `excerpt`, or `sp_info`.",

			vim.log.levels.ERROR
		)
		return
	end

	local graph = plugin_func.find_graph()
	local nodes = plugin_func.find_heading_nodes(graph, location)
	local namespace = plugin_func.find_namespace(show_type)
	local screen_width = vim.api.nvim_win_get_width(0) - 20

	for _, node in pairs(nodes) do
		local line_num = ts_utils.get_node_start_line(node._cache.ts_node)
		utils.clear_virtual_text(0, namespace, line_num, line_num + 1)

		for index, edge_id in ipairs(node._data.incoming_edge_ids or {}) do
			local edge = graph.edges[edge_id]
			local from_node = graph.nodes[edge._from]

			if show_type == "card_back" then
				local _, back = from_node:get_content(edge._type)
				back[1] = string.format("* Card %s [%s]: %s", index, edge._type, back[1])
				back = utils.limit_string_length(back, screen_width)
				-- FIXME: wrong order
				utils.add_virtual_text(0, namespace, line_num, back)
			elseif show_type == "excerpt" and from_node._type == "ExcerptNode" then
				local _, back = from_node:get_content(edge._type)
				back[1] = string.format("%s: %s", index, back[1])
				back = utils.limit_string_length(back, screen_width)
				-- FIXME: wrong order
				utils.add_virtual_text(0, namespace, line_num, back)
			elseif show_type == "sp_info" then
				local text = string.format(
					"Due: %s, Ease: %s, Interval: %s, Again: %s/%s",
					os.date("%Y-%m-%d", edge._due_at),
					edge._ease,
					edge._interval,
					edge._again_count,
					edge._answer_count
				)
				local text_type = edge._due_at < os.time() and "Error" or nil
				utils.add_virtual_text(0, namespace, line_num, text, text_type)
			end
		end
	end
end

vim.api.nvim_create_user_command("MindmapDisplay", function(opts)
	user_func.MindmapDisplay(opts.fargs[1], opts.fargs[2])
end, {
	nargs = "+",
	---@diagnostic disable-next-line: unused-local
	complete = function(arg_lead, cmd_line, cursor_pos)
		if cursor_pos == 12 then
			return { "latest", "nearest", "telescope", "buffer" }
		else
			return { "card_back", "excerpt", "sp_info" }
		end
	end,
})

----------
-- MindmapClean (c)
----------

---Clean virtual text for nodes in the graph.
---@param location string Location of the nodes to clean virtual text for.
---@param clean_type string Type of virtual text to clean. Can be "card_back", "excerpt", or "sp_info".
function user_func.MindmapClean(location, clean_type)
	if not vim.tbl_contains({ "card_back", "excerpt", "sp_info" }, clean_type) then
		vim.notify(
			"[MindmapClean] Invalid clean_type `"
				.. clean_type
				.. "`. Must be one of `card_back`, `excerpt`, or `sp_info`.",

			vim.log.levels.ERROR
		)
		return
	end

	local graph = plugin_func.find_graph()
	local nodes = plugin_func.find_heading_nodes(graph, location)
	local namespace = plugin_func.find_namespace(clean_type)

	for _, node in pairs(nodes) do
		local start_line = ts_utils.get_node_start_line(node._cache.ts_node)
		utils.clear_virtual_text(0, namespace, start_line, start_line + 1)
	end
end

vim.api.nvim_create_user_command("MindmapClean", function(opts)
	user_func.MindmapClean(opts.fargs[1], opts.fargs[2])
end, {
	nargs = "+",
	---@diagnostic disable-next-line: unused-local
	complete = function(arg_lead, cmd_line, cursor_pos)
		if cursor_pos == 13 then
			return { "latest", "nearest", "telescope", "buffer" }
		else
			return { "card_back", "excerpt", "sp_info" }
		end
	end,
})

----------
-- MindmapUndo (z)
----------

---Undo the last operation in the graph.
---This function will revert the most recent change made to the graph.
---@return nil
function user_func.MindmapUndo()
	local graph = plugin_func.find_graph()
	graph:undo()
end

vim.api.nvim_create_user_command("MindmapUndo", function()
	user_func.MindmapUndo()
end, {
	nargs = 0,
	desc = "Undo the last operation in the graph",
})

----------
-- MindmapRedo (Z)
----------

---Redo the last undone operation in the graph.
---This function will reapply the most recently undone change to the graph.
---@return nil
function user_func.MindmapRedo()
	local graph = plugin_func.find_graph()
	graph:redo()
end

vim.api.nvim_create_user_command("MindmapRedo", function()
	user_func.MindmapRedo()
end, {
	nargs = 0,
	desc = "Redo the last undone operation in the graph",
})

----------
-- MindmapReview (v)
----------

---Review cards in the graph based on the specified location.
---This function will go through all due cards at the given location and prompt for review.
---@param location string The location to review. Can be "latest", "nearest", "telescope", or "buffer".
---@return nil
function user_func.MindmapReview(location)
	local graph = plugin_func.find_graph()
	local nodes = plugin_func.find_heading_nodes(graph, location)

	for _, node in pairs(nodes) do
		for _, edge_id in ipairs(node._data.incoming_edge_ids or {}) do
			local edge = graph.edges[edge_id]
			if edge._due_at <= os.time() then
				local status = graph:show_card(edge_id)
				if status == "quit" then
					vim.notify("Review session ended.", vim.log.levels.INFO)
					return
				end
			end
		end
	end

	vim.notify("Review completed for all due cards.", vim.log.levels.INFO)
end

vim.api.nvim_create_user_command("MindmapReview", function(opts)
	user_func.MindmapReview(opts.fargs[1])
end, {
	nargs = 1,
	complete = function(_, _, _)
		return { "latest", "nearest", "telescope", "buffer" }
	end,
	desc = "Review cards in the graph at the specified location",
})

----------
-- MindmapSave (s)
----------

---Save the graph(s).
---This function can save either the graph for the current buffer or all graphs.
---@param save_type string The type of save operation. Can be "buffer" or "all".
---@return nil
function user_func.MindmapSave(save_type)
	if save_type == "buffer" then
		local graph = plugin_func.find_graph()
		graph:save()
		vim.notify("Saved graph for current buffer.", vim.log.levels.INFO)
	elseif save_type == "all" then
		for _, graph in pairs(plugin_func.get_cache().graphs) do
			graph:save()
		end
		vim.notify("Saved all graphs.", vim.log.levels.INFO)
	else
		vim.notify("Invalid save type. Use 'buffer' or 'all'.", vim.log.levels.ERROR)
	end
end

vim.api.nvim_create_user_command("MindmapSave", function(opts)
	user_func.MindmapSave(opts.fargs[1])
end, {
	nargs = 1,
	complete = function(_, _, _)
		return { "buffer", "all" }
	end,
	desc = "Save the graph(s) (buffer or all)",
})

----------
-- MindmapTest (t)
----------

--------------------

return user_func
