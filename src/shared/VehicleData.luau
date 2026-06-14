--!strict
-- Caravan vehicles (运娃车队). From the concept's vehicle line-up: a free cart
-- through to high-capacity trucks, each with trade-offs. Used in caravan runs to
-- decide how much loot you can haul, how fast, and how well-defended it is.

export type VehicleDef = {
	id: string,
	name: string,
	cost: number, -- coins to rent/buy; 0 = free starter
	capacity: number, -- how many babies/loot units it can carry
	speed: number, -- 1..5 affects run duration
	defense: number, -- 1..5 reduces loss chance on ambush
	fuelCost: number, -- coins consumed per run
	reliability: number, -- 0..1 chance of NOT breaking down
	blurb: string,
}

local VehicleData = {}

VehicleData.List = {
	{ id = "cart", name = "Push Cart", cost = 0, capacity = 1, speed = 1, defense = 1, fuelCost = 0, reliability = 0.95, blurb = "Free, slow, but it hauls." },
	{ id = "trike", name = "Caravan Trike", cost = 350, capacity = 2, speed = 2, defense = 1, fuelCost = 20, reliability = 0.85, blurb = "Classic three-wheeler — retro vibes." },
	{ id = "van", name = "Rental Van", cost = 500, capacity = 3, speed = 3, defense = 2, fuelCost = 40, reliability = 0.8, blurb = "Wobbly but roomy nostalgia-mobile." },
	{ id = "courier", name = "Courier Truck", cost = 800, capacity = 2, speed = 4, defense = 2, fuelCost = 50, reliability = 0.88, blurb = "Fast deliveries, smaller hold." },
	{ id = "pickup", name = "Old Pickup", cost = 1200, capacity = 4, speed = 3, defense = 3, fuelCost = 60, reliability = 0.82, blurb = "Tough farm truck, hauls and climbs." },
	{ id = "armored", name = "Armored Hauler", cost = 2000, capacity = 4, speed = 2, defense = 5, fuelCost = 90, reliability = 0.9, blurb = "Steel-clad — bandits bounce off." },
	{ id = "pearl_truck", name = "Pearl River Freighter", cost = 5000, capacity = 8, speed = 3, defense = 4, fuelCost = 150, reliability = 0.85, blurb = "Legendary river hauler, massive hold." },
} :: { VehicleDef }

VehicleData.ById = {} :: { [string]: VehicleDef }
for _, def in VehicleData.List do
	VehicleData.ById[def.id] = def
end

function VehicleData.get(id: string): VehicleDef?
	return VehicleData.ById[id]
end

return VehicleData
