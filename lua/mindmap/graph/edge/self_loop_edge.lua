local PrototypeEdge = require("mindmap.graph.edge.prototype_edge")

---@class SelfLoopEdge : PrototypeEdge
local SelfLoopEdge = setmetatable({}, { __index = PrototypeEdge })
SelfLoopEdge.__index = SelfLoopEdge

--------------------
-- Instance Method
--------------------

---Create a new self loop edge.
---@param from_node_id EdgeID Where this edge is from.
---@param to_node_id? EdgeID Where this edge is to.
---@param data? table Data of the edge.
---@param id? EdgeID ID of the edge.
---@param created_at? integer Created time of the edge.
---@param updated_at? integer Updated time of the edge.
---@param due_at? integer Due time of the edge.
---@param ease? integer Ease of the edge.
---@param interval? integer Interval of the edge.
---@return SelfLoopEdge|PrototypeEdge
function SelfLoopEdge:new(from_node_id, to_node_id, data, id, created_at, updated_at, due_at, ease, interval)
	to_node_id = from_node_id

	local prototype_edge = PrototypeEdge:new(
		"SelfLoopEdge",
		from_node_id,
		to_node_id,
		data,
		id,
		created_at,
		updated_at,
		due_at,
		ease,
		interval
	)

	setmetatable(prototype_edge, self)
	self.__index = self

	return prototype_edge
end

---Check if the edge is healthy.
---This is a simple check to see if all the required fields are there.
---@return boolean
function SelfLoopEdge:check_health()
	if true and PrototypeEdge.check_health(self) then
		return true
	end

	return false
end

--------------------
-- Class Method
--------------------

---Convert a table to an edge.
---@param table table Table to be converted.
---@return PrototypeEdge
function SelfLoopEdge.from_table(table)
	return SelfLoopEdge:new(
		table.from_node_id,
		table.to_node_id,
		table.data,
		table.id,
		table.created_at,
		table.updated_at,
		table.due_at,
		table.ease,
		table.interval
	)
end

--------------------

if false then
	local self_loop_edge = SelfLoopEdge:new("from_node_id", "to_node_id")
	print(self_loop_edge.id)
	print(self_loop_edge.type)

	local ok = self_loop_edge:check_health()
	print(ok)
end

return SelfLoopEdge
