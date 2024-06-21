vim.opt.runtimepath:append(vim.fn.expand("%:p:h:h"))

local files = vim.api.nvim_get_runtime_file("queries/norg/highlights.scm", true)

local function load_query(language, filename)
	local file = assert(io.open(filename, "r"), "Failed to open file: " .. filename)
	local contents = file:read("*a")
	file:close()

	vim.treesitter.query.set(language, "highlights", contents)
end

for _, v in pairs(files) do
	-- print(v)

	load_query("norg", v)
end
