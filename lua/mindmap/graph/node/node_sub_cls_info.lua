local utils = require("mindmap.utils")
local ts_utils = require("mindmap.ts_utils")

--------------------
-- Default Sub Node Class
--------------------

local default_node_sub_cls = {}

----------
-- SimpleNode
----------

---@class SimpleNode : PrototypeNode

default_node_sub_cls.SimpleNode = {
	data = {
		--
	},
	ins_methods = {
		--
	},
	cls_methods = {
		--
	},
}

----------
-- ExcerptNode
----------

---@class ExcerptNode : PrototypeNode
---@field data.start_row integer Start row of the excerpt.
---@field data.start_col integer Start column of the excerpt.
---@field data.end_row integer End row of the excerpt.
---@field data.end_col integer End column of the excerpt.

default_node_sub_cls.ExcerptNode = {
	data = {
		start_row = 0,
		end_row = 0,
		start_col = 0,
		end_col = 0,
	},
	ins_methods = {
		---Get the content of the node.
		---@param edge_type EdgeType Type of the edge.
		---@return string[] front ,string[] back Content of the node.
		---@diagnostic disable-next-line: unused-local
		get_content = function(self, edge_type)
			local abs_proj_path = utils.get_file_info()[4]
			local abs_file_path = utils.get_abs_path(self.rel_file_path, abs_proj_path)

			local excerpt = utils.get_file_content(
				abs_file_path .. "/" .. self.file_name,
				self.data.start_row,
				self.data.end_row,
				self.data.start_col,
				self.data.end_col
			)

			return excerpt, excerpt
		end,
	},
	cls_methods = {
		---Create a new excerpt node using the latest visual selection.
		---@param id NodeID ID of the node.
		---@return ExcerptNode _ The created node.
		---@diagnostic disable-next-line: unused-local
		create_using_latest_visual_selection = function(cls, self, id)
			-- FIXME: The first call will return { 0, 0 } for both marks
			local start_row = vim.api.nvim_buf_get_mark(0, "<")[1]
			local start_col = vim.api.nvim_buf_get_mark(0, "<")[2]
			local end_row = vim.api.nvim_buf_get_mark(0, ">")[1]
			local end_col = vim.api.nvim_buf_get_mark(0, ">")[2]

			local file_name, _, rel_file_path, _ = unpack(utils.get_file_info())
			return cls:new(id, file_name, rel_file_path, {
				start_row = start_row,
				start_col = start_col,
				end_row = end_row,
				end_col = end_col,
			})
		end,
	},
}

--------------------
-- HeadingNode
--------------------

---@class HeadingNode : PrototypeNode

default_node_sub_cls.HeadingNode = {
	data = {
		--
	},
	ins_methods = {
		---Manage the id of the node in the text.
		---@param action string Action to be taken. Can be 'add' or 'remove'.
		---@return nil _ This function does not return anything.
		manage_text_id = function(self, action)
			if action ~= "add" and action ~= "remove" then
				vim.notify("Invalid action: " .. action .. ". Action must be 'add' or 'remove'.")
				return
			end

			local ts_node, bufnr, is_temp_buf = self:get_corresponding_ts_node()
			local ts_node_title, _, _ = ts_utils.parse_heading_node(ts_node)

			if action == "add" then
				local node_text = vim.treesitter.get_node_text(ts_node_title, 0)
				ts_utils.replace_node_text(
					string.gsub(node_text, "%$", " %%" .. string.format("%08d", self.id) .. "%%"),
					ts_node_title,
					bufnr
				)
			end
			if action == "remove" then
				local node_text = vim.treesitter.get_node_text(ts_node_title, 0)
				ts_utils.replace_node_text(
					string.gsub(node_text, " %%" .. string.format("%08d", self.id) .. "%%", ""),
					ts_node_title,
					bufnr
				)
			end

			if is_temp_buf then
				vim.api.nvim_buf_delete(bufnr, { force = true })
			end
		end,

		---Get the content of the node.
		---@param edge_type EdgeType Type of the edge.
		---@return string[] front ,string[] back Content of the node.
		---@diagnostic disable-next-line: unused-local
		get_content = function(self, edge_type)
			local front, back = {}, {}

			local abs_proj_path = utils.get_file_info()[4]
			local abs_file_path = utils.get_abs_path(self.rel_file_path, abs_proj_path)
			local bufnr, is_temp_buf = utils.get_bufnr(abs_file_path .. "/" .. self.file_name)
			local heading_node = ts_utils.get_heading_node(bufnr, self.id)
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
					table.insert(
						back,
						utils.split_string(vim.treesitter.get_node_text(sub_heading_node, bufnr), "\n")[1]
					)
				end
			end

			if is_temp_buf then
				vim.api.nvim_buf_delete(bufnr, { force = true })
			end

			return front, back
		end,
	},
	cls_methods = {
		--
	},
}

--------------------

return default_node_sub_cls
