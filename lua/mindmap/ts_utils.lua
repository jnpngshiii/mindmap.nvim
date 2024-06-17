local ts_utils = {}

---Get the root node in the given buffer.
---@param bufnr? integer The buffer number.
---@return TSNode? _ The root node in the given buffer.
function ts_utils.get_root_node(bufnr)
	bufnr = bufnr or 0

	local lang_tree = vim.treesitter.get_parser(bufnr, "norg")
	if not lang_tree then
		vim.notify("Can not get norg tree in the given buffer", vim.log.levels.ERROR)
		return nil
	end

	local neorg_doc_tree = lang_tree:parse()[1]
	if not neorg_doc_tree then
		vim.notify("Can not parse norg tree in the given buffer", vim.log.levels.ERROR)
		return nil
	end

	return neorg_doc_tree:root()
end

---Get the title node, content node, and sub heading nodes of the given heading node.
---@param heading_node TSNode The heading node.
---@return TSNode title_node, TSNode? content_node, TSNode[] sub_heading_nodes The title node, content node, and sub heading nodes.
function ts_utils.parse_heading_node(heading_node)
	local sub_heading_level = tonumber(string.match(heading_node:type(), "%d")) + 1
	if not sub_heading_level then
		vim.notify("Node `" .. heading_node:type() .. "` is not a heading node.", vim.log.levels.ERROR)
	end

	local parsed_query = vim.treesitter.query.parse(
		"norg",
		string.format(
			[[
        title: (paragraph_segment) @title
        content: (paragraph) @content
        content: (%s) @sub_heading
      ]],
			"heading" .. sub_heading_level
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

---Get all heading nodes which have an id in the given buffer.
---@param bufnr? integer The buffer number.
---@return table<NodeID, TSNode> heading_nodes The heading nodes.
function ts_utils.get_heading_node_in_buf(bufnr)
	bufnr = bufnr or 0

	local root_node = ts_utils.get_root_node(bufnr)
	if not root_node then
		return {}
	end

	local parsed_query = vim.treesitter.query.parse(
		"norg",
		[[
      (_
        title: (paragraph_segment
          (inline_comment)
        )
      ) @heading_node
    ]]
	)

	local heading_nodes = {}
	for _, heading_node in parsed_query:iter_captures(root_node, 0) do
		local title_node, _, _ = ts_utils.parse_heading_node(heading_node)
		local title_node_text = vim.treesitter.get_node_text(title_node, bufnr)
		-- TODO: handle multiple matches.
		-- Just handle the first match now.
		local heading_node_id = tonumber(string.match(title_node_text, "%d%d%d%d%d%d%d%d"))
		if heading_node_id then
			heading_nodes[heading_node_id] = heading_node
		end
	end

	return heading_nodes
end

---Get the heading node by the given id.
---@param id NodeID The id of the heading node.
---@param bufnr? integer The buffer number.
---@return TSNode? _ The heading node.
function ts_utils.get_heading_node_by_id(id, bufnr)
	bufnr = bufnr or 0

	local heading_nodes = ts_utils.get_heading_node_in_buf(bufnr)
	return heading_nodes[id]
end

---Replace the text of the given tree-sitter node.
---@param text string|string[] The new text. Each element is a line.
---@param node TSNode The tree-sitter node.
---@param bufnr? integer The buffer number.
---@return nil _ This function does not return anything.
function ts_utils.replace_node_text(text, node, bufnr)
	if type(text) == "string" then
		text = { text }
	end
	-- table.insert(text, "") -- TODO: Remove this workaround.

	bufnr = bufnr or 0

	local start_row, start_col, end_row, end_col = node:range()
	vim.api.nvim_buf_set_text(bufnr, start_row, start_col, end_row, end_col, text)
end

--------------------

return ts_utils
