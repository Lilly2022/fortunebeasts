--!strict
-- Builds the actual world on server start: ground, a spawn pad, and a Collection
-- Gallery that displays every baby in the roster lined up on pedestals — so the
-- moment a player presses Play they see all the characters, before hatching
-- anything. (Roblox builds the world from code at runtime; this is that code.)

local Workspace = game:GetService("Workspace")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local BabyData = require(Shared.BabyData)
local BabyModel = require(Shared.BabyModel)
local Rarity = require(Shared.Rarity)

local WorldService = {}

local function makePart(name: string, size: Vector3, pos: Vector3, color: Color3, material: Enum.Material): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.Size = size
	p.Position = pos
	p.Color = color
	p.Material = material
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	return p
end

local function makeSign(text: string, pos: Vector3, color: Color3): Part
	local sign = makePart("Sign", Vector3.new(18, 3.5, 0.5), pos, color, Enum.Material.SmoothPlastic)
	local sg = Instance.new("SurfaceGui")
	sg.Face = Enum.NormalId.Front
	sg.CanvasSize = Vector2.new(600, 120)
	sg.Parent = sign
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.FredokaOne
	label.Text = text
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextScaled = true
	label.Parent = sg
	return sign
end

function WorldService.start()
	-- Ground.
	makePart("Ground", Vector3.new(400, 2, 400), Vector3.new(0, -1, 0), Color3.fromRGB(118, 168, 92), Enum.Material.Grass).Parent =
		Workspace

	-- Spawn pad (so players land somewhere solid, facing the gallery).
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "SpawnPad"
	spawn.Anchored = true
	spawn.Size = Vector3.new(14, 1, 14)
	spawn.Position = Vector3.new(0, 0.5, 16)
	spawn.Color = Color3.fromRGB(245, 90, 160)
	spawn.Material = Enum.Material.SmoothPlastic
	spawn.Neutral = true
	spawn.Parent = Workspace

	makeSign("FORTUNE BEASTS: SQUISH CARAVAN", Vector3.new(0, 7, 24), Color3.fromRGB(245, 90, 160)).Parent = Workspace

	-- Collection Gallery: every baby on a pedestal, in rows in front of spawn.
	local gallery = Instance.new("Folder")
	gallery.Name = "CollectionGallery"
	gallery.Parent = Workspace

	makeSign("COLLECTION GALLERY", Vector3.new(0, 6, 4), Color3.fromRGB(110, 80, 200)).Parent = gallery

	local perRow = 8
	local spacingX = 7
	local spacingZ = 9
	local startZ = -8

	for i, def in ipairs(BabyData.List) do
		local index = i - 1
		local row = math.floor(index / perRow)
		local col = index % perRow
		local cx = (col - (perRow - 1) / 2) * spacingX
		local cz = startZ - row * spacingZ

		-- Pedestal tinted by rarity.
		local rarity = Rarity.get(def.rarity)
		makePart("Pedestal", Vector3.new(4.5, 1.5, 4.5), Vector3.new(cx, 0.75, cz), rarity.color, Enum.Material.SmoothPlastic).Parent =
			gallery

		-- Baby model (placeholder now; uses real art/mesh automatically once added).
		local model = BabyModel.build(def.id)
		BabyModel.attachPortrait(model, def.id)
		for _, d in model:GetDescendants() do
			if d:IsA("BasePart") then
				d.Anchored = true
			end
		end
		model:PivotTo(CFrame.new(cx, 3.2, cz))
		model.Parent = gallery
	end

	print(string.format("[FortuneBeasts] World built — %d babies on display.", #BabyData.List))
end

return WorldService
