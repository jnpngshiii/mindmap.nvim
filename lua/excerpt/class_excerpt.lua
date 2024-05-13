local class_database = require("excerpt.class_database")
local class_log = require("excerpt.class_log")
local misc = require("excerpt.misc")

local M = {}

--------------------
-- Class ExcerptDatabase
--------------------

---@class ExcerptDatabase:Database
---@field cache ExcerptItem[]
---@field json_path string Path to the JSON file used to store the database.
---@field logger any Logger of the database. NOTE: Logger should have a method log(msg, msg_level).
M.ExcerptDatabase = class_database.Database:init({
	cache = {},
	json_path = "",
	logger = nil,
})

function M.ExcerptDatabase:init(obj)
	obj = obj or {}
	obj.cache = obj.cache or self.cache
	obj.json_path = obj.json_path or self.json_path
	obj.logger = obj.logger or self.logger
	if obj.logger then
		obj.logger:log("[Logger] Init logger.", "info")
	end

	setmetatable(obj, self)
	self.__index = self

	-- self:load()

	return obj
end

----------
-- Class Method
----------

----------
-- Instance Method
----------

--- Save the database to a JSON file.
---@return nil
function M.ExcerptDatabase:save()
	local json_context = {}
	for _, excerpt in pairs(self.cache) do
		if excerpt:check_health() then
			json_context[#json_context + 1] = excerpt.to_table(excerpt)
		else
			self:log("[Database] Invalid Excerpt (" .. excerpt.timestamp .. "), skip saving.", "error")
		end
	end
	json_context = vim.fn.json_encode(json_context)

	local json, err = io.open(self.json_path, "w")
	if not json then -- TODO:
		self:log("[Database] Could not save database at: " .. self.json_path, "error")
		error("Could not open file: " .. err)
	end

	json:write(json_context)
	json:close()
end

--- Load the database from a JSON file.
---@return nil
function M.ExcerptDatabase:load()
	local json_context = {}
	local json, _ = io.open(self.json_path, "r")
	if not json then
		-- Use save() to create a json file.
		self:save()
		self:log("[Database] Database not found at: " .. self.json_path .. ". Created a new one.", "info")
		return
	end
	json_context = vim.fn.json_decode(json:read("*a"))

	for _, table in pairs(json_context) do
		if type(table) == "table" then
			local excerpt = M.ExcerptItem.from_table(table)
			self.cache[excerpt.timestamp] = excerpt
		end
	end

	self:log("[Database] Database loaded at: " .. self.json_path, "info")
	json:close()
end

--- Call log method of the logger, or call fallback method.
---@param msg string Log message.
---@param msg_level string Log message level.
---@return nil
function M.ExcerptDatabase:log(msg, msg_level)
	if self.logger then
		self.logger:log(msg, msg_level) -- Use __call?
	else
		local formatted_timestamp = os.date("%Y-%m-%d %H:%M:%S", os.time())
		msg = formatted_timestamp .. " " .. string.upper(msg_level) .. " " .. msg .. "\n"
		if package.loaded["vim.api"] then
			vim.api.nvim_out_write(msg)
		else
			print(msg)
		end
	end
end

--------------------

return M
