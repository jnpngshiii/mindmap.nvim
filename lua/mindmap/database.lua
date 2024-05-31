local graph_class = require("mindmap.graph.init")
local utils = require("mindmap.utils")

---@alias path string

---@class Database
---@field cache table<path, Graph> Cache of graphs in different repos.
local Database = {}

function Database:new()
	local database = {
		cache = {},
	}

	setmetatable(database, self)
	self.__index = self

	return database
end

---Add a graph to the database.
---@param path? path Path to load and save the graph.
---@param log_level? string Logger log level of the graph.
---@param show_log_in_nvim? boolean Show log in Neovim when added.
---@param save_path? string Path to load and save the graph.
function Database:add_graph(path, log_level, show_log_in_nvim, save_path)
	local graph = graph_class["Graph"]:new(log_level, show_log_in_nvim, save_path)

	self.cache[graph.save_path] = graph
end

---Find a graph in the database using path.
---If not found, add a new graph to the database.
---@param path path Path to load and save the graph.
---@param log_level? string Logger log level of the graph.
---@param show_log_in_nvim? boolean Show log in Neovim when added.
---@param save_path? string Path to load and save the graph.
function Database:find_graph(path, log_level, show_log_in_nvim, save_path)
	if not self.cache[path] then
		self:add_graph(path, log_level, show_log_in_nvim, save_path)
	end

	return self.cache[path]
end

return {
	["Database"] = Database,
}
