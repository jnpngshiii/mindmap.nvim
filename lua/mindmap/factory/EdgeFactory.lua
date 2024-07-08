local logger = require("logger").register_plugin("mindmap"):register_source("Factory.Edge")

local BaseFactory = require("mindmap.base.BaseFactory")

--------------------
-- Class EdgeFactory
--------------------

---@class EdgeFactory : BaseFactory
local EdgeFactory = {}
EdgeFactory.__index = EdgeFactory
setmetatable(EdgeFactory, BaseFactory)

---Create a new factory.
---@param base_cls table Base class of the factory. Registered classes should inherit from this class.
---@return EdgeFactory factory The created factory.
function EdgeFactory:new(base_cls)
  local factory = {
    base_cls = base_cls,
    registered_cls = {},
  }
  setmetatable(factory, EdgeFactory)

  return factory
end

---Convert an edge to a table.
---@param edge BaseEdge The edge to be converted.
---@return table edge_table The converted table.
function EdgeFactory:to_table(edge)
  return {
    _type = edge._type,
    _id = edge._id,
    _from = edge._from,
    _to = edge._to,
    --
    _data = edge._data,
    -- _cache = edge._cache,
    _created_at = edge._created_at,
    _updated_at = edge._updated_at,
    _due_at = edge._due_at,
    _ease = edge._ease,
    _interval = edge._interval,
    _answer_count = edge._answer_count,
    _ease_count = edge._ease_count,
    _again_count = edge._again_count,
    _status = edge._status,
    _version = edge._version,
  }
end

---Convert a table to an edge.
---@param registered_type string Which registered type the table should be converted to.
---@param tbl table The table to be converted.
---@return BaseEdge? edge The converted edge or nil if conversion fails.
function EdgeFactory:from_table(registered_type, tbl)
  local registered_cls = self:get_registered_class(registered_type)

  return registered_cls:new(
    tbl._type,
    tbl._id,
    tbl._from,
    tbl._to,
    --
    tbl._data,
    {}, -- tbl._cache,
    tbl._created_at,
    tbl._updated_at,
    tbl._due_at,
    tbl._ease,
    tbl._interval,
    tbl._answer_count,
    tbl._ease_count,
    tbl._again_count,
    tbl._status,
    tbl._version
  )
end

--------------------

return EdgeFactory
