--!strict
-- Rarity tiers for babies. Higher tiers earn more and are harder to hatch.
-- Mirrors the concept's "Rarity Guide": Common -> Mythic.

export type RarityId = "Common" | "Uncommon" | "Rare" | "Epic" | "Legendary" | "Mythic"

export type RarityInfo = {
	id: RarityId,
	displayName: string,
	-- Relative weight used when rolling a random baby from a hatch. Higher = more common.
	hatchWeight: number,
	-- Multiplier applied to a baby's base income.
	incomeMultiplier: number,
	-- UI accent colour.
	color: Color3,
}

local Rarity = {}

Rarity.Order = { "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic" } :: { RarityId }

Rarity.Info = {
	Common = {
		id = "Common",
		displayName = "Common",
		hatchWeight = 1000,
		incomeMultiplier = 1.0,
		color = Color3.fromRGB(176, 176, 176),
	},
	Uncommon = {
		id = "Uncommon",
		displayName = "Uncommon",
		hatchWeight = 450,
		incomeMultiplier = 1.6,
		color = Color3.fromRGB(96, 200, 120),
	},
	Rare = {
		id = "Rare",
		displayName = "Rare",
		hatchWeight = 170,
		incomeMultiplier = 2.6,
		color = Color3.fromRGB(80, 150, 240),
	},
	Epic = {
		id = "Epic",
		displayName = "Epic",
		hatchWeight = 55,
		incomeMultiplier = 4.5,
		color = Color3.fromRGB(170, 96, 230),
	},
	Legendary = {
		id = "Legendary",
		displayName = "Legendary",
		hatchWeight = 14,
		incomeMultiplier = 8.0,
		color = Color3.fromRGB(245, 180, 60),
	},
	Mythic = {
		id = "Mythic",
		displayName = "Mythic",
		hatchWeight = 3,
		incomeMultiplier = 15.0,
		color = Color3.fromRGB(245, 90, 160),
	},
} :: { [string]: RarityInfo }

function Rarity.get(id: RarityId): RarityInfo
	return Rarity.Info[id]
end

return Rarity
