local M = {}

--------------------
-- Class Mindnode
--------------------

---@class Mindnode
---@field mindnode_type string Type of the mindnode.
---@field created_at string Time when the mindnode was created.
---@field updated_at string Time when the mindnode was last updated.
---@field due_at string Time when the mindnode is due.
---@field ease number Ease of the mindnode.
---@field interval number Interval of the mindnode.
M.Mindnode = {
	mindnode_type = "",
	created_at = "",
	updated_at = "",
	due_at = "",
	ease = 0,
	interval = 0,
}

----------
-- Instance Method
----------

---@param obj table?
---@return table
function M.Mindnode:new(obj)
	obj = obj or {}
	obj.mindnode_type = obj.mindnode_type or self.mindnode_type
	obj.created_at = obj.created_at or self.created_at
	obj.updated_at = obj.updated_at or self.updated_at
	obj.due_at = obj.due_at or self.due_at
	obj.ease = obj.ease or self.ease
	obj.interval = obj.interval or self.interval

	setmetatable(obj, self)
	self.__index = self

	return obj
end

---Check health of an Mindnode.
---@return boolean
function M.Mindnode:check_health()
	if
		self.mindnode_type == ""
		or self.created_at == ""
		or self.updated_at == ""
		or self.due_at == ""
		or self.ease == 0
		or self.interval == 0
	then
		return false
	else
		return true
	end
end

---Show info of an Mindnode in nvim_out_write.
---@return nil
function M.Mindnode:show_in_nvim_out_write()
	local info = ""
	info = info .. "===== Mindnode Start =====" .. "\n"
	info = info .. "Mindnode type: " .. self.mindnode_type .. "\n"
	info = info .. "Created At: " .. self.created_at .. "\n"
	info = info .. "Updated At: " .. self.updated_at .. "\n"
	info = info .. "Due At: " .. self.due_at .. "\n"
	info = info .. "Ease: " .. self.ease .. "\n"
	info = info .. "Interval: " .. self.interval .. "\n"
	info = info .. "=====  Mindnode End  =====" .. "\n"
	vim.api.nvim_out_write(info)
end

----------
-- Class Method
----------

--------------------

return M
