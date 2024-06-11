local Logger = require("mindmap.graph.logger")

local utils = require("mindmap.utils")

---@class Graph
---
---@field save_path string Path to load and save the graph. Default: {current_project_path}.
---
---@field log_level string Log level of the graph. Default: "INFO".
---@field show_log_in_nvim boolean Show log in Neovim. Default: false.
---
---@field default_node_type string Default type of the node. Default: "SimpleNode".
---@field node_prototype_cls PrototypeNode Prototype of the node. Used to create sub node classes. Must have a `new` method and a `data` field.
---@field node_sub_cls_info table<NodeType, table> Information of the sub node classes. Must have `data`, `ins_methods` and `cls_methods` fields.
---@field default_node_ins_method table<string, function> Default instance method for all nodes. Example: `foo(self, ...)`.
---@field default_node_cls_method table<string, function> Default class method for all nodes. Example: `foo(cls, self, ...)`.
---
---@field default_edge_type string Default type of the edge. Default: "SimpleEdge".
---@field edge_prototype_cls PrototypeEdge Prototype of the edge. Used to create sub edge classes. Must have a `new` method and a `data` field.
---@field edge_sub_cls_info table<EdgeType, table> Information of the sub node classes. Must have `data`, `ins_methods` and `cls_methods` fields.
---@field default_edge_ins_method table<string, function> Default instance method for all edges. Example: `bar(self, ...)`.
---@field default_edge_cls_method table<string, function> Default class method for all edges. Example: `bar(cls, self, ...)`.
---
---@field alg_type string Type of the algorithm used in space repetition. Default to "sm-2".
---@field alg_prototype_cls PrototypeAlg Prototype of the algorithm. Used to create sub algorithm classes. Must have a `new` method and a `data` field.
---@field alg_sub_cls_info table<AlgType, PrototypeAlg> Information of the sub algorithm classes. Must have `data`, `ins_methods` and `cls_methods` fields.
---@field default_alg_ins_method table<string, function> Default instance method for all algorithms. Example: `baz(self, ...)`.
---@field default_alg_cls_method table<string, function> Default class method for all algorithms. Example: `baz(cls, self, ...)`.
---
---@field version integer Version of the graph.
---
---@field logger Logger Logger of the graph.
---@field node_sub_cls table<NodeType, PrototypeNode> Registered sub node classes of the graph.
---@field edge_sub_cls table<EdgeType, PrototypeEdge> Registered sub edge classes of the graph.
---@field nodes table<NodeID, PrototypeNode> Nodes in the graph.
---@field edges table<EdgeID, PrototypeEdge> Edges in the graph.
---@field alg PrototypeAlg Algorithm of the graph.
local Graph = {}

local graph_version = 1
-- v0: Initial version.
-- v1: Add `alg` field.

--------------------
-- Instance Method
--------------------

---Register sub classes.
---@param sub_cls_category string Category of the sub class. Must be "node", "edge" or "alg".
---@param sub_cls_info table<string, table> Information of the sub class.
---Information must have `data`, `ins_methods` and `cls_methods` fields.
---
---Examples:
---  `cls.ins_method(self, ...)` -> `cls:ins_method(...)`
---  `cls_method(cls, self, ...)` -> `cls:ins_method(...)`
function Graph:register_sub_class(sub_cls_category, sub_cls_info)
	local sub_cls = self[sub_cls_category .. "_sub_cls"]

	assert(
		self[sub_cls_category .. "_prototype_cls"],
		"No prototype registered for `" .. sub_cls_category .. "` sub class."
	)
	local prototype = self[sub_cls_category .. "_prototype_cls"]

	for cls_type, cls_info in pairs(sub_cls_info) do
		assert(type(cls_info) == "table", "Information of the sub class must be a table.")

		-- Check if the class already exists.
		if not sub_cls.cls_type then
			---@diagnostic disable-next-line: missing-parameter
			local sub_class = prototype:new() -- TODO: fix this

			-- Add data in the sub class.
			if cls_info.data then
				for field, default in pairs(cls_info.data or {}) do
					assert(type(default) ~= "function", "Data `" .. field .. "` is a function.")
					sub_class.data[field] = default
				end
			end

			-- Add default instance methods.
			for name, func in pairs(self["default_" .. sub_cls_category .. "_cls_method"]) do
				assert(type(func) == "function", "Instance method `" .. name .. "` is not a function.")
				sub_class[name] = func
			end
			-- Add specific instance methods.
			if cls_info.ins_methods then
				for name, func in pairs(cls_info.ins_methods) do
					assert(type(func) == "function", "Instance method `" .. name .. "` is not a function.")
					sub_class[name] = func
				end
			end

			-- Add default class methods.
			for name, func in pairs(self["default_" .. sub_cls_category .. "_cls_method"]) do
				sub_class[name] = function(...)
					return func(sub_class, ...)
				end
			end
			-- Add specific class methods.
			if cls_info.cls_methods then
				for name, func in pairs(cls_info.cls_methods) do
					sub_class[name] = function(...)
						return func(sub_class, ...)
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
			sub_cls[cls_type] = sub_class
			self.logger:debug(sub_cls_category, "Register `" .. sub_cls_category .. "` sub class `" .. cls_type .. "`.")
		end
	end
end

---Create a new graph.
---@param save_path string Path to load and save the graph. Default: {current_project_path}.
---
---@param log_level string Log level of the graph. Default: "INFO".
---@param show_log_in_nvim boolean Show log in Neovim. Default: true.
---
---@param default_node_type string Default type of the node. Default: "SimpleNode".
---@param node_prototype_cls PrototypeNode Prototype of the node. Used to create sub node classes. Must have a `new` method and a `data` field.
---@param node_sub_cls_info table<NodeType, table> Information of the sub node classes. Must have `data`, `ins_methods` and `cls_methods` fields.
---@param default_node_ins_method table<string, function> Default instance method for all nodes. Example: `foo(self, ...)`.
---@param default_node_cls_method table<string, function> Default class method for all nodes. Example: `foo(cls, self, ...)`.
---
---@param default_edge_type string Default type of the edge. Default: "SimpleEdge".
---@param edge_prototype_cls PrototypeEdge Prototype of the edge. Used to create sub edge classes. Must have a `new` method and a `data` field.
---@param edge_sub_cls_info table<EdgeType, table> Information of the sub node classes. Must have `data`, `ins_methods` and `cls_methods` fields.
---@param default_edge_ins_method table<string, function> Default instance method for all edges. Example: `bar(self, ...)`.
---@param default_edge_cls_method table<string, function> Default class method for all edges. Example: `bar(cls, self, ...)`.
---
---@param alg_type string Type of the algorithm used in space repetition. Default to "sm-2".
---@param alg_prototype_cls PrototypeAlg Prototype of the algorithm. Used to create sub algorithm classes. Must have a `new` method and a `data` field.
---@param alg_sub_cls_info table<AlgType, PrototypeAlg> Information of the sub algorithm classes. Must have `data`, `ins_methods` and `cls_methods` fields.
---@param default_alg_ins_method table<string, function> Default instance method for all algorithms. Example: `baz(self, ...)`.
---@param default_alg_cls_method table<string, function> Default class method for all algorithms. Example: `baz(cls, self, ...)`.
---
---@param version? integer Version of the graph.
---@return Graph _ The new graph.
function Graph:new(
	save_path,
	--
	log_level,
	show_log_in_nvim,
	--
	default_node_type,
	node_prototype_cls,
	node_sub_cls_info,
	default_node_ins_method,
	default_node_cls_method,
	--
	default_edge_type,
	edge_prototype_cls,
	edge_sub_cls_info,
	default_edge_ins_method,
	default_edge_cls_method,
	--
	alg_type,
	alg_prototype_cls,
	alg_sub_cls_info,
	default_alg_ins_method,
	default_alg_cls_method,
	--
	version
)
	local graph = {
		save_path = save_path or utils.get_file_info()[4],
		--
		log_level = log_level or "INFO",
		show_log_in_nvim = show_log_in_nvim or true,
		--
		default_node_type = default_node_type or "SimpleNode",
		node_prototype_cls = node_prototype_cls,
		node_sub_cls = setmetatable({}, {
			__index = function(tbl, key)
				if tbl[key] then
					return tbl[key]
				else
					if tbl[default_node_type] then
						vim.notify(
							"Node sub class `"
								.. key
								.. "` not registered. Using default node sub class `"
								.. default_node_type
								.. "` instead.",
							vim.log.levels.WARN
						)
						return tbl[key]
					end
				end
			end,
		}),
		default_node_ins_method = default_node_ins_method or {},
		default_node_cls_method = default_node_cls_method or {},
		--
		default_edge_type = default_edge_type or "SimpleEdge",
		edge_prototype_cls = edge_prototype_cls,
		edge_sub_cls = setmetatable({}, {
			__index = function(tbl, key)
				if tbl[key] then
					return tbl[key]
				else
					if tbl[default_edge_type] then
						vim.notify(
							"Edge sub class `"
								.. key
								.. "` not registered. Using default edge sub class `"
								.. default_edge_type
								.. "` instead.",
							vim.log.levels.WARN
						)
						return tbl[key]
					end
				end
			end,
		}),
		default_edge_ins_method = default_edge_ins_method or {},
		default_edge_cls_method = default_edge_cls_method or {},
		--
		alg_type = alg_type or "sm-2",
		alg_prototype_cls = alg_prototype_cls,
		alg_sub_cls_info = setmetatable(alg_sub_cls_info, {
			__index = function(tbl, key)
				if tbl[key] then
					return tbl[key]
				else
					if tbl[alg_type] then
						vim.notify(
							"Algorithm sub class `"
								.. key
								.. "` not registered. Using default alg sub class `"
								.. alg_type
								.. "` instead.",
							vim.log.levels.WARN
						)
						return tbl[key]
					end
				end
			end,
		}),
		default_alg_ins_method = default_alg_ins_method or {},
		default_alg_cls_method = default_alg_cls_method or {},
		--
		version = version or graph_version,
	}

	setmetatable(graph, self)
	self.__index = self

	-----
	-- Initialize logger.
	-----

	graph.logger = Logger:new(log_level, show_log_in_nvim)

	-----
	-- Register node / edge / algorithm sub classes.
	-----

	graph.node_sub_cls = {}
	graph:register_sub_class("node", node_sub_cls_info)

	graph.edge_sub_cls = {}
	graph:register_sub_class("edge", edge_sub_cls_info)

	graph.alg_sub_cls = {}
	graph:register_sub_class("alg", alg_sub_cls_info)

	-----
	-- Load nodes and edges
	-----

	graph.nodes = {}
	graph.edges = {}
	local json_path = graph.save_path .. "/" .. ".mindmap.json"
	local json, _ = io.open(json_path, "r")
	if not json then
		graph.logger:warn("Graph", "Can not open file `" .. json_path .. "`. Skip loading.")
	else
		local json_content = vim.fn.json_decode(json:read("*all"))
		json:close()

		for node_id, node in pairs(json_content.nodes) do
			-- TODO: add check for node type
			graph.nodes[node_id] = graph.node_sub_cls[node.type]:from_table(node)
		end
		for edge_id, edge in pairs(json_content.edges) do
			-- TODO: add check for edge type
			graph.edges[edge_id] = graph.edge_sub_cls[edge.type]:from_table(edge)
		end
	end

	-----
	-- Initialize algorithm.
	-----

	-- TODO: using args
	graph.alg = graph.alg_sub_cls[alg_type]:new()

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
	-- TODO: add check for duplicate edge
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

---Spaced repetition function: get spaced repetition information from the edge.
---@param edge_id EdgeID ID of the edge.
---@return string[] front, string[] back, integer created_at, integer updated_at, integer due_at, integer ease, integer interval The spaced repetition information.
function Graph:get_sp_info_from_edge(edge_id)
	local edge = self.edges[edge_id]

	-- NOTE:
	-- TO   : Front
	-- From : Back

	local to_node = self.nodes[edge.to_node_id]
	local front, _ = to_node:get_content(edge.type)

	local from_node = self.nodes[edge.from_node_id]
	local _, back = from_node:get_content(edge.type)

	return front, back, edge.created_at, edge.updated_at, edge.due_at, edge.ease, edge.interval
end

---Save a graph to a JSON file.
-- TODO: update
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
