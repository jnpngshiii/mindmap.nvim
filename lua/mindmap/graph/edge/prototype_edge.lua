local utils = require("mindmap.utils")

---Do I really need these aliases?
---Of course not, but I like them.
---@alias EdgeID string
---@alias EdgeType string

---@class PrototypeEdge
---Must provide fields in all edge classes:
---@field type EdgeType Type of the edge.
---@field from_node_id NodeID Where this edge is from.
---@field to_node_id NodeID Where this edge is to.
---Must provide Fields in some edge classes: subclass should put there own field in this field.
---@field data table<string, number|string|boolean> Data of the edge.
---Auto generated and updated fields:
---@field id EdgeID ID of the edge. Auto generated.
---@field created_at integer Created time of the edge in UNIX timestemp format. Auto generated.
---@field updated_at integer Updated time of the edge in UNIX timestemp format. Used in space repetition. Auto generated and updated.
---@field due_at integer Due time of the edge in UNIX timestemp format. Used in space repetition. Auto generated and updated.
---@field ease integer Ease of the edge. Used in space repetition. Auto generated and updated.
---@field interval integer Interval of the edge. Used in space repetition. Auto generated and updated.
---@field cache table<string, number|string|boolean> Cache of the edge. Save temporary data to avoid recalculation. Auto generated and updated.
local PrototypeEdge = {}

--------------------
-- Instance Method
--------------------

---Create a new edge.
---@param type EdgeType Type of the edge.
---@param from_node_id NodeID Where this edge is from.
---@param to_node_id NodeID Where this edge is to.
---@param data? table Data of the edge.
---@param id? EdgeID ID of the edge.
---@param created_at? integer Created time of the edge.
---@param updated_at? integer Updated time of the edge.
---@param due_at? integer Due time of the edge.
---@param ease? integer Ease of the edge.
---@param interval? integer Interval of the edge.
---@return PrototypeEdge
function PrototypeEdge:new(type, from_node_id, to_node_id, data, id, created_at, updated_at, due_at, ease, interval)
	local prototype_edge = {
		type = type,
		from_node_id = from_node_id,
		to_node_id = to_node_id,
		data = data or {},
		id = id or utils.get_unique_id(),
		created_at = created_at or tonumber(os.time()),
		updated_at = updated_at or tonumber(os.time()),
		due_at = due_at or 0,
		ease = ease or 250,
		interval = interval or 1,
		cache = {},
	}

	setmetatable(prototype_edge, self)
	self.__index = self

	return prototype_edge
end

---Check if the edge is healthy.
---This is a simple check to see if all the required fields are there.
---@return boolean
function PrototypeEdge:check_health()
	if
		self.type
		and self.from_node_id
		and self.to_node_id
		and self.id
		and self.created_at
		and self.updated_at
		and self.due_at
		and self.ease
		and self.interval
	then
		return true
	end

	return false
end

--------------------
-- Class Method
--------------------

---Convert an edge to a table.
---@param edge PrototypeEdge Edge to be converted.
---@return table
function PrototypeEdge.to_table(edge)
	return {
		type = edge.type,
		from_node_id = edge.from_node_id,
		to_node_id = edge.to_node_id,
		data = edge.data,
		id = edge.id,
		created_at = edge.created_at,
		updated_at = edge.updated_at,
		due_at = edge.due_at,
		ease = edge.ease,
		interval = edge.interval,
	}
end

---@abstract
---Convert a table to an edge.
---@param table table Table to be converted.
---@return PrototypeEdge
function PrototypeEdge.from_table(table)
	error("[PrototypeEdge] Please implement function `from_table` in subclass.")
end

--------------------

return PrototypeEdge
