local mindmap = require("mindmap.mindmap")
local misc = require("mindmap.misc")

---@alias mindmap.Mindmap Mindmap

local M = {}

--------------------
-- Class Database
--------------------

---@class Database
---@field mindmap_tbl table<string, Mindmap> Mindmaps in the database.
M.Database = {
	mindmap_tbl = {},
}

----------
-- Instance Method
----------

---@param obj table?
---@return table
function M.Database:init(obj)
	obj = obj or {}

	obj.mindmap_tbl = obj.mindmap_tbl or self.mindmap_tbl
	if obj.mindmap_tbl then
		for k, v in pairs(obj.mindmap_tbl) do
			obj.mindmap_tbl[k] = mindmap.Mindmap:new(v)
		end
	end

	setmetatable(obj, self)
	self.__index = self

	return obj
end

---Add an mindmap to the database.
---@param mmap Mindmap Mindmap to be added.
---@return nil
function M.Database:add(mmap)
	if self.mindmap_tbl[mmap.mindmap_id] then
		vim.api.nvim_out_write("Mindmap with ID " .. mmap.mindmap_id .. " already exists. Aborting add.\n")
	end

	self.mindmap_tbl[mmap.mindmap_id] = mmap
end

---Pop an mindmap from the database.
---@param id string ID of the mindmap to be popped.
---@return Mindmap|nil
function M.Database:pop(id)
	local popped_mindmap = self.mindmap_tbl[id]
	if popped_mindmap == nil then
		vim.api.nvim_out_write("Mindmap with ID " .. id .. " not found. Aborting pop.\n")
		return nil
	end

	self.mindmap_tbl[id] = nil
	return popped_mindmap
end

---Remove an database from the database.
---@param id string ID of the database to be removed.
---@return nil
function M.Database:remove(id)
	local removed_mindmap = self.mindmap_tbl[id]
	if removed_mindmap == nil then
		vim.api.nvim_out_write("Mindmap with ID " .. id .. " not found. Aborting remove.\n")
		return nil
	end

	self.mindmap_tbl[id] = nil
end

---Save a given mindmap to a JSON file, or all mindmaps if no id is given.
---@param id string? ID of the mindmap to be saved.
---@return nil
function M.Database:save(id)
	-- TODO: Health check
	for _, mmap in pairs(self.mindmap_tbl) do
		if id and id ~= mmap.mindmap_id then
			goto continue
		end

		local json_context = misc.remove_table_field(mmap)
		local encoded_json_context = vim.fn.json_encode(json_context)

		local json_path = vim.fn.stdpath("data") .. "/mindmap/" .. mmap.mindmap_id .. ".json"
		local json, err = io.open(json_path, "w")
		if not json then
			error("Could not open file: " .. err)
		end

		json:write(encoded_json_context)
		json:close()

		::continue::
	end
end

---Load a given mindmap from a JSON file.
---@param id string ID of the mindmap to be loaded.
---@return nil
function M.Database:load(id)
	local json_path = vim.fn.stdpath("data") .. "/mindmap/" .. id .. ".json"
	local json, err = io.open(json_path, "r")
	if not json then
		error("Could not open file: " .. err)
	end

	local encoded_json_context = json:read("*a")
	local json_context = vim.fn.json_decode(encoded_json_context)

	self.mindmap_tbl[id] = mindmap.Mindmap:new(json_context)
end

----------
-- Class Method
----------

--------------------

return M
