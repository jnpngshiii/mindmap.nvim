local utils = require("mindmap.utils")

--------------------
-- Class Message
--------------------

---@alias Timestamp string

---@class Message
---@field type string Message type (DEBUG, INFO, WARN, ERROR). Default: `"INFO"`.
---@field source string Message source (DATABASE, MAIN, SECURITY, etc.). Default: `"UNKNOWN"`.
---@field content string Message content. Default: `"Unknown Content`.".
---@field timestamp Timestamp Message timestamp.
---@field str string Message string.
---Example:
---  2024-05-15 10:30:10 DEBUG [Database] Connecting to database
---  2024-05-15 10:30:15 INFO [Main] Application started
---  2024-05-15 10:30:20 WARN [Security] Unauthorized access attempt
---  2024-05-15 10:30:25 ERROR [Main] Error occurred: NullPointerException
local Message = {}

---Create a new message.
---@param type string Message type (DEBUG, INFO, WARN, ERROR). Default: `"INFO"`.
---@param source string Message source (DATABASE, MAIN, SECURITY, etc.). Default: `"UNKNOWN"`.
---@param content string Message content. Default: `"Unknown Content`."`.
---@param timestamp? Timestamp Message timestamp.
---@param str? string Message string.
---@return Message message The created message.
function Message:new(type, source, content, timestamp, str)
	local message = {}

	message.type = type:upper() or "INFO"
	message.source = source:upper() or "UNKNOWN"
	message.content = content or "Unknown Content."
	message.timestamp = timestamp or os.date("%Y-%m-%d %H:%M:%S")
	message.str = str
		or string.format("%s %s [%s] %s", message.timestamp, message.type, message.source, message.content)

	setmetatable(message, self)
	self.__index = self

	return message
end

--------------------
-- Class Logger
--------------------

---@class Logger
---@field log_level string Log level of the logger. Default: `"INFO"`.
---@field show_log_in_nvim boolean Show log in Neovim when added.
---@field save_path string Path to load and save the logger. Default: `{stdpath("data")}/mindmap`.
---@field messages table<string, Message> Table of messages. Key is the timestamp of the message.
---@field timestamp Timestamp Logger timestamp.
---@field log_level_tbl table<string, number> Table of log levels.
---NOTE: Please make sure the path does not contain a "/" at the end.
local Logger = {}

---Create a new logger.
---@param log_level? string Log level of the logger. Default: `"INFO"`.
---@param show_log_in_nvim? boolean Show logs in Neovim when added.
---@param save_path? string Path to load and save the logger. Default: `{stdpath("data")}/mindmap`.
---@param messages? table<string, Message> Table of messages. Key is the timestamp of the message.
---@param timestamp? Timestamp Logger timestamp.
---@param log_level_tbl? table<string, number> Table of log levels.
---@return Logger logger The created logger.
function Logger:new(log_level, show_log_in_nvim, save_path, messages, timestamp, log_level_tbl)
	local logger = {}

	logger.log_level_tbl = log_level_tbl or {
		["DEBUG"] = 1,
		["INFO"] = 2,
		["WARN"] = 3,
		["ERROR"] = 4,
	}

	if log_level then
		log_level = log_level:upper()

		if logger.log_level_tbl[log_level] then
			logger.log_level = log_level
		else
			logger.log_level = "INFO"
		end
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

---Add a message to logger.
---@param msg Message Message to be added.
---@return nil
function Logger:add(msg)
	self.messages[#self.messages + 1] = msg
end

---Add a [DEBUG] message to the logger.
---@param source string Message source (DATABASE, MAIN, SECURITY, etc.). Default: `"UNKNOWN"`.
---@param content string Message content.
---@return nil
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

---Add an [INFO] message to the logger.
---@param source string Message source (DATABASE, MAIN, SECURITY, etc.). Default: `"UNKNOWN"`.
---@param content string Message content.
---@return nil
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
---@param source string Message source (DATABASE, MAIN, SECURITY, etc.). Default: `"UNKNOWN"`.
---@param content string Message content.
---@return nil
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

---Add an [ERROR] message to the logger.
---@param source string Message source (DATABASE, MAIN, SECURITY, etc.). Default: `"UNKNOWN"`.
---@param content string Message content.
---@return nil
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

---Save the logger to a JSON file.
---@return nil
function Logger:save()
	local json_content = vim.fn.json_encode(utils.remove_table_fields(self))

	local json_path = self.save_path .. "/" .. "log_" .. self.timestamp .. ".json"
	local json, err_msg = io.open(json_path, "w")
	if not json then
		vim.notify("[Logger] Failed to open file: " .. err_msg .. ". Abort saving.", vim.log.levels.ERROR)
		return
	end

	json:write(json_content)
	json:close()
end

--------------------

return Logger
