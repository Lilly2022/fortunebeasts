--!strict
-- Server entry point. Sets up networking, starts every service, and routes the
-- client's remote calls to the right service with light validation.

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Net = require(Shared.Net)
local VehicleData = require(Shared.VehicleData)

local DataService = require(script.DataService)
local EconomyService = require(script.EconomyService)
local BabyService = require(script.BabyService)
local CaravanService = require(script.CaravanService)
local WorldService = require(script.WorldService)

-- 1. Create the remote folder before any client asks for it.
Net.init()

-- 2. Boot services (data first, then anything that reads profiles).
DataService.start()
BabyService.start()
WorldService.start()

-- 3. Route RemoteFunctions. Each handler validates the caller owns a profile;
--    the services themselves do the deeper rule checks.
Net.func("Hatch").OnServerInvoke = function(player: Player)
	return BabyService.hatch(player)
end

Net.func("PlaceBaby").OnServerInvoke = function(player: Player, uid)
	if type(uid) ~= "string" then
		return { ok = false, reason = "Bad request." }
	end
	return BabyService.place(player, uid)
end

Net.func("RecallBaby").OnServerInvoke = function(player: Player, uid)
	if type(uid) ~= "string" then
		return { ok = false, reason = "Bad request." }
	end
	return BabyService.recall(player, uid)
end

Net.func("BuyVehicle").OnServerInvoke = function(player: Player, vehicleId)
	if type(vehicleId) ~= "string" then
		return { ok = false, reason = "Bad request." }
	end
	local vehicle = VehicleData.get(vehicleId)
	if not vehicle then
		return { ok = false, reason = "Unknown vehicle." }
	end
	local profile = DataService.get(player)
	if not profile then
		return { ok = false, reason = "No profile." }
	end
	if table.find(profile.ownedVehicles, vehicleId) then
		return { ok = false, reason = "Already owned." }
	end
	if not EconomyService.trySpend(player, vehicle.cost) then
		return { ok = false, reason = "Not enough coins." }
	end
	table.insert(profile.ownedVehicles, vehicleId)
	DataService.markDirty(player)
	DataService.push(player)
	Net.event("Notify"):FireClient(player, { text = "Unlocked " .. vehicle.name .. "!", kind = "good" })
	return { ok = true }
end

Net.func("StartCaravan").OnServerInvoke = function(player: Player, vehicleId, insuranceId, babyUids)
	if type(vehicleId) ~= "string" or type(insuranceId) ~= "string" or type(babyUids) ~= "table" then
		return { ok = false, reason = "Bad request." }
	end
	-- Sanitise the baby list to plain strings.
	local clean: { string } = {}
	for _, v in babyUids :: { any } do
		if type(v) == "string" then
			table.insert(clean, v)
		end
	end
	return CaravanService.start(player, vehicleId, insuranceId, clean)
end

Net.func("ResolveCaravan").OnServerInvoke = function(player: Player, runId, betray)
	if type(runId) ~= "string" then
		return { ok = false, reason = "Bad request." }
	end
	return CaravanService.resolve(player, runId, betray == true)
end

-- 4. Squish (解压) — fun stress-relief trickle of coins, rate-limited per player.
local Players = game:GetService("Players")
local GameConfig = require(Shared.GameConfig)
local lastSquish: { [Player]: number } = {}
Players.PlayerRemoving:Connect(function(player)
	lastSquish[player] = nil
end)
Net.event("Squish").OnServerEvent:Connect(function(player: Player)
	local now = os.clock()
	if now - (lastSquish[player] or 0) < GameConfig.SquishCooldown then
		return
	end
	lastSquish[player] = now
	EconomyService.addCoins(player, GameConfig.SquishCoinReward)
	-- Let nearby clients play the squish feedback too.
	Net.event("SquishFx"):FireAllClients(player.UserId)
end)

print("[FortuneBeasts] Server ready — Squish Caravan online.")
