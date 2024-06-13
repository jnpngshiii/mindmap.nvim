--------------------
-- Class PrototypeEdge
--------------------

---@alias EdgeID integer
---@alias EdgeType string

---@class PrototypeEdge
---Mandatory fields:
---@field id EdgeID ID of the edge.
---@field from_node_id NodeID Where this edge is from.
---@field to_node_id NodeID Where this edge is to.
---Optional fields:
---@field data table Data of the node. Subclass should put there own field in this field.
---@field type EdgeType Type of the edge. Auto generated.
---@field tag table<string, string> Tag of the edge. Experimental.
---@field state string State of the edge. Default to "active". Can be "active", "removed", and "archived". Experimental.
---@field version integer Version of the edge. Auto generated and updated. Experimental.
---@field created_at integer Created time of the edge in UNIX timestemp format. Auto generated.
---@field updated_at integer Updated time of the edge in UNIX timestemp format. Used in space repetition. Auto generated and updated.
---@field due_at integer Due time of the edge in UNIX timestemp format. Used in space repetition. Auto generated and updated.
---@field ease integer Ease of the edge. Used in space repetition. Auto generated and updated.
---@field interval integer Interval of the edge. Used in space repetition. Auto generated and updated.
---@field answer_count integer Count of answer of the edge. Used in space repetition. Auto generated and updated.
---@field again_count integer Count of answer of the edge. Used in space repetition. Auto generated and updated.
---@field cache table Cache of the edge. Save temporary data to avoid recalculation. Auto generated and updated.
local PrototypeEdge = {}

local prototype_edge_version = 7
-- v0: Initial version.
-- v1: Add `tag` field.
-- v2: Remove `id` field.
-- v3: Make `type` field auto generated.
-- v4: Factory.
-- v5: Add `id` field, `algorithm` field, and `state` field.
-- v6: Remove `algorithm` field.
-- v7: Add `answer_count` field and `again_count` field.

----------
-- Instance Method
----------

---Create a new edge.
---@param id EdgeID ID of the edge.
---@param from_node_id NodeID Where this edge is from.
---@param to_node_id NodeID Where this edge is to.
---
---@param data? table Data of the edge.
---@param type? EdgeType Type of the edge.
---@param tag? table<string, string> Tag of the edge.
---@param state? string State of the edge. Default to "active". Can be "active", "removed", and "archived".
---@param version? integer Version of the edge.
---@param created_at? integer Created time of the edge.
---@param updated_at? integer Updated time of the edge.
---@param due_at? integer Due time of the edge.
---@param ease? integer Ease of the edge.
---@param interval? integer Interval of the edge.
---@param answer_count? integer Count of answer of the edge.
---@param again_count? integer Count of answer of the edge.
---@return PrototypeEdge _ The created edge.
function PrototypeEdge:new(
	id,
	from_node_id,
	to_node_id,
	--
	data,
	type,
	tag,
	state,
	version,
	created_at,
	updated_at,
	due_at,
	ease,
	interval,
	answer_count,
	again_count
)
	local prototype_edge = {
		id = id,
		from_node_id = from_node_id,
		to_node_id = to_node_id,
		--
		data = data or {},
		type = type or "PrototypeEdge",
		tag = tag or {},
		state = state or "active",
		version = version or prototype_edge_version, -- TODO: add merge function
		created_at = created_at or tonumber(os.time()),
		updated_at = updated_at or tonumber(os.time()),
		due_at = due_at or 0,
		ease = ease or 250,
		interval = interval or 1,
		answer_count = answer_count or 0,
		again_count = again_count or 0,
		cache = {},
	}

	setmetatable(prototype_edge, self)
	self.__index = self

	return prototype_edge
end

---@abstract
---Handle the edge before adding into the graph.
---@diagnostic disable-next-line: unused-vararg
function PrototypeEdge:before_add_into_graph(...)
	-- error("[PrototypeEdge] Please implement function `before_add_into_graph` in subclass.")
end

---@abstract
---Handle the edge after adding into the graph.
---@diagnostic disable-next-line: unused-vararg
function PrototypeEdge:after_add_into_graph(...)
	-- error("[PrototypeEdge] Please implement function `after_add_into_graph` in subclass.")
end

---@abstract
---Handle the edge before removing from the graph.
---@diagnostic disable-next-line: unused-vararg
function PrototypeEdge:before_remove_from_graph(...)
	-- error("[PrototypeEdge] Please implement function `before_remove_from_graph` in subclass.")
end

---@abstract
---Handle the edge after removing from the graph.
---@diagnostic disable-next-line: unused-vararg
function PrototypeEdge:after_remove_from_graph(...)
	-- error("[PrototypeEdge] Please implement function `after_remove_from_graph` in subclass.")
end

---@abstract
---Convert the edge to a table.
---@diagnostic disable-next-line: unused-vararg
function PrototypeEdge:to_table(...)
	error("[PrototypeEdge] Please implement function `to_table` in subclass.")
end

---@abstract
---Convert the table to a edge.
---@diagnostic disable-next-line: unused-vararg
function PrototypeEdge:from_table(...)
	error("[PrototypeEdge] Please implement function `from_table` in subclass.")
end

----------
-- Class Method
----------

--------------------

return PrototypeEdge
