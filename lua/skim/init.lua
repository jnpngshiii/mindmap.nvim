local function viewer_check()
	-- 使用 osascript 执行 AppleScript，检查 Skim 应用是否安装
	local handle = io.popen("osascript -l JavaScript -e 'Application(\"Skim\").id()'")
	if not handle then
		return false
	end

	local result = handle:read("*a")
	handle:close()
	if not result:match("net.sourceforge.skim%-app.skim") then
		return false
	end

	return true
end

print(viewer_check())
