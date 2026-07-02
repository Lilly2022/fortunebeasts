--[[
	CaravanService
	The trust-or-betray loop:
	1. A player starts a caravan at the MarketStart pad (ProximityPrompt)
	2. A 2nd player has 20 seconds to join at the same pad
	3. A wagon drives MarketStart -> BridgePoint -> DeliveryPoint
	   - all members must stay within escortDistance or the wagon PAUSES
	4. At the DeliveryPoint:
	   - solo runner: +50 coins, done
	   - two runners: each secretly picks SPLIT FAIR or GRAB EXTRA
	     * both fair    -> 60 coins each, +5 trust each
	     * one betrays  -> 90 for the betrayer, 30 for the victim,
	                       betrayer loses 10 trust + OATHBREAKER mark (10 min)
	     * both betray  -> 40 each, both lose trust, short Oathbreaker
	5. No answer within 30s counts as Split Fair (kindness by default)

	Server authoritative: choices, payouts and trust all resolved here.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local GameConfig = require(ReplicatedStorage.FB_Modules.GameConfig)

local CaravanService = {}

local services
local remotes
local caravan = nil -- current run: { phase, members, wagon, choices }
local cooldownUntil = {} -- [player] = os.clock time

local function dprint(...)
	if GameConfig.debug then
		print("[FB][Caravan]", ...)
	end
end

local function status(text)
	remotes.CaravanStatus:FireAllClients(text)
end

local function memberNames()
	local names = {}
	for _, member in ipairs(caravan.members) do
		table.insert(names, member.DisplayName)
	end
	return table.concat(names, " + ")
end

-- ============ WAGON ============

local function buildWagon(startPosition)
	local model = Instance.new("Model")
	model.Name = "CaravanWagon"

	local base = Instance.new("Part")
	base.Name = "Base"
	base.Size = Vector3.new(5, 2, 8)
	base.Color = Color3.fromRGB(150, 100, 60)
	base.Material = Enum.Material.WoodPlanks
	base.Anchored = true
	base.CFrame = CFrame.new(startPosition + Vector3.new(0, 2, 0))
	base.Parent = model
	model.PrimaryPart = base

	local canopy = Instance.new("Part")
	canopy.Size = Vector3.new(5.4, 2.4, 5)
	canopy.Color = Color3.fromRGB(240, 235, 220)
	canopy.Material = Enum.Material.Fabric
	canopy.Anchored = false
	canopy.CanCollide = false
	canopy.CFrame = base.CFrame * CFrame.new(0, 2.2, 1)
	canopy.Parent = model
	local canopyWeld = Instance.new("WeldConstraint")
	canopyWeld.Part0 = base
	canopyWeld.Part1 = canopy
	canopyWeld.Parent = base

	for _, offset in ipairs({
		Vector3.new(-2.8, -0.6, -2.5),
		Vector3.new(2.8, -0.6, -2.5),
		Vector3.new(-2.8, -0.6, 2.5),
		Vector3.new(2.8, -0.6, 2.5),
	}) do
		local wheel = Instance.new("Part")
		wheel.Shape = Enum.PartType.Cylinder
		wheel.Size = Vector3.new(0.6, 2.4, 2.4)
		wheel.Color = Color3.fromRGB(70, 50, 35)
		wheel.Material = Enum.Material.Wood
		wheel.Anchored = false
		wheel.CanCollide = false
		wheel.CFrame = base.CFrame * CFrame.new(offset)
		wheel.Parent = model
		local wheelWeld = Instance.new("WeldConstraint")
		wheelWeld.Part0 = base
		wheelWeld.Part1 = wheel
		wheelWeld.Parent = base
	end

	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.new(0, 200, 0, 40)
	billboard.StudsOffset = Vector3.new(0, 4, 0)
	billboard.AlwaysOnTop = true
	local text = Instance.new("TextLabel")
	text.Size = UDim2.new(1, 0, 1, 0)
	text.BackgroundTransparency = 1
	text.Text = "🚚 CARAVAN"
	text.TextScaled = true
	text.Font = Enum.Font.FredokaOne
	text.TextColor3 = Color3.fromRGB(255, 220, 120)
	text.TextStrokeTransparency = 0.2
	text.Parent = billboard
	billboard.Parent = base

	model.Parent = workspace.FB_Map
	return model
end

-- ============ OUTCOME ============

local function resolveChoices()
	local a, b = caravan.members[1], caravan.members[2]
	local choiceA = caravan.choices[a] or "fair"
	local choiceB = caravan.choices[b] or "fair"
	dprint(("Choices: %s=%s, %s=%s"):format(a.Name, choiceA, b.Name, choiceB))

	local function award(player, coins, message, kind)
		if player.Parent then
			services.PlayerData.addCoins(player, coins, "caravan")
			services.PlayerData.alert(player, message, kind)
		end
	end

	if choiceA == "fair" and choiceB == "fair" then
		for _, member in ipairs(caravan.members) do
			award(
				member,
				GameConfig.fairSplitEachReward,
				("🤝 Fair split! +%d coins, +%d trust!"):format(
					GameConfig.fairSplitEachReward,
					GameConfig.fairSplitTrustGain
				),
				"gold"
			)
			services.PlayerData.addTrust(member, GameConfig.fairSplitTrustGain, "fair split")
		end
	elseif choiceA == "grab" and choiceB == "grab" then
		for _, member in ipairs(caravan.members) do
			award(
				member,
				GameConfig.bothBetrayEachReward,
				("😈😈 You BOTH tried to grab extra! Only +%d coins each..."):format(
					GameConfig.bothBetrayEachReward
				),
				"warn"
			)
			services.PlayerData.addTrust(member, -GameConfig.betrayalTrustLoss, "double betrayal")
			services.PlayerData.setOathbreaker(member, GameConfig.bothBetrayOathbreakerSeconds)
		end
	else
		local betrayer = choiceA == "grab" and a or b
		local victim = betrayer == a and b or a
		award(
			betrayer,
			GameConfig.betrayerReward,
			("😈 You grabbed extra! +%d coins... but you are now an OATHBREAKER."):format(GameConfig.betrayerReward),
			"warn"
		)
		award(
			victim,
			GameConfig.betrayedReward,
			("💔 %s BETRAYED you! You only got %d coins."):format(betrayer.DisplayName, GameConfig.betrayedReward),
			"raid"
		)
		services.PlayerData.addTrust(betrayer, -GameConfig.betrayalTrustLoss, "betrayal")
		services.PlayerData.setOathbreaker(betrayer, GameConfig.oathbreakerDurationSeconds)
	end
end

-- ============ THE RUN ============

local function runCaravan()
	local route = workspace.FB_Map.CaravanRoute
	local waypoints = {
		route.MarketStart.Position,
		route.BridgePoint.Position,
		route.DeliveryPoint.Position,
	}

	caravan.phase = "traveling"
	status("🚚 Caravan rolling! Escort: " .. memberNames())
	local wagon = buildWagon(waypoints[1])
	caravan.wagon = wagon

	-- Move along the waypoints; pause if any member strays too far
	for segment = 1, #waypoints - 1 do
		local from, to = waypoints[segment], waypoints[segment + 1]
		local length = (to - from).Magnitude
		local progress = 0
		while progress < length do
			local dt = task.wait(0.1)
			-- Drop members who left or died
			for i = #caravan.members, 1, -1 do
				local member = caravan.members[i]
				local root = member.Parent and member.Character and member.Character:FindFirstChild("HumanoidRootPart")
				if not root then
					table.remove(caravan.members, i)
					status("⚠️ " .. member.DisplayName .. " left the caravan!")
				end
			end
			if #caravan.members == 0 then
				status("❌ Caravan abandoned...")
				wagon:Destroy()
				caravan = nil
				return
			end

			-- Everyone close enough?
			local wagonPosition = wagon.PrimaryPart.Position
			local allClose = true
			for _, member in ipairs(caravan.members) do
				local root = member.Character:FindFirstChild("HumanoidRootPart")
				if root and (root.Position - wagonPosition).Magnitude > GameConfig.caravanEscortDistance then
					allClose = false
				end
			end

			if allClose then
				progress = math.min(length, progress + GameConfig.caravanWagonSpeed * dt)
				local position = from:Lerp(to, progress / length)
				wagon:PivotTo(CFrame.lookAt(position + Vector3.new(0, 2, 0), to + Vector3.new(0, 2, 0)))
			else
				status("⏸️ Wagon waiting - stay within " .. GameConfig.caravanEscortDistance .. " studs!")
			end
		end
	end

	-- ============ ARRIVAL ============
	status("📦 Caravan arrived!")
	wagon:Destroy()
	caravan.wagon = nil

	if #caravan.members == 1 then
		local runner = caravan.members[1]
		services.PlayerData.addCoins(runner, GameConfig.soloCaravanReward, "solo caravan")
		services.PlayerData.alert(
			runner,
			("🎉 Solo delivery! +%d coins!"):format(GameConfig.soloCaravanReward),
			"gold"
		)
	else
		-- Two runners: secret choice time
		caravan.phase = "choosing"
		caravan.choices = {}
		for _, member in ipairs(caravan.members) do
			remotes.CaravanChoicePrompt:FireClient(member, GameConfig.caravanChoiceTimeoutSeconds)
		end
		status("🤔 " .. memberNames() .. " are deciding how to split the loot...")

		local deadline = os.clock() + GameConfig.caravanChoiceTimeoutSeconds
		while os.clock() < deadline do
			task.wait(0.25)
			local answered = 0
			for _, member in ipairs(caravan.members) do
				if caravan.choices[member] or not member.Parent then
					answered += 1
				end
			end
			if answered >= #caravan.members then
				break
			end
		end
		resolveChoices()
	end

	for _, member in ipairs(caravan.members) do
		cooldownUntil[member] = os.clock() + GameConfig.caravanCooldownSeconds
	end
	caravan = nil
	task.delay(4, function()
		if not caravan then
			status("")
		end
	end)
end

-- ============ START / JOIN ============

local function onStartPadTriggered(player)
	if cooldownUntil[player] and os.clock() < cooldownUntil[player] then
		services.PlayerData.alert(player, "⏳ Catch your breath! Caravan cooldown for a few more seconds.", "warn")
		return
	end

	if caravan == nil then
		-- Start a new caravan
		caravan = { phase = "gathering", members = { player }, choices = {} }
		services.PlayerData.alertAll(
			("🚩 %s started a caravan! Join at the market within %d seconds!"):format(
				player.DisplayName,
				GameConfig.caravanJoinWindowSeconds
			),
			"info"
		)
		dprint(player.Name .. " started a caravan")

		task.spawn(function()
			for remaining = GameConfig.caravanJoinWindowSeconds, 1, -1 do
				if caravan == nil or caravan.phase ~= "gathering" then
					return
				end
				status(
					("🚩 Caravan leaving in %ds - %d/2 aboard (%s)"):format(
						remaining,
						#caravan.members,
						memberNames()
					)
				)
				task.wait(1)
			end
			if caravan and caravan.phase == "gathering" then
				runCaravan()
			end
		end)
	elseif caravan.phase == "gathering" then
		for _, member in ipairs(caravan.members) do
			if member == player then
				services.PlayerData.alert(player, "You're already in this caravan!", "info")
				return
			end
		end
		if #caravan.members >= 2 then
			services.PlayerData.alert(player, "❌ This caravan is full (2 players max in the MVP).", "warn")
			return
		end
		table.insert(caravan.members, player)
		services.PlayerData.alertAll(("🚚 %s joined the caravan! Rolling out!"):format(player.DisplayName), "info")
		dprint(player.Name .. " joined the caravan")
		-- Full crew: leave immediately
		task.spawn(runCaravan)
	else
		services.PlayerData.alert(player, "🚚 A caravan is already on the road. Wait for the next one!", "warn")
	end
end

-- ============ LIFECYCLE ============

function CaravanService.init(injectedServices)
	services = injectedServices
	remotes = ReplicatedStorage:WaitForChild("FB_Remotes")

	-- Start/Join prompt on the MarketStart pad
	local startPad = workspace.FB_Map.CaravanRoute.MarketStart
	local prompt = Instance.new("ProximityPrompt")
	prompt.ObjectText = "Caravan"
	prompt.ActionText = "Start / Join Caravan"
	prompt.HoldDuration = 0.5
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.Parent = startPad
	prompt.Triggered:Connect(onStartPadTriggered)

	-- Receive Split Fair / Grab Extra answers
	remotes.CaravanChoice.OnServerEvent:Connect(function(player, choice)
		if caravan and caravan.phase == "choosing" then
			for _, member in ipairs(caravan.members) do
				if member == player and not caravan.choices[player] then
					-- Only "fair" or "grab" are valid; anything else = fair
					caravan.choices[player] = (choice == "grab") and "grab" or "fair"
					dprint(player.Name .. " chose: " .. caravan.choices[player])
				end
			end
		end
	end)

	Players.PlayerRemoving:Connect(function(player)
		cooldownUntil[player] = nil
	end)
end

return CaravanService
