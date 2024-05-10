local neorg = require("neorg.core")

local M = {}

function M.get_meta_root()
	local parser = vim.treesitter.get_parser(0, "norg")
	if not parser then
		return nil
	end

	for _, child in pairs(parser:children()) do
		if child:lang() == "norg_meta" then
			local meta_tree = child:parse()[1]
			if meta_tree then
				return meta_tree:root()
			end
		end
	end

	return nil
end

function M.get_doc_root()
	local parser = vim.treesitter.get_parser(0, "norg")
	if not parser then
		return nil
	end

	local doc_tree = parser:parse()[1]
	if doc_tree then
		return doc_tree:root()
	end

	return nil
end

function M.is_mindnode_file()
	local meta_root = M.get_meta_root()
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

	for _, node in query:iter_captures(meta_root, 0) do
		local value = M.get_node_text(node)
		if value == "true" then
			return true
		end
	end

	return false
end

--- Get the text of a node.
--- A text includes a title and a content.
function M.get_node_text(node)
	local end_row, end_col = node:end_()
	local eof_row = vim.api.nvim_buf_line_count(0)
	if end_row >= eof_row then
		end_row = eof_row - 1
		end_col = -1
	end

	local start_row, start_col = node:start()
	if start_row >= eof_row then
		return nil
	end

	local lines = vim.api.nvim_buf_get_text(0, start_row, start_col, end_row, end_col, {})

	return table.concat(lines, "\n")
end

--- Get the content of a node.
--- This method can only be used for heading nodes.
function M.get_node_content(node)
	if not string.match(node:type(), "heading%d") then
		return nil
	end

	local end_row, end_col = node:end_()
	local eof_row = vim.api.nvim_buf_line_count(0)
	if end_row >= eof_row then
		end_row = eof_row - 1
		end_col = -1
	end

	local start_row, start_col = node:start()
	start_row = start_row + 1 -- TODO: fix this hack
	if start_row >= eof_row then
		return nil
	end

	local lines = vim.api.nvim_buf_get_text(0, start_row, start_col, end_row, end_col, {})

	return table.concat(lines, "\n")
end

function M.get_node_title(node)
	if not string.match(node:type(), "heading%d") then
		return nil
	end

	local end_row, end_col = node:end_()
	local eof_row = vim.api.nvim_buf_line_count(0)
	if end_row >= eof_row then
		end_row = eof_row - 1
		end_col = -1
	end

	local start_row, start_col = node:start()
	if start_row >= eof_row then
		return nil
	end
	end_row = start_row + 1 -- TODO: fix this hack

	local lines = vim.api.nvim_buf_get_text(0, start_row, start_col, end_row, end_col, {})

	return table.concat(lines, "\n")
end

--------------------

if true then
	-- local meta_root = M.get_meta_root()
	-- local doc_root = M.get_doc_root()
	-- local is_mindnode = M.is_mindnode_file()
	-- print(meta_root, doc_root, is_mindnode)

	local query = neorg.utils.ts_parse_query(
		"norg",
		[[
      (heading1
        (heading1_prefix) @prefix
        (#eq? @prefix "*")
      )
    ]]
	)

	-- Lang tree
	local lang_tree = vim.treesitter.get_parser(0, "norg")
	print("Lang tree: ", lang_tree)
	print("Lang tree type: ", type(lang_tree))

	-- Lang tree -> TS tree table
	local ts_tree_table = lang_tree:parse()
	print("Lang tree table: ", ts_tree_table)
	print("Lang tree table type: ", type(ts_tree_table))

	-- TS tree table -> TS tree
	local first_ts_tree = ts_tree_table[1]
	print("First TS tree: ", first_ts_tree)
	print("First TS tree type: ", type(first_ts_tree))
	-- local second_ts_tree = ts_tree_table[2]
	-- print("Second TS tree: ", second_ts_tree)
	-- print("Second TS tree type: ", type(second_ts_tree))

	-- TS tree -> TS node
	local root_node = first_ts_tree:root()
	print("Root node: ", root_node)
	print("Root node type: ", type(root_node))

	-- TS node -> Children
	local children = root_node:iter_children()
	for child in children do
		print("-----")
		if child:type() == "heading1" then
			print("Heading1 title: ", M.get_node_title(child))
			print("Heading1 content: ", M.get_node_content(child))
			-- print("Heading1 content: ", M.get_node_content(child))
		end
		print("-----")
		-- print("Child: ", child)
		-- print("Child type: ", type(child))
		for _c in child:iter_children() do
			-- print("Child child child: ", _c)
			-- print("Child child type: ", type(_c))
			-- if _c:type() == "heading2" then
			-- 	print("Heading2 prefix: ", _c)
			-- 	print("Heading2 prefix type: ", type(_c))
			-- end
		end
	end
end

return M
