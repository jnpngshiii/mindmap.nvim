-- local neorg = require("neorg.core")
local ts_utils = require("nvim-treesitter.ts_utils")

local misc = require("mindmap.misc")

---@alias ts_node any|userdata
---@alias ts_tree any|userdata

local M = {}

--------------------
-- Tree
--------------------

---Get the root node of the neorg meta tree.
---@param bufnr? integer The buffer number.
---@return ts_node
function M.get_neorg_meta_root(bufnr)
	bufnr = bufnr or 0

	local lang_tree = vim.treesitter.get_parser(bufnr, "norg")
	if not lang_tree then
		return nil
	end

	for _, ts_tree in pairs(lang_tree:children()) do
		if ts_tree:lang() == "norg_meta" then
			local neorg_meta_tree = ts_tree:parse()[1]
			if neorg_meta_tree then
				return neorg_meta_tree:root()
			end
		end
	end

	return nil
end

---Get the root node of the neorg document tree.
---@param bufnr? integer The buffer number.
---@return ts_node
function M.get_neorg_doc_root(bufnr)
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

---Get the mindmap id of the given buffer.
---If the id is not found and register_if_not is true, then generate, register and return a new id.
---@param bufnr? integer The buffer number.
---@param register_if_not? boolean Register a new id if not found.
---@return string|nil
function M.get_buf_mindmap_id(bufnr, register_if_not)
	bufnr = bufnr or 0

	local meta_root = M.get_neorg_meta_root(bufnr)
	if not meta_root then
		return nil
	end

	local query = vim.treesitter.query.parse(
		"norg_meta",
		[[
      (pair
        (key) @key
        (#eq? @key "mindmap")
        (value) @value
      )
    ]]
	)

	local id
	for index, node in query:iter_captures(meta_root, 0) do
		if query.captures[index] == "value" then
			id = M.get_node_text(node)
		end
	end

	if not id and register_if_not then
		id = "mindmap-" .. misc.get_unique_id()
		local _, _, end_row, _ = meta_root:range()
		vim.api.nvim_buf_set_lines(bufnr, end_row, end_row + 1, false, { "mindmap: " .. id, "@end" })
		-- FIXME: 如何光标恰好在 end_row + 1, 会导致插入异常
	end

	return id
end

--------------------
-- Node
--------------------

---Replace the text of a node.
---@param text string|table<string>
---@param node ts_node
---@param bufnr? integer The buffer number.
---@return nil
function M.replace_node_text(text, node, bufnr)
	if type(text) == "string" then
		text = { text }
	end
	bufnr = bufnr or 0

	local start_row, start_col, end_row, end_col = node:range()
	vim.api.nvim_buf_set_text(0, start_row, start_col, end_row, end_col, text)
end

---Get the text of a node.
---@param node ts_node
---@param bufnr? integer The buffer number.
---@return string
function M.get_node_text(node, bufnr)
	bufnr = bufnr or 0
	return vim.treesitter.get_node_text(node, bufnr)
end

---Get the title and content node of the given heading node.
---@param node ts_node The heading node.
---@param bufnr? integer The buffer number.
---@return ts_node[] # { title_node, content_node? }
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
---@return ts_node[]
function M.get_subheading_nodes(node, bufnr)
	-- TODO: Implement this function.
	return {}
end

--------------------
-- Current Node
--------------------

---Get the nearest heading node at the cursor.
---@return ts_node
function M.get_nearest_heading_node()
	local current_node = ts_utils.get_node_at_cursor()

	while not current_node:type():match("^heading%d$") do
		current_node = current_node:parent()
	end

	return current_node
end

---Get the nearest heading node level at the cursor.
---@return string
function M.get_nearest_heading_node_level()
	local nearest_heading_node = M.get_nearest_heading_node()
	local level = string.match(nearest_heading_node:type(), "^heading(%d)$")
	return level
end

---Get the nearest heading node id at the cursor.
---If the id is not found and register_if_not is true, then generate, register and return a new id.
---@param register_if_not? boolean Register a new id if not found.
---@return string|nil
function M.get_nearest_heading_node_id(register_if_not)
	local nearest_heading_node = M.get_nearest_heading_node()
	local nhn_title_node = M.get_title_and_content_node(nearest_heading_node)[1]
	local nhn_title = M.get_node_text(nhn_title_node)

	local nhn_id = string.match(nhn_title, "mnode-%d%d%d%d%d%d%d%d%d%d-%d%d%d%d")
	-- TODO: Warn user if multiple ids are found.
	if not nhn_id and register_if_not then
		nhn_id = "mindnode-" .. misc.get_unique_id()
		M.replace_node_text(nhn_title .. " %" .. nhn_id .. "%", nhn_title_node)
	end

	return nhn_id
end

--------------------

if false then
	print("-----Start")
	print(M.get_nearest_heading_node_id())

	local nearest_heading_node = M.get_nearest_heading_node()
	local parsed_query = vim.treesitter.query.parse(
		"norg",
		[[
      (_
        title: (paragraph_segment
          (inline_comment)?
        )
        content: (paragraph)?
      ) @heading
    ]]
	)

	-- for _, node in parsed_query:iter_captures(nearest_heading_node, 0) do
	-- 	local title = M.get_node_text(node)
	-- end
	print("-----")
end

if false then
	print("-----Start")
	local id = M.get_buf_mindmap_id(0, true)
	print(id)
	print("-----")
end

return M
