local prototype = require("mindmap.prototype")

local M = {}

--------------------
-- Class Logger
--------------------

---@class Logger : SimpleItem
---@field log_level_tbl table<string, number> Table of log levels.
---@field log_level string Log level of the logger.
---@field show_in_nvim boolean Show logs in Neovim.
M.Logger = prototype.SimpleItem:new()

----------
-- Instance Method
----------

---@param tbl table?
---@return table
function M.Logger:new(tbl)
	tbl = tbl or {}
	tbl.type = "logger"
	tbl = prototype.SimpleItem:new(tbl)

	tbl.log_level_tbl = {
		["DEBUG"] = 1,
		["INFO"] = 2,
		["WARN"] = 3,
		["ERROR"] = 4,
	}

	if tbl.log_level and tbl.log_level_tbl[tbl.log_level] then
	else
		tbl.log_level = "INFO"
	end

	tbl.show_in_nvim = tbl.show_in_nvim or false

	setmetatable(tbl, self)
	self.__index = self

	return tbl
end

---Add a [DEBUG] message to the logger.
---@param source string Message source (Database, Main, Security, etc.). Default: "Unknown".
---@param content string Message content.
function M.Logger:debug(source, content)
	if self.log_level_tbl["DEBUG"] < self.log_level_tbl[self.log_level] then
		return
	end

	local msg = prototype.Message:new({
		type = "DEBUG",
		source = source,
		content = content,
	})
	self:add(msg)
	self:save()

	if self.show_in_nvim then
		vim.cmd("echohl comment")
		local ok = pcall(vim.cmd, string.format('echom "%s"', msg.string))
		if not ok then
			vim.api.nvim_out_write(msg.string .. "\n")
		end
		vim.cmd("echohl NONE")
	end
end

---Add a [INFO] message to the logger.
---@param source string Message source (Database, Main, Security, etc.). Default: "Unknown".
---@param content string Message content.
function M.Logger:info(source, content)
	if self.log_level_tbl["INFO"] < self.log_level_tbl[self.log_level] then
		return
	end

	local msg = prototype.Message:new({
		type = "INFO",
		source = source,
		content = content,
	})
	self:add(msg)
	self:save()

	if self.show_in_nvim then
		vim.cmd("echohl None")
		local ok = pcall(vim.cmd, string.format('echom "%s"', msg.string))
		if not ok then
			vim.api.nvim_out_write(msg.string .. "\n")
		end
		vim.cmd("echohl NONE")
	end
end

---Add a [WARN] message to the logger.
---@param source string Message source (Database, Main, Security, etc.). Default: "Unknown".
---@param content string Message content.
function M.Logger:warn(source, content)
	if self.log_level_tbl["WARN"] < self.log_level_tbl[self.log_level] then
		return
	end

	local msg = prototype.Message:new({
		type = "WARN",
		source = source,
		content = content,
	})
	self:add(msg)
	self:save()

	if self.show_in_nvim then
		vim.cmd("echohl WarningMsg")
		local ok = pcall(vim.cmd, string.format('echom "%s"', msg.string))
		if not ok then
			vim.api.nvim_out_write(msg.string .. "\n")
		end
		vim.cmd("echohl NONE")
	end
end

---Add a [ERROR] message to the logger.
---@param source string Message source (Database, Main, Security, etc.). Default: "Unknown".
---@param content string Message content.
function M.Logger:error(source, content)
	if self.log_level_tbl["ERROR"] < self.log_level_tbl[self.log_level] then
		return
	end

	local msg = prototype.Message:new({
		type = "ERROR",
		source = source,
		content = content,
	})
	self:add(msg)
	self:save()

	if self.show_in_nvim then
		vim.cmd("echohl ErrorMsg")
		local ok = pcall(vim.cmd, string.format('echom "%s"', msg.string))
		if not ok then
			vim.api.nvim_out_write(msg.string .. "\n")
		end
		vim.cmd("echohl NONE")
	end
end

----------
-- Class Method
----------

--------------------

if true then
	local lg = M.Logger:new({
		id = os.date("%Y-%m-%d %H:%M:%S"),
		log_level = "DEBUG",
		show_in_nvim = true,
	})
	lg:debug("Main", "This is a debug message")
	lg:info("Main", "This is an info message")
	lg:warn("Main", "This is a warn message")
	lg:error("Main", "This is an error message")
end

return M
