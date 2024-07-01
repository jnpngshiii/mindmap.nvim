local logger = require("mindmap.Logger"):register_source("Graph.Trans")

--------------------
-- Class Transaction
--------------------

---@class Transaction
---@field savepoint any Savepoint of the transaction.
---@field description string Description of the transaction. Default: `""`.
---@field operations function[] Operations in the transaction.
---@field inverses function[] Inverses of the operations in the transaction.
local Transaction = {}
Transaction.__index = Transaction

---Begin a new transaction.
---This method is often called automatically at the start of a "transaction" method.
---See: `Graph:transact`.
---@param savepoint any Savepoint of the transaction.
---@param description? string Description of the transaction.
---@return Transaction transaction The new transaction.
function Transaction:begin(savepoint, description)
  local transaction = {
    savepoint = savepoint,
    description = description or "",
    operations = {},
    inverses = {},
  }
  transaction.__index = transaction
  setmetatable(transaction, Transaction)

  return transaction
end

---Commit the transaction.
---This method is often called automatically at the end of a "transaction" method.
---See: `Graph:transact`.
---@return boolean is_committed Whether the transaction is successfully committed.
function Transaction:commit()
  local success = true

  for i = 1, #self.operations do
    local ok, _ = pcall(self.operations[i])
    if not ok then
      success = false
      break
    end
  end

  return success
end

---@deprecated Needs update.
---Rollback the transaction.
---This method is often called automatically at the end of a "transaction" method when `Transaction:commit` failed.
---See: `Graph:transact`.
---@return boolean is_rolled_back Whether the transaction is successfully rolled back.
function Transaction:rollback()
  local success = true

  for i = #self.operations, 1, -1 do
    local ok, _ = pcall(self.inverses[i])
    if not ok then
      success = false
      break
    end
  end

  return success
end

---Record an operation and its inverse.
---This method is often called automatically at the end of an "operation" method.
---The recorded operation is not executed immediately.
---To execute it, use the `Transaction:commit` method.
---See: `Graph:add_node`, `Graph:add_edge`, `Graph:remove_node`, `Graph:remove_edge`.
---@param operation function The operation.
---@param inverse function The inverse of the operation.
---@return nil
function Transaction:record(operation, inverse)
  table.insert(self.operations, operation)
  table.insert(self.inverses, inverse)
end

--------------------

return Transaction
