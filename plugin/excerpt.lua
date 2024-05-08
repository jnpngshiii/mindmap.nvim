vim.api.nvim_create_user_command("ExcerptCreateUsingVisualSelection", function()
	require("excerpt").create_excerpt_using_latest_visual_selection()
end, {})

vim.api.nvim_create_user_command("ExcerptShowCurrentLine", function()
	require("excerpt").show_all_excerpts_in_current_line()
end, {})

vim.api.nvim_create_user_command("ExcerptShowAll", function()
	require("excerpt").show_all_excerpts_in_database()
end, {})

vim.api.nvim_create_user_command("ExcerptAppendCurrentLine", function()
	require("excerpt").append_lastest_excerpt_to_current_line()
end, {})

vim.api.nvim_create_user_command("ExcerptShowLog", function()
	require("excerpt").show_log()
end, {})
