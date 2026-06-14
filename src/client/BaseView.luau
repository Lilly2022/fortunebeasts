--!strict
-- Renders the player's "placed" babies as squishy models on a little display
-- platform near spawn, and implements the squish (解压) mechanic: stand near a
-- baby, press E, and it squashes with a bouncy tween while a coin pops out.
--
-- The platform + models are client-side display. Coins/income are granted by the
-- server (the Squish remote), so this stays purely cosmetic and safe.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Net = require(Shared.Net)
local BabyModel = require(Shared.BabyModel)
local BabyData = require(Shared.BabyData)
local GameConfig = require(Shared.GameConfig)

local State = require(script.Parent.State)

local BaseView = {}

local PLATFORM_CENTER = Vector3.new(0, 0.5, -28)
local SLOT_SPACING = 6
local SQUISH_RANGE = 14

-- uid -> { model, baby, busy }
local active: { [string]: { model: Model, babyId: string, busy: boolean } } = {}
local folder: Folder? = nil

local function ensureFolder(): Folder
	if folder and folder.Parent then
		return folder
	end
	local f = Instance.new("Folder")
	f.Name = "FortuneBeasts_Display"
	f.Parent = workspace
	folder = f
	return f
end

local function buildPlatform()
	local f = ensureFolder()
	if f:FindFirstChild("Platform") then
		return
	end
	local plat = Instance.new("Part")
	plat.Name = "Platform"
	plat.Anchored = true
	plat.Size = Vector3.new(SLOT_SPACING * GameConfig.MaxPlacedBabies + 8, 1, 12)
	plat.Position = PLATFORM_CENTER - Vector3.new(0, 0.5, 0)
	plat.Color = Color3.fromRGB(70, 60, 95)
	plat.Material = Enum.Material.SmoothPlastic
	plat.TopSurface = Enum.SurfaceType.Smooth
	plat.Parent = f

	local sign = Instance.new("Part")
	sign.Name = "Sign"
	sign.Anchored = true
	sign.Size = Vector3.new(10, 2.5, 0.4)
	sign.Position = PLATFORM_CENTER + Vector3.new(0, 6, -6)
	sign.Color = Color3.fromRGB(245, 90, 160)
	sign.Parent = f
	local sg = Instance.new("SurfaceGui")
	sg.Face = Enum.NormalId.Front
	sg.CanvasSize = Vector2.new(400, 100)
	sg.Parent = sign
	local txt = Instance.new("TextLabel")
	txt.Size = UDim2.fromScale(1, 1)
	txt.BackgroundTransparency = 1
	txt.Font = Enum.Font.FredokaOne
	txt.Text = "SQUISH STATION — press E"
	txt.TextColor3 = Color3.fromRGB(255, 255, 255)
	txt.TextScaled = true
	txt.Parent = sg
end

local function slotCFrame(index: number, total: number): CFrame
	local offset = (index - (total + 1) / 2) * SLOT_SPACING
	return CFrame.new(PLATFORM_CENTER + Vector3.new(offset, 1.5, 0))
end

local function coinPop(position: Vector3)
	local part = Instance.new("Part")
	part.Anchored = true
	part.CanCollide = false
	part.Shape = Enum.PartType.Cylinder
	part.Size = Vector3.new(0.2, 0.9, 0.9)
	part.Color = Color3.fromRGB(245, 200, 70)
	part.Material = Enum.Material.Neon
	part.CFrame = CFrame.new(position) * CFrame.Angles(0, 0, math.rad(90))
	part.Parent = ensureFolder()
	local goal = CFrame.new(position + Vector3.new(math.random(-2, 2), 5, 0)) * CFrame.Angles(0, math.rad(720), math.rad(90))
	local tween = TweenService:Create(part, TweenInfo.new(0.6, Enum.EasingStyle.Quad), { CFrame = goal, Transparency = 1 })
	tween:Play()
	tween.Completed:Connect(function()
		part:Destroy()
	end)
end

local function squishModel(entry: { model: Model, babyId: string, busy: boolean })
	if entry.busy or not entry.model.PrimaryPart then
		return
	end
	entry.busy = true
	local def = BabyData.get(entry.babyId)
	local bounce = def and def.squishiness or 0.6
	local body = entry.model.PrimaryPart
	local base = body.Size
	-- Squash down then spring back.
	local squashed = Vector3.new(base.X * (1 + bounce * 0.4), base.Y * (1 - bounce * 0.5), base.Z * (1 + bounce * 0.4))
	local down = TweenService:Create(body, TweenInfo.new(0.08, Enum.EasingStyle.Quad), { Size = squashed })
	down:Play()
	down.Completed:Connect(function()
		local up = TweenService:Create(
			body,
			TweenInfo.new(0.35, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out),
			{ Size = base }
		)
		up:Play()
		up.Completed:Connect(function()
			entry.busy = false
		end)
	end)
	coinPop(body.Position)
end

-- Rebuild the display to match the current snapshot's placed babies.
local function sync(snap: any)
	if not snap then
		return
	end
	buildPlatform()

	local placed = {}
	for _, owned in snap.babies do
		if owned.placed then
			table.insert(placed, owned)
		end
	end

	-- Remove models no longer placed.
	local keep: { [string]: boolean } = {}
	for _, owned in placed do
		keep[owned.uid] = true
	end
	for uid, entry in active do
		if not keep[uid] then
			entry.model:Destroy()
			active[uid] = nil
		end
	end

	-- Add / reposition.
	for i, owned in placed do
		local entry = active[owned.uid]
		if not entry or entry.babyId ~= owned.babyId then
			if entry then
				entry.model:Destroy()
			end
			local model = BabyModel.build(owned.babyId)
			BabyModel.attachPortrait(model, owned.babyId)
			model.Parent = ensureFolder()
			entry = { model = model, babyId = owned.babyId, busy = false }
			active[owned.uid] = entry
		end
		entry.model:PivotTo(slotCFrame(i, #placed))
	end
end

local function nearestBaby(): { model: Model, babyId: string, busy: boolean }?
	local char = Players.LocalPlayer.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not root then
		return nil
	end
	local best, bestDist = nil, SQUISH_RANGE
	for _, entry in active do
		if entry.model.PrimaryPart then
			local d = (entry.model.PrimaryPart.Position - (root :: BasePart).Position).Magnitude
			if d < bestDist then
				best, bestDist = entry, d
			end
		end
	end
	return best
end

local lastSquish = 0

function BaseView.start()
	State.subscribe(sync)

	UserInputService.InputBegan:Connect(function(input, processed)
		if processed or input.KeyCode ~= GameConfig.SquishKey then
			return
		end
		if os.clock() - lastSquish < GameConfig.SquishCooldown then
			return
		end
		local entry = nearestBaby()
		if entry then
			lastSquish = os.clock()
			squishModel(entry)
			Net.event("Squish"):FireServer()
		end
	end)

	-- Other players' squishes (cosmetic ripple — pop a coin on a random model).
	Net.event("SquishFx").OnClientEvent:Connect(function(userId)
		if userId == Players.LocalPlayer.UserId then
			return
		end
		for _, entry in active do
			if not entry.busy then
				squishModel(entry)
				break
			end
		end
	end)
end

return BaseView
