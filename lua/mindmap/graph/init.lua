local node_class = require("mindmap.graph.node.init")
local edge_class = require("mindmap.graph.edge.init")
local logger_class = require("mindmap.graph.logger.init")
local misc = require("mindmap.misc")

---@class Graph
---
---@field log_level string Logger log level of the graph. Default: "INFO".
---@field show_log_in_nvim boolean Show log in Neovim when added.
---@field save_path string Path to load and save the graph. Default: {current_project_path}/.mindmap
---@field nodes table<NodeID, PrototypeNode> Nodes in the graph. Key is the ID of the node.
---@field edges table<EdgeID, PrototypeEdge> Edges in the graph. Key is the ID of the edge.
---@field logger Logger Logger of the graph.
local Graph = {}

--------------------
-- Instance Method
--------------------

---Create a new graph.
---@param log_level? string Logger log level of the graph. Default: "INFO".
---@param show_log_in_nvim? boolean Show log in Neovim when added.
---@param save_path? string Path to load and save the graph. Default: {current_project_path}/.mindmap
---@param nodes? table<NodeID, PrototypeNode> Nodes in the graph. Key is the ID of the node.
---@param edges? table<EdgeID, PrototypeEdge> Edges in the graph. Key is the ID of the edge.
---@return Graph
function Graph:new(log_level, show_log_in_nvim, save_path, nodes, edges, logger)
	local graph = {
		-- TODO: Check health?
		log_level = log_level or "INFO",
		show_log_in_nvim = show_log_in_nvim or false,
		save_path = save_path or misc.get_current_proj_path() .. "/.mindmap",
		nodes = nodes or {},
		edges = edges or {},
		logger = logger_class["Logger"]:new(log_level, show_log_in_nvim, save_path),
	}

	setmetatable(graph, self)
	self.__index = self

	return graph
end

---Add a node to the graph and return its ID.
---@param node PrototypeNode Node to be added.
---@return nil
function Graph:add_node(node)
	self.logger:info("Node", "Add " .. node.type .. " <" .. node.id .. ">.")

	self.nodes[node.id] = node
end

---Remove a node from the graph and all edges related to it using ID.
---@param node_id NodeID ID of the node to be removed.
---@return nil
function Graph:remove_node(node_id)
	self.logger:info("Node", "Remove " .. self.nodes[node_id].type .. " <" .. node_id .. "> and related edges.")

	local node = self.nodes[node_id]

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

	self.nodes[node_id] = nil
end

---Add a edge to the graph.
---@param edge PrototypeEdge Edge to be added.
---@return nil
function Graph:add_edge(edge)
	self.edges[edge.id] = edge

	local from_node = self.nodes[edge.from_node_id]
	from_node:add_outcoming_edge_id(edge.id)

	local to_node = self.nodes[edge.to_node_id]
	to_node:add_incoming_edge_id(edge.id)

	self.logger:info(
		"Edge",
		"Add "
			.. edge.type
			.. " <"
			.. edge.id
			.. "> from "
			.. from_node.type
			.. " <"
			.. edge.from_node_id
			.. "> to "
			.. to_node.type
			.. "<"
			.. edge.to_node_id
			.. ">."
	)
end

---Remove an edge from the graph using ID.
---@param edge_id EdgeID ID of the edge to be removed.
---@return nil
function Graph:remove_edge(edge_id)
	local edge = self.edges[edge_id]

	local from_node = self.nodes[edge.from_node_id]
	from_node:remove_outcoming_edge_id(edge_id)

	local to_node = self.nodes[edge.to_node_id]
	to_node:remove_outcoming_edge_id(edge.id)

	self.edges[edge_id] = nil

	self.logger:info(
		"Edge",
		"Remove "
			.. edge.type
			.. " <"
			.. edge.id
			.. "> from "
			.. from_node.type
			.. " <"
			.. edge.from_node_id
			.. "> to "
			.. to_node.type
			.. "<"
			.. edge.to_node_id
			.. ">."
	)
end

---Spaced repetition function: Convert an edge to a card.
---@param edge_id EdgeID ID of the edge to be converted.
---@return table % { front, back, updated_at, due_at, ease, interval }
function Graph:to_card(edge_id)
	local edge = self.edges[edge_id]
	local front = self.nodes[edge.from_node_id]:front()
	local back = self.nodes[edge.to_node_id]:back()
	local updated_at = edge.updated_at
	local due_at = edge.due_at
	local ease = edge.ease
	local interval = edge.interval

	self.logger:info("Card", "Convert edge <" .. edge_id .. "> to card.")

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
		nodes[node.id] = node_class[node.type].to_table(node)
	end

	local edges = {}
	for _, edge in pairs(graph.edges) do
		edges[edge.id] = edge_class[edge.type].to_table(edge)
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
		nodes[node.id] = node_class[node.type].from_table(node)
	end

	local edges = {}
	for _, edge in pairs(table.edges) do
		edges[edge.id] = edge_class[edge.type].from_table(edge)
	end

	return Graph:new(table.log_level, table.show_log_in_nvim, table.save_path, nodes, edges)
end

---Save a graph to a JSON file.
---@param graph Graph Graph to be saved.
---@param save_path? string Path to save the graph.
---@return nil
function Graph.save(graph, save_path)
	local json_content = vim.fn.json_encode(Graph.to_table(graph))
	print(graph.save_path)

	local json, err = io.open(save_path or graph.save_path .. "/" .. "graph.json", "w")
	if not json then
		error("[Graph] Could not open file: " .. err)
	end

	json:write(json_content)
	json:close()
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

	local node1 = node_class["ExcerptNode"]:new()
	local node2 = node_class["ExcerptNode"]:new()
	local node3 = node_class["ExcerptNode"]:new()
	graph:add_node(node1)
	graph:add_node(node2)
	graph:add_node(node3)

	local edge1 = edge_class["selfLoopEdge"]:new(node1.id)
	local edge2 = edge_class["selfLoopEdge"]:new(node2.id)
	local edge3 = edge_class["selfLoopEdge"]:new(node3.id)
	graph:add_edge(edge1)
	graph:add_edge(edge2)
	graph:add_edge(edge3)

	graph:save()
end

return {
	["Graph"] = Graph,
}
