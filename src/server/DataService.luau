--!strict
-- Player profile storage. Loads from a DataStore (with a safe in-memory fallback
-- so the game still runs in Studio without API access enabled), grants offline
-- earnings on join, and auto-saves. Other services mutate the profile in memory
-- and call DataService.markDirty / push.

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local GameConfig = require(Shared.GameConfig)
local BabyData = require(Shared.BabyData)
local Net = require(Shared.Net)
local Util = require(Shared.Util)
local Types = require(Shared.Types)

type Profile = Types.Profile

local DataService = {}

local profiles: { [Player]: Profile } = {}
local dirty: { [Player]: boolean } = {}

local store: DataStore? = nil
do
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore(GameConfig.DataStoreName)
	end)
	if ok then
		store = result
	else
		warn("[DataService] DataStore unavailable, using in-memory profiles:", result)
	end
end

local function defaultProfile(): Profile
	return {
		coins = GameConfig.StartingCoins,
		trust = GameConfig.StartingTrust,
		infamy = 0,
		babies = {},
		ownedVehicles = { "cart" },
		activeCaravan = nil,
		collectedIds = {},
		lastSeen = os.time(),
		stats = {
			babiesHatched = 0,
			caravansCompleted = 0,
			betrayals = 0,
			timesRaided = 0,
		},
	}
end

-- Fill in any fields a saved profile from an older version is missing.
local function reconcile(p: Profile): Profile
	local base = defaultProfile()
	for key, value in base :: any do
		if (p :: any)[key] == nil then
			(p :: any)[key] = value
		end
	end
	if type(p.stats) ~= "table" then
		p.stats = base.stats
	else
		for key, value in base.stats :: any do
			if (p.stats :: any)[key] == nil then
				(p.stats :: any)[key] = value
			end
		end
	end
	return p
end

-- Coins earned while the player was offline, capped and rate-reduced.
local function grantOfflineEarnings(p: Profile)
	if not GameConfig.OfflineIncomeEnabled then
		return
	end
	local elapsed = math.max(0, os.time() - (p.lastSeen or os.time()))
	elapsed = math.min(elapsed, GameConfig.OfflineIncomeCapSeconds)
	if elapsed <= 0 then
		return
	end
	local perSecond = 0
	for _, owned in p.babies do
		local mult = owned.placed and GameConfig.OpenIncomeMultiplier or GameConfig.VaultIncomeMultiplier
		perSecond += BabyData.incomePerSecond(owned.babyId) * mult
	end
	local earned = Util.round(perSecond * elapsed * GameConfig.OfflineIncomeRate)
	if earned > 0 then
		p.coins += earned
		p._offlineEarned = earned :: any -- transient, read once by init for the welcome toast
	end
end

function DataService.get(player: Player): Profile?
	return profiles[player]
end

function DataService.markDirty(player: Player)
	dirty[player] = true
end

-- Push a fresh snapshot to the player's client.
function DataService.push(player: Player)
	local p = profiles[player]
	if not p then
		return
	end
	Net.event("StateUpdate"):FireClient(player, {
		coins = p.coins,
		trust = p.trust,
		infamy = p.infamy,
		babies = p.babies,
		ownedVehicles = p.ownedVehicles,
		activeCaravan = p.activeCaravan,
		collectedIds = p.collectedIds,
		stats = p.stats,
	})
end

local function load(player: Player)
	local key = "player_" .. player.UserId
	local data: Profile? = nil
	if store then
		local ok, result = pcall(function()
			return (store :: DataStore):GetAsync(key)
		end)
		if ok and type(result) == "table" then
			data = result :: Profile
		elseif not ok then
			warn("[DataService] load failed for", player.Name, result)
		end
	end

	local profile = data and reconcile(data) or defaultProfile()
	grantOfflineEarnings(profile)
	profiles[player] = profile
	DataService.push(player)

	local offline = (profile :: any)._offlineEarned
	if offline then
		(profile :: any)._offlineEarned = nil
		Net.event("Notify"):FireClient(player, {
			text = string.format("Welcome back! Your babies earned %d coins while away.", offline),
			kind = "good",
		})
	end
end

function DataService.save(player: Player)
	local p = profiles[player]
	if not p or not store then
		dirty[player] = false
		return
	end
	p.lastSeen = os.time()
	local key = "player_" .. player.UserId
	local ok, err = pcall(function()
		(store :: DataStore):SetAsync(key, p)
	end)
	if ok then
		dirty[player] = false
	else
		warn("[DataService] save failed for", player.Name, err)
	end
end

function DataService.start()
	Players.PlayerAdded:Connect(load)
	for _, player in Players:GetPlayers() do
		task.spawn(load, player)
	end

	Players.PlayerRemoving:Connect(function(player)
		DataService.save(player)
		profiles[player] = nil
		dirty[player] = nil
	end)

	game:BindToClose(function()
		if RunService:IsStudio() then
			return
		end
		for _, player in Players:GetPlayers() do
			DataService.save(player)
		end
	end)

	-- Auto-save loop.
	task.spawn(function()
		while true do
			task.wait(GameConfig.AutoSaveSeconds)
			for player in profiles do
				if dirty[player] then
					DataService.save(player)
				end
			end
		end
	end)
end

return DataService
