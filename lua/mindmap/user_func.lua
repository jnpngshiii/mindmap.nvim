local nts_utils = require("nvim-treesitter.ts_utils")

local plugin_data = require("mindmap.plugin_data")
local plugin_func = require("mindmap.plugin_func")
local utils = require("mindmap.utils")
local ts_utils = require("mindmap.ts_utils")

--------------------

local user_func = {}

----------
-- MindmapAddNode (a)
-- MindmapAddNode (A)
----------

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
	end)
end

vim.api.nvim_create_user_command("MindmapAddNearestHeadingAsHeadingNode", function()
	user_func.MindmapAddNearestHeadingAsHeadingNode()
end, {
	nargs = 0,
})

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
	end)
end

vim.api.nvim_create_user_command("MindmapAddVisualSelectionAsExcerptNode", function()
	vim.api.nvim_input("<Esc>")
	user_func.MindmapAddVisualSelectionAsExcerptNode()
end, {
	nargs = 0,
})

----------
-- MindmapRemoveNode (r)
-- MindmapRemoveEdge (R)
----------

function user_func.MindmapRemoveNode(criteria)
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
	end)
end

function user_func.MindmapRemoveEdge(criteria)
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
	end)
end

vim.api.nvim_create_user_command("MindmapRemoveEdge", function(opts)
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

	user_func.MindmapRemoveEdge(criteria)
end, {
	nargs = "+",
	complete = function(ArgLead, CmdLine, CursorPos)
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

--------------------

return user_func
