--[[
	BeastConfig
	Two kinds of beasts live here:

	1. THE 5 CLASSICS (BeastConfig.Beasts) - hand-designed, exact stats
	   from the design doc. Starters + market stalls.

	2. THE CATALOG (BeastConfig.Catalog) - 300 generated collectible babies:
	   30 species x 10 numbered variants (like the concept art: 草莓88, 蓝莓33).
	   Each variant gets a deterministic rarity, color shift, accessory and
	   stats from its seed, so every player/server sees the same catalog.
	   Hatched from Mystery Eggs at the market.

	Shared fields per beast:
	- incomePerTick / stealTime / carrySpeedMultiplier: gameplay stats
	- color: hood color; flair: hood shape (ears/stem/horns/...)
	- accessory: extra cosmetic (crown/glasses/suit/...)
	- displayName + cnName: bilingual names like the posters
]]

local BeastConfig = {}

-- weight = hatch chance; income/steal/carry = stat block for generated babies
BeastConfig.Rarities = {
	Common = {
		color = Color3.fromRGB(190, 190, 190),
		weight = 50,
		incomePerTick = 4,
		stealTime = 3.5,
		carrySpeedMultiplier = 0.85,
	},
	Uncommon = {
		color = Color3.fromRGB(120, 200, 120),
		weight = 26,
		incomePerTick = 8,
		stealTime = 3,
		carrySpeedMultiplier = 0.8,
	},
	Rare = {
		color = Color3.fromRGB(90, 160, 255),
		weight = 15,
		incomePerTick = 16,
		stealTime = 2.5,
		carrySpeedMultiplier = 0.72,
	},
	Epic = {
		color = Color3.fromRGB(190, 100, 240),
		weight = 7,
		incomePerTick = 32,
		stealTime = 2,
		carrySpeedMultiplier = 0.65,
	},
	Legendary = {
		color = Color3.fromRGB(255, 150, 40),
		weight = 2,
		incomePerTick = 70,
		stealTime = 1.5,
		carrySpeedMultiplier = 0.55,
	},
}
BeastConfig.RarityOrder = { "Common", "Uncommon", "Rare", "Epic", "Legendary" }

-- ============ THE 5 CLASSICS ============

BeastConfig.Beasts = {
	TaxRat = {
		id = "TaxRat",
		displayName = "Tax Rat",
		cnName = "鼠鼠宝宝",
		rarity = "Common",
		incomePerTick = 5,
		stealTime = 3,
		carrySpeedMultiplier = 0.85,
		color = Color3.fromRGB(130, 130, 135),
		flair = "roundEars",
		role = "Steady beginner income",
	},
	GoldFrog = {
		id = "GoldFrog",
		displayName = "Gold Frog",
		cnName = "金娃宝宝",
		rarity = "Rare",
		incomePerTick = 20,
		stealTime = 2,
		carrySpeedMultiplier = 0.65,
		color = Color3.fromRGB(235, 190, 45),
		flair = "frogEyes",
		accessory = "coinBelly",
		role = "High income, high risk",
	},
	VaultTurtle = {
		id = "VaultTurtle",
		displayName = "Vault Turtle",
		cnName = "龟龟宝宝",
		rarity = "Uncommon",
		incomePerTick = 3,
		stealTime = 6, -- very slow to steal = defensive
		carrySpeedMultiplier = 0.75,
		color = Color3.fromRGB(90, 160, 90),
		flair = "shell",
		role = "Defense and safety",
	},
	TrustOwl = {
		id = "TrustOwl",
		displayName = "Trust Owl",
		cnName = "猫头鹰宝宝",
		rarity = "Uncommon",
		incomePerTick = 6,
		stealTime = 4,
		carrySpeedMultiplier = 0.8,
		color = Color3.fromRGB(90, 130, 220),
		flair = "owl",
		role = "Friendship and trust",
	},
	DebtDragon = {
		id = "DebtDragon",
		displayName = "Debt Dragon",
		cnName = "债务龙宝宝",
		rarity = "Rare",
		incomePerTick = 0,
		instantCoins = 100, -- paid the moment you take it home
		debtPercent = 0.2, -- ...then it takes 20% of every income tick
		stealTime = 3,
		carrySpeedMultiplier = 0.7,
		color = Color3.fromRGB(210, 70, 60),
		flair = "dragon",
		accessory = "suit",
		role = "Instant money, later consequences",
	},
}

-- Order used by the market stalls
BeastConfig.MarketOrder = { "VaultTurtle", "TrustOwl", "DebtDragon" }

-- ============ SPECIES (30) FOR THE GENERATED CATALOG ============

BeastConfig.Species = {
	-- Fruit babies (straight from the concept art)
	{ id = "Strawberry", en = "Strawberry", cn = "草莓", color = Color3.fromRGB(220, 60, 70), flair = "stem" },
	{ id = "Peach", en = "Peach", cn = "蜜桃", color = Color3.fromRGB(255, 170, 180), flair = "stem" },
	{ id = "GreenApple", en = "Green Apple", cn = "青苹果", color = Color3.fromRGB(150, 205, 80), flair = "stem" },
	{ id = "Blueberry", en = "Blueberry", cn = "蓝莓", color = Color3.fromRGB(80, 105, 210), flair = "stem" },
	{
		id = "Dragonfruit",
		en = "Dragonfruit",
		cn = "火龙果",
		color = Color3.fromRGB(230, 60, 140),
		flair = "spikes",
	},
	{ id = "Lemon", en = "Lemon", cn = "柠檬", color = Color3.fromRGB(245, 220, 70), flair = "stem" },
	{ id = "Grape", en = "Grape", cn = "葡萄", color = Color3.fromRGB(150, 90, 190), flair = "stem" },
	{ id = "Orange", en = "Orange", cn = "橙子", color = Color3.fromRGB(245, 150, 50), flair = "stem" },
	{ id = "Watermelon", en = "Watermelon", cn = "西瓜", color = Color3.fromRGB(95, 175, 85), flair = "stem" },
	{ id = "Pineapple", en = "Pineapple", cn = "菠萝", color = Color3.fromRGB(240, 200, 80), flair = "spikes" },
	{ id = "Avocado", en = "Avocado", cn = "牛油果", color = Color3.fromRGB(130, 160, 80), flair = "stem" },
	{ id = "Cherry", en = "Cherry", cn = "樱桃", color = Color3.fromRGB(200, 40, 60), flair = "stem" },
	{ id = "Mango", en = "Mango", cn = "芒果", color = Color3.fromRGB(255, 185, 70), flair = "stem" },
	{ id = "Kiwi", en = "Kiwi", cn = "奇异果", color = Color3.fromRGB(140, 150, 90), flair = "stem" },
	{ id = "Coconut", en = "Coconut", cn = "椰子", color = Color3.fromRGB(140, 105, 75), flair = "stem" },
	{ id = "Banana", en = "Banana", cn = "香蕉", color = Color3.fromRGB(250, 225, 105), flair = "stem" },
	-- Animal-hood babies (London/Seoul/Beijing/HK route casts)
	{ id = "Mouse", en = "Mouse", cn = "鼠鼠", color = Color3.fromRGB(140, 140, 145), flair = "roundEars" },
	{ id = "Frog", en = "Frog", cn = "蛙蛙", color = Color3.fromRGB(110, 180, 90), flair = "frogEyes" },
	{ id = "Turtle", en = "Turtle", cn = "龟龟", color = Color3.fromRGB(90, 160, 90), flair = "shell" },
	{ id = "Owl", en = "Owl", cn = "猫头鹰", color = Color3.fromRGB(165, 125, 85), flair = "owl" },
	{ id = "Dragon", en = "Dragon", cn = "龙龙", color = Color3.fromRGB(210, 70, 60), flair = "dragon" },
	{ id = "Cat", en = "Cat", cn = "猫猫", color = Color3.fromRGB(245, 180, 200), flair = "catEars" },
	{ id = "Bunny", en = "Bunny", cn = "兔兔", color = Color3.fromRGB(240, 240, 240), flair = "bunnyEars" },
	{ id = "Panda", en = "Panda", cn = "熊猫", color = Color3.fromRGB(245, 245, 245), flair = "pandaEars" },
	{ id = "Duck", en = "Duck", cn = "鸭鸭", color = Color3.fromRGB(250, 230, 120), flair = "duck" },
	{ id = "Lion", en = "Lion", cn = "狮子", color = Color3.fromRGB(230, 170, 80), flair = "mane" },
	{ id = "Fox", en = "Fox", cn = "狐狸", color = Color3.fromRGB(235, 130, 60), flair = "catEars" },
	{ id = "Otter", en = "Otter", cn = "水獭", color = Color3.fromRGB(150, 110, 80), flair = "roundEars" },
	{ id = "Husky", en = "Husky", cn = "哈士奇", color = Color3.fromRGB(150, 160, 175), flair = "catEars" },
	{ id = "Bulldog", en = "Bulldog", cn = "斗牛犬", color = Color3.fromRGB(180, 140, 110), flair = "roundEars" },
}

-- ============ CATALOG GENERATION (30 species x 10 numbers = 300) ============

local VARIANT_NUMBERS = { 8, 11, 22, 28, 33, 55, 66, 77, 88, 99 }
local ACCESSORY_POOL = { "none", "none", "none", "bowtie", "glasses", "headband", "headphones" }
-- Rarer babies are physically bigger (a Legendary towers over a Common!)
local RARITY_SIZE = { Common = 0.92, Uncommon = 1.0, Rare = 1.06, Epic = 1.16, Legendary = 1.28 }

local function pickRarity(rng)
	local total = 0
	for _, name in ipairs(BeastConfig.RarityOrder) do
		total += BeastConfig.Rarities[name].weight
	end
	local roll = rng:NextNumber() * total
	for _, name in ipairs(BeastConfig.RarityOrder) do
		roll -= BeastConfig.Rarities[name].weight
		if roll <= 0 then
			return name
		end
	end
	return "Common"
end

BeastConfig.Catalog = {}
BeastConfig.CatalogById = {}
BeastConfig.ByRarity = { Common = {}, Uncommon = {}, Rare = {}, Epic = {}, Legendary = {} }

for speciesIndex, species in ipairs(BeastConfig.Species) do
	for _, number in ipairs(VARIANT_NUMBERS) do
		-- Deterministic seed: every server generates the exact same catalog
		local rng = Random.new(speciesIndex * 1000 + number)

		local rarityName = pickRarity(rng)
		local rarity = BeastConfig.Rarities[rarityName]

		-- Slight per-variant color shift so siblings look related but distinct
		local h, s, v = species.color:ToHSV()
		local color = Color3.fromHSV(
			(h + (rng:NextNumber() - 0.5) * 0.06) % 1,
			math.clamp(s + (rng:NextNumber() - 0.5) * 0.2, 0, 1),
			math.clamp(v + (rng:NextNumber() - 0.5) * 0.2, 0.25, 1)
		)
		if rarityName == "Legendary" then
			color = color:Lerp(Color3.fromRGB(255, 200, 60), 0.45) -- golden sheen
		end

		local accessory = rarityName == "Legendary" and "crown" or ACCESSORY_POOL[rng:NextInteger(1, #ACCESSORY_POOL)]

		local def = {
			id = species.id .. number,
			displayName = ("%s %d"):format(species.en, number),
			cnName = species.cn .. number,
			species = species.id,
			rarity = rarityName,
			incomePerTick = math.max(1, math.floor(rarity.incomePerTick * (0.9 + rng:NextNumber() * 0.2) + 0.5)),
			stealTime = rarity.stealTime,
			carrySpeedMultiplier = rarity.carrySpeedMultiplier,
			color = color,
			flair = species.flair,
			accessory = accessory ~= "none" and accessory or nil,
			belly = rng:NextNumber() < 0.45, -- lighter belly patch on some
			sizeScale = RARITY_SIZE[rarityName] * (0.97 + rng:NextNumber() * 0.06),
			role = "Collectible",
		}

		table.insert(BeastConfig.Catalog, def)
		BeastConfig.CatalogById[def.id] = def
		table.insert(BeastConfig.ByRarity[rarityName], def)
	end
end

-- Everything that counts toward the collection (classics + catalog)
BeastConfig.TotalCollectible = #BeastConfig.Catalog + 5

-- ============ LOOKUPS ============

function BeastConfig.get(id)
	return BeastConfig.Beasts[id] or BeastConfig.CatalogById[id]
end

-- Server-side: roll a Mystery Egg (weighted rarity, then a random baby of it)
function BeastConfig.rollHatch()
	local total = 0
	for _, name in ipairs(BeastConfig.RarityOrder) do
		total += BeastConfig.Rarities[name].weight
	end
	local roll = math.random() * total
	for _, name in ipairs(BeastConfig.RarityOrder) do
		roll -= BeastConfig.Rarities[name].weight
		if roll <= 0 then
			local bucket = BeastConfig.ByRarity[name]
			if #bucket > 0 then
				return bucket[math.random(#bucket)]
			end
			break
		end
	end
	return BeastConfig.Catalog[math.random(#BeastConfig.Catalog)]
end

return BeastConfig
