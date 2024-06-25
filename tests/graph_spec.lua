local mocks = require("../tests/helper")

local Graph = require("../lua/mindmap/graph")
local NodeFactory = require("../lua/mindmap/factory/NodeFactory")
local BaseNode = require("../lua/mindmap/node/BaseNode")
local EdgeFactory = require("../lua/mindmap/factory/EdgeFactory")
local BaseEdge = require("../lua/mindmap/edge/BaseEdge")
local AlgFactory = require("../lua/mindmap/factory/AlgFactory")
local BaseAlg = require("../lua/mindmap/alg/BaseAlg")
local Logger = require("../lua/mindmap/graph/logger")

describe("Graph", function()
	local graph
	local node_factory
	local edge_factory
	local alg
	local logger

	before_each(function()
		node_factory = NodeFactory:new(BaseNode)
		edge_factory = EdgeFactory:new(BaseEdge)
		alg = BaseAlg:new()
		logger = Logger:new()
		graph = Graph:new("test_save_dir", node_factory, edge_factory, alg, logger)
	end)

	it("should add a node successfully", function()
		local success = graph:add_node("SimpleNode", "node1")
		assert.is_true(success)
		assert.is_not_nil(graph.nodes["node1"])
	end)

	it("should remove a node successfully", function()
		graph:add_node("SimpleNode", "node1")
		local success = graph:remove_node("node1")
		assert.is_true(success)
		assert.is_nil(graph.nodes["node1"])
	end)

	it("should execute a transaction successfully", function()
		local success = graph:transact(function()
			graph:add_node("SimpleNode", "node1")
			graph:add_node("SimpleNode", "node2")
		end)
		assert.is_true(success)
		assert.is_not_nil(graph.nodes["node1"])
		assert.is_not_nil(graph.nodes["node2"])
	end)
end)
