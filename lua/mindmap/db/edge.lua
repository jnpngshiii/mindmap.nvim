local misc = require("mindmap.misc")

---@class Edge
---
---@field from_node_id string Where this edge is from.
---@field to_node_id string Where this edge is to.
---
---@field id string Edge ID.
---@field type string Edge type. Default: "edge". This field is reserved for future use.
---
---@field created_at integer Edge created time.
---@field updated_at integer Space repetition updated time of the edge.
---@field due_at integer Space repetition due time of the edge.
---@field ease integer Space repetition ease of the edge.
---@field interval integer Space repetition interval of the edge.
---@field data table Data of the edge. This field is reserved for future use.
local Edge = {}

--------------------
-- Instance Method
--------------------

---Create a new edge.
---@param from_node_id string Where this edge is from.
---@param to_node_id string Where this edge is to.
---@param id? string Edge ID.
---@param type? string Edge type. Default: "edge". This field is reserved for future use.
---@param created_at? integer Edge created time.
---@param updated_at? integer Space repetition updated time of the edge.
---@param due_at? integer Space repetition due time of the edge.
---@param ease? integer Space repetition ease of the edge.
---@param interval? integer Space repetition interval of the edge.
---@param data? table Data of the edge. This field is reserved for future use.
function Edge:new(from_node_id, to_node_id, id, type, created_at, updated_at, due_at, ease, interval, data)
	local edge = {
		from_node_id = from_node_id,
		to_node_id = to_node_id,

		id = id or misc.get_unique_id(),
		type = type or "edge",

		created_at = created_at or tonumber(os.time()),
		updated_at = updated_at or tonumber(os.time()),
		due_at = due_at or 0,
		ease = ease or 250,
		interval = interval or 1,
		data = data or {},
	}

	setmetatable(edge, Edge)
	self.__index = self

	return edge
end

--------------------
-- Class Method
--------------------

---Convert edge to table.
---@param edge Edge Edge to convert.
---@return table
function Edge.to_table(edge)
	return {
		from_node_id = edge.from_node_id,
		to_node_id = edge.to_node_id,
		id = edge.id,
		type = edge.type,
		created_at = edge.created_at,
		updated_at = edge.updated_at,
		due_at = edge.due_at,
		ease = edge.ease,
		interval = edge.interval,
		data = edge.data,
	}
end

---Convert table to edge.
---@param table table Table to convert.
---@return Edge
function Edge.from_table(table)
	return Edge:new(
		table.from_node_id,
		table.to_node_id,
		table.id,
		table.type,
		table.created_at,
		table.updated_at,
		table.due_at,
		table.ease,
		table.interval,
		table.data
	)
end

--------------------

return Edge
