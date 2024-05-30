local ts_utils = require("nvim-treesitter.ts_utils")

local utils = require("mindmap.utils")

local M = {}

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

---Replace the text of a given tree-sitter node.
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

---Get the title and content node of the given heading node.
---@param node ts_node The heading node.
---@param bufnr? integer The buffer number.
---@return ts_node[] _ { title_node, content_node? }
function M.get_title_and_content_node(node, bufnr)
	if not string.match(node:type(), "^heading%d$") then
		return {}
	end

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
	for index, sub_node in parsed_query:iter_captures(node, 0) do
		if parsed_query.captures[index] == "title" then
			table.insert(result, sub_node)
		elseif parsed_query.captures[index] == "content" then
			table.insert(result, sub_node)
		else
		end
	end

	return result
end

---Get subheading nodes of the given heading node.
---@param node ts_node The heading node.
---@param bufnr? integer The buffer number.
---@return ts_node[] _
function M.get_subheading_nodes(node, bufnr)
	-- TODO: Implement this function.
	return {}
end

---Get the nearest heading node at the cursor.
---@return ts_node _
function M.get_nearest_heading_node()
	local current_node = ts_utils.get_node_at_cursor()

	while not current_node:type():match("^heading%d$") do
		current_node = current_node:parent()
	end

	return current_node
end

---Get the nearest heading node level at the cursor.
---@return string _
function M.get_nearest_heading_node_level()
	local nearest_heading_node = M.get_nearest_heading_node()
	local level = string.match(nearest_heading_node:type(), "^heading(%d)$")
	return level
end

---Get the nearest heading node id at the cursor.
---If the id is not found and register_if_not is true, then generate, register and return a new id.
---@param register_if_not? boolean Register a new id if not found.
---@return string? _
function M.get_nearest_heading_node_id(register_if_not)
	local nearest_heading_node = M.get_nearest_heading_node()
	local nhn_title_node = M.get_title_and_content_node(nearest_heading_node)[1]
	local nhn_title = M.get_node_text(nhn_title_node)

	local nhn_id = string.match(nhn_title, "mnode-%d%d%d%d%d%d%d%d%d%d-%d%d%d%d")
	-- TODO: Warn user if multiple ids are found.
	if not nhn_id and register_if_not then
		nhn_id = "mindnode-" .. utils.get_unique_id()
		M.replace_node_text(nhn_title .. " %" .. nhn_id .. "%", nhn_title_node)
	end

	return nhn_id
end

--------------------
-- Deprecated Functions
--------------------

---@deprecated
---Get the text of a given tree-sitter node.
---@param node ts_node The node whose text will be returned.
---@param bufnr? integer The buffer number. Default: 0.
---@return string _ The text of the given tree-sitter node.
function M.get_node_text(node, bufnr)
	bufnr = bufnr or 0

	return vim.treesitter.get_node_text(node, bufnr)
end

--------------------

return M
