-- local lineNum = vim.api.nvim_win_get_cursor(0)[1]
-- local backseatNamespace = vim.api.nvim_create_namespace("backseat")
--
-- local function get_highlight_group()
-- 	-- return vim.g.backseat_highlight_group
-- 	return "String"
-- end
--
-- vim.api.nvim_buf_set_extmark(0, backseatNamespace, lineNum - 1, 0, {
-- 	virt_text_pos = "overlay",
-- 	virt_lines = {
-- 		{ { "1", get_highlight_group() } },
-- 	},
-- 	hl_mode = "combine",
-- 	sign_text = "T",
-- 	sign_hl_group = get_highlight_group(),
-- })
--
-- -- Clear all backseat virtual text and signs
-- vim.api.nvim_create_user_command("BClear", function()
-- 	vim.api.nvim_buf_clear_namespace(0, backseatNamespace, 0, -1)
-- end, {})
--
-- -- Clear backseat virtual text and signs for that line
-- vim.api.nvim_create_user_command("BClearLine", function()
-- 	local lineNum = vim.api.nvim_win_get_cursor(0)[1]
-- 	vim.api.nvim_buf_clear_namespace(0, backseatNamespace, lineNum - 1, lineNum)
-- end, {})

-- local ts = require("nvim-treesitter")
-- local parsers = require("nvim-treesitter.parsers")
-- local queries = require("nvim-treesitter.query")
--
-- local function get_header_at_cursor(bufnr)
-- 	local cursor = vim.api.nvim_win_get_cursor(0)
-- 	local root = ts.get_parser(bufnr):parse():root()
--
-- 	local function find_header(node)
-- 		if node:type() == "heading" then
-- 			local start_row, _, end_row, _ = node:range()
-- 			if cursor[1] >= start_row and cursor[1] <= end_row then
-- 				return node
-- 			end
-- 		end
-- 		for _, child in ipairs(node:children()) do
-- 			local result = find_header(child)
-- 			if result then
-- 				return result
-- 			end
-- 		end
-- 	end
--
-- 	local header_node = find_header(root)
-- 	if header_node then
-- 		local text = table.concat(
-- 			header_node:sexpr():gsub("%b[]", ""):gsub("%s+", " "):gsub("^%s", ""):gsub("%s$", ""):match("[^\n]*")
-- 		)
-- 		return text
-- 	else
-- 		return nil
-- 	end
-- end
--
-- local bufnr = vim.api.nvim_get_current_buf()
-- local header = get_header_at_cursor(bufnr)
-- if header then
-- 	print("当前光标所在行所属的最小标题是: " .. header)
-- else
-- 	print("当前光标所在行不属于任何标题")
-- end

-- local ts_utils = require("nvim-treesitter.ts_utils")
--
-- local node = ts_utils.get_node_at_cursor(0)
-- print(node)

local ts_utils = require("nvim-treesitter.ts_utils")

local cursor_node = ts_utils.get_node_at_cursor(0)
print("cursor_node: ", cursor_node)

local parent_node = cursor_node:parent()
print("parent_node: ", parent_node)

local content = cursor_node:sexpr()
print("content: ", content)

local id = cursor_node:id()
print("id: ", id)

local children_node_num = cursor_node:named_child_count()
print("children_node_num: ", children_node_num)

local fist_child_node = cursor_node:child(0)
print("fist_child_node: ", fist_child_node)

local fist_named_child_node = cursor_node:named_child(0)
print("fist_named_child_node: ", fist_named_child_node)

--- Get the node's string representation.
local node_str = vim.treesitter.get_node_text(cursor_node, 0)
print("node_str: ", node_str)
