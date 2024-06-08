local node_cls_method = {}

---@diagnostic disable-next-line: unused-local
function node_cls_method.to_table(cls, self)
	return {
		id = self.id,
		file_name = self.file_name,
		rel_file_path = self.rel_file_path,
		--
		data = self.data,
		type = self.type,
		tag = self.tag,
		state = self.state,
		version = self.version,
		created_at = self.created_at,
		incoming_edge_ids = self.incoming_edge_ids,
		outcoming_edge_ids = self.outcoming_edge_ids,
	}
end

---@diagnostic disable-next-line: unused-local
function node_cls_method.from_table(cls, self, tbl)
	return cls:new(
		tbl.id,
		tbl.file_name,
		tbl.rel_file_path,
		--
		tbl.data,
		tbl.type,
		tbl.tag,
		tbl.state,
		tbl.version,
		tbl.created_at,
		tbl.incoming_edge_ids,
		tbl.outcoming_edge_ids
	)
end

return node_cls_method
