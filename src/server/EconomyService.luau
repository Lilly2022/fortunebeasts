--!strict
-- Thin layer over a profile's coins / trust / infamy. Always go through here so
-- every change marks the profile dirty and re-syncs the client.

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local GameConfig = require(Shared.GameConfig)
local Util = require(Shared.Util)
local DataService = require(script.Parent.DataService)

local EconomyService = {}

function EconomyService.getCoins(player: Player): number
	local p = DataService.get(player)
	return p and p.coins or 0
end

function EconomyService.canAfford(player: Player, amount: number): boolean
	return EconomyService.getCoins(player) >= amount
end

function EconomyService.addCoins(player: Player, amount: number)
	local p = DataService.get(player)
	if not p then
		return
	end
	p.coins = math.max(0, p.coins + amount)
	DataService.markDirty(player)
	DataService.push(player)
end

-- Returns true and deducts if affordable, otherwise false and no change.
function EconomyService.trySpend(player: Player, amount: number): boolean
	local p = DataService.get(player)
	if not p or p.coins < amount then
		return false
	end
	p.coins -= amount
	DataService.markDirty(player)
	DataService.push(player)
	return true
end

function EconomyService.adjustTrust(player: Player, delta: number)
	local p = DataService.get(player)
	if not p then
		return
	end
	p.trust = Util.clamp(p.trust + delta, 0, GameConfig.MaxTrust)
	if delta < 0 then
		p.infamy += math.abs(delta)
	end
	DataService.markDirty(player)
	DataService.push(player)
end

return EconomyService
