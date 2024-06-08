local utils = require("mindmap.utils")
local ts_utils = require("mindmap.ts_utils")

--------------------
-- Default Sub Node Class
--------------------

local default_node_sub_cls = {}

local node_sub_cls_methods = {
	---@diagnostic disable-next-line: unused-local
	to_table = function(cls, self)
		return {
			id = self.id,
			file_name = self.file_name,
			rel_file_path = self.rel_file_path,
			--
			data = self.data,
			type = self.type,
			tag = self.tag,
			state = self.state,
			version = self.version,
			created_at = self.created_at,
			incoming_edge_ids = self.incoming_edge_ids,
			outcoming_edge_ids = self.outcoming_edge_ids,
		}
	end,

	---@diagnostic disable-next-line: unused-local
	from_table = function(cls, self, tbl)
		return cls:new(
			tbl.id,
			tbl.file_name,
			tbl.rel_file_path,
			--
			tbl.data,
			tbl.type,
			tbl.tag,
			tbl.state,
			tbl.version,
			tbl.created_at,
			tbl.incoming_edge_ids,
			tbl.outcoming_edge_ids
		)
	end,
}

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
		to_table = node_sub_cls_methods.to_table,
		from_table = node_sub_cls_methods.from_table,
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

		to_table = node_sub_cls_methods.to_table,
		from_table = node_sub_cls_methods.from_table,
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
		---Get the content of the node.
		---@param edge_type EdgeType Type of the edge.
		---@return string[] front ,string[] back Content of the node.
		---@diagnostic disable-next-line: unused-local
		get_content = function(self, edge_type)
			local front, back = {}, {}

			local abs_proj_path = utils.get_file_info()[4]
			local abs_file_path = utils.get_abs_path(self.rel_file_path, abs_proj_path)
			local bufnr, is_temp_buf = utils.get_bufnr(abs_file_path .. "/" .. self.file_name)
			local heading_node = ts_utils.get_heading_node_using_id(self.id, bufnr)
			if not heading_node then
				return front, back
			end
			local title_node, content_node, sub_heading_nodes = ts_utils.get_sub_nodes(heading_node)

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
		to_table = node_sub_cls_methods.to_table,
		from_table = node_sub_cls_methods.from_table,
	},
}

--------------------

return default_node_sub_cls
