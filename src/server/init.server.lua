--[[
	FB_Server (main server script)
	Boots the whole game in a safe order:
	1. Creates the FB_Remotes folder (client <-> server messages)
	2. Builds the map (ground, market, caravan route)
	3. Starts every service

	Every service is a ModuleScript child of this script.
	Server is AUTHORITATIVE: the client is never trusted for coins,
	ownership, stealing, caravan rewards, or trust.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("FB_Modules"):WaitForChild("GameConfig"))

print("[FB] ============================================")
print("[FB] Fortune Beasts: Caravan Wars - server booting")
print("[FB] ============================================")

-- 1) Remotes ---------------------------------------------------------------
local remotes = Instance.new("Folder")
remotes.Name = "FB_Remotes"

local function makeRemote(name)
	local remote = Instance.new("RemoteEvent")
	remote.Name = name
	remote.Parent = remotes
end

makeRemote("State") -- server -> client: coins, trust, protection, oathbreaker
makeRemote("Alert") -- server -> client: popup messages (raid alerts etc.)
makeRemote("CaravanStatus") -- server -> client: caravan progress text
makeRemote("CaravanChoicePrompt") -- server -> client: show Split Fair / Grab Extra
makeRemote("CaravanChoice") -- client -> server: the player's choice
remotes.Parent = ReplicatedStorage
print("[FB] Remotes created")

-- 2) Services --------------------------------------------------------------
local services = {
	PlayerData = require(script.PlayerDataService),
	Map = require(script.MapService),
	Plot = require(script.PlotService),
	Beast = require(script.BeastService),
	Income = require(script.IncomeService),
	Steal = require(script.StealService),
	Market = require(script.MarketService),
	Caravan = require(script.CaravanService),
}

-- Boot order matters: map first, then data, then gameplay systems.
local bootOrder = { "Map", "PlayerData", "Plot", "Beast", "Income", "Steal", "Market", "Caravan" }

for _, name in ipairs(bootOrder) do
	local ok, err = pcall(function()
		services[name].init(services)
	end)
	if ok then
		print(("[FB] %sService ready"):format(name))
	else
		warn(("[FB] %sService FAILED to start: %s"):format(name, tostring(err)))
	end
end

print("[FB] Server ready. Debug mode:", GameConfig.debug)
