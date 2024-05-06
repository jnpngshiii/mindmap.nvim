local misc = require("excerpt.misc")

local M = {}

--------------------
-- Class Item
--------------------

---@class Item
---@field timestamp number UNIX timestamp when created. Use as identifier.
M.Item = {
	timestamp = 0,
}

----------
-- Class Method
----------

----------
-- Instance Method
----------

---@param obj table?
---@return table
function M.Item:new(obj)
	obj = obj or {}
	obj.timestamp = os.time()

	setmetatable(obj, self)
	self.__index = self

	return obj
end

--- Debugging method.
---@return nil
function M.Item:show_in_nvim_out_write()
	print(self.timestamp .. "\n")
end

--------------------
-- Class Database
--------------------

---@class Database
---@field cache Item[]
---@field json_path string Path to the JSON file used to store the database.
M.Database = {
	json_path = "",
	cache = {},
}

----------
-- Class Method
----------

--- Write the database to a JSON file.
---@param cache Item[]
---@param json_path string
---@return nil
function M.Database.write(cache, json_path)
	local json_content = vim.fn.json_encode(cache)

	local json, err = io.open(json_path, "w")
	if not json then
		error("Could not open file: " .. err)
	end

	json:write(json_content)
	json:close()
end

--- Read the database from a JSON file.
---@param json_path string
---@return nil
function M.Database.read(json_path)
	local json, _ = io.open(json_path, "r")
	if not json then
		M.Database.write({}, json_path)
		return {}
	end

	local cache = vim.fn.json_decode(json:read("*a"))
	json:close()
	return cache
end

----------
-- Instance Method
----------

---@return table
function M.Database:init(obj)
	obj = obj or {}
	obj.json_path = vim.fn.stdpath("data") .. "/excerpt.json"
	obj.cache = self.read(obj.json_path)

	setmetatable(obj, self)
	self.__index = self

	return obj
end

function M.Database:get_max_id()
	if #self.cache == 0 then
		vim.api.nvim_out_write("No Max ID found. Database is empty.\n")
		return nil
	end

	local max_id = 0
	for id, _ in pairs(self.cache) do
		if id > max_id then
			max_id = id
		end
	end
	return max_id
end

--- Add an item to the database.
---@param item Item
---@return nil
function M.Database:add(item)
	-- vim.api.nvim_out_write("Add an item to database.\n")
	self.cache[item.timestamp] = item
end

--- Pop an item from the database.
---@param index number
---@return Item|nil
function M.Database:pop(index)
	local poped_item = self.cache[index]
	if poped_item == nil then
		vim.api.nvim_out_write("No item found. Nothing to pop.\n")
		return nil
	end

	-- vim.api.nvim_out_write("Pop an item from database.\n")
	self.cache[index] = nil
	return poped_item
end

--- Pop the lastest item from the database.
---@return Item|nil
function M.Database:pop_lastest()
	local max_id = self:get_max_id()
	if max_id == nil then
		return
	end

	return self:pop(max_id)
end

--- Remove an item from the database.
---@param index number
---@return nil
function M.Database:remove(index)
	local remove_item = self.cache[index]
	if remove_item == nil then
		vim.api.nvim_out_write("No item found. Nothing to remove.\n")
	end

	-- vim.api.nvim_out_write("Remove an item from database.\n")
	self.cache[index] = nil
end

--- Trigger a function for each item in the database.
---@param func function|string
---@param ... any
---@return nil
function M.Database:trigger(func, ...)
	if type(func) == "string" then
		for _, item in pairs(self.cache) do
			if type(item[func]) == "function" then
				item[func](item, ...)
			else
				print("Method '" .. func .. "' does not exist for item.\n")
			end
		end
	elseif type(func) == "function" then
		for _, item in pairs(self.cache) do
			func(item, ...)
		end
	else
		print("Invalid argument type for 'func'\n.")
	end
end

-- local database_instance = M.Database:init()
-- database_instance:add(M.Item:new())
-- os.execute("sleep 1")
-- database_instance:add(M.Item:new())
-- os.execute("sleep 1")
-- database_instance:add(M.Item:new())
--
-- database_instance:trigger("show_in_nvim_out_write")
--
-- local function show_in_nvim_out_write(item, word)
--   print(item.timestamp .. " " .. word .. "\n")
-- end
--
-- database_instance:trigger(show_in_nvim_out_write, "word")

--------------------

return M
