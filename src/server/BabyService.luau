--!strict
-- Raising babies (养娃): hatching eggs, placing babies out in the open vs the
-- vault, and the passive-income tick that pays players for their roster.

local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local GameConfig = require(Shared.GameConfig)
local BabyData = require(Shared.BabyData)
local Rarity = require(Shared.Rarity)
local Util = require(Shared.Util)
local Net = require(Shared.Net)
local Types = require(Shared.Types)

local DataService = require(script.Parent.DataService)
local EconomyService = require(script.Parent.EconomyService)

type OwnedBaby = Types.OwnedBaby

local BabyService = {}

-- Roll a random baby, weighted by rarity (rarer = less likely).
local function rollBaby(): string
	local weights: { [string]: number } = {}
	for _, def in BabyData.List do
		weights[def.id] = Rarity.Info[def.rarity].hatchWeight
	end
	return Util.weightedPick(weights)
end

local function findBaby(profile: Types.Profile, uid: string): OwnedBaby?
	for _, owned in profile.babies do
		if owned.uid == uid then
			return owned
		end
	end
	return nil
end

local function countPlaced(profile: Types.Profile): number
	local n = 0
	for _, owned in profile.babies do
		if owned.placed then
			n += 1
		end
	end
	return n
end

function BabyService.hatch(player: Player): { ok: boolean, babyId: string?, reason: string? }
	local p = DataService.get(player)
	if not p then
		return { ok = false, reason = "No profile loaded." }
	end
	if #p.babies >= GameConfig.BaseBabyCapacity then
		return { ok = false, reason = "Vault is full — sell or caravan some babies first." }
	end
	if not EconomyService.trySpend(player, GameConfig.HatchCost) then
		return { ok = false, reason = "Not enough coins to hatch." }
	end

	local babyId = rollBaby()
	local owned: OwnedBaby = {
		uid = Util.uid("baby"),
		babyId = babyId,
		level = 1,
		placed = false,
	}
	table.insert(p.babies, owned)
	p.collectedIds[babyId] = true
	p.stats.babiesHatched += 1

	DataService.markDirty(player)
	DataService.push(player)

	local def = BabyData.get(babyId)
	Net.event("Notify"):FireClient(player, {
		text = string.format("Hatched %s (%s)!", def and def.name or babyId, def and def.rarity or "?"),
		kind = "good",
	})
	return { ok = true, babyId = babyId }
end

function BabyService.place(player: Player, uid: string): { ok: boolean, reason: string? }
	local p = DataService.get(player)
	if not p then
		return { ok = false, reason = "No profile loaded." }
	end
	local owned = findBaby(p, uid)
	if not owned then
		return { ok = false, reason = "Baby not found." }
	end
	if owned.placed then
		return { ok = true }
	end
	if countPlaced(p) >= GameConfig.MaxPlacedBabies then
		return { ok = false, reason = "No open slots left." }
	end
	owned.placed = true
	DataService.markDirty(player)
	DataService.push(player)
	return { ok = true }
end

function BabyService.recall(player: Player, uid: string): { ok: boolean, reason: string? }
	local p = DataService.get(player)
	if not p then
		return { ok = false, reason = "No profile loaded." }
	end
	local owned = findBaby(p, uid)
	if not owned then
		return { ok = false, reason = "Baby not found." }
	end
	owned.placed = false
	DataService.markDirty(player)
	DataService.push(player)
	return { ok = true }
end

-- Total coins/sec a player currently earns from their roster.
function BabyService.incomeRate(player: Player): number
	local p = DataService.get(player)
	if not p then
		return 0
	end

	-- Babies currently away on a caravan don't earn passive income at home.
	local onCaravan: { [string]: boolean } = {}
	if p.activeCaravan and not p.activeCaravan.resolved then
		for _, uid in p.activeCaravan.babyUids do
			onCaravan[uid] = true
		end
	end

	local rate = 0
	for _, owned in p.babies do
		if not onCaravan[owned.uid] then
			local mult = owned.placed and GameConfig.OpenIncomeMultiplier or GameConfig.VaultIncomeMultiplier
			rate += BabyData.incomePerSecond(owned.babyId) * mult
		end
	end
	return rate
end

-- Passive-income loop: pays every player their per-second rate.
function BabyService.start()
	task.spawn(function()
		while true do
			task.wait(GameConfig.IncomeTickSeconds)
			for _, player in Players:GetPlayers() do
				local rate = BabyService.incomeRate(player)
				local gain = Util.round(rate * GameConfig.IncomeTickSeconds)
				if gain > 0 then
					EconomyService.addCoins(player, gain)
				end
			end
		end
	end)
end

return BabyService
