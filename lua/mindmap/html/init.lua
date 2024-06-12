local parsers = require("nvim-treesitter.parsers")

parsers.get_parser_configs().html = {
	install_info = {
		url = "https://github.com/tree-sitter/tree-sitter-html",
		files = { "src/parser.c" },
		branch = "main",
	},
	filetype = "html",
	used_by = { "html" },
	queries = {
		highlights = {
			os.getenv("HOME") .. "/html.scm",
		},
	},
}

print("html parser installed")
