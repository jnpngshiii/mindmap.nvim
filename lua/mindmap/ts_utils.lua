local nts_utils = require("nvim-treesitter.ts_utils")

local utils = require("mindmap.utils")

local M = {}

--------------------
-- Functions that return tree-sitter nodes.
--------------------

---Get the root node of the tree-sitter tree in the given buffer or file path.
---@param bufnr_or_file_path? integer|string The buffer number or file path.
---@return TSNode? _ The root node of the tree-sitter tree in the given buffer or file path.
function M.get_tstree_root(bufnr_or_file_path)
	local bufnr, is_temp_buf = utils.get_bufnr(bufnr_or_file_path)

	local lang_tree = vim.treesitter.get_parser(bufnr, "norg")
	if not lang_tree then
		return nil
	end

	local neorg_doc_tree = lang_tree:parse()[1]
	if neorg_doc_tree then
		return neorg_doc_tree:root()
	end

	if is_temp_buf then
		vim.api.nvim_buf_delete(bufnr, { force = true })
	end

	return nil
end

---Get the nearest heading node according to the cursor.
---If node_id is given, return the nearest heading node with the id.
---If node_id is not given, return the nearest heading node.
---@param node_id? NodeID The id of the heading node.
---@return TSNode? _ The nearest heading node according to the cursor.
function M.get_nearest_heading_node(node_id)
	local current_node = nts_utils.get_node_at_cursor()

	local ok
	while current_node and not current_node:type():match("^heading%d$") and not ok do
		current_node = current_node:parent()
		if node_id and current_node then
			ok = node_id == M.get_heading_node_info(current_node, 0)
		end
	end

	return current_node
end

---Get the heading node with id in the given buffer or file path.
---@param node_id NodeID The id of the heading node.
---@param bufnr_or_file_path? integer|string The buffer number or file path.
---@return TSNode? _ The heading node with id in the given buffer or file path.
function M.get_heading_node_using_id(node_id, bufnr_or_file_path)
	local bufnr, is_temp_buf = utils.get_bufnr(bufnr_or_file_path)
	local root_node = M.get_tstree_root(bufnr)
	if not root_node then
		return nil
	end

	local parsed_heading_node_query = vim.treesitter.query.parse(
		"norg",
		[[
    (_
      title: (paragraph_segment
        (inline_comment)
      )
    ) @heading_node
    ]]
	)

	local parsed_inline_comment_query = vim.treesitter.query.parse(
		"norg",
		[[
    title: (paragraph_segment
      (inline_comment) @inline_comment
    )
    ]]
	)

	-- Get heading nodes.
	for _, heading_node in parsed_heading_node_query:iter_captures(root_node, 0) do
		-- Get inline comment nodes.
		for _, inline_comment_node in parsed_inline_comment_query:iter_captures(heading_node, 0) do
			local inline_comment = vim.treesitter.get_node_text(inline_comment_node, bufnr)
			if string.match(inline_comment, string.format("%08d", node_id)) then
				return heading_node
			end
		end
	end

	if is_temp_buf then
		vim.api.nvim_buf_delete(bufnr, { force = true })
	end

	return nil
end

--------------------
-- Functions that process tree-sitter nodes.
--------------------

---Replace the text of the given tree-sitter node.
---@param text string|string[] The new text. Each element is a line.
---@param node TSNode The tree-sitter node.
---@param bufnr integer The buffer number.
---@return nil _ This function does not return anything.
function M.replace_node_text(text, node, bufnr)
	if type(text) == "string" then
		text = { text }
	end
	-- table.insert(text, "") -- TODO: Remove this workaround.

	local start_row, start_col, end_row, end_col = node:range()
	vim.api.nvim_buf_set_text(bufnr, start_row, start_col, end_row, end_col, text)
end

---Get the information of the given heading node.
---@param heading_node TSNode The heading node.
---@param bufnr integer The buffer number.
---@return EdgeID? id, integer? level, string text The id, level, and text of the heading node.
function M.get_heading_node_info(heading_node, bufnr)
	local text = vim.treesitter.get_node_text(heading_node, bufnr)
	local id = tonumber(string.match(text, "%d%d%d%d%d%d%d%d"))
	local level = tonumber(string.match(heading_node:type(), "^heading(%d)$"))

	return id, level, text
end

---Get the title / content / sub heading nodes of the given heading node.
---@param heading_node TSNode The heading node.
---@return TSNode? title_node, TSNode? content_node, TSNode[] sub_heading_nodes The title node, content node, and sub heading nodes.
---TODO: just process given heading node.
function M.get_sub_nodes(heading_node)
	local sub_heading_level = tonumber(string.match(heading_node:type(), "%d")) + 1
	local sub_heading_type = "heading" .. sub_heading_level

	local parsed_query = vim.treesitter.query.parse(
		"norg",
		string.format(
			[[
        title: (paragraph_segment) @title
        content: (paragraph) @content
        content: (%s) @sub_heading
      ]],
			sub_heading_type
		)
	)

	local title_node
	local content_node
	local sub_heading_nodes = {}

	for index, sub_node in parsed_query:iter_captures(heading_node, 0) do
		if parsed_query.captures[index] == "title" then
			-- Only add the first content node.
			title_node = title_node or sub_node
		elseif parsed_query.captures[index] == "content" then
			-- Only add the first content node.
			content_node = content_node or sub_node
		elseif parsed_query.captures[index] == "sub_heading" then
			table.insert(sub_heading_nodes, sub_node)
		else
		end
	end

	return title_node, content_node, sub_heading_nodes
end

--------------------

return M
