local PrototypeNode = require("mindmap.graph.node.prototype_node")

local utils = require("mindmap.utils")
local ts_utils = require("mindmap.ts_utils")

--------------------
-- Class HeadingNode
--------------------

---@class HeadingNode : PrototypeNode
local HeadingNode = setmetatable({}, { __index = PrototypeNode })
HeadingNode.__index = HeadingNode

local heading_node_version = 1
-- v1.0: Initial version.

----------
-- Instance method
----------

---Create a new excerpt.
---@param file_name string Name of the file where the node is from.
---@param rel_file_path string Relative path to the project root of the file where the node is from.
---@param tag? string[] Tag of the node.
---@param data? table Data of the node. Subclass should put there own data in this field.
---@param id? NodeID ID of the node.
---@param version? integer Version of the node.
---@param created_at? integer Created time of the node in Unix timestamp format.
---@param incoming_edge_ids? table<EdgeID, EdgeID> IDs of incoming edges to this node.
---@param outcoming_edge_ids? table<EdgeID, EdgeID> IDs of outcoming edges from this node.
---@return HeadingNode|PrototypeNode _
function HeadingNode:new(
	file_name,
	rel_file_path,
	tag,
	data,
	id,
	version,
	created_at,
	incoming_edge_ids,
	outcoming_edge_ids
)
	local prototype_node = PrototypeNode:new(
		"HeadingNode",
		file_name,
		rel_file_path,
		tag,
		data,
		id,
		version or heading_node_version,
		created_at,
		incoming_edge_ids,
		outcoming_edge_ids
	)

	setmetatable(prototype_node, self)
	self.__index = self

	return prototype_node
end

---Check if the node is healthy.
---This is a simple check to see if all the required fields are there.
function HeadingNode:check_health()
	if true and PrototypeNode.check_health(self) then
		return true
	end

	return false
end

---Spaced representation
function HeadingNode:to_card()
	local output = {
		title = "N/A",
		content = "N/A",
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

	local parsed_sub_query = vim.treesitter.query.parse(
		"norg",
		[[
      title: (paragraph_segment
        (inline_comment)? @inline_comment
      ) @title
      content: (paragraph)? @content
    ]]
	)

	local abs_proj_path = utils.get_file_info()[4]
	local abs_file_path = utils.get_abs_path(self.rel_file_path, abs_proj_path)
	local bufnr, is_temp_buf = table.unpack(utils.get_bufnr_from_file_path(abs_file_path .. "/" .. self.file_name))
	local heading_node = utils.get_tstree_root(bufnr)

	for _, sub_node in parsed_query:iter_captures(heading_node, 0) do
		for _, sub_sub_node in parsed_sub_query:iter_captures(sub_node, 0) do
			if parsed_sub_query.captures[sub_sub_node] == "title" then
				output.title = ts_utils.get_node_text(sub_sub_node, bufnr)
			elseif parsed_sub_query.captures[sub_sub_node] == "content" then
				output.content = ts_utils.get_node_text(sub_sub_node, bufnr)
			end

			if string.match(output.title, self.id) then
				break
			end
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
---@return PrototypeNode _
function HeadingNode.from_table(table)
	return HeadingNode:new(
		table.file_name,
		table.rel_file_path,
		table.tag,
		table.data,
		table.id,
		table.version,
		table.created_at,
		table.incoming_edge_ids,
		table.outcoming_edge_ids
	)
end

--------------------

return HeadingNode
