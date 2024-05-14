local misc = require("mindmap.misc")

local M = {}

--------------------
-- Class Logger
--------------------

-- 2021-09-15 10:30:15 INFO [Main] Application started
-- 2021-09-15 10:30:20 DEBUG [Database] Connecting to database
-- 2021-09-15 10:30:25 ERROR [Main] Error occurred: NullPointerException
-- 2021-09-15 10:30:30 WARN [Security] Unauthorized access attempt

---@class Logger
---@field cache string[] The cache of log messages.
---@field log_path string Path to the log file.
---@field log_level string Log level of the logger.
---@field log_level_table table<string, number> The table of log levels.
M.Logger = {
	cache = {},
	log_path = "",
	log_level = "INFO", -- NOT USED
	log_level_table = {
		INFO = 1,
		DEBUG = 2,
		ERROR = 3,
		WARN = 4,
	},
}

----------
-- Instance Method
----------

---@param obj table?
---@return table
function M.Logger:init(obj)
	obj = obj or {}
	obj.cache = obj.cache or self.cache
	obj.log_path = obj.log_path or self.log_path
	obj.log_level = obj.log_level or self.log_level
	obj.log_level_table = obj.log_level_table or self.log_level_table

	if misc.check_table_index(self.log_level, self.log_level_table) then
		error("Logger Error: Invalid log level: " .. self.log_level)
	end

	setmetatable(obj, self)
	self.__index = self

	return obj
end

---Log a message.
---@param msg string The message to log.
---@param msg_level string The level of the message.
---@return nil
function M.Logger:log(msg, msg_level)
	if misc.check_table_index(msg_level, self.log_level_table) then
		error("Logger Error: Invalid log level: " .. msg_level)
	end

	local formatted_timestamp = os.date("%Y-%m-%d %H:%M:%S", os.time())
	msg = formatted_timestamp .. " " .. string.upper(msg_level) .. " " .. msg .. "\n"

	self.cache[#self.cache + 1] = msg
	self:save(msg)

	if true then
		vim.api.nvim_out_write(msg)
	end
end

---Show all logs in the log cache.
---@return nil
function M.Logger:show()
	for _, msg in pairs(self.cache) do
		vim.api.nvim_out_write(msg .. "\n")
	end
end

---Show all logs in the log file.
---@return nil
function M.Logger:show_all()
	local log_file, err = io.open(self.log_path, "r")
	if not log_file then
		error("Logger Info: Could not open file at: " .. self.log_path .. " Error: " .. err)
	end

	local log_content = log_file:read("*a")
	for msg in log_content:gmatch("[^\n\r]+") do
		vim.api.nvim_out_write(msg .. "\n")
	end

	log_file:close()
end

---Clean the log cache.
---@return nil
function M.Logger:clean()
	self.cache = {}
end

---Clean the log file.
---@return nil
function M.Logger:clean_all()
	local log_file, err = io.open(self.log_path, "w")
	if not log_file then
		error("Logger Info: Could not open file at: " .. self.log_path .. " Error: " .. err)
	end

	log_file:write("")
	log_file:close()
	self:clean()
end

---Save a log to the log file.
---@return nil
function M.Logger:save(msg)
	local log_file, err = io.open(self.log_path, "a")
	if not log_file then
		error("Logger Info: Could not open file at: " .. self.log_path .. " Error: " .. err)
	end

	log_file:seek("end")
	log_file:write(msg)
	log_file:close()
end

----------
-- Class Method
----------

--------------------

return M
