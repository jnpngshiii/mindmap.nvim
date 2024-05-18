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
function Graph:new(nodes, edges)
	local graph = {
		nodes = nodes or {},
		edges = edges or {},
	}

	setmetatable(graph, Graph)
	self.__index = self

	return graph
end

---Spaced repetition function: Convert an edge to a card.
---@param id string ID of the edge to be converted.
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

if true then
	local graph = Graph:new()

	local node1 = Node:new("test")
	local node2 = Node:new("test")
	local node3 = Node:new("test")

	local edge1 = Edge:new("test", node1.id, node2.id)
	local edge2 = Edge:new("test", node2.id, node3.id)
	local edge3 = Edge:new("test", node3.id, node1.id)

	graph:add_node(node1)

	local ok = Graph.save(graph, "test.json")
	print(ok)
end

return Graph
