vim.api.nvim_create_user_command("ExcerptSave", function()
	require("excerpt").excerpt_database:add_using_visual_selection()
end, {})

vim.api.nvim_create_user_command("ExcerptAppend", function()
	require("excerpt").save_lastest_excerpts_to_current_file()
end, {})

vim.api.nvim_create_user_command("ExcerptGet", function()
	require("excerpt").excerpt_database:show_lastest()
end, {})
