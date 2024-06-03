local PrototypeNode = require("mindmap.graph.node.prototype_node")

local utils = require("mindmap.utils")
local ts_utils = require("mindmap.ts_utils")

--------------------
-- Class HeadingNode
--------------------

---@class HeadingNode : PrototypeNode
local HeadingNode = setmetatable({}, { __index = PrototypeNode })
HeadingNode.__index = HeadingNode

local heading_node_version = 0.0
-- v0.0: Initial version.

----------
-- Instance method
----------

---Create a new excerpt.
---@param file_name string Name of the file where the node is from.
---@param rel_file_path string Relative path to the project root of the file where the node is from.
---
---@param data? table Data of the node. Subclass should put there own data in this field.
---
---@param tag? string[] Tag of the node.
---@param version? integer Version of the node.
---@param created_at? integer Created time of the node in Unix timestamp format.
---@param incoming_edge_ids? table<EdgeID, EdgeID> IDs of incoming edges to this node.
---@param outcoming_edge_ids? table<EdgeID, EdgeID> IDs of outcoming edges from this node.
---@return HeadingNode|PrototypeNode _ The created node.
function HeadingNode:new(
	file_name,
	rel_file_path,

	data,

	tag,
	version,
	created_at,
	incoming_edge_ids,
	outcoming_edge_ids
)
	local prototype_node = PrototypeNode:new(
		"HeadingNode",
		file_name,
		rel_file_path,
		--
		data,
		--
		tag,
		version or heading_node_version,
		created_at,
		incoming_edge_ids,
		outcoming_edge_ids
	)

	setmetatable(prototype_node, self)
	self.__index = self

	return prototype_node
end

---Get the content of the node.
---@param node_id NodeID ID of the node.
---@return string[] title_text, string[] content_text, string[] sub_heading_text
function HeadingNode:get_content(node_id)
	local abs_proj_path = utils.get_file_info()[4]
	local abs_file_path = utils.get_abs_path(self.rel_file_path, abs_proj_path)

	local title_node, content_node, sub_heading_nodes, bufnr = ts_utils.get_sub_nodes(node_id, abs_file_path)
	local title_text = utils.split_string(vim.treesitter.get_node_text(title_node, bufnr), "\n")
	local content_text = utils.split_string(vim.treesitter.get_node_text(content_node, bufnr), "\n")
	local sub_heading_text = {}
	for _, sub_heading_node in ipairs(sub_heading_nodes) do
		table.insert(
			sub_heading_text,
			utils.split_string(vim.treesitter.get_node_text(sub_heading_node, bufnr), "\n")[1]
		)
	end

	if bufnr then
		vim.api.nvim_buf_delete(bufnr, { force = true })
	end

	return title_text, content_text, sub_heading_text
end

----------
-- Class method
----------

---Convert a table to a node.
---@param table table Table to be converted.
---@return PrototypeNode _ The converted node.
function HeadingNode.from_table(table)
	return HeadingNode:new(
		table.file_name,
		table.rel_file_path,
		--
		table.data,
		--
		table.tag,
		table.version,
		table.created_at,
		table.incoming_edge_ids,
		table.outcoming_edge_ids
	)
end

--------------------

return HeadingNode
