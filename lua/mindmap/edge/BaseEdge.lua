--------------------
-- Class BaseEdge
--------------------

---@alias EdgeID integer
---@alias EdgeType string

---@class BaseEdge
---Mandatory fields:
---@field _type EdgeType Type of the edge.
---@field _id EdgeID ID of the edge.
---@field _from NodeID ID of the node where the edge is from.
---@field _to NodeID ID of the node where the edge is to.
---Optional fields:
---@field _data table Data of the node. Subclass should put there own field in this field.
---@field _cache table Cache of the edge.
---@field _created_at integer Created time of the edge in UNIX timestemp format.
---@field _updated_at integer Updated time of the edge in UNIX timestemp format.
---@field _due_at integer Due time of the edge in UNIX timestemp format.
---@field _ease integer Ease of the edge.
---@field _interval integer Interval of the edge.
---@field _answer_count integer Count of total answer of the edge.
---@field _ease_count integer Count of esae answer of the edge.
---@field _again_count integer Count of again answer of the edge.
---@field _state string State of the edge. Can be "active", "removed", and "archived". Default: "active".
---@field _version integer Version of the edge.
local BaseEdge = {}
BaseEdge.__index = BaseEdge

local base_edge_version = 12
-- v0: Initial version.
-- v1: Add `tag` field.
-- v2: Remove `id` field.
-- v3: Make `type` field auto generated.
-- v4: Factory.
-- v5: Add `id` field, `algorithm` field, and `state` field.
-- v6: Remove `algorithm` field.
-- v7: Add `answer_count` field and `again_count` field.
-- v8: Add `[before|after]_[add_into|remove_from]_graph` methods.
-- v9: Add `ease_count` field.
-- v10: Rename to `BaseEdge`.
-- v11: Remove `tag` field.
-- v12: Rename `field` to `_field`.

----------
-- Basic Method
----------

---Create a new edge.
---@param _type EdgeType Type of the edge.
---@param _id EdgeID ID of the edge.
---@param _from NodeID ID of the node where the edge is from.
---@param _to NodeID ID of the node where the edge is to.
---Optional fields:
---@param _data table Data of the node. Subclass should put there own field in this field.
---@param _cache table Cache of the edge.
---@param _created_at integer Created time of the edge in UNIX timestemp format.
---@param _updated_at integer Updated time of the edge in UNIX timestemp format.
---@param _due_at integer Due time of the edge in UNIX timestemp format.
---@param _ease integer Ease of the edge.
---@param _interval integer Interval of the edge.
---@param _answer_count integer Count of total answer of the edge.
---@param _ease_count integer Count of esae answer of the edge.
---@param _again_count integer Count of again answer of the edge.
---@param _state string State of the edge. Can be "active", "removed", and "archived". Default: "active".
---@param _version integer Version of the edge.
---@return BaseEdge _ The created edge.
function BaseEdge:new(
	_type,
	_id,
	_from,
	_to,
	--
	_data,
	_cache,
	_created_at,
	_updated_at,
	_due_at,
	_ease,
	_interval,
	_answer_count,
	_ease_count,
	_again_count,
	_state,
	_version
)
	local base_edge = {
		_type = _type,
		_id = _id,
		_from = _from,
		_to = _to,
		--
		_data = _data or {},
		_cache = _cache or {},
		_created_at = _created_at or tonumber(os.time()),
		_updated_at = _updated_at or tonumber(os.time()),
		_due_at = _due_at or 0,
		_ease = _ease or 250,
		_interval = _interval or 1,
		_answer_count = _answer_count or 0,
		_ease_count = _ease_count or 0,
		_again_count = _again_count or 0,
		_state = _state or "active",
		_version = _version or base_edge_version,
	}
	base_edge.__index = base_edge
	setmetatable(base_edge, BaseEdge)

	return base_edge
end

----------
-- Graph Method
-- TODO: How to remove there methods?
----------

---@abstract
---Handle the edge before adding into the graph.
---@return nil _ This function does not return anything.
---@diagnostic disable-next-line: unused-vararg
function BaseEdge:before_add_into_graph(...)
	vim.notify("[BaseEdge] Method `before_add_into_graph` is not implemented.")
end

---@abstract
---Handle the edge after adding into the graph.
---@return nil _ This function does not return anything.
---@diagnostic disable-next-line: unused-vararg
function BaseEdge:after_add_into_graph(...)
	vim.notify("[BaseEdge] Method `after_add_into_graph` is not implemented.")
end

---@abstract
---Handle the edge before removing from the graph.
---@return nil _ This function does not return anything.
---@diagnostic disable-next-line: unused-vararg
function BaseEdge:before_remove_from_graph(...)
	vim.notify("[BaseEdge] Method `before_remove_from_graph` is not implemented.")
end

---@abstract
---Handle the edge after removing from the graph.
---@return nil _ This function does not return anything.
---@diagnostic disable-next-line: unused-vararg
function BaseEdge:after_remove_from_graph(...)
	vim.notify("[BaseEdge] Method `after_remove_from_graph` is not implemented.")
end

--------------------

return BaseEdge
