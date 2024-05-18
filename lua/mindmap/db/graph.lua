local Node = require("mindmap.db.node")
local Edge = require("mindmap.db.edge")

---@class Graph
---
---@field nodes table<string, Node> Nodes in the graph. Key is the node ID.
---@field edges table<string, Edge> Edges in the graph. Key is the edge ID.
local Graph = {}

--------------------
-- Instance Method
--------------------

---Create a new graph.
---@param nodes? Node[] Nodes in the graph.
---@param edges? Edge[] Edges in the graph.
function Graph:new(nodes, edges)
	local graph = {
		nodes = nodes or {},
		edges = edges or {},
	}

	setmetatable(graph, Graph)
	self.__index = self

	return graph
end

---Spaced repetition function: Convert edge to card.
---@param id string ID of the edge to convert.
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

---Convert graph to table.
---@param graph Graph Graph to convert.
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

---Convert table to graph.
---@param table table Table to convert.
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

---Save the graph to a JSON file.
---@param graph Graph Graph to save.
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

	graph.nodes["1"] = Node:new("1")
	graph.nodes["2"] = Node:new("2")
	graph.nodes["3"] = Node:new("3")

	graph.edges["1"] = Edge:new("1", "2")
	graph.edges["2"] = Edge:new("2", "3")
	graph.edges["3"] = Edge:new("3", "1")

	local ok = Graph.save(graph, "test.json")
	print(ok)
end

return Graph
