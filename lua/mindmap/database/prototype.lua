--------------------
-- Class PrototypeNode
--------------------

---@alias NodeID integer
---@alias NodeType string

---@class PrototypeNode
---Mandatory fields:
---@field file_name string Name of the file where the node is from.
---@field rel_file_path string Relative path to the project root of the file where the node is from.
---Optional fields:
---@field data table Data of the node. Subclass should put there own data in this field.
---@field type NodeType Type of the node.
---@field tag string[] Tag of the node.
---@field version integer Version of the node.
---@field created_at integer Created time of the node in UNIX timestemp format.
---@field incoming_edge_ids EdgeID[] Ids of incoming edges to this node.
---@field outcoming_edge_ids EdgeID[] Ids of outcoming edges from this node.
---@field cache table<string, any> Cache of the node.
local PrototypeNode = {}

local prototype_node_version = 4
-- v0: Initial version.
-- v1: Add `tag` field.
-- v2: Remove `id` field.
-- v3: Make `type` field auto generated.
-- v4: Factory.

----------
-- Instance Method
----------

---Create a new node.
---@param file_name string Name of the file where the node is from.
---@param rel_file_path string Relative path to the project root of the file where the node is from.
---
---@param data? table Data of the node. Subclass should put there own data in this field.
---@param type? NodeType Type of the node.
---@param tag? string[] Tag of the node.
---@param version? integer Version of the node.
---@param created_at? integer Created time of the node in UNIX timestemp format.
---@param incoming_edge_ids? EdgeID[] Ids of incoming edges to this node.
---@param outcoming_edge_ids? EdgeID[] Ids of outcoming edges from this node.
---@return PrototypeNode _ The created node.
function PrototypeNode:new(
	file_name,
	rel_file_path,
	--
	data,
	type,
	tag,
	version,
	created_at,
	incoming_edge_ids,
	outcoming_edge_ids
)
	local prototype_node = {
		file_name = file_name,
		rel_file_path = rel_file_path,
		--
		data = data or {},
		type = type or "PrototypeNode",
		tag = tag or {},
		version = version or prototype_node_version,
		created_at = created_at or tonumber(os.time()),
		incoming_edge_ids = incoming_edge_ids or {},
		outcoming_edge_ids = outcoming_edge_ids or {},
	}

	setmetatable(prototype_node, self)
	self.__index = self

	return prototype_node
end

---Add incoming edge to the node.
---@param incoming_edge_id EdgeID ID of the incoming edge to be added.
---@return nil _ This function does not return anything.
function PrototypeNode:add_incoming_edge_id(incoming_edge_id)
	table.insert(self.incoming_edge_ids, incoming_edge_id)
end

---Remove incoming edge from the node.
---@param incoming_edge_id EdgeID ID of the incoming edge to be removed.
---@return nil _ This function does not return anything.
function PrototypeNode:remove_incoming_edge_id(incoming_edge_id)
	for i = 1, #self.incoming_edge_ids do
		if self.incoming_edge_ids[i] == incoming_edge_id then
			table.remove(self.incoming_edge_ids, i)
			break
		end
	end
end

---Add outcoming edge to the node.
---@param outcoming_edge_id EdgeID ID of the outcoming edge to be added.
---@return nil _ This function does not return anything.
function PrototypeNode:add_outcoming_edge_id(outcoming_edge_id)
	table.insert(self.outcoming_edge_ids, outcoming_edge_id)
end

---Remove outcoming edge from the node.
---@param outcoming_edge_id EdgeID ID of the outcoming edge to be removed.
---@return nil _ This function does not return anything.
function PrototypeNode:remove_outcoming_edge_id(outcoming_edge_id)
	for i = 1, #self.outcoming_edge_ids do
		if self.outcoming_edge_ids[i] == outcoming_edge_id then
			table.remove(self.outcoming_edge_ids, i)
			break
		end
	end
end

---@abstract
---Get the content of the node.
---@return any content Content of the node.
---@diagnostic disable-next-line: unused-vararg
function PrototypeNode:get_content(...)
	error("[PrototypeNode] Please implement function `get_content` in subclass.")
end

---@abstract
---Convert the node to a table.
---@diagnostic disable-next-line: unused-vararg
function PrototypeNode:to_table(...)
	error("[PrototypeNode] Please implement function `to_table` in subclass.")
end

---@abstract
---Convert the table to a node.
---@diagnostic disable-next-line: unused-vararg
function PrototypeNode:from_table(...)
	error("[PrototypeNode] Please implement function `to_table` in subclass.")
end

----------
-- Class Method
----------

--------------------
-- Class PrototypeEdge
--------------------

---@alias EdgeID integer
---@alias EdgeType string

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
	error("[PrototypeEdge] Please implement function `to_table` in subclass.")
end

----------
-- Class Method
----------

--------------------

return {
	node = PrototypeNode,
	edge = PrototypeEdge,
}
