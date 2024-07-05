local logger = require("mindmap.plugin_logger"):register_source("Plugin.Init")

local plugin_func = require("mindmap.plugin_func")
local user_func = require("mindmap.user_func")

--------------------

local M = {}

---Set up the plugin.
---@param user_config table User configuration. Used to override the default configuration.
---@return nil
function M.setup(user_config)
  user_config = user_config or {}

  -- Merge user config with default config
  local config = plugin_func.get_config(plugin_func.set_config(user_config))

  -- Set up default keymaps if enabled
  if config.enable_default_keymap then
    M.setup_default_keymaps()
  end

  -- Set up shorten keymaps if enabled
  if config.enable_shorten_keymap then
    M.setup_shorten_keymaps()
  end

  -- Set up default autocommands if enabled
  if config.enable_default_autocmd then
    M.setup_default_autocommands()
  end
end

function M.setup_default_keymaps()
  logger.info("default keymaps enabled")
  local keymap_prefix = plugin_func.get_config().keymap_prefix

  -- MindmapAdd (Node)
  vim.api.nvim_set_keymap(
    "n",
    keymap_prefix .. "an",
    "<cmd>MindmapAddNearestHeadingAsHeadingNode<CR>",
    { noremap = true, silent = true, desc = "Add nearest heading as heading node" }
  )
  vim.api.nvim_set_keymap(
    "n",
    keymap_prefix .. "ae",
    "<cmd>MindmapAddVisualSelectionAsExcerptNode<CR>",
    { noremap = true, silent = true, desc = "Add visual selection as excerpt node" }
  )
  vim.api.nvim_set_keymap(
    "v", -- Visual mode
    "E",
    "<cmd>MindmapAddVisualSelectionAsExcerptNode<CR>",
    { noremap = true, silent = true, desc = "Add visual selection as excerpt node" }
  )

  -- MindmapRemove (Node)
  vim.api.nvim_set_keymap(
    "n",
    keymap_prefix .. "rn",
    "<cmd>MindmapRemove nearest<CR>",
    { noremap = true, silent = true, desc = "Remove nearest node" }
  )
  vim.api.nvim_set_keymap(
    "n",
    keymap_prefix .. "rN",
    "<cmd>MindmapRemove buffer<CR>",
    { noremap = true, silent = true, desc = "Remove buffer node" }
  )

  -- MindmapLink (Edge)
  vim.api.nvim_set_keymap(
    "n",
    keymap_prefix .. "ll",
    "<cmd>MindmapLink latest SimpleEdge nearest<CR>",
    { noremap = true, silent = true, desc = "Add SimpleEdge from latest node to nearest node" }
  )
  vim.api.nvim_set_keymap(
    "n",
    keymap_prefix .. "lc",
    "<cmd>MindmapLink nearest ChildrenEdge nearest<CR>",
    { noremap = true, silent = true, desc = "Add ChildrenEdge form nearest node to nearest node" }
  )
  vim.api.nvim_set_keymap(
    "n",
    keymap_prefix .. "ls",
    "<cmd>MindmapLink nearest SelfLoopEdge nearest<CR>",
    { noremap = true, silent = true, desc = "Add SelfLoopEdge form nearest node to nearest node" }
  )

  -- MindmapUnlink (Edge)

  -- MindmapDisplay
  vim.api.nvim_set_keymap(
    "n",
    keymap_prefix .. "cc",
    "<cmd>MindmapDisplay nearest card_back<CR>",
    { noremap = true, silent = true, desc = "Display nearest card back" }
  )
  vim.api.nvim_set_keymap(
    "n",
    keymap_prefix .. "ce",
    "<cmd>MindmapDisplay nearest excerpt<CR>",
    { noremap = true, silent = true, desc = "Display nearest excerpt" }
  )
  vim.api.nvim_set_keymap(
    "n",
    keymap_prefix .. "cs",
    "<cmd>MindmapDisplay nearest sp_info<CR>",
    { noremap = true, silent = true, desc = "Display nearest spaced repetition info" }
  )

  -- MindmapClean
  vim.api.nvim_set_keymap(
    "n",
    keymap_prefix .. "dc",
    "<cmd>MindmapClean nearest card_back<CR>",
    { noremap = true, silent = true, desc = "Clean nearest card back" }
  )
  vim.api.nvim_set_keymap(
    "n",
    keymap_prefix .. "de",
    "<cmd>MindmapClean nearest excerpt<CR>",
    { noremap = true, silent = true, desc = "Clean nearest excerpt" }
  )
  vim.api.nvim_set_keymap(
    "n",
    keymap_prefix .. "ds",
    "<cmd>MindmapClean nearest sp_info<CR>",
    { noremap = true, silent = true, desc = "Clean nearest spaced repetition info" }
  )

  -- MindmapReview
  vim.api.nvim_set_keymap(
    "n",
    keymap_prefix .. "r",
    "<cmd>MindmapReview buffer<CR>",
    { noremap = true, silent = true, desc = "Review cards in current buffer" }
  )

  -- MindmapUndo/Redo
  vim.api.nvim_set_keymap(
    "n",
    keymap_prefix .. "z",
    "<cmd>MindmapUndo<CR>",
    { noremap = true, silent = true, desc = "Undo last mindmap operation" }
  )
  vim.api.nvim_set_keymap(
    "n",
    keymap_prefix .. "Z",
    "<cmd>MindmapRedo<CR>",
    { noremap = true, silent = true, desc = "Redo last undone mindmap operation" }
  )
end

function M.setup_shorten_keymaps()
  logger.info("shorten keymaps enabled")
  local shorten_prefix = plugin_func.get_config().shorten_keymap_prefix

  -- Remap 'm' to 'M' for marks if 'm' is used as prefix
  if shorten_prefix == "m" then
    vim.api.nvim_set_keymap("n", "M", "m", { noremap = true })
  end

  -- MindmapAdd (Node)
  vim.api.nvim_set_keymap(
    "n",
    shorten_prefix .. "a",
    "<cmd>MindmapAddNearestHeadingAsHeadingNode<CR>",
    { noremap = true, silent = true, desc = "Add nearest heading as node" }
  )

  -- MindmapLink (Edge)
  vim.api.nvim_set_keymap(
    "n",
    shorten_prefix .. "l",
    "<cmd>MindmapLink latest SimpleEdge nearest<CR>",
    { noremap = true, silent = true, desc = "Link latest node to nearest node" }
  )
  vim.api.nvim_set_keymap(
    "n",
    shorten_prefix .. "c",
    "<cmd>MindmapLink nearest ChildrenEdge nearest<CR>",
    { noremap = true, silent = true, desc = "Add ChildrenEdge to nearest node" }
  )
  vim.api.nvim_set_keymap(
    "n",
    shorten_prefix .. "s",
    "<cmd>MindmapLink nearest SelfLoopEdge nearest<CR>",
    { noremap = true, silent = true, desc = "Add SelfLoopEdge to nearest node" }
  )

  -- MindmapDisplay
  vim.api.nvim_set_keymap(
    "n",
    shorten_prefix .. "d",
    "<cmd>MindmapDisplay buffer sp_info<CR>",
    { noremap = true, silent = true, desc = "Display all spaced repetition info in current buffer" }
  )

  -- MindmapReview
  vim.api.nvim_set_keymap(
    "n",
    shorten_prefix .. "r",
    "<cmd>MindmapReview buffer<CR>",
    { noremap = true, silent = true, desc = "Review add cards in current buffer" }
  )
end

function M.setup_default_autocommands()
  logger.info("default autocommands enabled")

  vim.api.nvim_create_autocmd("VimLeave", {
    callback = function()
      user_func.MindmapSave("all")
    end,
    desc = "Save all mindmap graphs on exit",
  })

  local config = plugin_func.get_config()
  if config.show_excerpt_after_add then
    vim.api.nvim_create_autocmd("User", {
      pattern = "MindmapNodeAdded",
      callback = function()
        user_func.MindmapDisplay("latest", "excerpt")
      end,
      desc = "Show excerpt after adding a node",
    })
  end

  if config.show_excerpt_after_bfread then
    vim.api.nvim_create_autocmd("BufRead", {
      pattern = "*.norg",
      callback = function()
        user_func.MindmapDisplay("buffer", "excerpt")
      end,
      desc = "Show excerpts after reading a Neorg buffer",
    })
  end
end

--------------------

return M
