local misc = require("excerpt.misc")

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
-- Class Method
----------

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

---@return nil
function M.Logger:log(msg, msg_level)
	if misc.check_table_index(msg_level, self.log_level_table) then
		error("Logger Error: Invalid log level: " .. msg_level)
	end

	local formatted_timestamp = os.date("%Y-%m-%d %H:%M:%S", os.time())
	msg = formatted_timestamp .. " " .. string.upper(msg_level) .. " " .. msg .. "\n"

	self.cache[#self.cache + 1] = msg
	self:save(msg)
end

---@return nil
function M.Logger:show()
	for _, msg in pairs(self.cache) do
		vim.api.nvim_out_write(msg .. "\n")
	end
end

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

---@return nil
function M.Logger:clean()
	self.cache = {}
end

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

--------------------

-- TODO: Interesting, but not useful.

--- Wrap a function with a wrapping function.
---@param wrapping_func function The function used to wrap.
---@param wrapped_func function The function to be wrapped.
---@return function
function M.wrap_func(wrapping_func, wrapped_func)
	return function(...)
		wrapping_func(wrapped_func, ...)
	end
end

--- Wrap all functions in a table with a wrapping function recursively.
---@param wrapping_func function The function used to wrap.
---@param wrapped_tbl table The table to be wrapped.
---@return table
function M.wrap_table(wrapping_func, wrapped_tbl)
	for key, value in pairs(wrapped_tbl) do
		-- print("Checking key: " .. key .. " type: " .. type(value))
		if type(value) == "function" and key ~= "init" then
			-- print("    Wraping function: " .. key)
			wrapped_tbl[key] = M.wrap_func(wrapping_func, value)
		elseif type(value) == "table" then
			if key == "__index" then
				-- print("    Skip __index")
				wrapped_tbl[key] = value
			else
				wrapped_tbl[key] = M.wrap_table(wrapping_func, value)
			end
		end
	end
	return wrapped_tbl
end

if false then
	local unwrapped_logger_instance = M.Logger:init({
		log_path = "unwrapped_logger.log",
	})

	local function test_wrapping_func(func, ...)
		print("Output from wrapping function")
		func(...)
	end
	local wraped_logger = M.wrap_table(test_wrapping_func, M.Logger)
	local wrapped_logger_instance = wraped_logger:init({
		log_path = "wrapped_logger.log",
	})

	wrapped_logger_instance:clean_all()
	wrapped_logger_instance:log("Hello, a!")
	wrapped_logger_instance:log("Hello, s!")
	wrapped_logger_instance:log("Hello, d!")
	wrapped_logger_instance:log("Hello, f!")
	wrapped_logger_instance:show()
	wrapped_logger_instance:clean()
	wrapped_logger_instance:log("Hello, World!")
	wrapped_logger_instance:show_all()
end

--------------------

return M
