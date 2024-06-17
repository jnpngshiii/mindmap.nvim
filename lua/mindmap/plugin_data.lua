local plugin_data = {}

--------------------
-- Class plugin_data.config
--------------------

---@class plugin_data.config
---Logger configuration:
---@field log_level string Log level of the graph. Default: "INFO".
---@field show_log_in_nvim boolean Show log in Neovim. Default: true.
---Graph configuration:
---  Node:
---@field default_node_type string Default type of the node. Default: "SimpleNode".
---@field node_prototype_cls PrototypeNode Prototype of the node. Used to create sub node classes. Must have a `new` method and a `data` field.
---@field node_sub_cls_info table<NodeType, table> Information of the sub node classes. Must have `data`, `ins_methods` and `cls_methods` fields.
---@field default_node_ins_method table<string, function> Default instance method for all nodes. Example: `foo(self, ...)`.
---@field default_node_cls_method table<string, function> Default class method for all nodes. Example: `foo(cls, self, ...)`.
---  Edge:
---@field default_edge_type string Default type of the edge. Default: "SimpleEdge".
---@field edge_prototype_cls PrototypeEdge Prototype of the edge. Used to create sub edge classes. Must have a `new` method and a `data` field.
---@field edge_sub_cls_info table<EdgeType, table> Information of the sub node classes. Must have `data`, `ins_methods` and `cls_methods` fields.
---@field default_edge_ins_method table<string, function> Default instance method for all edges. Example: `bar(self, ...)`.
---@field default_edge_cls_method table<string, function> Default class method for all edges. Example: `bar(cls, self, ...)`.
---Space repetition configuration:
---@field alg_type string Type of the algorithm used in space repetition. Default to "SM2Alg".
---@field alg_prototype_cls PrototypeAlg Prototype of the algorithm. Used to create sub algorithm classes. Must have a `new` method and a `data` field.
---@field alg_sub_cls_info table<AlgType, PrototypeAlg> Information of the sub algorithm classes. Must have `data`, `ins_methods` and `cls_methods` fields.
---@field default_alg_ins_method table<string, function> Default instance method for all algorithms. Example: `baz(self, ...)`.
---@field default_alg_cls_method table<string, function> Default class method for all algorithms. Example: `baz(cls, self, ...)`.
---Behavior configuration:
---  Automatic behavior:
---@field show_excerpt_after_add boolean Show excerpt after adding a node. Default: true.
---@field show_excerpt_after_bfread boolean ...
---@field show_sp_info_after_bfread boolean ...
---  Default behavior:
---@field keymap_prefix string Prefix of the keymap. Default: "<localleader>m".
---@field enable_default_keymap boolean Enable default keymap. Default: true.
---@field enable_default_autocmd boolean Enable default atuocmd. Default: true.
plugin_data.config = {
	-- Logger configuration:
	log_level = "INFO",
	show_log_in_nvim = true,
	-- Graph configuration:
	--   Node:
	default_node_type = "SimpleNode",
	node_prototype_cls = require("mindmap.graph.node.prototype_node"),
	node_sub_cls_info = {
		ExcerptNode = require("mindmap.graph.node.excerpt_node"),
		HeadingNode = require("mindmap.graph.node.heading_node"),
		SimpleNode = require("mindmap.graph.node.simple_node"),
	},
	default_node_ins_method = require("mindmap.graph.node.default_ins_method"),
	default_node_cls_method = require("mindmap.graph.node.default_cls_method"),
	--   Edge:
	default_edge_type = "SimpleEdge",
	edge_prototype_cls = require("mindmap.graph.edge.prototype_edge"),
	edge_sub_cls_info = {
		SelfLoopContentEdge = require("mindmap.graph.edge.self_loop_content_edge"),
		SelfLoopSubheadingEdge = require("mindmap.graph.edge.self_loop_subheading_edge"),
		SimpleEdge = require("mindmap.graph.edge.simple_edge"),
	},
	default_edge_ins_method = require("mindmap.graph.edge.default_ins_method"),
	default_edge_cls_method = require("mindmap.graph.edge.default_cls_method"),
	-- Space repetitionconfiguration:
	alg_type = "SimpleAlg", -- TODO: "SM2Alg"
	alg_prototype_cls = require("mindmap.graph.alg.prototype_alg"),
	alg_sub_cls_info = {
		AnkiAlg = require("mindmap.graph.alg.anki_alg"),
		SimpleAlg = require("mindmap.graph.alg.simple_alg"),
		SM2Alg = require("mindmap.graph.alg.sm2_alg"),
	},
	default_alg_ins_method = require("mindmap.graph.alg.default_ins_method"),
	default_alg_cls_method = require("mindmap.graph.alg.default_cls_method"),
	-- Behavior configuration:
	--   Automatic behavior:
	show_excerpt_after_add = true,
	--   Default behavior:
	keymap_prefix = "<localleader>m",
	enable_default_keymap = true,
	enable_default_autocmd = true,
}

--------------------
-- Class plugin_data.cache
--------------------

---@class plugin_data.cache
---@field graphs table<string, Graph> Graphs of different repo.
---@field namespaces table<string, integer> Namespaces of different virtual text.
plugin_data.cache = {
	graphs = {},
	namespaces = {},
}

return plugin_data
