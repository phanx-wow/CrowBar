local _, private = ...

private.openSpells =  {
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

private.openItems = {
	-- Bugged items that don't show any "click to open" text:
	[ 89125] = true, -- Sack of Pet Supplies
	[ 93146] = true, -- Pandaren Spirit Pet Supplies (Burning)
	[ 93147] = true, -- Pandaren Spirit Pet Supplies (Flowing)
	[ 93148] = true, -- Pandaren Spirit Pet Supplies (Whispering)
	[ 93149] = true, -- Pandaren Spirit Pet Supplies (Thundering)
	[ 94207] = true, -- Fabled Pandaren Pet Supplies
	[ 98095] = true, -- Brawler's Pet Supplies
	-- Unique items: more efficient to check the itemID than scan for spell text.
	[ 69838] = true, -- Chirping Box
	[ 78890] = true, -- Crystalline Geode
	[ 78891] = true, -- Elementium-Coated Geode
	[ 90816] = true, -- Relic of the Thunder King
	[ 90815] = true, -- Relic of Guo-Lai
	[ 90816] = true, -- Relic of the Thunder King
	[ 94223] = true, -- Stolen Shado-Pan Insignia
	[ 94225] = true, -- Stolen Celestial Insignia
	[ 94226] = true, -- Stolen Klaxxi Insignia
	[ 94227] = true, -- Stolen Golden Lotus Insignia
	[ 95487] = true, -- Sunreaver Offensive Insignia
	[ 95488] = true, -- Greater Sunreaver Offensive Insignia
	[ 95489] = true, -- Kirin Tor Offensive Insignia
	[ 95490] = true, -- Greater Kirin Tor Offensive Insignia
	[ 95496] = true, -- Shado-Pan Assault Insignia
	[ 97268] = true, -- Tome of Valor
	[ 98134] = true, -- Heroic Cache of Treasures
	[ 98546] = true, -- Bulging Heroic Cache of Treasures
	[114116] = true, -- Bag of Salvaged Goods
	[114119] = true, -- Crate of Salvage
	[114120] = true, -- Big Crate of Salvage
	[117492] = true, -- Relic of Rukhmar
	[118697] = true, -- Big Bag of Pet Supplies
	[120301] = true, -- Armor Enhancement Token
	[120302] = true, -- Weapon Enhancement Token
	[122535] = true, -- Traveler's Pet Supplies
	[127751] = true, -- Fel-Touched Pet Supplies
	[136938] = true, -- Tome of Hex: Compy
}

private.combineItems = {
	-- Seasonal
	[49655]  = 10, -- Lovely Charm
	-- Herbalism
	[ 89112] = 10, -- Mote of Harmony
	[109624] = 10, -- Broken Frostweed Stem
	-- Leatherworking
	[  2934] =  3, -- Ruined Leather Scraps
	[ 25649] =  5, -- Knothide Leather Scraps
	[ 33567] =  5, -- Borean Leather Scraps
	[ 74493] =  5, -- Savage Leather
	[159069] = 10, -- Raw Beast Hide Scraps
	-- Mining
	[109991] = 10, -- True Iron Nugget
	[109992] = 10, -- Blackrock Fragment
	[115504] = 10, -- Fractured Temporal Crystal
	-- Fishing
	--[[ ignore: they occupy less bag space in raw form
	[111589] = 5, [111595] = 5, [111601] = 5, -- Crescent Saberfish
	[111659] = 5, [111664] = 5, [111671] = 5, -- Abyssal Gulper Eel
	[111652] = 5, [111667] = 5, [111674] = 5, -- Blind Lake Sturgeon
	[111662] = 5, [111663] = 5, [111670] = 5, -- Blackwater Whiptail
	[111658] = 5, [111665] = 5, [111672] = 5, -- Sea Scorpion
	[111651] = 5, [111668] = 5, [111675] = 5, -- Fat Sleeper
	[111656] = 5, [111666] = 5, [111673] = 5, -- Fire Ammonite
	[111650] = 5, [111669] = 5, [111676] = 5, -- Jawless Skulker
	]]
}

private.ignoreQuestItems = {
	[74034] = true, -- Pit Fighter
}
