SLASH_CROWBAR1 = "/crowbar"
SlashCmdList["CROWBAR"] = function(cmd)
	cmd = string.trim(string.lower(cmd or ""))

	local c = NORMAL_FONT_COLOR_CODE
	local r = "|r"
	local p = c .. "CrowBar: "

	if cmd == "reset" then
		if InCombatLockdown() then
			return DEFAULT_CHAT_FRAME:AddMessage(p .. "Button position cannot be reset in combat.")
		end
		CrowBarDB.posx = nil
		CrowBarDB.posy = nil
		CrowBar:RestorePosition()
		DEFAULT_CHAT_FRAME:AddMessage(p .. "Button position reset.")
	return end

	if cmd == "list" then
		local items, ids = {}, {}
		for id in pairs(CrowBarDB.ignore) do
			local name, link = GetItemInfo(id)
			if name and link then
				items[name] = link
				tinsert(items, name)
			else
				tinsert(ids, id)
			end
		end
		table.sort(items)
		table.sort(ids)
		DEFAULT_CHAT_FRAME:AddMessage(p .. "Ignoring " .. (#items + #ids) .. " items:")
		for i = 1, #items do
			DEFAULT_CHAT_FRAME:AddMessage("- " .. items[items[i]])
		end
		for i = 1, #ids do
			DEFAULT_CHAT_FRAME:AddMessage("- item:" .. ids[i])
		end
	return end

	if cmd == "remove all" then
		for id in pairs(CrowBarDB.ignore) do
			CrowBarDB.ignore[id] = nil
		end
		DEFAULT_CHAT_FRAME:AddMessage(p .. "Removed all items from the ignore list.")
	return end

	local id = tonumber(cmd:match("^remove (%d+)$"))
		or tonumber(cmd:match("^remove .*|Hitem:(%d+)"))

	if id and CrowBarDB.ignore[id] then
		CrowBarDB.ignore[id] = nil
		local name, link = GetItemInfo(id)
		if name and link then
			DEFAULT_CHAT_FRAME:AddMessage(p .. "Removed " .. link .. " from the ignore list.")
		else
			DEFAULT_CHAT_FRAME:AddMessage(p .. "Removed item:" .. id .. " from the ignore list.")
		end
	return end

	DEFAULT_CHAT_FRAME:AddMessage(p .. "Available commands:")
	DEFAULT_CHAT_FRAME:AddMessage("- list" .. c .. " - List all permanently ignored items")
	DEFAULT_CHAT_FRAME:AddMessage("- remove all" .. c .. " - Remove all items from the ignore list")
	DEFAULT_CHAT_FRAME:AddMessage("- remove <item link or ID>" .. c .. " - Remove the specified item from the ignore list")
	DEFAULT_CHAT_FRAME:AddMessage("- reset" .. c .. " - Reset the button position")
end
