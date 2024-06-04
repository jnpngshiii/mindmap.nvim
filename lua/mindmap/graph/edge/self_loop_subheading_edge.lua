local PrototypeEdge = require("mindmap.graph.edge.prototype_edge")

--------------------
-- Class SelfLoopSubheadingEdge
--------------------

---@class SelfLoopSubheadingEdge : PrototypeEdge
local SelfLoopSubheadingEdge = setmetatable({}, { __index = PrototypeEdge })
SelfLoopSubheadingEdge.__index = SelfLoopSubheadingEdge

local self_loop_content_edge_version = 0.0
-- v0.0: Initial version.

--------------------
-- Instance Method
--------------------

---Create a new self loop edge.
---@param from_node_id EdgeID Where this edge is from.
---@param to_node_id? EdgeID Where this edge is to.
---
---@param tag? string[] Tag of the edge.
---@param version? integer Version of the edge.
---@param created_at? integer Created time of the edge.
---@param updated_at? integer Updated time of the edge.
---@param due_at? integer Due time of the edge.
---@param ease? integer Ease of the edge.
---@param interval? integer Interval of the edge.
---@param data? table Data of the edge.
---@return SelfLoopSubheadingEdge _ The created edge.
function SelfLoopSubheadingEdge:new(
	from_node_id,
	to_node_id,

	tag,
	version,
	created_at,
	updated_at,
	due_at,
	ease,
	interval,
	data
)
	to_node_id = from_node_id

	local prototype_edge = PrototypeEdge:new(
		from_node_id,
		to_node_id,
		tag,
		version or self_loop_content_edge_version,
		created_at,
		updated_at,
		due_at,
		ease,
		interval,
		data
	)

	setmetatable(prototype_edge, self)
	self.__index = self

	---@cast prototype_edge SelfLoopSubheadingEdge
	return prototype_edge
end

--------------------
-- Class Method
--------------------

---Convert a table to an edge.
---@param table table Table to be converted.
---@return PrototypeEdge _ The converted edge.
function SelfLoopSubheadingEdge.from_table(table)
	return SelfLoopSubheadingEdge:new(
		table.from_node_id,
		table.to_node_id,
		--
		table.tag,
		table.version,
		table.created_at,
		table.updated_at,
		table.due_at,
		table.ease,
		table.interval,
		table.data
	)
end

--------------------

return SelfLoopSubheadingEdge
