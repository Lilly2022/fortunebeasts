--!strict
-- The baby roster — the collectible "Fortune Beasts". Pulled from the concept's
-- "Expanded Baby Roster". Each baby is a fruit-themed squishy character with a
-- rarity, a squad role and a base passive income (coins per second when raised).
--
-- baseIncome is BEFORE the rarity multiplier (see Rarity.incomeMultiplier).
-- Final passive income = baseIncome * rarity.incomeMultiplier (see BabyService).
--
-- color/accent drive the procedural placeholder model until real assets exist.

local Rarity = require(script.Parent.Rarity)
local Roles = require(script.Parent.Roles)

export type BabyDef = {
	id: string,
	name: string,
	fruit: string,
	rarity: Rarity.RarityId,
	role: Roles.RoleId,
	baseIncome: number, -- coins/sec before rarity multiplier
	-- 0..1 how squishy/bouncy the squish animation is.
	squishiness: number,
	color: Color3, -- body / outfit colour
	accent: Color3, -- fruit-hat colour
	blurb: string,
}

local function C(r: number, g: number, b: number): Color3
	return Color3.fromRGB(r, g, b)
end

local BabyData = {}

-- Ordered roster (index here == collection-board order, 1..N).
BabyData.List = {
	{ id = "goldberry_banker", name = "Goldberry Banker", fruit = "Strawberry", rarity = "Epic", role = "Income", baseIncome = 12, squishiness = 0.6, color = C(245, 200, 70), accent = C(220, 60, 60), blurb = "Counts every coin twice — earns big while raised." },
	{ id = "peach_comfort", name = "Peach Comfort Baby", fruit = "Peach", rarity = "Uncommon", role = "Support", baseIncome = 5, squishiness = 0.9, color = C(255, 200, 190), accent = C(255, 170, 150), blurb = "Hugs the squad and speeds up income recovery." },
	{ id = "bluecoin", name = "Bluecoin Baby", fruit = "Blueberry", rarity = "Rare", role = "Income", baseIncome = 8, squishiness = 0.7, color = C(90, 140, 230), accent = C(60, 100, 200), blurb = "A pocket full of coins, ready to multiply." },
	{ id = "kiwi_analyst", name = "Kiwi Analyst", fruit = "Kiwi", rarity = "Rare", role = "Trust", baseIncome = 6, squishiness = 0.5, color = C(120, 170, 70), accent = C(90, 140, 50), blurb = "Reads the room and keeps the team honest." },
	{ id = "bossberry", name = "Bossberry", fruit = "Grape", rarity = "Legendary", role = "Raid", baseIncome = 9, squishiness = 0.4, color = C(120, 80, 170), accent = C(90, 50, 140), blurb = "Runs the operation. Leads raids on rival bases." },
	{ id = "apple_hr", name = "Apple HR", fruit = "Apple", rarity = "Uncommon", role = "Support", baseIncome = 5, squishiness = 0.7, color = C(220, 70, 70), accent = C(120, 170, 70), blurb = "Keeps morale up; lowers squad betrayal chance." },
	{ id = "exam_sprint", name = "Exam Sprint Baby", fruit = "Lemon", rarity = "Uncommon", role = "Trust", baseIncome = 5, squishiness = 0.6, color = C(245, 215, 80), accent = C(230, 195, 60), blurb = "Studies hard, trusts harder." },
	{ id = "berry_scholar", name = "Berry Scholar", fruit = "Grape", rarity = "Rare", role = "Trust", baseIncome = 6, squishiness = 0.5, color = C(130, 90, 175), accent = C(100, 60, 145), blurb = "Knows every trick in the book — and the betrayal odds." },
	{ id = "cherry_cheer", name = "Cherry Cheer", fruit = "Cherry", rarity = "Uncommon", role = "Support", baseIncome = 5, squishiness = 0.95, color = C(230, 70, 90), accent = C(200, 50, 70), blurb = "Cheers the caravan onward, boosting morale." },
	{ id = "chillberry", name = "Chillberry", fruit = "Blueberry", rarity = "Common", role = "Support", baseIncome = 4, squishiness = 0.85, color = C(150, 195, 235), accent = C(110, 160, 215), blurb = "Stays cool under raid pressure." },
	{ id = "explorer_orange", name = "Explorer Orange", fruit = "Orange", rarity = "Rare", role = "Caravan", baseIncome = 6, squishiness = 0.6, color = C(245, 160, 60), accent = C(220, 130, 40), blurb = "Maps the safest caravan routes." },
	{ id = "jungleberry", name = "Jungleberry", fruit = "Watermelon", rarity = "Uncommon", role = "Defense", baseIncome = 5, squishiness = 0.6, color = C(90, 170, 90), accent = C(60, 140, 70), blurb = "Guards the vault with a leafy shield." },
	{ id = "strawberry_striker", name = "Strawberry Striker", fruit = "Strawberry", rarity = "Rare", role = "Raid", baseIncome = 6, squishiness = 0.7, color = C(225, 60, 60), accent = C(120, 170, 70), blurb = "Kicks down doors to steal the loot." },
	{ id = "peach_tennis_ace", name = "Peach Tennis Ace", fruit = "Peach", rarity = "Rare", role = "Raid", baseIncome = 6, squishiness = 0.7, color = C(255, 195, 180), accent = C(245, 165, 140), blurb = "Serves an unreturnable raid." },
	{ id = "dragonfruit_brawler", name = "Dragonfruit Brawler", fruit = "Dragonfruit", rarity = "Epic", role = "Raid", baseIncome = 8, squishiness = 0.55, color = C(235, 70, 130), accent = C(120, 200, 90), blurb = "A martial-arts master — feared on every raid." },
	{ id = "blueberry_skater", name = "Blueberry Skater", fruit = "Blueberry", rarity = "Rare", role = "Caravan", baseIncome = 6, squishiness = 0.7, color = C(80, 130, 220), accent = C(55, 95, 185), blurb = "Skates loot home faster than anyone." },
	{ id = "avocash", name = "Avocash", fruit = "Avocado", rarity = "Epic", role = "Income", baseIncome = 11, squishiness = 0.65, color = C(120, 150, 70), accent = C(90, 70, 50), blurb = "Rich, creamy, and always cashing in." },
	{ id = "papaya_planner", name = "Papaya Planner", fruit = "Papaya", rarity = "Rare", role = "Trust", baseIncome = 6, squishiness = 0.6, color = C(245, 150, 90), accent = C(220, 120, 70), blurb = "Plans the perfect heist and the fair split." },
	{ id = "coconut_sage", name = "Coconut Sage", fruit = "Coconut", rarity = "Uncommon", role = "Support", baseIncome = 5, squishiness = 0.45, color = C(150, 110, 80), accent = C(120, 85, 60), blurb = "Ancient wisdom for the caravan crew." },
	{ id = "melon_knight", name = "Melon Knight", fruit = "Melon", rarity = "Epic", role = "Defense", baseIncome = 7, squishiness = 0.5, color = C(90, 175, 90), accent = C(200, 80, 80), blurb = "Sword and shield guard your vault." },
	{ id = "mango_ranger", name = "Mango Ranger", fruit = "Mango", rarity = "Rare", role = "Caravan", baseIncome = 6, squishiness = 0.6, color = C(245, 175, 60), accent = C(225, 110, 50), blurb = "Escorts caravans through the wilds." },
	{ id = "pumpkin_punk", name = "Pumpkin Punk", fruit = "Pumpkin", rarity = "Epic", role = "Raid", baseIncome = 8, squishiness = 0.6, color = C(240, 140, 50), accent = C(60, 60, 60), blurb = "Loud, reckless, and great at raids." },
	{ id = "starfruit_dj", name = "Starfruit DJ", fruit = "Starfruit", rarity = "Legendary", role = "Support", baseIncome = 9, squishiness = 0.8, color = C(245, 215, 70), accent = C(120, 90, 200), blurb = "Drops beats that buff the whole squad." },
	{ id = "grape_clerk", name = "Grape Clerk", fruit = "Grape", rarity = "Uncommon", role = "Trust", baseIncome = 5, squishiness = 0.6, color = C(125, 85, 170), accent = C(95, 60, 140), blurb = "Files the paperwork and keeps deals fair." },
} :: { BabyDef }

-- id -> def lookup, built once.
BabyData.ById = {} :: { [string]: BabyDef }
for _, def in BabyData.List do
	BabyData.ById[def.id] = def
end

function BabyData.get(id: string): BabyDef?
	return BabyData.ById[id]
end

-- Final passive income (coins/sec) for a baby, factoring in rarity.
function BabyData.incomePerSecond(id: string): number
	local def = BabyData.ById[id]
	if not def then
		return 0
	end
	return def.baseIncome * Rarity.Info[def.rarity].incomeMultiplier
end

function BabyData.count(): number
	return #BabyData.List
end

return BabyData
