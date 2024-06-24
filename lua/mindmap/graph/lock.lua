--------------------
-- Class Lock
--------------------

---@class Lock
---@field is_locked boolean Whether the lock is locked.
Lock = {}
Lock.__index = Lock

----------
-- Basic Method
----------

---Create a new lock.
---@return Lock _ The lock.
function Lock:new()
	local lock = {
		is_locked = false,
	}
	lock.__index = lock
	setmetatable(lock, Lock)

	return lock
end

---Acquire the lock.
---@return nil _ This method does not return anything.
function Lock:acquire()
	while self.is_locked do
		coroutine.yield()
	end
	self.is_locked = true
end

---Release the lock.
---@return nil _ This method does not return anything.
function Lock:release()
	self.is_locked = false
end

--------------------

return Lock
