--[[
	MarketService
	Three little stalls at the center market:
	- Vault Turtle (60 coins) - slow to steal, protects value
	- Trust Owl (80 coins) - boosts caravan trust vibes
	- Debt Dragon (FREE + instant 100 coins... but takes 20% of income forever)

	Buying uses a ProximityPrompt. All payment checks happen on the server.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.FB_Modules.GameConfig)
local BeastConfig = require(ReplicatedStorage.FB_Modules.BeastConfig)

local MarketService = {}

local services

local function dprint(...)
	if GameConfig.debug then
		print("[FB][Market]", ...)
	end
end

local function buyBeast(player, beastId)
	local price = GameConfig.marketPrices[beastId] or 0
	local beastDef = BeastConfig.get(beastId)

	-- Check there's room BEFORE charging
	if not services.Beast.findFreeSlot(player, "exposed") then
		services.PlayerData.alert(player, "❌ Your base is full!", "warn")
		return
	end
	if price > 0 and not services.PlayerData.trySpendCoins(player, price, "bought " .. beastId) then
		services.PlayerData.alert(
			player,
			("❌ Not enough coins! %s costs %d."):format(beastDef.displayName, price),
			"warn"
		)
		return
	end

	local record = services.Beast.grantBeast(player, beastId)
	if not record then
		-- Refund if placement somehow failed
		if price > 0 then
			services.PlayerData.addCoins(player, price, "refund")
		end
		return
	end

	if beastDef.instantCoins then
		services.PlayerData.addCoins(player, beastDef.instantCoins, "Debt Dragon signing bonus")
		services.PlayerData.alert(
			player,
			("🐉 Debt Dragon pays you %d coins NOW... but takes %d%% of your income from now on!"):format(
				beastDef.instantCoins,
				beastDef.debtPercent * 100
			),
			"warn"
		)
	else
		services.PlayerData.alert(player, "🎉 You bought a " .. beastDef.displayName .. "!", "gold")
	end
	dprint(("%s bought %s for %d"):format(player.Name, beastId, price))
end

local function buildStall(index, beastId)
	local beastDef = BeastConfig.get(beastId)
	local price = GameConfig.marketPrices[beastId] or 0

	local angle = math.rad(120 + index * 40)
	local position = Vector3.new(math.cos(angle) * 22, 0, math.sin(angle) * 22)

	local stall = Instance.new("Part")
	stall.Name = "Stall_" .. beastId
	stall.Anchored = true
	stall.Size = Vector3.new(6, 4, 4)
	stall.CFrame = CFrame.lookAt(position + Vector3.new(0, 2, 0), Vector3.new(0, 2, 0))
	stall.Color = beastDef.color
	stall.Material = Enum.Material.SmoothPlastic

	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.new(0, 220, 0, 60)
	billboard.StudsOffset = Vector3.new(0, 4, 0)
	billboard.AlwaysOnTop = true
	billboard.MaxDistance = 100
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, 0, 0.5, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = beastDef.displayName
	nameLabel.TextScaled = true
	nameLabel.Font = Enum.Font.FredokaOne
	nameLabel.TextColor3 = BeastConfig.Rarities[beastDef.rarity].color
	nameLabel.TextStrokeTransparency = 0.2
	nameLabel.Parent = billboard
	local priceLabel = Instance.new("TextLabel")
	priceLabel.Size = UDim2.new(1, 0, 0.5, 0)
	priceLabel.Position = UDim2.new(0, 0, 0.5, 0)
	priceLabel.BackgroundTransparency = 1
	priceLabel.Text = price > 0 and ("🪙 %d coins"):format(price) or "🆓 FREE (+100 now!)"
	priceLabel.TextScaled = true
	priceLabel.Font = Enum.Font.FredokaOne
	priceLabel.TextColor3 = Color3.new(1, 1, 1)
	priceLabel.TextStrokeTransparency = 0.3
	priceLabel.Parent = billboard
	billboard.Parent = stall

	local prompt = Instance.new("ProximityPrompt")
	prompt.ObjectText = beastDef.displayName
	prompt.ActionText = price > 0 and ("Buy (%d)"):format(price) or "Take the deal 🐉"
	prompt.HoldDuration = 0.5
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Parent = stall
	prompt.Triggered:Connect(function(player)
		buyBeast(player, beastId)
	end)

	stall.Parent = workspace.FB_Map.Market
end

-- ============ MYSTERY EGG (hatch one of 300 collectible babies) ============

local function hatchEgg(player)
	if not services.Beast.findFreeSlot(player, "exposed") then
		services.PlayerData.alert(player, "❌ Your base is full!", "warn")
		return
	end
	if not services.PlayerData.trySpendCoins(player, GameConfig.hatchPrice, "Mystery Egg") then
		services.PlayerData.alert(
			player,
			("❌ Not enough coins! An egg costs %d."):format(GameConfig.hatchPrice),
			"warn"
		)
		return
	end

	local def = BeastConfig.rollHatch()
	local record = services.Beast.grantBeast(player, def.id)
	if not record then
		services.PlayerData.addCoins(player, GameConfig.hatchPrice, "refund")
		return
	end

	local flourish = def.rarity == "Legendary" and "🌟 LEGENDARY!!! " or def.rarity == "Epic" and "💜 EPIC! " or ""
	services.PlayerData.alert(
		player,
		("🥚 %sYou hatched %s · %s (%s)!"):format(flourish, def.displayName, def.cnName, def.rarity),
		def.rarity == "Common" and "info" or "gold"
	)
	if def.rarity == "Legendary" then
		services.PlayerData.alertAll(
			("🌟 %s hatched a LEGENDARY %s!"):format(player.DisplayName, def.displayName),
			"gold"
		)
	end
	dprint(("%s hatched %s (%s)"):format(player.Name, def.id, def.rarity))
end

local function buildHatchStand()
	-- A big wobbly egg on a pedestal at the market
	local pedestal = Instance.new("Part")
	pedestal.Name = "HatchStand"
	pedestal.Shape = Enum.PartType.Cylinder
	pedestal.Size = Vector3.new(1, 10, 10)
	pedestal.Color = Color3.fromRGB(250, 220, 240)
	pedestal.Material = Enum.Material.SmoothPlastic
	pedestal.Anchored = true
	local angle = math.rad(80)
	pedestal.CFrame = CFrame.new(math.cos(angle) * 22, 0.6, math.sin(angle) * 22) * CFrame.Angles(0, 0, math.rad(90))

	local egg = Instance.new("Part")
	egg.Shape = Enum.PartType.Ball
	egg.Size = Vector3.new(4, 4, 4)
	egg.Color = Color3.new(1, 1, 1)
	egg.Material = Enum.Material.Marble
	egg.Anchored = true
	egg.CanCollide = false
	egg.CFrame = pedestal.CFrame * CFrame.new(0, 0, 0) + Vector3.new(0, 2.6, 0)
	egg.Parent = pedestal

	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.new(0, 240, 0, 66)
	billboard.StudsOffset = Vector3.new(0, 4.5, 0)
	billboard.AlwaysOnTop = true
	billboard.MaxDistance = 120
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, 0, 0.5, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = "🥚 MYSTERY EGG"
	nameLabel.TextScaled = true
	nameLabel.Font = Enum.Font.FredokaOne
	nameLabel.TextColor3 = Color3.fromRGB(255, 220, 120)
	nameLabel.TextStrokeTransparency = 0.2
	nameLabel.Parent = billboard
	local infoLabel = Instance.new("TextLabel")
	infoLabel.Size = UDim2.new(1, 0, 0.5, 0)
	infoLabel.Position = UDim2.new(0, 0, 0.5, 0)
	infoLabel.BackgroundTransparency = 1
	infoLabel.Text = ("%d babies to collect! 🪙 %d"):format(BeastConfig.TotalCollectible, GameConfig.hatchPrice)
	infoLabel.TextScaled = true
	infoLabel.Font = Enum.Font.FredokaOne
	infoLabel.TextColor3 = Color3.new(1, 1, 1)
	infoLabel.TextStrokeTransparency = 0.3
	infoLabel.Parent = billboard
	billboard.Parent = egg

	local prompt = Instance.new("ProximityPrompt")
	prompt.ObjectText = "Mystery Egg"
	prompt.ActionText = ("Hatch! (%d)"):format(GameConfig.hatchPrice)
	prompt.HoldDuration = 0.8
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.Parent = egg
	prompt.Triggered:Connect(hatchEgg)

	pedestal.Parent = workspace.FB_Map.Market
end

function MarketService.init(injectedServices)
	services = injectedServices
	for index, beastId in ipairs(BeastConfig.MarketOrder) do
		buildStall(index, beastId)
	end
	buildHatchStand()
	dprint(("Market stalls + Mystery Egg built (%d babies in catalog)"):format(#BeastConfig.Catalog))
end

return MarketService
