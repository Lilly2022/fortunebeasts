--[[
	BeastConfig
	Every Fortune Beast in the game, exactly as designed.
	- incomePerTick: coins paid every income tick (see GameConfig.incomeTickSeconds)
	- stealTime: seconds a thief must hold the prompt to grab it
	- carrySpeedMultiplier: thief walk speed while carrying (lower = heavier)
	- instantCoins / debtPercent: Debt Dragon only (money now, a cut of income later)
]]

local BeastConfig = {}

BeastConfig.Rarities = {
	Common = { color = Color3.fromRGB(190, 190, 190) },
	Uncommon = { color = Color3.fromRGB(120, 200, 120) },
	Rare = { color = Color3.fromRGB(255, 200, 60) },
}

BeastConfig.Beasts = {
	TaxRat = {
		id = "TaxRat",
		displayName = "Tax Rat",
		rarity = "Common",
		incomePerTick = 5,
		stealTime = 3,
		carrySpeedMultiplier = 0.85,
		color = Color3.fromRGB(130, 130, 135), -- gray
		role = "Steady beginner income",
	},
	GoldFrog = {
		id = "GoldFrog",
		displayName = "Gold Frog",
		rarity = "Rare",
		incomePerTick = 20,
		stealTime = 2,
		carrySpeedMultiplier = 0.65,
		color = Color3.fromRGB(235, 190, 45), -- gold
		role = "High income, high risk",
	},
	VaultTurtle = {
		id = "VaultTurtle",
		displayName = "Vault Turtle",
		rarity = "Uncommon",
		incomePerTick = 3,
		stealTime = 6, -- very slow to steal = defensive
		carrySpeedMultiplier = 0.75,
		color = Color3.fromRGB(90, 160, 90), -- green
		role = "Defense and safety",
	},
	TrustOwl = {
		id = "TrustOwl",
		displayName = "Trust Owl",
		rarity = "Uncommon",
		incomePerTick = 6,
		stealTime = 4,
		carrySpeedMultiplier = 0.8,
		color = Color3.fromRGB(90, 130, 220), -- blue
		role = "Friendship and trust",
	},
	DebtDragon = {
		id = "DebtDragon",
		displayName = "Debt Dragon",
		rarity = "Rare",
		incomePerTick = 0,
		instantCoins = 100, -- paid the moment you take it home
		debtPercent = 0.2, -- ...then it takes 20% of every income tick
		stealTime = 3,
		carrySpeedMultiplier = 0.7,
		color = Color3.fromRGB(210, 70, 60), -- red
		role = "Instant money, later consequences",
	},
}

-- Order used by the market stalls
BeastConfig.MarketOrder = { "VaultTurtle", "TrustOwl", "DebtDragon" }

function BeastConfig.get(id)
	return BeastConfig.Beasts[id]
end

return BeastConfig
