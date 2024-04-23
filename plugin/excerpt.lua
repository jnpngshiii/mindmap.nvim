vim.api.nvim_create_user_command("ExcerptSave", function()
	require("excerpt").saveVisualSelection()
end, {
	range = "%",
})

vim.api.nvim_create_user_command("ExcerptAppend", function()
	require("excerpt").appendSavedVisualSelection()
end, {})

vim.api.nvim_create_user_command("ExcerptGet", function()
	require("excerpt").processCurrentLine(require("excerpt").processer1)
end, {})
