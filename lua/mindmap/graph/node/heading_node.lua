local PrototypeNode = require("mindmap.graph.node.prototype_node")

local utils = require("mindmap.utils")
local ts_utils = require("mindmap.ts_utils")

local nts_utils = require("nvim-treesitter.ts_utils")

--------------------
-- Class HeadingNode
--------------------

---@class HeadingNode : PrototypeNode
local HeadingNode = setmetatable({}, { __index = PrototypeNode })
HeadingNode.__index = HeadingNode

local heading_node_version = 0.0
-- v0.0: Initial version.

----------
-- Instance method
----------

---Create a new excerpt.
---@param file_name string Name of the file where the node is from.
---@param rel_file_path string Relative path to the project root of the file where the node is from.
---
---@param data? table Data of the node. Subclass should put there own data in this field.
---
---@param tag? string[] Tag of the node.
---@param version? integer Version of the node.
---@param created_at? integer Created time of the node in Unix timestamp format.
---@param incoming_edge_ids? table<EdgeID, EdgeID> IDs of incoming edges to this node.
---@param outcoming_edge_ids? table<EdgeID, EdgeID> IDs of outcoming edges from this node.
---@return HeadingNode|PrototypeNode _ The created node.
function HeadingNode:new(
	file_name,
	rel_file_path,

	data,

	tag,
	version,
	created_at,
	incoming_edge_ids,
	outcoming_edge_ids
)
	local prototype_node = PrototypeNode:new(
		"HeadingNode",
		file_name,
		rel_file_path,
		--
		data,
		--
		tag,
		version or heading_node_version,
		created_at,
		incoming_edge_ids,
		outcoming_edge_ids
	)

	setmetatable(prototype_node, self)
	self.__index = self

	return prototype_node
end

---Get the content of the node.
---@return table<string, string[]> _ { title = string[], content = string[] }
function HeadingNode:get_content()
	local output = {
		title = {},
		content = {},
	}

	local parsed_query = vim.treesitter.query.parse(
		"norg",
		[[
    (_
      title: (paragraph_segment
        (inline_comment)
      )
    ) @heading_node
    ]]
	)

	local abs_proj_path = utils.get_file_info()[4]
	local abs_file_path = utils.get_abs_path(self.rel_file_path, abs_proj_path)
	local bufnr, is_temp_buf = unpack(utils.get_bufnr_from_file_path(abs_file_path .. "/" .. self.file_name))
	local root_node = ts_utils.get_tstree_root(bufnr)

	for _, heading_node in parsed_query:iter_captures(root_node, 0) do
		local results = ts_utils.get_title_and_content_node(heading_node, bufnr)
		if results[1] then
			output.title = nts_utils.get_node_text(results[1], bufnr)
		end
		if results[2] then
			output.content = nts_utils.get_node_text(results[2], bufnr)
		end
	end

	if is_temp_buf then
		vim.api.nvim_buf_delete(bufnr, { force = true })
	end

	return output
end

----------
-- Class method
----------

---Convert a table to a node.
---@param table table Table to be converted.
---@return PrototypeNode _ The converted node.
function HeadingNode.from_table(table)
	return HeadingNode:new(
		table.file_name,
		table.rel_file_path,
		--
		table.data,
		--
		table.tag,
		table.version,
		table.created_at,
		table.incoming_edge_ids,
		table.outcoming_edge_ids
	)
end

--------------------

return HeadingNode
