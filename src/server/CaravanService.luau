--!strict
-- Caravan runs (运娃): load babies into a vehicle, optionally buy insurance, and
-- haul loot home. Runs take real time; on resolve there's an ambush/breakdown
-- roll, insurance pays out part of any loss, and the player chooses to split
-- fairly (honest, trust up) or skim extra ("betray", trust down).
--
-- This models a solo run. The hooks for true multiplayer team runs (shared pot,
-- per-member betray) are noted inline — see ROADMAP in README.

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local GameConfig = require(Shared.GameConfig)
local BabyData = require(Shared.BabyData)
local VehicleData = require(Shared.VehicleData)
local InsuranceData = require(Shared.InsuranceData)
local Util = require(Shared.Util)
local Net = require(Shared.Net)
local Types = require(Shared.Types)

local DataService = require(script.Parent.DataService)
local EconomyService = require(script.Parent.EconomyService)

local CaravanService = {}

local LOOT_FACTOR = 20 -- pot value = sum(baby income/sec) * this

local function babyByUid(profile: Types.Profile, uid: string): Types.OwnedBaby?
	for _, owned in profile.babies do
		if owned.uid == uid then
			return owned
		end
	end
	return nil
end

function CaravanService.start(
	player: Player,
	vehicleId: string,
	insuranceId: string,
	babyUids: { string }
): { ok: boolean, reason: string? }
	local p = DataService.get(player)
	if not p then
		return { ok = false, reason = "No profile loaded." }
	end
	if p.activeCaravan and not p.activeCaravan.resolved then
		return { ok = false, reason = "A caravan is already on the road." }
	end

	local vehicle = VehicleData.get(vehicleId)
	if not vehicle then
		return { ok = false, reason = "Unknown vehicle." }
	end
	if not table.find(p.ownedVehicles, vehicleId) then
		return { ok = false, reason = "You don't own that vehicle." }
	end
	if #babyUids == 0 then
		return { ok = false, reason = "Load at least one baby." }
	end
	if #babyUids > vehicle.capacity then
		return { ok = false, reason = "Too many babies for this vehicle." }
	end

	local insurance = InsuranceData.get((insuranceId :: any)) or InsuranceData.get("none")

	-- Validate babies and compute the pot.
	local potValue = 0
	for _, uid in babyUids do
		local owned = babyByUid(p, uid)
		if not owned then
			return { ok = false, reason = "A selected baby is missing." }
		end
		potValue += BabyData.incomePerSecond(owned.babyId)
	end
	potValue = Util.round(potValue * LOOT_FACTOR)

	local upfront = vehicle.fuelCost + insurance.cost
	if not EconomyService.trySpend(player, upfront) then
		return { ok = false, reason = string.format("Need %d coins for fuel + insurance.", upfront) }
	end

	local duration = Util.round(GameConfig.CaravanBaseDuration * (1 + (5 - vehicle.speed) * 0.15))
	local run: Types.CaravanRun = {
		runId = Util.uid("run"),
		vehicleId = vehicleId,
		insuranceId = insurance.id,
		babyUids = babyUids,
		potValue = potValue,
		startedAt = os.time(),
		duration = duration,
		resolved = false,
	}
	p.activeCaravan = run
	DataService.markDirty(player)
	DataService.push(player)

	Net.event("CaravanUpdate"):FireClient(player, { phase = "started", run = run })
	return { ok = true }
end

function CaravanService.resolve(
	player: Player,
	runId: string,
	betray: boolean
): { ok: boolean, reward: number?, reason: string? }
	local p = DataService.get(player)
	if not p or not p.activeCaravan then
		return { ok = false, reason = "No active caravan." }
	end
	local run = p.activeCaravan
	if run.runId ~= runId or run.resolved then
		return { ok = false, reason = "Caravan already resolved." }
	end
	if os.time() < run.startedAt + run.duration then
		local remaining = run.startedAt + run.duration - os.time()
		return { ok = false, reason = string.format("Caravan still en route (%ds left).", remaining) }
	end

	local vehicle = VehicleData.get(run.vehicleId)
	local insurance = InsuranceData.get((run.insuranceId :: any))

	-- Ambush / breakdown roll. Better defense and reliability cut losses.
	local ambushChance = Util.clamp(
		GameConfig.CaravanAmbushChance - (vehicle and vehicle.defense or 1) * 0.05,
		0.05,
		0.9
	)
	local brokeDown = vehicle and math.random() > vehicle.reliability or false
	local ambushed = math.random() < ambushChance

	local loss = 0
	if ambushed then
		loss += run.potValue * (0.3 + math.random() * 0.3) -- lose 30–60%
	end
	if brokeDown then
		loss += run.potValue * 0.15 -- repair / delay cost
	end
	loss = math.min(loss, run.potValue)

	local payout = loss * insurance.payoutRatio
	local reward = Util.round(run.potValue - loss + payout)

	-- Betray = skim extra at the cost of trust; honest = trust gain.
	if betray then
		reward = Util.round(reward * GameConfig.CaravanBetrayBonus)
		EconomyService.adjustTrust(player, -GameConfig.BetrayTrustPenalty)
		p.stats.betrayals += 1
	else
		EconomyService.adjustTrust(player, GameConfig.HonestTrustGain)
	end

	-- Return babies to the vault and close the run.
	for _, uid in run.babyUids do
		local owned = babyByUid(p, uid)
		if owned then
			owned.placed = false
		end
	end
	run.resolved = true
	p.activeCaravan = nil
	p.stats.caravansCompleted += 1

	EconomyService.addCoins(player, reward)
	DataService.markDirty(player)
	DataService.push(player)

	local summary
	if ambushed and brokeDown then
		summary = "Ambushed AND broke down!"
	elseif ambushed then
		summary = "Bandits hit the caravan!"
	elseif brokeDown then
		summary = "The vehicle broke down."
	else
		summary = "Smooth run!"
	end
	Net.event("CaravanUpdate"):FireClient(player, {
		phase = "resolved",
		reward = reward,
		loss = Util.round(loss),
		payout = Util.round(payout),
		betrayed = betray,
		summary = summary,
	})
	Net.event("Notify"):FireClient(player, {
		text = string.format("%s Caravan paid out %d coins.", summary, reward),
		kind = (ambushed or brokeDown) and "warn" or "good",
	})
	return { ok = true, reward = reward }
end

return CaravanService
