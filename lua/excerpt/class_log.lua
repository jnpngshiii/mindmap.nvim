local M = {}

--------------------
-- Class Logger
--------------------

---@class Logger
---@field cache string[] The cache of log messages.
---@field log_path string Path to the log file.
M.Logger = {
	cache = {},
	log_path = "",
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
	self.cache = obj.cache or {}
	self.log_path = obj.log_path or ""

	setmetatable(obj, self)
	self.__index = self

	return obj
end

---@return nil
function M.Logger:log(msg)
	self.cache[#self.cache + 1] = msg
	self:save(msg)
end

---@return nil
function M.Logger:show()
	for _, msg in pairs(self.cache) do
		-- vim.api.nvim_out_write(msg .. "\n")
		print(msg)
	end
end

---@return nil
function M.Logger:show_all()
	local log_file, err = io.open(self.log_path, "r")
	if not log_file then
		error("Logger Info: Could not open file: " .. err)
	end

	local log_content = log_file:read("*a")
	log_file:close()

	for _, msg in pairs(log_content) do
		-- vim.api.nvim_out_write(msg .. "\n")
		print(msg)
	end

	self:show()
end

---@return nil
function M.Logger:clear()
	self.cache = {}
end

---@return nil
function M.Logger:clear_all()
	local log_file, err = io.open(self.log_path, "w")
	if not log_file then
		error("Logger Info: Could not open file: " .. err)
	end

	log_file:write("")
	log_file:close()
	self:clear()
end

---@return nil
function M.Logger:save(msg)
	local log_file, err = io.open(self.log_path, "a")
	if not log_file then
		error("Logger Info: Could not open file: " .. err)
	end

	log_file:seek("end")
	log_file:write(msg .. "\n")
	log_file:close()
end

--------------------

local logger = M.Logger:init({
	log_path = "~/log.txt",
})

logger:log("Hello, World!")
logger:show()

logger:clear()
logger:log("!")
logger:show()

logger:clear()
logger:log("Hello, World!")
logger:log("Hello, World!")
logger:show()
logger:save()

return M
