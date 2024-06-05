local utils = require("mindmap.utils")
local ts_utils = require("mindmap.ts_utils")

---@alias EdgeID integer
---@alias EdgeType string

--------------------
-- Class PrototypeEdge
--------------------

---@class PrototypeEdge
---Mandatory fields:
---@field from_node_id NodeID Where this edge is from.
---@field to_node_id NodeID Where this edge is to.
---Optional fields:
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

local prototype_edge_version = 4
-- v0: Initial version.
-- v1: Add `tag` field.
-- v2: Remove `id` field.
-- v3: Make `type` field auto generated.
-- v4: Factory.

----------
-- Instance Method
----------

---Create a new edge.
---@param from_node_id NodeID Where this edge is from.
---@param to_node_id NodeID Where this edge is to.
---
---@param data? table Data of the edge.
---@param type? EdgeType Type of the edge.
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
	type,
	tag,
	version,
	created_at,
	updated_at,
	due_at,
	ease,
	interval
)
	local prototype_edge = {
		from_node_id = from_node_id,
		to_node_id = to_node_id,
		--
		data = data or {},
		type = type or "PrototypeEdge",
		tag = tag or {},
		version = version or prototype_edge_version, -- TODO: add merge function
		created_at = created_at or tonumber(os.time()),
		updated_at = updated_at or tonumber(os.time()),
		due_at = due_at or 0,
		ease = ease or 250,
		interval = interval or 1,
	}

	setmetatable(prototype_edge, self)
	self.__index = self

	return prototype_edge
end

---@abstract
---Spaced repetition function: Get spaced repetition information of the edge.
---@return string[] _ Spaced repetition information of the edge.
function PrototypeEdge:get_sp_info()
	error("[PrototypeEdge] Please implement function `get_sp_info` in subclass.")
end

----------
-- Class Method
----------

--------------------
-- Factory
--------------------

local edge_factory = require("mindmap.graph.factory")
edge_factory.register_base("EdgeClass", PrototypeEdge)

local edge_cls_methods = {
	to_table = function(cls, self)
		return {
			from_node_id = self.from_node_id,
			to_node_id = self.to_node_id,
			--
			data = self.data,
			type = self.type,
			tag = self.tag,
			version = self.version,
			created_at = self.created_at,
			updated_at = self.updated_at,
			due_at = self.due_at,
			ease = self.ease,
			interval = self.interval,
		}
	end,

	from_table = function(cls, self, table)
		return cls:new(
			table.from_node_id,
			table.to_node_id,
			--
			table.data,
			table.type,
			table.tag,
			table.version,
			table.created_at,
			table.updated_at,
			table.due_at,
			table.ease,
			table.interval
		)
	end,
}

--------------------
-- Subclass SimpleEdge
--------------------

---@class SimpleEdge : PrototypeEdge

edge_factory.create_class(
	-- Class category
	"EdgeClass",
	-- Class type
	"SimpleEdge",
	-- Additional fields
	{
		--
	},
	-- Additional methods
	{
		--
	}
)
edge_factory.add_cls_method("EdgeClass", "SimpleEdge", edge_cls_methods)

--------------------
-- Subclass SelfLoopContentEdge
--------------------

---@class SelfLoopContentEdge : PrototypeEdge

edge_factory.create_class(
	-- Class category
	"EdgeClass",
	-- Class type
	"SelfLoopContentEdge",
	-- Additional fields
	{
		--
	},
	-- Additional methods
	{
		--
	}
)
edge_factory.add_cls_method("EdgeClass", "SelfLoopContentEdge", edge_cls_methods)

--------------------
-- Subclass SelfLoopSubheadingEdge
--------------------

---@class SelfLoopSubheadingEdge : PrototypeEdge

edge_factory.create_class(
	-- Class category
	"EdgeClass",
	-- Class type
	"SelfLoopSubheadingEdge",
	-- Additional fields
	{
		--
	},
	-- Additional methods
	{
		--
	}
)
edge_factory.add_cls_method("EdgeClass", "SelfLoopSubheadingEdge", edge_cls_methods)

--------------------

return edge_factory.cls_categories["EdgeClass"]
