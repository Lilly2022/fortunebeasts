--!strict
-- Tiny networking helper. Defines every remote by name in one place so client
-- and server never disagree. On the server it creates the instances; on the
-- client it waits for them. Use Net.event(name) / Net.func(name).

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Net = {}

-- Server -> Client and Client -> Server fire-and-forget events.
Net.Events = {
	"StateUpdate", -- server -> client: full/partial profile snapshot
	"Notify", -- server -> client: toast { text, kind }
	"Squish", -- client -> server: a baby was squished { babyId }
	"SquishFx", -- server -> client: play squish feedback for others
	"CaravanUpdate", -- server -> client: caravan run progress / result
}

-- Request/response calls (RemoteFunction).
Net.Functions = {
	"Hatch", -- () -> { ok, babyId?, reason? }
	"PlaceBaby", -- (uid) -> { ok, reason? }
	"RecallBaby", -- (uid) -> { ok, reason? }
	"BuyVehicle", -- (vehicleId) -> { ok, reason? }
	"StartCaravan", -- (vehicleId, insuranceId, babyUids) -> { ok, reason? }
	"ResolveCaravan", -- (runId, betray: boolean) -> { ok, reward?, reason? }
}

local FOLDER_NAME = "FortuneBeastsNet"

local function getFolder(): Folder
	if RunService:IsServer() then
		local existing = ReplicatedStorage:FindFirstChild(FOLDER_NAME)
		if existing then
			return existing :: Folder
		end
		local folder = Instance.new("Folder")
		folder.Name = FOLDER_NAME

		local events = Instance.new("Folder")
		events.Name = "Events"
		events.Parent = folder
		for _, name in Net.Events do
			local ev = Instance.new("RemoteEvent")
			ev.Name = name
			ev.Parent = events
		end

		local funcs = Instance.new("Folder")
		funcs.Name = "Functions"
		funcs.Parent = folder
		for _, name in Net.Functions do
			local fn = Instance.new("RemoteFunction")
			fn.Name = name
			fn.Parent = funcs
		end

		folder.Parent = ReplicatedStorage
		return folder
	else
		return ReplicatedStorage:WaitForChild(FOLDER_NAME) :: Folder
	end
end

function Net.event(name: string): RemoteEvent
	local folder = getFolder()
	local events = folder:WaitForChild("Events")
	return events:WaitForChild(name) :: RemoteEvent
end

function Net.func(name: string): RemoteFunction
	local folder = getFolder()
	local funcs = folder:WaitForChild("Functions")
	return funcs:WaitForChild(name) :: RemoteFunction
end

-- Server should call this once at boot so the folder exists before clients ask.
function Net.init()
	assert(RunService:IsServer(), "Net.init must run on the server")
	getFolder()
end

return Net
