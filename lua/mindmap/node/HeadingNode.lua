local utils = require("mindmap.utils")
local ts_utils = require("mindmap.ts_utils")

--------------------
-- Class HeadingNode
--------------------

---@class HeadingNode : BaseNode
---@field _cache.ts_node userdata|nil See: `HeadingNode.get_ts_node`.
---@field _cache.ts_node_bufnr number|nil See: `HeadingNode.get_ts_node`.
local HeadingNode = {}

----------
-- Basic Method
----------

---Get the treesitter node and its buffer number of the `HeadingNode`.
---@return TSNode ts_node, number ts_node_bufnr Treesitter node and its buffer number.
function HeadingNode:get_ts_node()
	if self._cache.ts_node and type(self._cache.ts_node) == "userdata" then
		return self._cache.ts_node, self._cache.ts_node_bufnr
	end
	local ts_node, ts_node_bufnr

	local bufnr, is_temp_buf = utils.get_bufnr(self:get_abs_path(), true)
	local heading_node = ts_utils.get_heading_nodes(self._id, bufnr)[self._id]
	if not heading_node then
		vim.notify(
			"[HeadingNode] Can not find the treesitter node with id: `" .. self._id .. "`. Abort getting.",
			vim.log.levels.ERROR
		)
		return ts_node, ts_node_bufnr
	end

	if is_temp_buf then
		vim.api.nvim_buf_delete(bufnr, { force = true })
	else
		self._cache.ts_node = heading_node
		self._cache.ts_node_bufnr = bufnr
	end
	return ts_node, ts_node_bufnr
end

---Get the content of the node.
---@param edge_type EdgeType Type of the edge.
---@return string[] front, string[] back Content of the node.
---@diagnostic disable-next-line: unused-local
function HeadingNode:get_content(edge_type)
	local front, back = {}, {}

	local bufnr, is_temp_buf = utils.get_bufnr(self:get_abs_path(), true)
	local heading_node = ts_utils.get_heading_node_by_id(self._id, bufnr) -- TODO: UPDATE
	if not heading_node then
		return {}, {}
	end

	local title_node, content_node, sub_heading_nodes = ts_utils.parse_heading_node(heading_node)
	front = utils.split_string(vim.treesitter.get_node_text(title_node, bufnr), "\n")
	if not content_node and not #sub_heading_nodes then
		back = { "[Error] Can not find content_node or sub_heading_nodes." }
	end

	if content_node and edge_type == "SelfLoopContentEdge" then
		back = utils.split_string(vim.treesitter.get_node_text(content_node, bufnr), "\n")
	elseif sub_heading_nodes and edge_type == "SelfLoopSubheadingEdge" then
		for _, sub_heading_node in ipairs(sub_heading_nodes) do
			table.insert(back, utils.split_string(vim.treesitter.get_node_text(sub_heading_node, bufnr), "\n")[1])
		end
	end

	if is_temp_buf then
		vim.api.nvim_buf_delete(bufnr, { force = true })
	end

	return front, back
end

----------
-- Graph Method
----------

---Handle the node after adding into the graph.
---@return nil _ This function does not return anything.
function HeadingNode:after_add_into_graph()
	-- Use cache
	if type(self._cache.ts_node) == "userdata" and type(self._cache.ts_node_bufnr) == "number" then
		local ts_node_title, _, _ = ts_utils.parse_heading_node(self._cache.ts_node)
		local node_text = vim.treesitter.get_node_text(ts_node_title, 0)
		ts_utils.replace_node_text(
			string.gsub(node_text, "$", " %%" .. string.format("%08d", self._id) .. "%%"),
			ts_node_title,
			self._cache.ts_node_bufnr
		)
	end

	-- TODO: add else
end

---Handle the node before removing from the graph.
---@return nil _ This function does not return anything.
function HeadingNode:before_remove_from_graph()
	-- Use cache
	if type(self._cache.ts_node) == "userdata" and type(self._cache.ts_node_bufnr) == "number" then
		local ts_node_title, _, _ = ts_utils.parse_heading_node(self._cache.ts_node)
		local node_text = vim.treesitter.get_node_text(ts_node_title, 0)
		ts_utils.replace_node_text(
			string.gsub(node_text, " %%" .. string.format("%08d", self._id) .. "%%", ""),
			ts_node_title,
			self._cache.ts_node_bufnr
		)

		return
	end

	local abs_path = self:get_abs_path()
	local bufnr, is_temp_buf = utils.get_bufnr(abs_path, true)
	local ts_node = ts_utils.get_heading_node_by_id(self._id, bufnr)
	if not ts_node then
		vim.notify("Can not find the treesitter node with id: " .. self._id .. ". Aborted.", vim.log.levels.ERROR)
		return
	end

	local ts_node_title, _, _ = ts_utils.parse_heading_node(ts_node)

	local node_text = vim.treesitter.get_node_text(ts_node_title, 0)
	ts_utils.replace_node_text(
		string.gsub(node_text, " %%" .. string.format("%08d", self._id) .. "%%", ""),
		ts_node_title,
		bufnr
	)

	if is_temp_buf then
		vim.api.nvim_buf_delete(bufnr, { force = true })
	end
end

--------------------

return HeadingNode
