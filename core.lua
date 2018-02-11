--[[--------------------------------------------------------------------
	This is a heavily modified version of Ammo's CrowBar addon.
----------------------------------------------------------------------]]

local CROWBAR, private = ...

local L = setmetatable({}, { __index = function(t, k)
	local v = tostring(k)
	t[k] = v
	return v
end })

if GetLocale() == "deDE" then
	L["<Alt-Click and drag to move>"] = "<ALT-Klick und ziehen, um zu bewegen>"
	L["<Ctrl-Click to ignore this item>"] = "<STRG-Klick, um diesen Gegenstand zu ignorieren>"
	L["<Shift-Ctrl-Click to ignore forever>"] = "<Umschalt-STRG-Klick, um er dauerhaft ignorieren>"
	L["Now ignoring %s for the rest of this session."] = "%s wird für den Rest dieser Sitzung ignoriert."
	L["Now permanently ignoring %s."] = "%s wird ab jetzt ignoriert."
elseif GetLocale():match("^es") then
	L["<Alt-Click and drag to move>"] = "<Alt-clic y arrastre para mover>"
	L["<Ctrl-Click to ignore this item>"] = "<Ctrl-clic para ignorar este objetivo>"
	L["<Shift-Ctrl-Click to ignore forever>"] = "<Mayús-Ctrl-clic para ignorarlo permanentemente>"
	L["Now ignoring %s for the rest of this session."] = "%s será ignorardo por el resto de la sesión."
	L["Now permanently ignoring %s."] = "%s será ignorardo permanentemente."
end

local DELAYTIME = 0.25
local button, tooltip, tooltipLines
local opening = GetSpellInfo(6247)
local openStrings = {
	[ITEM_OPENABLE] = true,
	[ITEM_TOY_ONUSE] = true,
}

local openSpells = private.openSpells
local openItems = private.openItems
local combineItems = private.combineItems
local ignoreQuestItems = private.ignoreQuestItems

------------------------------------------------------------------------

local CrowBar = CreateFrame("Frame", "CrowBar")
CrowBar:SetScript("OnEvent", function(self, event, ...) return self[event] and self[event](self, event, ...) or self:CheckSpellCast(event, ...) end)
CrowBar:RegisterEvent("ADDON_LOADED")
CrowBar:Hide()

local debug = function(str, ...)
	if str:find("%%") then
		DEFAULT_CHAT_FRAME:AddMessage("|cffefa300[CrowBar]|r " .. str:format(...))
	else
		DEFAULT_CHAT_FRAME:AddMessage("|cffefa300[CrowBar]|r " .. string.join(" ", str, tostringall(...)))
	end
end

------------------------------------------------------------------------

function CrowBar:ADDON_LOADED(event, addon)
	if addon ~= CROWBAR then return end

	CrowBarDB = CrowBarDB or {}
	CrowBarDB.ignore = CrowBarDB.ignore or {}

	for id in pairs(CrowBarDB.ignore) do
		ignoreQuestItems[id] = true
	end

	self:UnregisterEvent("ADDON_LOADED")
	if IsLoggedIn() then
		self:PLAYER_LOGIN()
	else
		self:RegisterEvent("PLAYER_LOGIN")
	end
end

function CrowBar:PLAYER_LOGIN(event)
	button = CreateFrame("Button", "CrowBarButton", UIParent, "SecureActionButtonTemplate, ActionButtonTemplate")
	self.button = button

	tooltip = CreateFrame("GameTooltip", "CrowBarScanTip", UIParent, "GameTooltipTemplate")
	self.tooltip = tooltip

	tooltipLines = setmetatable({}, { __index = function(t, i)
		local v = _G["CrowBarScanTipTextLeft"..i]
		t[i] = v
		return v
	end })

	button:Hide()
	button:SetSize(48, 48)
	button:EnableMouse(true)
	button:RegisterForDrag("LeftButton")
	button:RegisterForClicks("AnyUp")
	button:SetMovable(true)

	button.icon = CrowBarButtonIcon
	button.icon:SetTexture("Interface\\Icons\\INV_Box_02")

	if LibStub("Masque", true) then
		LibStub("Masque"):Group(CROWBAR):AddButton(button)
	elseif PhanxBorder then
		button.icon:SetTexture(0.04, 0.96, 0.04, 0.96)
		button:GetNormalTexture():SetTexture(nil)
		PhanxBorder.AddBorder(button)
	end

	button.count = button:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
	button.count:SetPoint("BOTTOMLEFT")

	button:SetScript("OnDragStart", function(self)
		if not InCombatLockdown() and IsAltKeyDown() then
			self:StartMoving()
		end
	end)
	button:SetScript("OnDragStop", function(self)
		if not InCombatLockdown() then
			self:StopMovingOrSizing()
			CrowBar:SavePosition()
		end
	end)

	button:SetScript("OnEnter", function(self)
		if self.bag and self.slot then
			GameTooltip:SetOwner(self, "ANCHOR_NONE")
			GameTooltip:ClearAllPoints()
			local x = self:GetRight()
			if x >= (GetScreenWidth() / 2) then
				GameTooltip:SetPoint("TOPRIGHT", self, "TOPLEFT", -6, -2)
			else
				GameTooltip:SetPoint("TOPLEFT", self, "TOPRIGHT", 6, 2)
			end
			GameTooltip:SetBagItem(self.bag, self.slot)
			GameTooltip:AddLine(L["<Alt-Click and drag to move>"])
			GameTooltip:AddLine(L["<Ctrl-Click to ignore this item>"])
			GameTooltip:AddLine(L["<Shift-Ctrl-Click to ignore forever>"])
			GameTooltip:Show()
		end
	end)
	button:SetScript("OnLeave", GameTooltip_Hide)

	button:SetScript("PreClick", function(self)
		if self.bag and self.slot and IsControlKeyDown() then
			local id = GetContainerItemID(self.bag, self.slot)
			ignoreQuestItems[id] = true
			if IsShiftKeyDown() then
				CrowBarDB.ignore[id] = true
				DEFAULT_CHAT_FRAME:AddMessage("|cff00ddbaCrowBar:|r " .. format(L["Now permanently ignoring %s."], GetContainerItemLink(self.bag, self.slot)))
			else
				DEFAULT_CHAT_FRAME:AddMessage("|cff00ddbaCrowBar:|r " .. format(L["Now ignoring %s for the rest of this session."], GetContainerItemLink(self.bag, self.slot)))
			end
			CrowBar:HideButton()
			CrowBar:ScanBags()
		end
	end)

	self:RestorePosition()

	for spellID in next, openSpells do
		local spelltext
		tooltip:SetOwner(UIParent, "ANCHOR_NONE")
		tooltip:SetSpellByID(spellID)
		local lastline = tooltipLines[tooltip:NumLines()]
		if lastline then
			spelltext = lastline:GetText()
		end
		if spelltext then
			openStrings[ITEM_SPELL_TRIGGER_ONUSE.." "..spelltext] = spellID
		end
	end

	self:RegisterEvent("BAG_UPDATE_DELAYED")
	self.BAG_UPDATE_DELAYED = self.Show

	self:RegisterEvent("MINIMAP_UPDATE_TRACKING")
	self.MINIMAP_UPDATE_TRACKING = self.Show

	self:RegisterEvent("QUEST_ACCEPTED")
	self.QUEST_ACCEPTED = self.Show

	self:RegisterEvent("PLAYER_REGEN_DISABLED")
	self:RegisterEvent("PLAYER_REGEN_ENABLED")

	self:RegisterEvent("PET_BATTLE_OPENING_START")
	self.PET_BATTLE_OPENING_START = self.PLAYER_REGEN_DISABLED

	self:RegisterEvent("PET_BATTLE_CLOSE")
	self.PET_BATTLE_CLOSE = self.PLAYER_REGEN_ENABLED

	if not UnitAffectingCombat("player") then
		self:PLAYER_REGEN_ENABLED()
	end
end

CrowBar:SetScript("OnShow", function(self)
	-- debug("OnShow")
	self.countdown = DELAYTIME
end)

CrowBar:SetScript("OnUpdate", function(self, elapsed)
	self.countdown = self.countdown - elapsed
	if self.countdown < 0 then
		self:Hide()
		self:ScanBags()
	end
end)

function CrowBar:PLAYER_REGEN_DISABLED(event)
	-- debug("PLAYER_REGEN_DISABLED")
	self:UnregisterEvent("UNIT_SPELLCAST_FAILED")
	self:UnregisterEvent("UNIT_SPELLCAST_INTERRUPTED")
	self:UnregisterEvent("UNIT_SPELLCAST_STOP")
	self:UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED")
	self:HideButton()
end

function CrowBar:PLAYER_REGEN_ENABLED(event)
	-- debug("PLAYER_REGEN_ENABLED")
	self:RegisterUnitEvent("UNIT_SPELLCAST_FAILED", "player")
	self:RegisterUnitEvent("UNIT_SPELLCAST_INTERRUPTED", "player")
	self:RegisterUnitEvent("UNIT_SPELLCAST_STOP", "player")
	self:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
	self:Show()
end

function CrowBar:CheckSpellCast(event, unit, spell)
	if spell == OPENING then
		self:Show()
	end
end

------------------------------------------------------------------------

local ITEM_REQ_CLASS = "^" .. ITEM_CLASSES_ALLOWED:gsub("%%s", ".+")
local ITEM_REQ_LEVEL = "^" .. ITEM_MIN_LEVEL:gsub("%%d", "%d+")
local ITEM_REQ_SKILL = "^" .. ITEM_MIN_SKILL:gsub("%%%d$[sd]", ".+")

local ITEM_COOLDOWN  = " " .. ITEM_COOLDOWN_TOTAL:gsub("%%s", ".+"):gsub("([%(%)])", "%%%1")

local IsOpenable
do
	local CURRENT_BAG, CURRENT_SLOT

	setmetatable(openItems, { __index = function(t, itemID)
		local openable = false
		tooltip:SetOwner(UIParent, "ANCHOR_NONE")
		tooltip:SetBagItem(CURRENT_BAG, CURRENT_SLOT)
		for i = 1, tooltip:NumLines() do
			local text = tooltipLines[i]:GetText()
			text = gsub(text, ITEM_COOLDOWN, "") -- Tome of Valor, le sigh
			if openStrings[text] then
				openable = true
			elseif strmatch(text, ITEM_REQ_CLASS) or strmatch(text, ITEM_REQ_LEVEL) then
				local r, g, b = tooltipLines[i]:GetTextColor()
				if r > 0.95 and g < 0.15 and b < 0.15 then
					-- some requirement not met, don't show
					openable = false
					break
				end
			end
		end

		t[itemID] = openable
		return openable
	end })

	function IsOpenable(itemID, bag, slot)
		CURRENT_BAG, CURRENT_SLOT = bag, slot
		return openItems[itemID]
	end

	CrowBar.IsOpenable = IsOpenable
	CrowBar.openableItems = openItems
end

local function ShouldAcceptQuest(itemID, bag, slot)
	-- Don't show active quests or invalid items
	local _, questID, isActive = GetContainerItemQuestInfo(bag, slot)
	if not questID then
		ignoreQuestItems[itemID] = true
		return
	end
	if isActive or IsQuestFlaggedCompleted(questID) then
		return
	end
	-- Always show level 1 items since there's no way to check the quest level
	local _, _, _, _, minLevel = GetItemInfo(itemID)
	if not minLevel or minLevel < 2 then -- can be 0 or 1
		return true
	end
	-- Don't show quests the player's level is too low to accept
	local playerLevel = UnitLevel("player")
	if playerLevel < minLevel then
		return
	end
	-- Always show quests of appropriate level
	if playerLevel - minLevel <= GetQuestGreenRange() then
		return true
	end
	-- Show trivial quests only if the player is tracking them
	for i = 1, GetNumTrackingTypes() do
		local name, _, active = GetTrackingInfo(i)
		if active and name == MINIMAP_TRACKING_TRIVIAL_QUESTS then
			return true
		end
	end
	-- Either untracked trivial, or on the low end of green
end

local function retryScanBags()
	CrowBar:ScanBags()
end

function CrowBar:ScanBags()
	if InCombatLockdown() then return end
	-- debug("ScanBags")
	for bag = 0, 4 do
		for slot = 1, GetContainerNumSlots(bag) do
			local itemID = GetContainerItemID(bag, slot)
			if itemID and not ignoreQuestItems[itemID] then
				local name = GetItemInfo(itemID)
				if not name or name == "" then
					-- debug("Item info not yet available")
					C_Timer.After(5, retryScanBags)
					return self:HideButton()
				end
				local have, need = GetItemCount(itemID), combineItems[itemID]
				if need and have >= need then
					-- debug("%s %d/%d", name, need, have)
					return self:SetButton(bag, slot, floor(have / need))
				elseif not need and (IsOpenable(itemID, bag, slot) or ShouldAcceptQuest(itemID, bag, slot)) then
					return self:SetButton(bag, slot)
				end
			end
		end
	end
	self:HideButton()
end

------------------------------------------------------------------------

function CrowBar:SetButton(bag, slot, displayCount)
	if InCombatLockdown() then return end
	-- debug("SetButton", bag, slot, GetContainerItemLink(bag, slot))
	button.bag, button.slot = bag, slot

	local icon, _, _, _, _, _, link = GetContainerItemInfo(bag, slot)
	button.icon:SetTexture(icon or "Interface\\Icons\\INV_Box_02")

	local count = displayCount or GetItemCount(link)
	button.count:SetText(count > 1 and count or "")

	button:SetAttribute("type", "macro")
	button:SetAttribute("macrotext", format("/stopmacro [mod:ctrl]\n/run ClearCursor() if MerchantFrame:IsShown() then HideUIPanel(MerchantFrame) end\n/use %d %d", bag, slot))
	button:Show()

	if button:IsMouseOver() then
		button:GetScript("OnLeave")(button)
		button:GetScript("OnEnter")(button)
	end
end

function CrowBar:HideButton()
	if InCombatLockdown() then return end
	-- debug("HideButton")
	button.bag, button.slot = nil, nil
	button.icon:SetTexture("Interface\\Icons\\INV_Box_02")
	button:SetAttribute("type", nil)
	button:SetAttribute("macrotext", nil)
	button:Hide()
end

function CrowBar:SavePosition()
	local s = button:GetEffectiveScale()
	CrowBarDB.posx = button:GetLeft() * s
	CrowBarDB.posy = button:GetTop() * s
end

function CrowBar:RestorePosition()
	button:ClearAllPoints()

	local x = CrowBarDB.posx
	local y = CrowBarDB.posy
	if not x or not y then
		return button:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
	end

	local s = button:GetEffectiveScale()
	button:ClearAllPoints()
	button:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x / s, y / s)
end
