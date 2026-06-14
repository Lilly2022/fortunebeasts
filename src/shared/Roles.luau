--!strict
-- Squad roles from the concept's "Squad Roles" panel. Each baby has one role
-- which influences how it is used in the core loop.

export type RoleId = "Income" | "Trust" | "Defense" | "Raid" | "Caravan" | "Support"

export type RoleInfo = {
	id: RoleId,
	displayName: string,
	description: string,
	color: Color3,
}

local Roles = {}

Roles.Order = { "Income", "Trust", "Defense", "Raid", "Caravan", "Support" } :: { RoleId }

Roles.Info = {
	Income = {
		id = "Income",
		displayName = "Income",
		description = "Earn coins & resources passively.",
		color = Color3.fromRGB(245, 180, 60),
	},
	Trust = {
		id = "Trust",
		displayName = "Trust",
		description = "Boost team bonds and reduce betrayal odds.",
		color = Color3.fromRGB(232, 96, 120),
	},
	Defense = {
		id = "Defense",
		displayName = "Defense",
		description = "Guard your base & absorb raid damage.",
		color = Color3.fromRGB(80, 150, 240),
	},
	Raid = {
		id = "Raid",
		displayName = "Raid",
		description = "Attack & disrupt rival bases.",
		color = Color3.fromRGB(200, 70, 70),
	},
	Caravan = {
		id = "Caravan",
		displayName = "Caravan",
		description = "Travel, gather, and escort loot.",
		color = Color3.fromRGB(235, 140, 60),
	},
	Support = {
		id = "Support",
		displayName = "Support",
		description = "Heal, buff, and provide utility.",
		color = Color3.fromRGB(96, 200, 120),
	},
} :: { [string]: RoleInfo }

function Roles.get(id: RoleId): RoleInfo
	return Roles.Info[id]
end

return Roles
