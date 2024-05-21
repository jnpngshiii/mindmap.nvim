local ExcerptNode = require("mindmap.graph.node.excerpt_node")
local HeadingNode = require("mindmap.graph.node.heading_node")

-- The key is the type of the node, and the value is the node class.
return {
	["ExcerptNode"] = ExcerptNode,
	["HeadingNode"] = HeadingNode,
}
