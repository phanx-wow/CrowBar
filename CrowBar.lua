--[[--------------------------------------------------------------------
	This is a heavily modified version of Ammo's CrowBar addon.
----------------------------------------------------------------------]]

local CROWBAR = ...

local L = setmetatable({}, { __index = function(t, k)
	local v = tostring(k)
	t[k] = v
	return v
end })

if GetLocale() == "deDE" then
	L["<Ctrl-Click to ignore this item>"] = "<STRG-Klick, um diesen Gegenstand zu ignorieren>"
	L["<Alt-Click and drag to move>"] = "<ALT-Klick und ziehen, um zu bewegen>"
	L["Now ignoring %s for the rest of this session."] = "%s wird für den Rest dieser Sitzung ignoriert."
elseif GetLocale():match("^es") then
	L["<Ctrl-Click to ignore this item>"] = "<Ctrl-clic para ignorar este objetivo>"
	L["<Alt-Click and drag to move>"] = "<Alt-clic y arrastre para mover>"
	L["Now ignoring %s for the rest of this session."] = "%s será ignorardo por el resto de la sesión."
end

local DELAYTIME = 0.25
local button, tooltip, tooltipLines
local opening = GetSpellInfo(6247)
local openStrings = {
	[ITEM_OPENABLE] = true,
}

local openSpells = {
	[58168]  = true, -- Thick Shell Clam
	[58172]  = true, -- Small Barnacled Clam
	[102923] = true, -- Heavy Junkbox
	[109948] = true, -- Perfect Geode
	[126935] = true, -- Crate Restored Artifact
	[131935] = true, -- Valor Points +10
	[131936] = true, -- Valor Points +5
	[136267] = true, -- Honor Points +250
	[162367] = true, -- "Gain 25 Garrison Resources."
	[168751] = true, -- "Create a soulbound item appropriate for your loot specialization."
	[170888] = true, -- "Gain 100 Garrison Resources."
	[175836] = true, -- "Gain 50 Garrison Resources."
	[176549] = true, -- "Gain 250 Garrison Resources."
}

local openItems = {
	-- Bugged items that don't show any "click to open" text:
	[89125]  = true, -- Sack of Pet Supplies
	[93146]  = true, -- Pandaren Spirit Pet Supplies (Burning)
	[93147]  = true, -- Pandaren Spirit Pet Supplies (Flowing)
	[93148]  = true, -- Pandaren Spirit Pet Supplies (Whispering)
	[93149]  = true, -- Pandaren Spirit Pet Supplies (Thundering)
	[94207]  = true, -- Fabled Pandaren Pet Supplies
	[98095]  = true, -- Brawler's Pet Supplies
	-- Unique items: more efficient to check the itemID than scan for spell text.
	[69838]  = true, -- Chirping Box
	[78890]  = true, -- Crystalline Geode
	[78891]  = true, -- Elementium-Coated Geode
	[90816]  = true, -- Relic of the Thunder King
	[90815]  = true, -- Relic of Guo-Lai
	[90816]  = true, -- Relic of the Thunder King
	[94223]  = true, -- Stolen Shado-Pan Insignia
	[94225]  = true, -- Stolen Celestial Insignia
	[94226]  = true, -- Stolen Klaxxi Insignia
	[94227]  = true, -- Stolen Golden Lotus Insignia
	[95487]  = true, -- Sunreaver Offensive Insignia
	[95488]  = true, -- Greater Sunreaver Offensive Insignia
	[95489]  = true, -- Kirin Tor Offensive Insignia
	[95490]  = true, -- Greater Kirin Tor Offensive Insignia
	[95496]  = true, -- Shado-Pan Assault Insignia
	[97268]  = true, -- Tome of Valor
	[98134]  = true, -- Heroic Cache of Treasures
	[98546]  = true, -- Bulging Heroic Cache of Treasures
	[114116] = true, -- Bag of Salvaged Goods
	[114119] = true, -- Crate of Salvage
	[114120] = true, -- Big Crate of Salvage
	[117492] = true, -- Relic of Rukhmar
	[120301] = true, -- Armor Enhancement Token
	[120302] = true, -- Weapon Enhancement Token
	[122535] = true, -- Traveler's Pet Supplies
}

local combineItems = {
  [2934]   = 3,  -- Ruined Leather Scraps
  [25649]  = 5,  -- Knothide Leather Scraps
  [33567]  = 5,  -- Borean Leather Scraps
  [74493]  = 5,  -- Savage Leather
  [89112]  = 10, -- Mote of Harmony
  [109991] = 10, -- True Iron Nugget
  [109992] = 10, -- Blackrock Fragment
  [115504] = 10, -- Fractured Temporal Crystal
  [159069] = 10, -- Raw Beast Hide Scraps
  [111589] = 5, [111595] = 5, [111601] = 5, -- Crescent Saberfish
  [111659] = 5, [111664] = 5, [111671] = 5, -- Abyssal Gulper Eel
  [111652] = 5, [111667] = 5, [111674] = 5, -- Blind Lake Sturgeon
  [111662] = 5, [111663] = 5, [111670] = 5, -- Blackwater Whiptail
  [111658] = 5, [111665] = 5, [111672] = 5, -- Sea Scorpion
  [111651] = 5, [111668] = 5, [111675] = 5, -- Fat Sleeper
  [111656] = 5, [111666] = 5, [111673] = 5, -- Fire Ammonite
  [111650] = 5, [111669] = 5, [111676] = 5, -- Jawless Skulker
}

local ignoreQuestItems = {
	[74034] = true, -- Pit Fighter
}

------------------------------------------------------------------------

local CrowBar = CreateFrame("Frame", "CrowBar")
CrowBar:SetScript("OnEvent", function(self, event, ...) return self[event] and self[event](self, event, ...) or self:CheckSpellCast(event, ...) end)
CrowBar:RegisterEvent("ADDON_LOADED")
CrowBar:Hide()

------------------------------------------------------------------------

function CrowBar:ADDON_LOADED(event, addon)
	if addon ~= CROWBAR then return end

	CrowBarDB = CrowBarDB or {}

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
	button:ClearAllPoints()
	button:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
	button:EnableMouse(true)
	button:RegisterForDrag("LeftButton")
	button:RegisterForClicks("AnyUp")
	button:SetMovable(true)

	button.icon = CrowBarButtonIcon
	button.icon:SetTexture("Interface\\Icons\\INV_Box_02")

	if PhanxBorder then
		button.icon:SetTexture(0.04, 0.96, 0.04, 0.96)
		button:GetNormalTexture():SetTexture(nil)
		PhanxBorder.AddBorder(button)
	elseif LibStub("Masque", true) then
		LibStub("Masque"):Group(CROWBAR):AddButton(button)
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
			GameTooltip:AddLine(L["<Ctrl-Click to ignore this item>"])
			GameTooltip:AddLine(L["<Alt-Click and drag to move>"])
			GameTooltip:Show()
		end
	end)
	button:SetScript("OnLeave", GameTooltip_Hide)

	button:SetScript("PreClick", function(self)
		if self.bag and self.slot and IsControlKeyDown() then
			local id = GetContainerItemID(self.bag, self.slot)
			ignoreQuestItems[id] = true
			DEFAULT_CHAT_FRAME:AddMessage("|cff00ddbaCrowBar:|r " .. format(L["Now ignoring %s for the rest of this session."], GetContainerItemLink(self.bag, self.slot)))
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
	self.PLAYER_REGEN_DISABLED = self.OnEnterCombat

	self:RegisterEvent("PLAYER_REGEN_ENABLED")
	self.PLAYER_REGEN_ENABLED = self.OnLeaveCombat

	if not UnitAffectingCombat("player") then
		self:OnLeaveCombat()
	end
end

CrowBar:SetScript("OnShow", function(self)
	--print("CrowBar:OnShow")
	self.countdown = DELAYTIME
end)

CrowBar:SetScript("OnUpdate", function(self, elapsed)
	self.countdown = self.countdown - elapsed
	if self.countdown < 0 then
		self:Hide()
		self:ScanBags()
	end
end)

function CrowBar:OnEnterCombat(event)
	--print("CrowBar:OnEnterCombat")
	self:UnregisterEvent("UNIT_SPELLCAST_FAILED")
	self:UnregisterEvent("UNIT_SPELLCAST_INTERRUPTED")
	self:UnregisterEvent("UNIT_SPELLCAST_STOP")
	self:UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED")
	self:HideButton()
end

function CrowBar:OnLeaveCombat(event)
	--print("CrowBar:OnLeaveCombat")
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

local function IsOpenable(itemID, bag, slot)
	CURRENT_BAG, CURRENT_SLOT = bag, slot
	return openItems[itemID]
end
CrowBar.IsOpenable = IsOpenable

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

function CrowBar:ScanBags()
	if InCombatLockdown() then return end
	--print("CrowBar:ScanBags")
	for bag = 0, 4 do
		for slot = 1, GetContainerNumSlots(bag) do
			local itemID = GetContainerItemID(bag, slot)
			if itemID and not ignoreQuestItems[itemID] and (IsOpenable(itemID, bag, slot) or ShouldAcceptQuest(itemID, bag, slot)) then
				return self:SetButton(bag, slot)
			end
		end
	end
	self:HideButton()
end

------------------------------------------------------------------------

function CrowBar:SetButton(bag, slot)
	if InCombatLockdown() then return end
	--print("CrowBar:SetButton", bag, slot, GetContainerItemLink(bag, slot))
	button.bag, button.slot = bag, slot

	local icon, _, _, _, _, _, link = GetContainerItemInfo(bag, slot)
	button.icon:SetTexture(icon or "Interface\\Icons\\INV_Box_02")

	local count = GetItemCount(link)
	button.count:SetText(count > 1 and count or "")

	button:SetAttribute("type", "macro")
	button:SetAttribute("macrotext", format("/run ClearCursor() if MerchantFrame:IsShown() then HideUIPanel(MerchantFrame) end\n/use %d %d", bag, slot))
	button:Show()
end

function CrowBar:HideButton()
	if InCombatLockdown() then return end
	--print("CrowBar:HideButton")
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
	local x = CrowBarDB.posx
	local y = CrowBarDB.posy
	if not x or not y then return end

	local s = button:GetEffectiveScale()
	button:ClearAllPoints()
	button:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x / s, y / s)
end
