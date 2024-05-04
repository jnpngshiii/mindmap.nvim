vim.api.nvim_create_user_command("ExcerptSave", function()
	require("excerpt").database:add_using_visual_selection()
end, {})

vim.api.nvim_create_user_command("ExcerptAppend", function()
	require("excerpt").appendSavedVisualSelection()
end, {})

vim.api.nvim_create_user_command("ExcerptGet", function()
	require("excerpt").database:show_lastest()
end, {})
