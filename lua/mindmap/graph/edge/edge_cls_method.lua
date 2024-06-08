local edge_cls_method = {}

---@diagnostic disable-next-line: unused-local
function edge_cls_method.to_table(cls, self)
	return {
		id = self.id,
		from_node_id = self.from_node_id,
		to_node_id = self.to_node_id,
		--
		data = self.data,
		type = self.type,
		tag = self.tag,
		state = self.state,
		version = self.version,
		created_at = self.created_at,
		updated_at = self.updated_at,
		due_at = self.due_at,
		ease = self.ease,
		interval = self.interval,
	}
end

---@diagnostic disable-next-line: unused-local
function edge_cls_method.from_table(cls, self, tbl)
	return cls:new(
		tbl.id,
		tbl.from_node_id,
		tbl.to_node_id,
		--
		tbl.data,
		tbl.type,
		tbl.tag,
		tbl.state,
		tbl.version,
		tbl.created_at,
		tbl.updated_at,
		tbl.due_at,
		tbl.ease,
		tbl.interval
	)
end

return edge_cls_method
