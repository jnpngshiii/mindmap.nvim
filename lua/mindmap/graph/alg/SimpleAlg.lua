--------------------
-- Class SimpleAlg
--------------------

---@class SimpleAlg : BaseAlg
local SimpleAlg = {}

----------
-- Basic Method
----------

---Answer the card with "easy".
---@param self SimpleAlg The algorithm.
---@param edge BaseEdge The edge.
---@return nil _
---@diagnostic disable-next-line: unused-local
function SimpleAlg.answer_easy(self, edge)
	local new_ease = edge.ease + 20
	-- TODO: 1.3?
	local new_interval = edge.interval * new_ease / 100 * 1.3
	new_interval = self:random_adjust_interval(new_interval)

	---@diagnostic disable-next-line: assign-type-mismatch
	edge.updated_at = tonumber(os.time())
	edge.due_at = tonumber(os.time()) + edge.interval * DAY_SECONDS
	edge.ease = new_ease
	edge.interval = new_interval
	edge.answer_count = edge.answer_count + 1
	edge.ease_count = edge.ease_count + 1
end

---Answer the card with "good".
---@param self SimpleAlg The algorithm.
---@param edge BaseEdge The edge.
---@diagnostic disable-next-line: unused-local
---@return nil _
---@diagnostic disable-next-line: unused-local
function SimpleAlg.answer_good(self, edge)
	local new_ease = edge.ease
	local new_interval = edge.interval * new_ease / 100
	new_interval = self:random_adjust_interval(new_interval)

	---@diagnostic disable-next-line: assign-type-mismatch
	edge.updated_at = tonumber(os.time())
	edge.due_at = tonumber(os.time()) + edge.interval * DAY_SECONDS
	edge.ease = new_ease
	edge.interval = new_interval
	edge.answer_count = edge.answer_count + 1
end

---Answer the card with "again".
---@param self SimpleAlg The algorithm.
---@param edge BaseEdge The edge.
---@diagnostic disable-next-line: unused-local
---@return nil _
---@diagnostic disable-next-line: unused-local
function SimpleAlg.answer_again(self, edge)
	local new_ease = edge.ease - 20
	new_ease = math.max(new_ease, 130)
	-- TODO: 0.5?
	local new_interval = edge.interval * 0.5
	new_interval = self:random_adjust_interval(new_interval)

	---@diagnostic disable-next-line: assign-type-mismatch
	edge.updated_at = tonumber(os.time())
	edge.due_at = tonumber(os.time()) + edge.interval * DAY_SECONDS
	edge.ease = new_ease
	edge.interval = new_interval
	edge.answer_count = edge.answer_count + 1
	edge.again_count = edge.again_count + 1
end

--------------------

return SimpleAlg
