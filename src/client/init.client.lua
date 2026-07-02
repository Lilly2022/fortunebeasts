--[[
	FB_ClientController (LocalScript)
	Builds the FB_HUD ScreenGui and reacts to server messages.

	The client NEVER decides gameplay - it only:
	- shows coins / trust / protection timer
	- shows alert popups (raid alerts etc.)
	- shows the caravan status bar and the Split Fair / Grab Extra choice
	- hides the wrong ProximityPrompt locally
	  (you see "Move" on YOUR beasts, "Steal" on OTHER people's beasts)

	Everything is sized with Scale so it works on phones too.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")

local localPlayer = Players.LocalPlayer
local remotesFolder = ReplicatedStorage:WaitForChild("FB_Remotes")
local remotes = {
	State = remotesFolder:WaitForChild("State"),
	Alert = remotesFolder:WaitForChild("Alert"),
	CaravanStatus = remotesFolder:WaitForChild("CaravanStatus"),
	CaravanChoicePrompt = remotesFolder:WaitForChild("CaravanChoicePrompt"),
	CaravanChoice = remotesFolder:WaitForChild("CaravanChoice"),
}

local ALERT_COLORS = {
	info = Color3.fromRGB(235, 235, 235),
	raid = Color3.fromRGB(255, 90, 90),
	gold = Color3.fromRGB(255, 215, 100),
	warn = Color3.fromRGB(255, 160, 70),
}

-- ============ UI HELPERS ============

local function new(className, props, parent)
	local instance = Instance.new(className)
	for key, value in pairs(props) do
		instance[key] = value
	end
	instance.Parent = parent
	return instance
end

local function styleText(label)
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.TextStrokeTransparency = 0.5
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.new(1, 1, 1)
end

-- ============ BUILD THE HUD ============

local playerGui = localPlayer:WaitForChild("PlayerGui")

local hud = new("ScreenGui", { Name = "FB_HUD", ResetOnSpawn = false, IgnoreGuiInset = true }, playerGui)

-- Top-left: coins + trust
local statsFrame = new("Frame", {
	Size = UDim2.new(0.24, 0, 0.11, 0),
	Position = UDim2.new(0.015, 0, 0.02, 0),
	BackgroundColor3 = Color3.fromRGB(30, 30, 40),
	BackgroundTransparency = 0.25,
}, hud)
new("UICorner", { CornerRadius = UDim.new(0.2, 0) }, statsFrame)

local coinsLabel = new("TextLabel", {
	Size = UDim2.new(1, -10, 0.5, 0),
	Position = UDim2.new(0, 10, 0, 0),
	Text = "🪙 100",
	TextXAlignment = Enum.TextXAlignment.Left,
}, statsFrame)
styleText(coinsLabel)
coinsLabel.TextColor3 = Color3.fromRGB(255, 220, 100)

local trustLabel = new("TextLabel", {
	Size = UDim2.new(1, -10, 0.5, 0),
	Position = UDim2.new(0, 10, 0.5, 0),
	Text = "🤝 Trust: 0",
	TextXAlignment = Enum.TextXAlignment.Left,
}, statsFrame)
styleText(trustLabel)

-- Top-center: protection timer + oathbreaker warning + caravan status
local protectionLabel = new("TextLabel", {
	Size = UDim2.new(0.4, 0, 0.05, 0),
	Position = UDim2.new(0.3, 0, 0.02, 0),
	Text = "",
}, hud)
styleText(protectionLabel)
protectionLabel.TextColor3 = Color3.fromRGB(140, 220, 255)

local oathbreakerLabel = new("TextLabel", {
	Size = UDim2.new(0.4, 0, 0.045, 0),
	Position = UDim2.new(0.3, 0, 0.07, 0),
	Text = "",
}, hud)
styleText(oathbreakerLabel)
oathbreakerLabel.TextColor3 = Color3.fromRGB(255, 90, 90)

local caravanStatusLabel = new("TextLabel", {
	Size = UDim2.new(0.5, 0, 0.05, 0),
	Position = UDim2.new(0.25, 0, 0.115, 0),
	Text = "",
}, hud)
styleText(caravanStatusLabel)
caravanStatusLabel.TextColor3 = Color3.fromRGB(255, 200, 120)

-- Bottom hint bar
local hintLabel = new("TextLabel", {
	Size = UDim2.new(0.9, 0, 0.045, 0),
	Position = UDim2.new(0.05, 0, 0.94, 0),
	Text = "",
	TextTransparency = 0.15,
}, hud)
styleText(hintLabel)

local HINTS = {
	"💡 Beasts OUTSIDE earn 100% but can be STOLEN. Vaulted beasts are safe but earn 50%.",
	"💡 Hold F near another player's exposed beast to STEAL it... then RUN home! 😈",
	"💡 Press E on your own beast to move it between OUTSIDE and the VAULT.",
	"💡 Start a CARAVAN at the orange pad by the market for bonus coins!",
	"💡 If a thief grabs your beast, CHASE THEM - touch them to get it back!",
	"💡 The Debt Dragon pays you 100 coins now... and takes 20% of your income forever. 🐉",
}
task.spawn(function()
	local index = 1
	while true do
		hintLabel.Text = HINTS[index]
		index = (index % #HINTS) + 1
		task.wait(7)
	end
end)

-- Right side: alert feed
local alertFrame = new("Frame", {
	Size = UDim2.new(0.32, 0, 0.5, 0),
	Position = UDim2.new(0.67, 0, 0.18, 0),
	BackgroundTransparency = 1,
}, hud)
local alertLayout = new("UIListLayout", {
	SortOrder = Enum.SortOrder.LayoutOrder,
	Padding = UDim.new(0, 6),
	VerticalAlignment = Enum.VerticalAlignment.Top,
}, alertFrame)

local alertCount = 0
local function showAlert(message, kind)
	alertCount += 1
	local alert = new("TextLabel", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Text = message,
		TextWrapped = true,
		TextSize = 20,
		RichText = true,
		Font = Enum.Font.FredokaOne,
		TextColor3 = ALERT_COLORS[kind] or ALERT_COLORS.info,
		BackgroundColor3 = Color3.fromRGB(25, 25, 35),
		BackgroundTransparency = 0.25,
		LayoutOrder = alertCount,
		TextStrokeTransparency = 0.6,
	}, alertFrame)
	new("UICorner", { CornerRadius = UDim.new(0, 10) }, alert)
	new("UIPadding", {
		PaddingTop = UDim.new(0, 6),
		PaddingBottom = UDim.new(0, 6),
		PaddingLeft = UDim.new(0, 10),
		PaddingRight = UDim.new(0, 10),
	}, alert)

	-- Raid alerts shake a little so they feel urgent
	if kind == "raid" then
		alert.TextSize = 24
	end

	task.delay(6, function()
		local tween =
			TweenService:Create(alert, TweenInfo.new(0.8), { TextTransparency = 1, BackgroundTransparency = 1 })
		tween:Play()
		tween.Completed:Wait()
		alert:Destroy()
	end)

	-- Keep max 6 on screen
	local children = {}
	for _, child in ipairs(alertFrame:GetChildren()) do
		if child:IsA("TextLabel") then
			table.insert(children, child)
		end
	end
	table.sort(children, function(x, y)
		return x.LayoutOrder < y.LayoutOrder
	end)
	for i = 1, #children - 6 do
		children[i]:Destroy()
	end
end

-- ============ CARAVAN CHOICE MODAL ============

local choiceModal = new("Frame", {
	Size = UDim2.new(0.5, 0, 0.34, 0),
	Position = UDim2.new(0.25, 0, 0.3, 0),
	BackgroundColor3 = Color3.fromRGB(35, 30, 50),
	Visible = false,
}, hud)
new("UICorner", { CornerRadius = UDim.new(0.06, 0) }, choiceModal)

local choiceTitle = new("TextLabel", {
	Size = UDim2.new(1, 0, 0.3, 0),
	Text = "📦 Caravan arrived! Split the loot?",
}, choiceModal)
styleText(choiceTitle)

local choiceTimer = new("TextLabel", {
	Size = UDim2.new(1, 0, 0.14, 0),
	Position = UDim2.new(0, 0, 0.28, 0),
	Text = "",
}, choiceModal)
styleText(choiceTimer)
choiceTimer.TextColor3 = Color3.fromRGB(200, 200, 200)

local function choiceButton(text, color, xPosition, choice)
	local button = new("TextButton", {
		Size = UDim2.new(0.42, 0, 0.4, 0),
		Position = UDim2.new(xPosition, 0, 0.5, 0),
		Text = text,
		BackgroundColor3 = color,
		TextWrapped = true,
	}, choiceModal)
	new("UICorner", { CornerRadius = UDim.new(0.15, 0) }, button)
	button.Font = Enum.Font.FredokaOne
	button.TextScaled = true
	button.TextColor3 = Color3.new(1, 1, 1)
	button.Activated:Connect(function()
		remotes.CaravanChoice:FireServer(choice)
		choiceModal.Visible = false
		showAlert(
			choice == "fair" and "🤝 You chose to split fair. Waiting for your partner..."
				or "😈 You're grabbing extra. Waiting for your partner...",
			"info"
		)
	end)
	return button
end

choiceButton("🤝 SPLIT FAIR\n(60 coins + trust)", Color3.fromRGB(60, 160, 90), 0.06, "fair")
choiceButton("😈 GRAB EXTRA\n(90 coins... but 💀)", Color3.fromRGB(190, 60, 60), 0.52, "grab")

remotes.CaravanChoicePrompt.OnClientEvent:Connect(function(timeoutSeconds)
	choiceModal.Visible = true
	task.spawn(function()
		for remaining = timeoutSeconds, 1, -1 do
			if not choiceModal.Visible then
				return
			end
			choiceTimer.Text = ("No answer in %ds = Split Fair"):format(remaining)
			task.wait(1)
		end
		choiceModal.Visible = false
	end)
end)

-- ============ STATE / ALERT / STATUS LISTENERS ============

local protectedSecondsLeft = 0
local oathbreakerSecondsLeft = 0

remotes.State.OnClientEvent:Connect(function(state)
	coinsLabel.Text = ("🪙 %d"):format(state.coins)
	trustLabel.Text = ("🤝 Trust: %d"):format(state.trust)
	protectedSecondsLeft = state.protectedSecondsLeft or 0
	oathbreakerSecondsLeft = state.oathbreakerSecondsLeft or 0
end)

-- Local countdown display (server remains the real authority)
task.spawn(function()
	while true do
		task.wait(1)
		if protectedSecondsLeft > 0 then
			protectedSecondsLeft -= 1
			protectionLabel.Text = ("🛡️ Protected: %d:%02d"):format(
				math.floor(protectedSecondsLeft / 60),
				protectedSecondsLeft % 60
			)
		else
			protectionLabel.Text = ""
		end
		if oathbreakerSecondsLeft > 0 then
			oathbreakerSecondsLeft -= 1
			oathbreakerLabel.Text = ("💀 OATHBREAKER: %d:%02d"):format(
				math.floor(oathbreakerSecondsLeft / 60),
				oathbreakerSecondsLeft % 60
			)
		else
			oathbreakerLabel.Text = ""
		end
	end
end)

remotes.Alert.OnClientEvent:Connect(showAlert)

remotes.CaravanStatus.OnClientEvent:Connect(function(text)
	caravanStatusLabel.Text = text or ""
end)

-- ============ PROMPT FILTERING ============
-- Server puts both prompts on every beast; locally we hide the one that
-- doesn't apply to us. (Local property changes don't replicate, so this
-- is purely cosmetic - the server still validates everything.)

local function filterPrompts(beastModel)
	local function apply()
		local ownerUserId = beastModel:GetAttribute("OwnerUserId")
		local body = beastModel:FindFirstChild("Body")
		if not body then
			return
		end
		local isMine = ownerUserId == localPlayer.UserId
		local movePrompt = body:FindFirstChild("MovePrompt")
		local stealPrompt = body:FindFirstChild("StealPrompt")
		if movePrompt then
			movePrompt.Enabled = isMine
		end
		if stealPrompt then
			stealPrompt.Enabled = not isMine
		end
	end
	apply()
	beastModel:GetAttributeChangedSignal("OwnerUserId"):Connect(apply)
	-- Prompts are added right after the tag, so re-check shortly after
	task.delay(0.5, apply)
end

for _, beastModel in ipairs(CollectionService:GetTagged("FB_Beast")) do
	filterPrompts(beastModel)
end
CollectionService:GetInstanceAddedSignal("FB_Beast"):Connect(filterPrompts)

print("[FB][Client] HUD ready for " .. localPlayer.Name)
