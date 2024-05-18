local Node = require("mindmap.db.node")
local Edge = require("mindmap.db.edge")

---@class Graph
---
---@field nodes table<string, Node> Nodes in the graph. Key is the ID of the node.
---@field edges table<string, Edge> Edges in the graph. Key is the ID of the edge.
local Graph = {}

--------------------
-- Instance Method
--------------------

---Create a new graph.
---@param nodes? table<string, Node> Nodes in the graph.
---@param edges? table<string, Edge> Edges in the graph.
---@return Graph
function Graph:new(nodes, edges)
	local graph = {
		nodes = nodes or {},
		edges = edges or {},
	}

	setmetatable(graph, Graph)
	self.__index = self

	return graph
end

---Add a node to the graph and return its ID.
---@param type string Type of the node.
---@param data? table Data of the node. Subclass should put there own data in this field.
---@param incoming_edge_ids? table<ID, ID> IDs of incoming edges to this node.
---@param outcoming_edge_ids? table<ID, ID> IDs of outcoming edges from this node.
---@param id? ID ID of the node.
---@param created_at? integer Created time of the node.
---@return ID
function Graph:add_node(type, data, incoming_edge_ids, outcoming_edge_ids, id, created_at)
	local node = Node:new(type, data, incoming_edge_ids, outcoming_edge_ids, id, created_at)
	self.nodes[node.id] = node

	return node.id
end

---Remove a node from the graph and all edges related to it using ID.
---@param id ID ID of the node to be removed.
---@return nil
function Graph:remove_node(id)
	local node = self.nodes[id]

	for _, incoming_edge_id in pairs(node.incoming_edge_ids) do
		local edge = self.edges[incoming_edge_id]
		local from_node = self.nodes[edge.from_node_id]
		from_node:remove_outcoming_edge_id(incoming_edge_id)
		self:remove_edge(edge.id)
	end

	for _, outcoming_edge_id in pairs(node.outcoming_edge_ids) do
		local edge = self.edges[outcoming_edge_id]
		local to_node = self.nodes[edge.to_node_id]
		to_node:remove_incoming_edge_id(outcoming_edge_id)
		self:remove_edge(edge.id)
	end

	self.nodes[id] = nil
end

---Add a edge to the graph and return its ID.
---@param type string Edge type.
---@param from_node_id string Where this edge is from.
---@param to_node_id string Where this edge is to.
---@param data? table Data of the edge. Subclass should put there own data in this field.
---@param id? ID ID of the edge.
---@param created_at? integer Created time of the edge.
---@param updated_at? integer Space repetition updated time of the edge.
---@param due_at? integer Space repetition due time of the edge.
---@param ease? integer Space repetition ease of the edge.
---@param interval? integer Space repetition interval of the edge.
---@return ID
function Graph:add_edge(type, from_node_id, to_node_id, data, id, created_at, updated_at, due_at, ease, interval)
	local edge = Edge:new(type, from_node_id, to_node_id, data, id, created_at, updated_at, due_at, ease, interval)
	self.edges[edge.id] = edge

	local from_node = self.nodes[from_node_id]
	from_node:add_outcoming_edge_id(edge.id)

	local to_node = self.nodes[to_node_id]
	to_node:add_incoming_edge_id(edge.id)

	return edge.id
end

---Remove an edge from the graph using ID.
---@param id ID ID of the edge to be removed.
---@return nil
function Graph:remove_edge(id)
	local edge = self.edges[id]

	local from_node = self.nodes[edge.from_node_id]
	from_node:remove_outcoming_edge_id(id)

	local to_node = self.nodes[edge.to_node_id]
	to_node:remove_outcoming_edge_id(edge.id)

	self.edges[id] = nil
end

---Spaced repetition function: Convert an edge to a card.
---@param id ID ID of the edge to be converted.
---@return table % { front, back, updated_at, due_at, ease, interval }
function Graph:to_card(id)
	local edge = self.edges[id]
	local front = self.nodes[edge.from_node_id]:content()
	local back = self.nodes[edge.to_node_id]:content()
	local updated_at = edge.updated_at
	local due_at = edge.due_at
	local ease = edge.ease
	local interval = edge.interval
	return { front, back, updated_at, due_at, ease, interval }
end

--------------------
-- class Method
--------------------

---Convert a graph to a table.
---@param graph Graph Graph to be converted.
---@return table
function Graph.to_table(graph)
	local nodes = {}
	for _, node in pairs(graph.nodes) do
		nodes[node.id] = Node.to_table(node)
	end

	local edges = {}
	for _, edge in pairs(graph.edges) do
		edges[edge.id] = Edge.to_table(edge)
	end

	return {
		nodes = nodes,
		edges = edges,
	}
end

---Convert a table to a graph.
---@param table table Table to be converted.
---@return Graph
function Graph.from_table(table)
	local nodes = {}
	for _, node in pairs(table.nodes) do
		nodes[node.id] = Node.from_table(node)
	end

	local edges = {}
	for _, edge in pairs(table.edges) do
		edges[edge.id] = Edge.from_table(edge)
	end

	return Graph:new(nodes, edges)
end

---Save a graph to a JSON file.
---@param graph Graph Graph to be saved.
---@param save_path string Path to save the graph.
---@return boolean
function Graph.save(graph, save_path)
	local json_content = vim.fn.json_encode(Graph.to_table(graph))

	local json, _ = io.open(save_path, "w")
	if not json then
		return false
	end

	json:write(json_content)
	json:close()

	return true
end

---Load a graph from a JSON file.
---@param save_path string Path to save the graph.
---@return Graph|nil
function Graph.load(save_path)
	local json, _ = io.open(save_path, "r")
	if not json then
		return nil
	end

	local json_content = json:read("*all")
	json:close()

	return Graph.from_table(vim.fn.json_decode(json_content))
end

--------------------

if false then
	local graph = Graph:new()

	local node1 = graph:add_node("test")
	local node2 = graph:add_node("test")
	local node3 = graph:add_node("test")

	local edge1 = graph:add_edge("test", node1, node2)
	local edge2 = graph:add_edge("test", node2, node3)
	local edge3 = graph:add_edge("test", node3, node1)

	local ok = Graph.save(graph, "test.json")
	print(ok)
end

return Graph
