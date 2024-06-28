local Popup = require("nui.popup")
local Layout = require("nui.layout")

local Transaction = require("mindmap.graph.transaction")
local Lock = require("mindmap.graph.lock")
local utils = require("mindmap.utils")

--------------------
-- Class Graph
--------------------

---@class Graph
---Basic:
---@field save_dir string Directory to load and save the graph. The graph will be saved in `{self.save_dir}/.mindmap.json`. Default: `{current_project_path}`.
---  Node:
---@field node_factory NodeFactory Factory for creating nodes.
---@field nodes table<NodeID, BaseNode> Nodes in the graph.
---  Edge:
---@field edge_factory EdgeFactory Factory for creating edges.
---@field edges table<EdgeID, BaseEdge> Edges in the graph.
---  Alg:
---@field alg BaseAlg Algorithm for the graph.
---  Logger:
---@field logger Logger Logger for the graph.
---Transaction:
---@field current_transaction Transaction? Current active transaction.
---@field undo_redo_limit integer Maximum number of undo and redo operations. Default: `3`.
---@field undo_stack Transaction[] Stack of transactions for undo operations.
---@field redo_stack Transaction[] Stack of transactions for redo operations.
---Lock:
---@field lock Lock Lock for the graph.
---Others:
---@field thread_num integer Number of threads to use. Default: `3`.
---@field version integer Version of the graph.
local Graph = {}
Graph.__index = Graph

local graph_version = 6
-- v0: Initial version.
-- v1: Add `alg` field.
-- v2: Auto call `[before|after]_[add_into|remove_from]_graph`
-- v3: Use factory to manage `[node|edge|alf]` classes.
-- v4: Use `Transaction` class to manage transactions.
-- v5: Update `load` and `save` methods.
-- v6: Add `lock` and `transact` related methods.

----------
-- Basic Method
----------

---Create a new graph.
---@param save_dir string Directory to load and save the graph. The graph will be saved in `{self.save_dir}/.mindmap.json`. Default: `{current_project_path}`.
---@param node_factory NodeFactory Factory for creating nodes.
---@param edge_factory EdgeFactory Factory for creating edges.
---@param alg BaseAlg Algorithm for the graph.
---@param logger Logger Logger for the graph.
---@param undo_redo_limit? integer Limit of undo and redo operations. Default: `3`.
---@param thread_num? integer Number of threads to use. Default: `3`.
---@param version? integer Version of the graph.
---@return Graph graph The new graph.
function Graph:new(save_dir, node_factory, edge_factory, alg, logger, undo_redo_limit, thread_num, version)
	local graph = {
		-- Basic:
		save_dir = save_dir,
		--   Node:
		node_factory = node_factory,
		nodes = {},
		--   Edge:
		edge_factory = edge_factory,
		edges = {},
		--   Alg:
		alg = alg,
		--   Logger:
		logger = logger,
		-- Transaction:
		current_transaction = nil,
		undo_redo_limit = undo_redo_limit or 3,
		undo_stack = {},
		redo_stack = {},
		-- Lock:
		lock = Lock:new(),
		-- Others:
		thread_num = thread_num or 3,
		version = version or graph_version,
	}
	graph.__index = graph
	setmetatable(graph, Graph)

	graph:load()

	return graph
end

---Load the graph from `{self.save_dir}/.mindmap.json`.
---@return nil
function Graph:load()
	local json_path = self.save_dir .. "/" .. ".mindmap.json"
	local json, _ = io.open(json_path, "r")
	if not json then
		self.logger:warn("Graph", "Load graph failed. Can not open file `" .. json_path .. "`.")
		return
	end

	local json_content = json:read("*all")
	json:close()

	if json_content == "" then
		self.logger:warn("Graph", "Load graph skipped. File `" .. json_path .. "` is empty.")
		return
	end
	json_content = vim.fn.json_decode(json_content)

	for node_id, node in pairs(json_content.nodes) do
		self.nodes[node_id] = self.node_factory:from_table(node._type, node)
	end
	for edge_id, edge in pairs(json_content.edges) do
		self.edges[edge_id] = self.edge_factory:from_table(edge._type, edge)
	end
end

---Save the graph to `{self.save_dir}/.mindmap.json`.
---@return nil
function Graph:save()
	local graph_tbl = {
		nodes = {},
		edges = {},
	}
	for node_id, node in pairs(self.nodes) do
		graph_tbl.nodes[node_id] = self.node_factory:to_table(node)
	end
	for edge_id, edge in pairs(self.edges) do
		graph_tbl.edges[edge_id] = self.edge_factory:to_table(edge)
	end

	local json_path = self.save_dir .. "/" .. ".mindmap.json"
	local json, _ = io.open(json_path, "w")
	if not json then
		self.logger:error("Graph", "Save graph failed. Can not open file `" .. json_path .. "`.")
		return
	end

	local json_content = vim.fn.json_encode(graph_tbl)
	json:write(json_content)
	json:close()
end

---Create a savepoint.
---@return table savepoint The created savepoint.
function Graph:create_savepoint()
	local savepoint = {
		nodes = self.nodes,
		edges = self.edges,
	}
	return savepoint
end

---Rollback to a savepoint.
---@param savepoint table The savepoint to rollback to.
---@return nil
function Graph:rollback_savepoint(savepoint)
	self.nodes = savepoint.nodes
	self.edges = savepoint.edges
end

----------
-- CRUD Method
----------

-----
-- C
-----

---Add a node to the graph.
---If the node has `before_add_into_graph` or `after_add_into_graph` methods, they will be called automatically.
---If a transaction is active, the operation and its inverse will be recorded automatically.
---@param node_or_node_type string|BaseNode Node or type of the node to be added.
---@param ... any Additional information to create the node.
---@return boolean is_added, BaseNode? node Whether the node is added successfully, and the added node.
function Graph:add_node(node_or_node_type, ...)
	local node
	if type(node_or_node_type) == "table" then
		node = node_or_node_type
	elseif type(node_or_node_type) == "string" then
		node = self.node_factory:create(node_or_node_type, ...)
		if not node then
			self.logger:warn("Graph", "Add node failed. Can not create `" .. node_or_node_type .. "`.")
			return false, nil
		end
	else
		self.logger:error(
			"Graph",
			"Add node failed. The type of node_or_node_type must be `string` or `table`, but got `"
				.. type(node_or_node_type)
				.. "`."
		)
		return false, nil
	end

	-- Operation --

	local operation = function()
		-- Pre action --

		if node.before_add_into_graph then
			node:before_add_into_graph()
		end

		-- Main action --

		self.nodes[node._id] = node
		node._state = "active"

		-- Post action --

		if node.after_add_into_graph then
			node:after_add_into_graph()
		end
	end

	-- Inverse --

	local inverse = function()
		self:remove_node(node._id)
	end

	-- Transaction --

	if self.current_transaction then
		self.current_transaction:record(operation, inverse)
	else
		operation()
	end

	-- Others --

	self.logger:info("Graph", "Add `" .. node._type .. "` `" .. node._id .. "` to graph.")
	return true, node
end

---Add an edge to the graph.
---If the edge has `before_add_into_graph` or `after_add_into_graph` methods, they will be called automatically.
---If a transaction is active, the operation and its inverse will be recorded automatically.
---@param edge_or_edge_type string|BaseEdge Edge or type of the edge to be added.
---@param ... any Additional information to create the edge.
---@return boolean is_added, BaseEdge? edge Whether the edge is added successfully, and the added edge.
function Graph:add_edge(edge_or_edge_type, ...)
	local edge
	if type(edge_or_edge_type) == "table" then
		edge = edge_or_edge_type
	elseif type(edge_or_edge_type) == "string" then
		edge = self.edge_factory:create(edge_or_edge_type, ...)
		if not edge then
			self.logger:warn("Graph", "Add edge failed. Can not create `" .. edge_or_edge_type .. "`.")
			return false, nil
		end
	else
		self.logger:error(
			"Graph",
			"Add edge failed. The type of edge_or_edge_type must be `string` or `table`, but got `"
				.. type(edge_or_edge_type)
				.. "`."
		)
		return false, nil
	end

	-- Operation --

	local operation = function()
		-- Pre action --

		if edge._before_add_into_graph then
			edge:before_add_into_graph()
		end

		-- Main action --

		self.edges[edge._id] = edge
		edge._state = "active"

		-- Post action --

		if edge._after_add_into_graph then
			edge:after_add_into_graph()
		end
	end

	-- Inverse --

	local inverse = function()
		self:remove_edge(edge._id)
	end

	-- Transaction --

	if self.current_transaction then
		self.current_transaction:record(operation, inverse)
	else
		operation()
	end

	-- Others --

	self.logger:info("Graph", "Add `" .. edge._type .. "` `" .. edge._id .. "` to graph.")
	return true, edge
end

-----
-- R
-----

---Find nodes based on given criteria.
---@param criteria table The criteria to match nodes against.
---Example:
---  ```
---  Graph.find_nodes({
---    {"_type", "SimpleNode"},
---    {"_state", "active"},
---    {"_hello", function(field) return field == "Hello" end}
---  })
---  ```
---@return table matched_nodes The nodes matching the criteria.
function Graph:find_nodes(criteria)
	local function _matcher(_, item)
		for _, condition in ipairs(criteria) do
			local field, value_or_func = condition[1], condition[2]
			local field_value = item[field]

			if type(value_or_func) == "function" then
				if not value_or_func(field_value) then
					return nil
				end
			else
				if field_value ~= value_or_func then
					return nil
				end
			end
		end

		return item
	end

	return utils.pfor(self.nodes, _matcher, self.thread_num)
end

---Find edges based on given criteria.
---Example:
---  ```
---  Graph.find_edges({
---    {"_type", "SimpleEdge"},
---    {"_state", "active"},
---    {"_hello", function(field) return field == "Hello" end}
---  })
---  ```
---@param criteria table The criteria to match edges against.
---@return table matched_edges The edges matching the criteria.
function Graph:find_edges(criteria)
	local function _matcher(_, item)
		for _, condition in ipairs(criteria) do
			local field, value_or_func = condition[1], condition[2]
			local field_value = item[field]

			if type(value_or_func) == "function" then
				if not value_or_func(field_value) then
					return nil
				end
			else
				if field_value ~= value_or_func then
					return nil
				end
			end
		end
		return item
	end

	return utils.pfor(self.edges, _matcher, self.thread_num)
end

-----
-- U
-----

-----
-- D
-----

---Remove an edge from the graph using ID.
---If the edge has `before_remove_from_graph` or `after_remove_from_graph` methods, they will be called automatically.
---If a transaction is active, the operation and its inverse will be recorded automatically.
---@param edge_id EdgeID ID of the edge to be removed.
---@return boolean is_removed Whether the edge is removed successfully.
function Graph:remove_edge(edge_id)
	local edge = self.edges[edge_id]
	if not edge then
		self.logger:warn("Graph", "Remove edge failed. Can not find edge `" .. edge_id .. "`.")
		return false
	end

	-- Operation --

	local operation = function()
		-- Pre action --

		if self.edges[edge_id].before_remove_from_graph then
			self.edges[edge_id]:before_remove_from_graph()
		end

		-- Main action --

		self.edges[edge_id]._state = "removed"

		-- Post action --

		if self.edges[edge_id].after_remove_from_graph then
			self.edges[edge_id]:after_remove_from_graph()
		end
	end

	-- Inverse --

	local inverse = function()
		self:add_edge(edge)
	end

	-- Transaction --

	if self.current_transaction then
		self.current_transaction:record(operation, inverse)
	else
		operation()
	end

	-- Others --

	self.logger:info("Graph", "Remove `" .. edge._type .. "` `" .. edge._id .. "` from graph.")
	return true
end

---Remove a node from the graph and all edges related to it using ID.
---If the node has `before_remove_from_graph` or `after_remove_from_graph` methods, they will be called automatically.
---If a transaction is active, the operation and its inverse will be recorded automatically.
---@param node_id NodeID ID of the node to be removed.
---@return boolean is_removed Whether the node is removed successfully.
function Graph:remove_node(node_id)
	local node = self.nodes[node_id]
	if not node then
		self.logger:warn("Graph", "Remove node failed. Can not find node `" .. node_id .. "`.")
		return false
	end

	-- Operation --

	local operation = function()
		-- Pre action --

		if self.nodes[node_id].before_remove_from_graph then
			self.nodes[node_id]:before_remove_from_graph()
		end

		-- Main action --

		self.nodes[node_id]._state = "removed"

		-- Post action --

		if self.nodes[node_id].after_remove_from_graph then
			self.nodes[node_id]:after_remove_from_graph()
		end
	end

	-- Inverse --

	local inverse = function()
		self:add_node(node)
	end

	-- Transaction --

	if self.current_transaction then
		self.current_transaction:record(operation, inverse)
	else
		operation()
	end

	-- Others --

	self.logger:info("Graph", "Remove `" .. node._type .. "` `" .. node._id .. "` from graph.")
	return true
end

----------
-- Transaction Method
----------

---Executes a transaction on the graph.
---@param closure function The function to be executed within the transaction.
---@param description? string Description of the transaction.
---@return boolean success Whether the transaction was successfully committed.
function Graph:transact(closure, description)
	self.lock:acquire()
	self.current_transaction = Transaction:begin(self:create_savepoint(), description)
	self.logger:info("Graph", "Transaction `" .. self.current_transaction.description .. "` begin.")

	local success, err_msg = pcall(closure)
	if success then
		if self.current_transaction:commit() then
			if #self.undo_stack >= self.undo_redo_limit then
				table.remove(self.undo_stack, 1)
			end

			table.insert(self.undo_stack, self.current_transaction)
			self.redo_stack = {}

			self.logger:info("Graph", "Transaction `" .. self.current_transaction.description .. "` commit completed.")
		else
			success = false
			self.logger:error("Graph", "Transaction `" .. self.current_transaction.description .. "` commit failed.")
		end
	end

	if not success then
		self.logger:warn(
			"Graph",
			"Transaction `" .. self.current_transaction.description .. "` failed: " .. err_msg .. "."
		)
		-- Just simply rollback the savepoint now.
		self:rollback_savepoint(self.current_transaction.savepoint)
		self.logger:warn("Graph", "Transaction `" .. self.current_transaction.description .. "` rollback completed.")
		-- if self.current_transaction:rollback() then
		--   self.logger:info("Graph", "Transaction rollback completed.")
		-- else
		--   self.logger:error("Graph", "Transaction rollback failed.")
		-- end
	end

	self.current_transaction = nil
	self.lock:release()
	return success
end

---Undo the latest transaction.
---@return boolean is_successful Whether the undo operation is successful.
function Graph:undo()
	local transaction = table.remove(self.undo_stack)
	if not transaction then
		self.logger:info("Graph", "No transaction to undo.")
		return false
	end

	transaction:rollback()

	-- Record the redo operation of the undo operation
	if #self.redo_stack >= self.undo_redo_limit then
		table.remove(self.redo_stack, 1)
	end
	table.insert(self.redo_stack, transaction)

	return true
end

---Redo the latest transaction.
---@return boolean is_successful Whether the redo operation is successful.
function Graph:redo()
	local transaction = table.remove(self.redo_stack)
	if not transaction then
		self.logger:info("Graph", "No operation to redo.")
		return false
	end

	transaction:commit()

	-- Record the undo operation of the redo operation
	if #self.undo_stack >= self.undo_redo_limit then
		table.remove(self.undo_stack, 1)
	end
	table.insert(self.undo_stack, transaction)

	return true
end

----------
-- Spaced Repetition Methods
-- TODO:
----------

---Get spaced repetition information from the edge.
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

---Show card for spaced repetition.
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
		self.logger:info("Graph", "Skip spaced repetition of the current card.")
		status = "skip"
		card_ui:unmount()
		return status
	elseif choice == string.byte("q") then
		self.logger:info("Graph", "Quit spaced repetition of the current deck.")
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
		self.logger:debug("Graph", "Answer again to edge `" .. edge_id .. "`.")
		self.alg:answer_again(edge)
		status = "again"
	elseif choice == string.byte(" ") or choice == string.byte("2") or choice == string.byte("g") then
		self.logger:debug("Graph", "Answer good to edge `" .. edge_id .. "`.")
		self.alg:answer_good(edge)
		status = "good"
	elseif choice == string.byte("3") or choice == string.byte("e") then
		self.logger:debug("Graph", "Answer easy to edge `" .. edge_id .. "`.")
		self.alg:answer_easy(edge)
		status = "easy"
	elseif choice == string.byte("s") then
		self.logger:info("Graph", "Skip spaced repetition of the current card.")
		status = "skip"
	elseif choice == string.byte("q") then
		self.logger:info("Graph", "Quit spaced repetition of the current deck.")
		status = "quit"
	end

	card_ui:unmount()
	return status
end

--------------------

return Graph
