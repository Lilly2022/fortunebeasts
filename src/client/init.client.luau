--!strict
-- Client entry point. Wires the network snapshot into local State, mounts the UI
-- and the squish-station world view, and pipes server notifications to toasts.

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Net = require(Shared.Net)

local State = require(script.State)
local UI = require(script.UI)
local BaseView = require(script.BaseView)
local Notifications = require(script.Notifications)

-- Server -> client: profile snapshots.
Net.event("StateUpdate").OnClientEvent:Connect(function(snapshot)
	State.set(snapshot)
end)

-- Server -> client: toast messages.
Net.event("Notify").OnClientEvent:Connect(function(payload)
	if type(payload) == "table" and payload.text then
		Notifications.show(payload.text, payload.kind)
	end
end)

-- Server -> client: caravan progress / results (UI also reads from State).
Net.event("CaravanUpdate").OnClientEvent:Connect(function(payload)
	if type(payload) == "table" and payload.phase == "resolved" then
		local tag = payload.betrayed and "😈 Betrayed" or "🤝 Split"
		Notifications.show(
			string.format("%s — %s Reward %d (loss %d, insurance %d).", tag, payload.summary, payload.reward, payload.loss or 0, payload.payout or 0),
			payload.betrayed and "warn" or "good"
		)
	end
end)

UI.mount()
BaseView.start()

print("[FortuneBeasts] Client ready.")
