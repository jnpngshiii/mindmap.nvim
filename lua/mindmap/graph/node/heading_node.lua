local PrototypeNode = require("mindmap.graph.node.prototype_node")
local misc = require("mindmap.misc")

--------------------
-- Class HeadingNode
--------------------

---@class HeadingNode : PrototypeNode
---@field data.start_row integer Start row of the excerpt.
---@field data.start_col integer Start column of the excerpt.
---@field data.end_row integer End row of the excerpt.
---@field data.end_col integer End column of the excerpt.
local HeadingNode = setmetatable({}, { __index = PrototypeNode })
HeadingNode.__index = HeadingNode

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
---@return HeadingNode|PrototypeNode
function HeadingNode:new(file_name, rel_file_path, data, id, created_at, incoming_edge_ids, outcoming_edge_ids)
	local prototype_node = PrototypeNode:new(
		"HeadingNode",
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
function HeadingNode:check_health()
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

---Convert a table to a node.
---@param table table Table to be converted.
---@return PrototypeNode
function HeadingNode.from_table(table)
	return HeadingNode:new(
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

return HeadingNode
