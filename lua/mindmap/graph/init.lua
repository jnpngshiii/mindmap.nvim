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
---@field save_dir string Dir to load and save the graph. The graph will be saved in `{self.save_dir}/.mindmap.json`. Default: {current_project_path}.
---  Node:
---@field node_factory NodeFactory Factory of the node.
---@field nodes table<NodeID, BaseNode> Nodes in the graph.
---  Edge:
---@field edge_factory EdgeFactory Factory of the edge.
---@field edges table<EdgeID, BaseEdge> Edges in the graph.
---  Alg:
---@field alg BaseAlg Algorithm of the graph.
---  Logger:
---@field logger Logger Logger of the graph.
---Transaction:
---@field current_transaction Transaction? Current transaction.
---@field undo_redo_limit integer Max number of undo and redo. Default: `3`.
---@field undo_stack Transaction[] Stack of transaction for undo.
---@field redo_stack Transaction[] Stack of transaction for redo.
---Lock:
---@field lock Lock Lock of the graph.
---Others:
---@field version integer Version of the graph.
local Graph = {}
Graph.__index = Graph

local graph_version = 5
-- v0: Initial version.
-- v1: Add `alg` field.
-- v2: Auto call `[before|after]_[add_into|remove_from]_graph`
-- v3: Use factory to manage `[node|edge|alf]` classes.
-- v4: Use `Transaction` class to manage transactions.
-- v5: Update `load` and `save` methods.

----------
-- Basic Method
----------

---Create a new graph.
---Basic:
---@param save_dir string Dir to load and save the graph. The graph will be saved in `{self.save_dir}/.mindmap.json`. Default: {current_project_path}.
---  Node:
---@param node_factory NodeFactory Factory of the node.
---  Edge:
---@param edge_factory EdgeFactory Factory of the edge.
---  Alg:
---@param alg BaseAlg Algorithm of the graph.
---  Logger:
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
		version = version or graph_version,
	}
	graph.__index = graph
	setmetatable(graph, Graph)

	graph:load()

	return graph
end

---Load the graph from `{self.save_dir}/.mindmap.json`.
---@return nil _ This function does not return anything.
function Graph:load()
	local json_path = self.save_dir .. "/" .. ".mindmap.json"
	local json, _ = io.open(json_path, "w")
	if not json then
		self.logger:error("Graph", "Load graph failed. Can not open file `" .. json_path .. "`.")
		return
	end

	local json_content = vim.fn.json_decode(json:read("*all"))
	json:close()

	for node_id, node in pairs(json_content.nodes) do
		self.nodes[node_id] = self.node_factory:from_table(node._type, node)
	end
	for edge_id, edge in pairs(json_content.edges) do
		self.edges[edge_id] = self.edge_factory:from_table(edge._type, edge)
	end
end

---Save the graph to `{self.save_dir}/.mindmap.json`.
---@return nil _ This function does not return anything.
function Graph:save()
	local graph_tbl = {
		nodes = {},
		edges = {},
	}
	for node_id, node in ipairs(self.nodes) do
		graph_tbl.nodes[node_id] = self.node_factory:to_table(node)
	end
	for edge_id, edge in ipairs(self.edges) do
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
---@return table _ The savepoint.
function Graph:create_savepoint()
	local savepoint = {
		nodes = vim.deepcopy(self.nodes),
		edges = vim.deepcopy(self.edges),
	}
	return savepoint
end

---Rollback to a savepoint.
---@return nil _ This method does not return anything.
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
---If `node.before_add_into_graph ~= nil` and / or `node.after_add_into_graph ~= nil`,
---`add_node` will automatically call these methods before and after adding the node.
---If `self.current_transaction ~= nil`,
---`add_node` will automatically record the its operation and inverse to the transaction.
---@param node_or_node_type string|BaseNode Node or type of the node to be added.
---@param ... any Information to create the node.
---@return boolean _ Whether the node is added.
function Graph:add_node(node_or_node_type, ...)
	local node
	if type(node_or_node_type) == "table" then
		node = node_or_node_type
	elseif type(node_or_node_type) == "string" then
		node = self.node_factory:create(node_or_node_type, ...)
		if not node then
			self.logger:warn("Node", "Add node failed. Can not create `" .. node_or_node_type .. "`.")
			return false
		end
	else
		self.logger:error(
			"Node",
			"Add node failed. The type of node_or_node_type must be `string` or `table`, but got `"
				.. type(node_or_node_type)
				.. "`."
		)
		return false
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

	self.logger:info("Node", "Add `" .. node._type .. "` `" .. node._id .. "` to graph.")
	return true
end

---Add a edge to the graph.
---If `edge.before_add_into_graph ~= nil` and / or `edge.after_add_into_graph ~= nil`,
---`add_edge` will automatically call these methods before and after adding the edge.
---If `self.current_transaction ~= nil`,
---`add_edge` will automatically record the its operation and inverse to the transaction.
---@param edge_or_edge_type string|BaseEdge Edge or type of the edge to be added.
---@return boolean _ Whether the edge is added.
function Graph:add_edge(edge_or_edge_type, ...)
	local edge
	if type(edge_or_edge_type) == "table" then
		edge = edge_or_edge_type
	elseif type(edge_or_edge_type) == "string" then
		edge = self.edge_factory:create(edge_or_edge_type, ...)
		if not edge then
			self.logger:warn("Edge", "Add edge failed. Can not create `" .. edge_or_edge_type .. "`.")
			return false
		end
	else
		self.logger:error(
			"Edge",
			"Add edge failed. The type of edge_or_edge_type must be `string` or `table`, but got `"
				.. type(edge_or_edge_type)
				.. "`."
		)
		return false
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

	self.logger:info("Edge", "Add `" .. edge._type .. "` `" .. edge._id .. "` to graph.")
	return true
end

-----
-- R
-----

function Graph:find_nodes(criteria)
	local result = {}

	for _, node in pairs(self.nodes) do
		local matches = true
		for _, condition in ipairs(criteria) do
			local field, value_or_func = condition[1], condition[2]
			local node_value = node[field]

			if type(value_or_func) == "function" then
				if not value_or_func(node_value) then
					matches = false
					break
				end
			else
				if node_value ~= value_or_func then
					matches = false
					break
				end
			end
		end

		if matches then
			table.insert(result, node)
		end
	end

	return result
end

function Graph:find_edges(criteria)
	local result = {}

	for _, edge in pairs(self.edges) do
		local matches = true
		for _, condition in ipairs(criteria) do
			local field, value_or_func = condition[1], condition[2]
			local edge_value = edge[field]

			if type(value_or_func) == "function" then
				if not value_or_func(edge_value) then
					matches = false
					break
				end
			else
				if edge_value ~= value_or_func then
					matches = false
					break
				end
			end
		end

		if matches then
			table.insert(result, edge)
		end
	end

	return result
end

-----
-- U
-----

-----
-- D
-----

---Remove an edge from the graph using ID.
---If `edge.before_remove_from_graph ~= nil` and / or `edge.after_remove_from_graph ~= nil`,
---`remove_edge` will automatically call these methods before and after removing the edge.
---If `self.current_transaction ~= nil`,
---`remove_edge` will automatically record the its operation and inverse to the transaction.
---@param edge_id EdgeID ID of the edge to be removed.
---@return boolean _ Whether the edge is removed.
function Graph:remove_edge(edge_id)
	local edge = self.edges[edge_id]
	if not edge then
		self.logger:warn("Edge", "Remove edge failed. Can not find edge `" .. edge_id .. "`.")
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

	self.logger:info("Edge", "Remove " .. edge._type .. " <" .. edge._id .. "> from graph.")
	return true
end

---Remove a node from the graph and all edges related to it using ID.
---If `node.before_remove_from_graph ~= nil` and / or `node.after_remove_from_graph ~= nil`,
---`remove_node` will automatically call these methods before and after removing the node.
---If `self.current_transaction ~= nil`,
---`remove_node` will automatically record the its operation and inverse to the transaction.
---@param node_id NodeID ID of the node to be removed.
---@return boolean _ Whether the node is removed.
function Graph:remove_node(node_id)
	local node = self.nodes[node_id]
	if not node then
		self.logger:warn("Node", "Remove node failed. Can not find node `" .. node_id .. "`.")
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

	self.logger:info("Node", "Remove " .. node._type .. " <" .. node._id .. "> from graph.")
	return true
end

----------
-- Transaction Method
----------

---Executes a transaction on the graph.
---This method acquires a lock, executes the provided closure within a transaction,
---and then either commits or rolls back the transaction based on the execution result.
---@param closure function The function to be executed within the transaction.
---@return boolean success Whether the transaction was successfully committed.
function Graph:transact(closure)
	self.lock:acquire()
	self.current_transaction = Transaction:begin(self:create_savepoint())

	local success, err_msg = pcall(closure)
	if success then
		if self.current_transaction:commit() then
			if #self.undo_stack >= self.undo_redo_limit then
				table.remove(self.undo_stack, 1)
			end

			table.insert(self.undo_stack, self.current_transaction)
			self.redo_stack = {}

			self.logger:info("Graph", "Transaction commit completed.")
		else
			success = false
			self.logger:error("Graph", "Transaction commit failed.")
		end
	end

	if not success then
		self.logger:error("Graph", "Transaction failed: " .. err_msg .. ".")

		-- Just simply rollback the savepoint now.
		self:rollback_savepoint(self.current_transaction.savepoint)
		self.logger:info("Graph", "Transaction rollback completed.")
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

---Undo the lastest transaction.
---@return boolean _ Whether the undo operation is successful.
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

---Redo the lastest transaction.
---@return boolean _ Whether the redo operation is successful.
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
----------

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

----------
-- class Method
----------

--------------------

return Graph
