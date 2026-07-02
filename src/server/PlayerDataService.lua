--[[
	PlayerDataService
	The single source of truth for every player's session data:
	coins, trust, beginner/post-theft protection, and Oathbreaker status.

	Also owns leaderstats (Coins + Trust show on the Roblox player list)
	and pushes state snapshots to the client HUD.

	NOTE: MVP has no saving between sessions on purpose (keeps testing
	simple and safe). DataStore saving is a later step - see docs/ROADMAP.md.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.FB_Modules.GameConfig)

local PlayerDataService = {}

local data = {} -- [player] = { coins, trust, joinedAt, protectedUntil, oathbreakerUntil }
local remotes

local function dprint(...)
	if GameConfig.debug then
		print("[FB][Data]", ...)
	end
end

-- ============ INTERNAL ============

local function pushState(player)
	local record = data[player]
	if not record then
		return
	end
	local now = os.clock()
	remotes.State:FireClient(player, {
		coins = record.coins,
		trust = record.trust,
		protectedSecondsLeft = math.max(0, math.ceil(record.protectedUntil - now)),
		oathbreakerSecondsLeft = math.max(0, math.ceil(record.oathbreakerUntil - now)),
		collectionCount = record.collectionCount,
	})
end

local function updateLeaderstats(player)
	local record = data[player]
	local stats = player:FindFirstChild("leaderstats")
	if record and stats then
		stats.Coins.Value = record.coins
		stats.Trust.Value = record.trust
	end
end

local function applyOathbreakerTag(player)
	-- Floating skull tag over the betrayer's head so everyone can see it
	local character = player.Character
	local record = data[player]
	if not character or not record then
		return
	end
	local head = character:FindFirstChild("Head")
	if not head then
		return
	end
	local existing = head:FindFirstChild("FB_OathbreakerTag")
	local active = record.oathbreakerUntil > os.clock()
	if active and not existing then
		local billboard = Instance.new("BillboardGui")
		billboard.Name = "FB_OathbreakerTag"
		billboard.Size = UDim2.new(0, 200, 0, 34)
		billboard.StudsOffset = Vector3.new(0, 2.6, 0)
		billboard.AlwaysOnTop = true
		local text = Instance.new("TextLabel")
		text.Size = UDim2.new(1, 0, 1, 0)
		text.BackgroundTransparency = 1
		text.Text = "💀 OATHBREAKER"
		text.TextScaled = true
		text.Font = Enum.Font.FredokaOne
		text.TextColor3 = Color3.fromRGB(255, 80, 80)
		text.TextStrokeTransparency = 0.2
		text.Parent = billboard
		billboard.Parent = head
	elseif not active and existing then
		existing:Destroy()
	end
end

-- ============ PUBLIC API ============

function PlayerDataService.get(player)
	return data[player]
end

function PlayerDataService.getCoins(player)
	local record = data[player]
	return record and record.coins or 0
end

function PlayerDataService.addCoins(player, amount, reason)
	local record = data[player]
	if not record then
		return
	end
	record.coins = math.max(0, record.coins + amount)
	updateLeaderstats(player)
	pushState(player)
	dprint(("%s %+d coins (%s) -> %d"):format(player.Name, amount, reason or "?", record.coins))
end

function PlayerDataService.trySpendCoins(player, amount, reason)
	local record = data[player]
	if not record or record.coins < amount then
		return false
	end
	record.coins -= amount
	updateLeaderstats(player)
	pushState(player)
	dprint(("%s spent %d coins (%s) -> %d"):format(player.Name, amount, reason or "?", record.coins))
	return true
end

function PlayerDataService.addTrust(player, amount, reason)
	local record = data[player]
	if not record then
		return
	end
	record.trust += amount
	updateLeaderstats(player)
	pushState(player)
	dprint(("%s %+d trust (%s) -> %d"):format(player.Name, amount, reason or "?", record.trust))
end

-- True while the player cannot be robbed (beginner or post-theft protection)
function PlayerDataService.isProtected(player)
	local record = data[player]
	return record ~= nil and record.protectedUntil > os.clock()
end

function PlayerDataService.giveProtection(player, seconds, reason)
	local record = data[player]
	if not record then
		return
	end
	record.protectedUntil = math.max(record.protectedUntil, os.clock() + seconds)
	pushState(player)
	dprint(("%s protected for %ds (%s)"):format(player.Name, seconds, reason or "?"))
end

-- Records that this player has owned this beast type at least once.
-- Returns (isNew, totalDiscovered).
function PlayerDataService.markDiscovered(player, beastId)
	local record = data[player]
	if not record then
		return false, 0
	end
	if record.collection[beastId] then
		return false, record.collectionCount
	end
	record.collection[beastId] = true
	record.collectionCount += 1
	pushState(player)
	dprint(("%s discovered %s (collection: %d)"):format(player.Name, beastId, record.collectionCount))
	return true, record.collectionCount
end

function PlayerDataService.isOathbreaker(player)
	local record = data[player]
	return record ~= nil and record.oathbreakerUntil > os.clock()
end

function PlayerDataService.setOathbreaker(player, seconds)
	local record = data[player]
	if not record then
		return
	end
	record.oathbreakerUntil = os.clock() + seconds
	applyOathbreakerTag(player)
	pushState(player)
	dprint(("%s is now an OATHBREAKER for %ds"):format(player.Name, seconds))
	-- Remove the tag automatically when the mark expires
	task.delay(seconds + 1, function()
		if player.Parent then
			applyOathbreakerTag(player)
			pushState(player)
		end
	end)
end

function PlayerDataService.alert(player, message, kind)
	-- kind: "info" | "raid" | "gold" | "warn" (client picks the color)
	remotes.Alert:FireClient(player, message, kind or "info")
end

function PlayerDataService.alertAll(message, kind)
	remotes.Alert:FireAllClients(message, kind or "info")
end

function PlayerDataService.pushState(player)
	pushState(player)
end

-- ============ LIFECYCLE ============

function PlayerDataService.init(_services)
	remotes = ReplicatedStorage:WaitForChild("FB_Remotes")

	local function onPlayerAdded(player)
		data[player] = {
			coins = GameConfig.startingCoins,
			trust = 0,
			joinedAt = os.clock(),
			protectedUntil = os.clock() + GameConfig.beginnerProtectionSeconds,
			oathbreakerUntil = 0,
			collection = {}, -- [beastId] = true for every beast ever owned
			collectionCount = 0,
		}

		-- Leaderstats: shows Coins + Trust in the Roblox player list
		local stats = Instance.new("Folder")
		stats.Name = "leaderstats"
		local coins = Instance.new("IntValue")
		coins.Name = "Coins"
		coins.Value = GameConfig.startingCoins
		coins.Parent = stats
		local trust = Instance.new("IntValue")
		trust.Name = "Trust"
		trust.Value = 0
		trust.Parent = stats
		stats.Parent = player

		player.CharacterAdded:Connect(function()
			task.wait(0.5)
			applyOathbreakerTag(player)
			pushState(player)
		end)

		pushState(player)
		PlayerDataService.alert(player, "🛡️ Beginner protection: nobody can rob you for 3 minutes!", "info")
		dprint(player.Name .. " joined. Starting coins:", GameConfig.startingCoins)
	end

	Players.PlayerAdded:Connect(onPlayerAdded)
	for _, player in ipairs(Players:GetPlayers()) do
		onPlayerAdded(player)
	end

	Players.PlayerRemoving:Connect(function(player)
		data[player] = nil
		dprint(player.Name .. " left, session data cleared")
	end)
end

return PlayerDataService
