--!strict
-- The Season 1 baby roster — the collectible "Fortune Beasts". Mirrors the
-- official roster sheet: 36 babies in 6 categories (Finance, Office, Study, Mood,
-- Adventure, Sports), each a fruit-themed squishy character with a rarity, a squad
-- role and a base passive income (coins per second when raised).
--
-- baseIncome is BEFORE the rarity multiplier (see Rarity.incomeMultiplier).
-- Final passive income = baseIncome * rarity.incomeMultiplier (see BabyService).
--
-- color/accent drive the procedural placeholder. Add `image` (and optionally
-- meshId/textureId) per baby to make it look like the real artwork — see
-- ART_GUIDE.md. Each baby's `id` is also the suggested art filename, e.g.
-- goldberry.png.

local Rarity = require(script.Parent.Rarity)
local Roles = require(script.Parent.Roles)

export type BabyDef = {
	id: string,
	name: string,
	fruit: string,
	category: string, -- Finance / Office / Study / Mood / Adventure / Sports
	rarity: Rarity.RarityId,
	role: Roles.RoleId,
	baseIncome: number, -- coins/sec before rarity multiplier
	squishiness: number, -- 0..1 how bouncy the squish animation is
	color: Color3, -- body / outfit colour
	accent: Color3, -- fruit-hat colour
	blurb: string,
	-- Optional real-art hooks (Roblox asset IDs); used automatically when set.
	image: string?,
	meshId: string?,
	textureId: string?,
}

local function C(r: number, g: number, b: number): Color3
	return Color3.fromRGB(r, g, b)
end

local BabyData = {}

-- Ordered roster (index here == collection-board order, 1..N).
BabyData.List = {
	--========================= FINANCE (Income) =========================--
	{ id = "goldberry", name = "Goldberry", fruit = "Strawberry", category = "Finance", rarity = "Legendary", role = "Income", baseIncome = 14, squishiness = 0.6, color = C(225, 60, 60), accent = C(245, 200, 70), blurb = "Master of wealth — counts every coin twice." },
	{ id = "mandarin", name = "Mandarin", fruit = "Orange", category = "Finance", rarity = "Rare", role = "Income", baseIncome = 9, squishiness = 0.6, color = C(245, 160, 60), accent = C(120, 90, 60), blurb = "Old-school accountant with a trusty abacus." },
	{ id = "peachy", name = "Peachy", fruit = "Peach", category = "Finance", rarity = "Uncommon", role = "Income", baseIncome = 8, squishiness = 0.85, color = C(255, 195, 180), accent = C(245, 165, 140), blurb = "Crunches numbers on a pink calculator." },
	{ id = "lemonade", name = "Lemonade", fruit = "Lemon", category = "Finance", rarity = "Rare", role = "Income", baseIncome = 9, squishiness = 0.7, color = C(245, 215, 80), accent = C(230, 195, 60), blurb = "Turns sour markets into sweet profit." },
	{ id = "avocash", name = "Avocash", fruit = "Avocado", category = "Finance", rarity = "Epic", role = "Income", baseIncome = 12, squishiness = 0.65, color = C(120, 150, 70), accent = C(90, 70, 50), blurb = "Rich, creamy, and always cashing in." },
	{ id = "bluecoin", name = "Bluecoin", fruit = "Blueberry", category = "Finance", rarity = "Rare", role = "Income", baseIncome = 9, squishiness = 0.7, color = C(90, 140, 230), accent = C(60, 100, 200), blurb = "A pocket full of coins, ready to multiply." },

	--========================= OFFICE (Support) =========================--
	{ id = "bossberry", name = "Bossberry", fruit = "Strawberry", category = "Office", rarity = "Epic", role = "Support", baseIncome = 7, squishiness = 0.5, color = C(220, 55, 55), accent = C(40, 40, 40), blurb = "The #1 boss — keeps the whole caravan in line." },
	{ id = "apple_hr", name = "Apple HR", fruit = "Apple", category = "Office", rarity = "Uncommon", role = "Support", baseIncome = 5, squishiness = 0.7, color = C(220, 70, 70), accent = C(120, 170, 70), blurb = "Keeps morale up; lowers squad betrayal chance." },
	{ id = "papaya_planner", name = "Papaya Planner", fruit = "Papaya", category = "Office", rarity = "Rare", role = "Support", baseIncome = 6, squishiness = 0.6, color = C(245, 150, 90), accent = C(220, 120, 70), blurb = "Plans the perfect heist and the fair split." },
	{ id = "kiwi_analyst", name = "Kiwi Analyst", fruit = "Kiwi", category = "Office", rarity = "Rare", role = "Support", baseIncome = 6, squishiness = 0.5, color = C(120, 170, 70), accent = C(90, 140, 50), blurb = "Reads the room and the spreadsheets." },
	{ id = "grape_clerk", name = "Grape Clerk", fruit = "Grape", category = "Office", rarity = "Uncommon", role = "Support", baseIncome = 5, squishiness = 0.6, color = C(125, 85, 170), accent = C(95, 60, 140), blurb = "Files the paperwork and keeps deals fair." },
	{ id = "dragonfruit_dev", name = "Dragonfruit Dev", fruit = "Dragonfruit", category = "Office", rarity = "Epic", role = "Support", baseIncome = 7, squishiness = 0.55, color = C(235, 70, 130), accent = C(120, 200, 90), blurb = "Optimizes the caravan's routes in code." },

	--========================= STUDY (Trust) =========================--
	{ id = "smarty_strawberry", name = "Smarty Strawberry", fruit = "Strawberry", category = "Study", rarity = "Uncommon", role = "Trust", baseIncome = 5, squishiness = 0.6, color = C(225, 60, 60), accent = C(40, 40, 40), blurb = "Top of the class, trusts the data." },
	{ id = "berry_scholar", name = "Berry Scholar", fruit = "Blueberry", category = "Study", rarity = "Rare", role = "Trust", baseIncome = 6, squishiness = 0.5, color = C(90, 140, 230), accent = C(60, 100, 200), blurb = "Knows every trick in the book." },
	{ id = "peach_tutor", name = "Peach Tutor", fruit = "Peach", category = "Study", rarity = "Uncommon", role = "Trust", baseIncome = 5, squishiness = 0.8, color = C(255, 195, 180), accent = C(245, 165, 140), blurb = "Patient pointer-wielding mentor." },
	{ id = "melon_bookworm", name = "Melon Bookworm", fruit = "Watermelon", category = "Study", rarity = "Rare", role = "Trust", baseIncome = 6, squishiness = 0.6, color = C(90, 170, 90), accent = C(60, 140, 70), blurb = "Buried in books, sharp as a tack." },
	{ id = "pineapple_prof", name = "Pineapple Prof", fruit = "Pineapple", category = "Study", rarity = "Epic", role = "Trust", baseIncome = 7, squishiness = 0.5, color = C(245, 205, 70), accent = C(120, 160, 60), blurb = "Graduated top of Caravan University." },
	{ id = "coconut_sage", name = "Coconut Sage", fruit = "Coconut", category = "Study", rarity = "Uncommon", role = "Trust", baseIncome = 5, squishiness = 0.45, color = C(150, 110, 80), accent = C(120, 85, 60), blurb = "Ancient wisdom for the caravan crew." },

	--========================= MOOD (Support) =========================--
	{ id = "cherry_cheerer", name = "Cherry Cheerer", fruit = "Cherry", category = "Mood", rarity = "Uncommon", role = "Support", baseIncome = 5, squishiness = 0.95, color = C(230, 70, 90), accent = C(200, 50, 70), blurb = "Cheers the caravan onward, boosting morale." },
	{ id = "sunshine", name = "Sunshine", fruit = "Lemon", category = "Mood", rarity = "Common", role = "Support", baseIncome = 4, squishiness = 0.85, color = C(245, 215, 80), accent = C(245, 180, 60), blurb = "Sunny vibes keep spirits high." },
	{ id = "chillberry", name = "Chillberry", fruit = "Blueberry", category = "Mood", rarity = "Common", role = "Support", baseIncome = 4, squishiness = 0.85, color = C(150, 195, 235), accent = C(110, 160, 215), blurb = "Stays cool under raid pressure." },
	{ id = "zen_kiwi", name = "Zen Kiwi", fruit = "Watermelon", category = "Mood", rarity = "Uncommon", role = "Support", baseIncome = 5, squishiness = 0.7, color = C(110, 175, 95), accent = C(80, 145, 70), blurb = "Calm, centered, unbothered by chaos." },
	{ id = "pumpkin_punk", name = "Pumpkin Punk", fruit = "Pumpkin", category = "Mood", rarity = "Rare", role = "Support", baseIncome = 6, squishiness = 0.6, color = C(240, 140, 50), accent = C(60, 60, 60), blurb = "Loud riffs that hype the whole squad." },
	{ id = "starfruit_dj", name = "Starfruit DJ", fruit = "Starfruit", category = "Mood", rarity = "Legendary", role = "Support", baseIncome = 9, squishiness = 0.8, color = C(245, 215, 70), accent = C(120, 90, 200), blurb = "Drops beats that buff the whole squad." },

	--========================= ADVENTURE (Raid) =========================--
	{ id = "explorer_orange", name = "Explorer Orange", fruit = "Orange", category = "Adventure", rarity = "Rare", role = "Raid", baseIncome = 6, squishiness = 0.6, color = C(245, 160, 60), accent = C(220, 130, 40), blurb = "Maps the route, leads the charge." },
	{ id = "jungleberry", name = "Jungleberry", fruit = "Grape", category = "Adventure", rarity = "Uncommon", role = "Raid", baseIncome = 5, squishiness = 0.6, color = C(120, 80, 150), accent = C(90, 140, 70), blurb = "At home in the wild, fearless on raids." },
	{ id = "pitaya_scout", name = "Pitaya Scout", fruit = "Dragonfruit", category = "Adventure", rarity = "Rare", role = "Raid", baseIncome = 6, squishiness = 0.6, color = C(235, 70, 130), accent = C(120, 200, 90), blurb = "Spots the loot before anyone else." },
	{ id = "melon_knight", name = "Melon Knight", fruit = "Watermelon", category = "Adventure", rarity = "Epic", role = "Raid", baseIncome = 7, squishiness = 0.5, color = C(90, 175, 90), accent = C(200, 80, 80), blurb = "Sword and shield — storms rival vaults." },
	{ id = "coco_raider", name = "Coco Raider", fruit = "Coconut", category = "Adventure", rarity = "Rare", role = "Raid", baseIncome = 6, squishiness = 0.45, color = C(150, 110, 80), accent = C(90, 65, 45), blurb = "Eyepatch, cutlass, no fear." },
	{ id = "mango_ranger", name = "Mango Ranger", fruit = "Mango", category = "Adventure", rarity = "Rare", role = "Raid", baseIncome = 6, squishiness = 0.6, color = C(245, 175, 60), accent = C(225, 110, 50), blurb = "Escorts caravans through the wilds." },

	--========================= SPORTS (Raid) =========================--
	{ id = "strawberry_striker", name = "Strawberry Striker", fruit = "Strawberry", category = "Sports", rarity = "Rare", role = "Raid", baseIncome = 6, squishiness = 0.7, color = C(225, 60, 60), accent = C(120, 170, 70), blurb = "Kicks down doors to steal the loot." },
	{ id = "peach_tennis_ace", name = "Peach Tennis Ace", fruit = "Peach", category = "Sports", rarity = "Rare", role = "Raid", baseIncome = 6, squishiness = 0.7, color = C(255, 195, 180), accent = C(245, 165, 140), blurb = "Serves an unreturnable raid." },
	{ id = "apple_golfer", name = "Apple Golfer", fruit = "Green Apple", category = "Sports", rarity = "Uncommon", role = "Raid", baseIncome = 5, squishiness = 0.7, color = C(150, 200, 90), accent = C(110, 170, 60), blurb = "A precise swing, every time." },
	{ id = "dragonfruit_brawler", name = "Dragonfruit Brawler", fruit = "Dragonfruit", category = "Sports", rarity = "Epic", role = "Raid", baseIncome = 8, squishiness = 0.55, color = C(235, 70, 130), accent = C(120, 200, 90), blurb = "A martial-arts master — feared on every raid." },
	{ id = "pineapple_slammer", name = "Pineapple Slammer", fruit = "Pineapple", category = "Sports", rarity = "Rare", role = "Raid", baseIncome = 6, squishiness = 0.6, color = C(245, 205, 70), accent = C(120, 160, 60), blurb = "Dunks on the competition." },
	{ id = "blueberry_skater", name = "Blueberry Skater", fruit = "Blueberry", category = "Sports", rarity = "Rare", role = "Raid", baseIncome = 6, squishiness = 0.7, color = C(80, 130, 220), accent = C(55, 95, 185), blurb = "Skates loot home faster than anyone." },
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
