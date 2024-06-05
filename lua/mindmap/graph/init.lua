local node_class = require("mindmap.graph.node")
local edge_class = require("mindmap.graph.edge")
local logger_class = require("mindmap.graph.logger.init")
local utils = require("mindmap.utils")

---@class Graph
---
---@field log_level string Logger log level of the graph. Default: "INFO".
---@field show_log_in_nvim boolean Show log in Neovim when added.
---@field save_path string Path to load and save the graph. Default: {current_project_path}.
---@field nodes table<NodeID, PrototypeNode|HeadingNode|ExcerptNode> Nodes in the graph. Key is the ID of the node. If the value is 0, the node is removed.
---@field edges table<EdgeID, PrototypeEdge|SelfLoopContentEdge|SelfLoopSubheadingEdge> Edges in the graph. Key is the ID of the edge. If the value is 0, the edge is removed.
---@field logger Logger Logger of the graph.
local Graph = {}

--------------------
-- Instance Method
--------------------

---Create a new graph.
---@param log_level? string Logger log level of the graph. Default: "INFO".
---@param show_log_in_nvim? boolean Show log in Neovim when added. Default: false.
---@param save_path? string Path to load and save the graph. Default: {current_project_path}.
---@param nodes? table<NodeID, PrototypeNode|HeadingNode|ExcerptNode> Nodes in the graph. Key is the ID of the node.
---@param edges? table<EdgeID, PrototypeEdge|SelfLoopContentEdge|SelfLoopSubheadingEdge> Edges in the graph. Key is the ID of the edge.
---@param logger? Logger Logger of the graph.
---@return Graph _ The new graph.
function Graph:new(log_level, show_log_in_nvim, save_path, nodes, edges, logger)
	local graph = {
		log_level = log_level or "INFO",
		show_log_in_nvim = show_log_in_nvim or false,
		save_path = save_path or utils.get_file_info()[4],
		nodes = nodes or {},
		edges = edges or {},
		logger = logger_class["Logger"]:new(log_level, show_log_in_nvim) or logger,
	}

	setmetatable(graph, self)
	self.__index = self

	return graph
end

---Add a node to the graph.
---@param node PrototypeNode Node to be added.
---@return nil _ This function does not return anything.
function Graph:add_node(node)
	local node_id = #self.nodes + 1
	self.nodes[node_id] = node

	self.logger:info("Node", "Add " .. node.type .. " <" .. node_id .. ">.")
end

---Remove a node from the graph and all edges related to it using ID.
---@param node_id NodeID ID of the node to be removed.
---@return nil _ This function does not return anything.
function Graph:remove_node(node_id)
	local node = self.nodes[node_id]

	for _, incoming_edge_id in pairs(node.incoming_edge_ids) do
		local incoming_edge = self.edges[incoming_edge_id]
		local from_node = self.nodes[incoming_edge.from_node_id]
		from_node:remove_outcoming_edge_id(incoming_edge_id)
		self:remove_edge(incoming_edge_id)
	end

	for _, outcoming_edge_id in pairs(node.outcoming_edge_ids) do
		local outcoming_edge = self.edges[outcoming_edge_id]
		local to_node = self.nodes[outcoming_edge.to_node_id]
		to_node:remove_incoming_edge_id(outcoming_edge_id)
		self:remove_edge(outcoming_edge_id)
	end

	self.nodes[node_id] = nil -- Mark as removed

	self.logger:info("Node", "Remove " .. self.nodes[node_id].type .. " <" .. node_id .. "> and related edges.")
end

---Add a edge to the graph.
---@param edge PrototypeEdge Edge to be added.
---@return nil _ This function does not return anything.
function Graph:add_edge(edge)
	local edge_id = #self.edges + 1
	self.edges[edge_id] = edge

	local from_node = self.nodes[edge.from_node_id]
	from_node:add_outcoming_edge_id(edge_id)
	local to_node = self.nodes[edge.to_node_id]
	to_node:add_incoming_edge_id(edge_id)

	self.logger:info(
		"Edge",
		"Add "
			.. edge.type
			.. " <"
			.. edge_id
			.. "> from "
			.. from_node.type
			.. " <"
			.. edge.from_node_id
			.. "> to "
			.. to_node.type
			.. " <"
			.. edge.to_node_id
			.. ">."
	)
end

---Remove an edge from the graph using ID.
---@param edge_id EdgeID ID of the edge to be removed.
---@return nil _ This function does not return anything.
function Graph:remove_edge(edge_id)
	local edge = self.edges[edge_id]

	local from_node = self.nodes[edge.from_node_id]
	from_node:remove_outcoming_edge_id(edge_id)

	local to_node = self.nodes[edge.to_node_id]
	to_node:remove_outcoming_edge_id(edge_id)

	self.edges[edge_id] = nil -- Mark as removed

	self.logger:info(
		"Edge",
		"Remove "
			.. edge.type
			.. " <"
			.. edge_id
			.. "> from "
			.. from_node.type
			.. " <"
			.. edge.from_node_id
			.. "> to "
			.. to_node.type
			.. " <"
			.. edge.to_node_id
			.. ">."
	)
end

---@deprecated
---Spaced repetition function: get card information from the given edge.
---@param edge_id EdgeID ID of the edge to be converted.
---@return string[] front, string[] back, integer created_at, integer updated_at, integer due_at, integer ease, integer interval The getted card information.
function Graph:get_card_info_from_edge(edge_id)
	local edge = self.edges[edge_id]

	local front
	local back
	if edge.type == "SelfLoopContentEdge" then
		local node = self.nodes[edge.from_node_id]
		if node.type == "HeadingNode" then
			local title_text, content_text, _ = node:get_content(edge.from_node_id)

			front = title_text
			back = content_text
		else
			self.logger:error("Node", "Can not convert node type <" .. node.type .. "> to card.")
		end
	elseif edge.type == "SelfLoopSubheadingEdge" then
		local node = self.nodes[edge.from_node_id]
		if node.type == "HeadingNode" then
			local title_text, _, sub_heading_text = node:get_content(edge.from_node_id)

			front = title_text
			back = sub_heading_text
		else
			self.logger:error("Node", "Can not convert node type <" .. node.type .. "> to card.")
		end
	elseif edge.type == "SimpleEdge" then
		-- TODO: needs update
		local from_node = self.nodes[edge.from_node_id]
		if from_node.type == "ExcerptNode" then
			back = from_node:get_content()
		end
		local to_node = self.nodes[edge.to_node_id]
		if to_node.type == "HeadingNode" then
			front, _, _ = to_node:get_content(edge.to_node_id)
		end
	else
		self.logger:error("Edge", "Can not convert edge type <" .. edge.type .. "> to card.")
	end

	return front, back, edge.created_at, edge.updated_at, edge.due_at, edge.ease, edge.interval
end

--------------------
-- class Method
--------------------

---Convert a graph to a table.
---@param graph Graph Graph to be converted.
---@return table _ The converted table.
function Graph.to_table(graph)
	local nodes = {}
	for node_id, node in ipairs(graph.nodes) do
		nodes[node_id] = node_class[node.type].to_table(node)
	end

	local edges = {}
	for edge_id, edge in ipairs(graph.edges) do
		edges[edge_id] = edge_class[edge.type].to_table(edge)
	end

	return {
		log_level = graph.log_level,
		show_log_in_nvim = graph.show_log_in_nvim,
		save_path = graph.save_path,
		nodes = nodes,
		edges = edges,
	}
end

---Convert a table to a graph.
---@param table table Table to be converted.
---@return Graph _ The converted graph.
function Graph.from_table(table)
	local nodes = {}
	for node_id, node in ipairs(table.nodes) do
		nodes[node_id] = node_class[node.type].from_table(node)
	end

	local edges = {}
	for edge_id, edge in ipairs(table.edges) do
		edges[edge_id] = edge_class[edge.type].from_table(edge)
	end

	return Graph:new(table.log_level, table.show_log_in_nvim, table.save_path, nodes, edges)
end

---Save a graph to a JSON file.
---@param graph Graph Graph to be saved.
---@param save_path? string Path to save the graph.
---@return nil _ This function does not return anything.
function Graph.save(graph, save_path)
	local json_content = vim.fn.json_encode(Graph.to_table(graph))

	local json, err = io.open(save_path or graph.save_path .. "/" .. ".mindmap.json", "w")
	if not json then
		error("[Graph] Could not open file: " .. err)
	end

	json:write(json_content)
	json:close()
end

---Load a graph from a JSON file.
---@param save_path string Path to save the graph.
---@return Graph? _ The loaded graph. If the file does not exist, return nil.
function Graph.load(save_path)
	save_path = save_path .. "/" .. ".mindmap.json"

	local json, _ = io.open(save_path, "r")
	if not json then
		return nil
	end

	local json_content = json:read("*all")
	json:close()

	if json_content then
		return Graph.from_table(vim.fn.json_decode(json_content))
	end

	return nil
end

--------------------

return {
	["Graph"] = Graph,
}
