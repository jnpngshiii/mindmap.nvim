vim.api.nvim_create_user_command("ExcerptSaveVisualSelection", function()
	require("excerpt").save_latest_visual_selection_to_database()
end, {})

vim.api.nvim_create_user_command("ExcerptShowCurrentLine", function()
	require("excerpt").show_all_excerpts_in_current_line()
end, {})

vim.api.nvim_create_user_command("ExcerptShowAll", function()
	require("excerpt").show_all_excerpts_in_database()
end, {})
