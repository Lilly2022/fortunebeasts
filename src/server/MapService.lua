--[[
	MapService
	Builds the whole placeholder map from Parts at runtime.
	Nothing needs to be built by hand in Studio - press Play and it appears.

	Creates Workspace.FB_Map with:
	- Ground (big green baseplate) + a blue river strip
	- Market (center plaza, spawn, market stalls area)
	- CaravanRoute (MarketStart -> BridgePoint -> DeliveryPoint, with a bridge)
	- DebugParts (empty folder for experiments)

	Plots are built by PlotService into FB_Map.Plots.
]]

local MapService = {}

local map -- Workspace.FB_Map

-- Small helper: make an anchored Part with common defaults
local function part(props)
	local p = Instance.new("Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for key, value in pairs(props) do
		p[key] = value
	end
	return p
end

local function label(parent, text, height)
	-- Floating sign text above a part
	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.new(0, 220, 0, 44)
	billboard.StudsOffset = Vector3.new(0, height or 5, 0)
	billboard.AlwaysOnTop = true
	billboard.MaxDistance = 200
	local textLabel = Instance.new("TextLabel")
	textLabel.Size = UDim2.new(1, 0, 1, 0)
	textLabel.BackgroundTransparency = 1
	textLabel.Text = text
	textLabel.TextScaled = true
	textLabel.Font = Enum.Font.FredokaOne
	textLabel.TextColor3 = Color3.new(1, 1, 1)
	textLabel.TextStrokeTransparency = 0.2
	textLabel.Parent = billboard
	billboard.Parent = parent
	return billboard
end

function MapService.getMap()
	return map
end

function MapService.init(_services)
	map = Instance.new("Folder")
	map.Name = "FB_Map"

	-- ============ GROUND ============
	local ground = part({
		Name = "Ground",
		Size = Vector3.new(800, 2, 800),
		Position = Vector3.new(0, -1, 0), -- top surface sits at Y = 0
		Color = Color3.fromRGB(106, 170, 92),
		Material = Enum.Material.Grass,
	})
	ground.Parent = map

	-- River strip (decorative) crossing the caravan route
	local river = part({
		Name = "River",
		Size = Vector3.new(800, 1, 16),
		Position = Vector3.new(0, -0.4, -100),
		Color = Color3.fromRGB(70, 140, 220),
		Material = Enum.Material.Glass,
		Transparency = 0.3,
	})
	river.Parent = map

	-- ============ MARKET (center) ============
	local market = Instance.new("Folder")
	market.Name = "Market"
	market.Parent = map

	local plaza = part({
		Name = "Plaza",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(1, 60, 60),
		CFrame = CFrame.new(0, 0.5, 0) * CFrame.Angles(0, 0, math.rad(90)),
		Color = Color3.fromRGB(215, 200, 170),
		Material = Enum.Material.SmoothPlastic,
	})
	plaza.Parent = market
	label(plaza, "🏪 MARKET", 8)

	local spawnLocation = Instance.new("SpawnLocation")
	spawnLocation.Name = "Spawn"
	spawnLocation.Size = Vector3.new(10, 1, 10)
	spawnLocation.Position = Vector3.new(0, 1.5, 12)
	spawnLocation.Anchored = true
	spawnLocation.Neutral = true
	spawnLocation.Color = Color3.fromRGB(240, 240, 240)
	spawnLocation.Duration = 0
	spawnLocation.Parent = market

	-- ============ CARAVAN ROUTE ============
	local route = Instance.new("Folder")
	route.Name = "CaravanRoute"
	route.Parent = map

	local function routePad(name, position, color, text)
		local pad = part({
			Name = name,
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(1, 14, 14),
			CFrame = CFrame.new(position) * CFrame.Angles(0, 0, math.rad(90)),
			Color = color,
			Material = Enum.Material.Neon,
		})
		pad.Parent = route
		label(pad, text, 6)
		return pad
	end

	routePad("MarketStart", Vector3.new(0, 0.6, -35), Color3.fromRGB(255, 170, 60), "🚩 CARAVAN START")
	routePad("BridgePoint", Vector3.new(0, 0.6, -100), Color3.fromRGB(170, 130, 90), "🌉 BRIDGE")
	routePad("DeliveryPoint", Vector3.new(0, 0.6, -170), Color3.fromRGB(120, 220, 120), "📦 DELIVERY")

	-- Bridge over the river
	local bridge = part({
		Name = "Bridge",
		Size = Vector3.new(12, 1, 24),
		Position = Vector3.new(0, 0.9, -100),
		Color = Color3.fromRGB(150, 110, 70),
		Material = Enum.Material.WoodPlanks,
	})
	bridge.Parent = route

	-- Dirt path connecting the route so players can see where to go
	local pathA = part({
		Name = "PathA",
		Size = Vector3.new(8, 0.4, 60),
		Position = Vector3.new(0, 0.2, -62),
		Color = Color3.fromRGB(180, 150, 110),
		Material = Enum.Material.Sand,
	})
	pathA.Parent = route
	local pathB = part({
		Name = "PathB",
		Size = Vector3.new(8, 0.4, 58),
		Position = Vector3.new(0, 0.2, -141),
		Color = Color3.fromRGB(180, 150, 110),
		Material = Enum.Material.Sand,
	})
	pathB.Parent = route

	-- ============ DEBUG ============
	local debugParts = Instance.new("Folder")
	debugParts.Name = "DebugParts"
	debugParts.Parent = map

	map.Parent = workspace
	print("[FB][Map] Map built: ground, market, caravan route")
end

return MapService
