local PrototypeEdge = require("mindmap.graph.edge.prototype_edge")

--------------------
-- Class SimpleEdge
--------------------

---@class SimpleEdge : PrototypeEdge
local SimpleEdge = setmetatable({}, { __index = PrototypeEdge })
SimpleEdge.__index = SimpleEdge

local self_loop_content_edge_version = 0.0
-- v0.0: Initial version.

--------------------
-- Instance Method
--------------------

---Create a new edge.
---@param from_node_id EdgeID Where this edge is from.
---@param to_node_id EdgeID Where this edge is to.
---
---@param data? table Data of the edge.
---@param tag? string[] Tag of the edge.
---@param version? integer Version of the edge.
---@param created_at? integer Created time of the edge.
---@param updated_at? integer Updated time of the edge.
---@param due_at? integer Due time of the edge.
---@param ease? integer Ease of the edge.
---@param interval? integer Interval of the edge.
---@return SimpleEdge _ The created edge.
function SimpleEdge:new(
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
	local prototype_edge = PrototypeEdge:new(
		from_node_id,
		to_node_id,
		--
		data,
		tag,
		version or self_loop_content_edge_version,
		created_at,
		updated_at,
		due_at,
		ease,
		interval
	)

	prototype_edge.type = "SimpleEdge"

	setmetatable(prototype_edge, self)
	self.__index = self

	---@cast prototype_edge SimpleEdge
	return prototype_edge
end

--------------------
-- Class Method
--------------------

---Convert a table to an edge.
---@param table table Table to be converted.
---@return PrototypeEdge _ The converted edge.
function SimpleEdge.from_table(table)
	return SimpleEdge:new(
		table.from_node_id,
		table.to_node_id,
		--
		table.data,
		table.tag,
		table.version,
		table.created_at,
		table.updated_at,
		table.due_at,
		table.ease,
		table.interval
	)
end

--------------------

return SimpleEdge
