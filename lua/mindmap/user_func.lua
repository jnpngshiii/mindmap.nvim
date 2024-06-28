local nts_utils = require("nvim-treesitter.ts_utils")

local plugin_func = require("mindmap.plugin_func")
local utils = require("mindmap.utils")
local ts_utils = require("mindmap.ts_utils")

--------------------

local location_list = { "latest", "nearest", "*telescope", "buffer" }

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
			graph.logger:error("[Mindmap]", "Cannot find the treesitter node of the nearest heading.")
			return
		end

		local new_node = graph.node_factory:create("HeadingNode", #graph.nodes + 1, file_name, rel_file_dir, {}, {
			ts_node = ts_node,
		})

		graph:add_node(new_node)
	end, "Add the nearest heading as a `HeadingNode`")
end

vim.api.nvim_create_user_command("MindmapAddNearestHeadingAsHeadingNode", function()
	user_func.MindmapAddNearestHeadingAsHeadingNode()
end, {
	nargs = 0,
	desc = "Add the nearest heading as a `HeadingNode`",
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
	end, "Add visual selection as an `ExcerptNode`")
end

vim.api.nvim_create_user_command("MindmapAddVisualSelectionAsExcerptNode", function()
	vim.api.nvim_input("<Esc>")
	user_func.MindmapAddVisualSelectionAsExcerptNode()
end, {
	nargs = 0,
	desc = "Add visual selection as an `ExcerptNode`",
})

----------
-- MindmapRemove (r)
----------

---Remove node(s) from the graph based on specified location.
---@param location string Location of the node(s). Can be "latest", "nearest", "telescope", or "buffer".
---@return nil
function user_func.MindmapRemove(location)
	if not vim.tbl_contains(location_list, location) then
		vim.notify("[Mindmap] Invalid `location`.", vim.log.levels.ERROR)
		return
	end

	local graph = plugin_func.find_graph()
	local nodes = plugin_func.find_heading_nodes(graph, location)
	graph:transact(function()
		for _, node in pairs(nodes) do
			graph:remove_node(node._id)
		end
	end, "Remove Node(s) based on `" .. location .. "`")
end

vim.api.nvim_create_user_command("MindmapRemove", function(opts)
	user_func.MindmapRemove(opts.fargs[1])
end, {
	nargs = "+",
	---@diagnostic disable-next-line: unused-local
	complete = function(arg_lead, cmd_line, cursor_pos)
		return location_list
	end,
	desc = "Remove node(s) based on specified location",
})

----------
-- MindmapLink (l)
----------

---Link node(s) in the graph based on specified location.
---@param from_node_location string Location of the source node(s). Can be "latest", "nearest", "telescope", or "buffer".
---@param edge_type string Type of the edge used for linking.
---@param to_node_location? string Location of the target node(s). If nil, links to the source node(s). Can be "latest", "nearest", "telescope", or "buffer".
function user_func.MindmapLink(from_node_location, edge_type, to_node_location)
	if not vim.tbl_contains(location_list, from_node_location) then
		vim.notify("[Mindmap] Invalid `from_node_location`.", vim.log.levels.ERROR)
		return
	end

	to_node_location = to_node_location or from_node_location
	if to_node_location and not vim.tbl_contains(location_list, to_node_location) then
		vim.notify("[Mindmap] Invalid `to_node_location`.", vim.log.levels.ERROR)
		return
	end

	local graph = plugin_func.find_graph()
	if not vim.tbl_contains(graph.edge_factory:get_registered_types(), edge_type) then
		graph.logger:error(
			"[MindmapLink]",
			string.format("Invalid edge type `%s`. Type must be registered in graph first.", edge_type)
		)
		return
	end

	graph:transact(function()
		local from_nodes = plugin_func.find_heading_nodes(graph, from_node_location)
		local to_nodes = plugin_func.find_heading_nodes(graph, to_node_location)

		for _, from_node in pairs(from_nodes) do
			for _, to_node in pairs(to_nodes) do
				local new_edge = graph.edge_factory:create(edge_type, #graph.edges + 1, from_node._id, to_node._id)
				graph:add_edge(new_edge)
			end
		end
	end, "Link Node(s) based on `" .. from_node_location .. "` and `" .. to_node_location .. "`")
end

vim.api.nvim_create_user_command("MindmapLink", function(opts)
	user_func.MindmapLink(opts.fargs[1], opts.fargs[2], opts.fargs[3])
end, {
	nargs = "+",
	---@diagnostic disable-next-line: unused-local
	complete = function(arg_lead, cmd_line, cursor_pos)
		return location_list
	end,
	desc = "Link node(s) based on specified location",
})

----------
-- TODO:
-- MindmapUnlink (u)
----------

---Remove edge(s) from the graph based on specified criteria.
---@param criteria table A table of criteria to match edge(s) against for removal.
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
	end, "Unlink Node(s)")
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
						vim.notify("[Mindmap] Invalid Lua function for key `" .. key .. "`.", vim.log.levels.ERROR)
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
			vim.notify("[Mindmap] Odd number of arguments. Key `" .. args[i] .. "` has no value.", vim.log.levels.ERROR)
			return
		end
	end

	user_func.MindmapUnlink(criteria)
end, {
	nargs = "+",
	---@diagnostic disable-next-line: unused-local
	complete = function(arg_lead, cmd_line, cursor_pos)
		return location_list
	end,
	desc = "Remove edge(s) from graph based on specified criteria",
})

----------
-- MindmapDisplay (d)
----------

---Display information of node(s) in the graph based on specified location.
---@param location string Location of the node(s) to display information for. Can be "latest", "nearest", "telescope", or "buffer".
---@param show_type string Type of information to display. Can be "card_back", "excerpt", or "sp_info".
function user_func.MindmapDisplay(location, show_type)
	if not vim.tbl_contains(location_list, location) then
		vim.notify("[Mindmap] Invalid `location`.", vim.log.levels.ERROR)
	end
	if not vim.tbl_contains({ "card_back", "excerpt", "sp_info" }, show_type) then
		vim.notify("[Mindmap] Invalid `show_type`.", vim.log.levels.ERROR)
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
		if cursor_pos == 15 then
			return location_list
		else
			return { "card_back", "excerpt", "sp_info" }
		end
	end,
	desc = "Display information of node(s) based on specified location",
})

----------
-- MindmapClean (c)
----------

---Clean virtual text for node(s) in the graph based on specified location.
---@param location string Location of the node(s) to clean virtual text for. Can be "latest", "nearest", "telescope", or "buffer".
---@param clean_type string Type of virtual text to clean. Can be "card_back", "excerpt", or "sp_info".
function user_func.MindmapClean(location, clean_type)
	if not vim.tbl_contains(location_list, location) then
		vim.notify("[Mindmap] Invalid `location`.", vim.log.levels.ERROR)
	end
	if not vim.tbl_contains({ "card_back", "excerpt", "sp_info" }, clean_type) then
		vim.notify("[Mindmap] Invalid `clean_type`.", vim.log.levels.ERROR)
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
			return location_list
		else
			return { "card_back", "excerpt", "sp_info" }
		end
	end,
	desc = "Clean virtual text for node(s) based on specified location",
})

----------
-- MindmapUndo (z)
----------

---Undo the last operation in the graph.
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

---Review card(s) in the graph based on specified location.
---@param location string Location of card(s) to review. Can be "latest", "nearest", "telescope", or "buffer".
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
					vim.notify("[Mindmap] Review session ended.", vim.log.levels.INFO)
					return
				end
			end
		end
	end

	vim.notify("[Mindmap] Review completed for all due cards.", vim.log.levels.INFO)
end

vim.api.nvim_create_user_command("MindmapReview", function(opts)
	user_func.MindmapReview(opts.fargs[1])
end, {
	nargs = 1,
	complete = function(_, _, _)
		return { "latest", "nearest", "telescope", "buffer" }
	end,
	desc = "Review card(s) in the graph based on specified location",
})

----------
-- MindmapSave (s)
----------

---Save the graph.
---@param save_dir? string
---@return nil
function user_func.MindmapSave(save_dir)
	save_dir = save_dir or ({ utils.get_file_path() })[4]
	if save_dir == "all" then
		for _, graph in pairs(plugin_func.get_cache().graphs) do
			graph:save()
		end
		vim.notify("[Mindmap] Saved all graphs.", vim.log.levels.INFO)
	end

	local graph = plugin_func.find_graph(save_dir)
	if not graph then
		vim.notify("[Mindmap] No graph found.", vim.log.levels.ERROR)
		return
	end

	graph:save()
	graph.logger:info("graph", "Graph saved to `" .. save_dir .. "`.")
end

vim.api.nvim_create_user_command("MindmapSave", function(opts)
	user_func.MindmapSave(opts.fargs[1])
end, {
	nargs = 1,
	complete = function(_, _, _) end,
	desc = "Save graph(s)",
})

----------
-- MindmapTest (t)
----------

--------------------

return user_func
