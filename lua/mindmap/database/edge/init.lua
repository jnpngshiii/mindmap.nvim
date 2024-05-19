local SelfLoopEdge = require("mindmap.database.edge.self_loop_edge")

-- The key is the type of the edge, and the value is the edge class.
-- TODO: Maybe we need a better way to manage edge classes. Such as automatically loading all edge classes in the directory.
return {
	["SelfLoopEdge"] = SelfLoopEdge,
}
