--!strict
-- Themed caravan routes (路线扩展) from the concept's region sheets: Arctic,
-- Africa, New York, Singapore, and Osaka. Each route adds themed babies, route-
-- specific vehicles, an insurance setup, and headline profit/risk/time numbers.
--
-- This is content data for the upcoming "route" phase of the caravan system. It's
-- defined here so the designs are captured and ready to wire into CaravanService
-- (pick a route -> its risk/reward/event table drives the run). Babies here are
-- not yet in the hatch pool; see ROADMAP in README.
--
-- `role` maps each baby's themed type (typeLabel) onto a gameplay Roles.RoleId so
-- it slots into the existing squad system.

local Roles = require(script.Parent.Roles)
local Rarity = require(script.Parent.Rarity)

export type RouteBaby = {
	id: string,
	name: string, -- English display name
	theme: string, -- animal / costume motif
	city: string?, -- real-world tie-in where the sheet names one
	typeLabel: string, -- original themed type, e.g. "Guardian"
	role: Roles.RoleId,
	rarity: Rarity.RarityId,
	-- image / meshId / textureId can be added later (same as BabyData) for art.
}

export type RouteVehicle = {
	id: string,
	name: string,
	note: string,
}

export type RouteInsurance = {
	name: string,
	cost: number,
	payoutRatio: number,
}

export type Route = {
	id: string,
	name: string, -- English route name
	region: string,
	tagline: string,
	profit: number, -- headline expected payout
	riskStars: number, -- 1..5
	timeText: string, -- human-readable run length from the sheet
	babies: { RouteBaby },
	vehicles: { RouteVehicle },
	insurance: { RouteInsurance },
}

local RouteData = {}

RouteData.List = {
	--======================= ARCTIC (北极路线) =======================--
	{
		id = "arctic",
		name = "Arctic Route",
		region = "Polar / Tundra",
		tagline = "Brave the deep freeze to deliver the rarest babies.",
		profit = 6888,
		riskStars = 3,
		timeText = "25–35 min",
		babies = {
			{ id = "arctic_polarbear", name = "Polar Bear Baby", theme = "Polar bear suit", typeLabel = "Guardian", role = "Defense", rarity = "Epic" },
			{ id = "arctic_penguin", name = "Penguin Baby", theme = "Penguin suit", typeLabel = "Agile", role = "Caravan", rarity = "Rare" },
			{ id = "arctic_seal", name = "Seal Baby", theme = "Seal suit", typeLabel = "Endurance", role = "Defense", rarity = "Uncommon" },
			{ id = "arctic_reindeer", name = "Reindeer Baby", theme = "Reindeer suit", typeLabel = "Support", role = "Support", rarity = "Rare" },
			{ id = "arctic_icefisher", name = "Ice Fishing Baby", theme = "Ice angler", typeLabel = "Explorer", role = "Caravan", rarity = "Uncommon" },
			{ id = "arctic_aurora", name = "Aurora Explorer Baby", theme = "Aurora gear", typeLabel = "Special", role = "Support", rarity = "Legendary" },
			{ id = "arctic_escort", name = "Snow Escort Baby", theme = "Medic parka", typeLabel = "Escort", role = "Caravan", rarity = "Epic" },
			{ id = "arctic_navigator", name = "Glacier Navigator Baby", theme = "Navigator", typeLabel = "Commander", role = "Trust", rarity = "Epic" },
		},
		vehicles = {
			{ id = "snowmobile", name = "Snowmobile", note = "Fast over snow, small hold." },
			{ id = "icebreaker", name = "Icebreaker Truck", note = "Smashes through ice." },
			{ id = "reindeer_sleigh", name = "Reindeer Sleigh", note = "Classic, cosy capacity." },
			{ id = "tundra_tracked", name = "Tundra Tracked Hauler", note = "Tracked, big load." },
		},
		insurance = {
			{ name = "Basic", cost = 500, payoutRatio = 0.3 },
			{ name = "Transport", cost = 888, payoutRatio = 0.7 },
			{ name = "Polar Full", cost = 1888, payoutRatio = 1.0 },
		},
	},

	--======================= AFRICA (非洲路线) =======================--
	{
		id = "africa",
		name = "Africa Route",
		region = "Savanna / Desert / Coast",
		tagline = "Cross the vast continent on a new transport adventure.",
		profit = 8888,
		riskStars = 3,
		timeText = "~18 hrs",
		babies = {
			{ id = "africa_lion", name = "Savanna Lion Cub", theme = "Lion suit", city = "Serengeti", typeLabel = "Wildlife Photographer", role = "Caravan", rarity = "Rare" },
			{ id = "africa_pyramid", name = "Pyramid Baby", theme = "Pharaoh", city = "Cairo, Egypt", typeLabel = "Market Trader", role = "Income", rarity = "Epic" },
			{ id = "africa_wave", name = "Wave Kid", theme = "Surfer", city = "Cape Town, SA", typeLabel = "Surf Adventurer", role = "Caravan", rarity = "Uncommon" },
			{ id = "africa_sprinter", name = "Speed Cadet", theme = "Marathoner", city = "Nairobi, Kenya", typeLabel = "Marathon Runner", role = "Raid", rarity = "Rare" },
			{ id = "africa_caravan", name = "Desert Caravan Baby", theme = "Camel leader", city = "Sahara, Morocco", typeLabel = "Caravan Leader", role = "Caravan", rarity = "Epic" },
			{ id = "africa_drummer", name = "Drum Baby", theme = "Tribal drummer", city = "Ghana, W. Africa", typeLabel = "Rhythm Master", role = "Support", rarity = "Uncommon" },
			{ id = "africa_ranger", name = "Little Guardian", theme = "Park ranger", city = "Kenya", typeLabel = "Wildlife Ranger", role = "Defense", rarity = "Rare" },
			{ id = "africa_portboss", name = "Port Boss", theme = "Trader", city = "Lagos, Nigeria", typeLabel = "Port Trade Ace", role = "Trust", rarity = "Epic" },
		},
		vehicles = {
			{ id = "wild_jeep", name = "Wild Safari Jeep", note = "Off-road monster (5★ offroad)." },
			{ id = "cargo_trike", name = "Cargo Trike", note = "Nimble alley specialist." },
			{ id = "desert_truck", name = "Desert Cargo Truck", note = "Heavy load, fears no sand." },
			{ id = "city_courier", name = "City Courier", note = "Fuel-efficient urban runs." },
		},
		insurance = {
			{ name = "Basic", cost = 0, payoutRatio = 0.3 }, -- premium shown as % of pot on this sheet
			{ name = "Full", cost = 0, payoutRatio = 0.6 },
			{ name = "Premium", cost = 0, payoutRatio = 0.9 },
		},
	},

	--======================= NEW YORK (纽约路线) =======================--
	{
		id = "newyork",
		name = "New York Route",
		region = "Wall Street / NYC",
		tagline = "Run babies through NYC — the money's in your hands.",
		profit = 6888,
		riskStars = 3,
		timeText = "12–18 min",
		babies = {
			{ id = "ny_bull", name = "Wall St Bull Baby", theme = "Bull / suit", typeLabel = "Finance Elite", role = "Income", rarity = "Epic" },
			{ id = "ny_bagel", name = "Bagel Mouse Baby", theme = "Mouse / bagel", typeLabel = "Foodie", role = "Support", rarity = "Uncommon" },
			{ id = "ny_taxi", name = "Taxi Dog Baby", theme = "Dog / taxi cap", typeLabel = "Taxi Driver", role = "Caravan", rarity = "Rare" },
			{ id = "ny_coffee", name = "Coffee Analyst Baby", theme = "Analyst", typeLabel = "Data Whiz", role = "Trust", rarity = "Rare" },
			{ id = "ny_broadway", name = "Broadway Star Baby", theme = "Stage star", typeLabel = "Stage Star", role = "Support", rarity = "Epic" },
			{ id = "ny_hotdog", name = "Hotdog Corgi Baby", theme = "Corgi / hotdog", typeLabel = "Street Food", role = "Income", rarity = "Uncommon" },
			{ id = "ny_pigeon", name = "Subway Pigeon Baby", theme = "Pigeon", typeLabel = "Subway Patrol", role = "Defense", rarity = "Rare" },
			{ id = "ny_turtle", name = "Central Park Turtle Baby", theme = "Turtle", typeLabel = "Nature Guardian", role = "Defense", rarity = "Rare" },
		},
		vehicles = {
			{ id = "yellow_taxi", name = "Yellow Taxi", note = "Fast, great for short hops." },
			{ id = "armored_money", name = "Armored Money Truck", note = "High defense for valuables." },
			{ id = "delivery_scooter", name = "Delivery Scooter", note = "Agile through traffic." },
			{ id = "city_van", name = "City Van", note = "Balanced, stable, reliable." },
		},
		insurance = {
			{ name = "Basic", cost = 888, payoutRatio = 0.3 },
			{ name = "Mid", cost = 1666, payoutRatio = 0.5 },
			{ name = "Premium", cost = 2999, payoutRatio = 0.8 },
		},
	},

	--======================= SINGAPORE (新加坡·花园港) =======================--
	{
		id = "singapore",
		name = "Singapore Route",
		region = "Garden Port",
		tagline = "Weave between gardens and harbour in the Lion City.",
		profit = 12000,
		riskStars = 3,
		timeText = "Garden Port run",
		babies = {
			{ id = "sg_merlion", name = "Merlion Baby", theme = "Merlion", typeLabel = "Guardian", role = "Defense", rarity = "Legendary" },
			{ id = "sg_milktea", name = "Milk Tea Bunny Baby", theme = "Bunny / bubble tea", typeLabel = "Sweet & Cute", role = "Support", rarity = "Uncommon" },
			{ id = "sg_owl", name = "Orchid Owl Baby", theme = "Owl / orchid", typeLabel = "Elegant", role = "Trust", rarity = "Rare" },
			{ id = "sg_crab", name = "Hawker Crab Baby", theme = "Crab", typeLabel = "Food Master", role = "Income", rarity = "Epic" },
			{ id = "sg_panda", name = "Garden Panda Baby", theme = "Panda", typeLabel = "Nature Healing", role = "Support", rarity = "Rare" },
			{ id = "sg_otter", name = "Port Otter Baby", theme = "Otter", typeLabel = "Lively & Clever", role = "Caravan", rarity = "Rare" },
			{ id = "sg_apple", name = "Smart Apple Baby", theme = "Apple / glasses", typeLabel = "Tech Pioneer", role = "Trust", rarity = "Rare" },
			{ id = "sg_frog", name = "Rainstorm Frog Baby", theme = "Frog / umbrella", typeLabel = "Monsoon Warrior", role = "Defense", rarity = "Uncommon" },
		},
		vehicles = {
			{ id = "clean_van", name = "Clean Delivery Van", note = "Eco, nimble city weaving." },
			{ id = "port_flatbed", name = "Port Flatbed", note = "Harbour-only, stable load." },
			{ id = "garden_tour", name = "Garden Tour Car", note = "Smooth scenic cruiser." },
			{ id = "small_port_truck", name = "Small Port Truck", note = "Big capacity, storm-ready." },
		},
		insurance = {
			{ name = "Basic", cost = 888, payoutRatio = 0.3 },
			{ name = "Transport", cost = 1288, payoutRatio = 0.5 },
			{ name = "Used-car", cost = 1688, payoutRatio = 0.6 },
			{ name = "Full", cost = 2288, payoutRatio = 0.7 },
		},
	},

	--======================= OSAKA (大阪·商店街) =======================--
	{
		id = "osaka",
		name = "Osaka Route",
		region = "Shopping Arcade",
		tagline = "Food, shopping, and neon nights — caravan with flavour.",
		profit = 6666,
		riskStars = 2,
		timeText = "Medium",
		babies = {
			{ id = "osaka_takoyaki", name = "Takoyaki Baby", theme = "Octopus / takoyaki", typeLabel = "Food Master", role = "Income", rarity = "Epic" },
			{ id = "osaka_ramen", name = "Ramen Baby", theme = "Fox / ramen", typeLabel = "Late-night Eats", role = "Support", rarity = "Uncommon" },
			{ id = "osaka_arcade", name = "Arcade Baby", theme = "Panda / gamer", typeLabel = "Game Master", role = "Caravan", rarity = "Rare" },
			{ id = "osaka_tanuki", name = "Shop Tanuki Baby", theme = "Tanuki", typeLabel = "Shopkeeper", role = "Trust", rarity = "Rare" },
			{ id = "osaka_neonpeach", name = "Neon Peach Baby", theme = "Peach / neon", typeLabel = "Fashion Icon", role = "Support", rarity = "Rare" },
			{ id = "osaka_dorayaki", name = "Dorayaki Baby", theme = "Dorayaki", typeLabel = "Sweet Treat", role = "Income", rarity = "Uncommon" },
			{ id = "osaka_neonberry", name = "Neon Berry Baby", theme = "Berry / neon", typeLabel = "Speed Sweet", role = "Caravan", rarity = "Rare" },
			{ id = "osaka_bull", name = "Bull Demon Baby", theme = "Bull", typeLabel = "Mighty Brawler", role = "Raid", rarity = "Epic" },
			{ id = "osaka_catspeed", name = "Cat Courier Baby", theme = "Cat", typeLabel = "Delivery Ace", role = "Caravan", rarity = "Rare" },
			{ id = "osaka_castleturtle", name = "Castle Turtle Baby", theme = "Turtle", typeLabel = "History Buff", role = "Defense", rarity = "Rare" },
		},
		vehicles = {
			{ id = "kei_van", name = "Kei Van", note = "Thrifty, weaves alleys (¥500)." },
			{ id = "takoyaki_trike", name = "Takoyaki Snack Trike", note = "Mobile stall, fast (¥800)." },
			{ id = "mini_ev", name = "Mini Delivery EV", note = "Quiet, steady (¥1200)." },
			{ id = "retro_handcart", name = "Retro Handcart", note = "Slow but big retro hold (¥1500)." },
		},
		insurance = {
			{ name = "Basic", cost = 300, payoutRatio = 0.3 },
			{ name = "Transport", cost = 600, payoutRatio = 0.6 },
			{ name = "Used-car", cost = 450, payoutRatio = 0.5 },
			{ name = "Betrayal", cost = 999, payoutRatio = 0.5 },
			{ name = "Full", cost = 1200, payoutRatio = 0.8 },
		},
	},
} :: { Route }

RouteData.ById = {} :: { [string]: Route }
for _, route in RouteData.List do
	RouteData.ById[route.id] = route
end

function RouteData.get(id: string): Route?
	return RouteData.ById[id]
end

return RouteData
