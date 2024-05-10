---@author Jnpng Shiii
---@date 2024-05-10

local neorg = require("neorg.core")

local function get_node_text(node, source)
	source = source or 0

	local start_row, start_col = node:start()
	local end_row, end_col = node:end_()

	local eof_row = vim.api.nvim_buf_line_count(source)

	if end_row >= eof_row then
		end_row = eof_row - 1
		end_col = -1
	end

	if start_row >= eof_row then
		return nil
	end

	local lines = vim.api.nvim_buf_get_text(source, start_row, start_col, end_row, end_col, {})

	return table.concat(lines, "\n")
end

local M = {}

function M.get_meta_root(bufnr)
	bufnr = bufnr or 0

	local tree = vim.treesitter.get_parser(bufnr, "norg")
	if not tree then
		return nil
	end

	for _, child in pairs(tree:children()) do
		if child:lang() == "norg_meta" then
			local meta_tree = child:parse()[1]
			if meta_tree then
				return meta_tree:root()
			end
		end
	end

	return nil
end

function M.is_mindnode_file(bufnr)
	bufnr = bufnr or 0

	local meta_root = M.get_meta_root(bufnr)
	if not meta_root then
		return false
	end

	local query = neorg.utils.ts_parse_query(
		"norg_meta",
		[[
      (pair
        (key) @key
        (#eq? @key "mindnode")
        (value) @mindnode
      )
    ]]
	)

	for id, node in query:iter_captures(meta_root, bufnr) do
		-- local key = query.captures[id]
		local value = get_node_text(node)
		if value == "true" then
			return true
		end
	end

	return false
end

print(M.is_mindnode_file(0))

return M
