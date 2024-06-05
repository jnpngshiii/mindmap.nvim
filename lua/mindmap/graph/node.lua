local utils = require("mindmap.utils")
local ts_utils = require("mindmap.ts_utils")

---@alias NodeID integer
---@alias NodeType string

--------------------
-- Class PrototypeNode
--------------------

---@class PrototypeNode
---Mandatory fields:
---@field file_name string Name of the file where the node is from.
---@field rel_file_path string Relative path to the project root of the file where the node is from.
---Optional fields:
---@field data table Data of the node. Subclass should put there own data in this field.
---@field type NodeType Type of the node.
---@field tag string[] Tag of the node.
---@field version integer Version of the node.
---@field created_at integer Created time of the node in UNIX timestemp format.
---@field incoming_edge_ids EdgeID[] Ids of incoming edges to this node.
---@field outcoming_edge_ids EdgeID[] Ids of outcoming edges from this node.
---@field cache table<string, any> Cache of the node.
local PrototypeNode = {}

local prototype_node_version = 4
-- v0: Initial version.
-- v1: Add `tag` field.
-- v2: Remove `id` field.
-- v3: Make `type` field auto generated.
-- v4: Factory.

----------
-- Instance Method
----------

---Create a new node.
---@param file_name string Name of the file where the node is from.
---@param rel_file_path string Relative path to the project root of the file where the node is from.
---
---@param data table Data of the node. Subclass should put there own data in this field.
---@param type NodeType Type of the node.
---@param tag? string[] Tag of the node.
---@param version? integer Version of the node.
---@param created_at? integer Created time of the node in UNIX timestemp format.
---@param incoming_edge_ids? EdgeID[] Ids of incoming edges to this node.
---@param outcoming_edge_ids? EdgeID[] Ids of outcoming edges from this node.
---@return PrototypeNode _ The created node.
function PrototypeNode:new(
	file_name,
	rel_file_path,
	--
	data,
	type,
	tag,
	version,
	created_at,
	incoming_edge_ids,
	outcoming_edge_ids
)
	local prototype_node = {
		file_name = file_name,
		rel_file_path = rel_file_path,
		--
		data = data or {},
		type = type or "PrototypeNode",
		tag = tag or {},
		version = version or prototype_node_version,
		created_at = created_at or tonumber(os.time()),
		incoming_edge_ids = incoming_edge_ids or {},
		outcoming_edge_ids = outcoming_edge_ids or {},
	}

	setmetatable(prototype_node, self)
	self.__index = self

	return prototype_node
end

---Add incoming edge to the node.
---@param incoming_edge_id EdgeID ID of the incoming edge to be added.
---@return nil _ This function does not return anything.
function PrototypeNode:add_incoming_edge_id(incoming_edge_id)
	table.insert(self.incoming_edge_ids, incoming_edge_id)
end

---Remove incoming edge from the node.
---@param incoming_edge_id EdgeID ID of the incoming edge to be removed.
---@return nil _ This function does not return anything.
function PrototypeNode:remove_incoming_edge_id(incoming_edge_id)
	for i = 1, #self.incoming_edge_ids do
		if self.incoming_edge_ids[i] == incoming_edge_id then
			table.remove(self.incoming_edge_ids, i)
			break
		end
	end
end

---Add outcoming edge to the node.
---@param outcoming_edge_id EdgeID ID of the outcoming edge to be added.
---@return nil _ This function does not return anything.
function PrototypeNode:add_outcoming_edge_id(outcoming_edge_id)
	table.insert(self.outcoming_edge_ids, outcoming_edge_id)
end

---Remove outcoming edge from the node.
---@param outcoming_edge_id EdgeID ID of the outcoming edge to be removed.
---@return nil _ This function does not return anything.
function PrototypeNode:remove_outcoming_edge_id(outcoming_edge_id)
	for i = 1, #self.outcoming_edge_ids do
		if self.outcoming_edge_ids[i] == outcoming_edge_id then
			table.remove(self.outcoming_edge_ids, i)
			break
		end
	end
end

---@abstract
---Get the content of the node.
---@return any content Content of the node.
function PrototypeNode:get_content()
	error("[PrototypeNode] Please implement function `get_content` in subclass.")
end

----------
-- Class Method
----------

--------------------
-- Factory
--------------------

local node_factory = require("mindmap.graph.factory")
node_factory.register_base("NodeClass", PrototypeNode)

local node_cls_methods = {
	to_table = function(cls, self)
		return {
			file_name = self.file_name,
			rel_file_path = self.rel_file_path,
			--
			data = self.data,
			type = self.type,
			tag = self.tag,
			version = self.version,
			created_at = self.created_at,
			incoming_edge_ids = self.incoming_edge_ids,
			outgoing_edge_ids = self.outgoing_edge_ids,
		}
	end,

	from_table = function(cls, self, table)
		return cls:new(
			table.file_name,
			table.rel_file_path,
			--
			table.data,
			table.type,
			table.tag,
			table.version,
			table.created_at,
			table.incoming_edge_ids,
			table.outgoing_edge_ids
		)
	end,
}

--------------------
-- Subclass ExcerptNode
--------------------

---@class ExcerptNode : PrototypeNode
---@field data.start_row integer Start row of the excerpt.
---@field data.start_col integer Start column of the excerpt.
---@field data.end_row integer End row of the excerpt.
---@field data.end_col integer End column of the excerpt.

node_factory.create_class(
	-- Class category
	"NodeClass",
	-- Class type
	"ExcerptNode",
	-- Additional fields
	{
		--
	},
	-- Additional methods
	{
		---Get the content of the node.
		---@return string[] content
		get_content = function(self)
			local abs_proj_path = utils.get_file_info()[4]
			local abs_file_path = utils.get_abs_path(self.rel_file_path, abs_proj_path)

			local content = utils.get_file_content(
				abs_file_path .. "/" .. self.file_name,
				self.data.start_row,
				self.data.end_row,
				self.data.start_col,
				self.data.end_col
			)

			return content
		end,

		---Create a new excerpt node using the latest visual selection.
		---@return ExcerptNode _ The created node.
		create_using_latest_visual_selection = function()
			local start_row = vim.api.nvim_buf_get_mark(0, "<")[1]
			local start_col = vim.api.nvim_buf_get_mark(0, "<")[2]
			local end_row = vim.api.nvim_buf_get_mark(0, ">")[1]
			local end_col = vim.api.nvim_buf_get_mark(0, ">")[2]

			local file_name, _, rel_file_path, _ = unpack(utils.get_file_info())
			-- TODO: Check if this is correct
			return node_factory.cls_categories["NodeClass"]["ExcerptNode"]:new(file_name, rel_file_path, {
				["start_row"] = start_row,
				["start_col"] = start_col,
				["end_row"] = end_row,
				["end_col"] = end_col,
			})
		end,
	}
)
node_factory.add_cls_method("NodeClass", "ExcerptNode", node_cls_methods)

--------------------
-- Subclass HeadingNode
--------------------

---@class HeadingNode : PrototypeNode

node_factory.create_class(
	-- Class category
	"NodeClass",
	-- Class type
	"HeadingNode",
	-- Additional fields
	{
		--
	},
	-- Additional methods
	{
		---Get the content of the node.
		---@param node_id NodeID ID of the node.
		---@return string[] title_text, string[] content_text, string[] sub_heading_text
		get_content = function(self, node_id)
			local is_modified -- TODO: Only use cache if the file is not modified
			if self.cache and self.cache.get_content and not is_modified then
				return self.cache.get_content.title_text,
					self.cache.get_content.content_text,
					self.cache.get_content.sub_heading_text
			end

			local abs_proj_path = utils.get_file_info()[4]
			local abs_file_path = utils.get_abs_path(self.rel_file_path, abs_proj_path)
			local bufnr, is_temp_buf = utils.get_bufnr(abs_file_path .. "/" .. self.file_name)
			local heading_node = ts_utils.get_heading_node_using_id(node_id, bufnr)
			if not heading_node then
				return {}, {}, {}
			end

			local title_node, content_node, sub_heading_nodes = ts_utils.get_sub_nodes(heading_node)
			local title_text = utils.split_string(vim.treesitter.get_node_text(title_node, bufnr), "\n")
			local content_text = utils.split_string(vim.treesitter.get_node_text(content_node, bufnr), "\n")
			local sub_heading_text = {}
			for _, sub_heading_node in ipairs(sub_heading_nodes) do
				table.insert(
					sub_heading_text,
					utils.split_string(vim.treesitter.get_node_text(sub_heading_node, bufnr), "\n")[1]
				)
			end

			if is_temp_buf then
				vim.api.nvim_buf_delete(bufnr, { force = true })
			end

			if self.cache then
				self.cache.get_content = {
					title_text = title_text,
					content_text = content_text,
					sub_heading_text = sub_heading_text,
				}
			end

			return title_text, content_text, sub_heading_text
		end,
	}
)
node_factory.add_cls_method("NodeClass", "HeadingNode", node_cls_methods)

--------------------

return node_factory.cls_categories["NodeClass"]
