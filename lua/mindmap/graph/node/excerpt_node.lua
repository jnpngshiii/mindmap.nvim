local PrototypeNode = require("mindmap.graph.node.prototype_node")
local utils = require("mindmap.utils")

--------------------
-- Class ExcerptNode
--------------------

---@class ExcerptNode : PrototypeNode
---@field data.start_row integer Start row of the excerpt.
---@field data.start_col integer Start column of the excerpt.
---@field data.end_row integer End row of the excerpt.
---@field data.end_col integer End column of the excerpt.
local ExcerptNode = setmetatable({}, { __index = PrototypeNode })
ExcerptNode.__index = ExcerptNode

----------
-- Instance method
----------

---Create a new excerpt.
---@param file_name string Name of the file where the node is from.
---@param rel_file_path string Relative path to the project root of the file where the node is from.
---@param data? table Data of the node. Subclass should put there own data in this field.
---@param id? NodeID ID of the node.
---@param created_at? integer Created time of the node in Unix timestamp format.
---@param incoming_edge_ids? table<EdgeID, EdgeID> IDs of incoming edges to this node.
---@param outcoming_edge_ids? table<EdgeID, EdgeID> IDs of outcoming edges from this node.
---@return ExcerptNode|PrototypeNode
function ExcerptNode:new(file_name, rel_file_path, data, id, created_at, incoming_edge_ids, outcoming_edge_ids)
	local prototype_node = PrototypeNode:new(
		"ExcerptNode",
		file_name,
		rel_file_path,
		data,
		id,
		created_at,
		incoming_edge_ids,
		outcoming_edge_ids
	)

	setmetatable(prototype_node, self)
	self.__index = self

	return prototype_node
end

---Check if the node is healthy.
---This is a simple check to see if all the required fields are there.
function ExcerptNode:check_health()
	if
		self.data.start_row
		and self.data.start_col
		and self.data.end_row
		and self.data.end_col
		and PrototypeNode.check_health(self)
	then
		return true
	end

	return false
end

----------
-- Class method
----------

---Create a new excerpt node using the latest visual selection.
---@return ExcerptNode|PrototypeNode
function ExcerptNode.create_using_latest_visual_selection()
	local start_row = vim.api.nvim_buf_get_mark(0, "<")[1]
	local start_col = vim.api.nvim_buf_get_mark(0, "<")[2]
	local end_row = vim.api.nvim_buf_get_mark(0, ">")[1]
	local end_col = vim.api.nvim_buf_get_mark(0, ">")[2]

	local file_name, _, rel_file_path, _ = table.unpack(utils.get_file_info())
	return ExcerptNode:new(file_name, rel_file_path, {
		["start_row"] = start_row,
		["start_col"] = start_col,
		["end_row"] = end_row,
		["end_col"] = end_col,
	})
end

---Convert a table to a node.
---@param table table Table to be converted.
---@return PrototypeNode
function ExcerptNode.from_table(table)
	return ExcerptNode:new(
		table.file_name,
		table.rel_file_path,
		table.data,
		table.id,
		table.created_at,
		table.incoming_edge_ids,
		table.outcoming_edge_ids
	)
end

--------------------

return ExcerptNode
