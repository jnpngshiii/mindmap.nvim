local parsers = require("nvim-treesitter.parsers")

require("nvim-treesitter.configs").setup({
	modules = {},
	sync_install = true,
	ignore_install = {},
	auto_install = true,
	ensure_installed = { "html" },
	highlight = {
		enable = true,
	},
})

print("html parser installed")
