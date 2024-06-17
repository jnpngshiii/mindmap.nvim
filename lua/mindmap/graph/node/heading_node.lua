local utils = require("mindmap.utils")
local ts_utils = require("mindmap.ts_utils")

--------------------
-- Class HeadingNode
--------------------

---@class HeadingNode : PrototypeNode
---@field after_add_into_graph fun(self: HeadingNode) Extra function to run after adding the node into the graph.
---@field after_remove_from_graph fun(self: HeadingNode) Extra function to run after removing the node from the graph.
---@field get_content fun(self: HeadingNode, edge_type: EdgeType): string[], string[] Get the content of the node.
local HeadingNode = {
	data = {},
	ins_methods = {},
	cls_methods = {},
}

--------------------
-- Instance methods
--------------------

---Extra function to run after adding the node into the graph.
---@param self HeadingNode The node.
function HeadingNode.ins_methods.after_add_into_graph(self)
	-- Use cache
	if type(self.cache.ts_node) == "userdata" and type(self.cache.ts_node_bufnr) == "number" then
		local ts_node_title, _, _ = ts_utils.parse_heading_node(self.cache.ts_node)
		local node_text = vim.treesitter.get_node_text(ts_node_title, 0)
		ts_utils.replace_node_text(
			string.gsub(node_text, "$", " %%" .. string.format("%08d", self.id) .. "%%"),
			ts_node_title,
			self.cache.ts_node_bufnr
		)
	end

	-- TODO: add else
end

---Extra function to run after removing the node from the graph.
---@param self HeadingNode The node.
function HeadingNode.ins_methods.after_remove_from_graph(self)
	-- Use cache
	if type(self.cache.ts_node) == "userdata" and type(self.cache.ts_node_bufnr) == "number" then
		local ts_node_title, _, _ = ts_utils.parse_heading_node(self.cache.ts_node)
		local node_text = vim.treesitter.get_node_text(ts_node_title, 0)
		ts_utils.replace_node_text(
			string.gsub(node_text, " %%" .. string.format("%08d", self.id) .. "%%", ""),
			ts_node_title,
			self.cache.ts_node_bufnr
		)

		return
	end

	local abs_path = self:get_abs_path()
	local bufnr, is_temp_buf = utils.get_bufnr(abs_path, true)
	local ts_node = ts_utils.get_heading_node_by_id(self.id, bufnr)
	if not ts_node then
		vim.notify("Can not find the tree-sitter node with id: " .. self.id .. ". Aborted.", vim.log.levels.ERROR)
		return
	end

	local ts_node_title, _, _ = ts_utils.parse_heading_node(ts_node)

	local node_text = vim.treesitter.get_node_text(ts_node_title, 0)
	ts_utils.replace_node_text(
		string.gsub(node_text, " %%" .. string.format("%08d", self.id) .. "%%", ""),
		ts_node_title,
		bufnr
	)

	if is_temp_buf then
		vim.api.nvim_buf_delete(bufnr, { force = true })
	end
end

---Get the content of the node.
---@param self HeadingNode The node.
---@param edge_type EdgeType Type of the edge.
---@return string[] front ,string[] back Content of the node.
---@diagnostic disable-next-line: unused-local
function HeadingNode.ins_methods.get_content(self, edge_type)
	local front, back = {}, {}

	local abs_proj_path = utils.get_file_info()[4]
	local abs_file_path = utils.get_abs_path(self.rel_file_path, abs_proj_path)
	local bufnr, is_temp_buf = utils.get_bufnr(abs_file_path .. "/" .. self.file_name, true)
	local heading_node = ts_utils.get_heading_node_by_id(self.id, bufnr)

	if not heading_node then
		return front, back
	end
	local title_node, content_node, sub_heading_nodes = ts_utils.parse_heading_node(heading_node)

	if title_node then
		front = utils.split_string(vim.treesitter.get_node_text(title_node, bufnr), "\n")
	end

	if content_node and edge_type == "SelfLoopContentEdge" then
		back = utils.split_string(vim.treesitter.get_node_text(content_node, bufnr), "\n")
	elseif content_node and edge_type == "SelfLoopSubheadingEdge" then
		for _, sub_heading_node in ipairs(sub_heading_nodes) do
			table.insert(back, utils.split_string(vim.treesitter.get_node_text(sub_heading_node, bufnr), "\n")[1])
		end
	end

	if is_temp_buf then
		vim.api.nvim_buf_delete(bufnr, { force = true })
	end

	return front, back
end

--------------------
-- Class methods
--------------------

--------------------

return HeadingNode
