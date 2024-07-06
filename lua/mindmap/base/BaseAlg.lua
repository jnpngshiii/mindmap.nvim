local logger = require("logger").register_plugin("mindmap"):register_source("Base.Alg")

--------------------
-- Class BaseAlg
--------------------

DAY_SECONDS = 86400
HOUR_SECONDS = 3600
MINUTE_SECONDS = 60

---@alias AlgType string

---@class BaseAlg
---@field initial_ease integer Initial ease factor of the algorithm. Default: `250`.
---@field initial_interval integer Initial interval of the algorithm in days. Default: `1`.
---@field version integer Version of the algorithm.
local BaseAlg = {}
BaseAlg.__index = BaseAlg

local base_alg_version = 3
-- v0: Initial version.
-- v1: Rename to `BaseAlg`.
-- v2: Remove `data` field.
-- v3: Add `check_health` method an `upgrade` method.

----------
-- Basic Method
----------

---Create a new algorithm.
---@param version? integer Version of the algorithm.
---@return BaseAlg? base_alg The created algorithm, or nil if check health failed.
function BaseAlg:new(version)
  local base_alg = {
    initial_ease = 250,
    initial_interval = 1,
    version = version or base_alg_version,
  }
  setmetatable(base_alg, BaseAlg)

  base_alg:check_health()

  return base_alg
end

---Basic health check for alg.
---Subclasses should override this method.
---@return nil
function BaseAlg:check_health()
  local issues = {}
  if type(self.initial_ease) ~= "number" then
    table.insert(issues, "Invalid `initial_ease`: expected `number`, got `" .. type(self.initial_ease) .. "`;")
  end
  if type(self.initial_interval) ~= "number" then
    table.insert(issues, "Invalid `initial_interval`: expected `number`, got `" .. type(self.initial_interval) .. "`;")
  end

  if #issues ~= 0 then
    logger.error({ content = "health check failed", extra_info = { issues = issues } })
    error("health check failed")
  end
end

---@abstract
---Answer the card with "easy".
---@param edge BaseEdge The edge being reviewed.
---@param ... any Additional arguments.
---@return nil
---@diagnostic disable-next-line: unused-local, unused-vararg
function BaseAlg:answer_easy(edge, ...)
  logger.warn({
    content = "method 'answer_easy' not implemented",
    action = "operation skipped",
    extra_info = { edge = edge },
  })
end

---@abstract
---Answer the card with "good".
---@param edge BaseEdge The edge being reviewed.
---@param ... any Additional arguments.
---@return nil
---@diagnostic disable-next-line: unused-local, unused-vararg
function BaseAlg:answer_good(edge, ...)
  logger.warn({
    content = "method 'answer_good' not implemented",
    action = "operation skipped",
    extra_info = { edge = edge },
  })
end

---@abstract
---Answer the card with "again".
---@param edge BaseEdge The edge being reviewed.
---@param ... any Additional arguments.
---@return nil
---@diagnostic disable-next-line: unused-local, unused-vararg
function BaseAlg:answer_again(edge, ...)
  logger.warn({
    content = "method 'answer_again' not implemented",
    action = "operation skipped",
    extra_info = { edge = edge },
  })
end

----------
-- Helper Method
----------

---Adjust the interval for 8 or more days with a random fuzz factor.
---See: "Anki also applies a small amount of random "fuzz" to prevent cards that
---  were introduced at the same time and given the same ratings from sticking
---  together and always coming up for review on the same day."
---@param interval integer The interval in days.
---@param fuzz? integer The fuzz factor. Default is 3.
---@return integer new_interval The new adjusted interval.
function BaseAlg:random_adjust_interval(interval, fuzz)
  fuzz = fuzz or 3

  if interval >= 8 then
    local choices = { -fuzz, 0, fuzz }
    local random_index = math.random(#choices)
    interval = interval + choices[random_index]
  end

  return interval
end

--------------------

return BaseAlg
