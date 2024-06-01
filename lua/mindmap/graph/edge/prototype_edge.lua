---@alias EdgeID integer
---@alias EdgeType string

--------------------
-- Class PrototypeEdge
--------------------

---@class PrototypeEdge
---Must provide fields in all edge classes:
---@field type EdgeType Type of the edge.
---@field from_node_id NodeID Where this edge is from.
---@field to_node_id NodeID Where this edge is to.
---Must provide Fields in some edge classes: subclass should put there own field in this field.
---@field data table Data of the edge.
---Auto generated and updated fields:
---@field tag string[] Tag of the edge.
---@field version integer Version of the edge. Auto generated and updated.
---@field created_at integer Created time of the edge in UNIX timestemp format. Auto generated.
---@field updated_at integer Updated time of the edge in UNIX timestemp format. Used in space repetition. Auto generated and updated.
---@field due_at integer Due time of the edge in UNIX timestemp format. Used in space repetition. Auto generated and updated.
---@field ease integer Ease of the edge. Used in space repetition. Auto generated and updated.
---@field interval integer Interval of the edge. Used in space repetition. Auto generated and updated.
---@field cache table Cache of the edge. Save temporary data to avoid recalculation. Auto generated and updated.
local PrototypeEdge = {}

local prototype_edge_version = 0.2
-- v0.0: Initial version.
-- v0.1: Add `tag` field.
-- v0.2: Remove `id` field.

--------------------
-- Instance Method
--------------------

---Create a new edge.
---@param type EdgeType Type of the edge.
---@param from_node_id NodeID Where this edge is from.
---@param to_node_id NodeID Where this edge is to.
---
---@param data? table Data of the edge.
---
---@param tag? string[] Tag of the edge.
---@param version? integer Version of the edge.
---@param created_at? integer Created time of the edge.
---@param updated_at? integer Updated time of the edge.
---@param due_at? integer Due time of the edge.
---@param ease? integer Ease of the edge.
---@param interval? integer Interval of the edge.
---@return PrototypeEdge _ The created edge.
function PrototypeEdge:new(
	type,
	from_node_id,
	to_node_id,

	data,

	tag,
	version,
	created_at,
	updated_at,
	due_at,
	ease,
	interval
)
	local prototype_edge = {
		type = type,
		from_node_id = from_node_id,
		to_node_id = to_node_id,

		data = data or {},

		tag = tag or {},
		version = version or prototype_edge_version,
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

---@abstract
---Spaced repetition function: Get spaced repetition information of the edge.
---@return string[] _ Spaced repetition information of the edge.
function PrototypeEdge:get_sp_info()
	error("[PrototypeEdge] Please implement function `get_sp_info` in subclass.")
end

--------------------
-- Class Method
--------------------

---Convert an edge to a table.
---@param edge PrototypeEdge Edge to be converted.
---@return table _ The converted table.
function PrototypeEdge.to_table(edge)
	return {
		type = edge.type,
		from_node_id = edge.from_node_id,
		to_node_id = edge.to_node_id,

		data = edge.data,

		tag = edge.tag,
		version = edge.version,
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
---@return PrototypeEdge _ The converted edge.
function PrototypeEdge.from_table(table)
	error("[PrototypeEdge] Please implement function `from_table` in subclass.")
end

--------------------

return PrototypeEdge
