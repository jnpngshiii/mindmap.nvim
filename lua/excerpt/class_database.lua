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
	obj.timestamp = obj.timestamp or os.time()

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
M.Database = {
	cache = {},
}

----------
-- Class Method
----------

--- Trigger a function on given items.
---@param items Item[] Items to trigger the function on.
---@param func function|string Function to trigger.
---@param ... any Arguments for the function.
---@return any[]
function M.Database.trigger(items, func, ...)
	-- TODO: Return the output of the function (may be nil) as a table.
	-- TODO: If items is not given, then use self.cache.
	-- TODO: Support for single item.
	-- TODO: Add type checking.
	local output = {}
	if type(func) == "string" then
		for _, item in pairs(items) do
			if type(item[func]) == "function" then
				item[func](item, ...)
			else
				print("Method '" .. func .. "' does not exist for item.\n")
			end
		end
	elseif type(func) == "function" then
		for _, item in pairs(items) do
			func(item, ...)
		end
	else
		print("Invalid argument type for 'func'\n.")
	end
	return output
end

----------
-- Instance Method
----------

---@return table
function M.Database:init(obj)
	obj = obj or {}
	obj.cache = obj.cache or self.cache

	setmetatable(obj, self)
	self.__index = self

	return obj
end

---@deprecated
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

---@deprecated
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

--- Find item(s) in the database.
---@param timestamp string|string[]
---@return Item|Item[]
function M.Database:find(timestamp)
	if type(timestamp) ~= "table" then
		if type(timestamp) == "string" then
			return self.cache[timestamp]
		end
	end

	local found_items = {}
	for _, v in pairs(timestamp) do
		found_items[v] = self:find(v)
	end
	return found_items
end

--------------------

return M
