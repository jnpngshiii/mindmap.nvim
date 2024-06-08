--------------------
-- Default Sub Edge Class
--------------------

local default_edge_sub_cls = {}

local edge_sub_cls_methods = {
	---@diagnostic disable-next-line: unused-local
	to_table = function(cls, self)
		return {
			id = self.id,
			from_node_id = self.from_node_id,
			to_node_id = self.to_node_id,
			--
			data = self.data,
			type = self.type,
			algorithm = self.algorithm,
			tag = self.tag,
			state = self.state,
			version = self.version,
			created_at = self.created_at,
			updated_at = self.updated_at,
			due_at = self.due_at,
			ease = self.ease,
			interval = self.interval,
		}
	end,

	---@diagnostic disable-next-line: unused-local
	from_table = function(cls, self, tbl)
		return cls:new(
			tbl.id,
			tbl.from_node_id,
			tbl.to_node_id,
			--
			tbl.data,
			tbl.type,
			tbl.algorithm,
			tbl.tag,
			tbl.state,
			tbl.version,
			tbl.created_at,
			tbl.updated_at,
			tbl.due_at,
			tbl.ease,
			tbl.interval
		)
	end,
}

----------
-- SimpleEdge
----------

---@class SimpleEdge : PrototypeEdge

default_edge_sub_cls.SimpleEdge = {
	data = {
		--
	},
	ins_methods = {
		--
	},
	cls_methods = {
		to_table = edge_sub_cls_methods.to_table,
		from_table = edge_sub_cls_methods.from_table,
	},
}

----------
-- SelfLoopContentEdge
----------

---@class SelfLoopContentEdge : PrototypeEdge

default_edge_sub_cls.SelfLoopContentEdge = {
	data = {
		--
	},
	ins_methods = {
		--
	},
	cls_methods = {
		to_table = edge_sub_cls_methods.to_table,
		from_table = edge_sub_cls_methods.from_table,
	},
}

----------
-- SelfLoopSubheadingEdge
----------

---@class SelfLoopSubheadingEdge : PrototypeEdge

default_edge_sub_cls.SelfLoopSubheadingEdge = {
	data = {
		--
	},
	ins_methods = {
		--
	},
	cls_methods = {
		to_table = edge_sub_cls_methods.to_table,
		from_table = edge_sub_cls_methods.from_table,
	},
}

--------------------

return default_edge_sub_cls
