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

local DARK = Color3.fromRGB(45, 30, 25)

local function darker(color, factor)
	return Color3.new(color.R * factor, color.G * factor, color.B * factor)
end

local function lighter(color, amount)
	return color:Lerp(Color3.new(1, 1, 1), amount)
end

-- Deterministic per-baby cosmetic jitter (same look on every server)
local function hashString(text)
	local hash = 0
	for i = 1, #text do
		hash = (hash * 31 + string.byte(text, i)) % 2147483647
	end
	return hash
end

-- ============ HOOD FLAIRS (one per species family) ============
-- Every builder receives ctx = { model, body, origin, hood } and welds to body.

local FLAIRS = {}

FLAIRS.roundEars = function(ctx)
	for _, x in ipairs({ -0.9, 0.9 }) do
		weldTo(ctx.body, ball(0.8, ctx.hood, ctx.origin * CFrame.new(x, 2.8, 0.35), ctx.model))
		weldTo(ctx.body, ball(0.45, BLUSH, ctx.origin * CFrame.new(x, 2.82, 0.12), ctx.model))
	end
end

FLAIRS.frogEyes = function(ctx)
	for _, x in ipairs({ -0.58, 0.58 }) do
		weldTo(ctx.body, ball(0.7, ctx.hood, ctx.origin * CFrame.new(x, 2.9, 0.15), ctx.model))
		weldTo(ctx.body, ball(0.26, DARK, ctx.origin * CFrame.new(x, 3.0, -0.12), ctx.model))
	end
end

FLAIRS.shell = function(ctx)
	weldTo(ctx.body, ball(1.8, darker(ctx.hood, 0.6), ctx.origin * CFrame.new(0, 0.3, 0.9), ctx.model))
end

FLAIRS.owl = function(ctx)
	for _, x in ipairs({ -0.8, 0.8 }) do
		weldTo(ctx.body, ball(0.45, ctx.hood, ctx.origin * CFrame.new(x, 3.0, 0.35), ctx.model))
		weldTo(ctx.body, ball(0.85, ctx.hood, ctx.origin * CFrame.new(x * 1.4, 0.3, 0.2), ctx.model))
	end
end

FLAIRS.dragon = function(ctx)
	for _, x in ipairs({ -0.55, 0.55 }) do
		weldTo(ctx.body, ball(0.4, Color3.fromRGB(255, 225, 130), ctx.origin * CFrame.new(x, 3.0, 0.25), ctx.model))
		weldTo(ctx.body, ball(0.6, darker(ctx.hood, 0.7), ctx.origin * CFrame.new(x * 1.9, 0.5, 0.55), ctx.model))
	end
end

FLAIRS.catEars = function(ctx)
	for _, x in ipairs({ -0.78, 0.78 }) do
		weldTo(ctx.body, ball(0.55, ctx.hood, ctx.origin * CFrame.new(x, 2.98, 0.3), ctx.model))
		weldTo(ctx.body, ball(0.3, BLUSH, ctx.origin * CFrame.new(x, 3.0, 0.12), ctx.model))
	end
end

FLAIRS.bunnyEars = function(ctx)
	for _, x in ipairs({ -0.55, 0.55 }) do
		weldTo(ctx.body, ball(0.5, ctx.hood, ctx.origin * CFrame.new(x, 3.0, 0.3), ctx.model))
		weldTo(ctx.body, ball(0.45, ctx.hood, ctx.origin * CFrame.new(x, 3.45, 0.3), ctx.model))
	end
end

FLAIRS.pandaEars = function(ctx)
	local black = Color3.fromRGB(35, 35, 40)
	for _, x in ipairs({ -0.9, 0.9 }) do
		weldTo(ctx.body, ball(0.75, black, ctx.origin * CFrame.new(x, 2.8, 0.35), ctx.model))
		-- Panda eye patches behind the eye whites
		weldTo(ctx.body, ball(0.6, black, ctx.origin * CFrame.new(x * 0.5, 1.72, -0.9), ctx.model))
	end
end

FLAIRS.duck = function(ctx)
	weldTo(ctx.body, ball(0.3, Color3.fromRGB(245, 150, 50), ctx.origin * CFrame.new(0, 3.1, 0.25), ctx.model))
	for _, x in ipairs({ -1.05, 1.05 }) do
		weldTo(ctx.body, ball(0.7, ctx.hood, ctx.origin * CFrame.new(x, 0.35, 0.25), ctx.model))
	end
end

FLAIRS.mane = function(ctx)
	local maneColor = darker(ctx.hood, 0.72)
	for i = 0, 7 do
		local angle = math.rad(i * 45)
		local x = math.cos(angle) * 1.15
		local y = 1.7 + math.sin(angle) * 1.15
		weldTo(ctx.body, ball(0.6, maneColor, ctx.origin * CFrame.new(x, y, -0.3), ctx.model))
	end
end

FLAIRS.stem = function(ctx)
	weldTo(
		ctx.body,
		box(Vector3.new(0.22, 0.5, 0.22), Color3.fromRGB(110, 75, 50), ctx.origin * CFrame.new(0, 3.15, 0.3), ctx.model)
	)
	weldTo(ctx.body, ball(0.45, Color3.fromRGB(110, 180, 70), ctx.origin * CFrame.new(0.42, 3.2, 0.3), ctx.model))
end

FLAIRS.spikes = function(ctx)
	local spikeColor = Color3.fromRGB(120, 200, 90)
	for _, offset in ipairs({
		Vector3.new(0, 3.1, 0.3),
		Vector3.new(-0.62, 2.9, 0.2),
		Vector3.new(0.62, 2.9, 0.2),
		Vector3.new(-0.32, 3.0, 0.7),
		Vector3.new(0.32, 3.0, 0.7),
	}) do
		weldTo(ctx.body, ball(0.38, spikeColor, ctx.origin * CFrame.new(offset), ctx.model))
	end
end

-- ============ ACCESSORIES ============

local ACCESSORY_BUILDERS = {}

ACCESSORY_BUILDERS.suit = function(ctx)
	weldTo(
		ctx.body,
		box(Vector3.new(1.2, 0.9, 0.25), Color3.new(1, 1, 1), ctx.origin * CFrame.new(0, 0.1, -0.88), ctx.model)
	)
	weldTo(
		ctx.body,
		box(Vector3.new(0.3, 0.7, 0.14), Color3.new(0, 0, 0), ctx.origin * CFrame.new(0, 0, -1.0), ctx.model)
	)
end

ACCESSORY_BUILDERS.coinBelly = function(ctx)
	local coin = frontDisc(0.95, 0.18, Color3.fromRGB(255, 220, 90), ctx.origin * CFrame.new(0, 0.05, -0.85), ctx.model)
	coin.Material = Enum.Material.Metal
	weldTo(ctx.body, coin)
end

ACCESSORY_BUILDERS.bowtie = function(ctx)
	local red = Color3.fromRGB(200, 50, 60)
	weldTo(ctx.body, box(Vector3.new(0.55, 0.28, 0.2), red, ctx.origin * CFrame.new(0, 0.82, -0.85), ctx.model))
	weldTo(ctx.body, ball(0.18, darker(red, 0.7), ctx.origin * CFrame.new(0, 0.82, -0.95), ctx.model))
end

ACCESSORY_BUILDERS.glasses = function(ctx)
	local frame = Color3.fromRGB(40, 40, 45)
	for _, x in ipairs({ -0.45, 0.45 }) do
		local lens = frontDisc(0.55, 0.1, frame, ctx.origin * CFrame.new(x, 1.68, -1.16), ctx.model)
		lens.Transparency = 0.35
		weldTo(ctx.body, lens)
	end
	weldTo(ctx.body, box(Vector3.new(0.32, 0.08, 0.08), frame, ctx.origin * CFrame.new(0, 1.68, -1.16), ctx.model))
end

ACCESSORY_BUILDERS.headband = function(ctx)
	weldTo(
		ctx.body,
		box(Vector3.new(1.5, 0.26, 0.22), Color3.fromRGB(210, 60, 60), ctx.origin * CFrame.new(0, 2.3, -0.9), ctx.model)
	)
end

ACCESSORY_BUILDERS.headphones = function(ctx)
	local dark = Color3.fromRGB(50, 50, 55)
	for _, x in ipairs({ -1.08, 1.08 }) do
		weldTo(ctx.body, ball(0.5, dark, ctx.origin * CFrame.new(x, 1.75, -0.15), ctx.model))
	end
	weldTo(ctx.body, box(Vector3.new(2.25, 0.14, 0.14), dark, ctx.origin * CFrame.new(0, 2.95, -0.15), ctx.model))
end

ACCESSORY_BUILDERS.crown = function(ctx)
	local gold = Color3.fromRGB(255, 210, 70)
	local ring = Instance.new("Part")
	ring.Shape = Enum.PartType.Cylinder
	ring.Size = Vector3.new(0.4, 0.95, 0.95)
	ring.Color = gold
	ring.Material = Enum.Material.Metal
	ring.CanCollide = false
	ring.CFrame = ctx.origin * CFrame.new(0, 3.25, 0.15) * CFrame.Angles(0, 0, math.rad(90))
	ring.Parent = ctx.model
	weldTo(ctx.body, ring)
	local gem = ball(0.22, Color3.fromRGB(255, 90, 90), ctx.origin * CFrame.new(0, 3.55, 0.15), ctx.model)
	gem.Material = Enum.Material.Neon
	weldTo(ctx.body, gem)
end

--[[
	Builds a chibi hooded baby (~3.2 studs tall) in the concept-art style:
	skin-tone face peeking out of an animal/fruit hood with a darker hood rim,
	pacifier, angry eyebrows, blush cheeks, and a white diaper.
	Distinctiveness comes from: species flair + accessory + belly patch +
	per-baby color/eye jitter + physical size that grows with rarity.
]]
local function buildBeastModel(beastDef, ownerName)
	local model = Instance.new("Model")
	model.Name = "Beast_" .. beastDef.id

	local origin = CFrame.new(0, 100, 0) -- moved onto a pad right after building
	local hoodColor = beastDef.color
	-- Cosmetic jitter seeded by the beast id: consistent everywhere
	local rng = Random.new(hashString(beastDef.id))

	-- Body (root part) in the hood/onesie color
	local body = ball(1.9, hoodColor, origin, model)
	body.Name = "Body"
	body.CanCollide = true
	model.PrimaryPart = body

	-- White diaper peeking out under the onesie
	local diaper = ball(1.5, Color3.new(1, 1, 1), origin * CFrame.new(0, -0.5, 0), model)
	weldTo(body, diaper)

	-- Big baby head (chibi = head bigger than body), hood behind it,
	-- and a darker hood rim framing the face like the concept art
	local head = ball(2.1, SKIN, origin * CFrame.new(0, 1.55, -0.15), model)
	weldTo(body, head)
	local hood = ball(2.5, hoodColor, origin * CFrame.new(0, 1.7, 0.4), model)
	weldTo(body, hood)
	local rim = frontDisc(2.35, 0.35, darker(hoodColor, 0.72), origin * CFrame.new(0, 1.7, -0.72), model)
	weldTo(body, rim)

	-- Face: eyes, ANGRY eyebrows, blush cheeks (each baby slightly different)
	local pupilSize = 0.22 + rng:NextNumber() * 0.08
	local browTilt = 0.25 + rng:NextNumber() * 0.2
	for _, xOffset in ipairs({ -0.45, 0.45 }) do
		local white = ball(0.5, Color3.new(1, 1, 1), origin * CFrame.new(xOffset, 1.68, -1.02), model)
		weldTo(body, white)
		local pupil = ball(pupilSize, DARK, origin * CFrame.new(xOffset, 1.68, -1.2), model)
		weldTo(body, pupil)

		-- Angry brow: inner end tilted down toward the nose
		local browAngle = xOffset < 0 and -browTilt or browTilt
		local brow = box(
			Vector3.new(0.55, 0.1, 0.12),
			DARK,
			origin * CFrame.new(xOffset, 2.02, -1.05) * CFrame.Angles(0, 0, browAngle),
			model
		)
		weldTo(body, brow)

		local blush = ball(0.3, BLUSH, origin * CFrame.new(xOffset * 1.75, 1.4, -0.82), model)
		weldTo(body, blush)
	end

	-- Signature pacifier 🍼 (a few color varieties)
	local pacifierColors = { PACIFIER, PACIFIER, Color3.fromRGB(130, 190, 255), Color3.fromRGB(150, 230, 190) }
	local pacifierColor = pacifierColors[rng:NextInteger(1, #pacifierColors)]
	weldTo(body, frontDisc(0.6, 0.16, pacifierColor, origin * CFrame.new(0, 1.28, -1.1), model))
	weldTo(body, ball(0.3, pacifierColor, origin * CFrame.new(0, 1.28, -1.28), model))

	local ctx = { model = model, body = body, origin = origin, hood = hoodColor }

	-- Lighter belly patch (some babies), unless an accessory covers the belly
	if beastDef.belly and beastDef.accessory ~= "suit" and beastDef.accessory ~= "coinBelly" then
		weldTo(body, frontDisc(0.85, 0.12, lighter(hoodColor, 0.55), origin * CFrame.new(0, 0.12, -0.88), model))
	end

	-- Species hood flair + accessory
	local flairBuilder = FLAIRS[beastDef.flair]
	if flairBuilder then
		flairBuilder(ctx)
	end
	local accessoryBuilder = beastDef.accessory and ACCESSORY_BUILDERS[beastDef.accessory]
	if accessoryBuilder then
		accessoryBuilder(ctx)
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

	-- Rarer babies are bigger! (Legendary ~1.28x)
	if beastDef.sizeScale and beastDef.sizeScale ~= 1 then
		pcall(function()
			model:ScaleTo(beastDef.sizeScale)
		end)
	end

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
	-- Bigger (rarer) babies sit a little higher so they don't clip the pad
	local scale = BeastConfig.get(record.beastId).sizeScale or 1
	record.model:PivotTo(pad.CFrame * CFrame.Angles(0, 0, math.rad(-90)) * CFrame.new(0, 1.45 * scale + 0.25, 0))
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

	-- Collection tracking: first time owning this exact baby = NEW discovery!
	local isNew, count = services.PlayerData.markDiscovered(player, beastId)
	if isNew then
		services.PlayerData.alert(
			player,
			("✨ NEW! %s (%s) — Collection %d/%d"):format(
				beastDef.displayName,
				beastDef.rarity,
				count,
				BeastConfig.TotalCollectible
			),
			"gold"
		)
	end

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
