vim.api.nvim_create_user_command("ExcerptShow", function()
	require("excerpt").show_all_excerpts_in_database()
end, {})

vim.api.nvim_create_user_command("ExcerptSave", function()
	require("excerpt").save_latest_visual_selection_to_database()
end, {})

vim.api.nvim_create_user_command("ExcerptDatabaseSave", function()
	require("excerpt").save_all_excerpts_in_database()
end, {})
