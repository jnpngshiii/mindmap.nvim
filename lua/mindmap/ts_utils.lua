local ts_utils = require("nvim-treesitter.ts_utils")

---@alias ts_node userdata
---@alias ts_tree userdata

local M = {}

--------------------
-- Functions that return tree-sitter nodes.
--------------------

---Get the root node of the tree-sitter tree in the given buffer.
---@param bufnr? integer The buffer number. Default: 0.
---@return ts_node? _ The root node of the tree-sitter tree in the given buffer.
function M.get_tstree_root(bufnr)
	bufnr = bufnr or 0

	local lang_tree = vim.treesitter.get_parser(bufnr, "norg")
	if not lang_tree then
		return nil
	end

	local neorg_doc_tree = lang_tree:parse()[1]
	if neorg_doc_tree then
		return neorg_doc_tree:root()
	end

	return nil
end

---Get the nearest heading node according to the cursor.
---@return ts_node _ The nearest heading node according to the cursor.
function M.get_nearest_heading_node()
	local current_node = ts_utils.get_node_at_cursor()

	while not current_node:type():match("^heading%d$") do
		current_node = current_node:parent()
	end

	return current_node
end

---Get subheading nodes of the given heading node.
---@param heading_node ts_node The heading node.
---@param bufnr? integer The buffer number. Default: 0.
---@return ts_node[] _ The subheading nodes of the given heading node.
function M.get_subheading_nodes(heading_node, bufnr)
	-- TODO: Implement this function.
	return {}
end

--------------------
-- Functions that process tree-sitter nodes.
--------------------

---Replace the text of the given tree-sitter node.
---@param text string|string[] The new text. Each element is a line.
---@param node ts_node The node whose text will be replaced.
---@param bufnr? integer The buffer number. Default: 0.
---@return nil _ This function does not return anything.
function M.replace_node_text(text, node, bufnr)
	bufnr = bufnr or 0

	if type(text) == "string" then
		text = { text }
	end

	local start_row, start_col, end_row, end_col = node:range()
	vim.api.nvim_buf_set_text(0, start_row, start_col, end_row, end_col, text)
end

---Get the information of the given heading node.
---@param heading_node ts_node The heading node.
---@param bufnr? integer The buffer number. Default: 0.
---@return table _ { id, level, text }
function M.get_heading_node_info(heading_node, bufnr)
	bufnr = bufnr or 0

	local text = vim.treesitter.get_node_text(heading_node, bufnr)
	local id = string.match(text, "%d%d%d%d%d%d%d%d%d%d-%d%d%d%d")
	local level = string.match(heading_node:type(), "^heading(%d)$")

	return { id, level, text }
end

---Get the title node and content node of the given heading node.
---@param heading_node ts_node The heading node.
---@param bufnr? integer The buffer number. Default: 0.
---@return ts_node[] _ { title_node, content_node? }
function M.get_title_and_content_node(heading_node, bufnr)
	bufnr = bufnr or 0

	local parsed_query = vim.treesitter.query.parse(
		"norg",
		[[
      title: (paragraph_segment
        (inline_comment)?
      ) @title
      content: (paragraph)? @content
    ]]
	)

	local result = {}
	for index, sub_node in parsed_query:iter_captures(heading_node, 0) do
		if parsed_query.captures[index] == "title" then
			table.insert(result, sub_node)
		elseif parsed_query.captures[index] == "content" then
			table.insert(result, sub_node)
		else
		end
	end

	return result
end

--------------------

return M
