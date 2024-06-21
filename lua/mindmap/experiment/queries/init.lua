local current_folder = vim.fn.expand("%:p:h")
vim.cmd("set runtimepath+=" .. current_folder)
