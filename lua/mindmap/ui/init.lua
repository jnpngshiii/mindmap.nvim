local Popup = require("nui.popup")
local Layout = require("nui.layout")

local ui = {}

ui.init = function()
	local popup_front = Popup({
		enter = true,
		focusable = true,
		border = {
			style = "rounded", -- TODO: ?
			text = {
				top = " Front ",
				top_align = "center",
			},
		},
		buf_options = {
			filetype = "norg", -- TODO:
			readonly = true,
		},
	})

	local popup_back = Popup({
		enter = true,
		focusable = true,
		relative = "editor",
		border = {
			style = "rounded",
			text = {
				top = " Back ",
				top_align = "center",
			},
		},
		buf_options = {
			filetype = "norg", -- TODO:
			readonly = true,
		},
	})

	local layout = Layout(
		{
			position = {
				row = "50%",
				col = "50%",
			},
			size = {
				width = "20%",
				height = "20%",
			},
		},
		Layout.Box({
			Layout.Box(popup_front, { size = "20%" }),
			Layout.Box(popup_back, { size = "80%" }),
		}, { dir = "col" })
	)
	layout:mount()

	return layout, popup_front, popup_back
end

ui.srSync = function()
	LAYOUT:unmount()
end

return ui
