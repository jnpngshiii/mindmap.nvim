local logger = require("logger").register_plugin("mindmap"):register_source("Alg.Simple")

local BaseAlg = require("mindmap.base.BaseAlg")

--------------------
-- Class SimpleAlg
--------------------

---@class SimpleAlg : BaseAlg
local SimpleAlg = {}
SimpleAlg.__index = SimpleAlg
setmetatable(SimpleAlg, BaseAlg)

function SimpleAlg:new(...)
  local ins = BaseAlg:new(...)
  setmetatable(ins, SimpleAlg)

  return ins
end

----------
-- Basic Method
----------

---Answer the card with "easy".
---@param edge BaseEdge The edge being reviewed.
---@return nil
function SimpleAlg:answer_easy(edge)
  local new_ease = edge._ease + 20

  local new_interval = edge._interval * new_ease / 100 * 1.3 -- TODO: 1.3?
  new_interval = self:random_adjust_interval(new_interval)

  ---@diagnostic disable-next-line: assign-type-mismatch
  edge._updated_at = tonumber(os.time())
  edge._due_at = tonumber(os.time()) + edge._interval * DAY_SECONDS
  edge._ease = new_ease
  edge._interval = new_interval
  edge._answer_count = edge._answer_count + 1
  edge._ease_count = edge._ease_count + 1
end

---Answer the card with "good".
---@param edge BaseEdge The edge being reviewed.
---@return nil
function SimpleAlg:answer_good(edge)
  local new_ease = edge._ease

  local new_interval = edge._interval * new_ease / 100
  new_interval = self:random_adjust_interval(new_interval)

  ---@diagnostic disable-next-line: assign-type-mismatch
  edge._updated_at = tonumber(os.time())
  edge._due_at = tonumber(os.time()) + edge._interval * DAY_SECONDS
  edge._ease = new_ease
  edge._interval = new_interval
  edge._answer_count = edge._answer_count + 1
end

---Answer the card with "again".
---@param edge BaseEdge The edge being reviewed.
---@return nil
function SimpleAlg:answer_again(edge)
  local new_ease = edge._ease - 20
  new_ease = math.max(new_ease, 130)

  local new_interval = edge._interval * 0.5 -- TODO: 0.5?
  new_interval = self:random_adjust_interval(new_interval)

  ---@diagnostic disable-next-line: assign-type-mismatch
  edge._updated_at = tonumber(os.time())
  edge._due_at = tonumber(os.time()) + edge._interval * DAY_SECONDS
  edge._ease = new_ease
  edge._interval = new_interval
  edge._answer_count = edge._answer_count + 1
  edge._again_count = edge._again_count + 1
end

--------------------

return SimpleAlg
