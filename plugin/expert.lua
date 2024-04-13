vim.api.nvim_create_user_command("ExpertSave", function()
	require("expert").saveVisualSelection()
end, {
	range = "%",
})

vim.api.nvim_create_user_command("ExpertGet", function()
	require("expert").getSavedVisualSelection()
end, {
	range = "%",
})
