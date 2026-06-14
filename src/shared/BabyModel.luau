--!strict
-- Builds a chunky procedural "squish baby" model from a BabyDef. These are
-- placeholders standing in for real modelled/animated assets, but they're shaped
-- to read at a glance (round body, fruit-hat, pacifier) and they squish nicely.

local BabyData = require(script.Parent.BabyData)

local BabyModel = {}

local function part(name: string, size: Vector3, color: Color3, shape: Enum.PartType): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Shape = shape
	p.Size = size
	p.Color = color
	p.Material = Enum.Material.SmoothPlastic
	p.Anchored = true
	p.CanCollide = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	return p
end

-- Builds the real 3D mesh figure when the baby has a meshId asset. Returns a
-- Model whose PrimaryPart ("Body") carries the mesh, so the squish tween (which
-- scales Body) still works unchanged.
local function buildMeshModel(babyId: string, meshId: string, textureId: string?): Model
	local model = Instance.new("Model")
	model.Name = "Baby_" .. babyId

	local body = Instance.new("Part")
	body.Name = "Body"
	body.Size = Vector3.new(3, 3, 3)
	body.Transparency = 1 -- the mesh provides the visuals
	body.Anchored = true
	body.CanCollide = false

	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.FileMesh
	mesh.MeshId = meshId
	if textureId then
		mesh.TextureId = textureId
	end
	mesh.Scale = Vector3.new(1, 1, 1)
	mesh.Parent = body

	body.Parent = model
	model.PrimaryPart = body
	return model
end

-- Returns a Model with a PrimaryPart named "Body" at the origin. Caller sets CFrame.
function BabyModel.build(babyId: string): Model
	local def = BabyData.get(babyId)

	-- Prefer a real mesh asset if the designer supplied one.
	if def and def.meshId and def.meshId ~= "" then
		return buildMeshModel(babyId, def.meshId, def.textureId)
	end

	local bodyColor = def and def.color or Color3.fromRGB(255, 220, 200)
	local hatColor = def and def.accent or Color3.fromRGB(220, 80, 80)

	local model = Instance.new("Model")
	model.Name = "Baby_" .. babyId

	local body = part("Body", Vector3.new(2.2, 2, 2.2), bodyColor, Enum.PartType.Ball)
	body.Parent = model
	model.PrimaryPart = body

	local head = part("Head", Vector3.new(1.7, 1.6, 1.7), Color3.fromRGB(255, 224, 196), Enum.PartType.Ball)
	head.CFrame = body.CFrame * CFrame.new(0, 1.5, 0)
	head.Parent = model

	local hat = part("FruitHat", Vector3.new(1.9, 1.1, 1.9), hatColor, Enum.PartType.Ball)
	hat.CFrame = head.CFrame * CFrame.new(0, 0.8, 0)
	hat.Parent = model

	local pacifier = part("Pacifier", Vector3.new(0.5, 0.5, 0.5), Color3.fromRGB(255, 170, 190), Enum.PartType.Ball)
	pacifier.CFrame = head.CFrame * CFrame.new(0, -0.2, 0.85)
	pacifier.Parent = model

	-- A subtle eye pair so it has a face.
	for _, side in { -0.45, 0.45 } do
		local eye = part("Eye", Vector3.new(0.28, 0.28, 0.28), Color3.fromRGB(40, 40, 40), Enum.PartType.Ball)
		eye.CFrame = head.CFrame * CFrame.new(side, 0.2, 0.8)
		eye.Parent = model
	end

	return model
end

-- Floats the baby's 2D artwork + name on a billboard above the model. Safe to
-- call even if the baby has no `image` yet (then it just shows the name).
function BabyModel.attachPortrait(model: Model, babyId: string)
	local def = BabyData.get(babyId)
	if not model.PrimaryPart then
		return
	end

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "Portrait"
	billboard.Size = UDim2.fromOffset(120, 150)
	billboard.StudsOffsetWorldSpace = Vector3.new(0, 3.5, 0)
	billboard.AlwaysOnTop = false
	billboard.Adornee = model.PrimaryPart
	billboard.Parent = model.PrimaryPart

	if def and def.image and def.image ~= "" then
		local img = Instance.new("ImageLabel")
		img.Size = UDim2.fromOffset(110, 110)
		img.Position = UDim2.fromOffset(5, 0)
		img.BackgroundTransparency = 1
		img.Image = def.image
		img.ScaleType = Enum.ScaleType.Fit
		img.Parent = billboard
	end

	local name = Instance.new("TextLabel")
	name.Size = UDim2.new(1, 0, 0, 28)
	name.Position = UDim2.new(0, 0, 1, -28)
	name.BackgroundTransparency = 0.3
	name.BackgroundColor3 = Color3.fromRGB(20, 18, 30)
	name.Font = Enum.Font.FredokaOne
	name.Text = def and def.name or babyId
	name.TextColor3 = Color3.fromRGB(255, 255, 255)
	name.TextScaled = true
	name.Parent = billboard

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = name
end

return BabyModel
