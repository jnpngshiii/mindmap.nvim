local ts_utils = {}

---Get the root node in the given buffer.
---@param bufnr? integer The buffer number. Default: `0`.
---@return TSNode? root_node The root node of the buffer.
function ts_utils.get_root_node(bufnr)
	bufnr = bufnr or 0

	local lang_tree = vim.treesitter.get_parser(bufnr, "norg")
	if not lang_tree then
		vim.notify("[TSUtils] Cannot get norg tree in the given buffer", vim.log.levels.ERROR)
		return
	end

	local neorg_doc_tree = lang_tree:parse()[1]
	if not neorg_doc_tree then
		vim.notify("[TSUtils] Cannot parse norg tree in the given buffer", vim.log.levels.ERROR)
		return
	end

	return neorg_doc_tree:root()
end

---Get all heading nodes matched the given id in the given buffer.
---@param id? string The id of the heading node. Default: `%d%d%d%d%d%d%d%d`.
---@param bufnr? integer The buffer number. Default: `0`.
---@return table<NodeID, TSNode> heading_nodes The table of heading nodes indexed by their IDs.
function ts_utils.get_heading_nodes(id, bufnr)
	id = id or "%d%d%d%d%d%d%d%d"
	bufnr = bufnr or 0
	local heading_nodes = {}

	local root_node = ts_utils.get_root_node(bufnr)
	if not root_node then
		return heading_nodes
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

	for _, heading_node in parsed_query:iter_captures(root_node, 0) do
		local title_node, _, _ = ts_utils.parse_heading_node(heading_node)
		if not title_node then
			goto continue
		end

		local title_node_text = vim.treesitter.get_node_text(title_node, bufnr)
		if not title_node_text then
			goto continue
		end

		-- Just handle the first match.
		local heading_node_id = tonumber(string.match(title_node_text, "%%" .. id .. "%%"))
		if heading_node_id then
			heading_nodes[heading_node_id] = heading_node
		end

		::continue::
	end

	return heading_nodes
end

---Get the title node, content node, and sub heading nodes in the given heading node.
---@param heading_node TSNode The heading node to parse.
---@return TSNode? title_node, TSNode? content_node, TSNode[] sub_heading_nodes The title node, content node, and sub heading nodes.
function ts_utils.parse_heading_node(heading_node)
	local title_node, content_node, sub_heading_nodes = nil, nil, {}

	local sub_heading_level = tonumber(string.match(heading_node:type(), "%d")) + 1
	if not sub_heading_level then
		vim.notify(
			string.format("[TSUtils] Node `%s` is not a heading node. Aborting parsing.", heading_node:type()),
			vim.log.levels.ERROR
		)
		return title_node, content_node, sub_heading_nodes
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

	for index, sub_node in parsed_query:iter_captures(heading_node, 0) do
		if parsed_query.captures[index] == "title" then
			-- Only add the first content node.
			title_node = title_node or sub_node
		elseif parsed_query.captures[index] == "content" then
			-- Only add the first content node.
			content_node = content_node or sub_node
		elseif parsed_query.captures[index] == "sub_heading" then
			table.insert(sub_heading_nodes, sub_node)
		end
	end

	return title_node, content_node, sub_heading_nodes
end

---Replace the text of the given treesitter node.
---@param text string|string[] The text used to replace the node text. Each element of the array is a line.
---@param node TSNode The treesitter node to replace.
---@param bufnr? integer The buffer number. Default: `0`.
---@return nil
function ts_utils.replace_node_text(text, node, bufnr)
	if type(text) == "string" then
		text = { text }
	end
	bufnr = bufnr or 0

	local start_row, start_col, end_row, end_col = node:range()
	vim.api.nvim_buf_set_text(bufnr, start_row, start_col, end_row, end_col, text)
end

--------------------

return ts_utils
