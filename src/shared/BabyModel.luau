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

-- Returns a Model with a PrimaryPart named "Body" at the origin. Caller sets CFrame.
function BabyModel.build(babyId: string): Model
	local def = BabyData.get(babyId)
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

return BabyModel
