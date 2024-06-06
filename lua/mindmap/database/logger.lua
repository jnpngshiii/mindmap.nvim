local utils = require("mindmap.utils")

---@alias Timestamp string

--------------------
-- Class Message
--------------------

---@class Message
---@field type string Message type (DEBUG, INFO, WARN, ERROR). Default: "INFO".
---@field source string Message source (Database, Main, Security, etc.). Default: "Unknown".
---@field content string Message content. Default: "Unknown Content.".
---@field timestamp Timestamp Message timestamp.
---@field str string Message string.
---Example:
---2024-05-15 10:30:10 DEBUG [Database] Connecting to database
---2024-05-15 10:30:15 INFO [Main] Application started
---2024-05-15 10:30:20 WARN [Security] Unauthorized access attempt
---2024-05-15 10:30:25 ERROR [Main] Error occurred: NullPointerException
local Message = {}

----------
-- Instance Method
----------

---Create a new message.
---@param type string Message type (DEBUG, INFO, WARN, ERROR). Default: "INFO".
---@param source string Message source (Database, Main, Security, etc.). Default: "Unknown".
---@param content string Message content. Default: "Unknown Content.".
---@param timestamp? Timestamp Message timestamp.
---@param str? string Message string.
---@return Message _
function Message:new(type, source, content, timestamp, str)
	local message = {}

	message.type = type or "INFO"
	message.source = source or "Unknown"
	message.content = content or "Unknown Content."
	message.timestamp = timestamp or os.date("%Y-%m-%d %H:%M:%S")
	message.str = str
		or string.format("%s %s [%s] %s", message.timestamp, message.type, message.source, message.content)

	message.type = nil
	message.source = nil
	message.content = nil
	message.timestamp = nil

	setmetatable(message, self)
	self.__index = self

	return message
end

--------------------
-- Class Logger
--------------------

---@class Logger
---@field log_level string Log level of the logger. Default: "INFO".
---@field show_log_in_nvim boolean Show log in Neovim when added.
---@field save_path string Path to load and save the logger. Default: {stdpath("data")}/mindmap.
---@field messages table<string, Message> Table of messages. Key is the timestamp of the message.
---@field timestamp Timestamp Logger timestamp.
---@field log_level_tbl table<string, number> Table of log levels.
---NOTE: Please make sure the path does not contain a "/" at the end.
local Logger = {}

----------
-- Instance Method
----------

---Create a new logger.
---@param log_level? string Log level of the logger. Default: "INFO".
---@param show_log_in_nvim? boolean Show logs in Neovim when added.
---@param save_path? string Path to load and save the logger. Default: {stdpath("data")}/mindmap.
---@param messages? table<string, Message> Table of messages. Key is the timestamp of the message.
---@param timestamp? Timestamp Logger timestamp.
---@param log_level_tbl? table<string, number> Table of log levels.
---@return Logger _
function Logger:new(log_level, show_log_in_nvim, save_path, messages, timestamp, log_level_tbl)
	local logger = {}

	logger.log_level_tbl = log_level_tbl or {
		["DEBUG"] = 1,
		["INFO"] = 2,
		["WARN"] = 3,
		["ERROR"] = 4,
	}

	if log_level and logger.log_level_tbl[log_level] then
		logger.log_level = log_level
	else
		logger.log_level = "INFO"
	end

	logger.show_log_in_nvim = show_log_in_nvim or false

	logger.save_path = save_path or vim.fn.stdpath("data") .. "/mindmap"
	vim.fn.system("mkdir -p " .. logger.save_path)

	logger.messages = messages or {}
	logger.timestamp = timestamp or os.date("%Y-%m-%d %H:%M:%S")

	setmetatable(logger, self)
	self.__index = self

	return logger
end

---Add a msg to logger.
---@param msg Message Message to be added.
---@return nil _
function Logger:add(msg)
	self.messages[#self.messages + 1] = msg
end

---Add a [DEBUG] message to the logger.
---@param source string Message source (Database, Main, Security, etc.). Default: "Unknown".
---@param content string Message content.
function Logger:debug(source, content)
	if self.log_level_tbl["DEBUG"] < self.log_level_tbl[self.log_level] then
		return
	end

	local msg = Message:new("DEBUG", source, content)
	self:add(msg)
	self:save()

	if self.show_log_in_nvim then
		vim.notify(msg.str, vim.log.levels.DEBUG)
	end
end

---Add a [INFO] message to the logger.
---@param source string Message source (Database, Main, Security, etc.). Default: "Unknown".
---@param content string Message content.
function Logger:info(source, content)
	if self.log_level_tbl["INFO"] < self.log_level_tbl[self.log_level] then
		return
	end

	local msg = Message:new("INFO", source, content)
	self:add(msg)
	self:save()

	if self.show_log_in_nvim then
		vim.notify(msg.str, vim.log.levels.INFO)
	end
end

---Add a [WARN] message to the logger.
---@param source string Message source (Database, Main, Security, etc.). Default: "Unknown".
---@param content string Message content.
function Logger:warn(source, content)
	if self.log_level_tbl["WARN"] < self.log_level_tbl[self.log_level] then
		return
	end

	local msg = Message:new("WARN", source, content)
	self:add(msg)
	self:save()

	if self.show_log_in_nvim then
		vim.notify(msg.str, vim.log.levels.WARN)
	end
end

---Add a [ERROR] message to the logger.
---@param source string Message source (Database, Main, Security, etc.). Default: "Unknown".
---@param content string Message content.
function Logger:error(source, content)
	if self.log_level_tbl["ERROR"] < self.log_level_tbl[self.log_level] then
		return
	end

	local msg = Message:new("ERROR", source, content)
	self:add(msg)
	self:save()

	if self.show_log_in_nvim then
		vim.notify(msg.str, vim.log.levels.ERROR)
	end
end

----------
-- Class Method
----------

---Save a logger to a json file.
---@param logger Logger Logger to be saved.
---@return nil _
function Logger.save(logger)
	local json_content = vim.fn.json_encode(utils.remove_table_fields(logger))

	local json_path = logger.save_path .. "/" .. "log " .. logger.timestamp .. ".json"
	local json, err = io.open(json_path, "w")
	if not json then
		error("[Logger] Could not open file: " .. err)
	end

	json:write(json_content)
	json:close()
end

--------------------

if false then
	local lg = Logger:new("DEBUG", true)
	lg:debug("Main", "This is a debug message")
	lg:info("Main", "This is an info message")
	lg:warn("Main", "This is a warn message")
	lg:error("Main", "This is an error message")
end

return {
	["Logger"] = Logger,
}
