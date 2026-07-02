--[[
	BeastService
	Owns every Fortune Beast in the world:
	- builds cute placeholder beast models out of Parts
	- places beasts on exposed / vault pads
	- lets owners move beasts between exposed and vault (ProximityPrompt "E")
	- gives new players their starter beasts (Tax Rat + Gold Frog)
	- transfers ownership when a steal succeeds (called by StealService)

	Beast record shape:
	{ uid, beastId, owner, slotType ("exposed"/"vault"), slotIndex,
	  model, isStarter, carriedBy }
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local GameConfig = require(ReplicatedStorage.FB_Modules.GameConfig)
local BeastConfig = require(ReplicatedStorage.FB_Modules.BeastConfig)

local BeastService = {}

local beastsByPlayer = {} -- [player] = { record, record, ... }
local recordByModel = {} -- [model] = record
local nextUid = 0
local services

local function dprint(...)
	if GameConfig.debug then
		print("[FB][Beast]", ...)
	end
end

-- ============ MODEL BUILDING (placeholder Parts, no Toolbox assets) ============

local function ball(size, color, cf, parent)
	local p = Instance.new("Part")
	p.Shape = Enum.PartType.Ball
	p.Size = Vector3.new(size, size, size)
	p.Color = color
	p.Material = Enum.Material.SmoothPlastic
	p.CFrame = cf
	p.CanCollide = false
	p.Anchored = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

local function weldTo(root, p)
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = root
	weld.Part1 = p
	weld.Parent = root
end

local function box(size, color, cf, parent)
	local p = Instance.new("Part")
	p.Size = size
	p.Color = color
	p.Material = Enum.Material.SmoothPlastic
	p.CFrame = cf
	p.CanCollide = false
	p.Anchored = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

-- Flat disc facing forward (used for the pacifier ring and belly patches)
local function frontDisc(diameter, thickness, color, cf, parent)
	local p = Instance.new("Part")
	p.Shape = Enum.PartType.Cylinder
	p.Size = Vector3.new(thickness, diameter, diameter)
	p.Color = color
	p.Material = Enum.Material.SmoothPlastic
	p.CFrame = cf * CFrame.Angles(0, math.rad(90), 0) -- cylinder axis points forward
	p.CanCollide = false
	p.Anchored = false
	p.Parent = parent
	return p
end

local SKIN = Color3.fromRGB(255, 222, 195)
local BLUSH = Color3.fromRGB(255, 150, 160)
local PACIFIER = Color3.fromRGB(255, 130, 160)

--[[
	Builds a chibi hooded baby (~3.2 studs tall) in the concept-art style:
	skin-tone face peeking out of an animal/fruit hood, pacifier, angry
	eyebrows, blush cheeks, and a white diaper. Each beast gets its own
	hood flair (mouse ears, frog eyes, turtle shell, owl tufts, dragon horns).
]]
local function buildBeastModel(beastDef, ownerName)
	local model = Instance.new("Model")
	model.Name = "Beast_" .. beastDef.id

	local origin = CFrame.new(0, 100, 0) -- moved onto a pad right after building
	local hoodColor = beastDef.color

	-- Body (root part) in the hood/onesie color
	local body = ball(1.9, hoodColor, origin, model)
	body.Name = "Body"
	body.CanCollide = true
	model.PrimaryPart = body

	-- White diaper peeking out under the onesie
	local diaper = ball(1.5, Color3.new(1, 1, 1), origin * CFrame.new(0, -0.5, 0), model)
	weldTo(body, diaper)

	-- Big baby head (chibi = head bigger than body) with the hood behind it
	local head = ball(2.1, SKIN, origin * CFrame.new(0, 1.55, -0.15), model)
	weldTo(body, head)
	local hood = ball(2.5, hoodColor, origin * CFrame.new(0, 1.7, 0.4), model)
	weldTo(body, hood)

	-- Face: eyes, ANGRY eyebrows, blush cheeks
	for _, xOffset in ipairs({ -0.45, 0.45 }) do
		local white = ball(0.5, Color3.new(1, 1, 1), origin * CFrame.new(xOffset, 1.68, -1.02), model)
		weldTo(body, white)
		local pupil = ball(0.26, Color3.fromRGB(45, 30, 25), origin * CFrame.new(xOffset, 1.68, -1.2), model)
		weldTo(body, pupil)

		-- Angry brow: inner end tilted down toward the nose
		local browAngle = xOffset < 0 and -0.35 or 0.35
		local brow = box(
			Vector3.new(0.55, 0.1, 0.12),
			Color3.fromRGB(45, 30, 25),
			origin * CFrame.new(xOffset, 2.02, -1.05) * CFrame.Angles(0, 0, browAngle),
			model
		)
		weldTo(body, brow)

		local blush = ball(0.3, BLUSH, origin * CFrame.new(xOffset * 1.75, 1.4, -0.82), model)
		weldTo(body, blush)
	end

	-- Signature pacifier 🍼
	local pacifierRing = frontDisc(0.6, 0.16, PACIFIER, origin * CFrame.new(0, 1.28, -1.1), model)
	weldTo(body, pacifierRing)
	local pacifierKnob = ball(0.3, PACIFIER, origin * CFrame.new(0, 1.28, -1.28), model)
	weldTo(body, pacifierKnob)

	-- Per-beast hood flair so each one is recognizable at a glance
	if beastDef.id == "TaxRat" then
		-- Mouse hood: round gray ears with pink inners
		for _, xOffset in ipairs({ -0.9, 0.9 }) do
			local ear = ball(0.8, hoodColor, origin * CFrame.new(xOffset, 2.8, 0.35), model)
			weldTo(body, ear)
			local inner = ball(0.45, BLUSH, origin * CFrame.new(xOffset, 2.82, 0.1), model)
			weldTo(body, inner)
		end
	elseif beastDef.id == "GoldFrog" then
		-- Gold frog hood (金娃宝宝!): bulgy frog eyes on top + coin on the belly
		for _, xOffset in ipairs({ -0.58, 0.58 }) do
			local frogEye = ball(0.7, hoodColor, origin * CFrame.new(xOffset, 2.9, 0.15), model)
			weldTo(body, frogEye)
			local frogPupil = ball(0.26, Color3.fromRGB(45, 30, 25), origin * CFrame.new(xOffset, 3.0, -0.12), model)
			weldTo(body, frogPupil)
		end
		local coin = frontDisc(0.95, 0.18, Color3.fromRGB(255, 220, 90), origin * CFrame.new(0, 0.05, -0.85), model)
		coin.Material = Enum.Material.Metal
		weldTo(body, coin)
	elseif beastDef.id == "VaultTurtle" then
		-- Turtle hood: shell on the back
		local shell = ball(1.8, Color3.fromRGB(55, 105, 55), origin * CFrame.new(0, 0.3, 0.9), model)
		weldTo(body, shell)
	elseif beastDef.id == "TrustOwl" then
		-- Owl hood: ear tufts, little wings, light belly patch
		for _, xOffset in ipairs({ -0.8, 0.8 }) do
			local tuft = ball(0.45, hoodColor, origin * CFrame.new(xOffset, 3.0, 0.35), model)
			weldTo(body, tuft)
			local wing = ball(0.85, hoodColor, origin * CFrame.new(xOffset * 1.4, 0.3, 0.2), model)
			weldTo(body, wing)
		end
		local belly = frontDisc(0.8, 0.12, Color3.fromRGB(200, 220, 255), origin * CFrame.new(0, 0.15, -0.88), model)
		weldTo(body, belly)
	elseif beastDef.id == "DebtDragon" then
		-- Dragon hood in a tiny business suit: gold horns, shirt + tie, stubby wings
		for _, xOffset in ipairs({ -0.55, 0.55 }) do
			local horn = ball(0.4, Color3.fromRGB(255, 225, 130), origin * CFrame.new(xOffset, 3.0, 0.25), model)
			weldTo(body, horn)
			local wing = ball(0.6, Color3.fromRGB(160, 50, 45), origin * CFrame.new(xOffset * 1.9, 0.5, 0.55), model)
			weldTo(body, wing)
		end
		local shirt = box(Vector3.new(1.2, 0.9, 0.25), Color3.new(1, 1, 1), origin * CFrame.new(0, 0.1, -0.88), model)
		weldTo(body, shirt)
		local tie = box(Vector3.new(0.3, 0.7, 0.14), Color3.new(0, 0, 0), origin * CFrame.new(0, 0, -1.0), model)
		weldTo(body, tie)
	end

	-- Name tag: "Gold Frog · 金娃宝宝" + owner
	local rarityColor = BeastConfig.Rarities[beastDef.rarity].color
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "NameTag"
	billboard.Size = UDim2.new(0, 200, 0, 50)
	billboard.StudsOffset = Vector3.new(0, 3.8, 0)
	billboard.AlwaysOnTop = true
	billboard.MaxDistance = 90
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "BeastName"
	nameLabel.Size = UDim2.new(1, 0, 0.55, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = beastDef.cnName and (beastDef.displayName .. " · " .. beastDef.cnName) or beastDef.displayName
	nameLabel.TextScaled = true
	nameLabel.Font = Enum.Font.FredokaOne
	nameLabel.TextColor3 = rarityColor
	nameLabel.TextStrokeTransparency = 0.2
	nameLabel.Parent = billboard
	local ownerLabel = Instance.new("TextLabel")
	ownerLabel.Name = "OwnerName"
	ownerLabel.Size = UDim2.new(1, 0, 0.45, 0)
	ownerLabel.Position = UDim2.new(0, 0, 0.55, 0)
	ownerLabel.BackgroundTransparency = 1
	ownerLabel.Text = ownerName .. "'s"
	ownerLabel.TextScaled = true
	ownerLabel.Font = Enum.Font.FredokaOne
	ownerLabel.TextColor3 = Color3.new(1, 1, 1)
	ownerLabel.TextStrokeTransparency = 0.4
	ownerLabel.Parent = billboard
	billboard.Parent = body

	-- Freeze in place (unanchored only while being carried)
	body.Anchored = true

	return model
end

-- ============ SLOTS ============

local function isSlotFree(player, slotType, slotIndex)
	for _, record in ipairs(beastsByPlayer[player] or {}) do
		if record.slotType == slotType and record.slotIndex == slotIndex and not record.carriedBy then
			return false
		end
	end
	return true
end

function BeastService.findFreeSlot(player, preferredType)
	local order = preferredType == "vault" and { "vault", "exposed" } or { "exposed", "vault" }
	for _, slotType in ipairs(order) do
		local count = slotType == "exposed" and GameConfig.exposedSlotsPerPlot or GameConfig.vaultSlotsPerPlot
		for slotIndex = 1, count do
			if isSlotFree(player, slotType, slotIndex) then
				return slotType, slotIndex
			end
		end
	end
	return nil
end

local function placeOnPad(record)
	local pad = services.Plot.getPad(record.owner, record.slotType, record.slotIndex)
	if not pad then
		return
	end
	local body = record.model.PrimaryPart
	body.Anchored = true
	record.model:PivotTo(pad.CFrame * CFrame.Angles(0, 0, math.rad(-90)) * CFrame.new(0, 1.6, 0))
end

-- ============ PROMPTS ============

local function updateMovePrompt(record)
	local prompt = record.model.PrimaryPart:FindFirstChild("MovePrompt")
	if prompt then
		prompt.ActionText = record.slotType == "exposed" and "Send to Vault 🔒" or "Send Outside ☀️"
	end
end

local function attachPrompts(record)
	local beastDef = BeastConfig.get(record.beastId)
	local body = record.model.PrimaryPart

	-- Owner prompt (E): move between exposed <-> vault
	local movePrompt = Instance.new("ProximityPrompt")
	movePrompt.Name = "MovePrompt"
	movePrompt.ObjectText = beastDef.displayName
	movePrompt.KeyboardKeyCode = Enum.KeyCode.E
	movePrompt.HoldDuration = 0.3
	movePrompt.MaxActivationDistance = 10
	movePrompt.RequiresLineOfSight = false
	movePrompt.Parent = body
	movePrompt.Triggered:Connect(function(player)
		BeastService.tryMoveBeast(player, record)
	end)

	-- Thief prompt (F): steal (starter Tax Rat can never be stolen)
	if not (record.isStarter and record.beastId == "TaxRat") then
		local stealPrompt = Instance.new("ProximityPrompt")
		stealPrompt.Name = "StealPrompt"
		stealPrompt.ObjectText = beastDef.displayName
		stealPrompt.ActionText = "Steal! 😈"
		stealPrompt.KeyboardKeyCode = Enum.KeyCode.F
		stealPrompt.HoldDuration = beastDef.stealTime
		stealPrompt.MaxActivationDistance = GameConfig.stealMaxDistance
		stealPrompt.RequiresLineOfSight = false
		stealPrompt.Parent = body
		stealPrompt.Triggered:Connect(function(player)
			services.Steal.trySteal(player, record)
		end)
	end

	updateMovePrompt(record)
end

-- The client hides the wrong prompt locally; these attributes tell it who owns what
local function updateAttributes(record)
	local model = record.model
	model:SetAttribute("OwnerUserId", record.owner.UserId)
	model:SetAttribute("BeastId", record.beastId)
	model:SetAttribute("SlotType", record.slotType)
	local ownerLabel = model.PrimaryPart.NameTag:FindFirstChild("OwnerName")
	if ownerLabel then
		ownerLabel.Text = record.owner.DisplayName .. "'s"
	end
end

-- ============ PUBLIC API ============

function BeastService.getBeasts(player)
	return beastsByPlayer[player] or {}
end

function BeastService.getRecordByModel(model)
	return recordByModel[model]
end

-- Gives a beast to a player and places it on a free pad.
-- Returns the record, or nil if the plot is full.
function BeastService.grantBeast(player, beastId, options)
	options = options or {}
	local beastDef = BeastConfig.get(beastId)
	if not beastDef then
		warn("[FB][Beast] Unknown beast id: " .. tostring(beastId))
		return nil
	end
	local slotType, slotIndex = BeastService.findFreeSlot(player, options.preferredType or "exposed")
	if not slotType then
		services.PlayerData.alert(player, "❌ Your base is full! Move something to make room.", "warn")
		return nil
	end

	nextUid += 1
	local record = {
		uid = nextUid,
		beastId = beastId,
		owner = player,
		slotType = slotType,
		slotIndex = slotIndex,
		model = buildBeastModel(beastDef, player.DisplayName),
		isStarter = options.isStarter or false,
		carriedBy = nil,
	}

	beastsByPlayer[player] = beastsByPlayer[player] or {}
	table.insert(beastsByPlayer[player], record)
	recordByModel[record.model] = record

	record.model.Parent = workspace.FB_Map.Beasts
	CollectionService:AddTag(record.model, "FB_Beast")
	updateAttributes(record)
	attachPrompts(record)
	placeOnPad(record)

	dprint(("%s got %s (%s slot %d)"):format(player.Name, beastId, slotType, slotIndex))
	return record
end

-- Owner moves a beast between exposed <-> vault
function BeastService.tryMoveBeast(player, record)
	if record.owner ~= player then
		services.PlayerData.alert(player, "That's not your beast! Hold F to steal it. 😈", "warn")
		return
	end
	if record.carriedBy then
		return -- being stolen right now
	end
	local targetType = record.slotType == "exposed" and "vault" or "exposed"
	local count = targetType == "exposed" and GameConfig.exposedSlotsPerPlot or GameConfig.vaultSlotsPerPlot
	for slotIndex = 1, count do
		if isSlotFree(player, targetType, slotIndex) then
			record.slotType = targetType
			record.slotIndex = slotIndex
			placeOnPad(record)
			updateAttributes(record)
			updateMovePrompt(record)
			local where = targetType == "vault" and "the VAULT (safe, 50% income)"
				or "OUTSIDE (100% income, stealable!)"
			services.PlayerData.alert(
				player,
				"📦 " .. BeastConfig.get(record.beastId).displayName .. " moved to " .. where,
				"info"
			)
			dprint(("%s moved %s to %s %d"):format(player.Name, record.beastId, targetType, slotIndex))
			return
		end
	end
	services.PlayerData.alert(player, "❌ No free " .. targetType .. " slot!", "warn")
end

-- Called by StealService when a thief reaches their capture zone
function BeastService.transferBeast(record, thief)
	local victim = record.owner
	local slotType, slotIndex = BeastService.findFreeSlot(thief, "exposed")
	if not slotType then
		return false -- thief's base is full; keep carrying
	end

	-- Remove from victim's list
	local victimList = beastsByPlayer[victim]
	if victimList then
		for i, r in ipairs(victimList) do
			if r == record then
				table.remove(victimList, i)
				break
			end
		end
	end

	-- Add to thief's list
	record.owner = thief
	record.slotType = slotType
	record.slotIndex = slotIndex
	record.carriedBy = nil
	record.isStarter = false
	beastsByPlayer[thief] = beastsByPlayer[thief] or {}
	table.insert(beastsByPlayer[thief], record)

	updateAttributes(record)
	updateMovePrompt(record)
	placeOnPad(record)
	dprint(("%s now owns %s (stolen from %s)"):format(thief.Name, record.beastId, victim.Name))
	return true
end

-- Put a beast back on its owner's pad (failed steal, thief died, etc.)
function BeastService.returnBeast(record)
	record.carriedBy = nil
	if not isSlotFree(record.owner, record.slotType, record.slotIndex) then
		local slotType, slotIndex = BeastService.findFreeSlot(record.owner, record.slotType)
		if slotType then
			record.slotType = slotType
			record.slotIndex = slotIndex
		end
	end
	placeOnPad(record)
	updateMovePrompt(record)
	dprint(("%s returned home to %s"):format(record.beastId, record.owner.Name))
end

-- ============ LIFECYCLE ============

function BeastService.init(injectedServices)
	services = injectedServices

	local beastsFolder = Instance.new("Folder")
	beastsFolder.Name = "Beasts"
	beastsFolder.Parent = workspace.FB_Map

	-- Starter beasts: Tax Rat (never lost) + Gold Frog (the drama magnet)
	local function giveStarters(player)
		-- Wait until the plot is assigned (PlotService also listens to PlayerAdded)
		task.defer(function()
			local tries = 0
			while not services.Plot.getPlot(player) and tries < 50 do
				task.wait(0.1)
				tries += 1
			end
			if not services.Plot.getPlot(player) then
				return
			end
			BeastService.grantBeast(player, "TaxRat", { isStarter = true })
			BeastService.grantBeast(player, "GoldFrog", { isStarter = true })
			services.PlayerData.alert(
				player,
				"🐭 You got a Tax Rat and a 🐸 Gold Frog! They earn coins every 10s.",
				"gold"
			)
		end)
	end

	Players.PlayerAdded:Connect(giveStarters)
	for _, player in ipairs(Players:GetPlayers()) do
		giveStarters(player)
	end

	Players.PlayerRemoving:Connect(function(player)
		-- Despawn their beasts (no saving in the MVP)
		for _, record in ipairs(beastsByPlayer[player] or {}) do
			recordByModel[record.model] = nil
			record.model:Destroy()
		end
		beastsByPlayer[player] = nil
	end)
end

return BeastService
