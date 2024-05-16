local misc = require("mindmap.misc")

local M = {}

--------------------
-- Class SimpleItem
--------------------

-- SimpleItem can be used as a simple item, or a simple database that manages sub items.
--
-- Example:
-- ---@class Card : SimpleItem
--
-- ---@class Mindnode : SimpleItem
-- ---@field sub_items Card Cards in the mindnode.
--
-- ---@class Mindmap : SimpleItem
-- ---@field sub_items Mindnode Mindnodes in the mindmap.
--
-- ---@class Database : SimpleItem
-- ---@field sub_items Mindmap Mindmaps in the database.

---@class SimpleItem
---@field type string Type of the item.
---@field id string Id of the item.
---@field created_at integer Created time of the item.
---@field updated_at integer Updated time of the item.
---@field save_path string Path to load and save the item.
---Default: {current_project_path}/.mindmap/{id}.json
---Please make sure the path does not contain a "/" at the end.
---@field sub_items table<string, SimpleItem> Sub items in the item.
M.SimpleItem = {}

----------
-- Instance Method
----------

---@param tbl? table Table used to create the item.
---@param sub_item_class? SimpleItem Class of the sub items.
---@return table
function M.SimpleItem:new(tbl, sub_item_class)
	tbl = tbl or {}

	tbl.type = tbl.type or "simpleitem"
	tbl.id = tbl.id or (tbl.type .. "-" .. misc.get_unique_id())
	tbl.created_at = tbl.created_at or tonumber(os.time())
	tbl.updated_at = tbl.updated_at or tonumber(os.time())

	tbl.save_path = tbl.save_path or misc.get_current_proj_path() .. "/.mindmap"
	vim.fn.system("mkdir -p " .. tbl.save_path)

	tbl.sub_items = tbl.sub_items or {}
	-- If sub_item_class is provided and has function `new`, use this function to create sub items.
	if sub_item_class and sub_item_class.new then
		local json_path = tbl.save_path .. "/" .. tbl.id .. ".json"
		local json, _ = io.open(json_path, "r")
		if json then
			local json_content = vim.fn.json_decode(json:read("*a"))
			for k, v in pairs(json_content) do
				if type(k) == "string" and type(v) == "table" and not v.new then
					-- Make sure v is just a table.
					tbl.sub_items[k] = v
				end
			end
		end
		-- Create sub items using the provided function `new`.
		if not #tbl.sub_items then
			for k, v in pairs(tbl.sub_items) do
				tbl.sub_items[k] = sub_item_class:new(v)
			end
		end
	end

	-- TODO: Check the health of sub items.

	setmetatable(tbl, self)
	self.__index = self

	return tbl
end

---Add a sub item to the item.
---@param item SimpleItem Sub item to be added.
---@return nil
function M.SimpleItem:add(item)
	self.sub_items[item.id] = item
end

---Remove a sub item from the item.
---@param id string Sub item ID to be removed.
---@return nil
function M.SimpleItem:remove(id)
	self.sub_items[id] = nil
end

---@deprecated
---Pop a sub item from the item and return it.
---@param id string Sub item ID to be popped.
---@return SimpleItem
function M.SimpleItem:pop(id)
	error("Not implemented")
end

---@deprecated
---Find a sub item in the item and return it.
---If the item is not found and created_if_not_found = true,
---then create and return a new item.
---@param id string Sub item ID to be found.
---@param created_if_not_found boolean Create a new item if not found.
---@return SimpleItem
function M.SimpleItem:find(id, created_if_not_found)
	local found_item = self.sub_items[id]
	if not found_item and created_if_not_found then
		found_item = self:new({ id = id })
		self:add(found_item)
	end
	return found_item
end

---@deprecated
---Check if the item is healthy.
---@return boolean
function M.SimpleItem:is_healthy()
	error("Not implemented")
end

---@deprecated
---This is a test function.
function M.SimpleItem:show_id()
	if vim.api then
		vim.api.nvim_out_write(self.id .. "\n")
	else
		print(self.id)
	end
end

---Trigger a function on each sub item in the item.
---@param func function|string Function to trigger.
---If string, the function should be a method of the sub item.
---If function, the function should be a function that takes an sub item as the first argument.
---@param ... any Function arguments to be passed.
---@return any
function M.SimpleItem:trigger(func, ...)
	-- TODO: Return the output of the function (may be nil) as a table.
	local output = {}
	if type(func) == "string" then
		for _, item in pairs(self.sub_items) do
			if type(item[func]) == "function" then
				item[func](item, ...)
			else
				print("Method '" .. func .. "' does not exist for item.\n")
			end
		end
	elseif type(func) == "function" then
		for _, item in pairs(self.sub_items) do
			func(item, ...)
		end
	else
		print("Invalid argument type for 'func'\n.")
	end
	return output
end

----------
-- Class Method
----------

---Save an item to a JSON file.
---@param item SimpleItem Item to be saved.
---@return nil
function M.SimpleItem.save(item)
	local json_content = vim.fn.json_encode(misc.remove_table_field(item))

	local json_path = item.save_path .. "/" .. item.id .. ".json"
	local json, err = io.open(json_path, "w")
	if not json then
		error("Could not open file: " .. err)
	end

	json:write(json_content)
	json:close()
end

----------

return M
