local mindmap = require("mindmap.mindmap")
local misc = require("mindmap.misc")

---@alias mindmap.Mindmap Mindmap

local M = {}

--------------------
-- Class Database
--------------------

---@class Database
---@field mindmap_tbl table<string, Mindmap> Mindmaps in the database.
---@field database_path string Path to the database.
M.Database = {
	mindmap_tbl = {},
	database_path = "",
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

	local database_path = misc.get_current_proj_path() .. ".mindmap"
	obj.database_path = obj.database_path or database_path or self.database_path
	vim.fn.system("mkdir -p " .. obj.database_path)

	setmetatable(obj, self)
	self.__index = self

	return obj
end

---Add an mindmap to the database.
---@param mmap Mindmap Mindmap to be added.
---@return nil
function M.Database:add(mmap)
	if self.mindmap_tbl[mmap.id] then
		vim.api.nvim_out_write("Mindmap with ID " .. mmap.id .. " already exists. Aborting add.\n")
	end

	self.mindmap_tbl[mmap.id] = mmap
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
		if id and id ~= mmap.id then
			goto continue
		end

		local json_content = misc.remove_table_field(mmap)
		local encoded_json_content = vim.fn.json_encode(json_content)

		local json_path = self.database_path .. "/" .. id .. ".json"
		local json, err = io.open(json_path, "w")
		if not json then
			error("Could not open file: " .. err)
		end

		json:write(encoded_json_content)
		json:close()

		::continue::
	end
end

---Load a given mindmap from a JSON file.
---@param id string ID of the mindmap to be loaded.
---@return nil
function M.Database:load(id)
	local json_path = self.database_path .. "/" .. id .. ".json"
	local json, err = io.open(json_path, "r")
	if not json then
		error("Could not open file: " .. err)
	end

	local encoded_json_content = json:read("*a")
	local json_content = vim.fn.json_decode(encoded_json_content)

	self.mindmap_tbl[id] = mindmap.Mindmap:new(json_content)
end

---Find a mindmap in the database.
---If the mindmap is not found and register_if_not is true, then generate, register and return a new mindmap.
---@param id string ID of the mindmap to be found.
---@param register_if_not boolean Register a new mindmap if not found.
---@return Mindmap|nil
function M.Database:find_mindmap(id, register_if_not)
	local found_mmap = self.mindmap_tbl[id]
	if not found_mmap and register_if_not then
		found_mmap = mindmap.Mindmap:new({ mindmap_id = id })
		self:add(found_mmap)
	end
	return found_mmap
end

----------
-- Class Method
----------

--------------------

return M
