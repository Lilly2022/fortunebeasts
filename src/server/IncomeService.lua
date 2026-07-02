--[[
	IncomeService
	Every GameConfig.incomeTickSeconds (10s):
	- exposed beasts pay 100% of incomePerTick
	- vaulted beasts pay 50%
	- beasts being carried by a thief pay NOTHING
	- if you own a Debt Dragon, it takes its 20% cut of the whole tick 🐉
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.FB_Modules.GameConfig)
local BeastConfig = require(ReplicatedStorage.FB_Modules.BeastConfig)

local IncomeService = {}

local services

local function dprint(...)
	if GameConfig.debug then
		print("[FB][Income]", ...)
	end
end

local function payPlayer(player)
	local total = 0
	local dragonCount = 0

	for _, record in ipairs(services.Beast.getBeasts(player)) do
		local beastDef = BeastConfig.get(record.beastId)
		if record.carriedBy then
			continue -- stolen mid-carry = no income
		end
		if beastDef.debtPercent then
			dragonCount += 1
		end
		local multiplier = record.slotType == "vault" and GameConfig.vaultIncomeMultiplier
			or GameConfig.exposedIncomeMultiplier
		total += beastDef.incomePerTick * multiplier
	end

	total = math.floor(total)
	if total <= 0 and dragonCount == 0 then
		return
	end

	-- Debt Dragon takes its cut of everything you earned this tick
	local debtCut = 0
	if dragonCount > 0 and total > 0 then
		local dragon = BeastConfig.get("DebtDragon")
		debtCut = math.floor(total * dragon.debtPercent * dragonCount)
		total -= debtCut
	end

	if total > 0 then
		services.PlayerData.addCoins(player, total, "income tick")
	end
	if debtCut > 0 then
		services.PlayerData.alert(
			player,
			("🐉 Debt Dragon took %d coins from your income..."):format(debtCut),
			"warn"
		)
		dprint(("%s paid %d to the Debt Dragon"):format(player.Name, debtCut))
	end
end

function IncomeService.init(injectedServices)
	services = injectedServices

	task.spawn(function()
		while true do
			task.wait(GameConfig.incomeTickSeconds)
			for _, player in ipairs(Players:GetPlayers()) do
				payPlayer(player)
			end
			dprint("Income tick paid out")
		end
	end)
end

return IncomeService
