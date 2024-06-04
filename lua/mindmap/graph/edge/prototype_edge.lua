---@alias EdgeID integer
---@alias EdgeType string

--------------------
-- Class PrototypeEdge
--------------------

---@class PrototypeEdge
---Must provide fields in all edge classes:
---@field from_node_id NodeID Where this edge is from.
---@field to_node_id NodeID Where this edge is to.
---Auto generated and updated fields:
---@field data table Data of the node. Subclass should put there own field in this field.
---@field type EdgeType Type of the edge. Auto generated.
---@field tag string[] Tag of the edge.
---@field version integer Version of the edge. Auto generated and updated.
---@field created_at integer Created time of the edge in UNIX timestemp format. Auto generated.
---@field updated_at integer Updated time of the edge in UNIX timestemp format. Used in space repetition. Auto generated and updated.
---@field due_at integer Due time of the edge in UNIX timestemp format. Used in space repetition. Auto generated and updated.
---@field ease integer Ease of the edge. Used in space repetition. Auto generated and updated.
---@field interval integer Interval of the edge. Used in space repetition. Auto generated and updated.
---@field cache table Cache of the edge. Save temporary data to avoid recalculation. Auto generated and updated.
local PrototypeEdge = {}

local prototype_edge_version = 0.3
-- v0.0: Initial version.
-- v0.1: Add `tag` field.
-- v0.2: Remove `id` field.
-- v0.3: Make `type` field auto generated.

--------------------
-- Instance Method
--------------------

---Create a new edge.
---@param from_node_id NodeID Where this edge is from.
---@param to_node_id NodeID Where this edge is to.
---
---@param data? table Data of the edge.
---@param tag? string[] Tag of the edge.
---@param version? integer Version of the edge.
---@param created_at? integer Created time of the edge.
---@param updated_at? integer Updated time of the edge.
---@param due_at? integer Due time of the edge.
---@param ease? integer Ease of the edge.
---@param interval? integer Interval of the edge.
---@return PrototypeEdge _ The created edge.
function PrototypeEdge:new(
	from_node_id,
	to_node_id,
	--
	data,
	tag,
	version,
	created_at,
	updated_at,
	due_at,
	ease,
	interval
)
	local edge = {
		from_node_id = from_node_id,
		to_node_id = to_node_id,
		--
		data = data or {},
		tag = tag or {},
		-- TODO: add merge function
		version = version or prototype_edge_version,
		created_at = created_at or tonumber(os.time()),
		updated_at = updated_at or tonumber(os.time()),
		due_at = due_at or 0,
		ease = ease or 250,
		interval = interval or 1,
	}

	edge.type = "PrototypeEdge"
	edge.cache = {}

	setmetatable(edge, self)
	self.__index = self

	return edge
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
		from_node_id = edge.from_node_id,
		to_node_id = edge.to_node_id,
		--
		data = edge.data,
		type = edge.type,
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
