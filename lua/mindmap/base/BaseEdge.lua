--------------------
-- Class BaseEdge
--------------------

---@alias EdgeID integer
---@alias EdgeType string

---@class BaseEdge
---Mandatory fields:
---@field _type EdgeType Type of the edge.
---@field _id EdgeID ID of the edge.
---@field _from NodeID ID of the node where the edge starts.
---@field _to NodeID ID of the node where the edge ends.
---Optional fields:
---@field _data table Custom data of the edge (subclasses should add their own fields here).
---@field _cache table Cache storage for the edge.
---@field _created_at integer Creation time of the edge (UNIX timestamp).
---@field _updated_at integer Last update time of the edge (UNIX timestamp).
---@field _due_at integer Due time of the edge (UNIX timestamp).
---@field _ease integer Ease factor of the edge.
---@field _interval integer Interval of the edge.
---@field _answer_count integer Total number of answers for the edge.
---@field _ease_count integer Number of "easy" answers for the edge.
---@field _again_count integer Number of "again" answers for the edge.
---@field _state string State of the edge ("active", "removed", or "archived"). Default: `"active"`.
---@field _version integer Version of the edge.
local BaseEdge = {}
BaseEdge.__index = BaseEdge

local base_edge_version = 13
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
-- v13: Add `check_health` method.

----------
-- Basic Method
----------

---Create a new edge.
---If the edge has `check_health` method, it will be called automatically.
---@param _type EdgeType Type of the edge.
---@param _id EdgeID ID of the edge.
---@param _from NodeID ID of the node where the edge starts.
---@param _to NodeID ID of the node where the edge ends.
---Optional fields:
---@param _data table Custom data of the edge (subclasses should add their own fields here).
---@param _cache table Cache storage for the edge.
---@param _created_at integer Creation time of the edge (UNIX timestamp).
---@param _updated_at integer Last update time of the edge (UNIX timestamp).
---@param _due_at integer Due time of the edge (UNIX timestamp).
---@param _ease integer Ease factor of the edge.
---@param _interval integer Interval of the edge.
---@param _answer_count integer Total number of answers for the edge.
---@param _ease_count integer Number of "easy" answers for the edge.
---@param _again_count integer Number of "again" answers for the edge.
---@param _state string State of the edge ("active", "removed", or "archived"). Default: `"active"`.
---@param _version integer Version of the edge.
---@return BaseEdge? base_edge The created edge, or nil if check health failed.
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

	if base_edge.check_health then
		local issues = base_edge:check_health()
		if #issues > 0 then
			vim.notify(
				"[Edge] Health check failed:\n" .. table.concat(issues, "\n") .. "\nReturn nil.",
				vim.log.levels.WARN
			)
			return nil
		end
	end

	return base_edge
end

---Basic health check for edge.
---Subclasses should override this method.
---@return string[] issues List of issues. Empty if the edge is healthy.
function BaseEdge:check_health()
	local issues = {}

	-- Check mandatory fields
	if type(self._type) ~= "string" then
		table.insert(issues, "Invalid `_type`: expected `string`, got `" .. type(self._type) .. "`;")
	end
	if type(self._id) ~= "number" then
		table.insert(issues, "Invalid `_id`: expected `number`, got `" .. type(self._id) .. "`;")
	end
	if type(self._from) ~= "number" then
		table.insert(issues, "Invalid `_from`: expected `number`, got `" .. type(self._from) .. "`;")
	end
	if type(self._to) ~= "number" then
		table.insert(issues, "Invalid `_to`: expected `number`, got `" .. type(self._to) .. "`;")
	end

	-- Check optional fields
	if type(self._data) ~= "table" then
		table.insert(issues, "Invalid `_data`: expected `table` or `nil`, got `" .. type(self._data) .. "`;")
	end
	if type(self._cache) ~= "table" then
		table.insert(issues, "Invalid `_cache`: expected `table` or `nil`, got `" .. type(self._cache) .. "`;")
	end
	if type(self._created_at) ~= "number" then
		table.insert(
			issues,
			"Invalid `_created_at`: expected `number` or `nil`, got `" .. type(self._created_at) .. "`;"
		)
	end
	if type(self._updated_at) ~= "number" then
		table.insert(
			issues,
			"Invalid `_updated_at`: expected `number` or `nil`, got `" .. type(self._updated_at) .. "`;"
		)
	end
	if type(self._due_at) ~= "number" then
		table.insert(issues, "Invalid `_due_at`: expected `number` or `nil`, got `" .. type(self._due_at) .. "`;")
	end
	if type(self._ease) ~= "number" then
		table.insert(issues, "Invalid `_ease`: expected `number` or `nil`, got `" .. type(self._ease) .. "`;")
	end
	if type(self._interval) ~= "number" then
		table.insert(issues, "Invalid `_interval`: expected `number` or `nil`, got `" .. type(self._interval) .. "`;")
	end
	if type(self._answer_count) ~= "number" then
		table.insert(
			issues,
			"Invalid `_answer_count`: expected `number` or `nil`, got `" .. type(self._answer_count) .. "`;"
		)
	end
	if type(self._ease_count) ~= "number" then
		table.insert(
			issues,
			"Invalid `_ease_count`: expected `number` or `nil`, got `" .. type(self._ease_count) .. "`;"
		)
	end
	if type(self._again_count) ~= "number" then
		table.insert(
			issues,
			"Invalid `_again_count`: expected `number` or `nil`, got `" .. type(self._again_count) .. "`;"
		)
	end
	if type(self._state) ~= "string" then
		table.insert(issues, "Invalid `_state`: expected `string` or `nil`, got `" .. type(self._state) .. "`;")
	end
	if type(self._version) ~= "number" then
		table.insert(issues, "Invalid `_version`: expected `number` or `nil`, got `" .. type(self._version) .. "`;")
	end

	return issues
end

----------
-- Graph Method
-- TODO: How to remove these methods?
----------

---@abstract
---Handle the edge before adding it to the graph.
---@param ... any Additional arguments.
---@return nil
---@diagnostic disable-next-line: unused-vararg
function BaseEdge:before_add_into_graph(...)
	-- vim.notify("[Edge] Method `before_add_into_graph` is not implemented.")
end

---@abstract
---Handle the edge after adding it to the graph.
---@param ... any Additional arguments.
---@return nil
---@diagnostic disable-next-line: unused-vararg
function BaseEdge:after_add_into_graph(...)
	-- vim.notify("[Edge] Method `after_add_into_graph` is not implemented.")
end

---@abstract
---Handle the edge before removing it from the graph.
---@param ... any Additional arguments.
---@return nil
---@diagnostic disable-next-line: unused-vararg
function BaseEdge:before_remove_from_graph(...)
	-- vim.notify("[Edge] Method `before_remove_from_graph` is not implemented.")
end

---@abstract
---Handle the edge after removing it from the graph.
---@param ... any Additional arguments.
---@return nil
---@diagnostic disable-next-line: unused-vararg
function BaseEdge:after_remove_from_graph(...)
	-- vim.notify("[Edge] Method `after_remove_from_graph` is not implemented.")
end

--------------------

return BaseEdge
