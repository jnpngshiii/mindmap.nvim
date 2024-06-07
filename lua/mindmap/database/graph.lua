local logger_class = require("mindmap.database.logger")

local utils = require("mindmap.utils")

---@class Graph
---
---@field save_path string Path to load and save the graph. Default: {current_project_path}.
---
---@field log_level string Log level of the graph. Default: "INFO".
---@field show_log_in_nvim boolean Show log in Neovim. Default: false.
---@field logger Logger Logger of the graph.
---
---@field node_prototype PrototypeNode Prototype of the node. Used to create sub node classes. Must have a `new` method and a `data` field.
---@field edge_prototype PrototypeEdge Prototype of the edge. Used to create sub edge classes. Must have a `new` method and a `data` field.
---@field node_class table<NodeType, PrototypeNode> Registered sub node classes.
---@field edge_class table<EdgeType, PrototypeEdge> Registered sub edge classes.
---@field nodes table<NodeID, PrototypeNode> Nodes in the graph. Key is the ID of the node. If the value is nil, the node is removed.
---@field edges table<EdgeID, PrototypeEdge> Edges in the graph. Key is the ID of the edge. If the value is nil, the edge is removed.
local Graph = {}

--------------------
-- Instance Method
--------------------

---Register sub classes.
---@param sub_cls_category string Category of the sub class. Must be "node" or "edge".
---@param sub_cls_info table<string, table> Information of the sub class.
---Information must have `data`, `ins_methods` and `cls_methods` fields.
---Method examples:
---  `cls_method(cls, self)`
---  `ins_method(self, ...)`
---The `cls_methods` will be registered to a instance and converted to a instance method.
function Graph:register_sub_class(sub_cls_category, sub_cls_info)
	local sub_cls_category_tbl = self[sub_cls_category .. "_class"]

	assert(
		self[sub_cls_category .. "_prototype"],
		"No prototype registered for sub `" .. sub_cls_category .. "` class."
	)
	local prototype = self[sub_cls_category .. "_prototype"]

	for cls_type, cls_info in pairs(sub_cls_info) do
		assert(type(cls_info) == "table", "Information of the sub class must be a table.")

		-- Check if the class already exists.
		if not sub_cls_category_tbl.cls_type then
			---@diagnostic disable-next-line: missing-parameter
			local sub_class = prototype:new() -- TODO: fix this

			-- Add data in the sub class.
			if cls_info.data then
				for field, default in pairs(cls_info.data or {}) do
					assert(type(default) ~= "function", "Data `" .. field .. "` is a function.")
					sub_class.data[field] = default
				end
			end

			-- Add instance methods in the sub class.
			if cls_info.ins_methods then
				for name, func in pairs(cls_info.ins_methods or {}) do
					assert(type(func) == "function", "Instance method `" .. name .. "` is not a function.")
					sub_class[name] = func
				end
			end

			-- Add class methods in the sub class.
			if cls_info.cls_methods then
				for name, func in pairs(cls_info.cls_methods or {}) do
					sub_class[name] = function(...)
						return func(sub_class, ...) -- TODO: check this
					end
				end
			end

			---@diagnostic disable-next-line: duplicate-set-field
			function sub_class:new(...)
				local sub_class_instance = prototype:new(...)

				sub_class_instance.type = cls_type

				setmetatable(sub_class_instance, self)
				self.__index = self

				return sub_class_instance
			end

			-- Register the new class.
			sub_cls_category_tbl[cls_type] = sub_class
			self.logger:info(sub_cls_category, "Register Node type `" .. cls_type .. "`.")
		end
	end
end

---Create a new graph.
---@param save_path? string Path to load and save the graph. Default: {current_project_path}.
---
---@param log_level? string Log level of the graph. Default: "INFO".
---@param show_log_in_nvim? boolean Show log in Neovim when added. Default: false.
---
---@param node_prototype PrototypeNode Prototype of the node. Used to create sub node classes. Must have a `new` method and a `data` field.
---@param edge_prototype PrototypeEdge Prototype of the edge. Used to create sub edge classes. Must have a `new` method and a `data` field.
---@param node_cls_info table<NodeType, table> Node class information used to create sub node classes. Information table must have `data` and `ins_methods` fields.
---@param edge_cls_info table<EdgeType, table> Edge class information used to create sub edge classes. Information table must have `data` and `ins_methods` fields.
---@return Graph _ The new graph.
function Graph:new(
	save_path,
	--
	log_level,
	show_log_in_nvim,
	--
	node_prototype,
	edge_prototype,
	node_cls_info,
	edge_cls_info
)
	local graph = {
		save_path = save_path or utils.get_file_info()[4],
		--
		log_level = log_level or "INFO",
		show_log_in_nvim = show_log_in_nvim or false,
		logger = logger_class["Logger"]:new(log_level, show_log_in_nvim),
		--
		node_prototype = node_prototype,
		edge_prototype = edge_prototype,
		node_class = {},
		edge_class = {},
		nodes = {},
		edges = {},
	}

	setmetatable(graph, self)
	self.__index = self

	-- Register sub node and edge classes.
	graph:register_sub_class("node", node_cls_info)
	graph:register_sub_class("edge", edge_cls_info)

	-- Load nodes and edges from the given information.
	local json_path = graph.save_path .. "/" .. ".mindmap.json"
	local json, _ = io.open(json_path, "r")
	if not json then
		graph.logger:warn("Graph", "Can not open file `" .. json_path .. "`. Skip loading.")
	else
		local json_content = vim.fn.json_decode(json:read("*all"))
		json:close()

		for node_id, node in pairs(json_content.nodes) do
			-- TODO: add check for node type
			graph.nodes[node_id] = graph.node_class[node.type]:from_table(node)
		end
		for edge_id, edge in pairs(json_content.edges) do
			-- TODO: add check for edge type
			graph.edges[edge_id] = graph.edge_class[edge.type]:from_table(edge)
		end
	end

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
	self.logger:info("Node", "Remove " .. self.nodes[node_id].type .. " <" .. node_id .. "> and related edges.")

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

	self.nodes[node_id].state = "removed"
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

	self.edges[edge_id].state = "removed"

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

---Spaced repetition function: get spacd repetition information from the edge.
---@param edge_id EdgeID ID of the edge.
---@return string[] front, string[] back, integer created_at, integer updated_at, integer due_at, integer ease, integer interval The spaced repetition information.
function Graph:get_sp_info_from_edge(edge_id)
	local edge = self.edges[edge_id]

	local to_node = self.nodes[edge.to_node_id]
	local front, _ = to_node:get_content(edge.type)

	local from_node = self.nodes[edge.from_node_id]
	local _, back = from_node:get_content(edge.type)

	return front, back, edge.created_at, edge.updated_at, edge.due_at, edge.ease, edge.interval
end

---Save a graph to a JSON file.
function Graph:save()
	local graph_tbl = {
		-- save_path = self.save_path,
		--
		-- log_level = self.log_level,
		-- show_log_in_nvim = self.show_log_in_nvim,
		--
		nodes = {},
		edges = {},
	}

	for node_id, node in ipairs(self.nodes) do
		graph_tbl.nodes[node_id] = node:to_table()
	end
	for edge_id, edge in ipairs(self.edges) do
		graph_tbl.edges[edge_id] = edge:to_table()
	end

	local json_path = self.save_path .. "/" .. ".mindmap.json"
	local json, _ = io.open(json_path, "w")
	if not json then
		self.logger:error("Graph", "Can not open file `" .. json_path .. "`. Skip saving.")
		return
	end

	local json_content = vim.fn.json_encode(graph_tbl)
	json:write(json_content)
	json:close()
end

--------------------
-- class Method
--------------------

--------------------

return Graph
