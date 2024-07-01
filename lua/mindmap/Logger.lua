--------------------
-- Class Logger
--------------------

---@class Logger
---@field log_level number Log level of the logger.
---@field log_dir string Directory to store log files.
---@field log_timestamp string Timestamp used for the log file name.
local Logger = {}
Logger.__index = Logger

---Create a new logger.
---@param log_level? number Log level of the logger. Default: `vim.log.levels.INFO`.
---@param log_dir? string Directory to store log files. Default: `vim.fn.stdpath("data") .. "/mindmap/logs"`.
---@return Logger logger The created logger.
function Logger:new(log_level, log_dir)
  local logger = {
    log_level = log_level or vim.log.levels.INFO,
    log_dir = log_dir or vim.fn.stdpath("data") .. "/mindmap/logs",
    log_timestamp = os.date("%Y-%m-%d_%H-%M-%S"),
  }
  logger.__index = logger
  setmetatable(logger, Logger)

  vim.fn.mkdir(logger.log_dir, "p")

  return logger
end

---Internal method to handle logging.
---@param level number Log level from `vim.log.levels`.
---@param source string Message source (e.g., "Main", "Database", "Security").
---@param content string Message content.
---@return nil
function Logger:log(level, source, content)
  if level < self.log_level then
    return
  end

  -- Example:
  --   2024-05-15 10:30:10 DEBUG [Database] Connecting to database
  --   2024-05-15 10:30:15 INFO [Main] Application started
  --   2024-05-15 10:30:20 WARN [Security] Unauthorized access attempt
  --   2024-05-15 10:30:25 ERROR [Main] Error occurred: NullPointerException
  local timestamp = os.date("%Y-%m-%d %H:%M:%S")
  local level_name = vim.lsp.log_levels[level]
  local msg = string.format("%s %s [%s] %s", timestamp, level_name, source, content)

  self:save(msg)

  if level_name == "ERROR" then
    error(msg)
  else
    vim.schedule(function()
      vim.notify(msg, level)
    end)
  end
end

---Save logs to file.
---@param msg string The log message to save.
---@return nil
function Logger:save(msg)
  local file_path = string.format("%s/%s.log", self.log_dir, self.log_timestamp)
  local file, err_msg = io.open(file_path, "a")
  if not file then
    vim.schedule(function()
      vim.notify(string.format("[Logger] Failed to write log to file: %s", err_msg), vim.log.levels.ERROR)
    end)
    return
  end

  file:write(msg .. "\n")
  file:close()
end

---Log a TRACE level message.
---@param source string Message source.
---@param content string Message content.
function Logger:trace(source, content)
  self:log(vim.log.levels.TRACE, source, content)
end

---Log a DEBUG level message.
---@param source string Message source.
---@param content string Message content.
function Logger:debug(source, content)
  self:log(vim.log.levels.DEBUG, source, content)
end

---Log an INFO level message.
---@param source string Message source.
---@param content string Message content.
function Logger:info(source, content)
  self:log(vim.log.levels.INFO, source, content)
end

---Log a WARN level message.
---@param source string Message source.
---@param content string Message content.
function Logger:warn(source, content)
  self:log(vim.log.levels.WARN, source, content)
end

---Log an ERROR level message.
---@param source string Message source.
---@param content string Message content.
function Logger:error(source, content)
  self:log(vim.log.levels.ERROR, source, content)
end

---Register a source-specific logger.
---@param source string The source for this logger.
---@return table source_logger A table with trace, debug, info, warn, and error methods.
function Logger:register_source(source)
  return {
    trace = function(content)
      self:log(vim.log.levels.TRACE, source, content)
    end,
    debug = function(content)
      self:log(vim.log.levels.DEBUG, source, content)
    end,
    info = function(content)
      self:log(vim.log.levels.INFO, source, content)
    end,
    warn = function(content)
      self:log(vim.log.levels.WARN, source, content)
    end,
    error = function(content)
      self:log(vim.log.levels.ERROR, source, content)
    end,
  }
end

--------------------

local global_logger = Logger:new(vim.log.levels.DEBUG)
return global_logger
