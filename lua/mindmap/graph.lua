local Popup = require("nui.popup")
local Layout = require("nui.layout")

local utils = require("mindmap.utils")

--------------------
-- Class Graph
--------------------

---@class Graph
---Basic:
---@field save_dir string Dir to load and save the graph. The graph will be saved in `{self.save_dir}/.mindmap.json`. Default: {current_project_path}.
---Node:
---@field node_factory NodeFactory Factory of the node.
---@field nodes table<NodeID, BaseNode> Nodes in the graph.
---Edge:
---@field edge_factory EdgeFactory Factory of the edge.
---@field edges table<EdgeID, BaseEdge> Edges in the graph.
---Alg:
---@field alg BaseAlg Algorithm of the graph.
---Logger:
---@field logger Logger Logger of the graph.
---Transaction:
---@field current_operation table? Current operation.
---@field undo_redo_limit integer Limit of undo and redo operations.
---@field undo_stack table<string, table> Stack of undo operations.
---@field redo_stack table<string, table> Stack of redo operations.
---Others:
---@field version integer Version of the graph.
local Graph = {}
Graph.__index = Graph

local graph_version = 3
-- v0: Initial version.
-- v1: Add `alg` field.
-- v2: Auto call `[before|after]_[add_into|remove_from]_graph`
-- v3: Use factory to manage `[node|edge|alf]` classes.

----------
-- Basic Method
----------

---Create a new graph.
---Basic:
---@param save_dir string Dir to load and save the graph. The graph will be saved in `{self.save_dir}/.mindmap.json`. Default: {current_project_path}.
---Node:
---@param node_factory NodeFactory Factory of the node.
---Edge:
---@param edge_factory EdgeFactory Factory of the edge.
---Alg:
---@param alg BaseAlg Algorithm of the graph.
---Logger:
---@param logger Logger Logger of the graph.
---Transaction:
---@param undo_redo_limit? integer Limit of undo and redo operations. Default: 3.
---Others:
---@param version? integer Version of the graph. Default: `graph_version`.
---@return Graph _ The new graph.
function Graph:new(
	-- Basic:
	save_dir,
	-- Node:
	node_factory,
	-- Edge:
	edge_factory,
	-- Alg:
	alg,
	-- Logger:
	logger,
	-- Transaction:
	undo_redo_limit,
	-- Others:
	version
)
	local graph = {
		-- Basic:
		save_dir = save_dir or utils.get_file_info()[4],
		-- Node:
		node_factory = node_factory,
		nodes = {},
		-- Edge:
		edge_factory = edge_factory,
		edges = {},
		-- Alg:
		alg = alg,
		-- Logger:
		logger = logger,
		-- Transaction:
		current_operation = nil,
		undo_redo_limit = undo_redo_limit or 3,
		undo_stack = {},
		redo_stack = {},
		-- Others:
		version = version or graph_version,
	}
	graph.__index = graph
	setmetatable(graph, Graph)

	-- Load nodes and edges --

	local json_path = graph.save_dir .. "/" .. ".mindmap.json"
	local json, _ = io.open(json_path, "r")
	if not json then
		graph.logger:warn("Graph", "Can not open file `" .. json_path .. "`. Skip loading.")
	else
		local json_content = vim.fn.json_decode(json:read("*all"))
		json:close()

		for node_id, node in pairs(json_content.nodes) do
			graph.nodes[node_id] = graph.node_factory:from_table(node.type, node)
		end
		for edge_id, edge in pairs(json_content.edges) do
			graph.edges[edge_id] = graph.edge_factory:from_table(edge.type, edge)
		end
	end

	return graph
end

---Add a node to the graph.
---If the node has `before_add_into_graph` and `after_add_into_graph` methods,
---they will be called before and after adding the node.
---This method soppurt undo and redo.
---@param node_type string Type of the node to be added.
---@return boolean _ Whether the node is added.
function Graph:add_node(node_type, ...)
	local node = self.node_factory:create(node_type, ...)
	if not node then
		self.logger:warn("Node", "Create " .. node_type .. " failed. Abort adding.")
		return false
	end

	-- Pre action --

	if node.before_add_into_graph then
		node:before_add_into_graph()
	end

	-- Main action --

	self.nodes[node.id] = node
	node.state = "active"

	-- Post action --

	if node.after_add_into_graph then
		node:after_add_into_graph()
	end

	-- Transaction --

	if self.current_operation then
		self:record_sub_operation(
			-- Redo
			utils.create_closure(
				self.add_node,
				self,
				-- node_type
				node_type,
				-- ...
				...
			),
			-- Undo
			utils.create_closure(
				self.remove_node,
				self,
				-- node_id
				node.id
			)
		)
	end

	-- Others --

	self.logger:info("Node", "Add " .. node.type .. " <" .. node.id .. ">.")
	return true
end

---Remove a node from the graph and all edges related to it using ID.
---If the node has `before_remove_from_graph` and `after_remove_from_graph` methods,
---they will be called before and after removing the node.
---This method soppurt undo and redo.
---@param node_id NodeID ID of the node to be removed.
---@return boolean _ Whether the node is removed.
function Graph:remove_node(node_id)
	if not self.nodes[node_id] then
		self.logger:warn("Node", "Node <" .. node_id .. "> does not exist. Abort removing.")
		return false
	end

	-- Pre action --

	if self.nodes[node_id].before_remove_from_graph then
		self.nodes[node_id]:before_remove_from_graph()
	end

	-- Main action --

	local node = self.nodes[node_id]
	for _, incoming_edge_id in pairs(node.incoming_edge_ids) do
		self:remove_edge(incoming_edge_id)
	end
	for _, outcoming_edge_id in pairs(node.outcoming_edge_ids) do
		self:remove_edge(outcoming_edge_id)
	end
	self.nodes[node_id].state = "removed"

	-- Post action --

	if self.nodes[node_id].after_remove_from_graph then
		self.nodes[node_id]:after_remove_from_graph()
	end

	-- Transaction --

	if self.current_operation then
		self:record_sub_operation(
			-- Redo
			utils.create_closure(
				self.remove_node,
				self,
				-- node_id
				node_id
			),
			-- Undo
			utils.create_closure(
				self.add_node,
				self,
				-- node_type
				node.type,
				-- ...
				node.type,
				node.id,
				node.file_name,
				node.rel_file_path,
				node.data,
				node.tag,
				node.state,
				node.version,
				node.created_at,
				node.incoming_edge_ids,
				node.outcoming_edge_ids
			)
		)
	end

	-- Others --

	self.logger:info("Node", "Remove " .. self.nodes[node_id].type .. " <" .. node_id .. "> and related edges.")
	return true
end

---Add a edge to the graph.
---If the edge has `before_add_into_graph` and `after_add_into_graph` methods,
---they will be called before and after adding the edge.
---This method soppurt undo and redo.
---@param edge_type string Type of the edge to be added.
---@return boolean _ Whether the edge is added.
function Graph:add_edge(edge_type, ...)
	-- TODO: allow use init function to init interval and ease.
	local edge = self.edge_factory:create(edge_type, ...)
	if not edge then
		self.logger:warn("Edge", "Create " .. edge_type .. " failed. Abort adding.")
		return false
	end

	-- Pre action --

	if edge.before_add_into_graph then
		edge:before_add_into_graph()
	end

	-- Main action --

	local from_node = self.nodes[edge.from_node_id]
	from_node:add_outcoming_edge_id(edge.id)
	local to_node = self.nodes[edge.to_node_id]
	to_node:add_incoming_edge_id(edge.id)
	edge.state = "active"

	-- Post action --

	if edge.after_add_into_graph then
		edge:after_add_into_graph()
	end

	-- Transaction --

	if self.current_operation then
		self:record_sub_operation(
			-- Redo
			utils.create_closure(
				self.add_edge,
				self,
				-- edge_type
				edge_type,
				-- ...
				...
			),
			-- Undo
			utils.create_closure(
				self.remove_edge,
				self,
				-- edge_id
				edge.id
			)
		)
	end

	-- Others --

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
			.. " <"
			.. edge.to_node_id
			.. ">."
	)
	return true
end

---Remove an edge from the graph using ID.
---If the node has `before_remove_from_graph` and `after_remove_from_graph` methods,
---they will be called before and after removing the node.
---This method soppurt undo and redo.
---@param edge_id EdgeID ID of the edge to be removed.
---@return boolean _ Whether the edge is removed.
function Graph:remove_edge(edge_id)
	if not self.edges[edge_id] then
		self.logger:warn("Edge", "Edge <" .. edge_id .. "> does not exist. Abort removing.")
		return false
	end

	-- Pre action --

	if self.edges[edge_id].before_remove_from_graph then
		self.edges[edge_id]:before_remove_from_graph()
	end

	-- Main action --

	local edge = self.edges[edge_id]
	local from_node = self.nodes[edge.from_node_id]
	from_node:remove_outcoming_edge_id(edge_id)
	local to_node = self.nodes[edge.to_node_id]
	to_node:remove_outcoming_edge_id(edge_id)
	self.edges[edge_id].state = "removed"

	-- Post action --

	if self.edges[edge_id].after_remove_from_graph then
		self.edges[edge_id]:after_remove_from_graph()
	end

	-- Transaction --

	if self.current_operation then
		self:record_sub_operation(
			-- Redo
			utils.create_closure(
				self.remove_edge,
				self,
				-- edge_id
				edge_id
			),
			-- Undo
			utils.create_closure(
				self.add_edge,
				self,
				-- edge_type
				edge.type,
				-- ...
				edge.id,
				edge.from_node_id,
				edge.to_node_id,
				edge.data,
				edge.type,
				edge.tag,
				edge.state,
				edge.version,
				edge.created_at,
				edge.updated_at,
				edge.due_at,
				edge.ease,
				edge.interval,
				edge.answer_count,
				edge.ease_count,
				edge.again_count
			)
		)
	end

	-- Others --

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
	return true
end

---Spaced repetition function: get spaced repetition information from the edge.
---@param edge_id EdgeID ID of the edge.
---@return string[] front, string[] back, integer created_at, integer updated_at, integer due_at, integer ease, integer interval, integer answer_count, integer ease_count, integer again_count The spaced repetition information.
function Graph:get_sp_info_from_edge(edge_id)
	local edge = self.edges[edge_id]
	local screen_width = vim.api.nvim_win_get_width(0) - 20

	-- NOTE:
	-- TO   : Front
	-- From : Back

	local to_node = self.nodes[edge.to_node_id]
	local front, _ = to_node:get_content(edge.type)
	front = utils.limit_string_length(front, screen_width)

	local from_node = self.nodes[edge.from_node_id]
	local _, back = from_node:get_content(edge.type)
	back = utils.limit_string_length(back, screen_width)

	return front,
		back,
		edge.created_at,
		edge.updated_at,
		edge.due_at,
		edge.ease,
		edge.interval,
		edge.answer_count,
		edge.ease_count,
		edge.again_count
end

---Show card.
---@param edge_id EdgeID ID of the edge.
---@return string status Status of spaced repetition. Can be "again", "good", "easy", "skip" or "quit".
function Graph:show_card(edge_id)
	local edge = self.edges[edge_id]
	local from_node_type = self.nodes[edge.from_node_id].type
	local to_node_type = self.nodes[edge.to_node_id].type
	local front, back, _, _, _, _, _, _, _, _ = self:get_sp_info_from_edge(edge_id)

	--------------------
	-- UI
	--------------------

	local card_front, card_back =
		Popup({
			enter = false,
			focusable = false,
			border = {
				style = "rounded",
				text = { top = string.format(" Front: %s ", to_node_type), top_align = "center" },
			},
			buf_options = { filetype = "norg", readonly = false },
		}), Popup({
			enter = false,
			focusable = false,
			relative = "editor",
			border = {
				style = "rounded",
				text = { top = string.format(" Back: %s ", from_node_type), top_align = "center" },
			},
			buf_options = { filetype = "norg", readonly = false },
		})

	local card_ui = Layout(
		{
			position = { row = "50%", col = "50%" },
			size = { width = "40%", height = "40%" },
		},
		Layout.Box({
			Layout.Box(card_front, { size = "50%" }),
			Layout.Box(card_back, { size = "50%" }),
		}, { dir = "col" })
	)
	card_ui:mount()

	--------------------
	-- Front
	--------------------

	local choice
	local status

	vim.api.nvim_buf_set_lines(card_front.bufnr, 0, -1, false, front)

	repeat
		choice = vim.fn.getchar()
	until choice == string.byte(" ") or choice == string.byte("s") or choice == string.byte("q")

	if choice == string.byte("s") then
		self.logger:info("SP", "Skip spaced repetition of the current card.")
		status = "skip"
		card_ui:unmount()
		return status
	elseif choice == string.byte("q") then
		self.logger:info("SP", "Quit spaced repetition of the current deck.")
		status = "quit"
		card_ui:unmount()
		return status
	end

	--------------------
	-- Back
	--------------------

	vim.api.nvim_buf_set_lines(card_back.bufnr, 0, -1, false, back)
	card_ui:update()

	repeat
		choice = vim.fn.getchar()
	until choice == string.byte("1")
		or choice == string.byte("a")
		or choice == string.byte(" ")
		or choice == string.byte("2")
		or choice == string.byte("g")
		or choice == string.byte("3")
		or choice == string.byte("e")
		or choice == string.byte("s")
		or choice == string.byte("q")

	if choice == string.byte("1") or choice == string.byte("a") then
		self.logger:debug("SP", "Answer again to edge `" .. edge_id .. "`.")
		self.alg:answer_again(edge)
		status = "again"
	elseif choice == string.byte(" ") or choice == string.byte("2") or choice == string.byte("g") then
		self.logger:debug("SP", "Answer good to edge `" .. edge_id .. "`.")
		self.alg:answer_good(edge)
		status = "good"
	elseif choice == string.byte("3") or choice == string.byte("e") then
		self.logger:debug("SP", "Answer easy to edge `" .. edge_id .. "`.")
		self.alg:answer_easy(edge)
		status = "easy"
	elseif choice == string.byte("s") then
		self.logger:info("SP", "Skip spaced repetition of the current card.")
		status = "skip"
	elseif choice == string.byte("q") then
		self.logger:info("SP", "Quit spaced repetition of the current deck.")
		status = "quit"
	end

	card_ui:unmount()
	return status
end

---Save a graph to a JSON file.
-- TODO: update
function Graph:save()
	local graph_tbl = {
		-- save_dir = self.save_dir,
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

	local json_path = self.save_dir .. "/" .. ".mindmap.json"
	local json, _ = io.open(json_path, "w")
	if not json then
		self.logger:error("Graph", "Can not open file `" .. json_path .. "`. Skip saving.")
		return
	end

	local json_content = vim.fn.json_encode(graph_tbl)
	json:write(json_content)
	json:close()
end

----------
-- Transaction Methods
----------

function Graph:begin_operation()
	if self.current_operation then
		self.logger:debug("Graph", "An Operation is in progress. Can not begin a new operation.")
		return
	end

	-- Init current_operation
	self.current_operation = {
		operations = {},
		inverses = {},
	}
end

function Graph:record_sub_operation(operation, inverse)
	if not self.current_operation then
		self.logger:debug("Graph", "No Operation is in progress. Can not record sub operation.")
		return
	end

	-- Record the operation
	table.insert(self.current_operation.operations, operation)
	table.insert(self.current_operation.inverses, inverse)
end

function Graph:end_operation()
	if not self.current_operation then
		self.logger:debug("Graph", "No Operation is in progress. Can not end the operation.")
		return
	end

	-- If no operation is recorded, do nothing.
	if #self.current_operation.operations == 0 then
		return
	end

	-- NOTE: If use `self.current_operation` directly, it will cause an error.
	local current_operation = self.current_operation
	self.current_operation = nil

	-- If the undo stack is full, remove the oldest operation.
	if #self.undo_stack >= self.undo_redo_limit then
		table.remove(self.undo_stack, 1)
	end

	-- Setup the undo stack
	table.insert(self.undo_stack, {
		redo_op = function()
			for i = 1, #current_operation.operations do
				current_operation.operations[i]()
			end
		end,
		undo_op = function()
			for i = #current_operation.inverses, 1, -1 do
				current_operation.inverses[i]()
			end
		end,
	})

	-- Clean the redo stack, because a new operation is added.
	self.redo_stack = {}
end

function Graph:undo()
	local op = table.remove(self.undo_stack)
	if not op then
		self.logger:info("Graph", "No operation to undo.")
		return false
	end

	-- Trigger the undo operation
	op.undo_op()

	-- Record the redo operation of the undo operation
	if #self.redo_stack >= self.undo_redo_limit then
		table.remove(self.redo_stack, 1)
	end
	table.insert(self.redo_stack, op)

	return true
end

function Graph:redo()
	local op = table.remove(self.redo_stack)
	if not op then
		self.logger:info("Graph", "No operation to redo.")
		return false
	end

	-- Trigger the redo operation
	op.redo_op()

	-- Record the undo operation of the redo operation
	if #self.undo_stack >= self.undo_redo_limit then
		table.remove(self.undo_stack, 1)
	end
	table.insert(self.undo_stack, op)

	return true
end

---@deprecated
---Create a savepoint of the graph.
function Graph:create_savepoint()
	self.logger:debug("Graph", "Create a savepoint.")

	return {
		nodes = vim.deepcopy(self.nodes),
		edges = vim.deepcopy(self.edges),
	}
end

----------
-- class Method
----------

--------------------

return Graph
