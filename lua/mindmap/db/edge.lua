local misc = require("mindmap.misc")

---@class Edge
---
---@field type string Edge type.
---@field from_node_id string Where this edge is from.
---@field to_node_id string Where this edge is to.
---@field data table Data of the edge. Subclass should put there own data in this field.
---@field id string Edge ID.
---@field created_at integer Edge created time.
---@field updated_at integer Space repetition updated time of the edge.
---@field due_at integer Space repetition due time of the edge.
---@field ease integer Space repetition ease of the edge.
---@field interval integer Space repetition interval of the edge.
local Edge = {}

--------------------
-- Instance Method
--------------------

---Create a new edge.
---@param type string Edge type.
---@param from_node_id string Where this edge is from.
---@param to_node_id string Where this edge is to.
---@param data? table Data of the edge. Subclass should put there own data in this field.
---@param id? string ID of the edge.
---@param created_at? integer Created time of the edge.
---@param updated_at? integer Space repetition updated time of the edge.
---@param due_at? integer Space repetition due time of the edge.
---@param ease? integer Space repetition ease of the edge.
---@param interval? integer Space repetition interval of the edge.
function Edge:new(type, from_node_id, to_node_id, data, id, created_at, updated_at, due_at, ease, interval)
	local edge = {
		type = type,
		from_node_id = from_node_id,
		to_node_id = to_node_id,
		data = data or {},
		id = id or misc.get_unique_id(),
		created_at = created_at or tonumber(os.time()),
		updated_at = updated_at or tonumber(os.time()),
		due_at = due_at or 0,
		ease = ease or 250,
		interval = interval or 1,
	}

	setmetatable(edge, Edge)
	self.__index = self

	return edge
end

--------------------
-- Class Method
--------------------

---Convert an edge to a table.
---@param edge Edge Edge to be converted.
---@return table
function Edge.to_table(edge)
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

---Convert a table to an edge.
---@param table table Table to be converted.
---@return Edge
function Edge.from_table(table)
	return Edge:new(
		table.type,
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

return Edge
