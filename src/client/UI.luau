--!strict
-- Builds the whole 2D interface and keeps it in sync with State. Server stays
-- authoritative — every button here just invokes a remote and waits for the
-- resulting StateUpdate to refresh the screen.

local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Net = require(Shared.Net)
local BabyData = require(Shared.BabyData)
local Rarity = require(Shared.Rarity)
local Roles = require(Shared.Roles)
local VehicleData = require(Shared.VehicleData)
local InsuranceData = require(Shared.InsuranceData)
local GameConfig = require(Shared.GameConfig)

local Make = require(script.Parent.Make)
local Theme = require(script.Parent.Theme)
local State = require(script.Parent.State)
local Notifications = require(script.Parent.Notifications)

local UI = {}

-- Live element references updated on each snapshot.
local refs: { [string]: any } = {}
-- Panels keyed by name; only one open at a time.
local panels: { [string]: Frame } = {}
-- Caravan loadout selection (uid -> true).
local selected: { [string]: boolean } = {}
local chosenVehicle = "cart"
local chosenInsurance: string = "none"

local function fmt(n: number): string
	local s = tostring(math.floor(n))
	local out = s:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	return (out:gsub("^,", ""))
end

-- Income/sec computed from the snapshot, mirroring server logic for display.
local function incomeRate(snap: any): number
	if not snap then
		return 0
	end
	local onCaravan: { [string]: boolean } = {}
	if snap.activeCaravan and not snap.activeCaravan.resolved then
		for _, uid in snap.activeCaravan.babyUids do
			onCaravan[uid] = true
		end
	end
	local rate = 0
	for _, owned in snap.babies do
		if not onCaravan[owned.uid] then
			local mult = owned.placed and GameConfig.OpenIncomeMultiplier or GameConfig.VaultIncomeMultiplier
			rate += BabyData.incomePerSecond(owned.babyId) * mult
		end
	end
	return rate
end

local function button(text: string, color: Color3, onClick: () -> ()): TextButton
	local b = Make("TextButton", {
		Size = UDim2.new(0, 0, 1, 0),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundColor3 = color,
		AutoButtonColor = true,
		Font = Theme.Font,
		Text = "  " .. text .. "  ",
		TextColor3 = Theme.Colors.Text,
		TextSize = 18,
	}, {
		Theme.corner(10),
		Make("UIPadding", { PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6) }),
	})
	b.Activated:Connect(onClick)
	return b
end

local function showPanel(name: string?)
	for key, panel in panels do
		panel.Visible = (key == name)
	end
end

--========================================================================--
--  TOP BAR
--========================================================================--
local function buildTopBar(parent: ScreenGui)
	local bar = Make("Frame", {
		Name = "TopBar",
		Position = UDim2.new(0, 16, 0, 16),
		Size = UDim2.new(0, 520, 0, 56),
		BackgroundColor3 = Theme.Colors.Panel,
		Parent = parent,
	}, {
		Theme.corner(14),
		Theme.stroke(2, Theme.Colors.PanelLight),
		Make("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			Padding = UDim.new(0, 18),
			VerticalAlignment = Enum.VerticalAlignment.Center,
			HorizontalAlignment = Enum.HorizontalAlignment.Left,
		}),
		Theme.pad(14),
	})

	local function stat(name: string, color: Color3): TextLabel
		local label = Make("TextLabel", {
			Name = name,
			AutomaticSize = Enum.AutomaticSize.X,
			Size = UDim2.new(0, 0, 1, 0),
			BackgroundTransparency = 1,
			Font = Theme.Font,
			Text = name,
			TextColor3 = color,
			TextSize = 20,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = bar,
		})
		return label
	end

	refs.coins = stat("Coins", Theme.Colors.Coin)
	refs.income = stat("Income", Theme.Colors.Good)
	refs.trust = stat("Trust", Theme.Colors.Accent)
end

--========================================================================--
--  BOTTOM ACTION BAR
--========================================================================--
local function buildActionBar(parent: ScreenGui)
	local bar = Make("Frame", {
		Name = "ActionBar",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -16),
		Size = UDim2.new(0, 700, 0, 56),
		BackgroundColor3 = Theme.Colors.Panel,
		Parent = parent,
	}, {
		Theme.corner(16),
		Theme.stroke(2, Theme.Colors.PanelLight),
		Theme.pad(8),
		Make("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			Padding = UDim.new(0, 8),
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			VerticalAlignment = Enum.VerticalAlignment.Center,
		}),
	})

	local hatch = button(string.format("🥚 Hatch (%d)", GameConfig.HatchCost), Theme.Colors.Accent, function()
		local res = Net.func("Hatch"):InvokeServer()
		if res and not res.ok and res.reason then
			Notifications.show(res.reason, "warn")
		end
	end)
	hatch.Parent = bar

	button("👶 Babies", Theme.Colors.PanelLight, function()
		showPanel(panels.babies.Visible and nil or "babies")
	end).Parent = bar

	button("🚚 Caravan", Theme.Colors.PanelLight, function()
		showPanel(panels.caravan.Visible and nil or "caravan")
	end).Parent = bar

	button("🛒 Garage", Theme.Colors.PanelLight, function()
		showPanel(panels.shop.Visible and nil or "shop")
	end).Parent = bar
end

--========================================================================--
--  PANEL SHELL
--========================================================================--
local function makePanel(name: string, title: string, parent: ScreenGui): (Frame, ScrollingFrame)
	local panel = Make("Frame", {
		Name = name,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(0, 560, 0, 460),
		BackgroundColor3 = Theme.Colors.Panel,
		Visible = false,
		Parent = parent,
	}, {
		Theme.corner(18),
		Theme.stroke(2, Theme.Colors.PanelLight),
	})

	Make("TextLabel", {
		Size = UDim2.new(1, -40, 0, 44),
		Position = UDim2.new(0, 16, 0, 10),
		BackgroundTransparency = 1,
		Font = Theme.Font,
		Text = title,
		TextColor3 = Theme.Colors.Text,
		TextSize = 24,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = panel,
	})

	local close = button("✕", Theme.Colors.Bad, function()
		showPanel(nil)
	end)
	close.AnchorPoint = Vector2.new(1, 0)
	close.Position = UDim2.new(1, -10, 0, 12)
	close.Size = UDim2.new(0, 40, 0, 36)
	close.Parent = panel

	local scroll = Make("ScrollingFrame", {
		Name = "Content",
		Position = UDim2.new(0, 12, 0, 60),
		Size = UDim2.new(1, -24, 1, -72),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 6,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		Parent = panel,
	}, {
		Make("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }),
	})

	panels[name] = panel
	return panel, scroll
end

--========================================================================--
--  BABIES PANEL (collection + place/recall + caravan selection)
--========================================================================--
local function buildBabiesPanel(parent: ScreenGui)
	local _, scroll = makePanel("babies", "👶 My Babies", parent)
	refs.babiesScroll = scroll

	refs.collectedHeader = Make("TextLabel", {
		Size = UDim2.new(1, 0, 0, 22),
		BackgroundTransparency = 1,
		Font = Theme.BodyFont,
		Text = "Collected 0 / " .. BabyData.count(),
		TextColor3 = Theme.Colors.SubText,
		TextSize = 15,
		TextXAlignment = Enum.TextXAlignment.Left,
		LayoutOrder = 0,
		Parent = scroll,
	})
end

local function refreshBabies(snap: any)
	local scroll = refs.babiesScroll
	if not scroll then
		return
	end
	-- Clear previous rows (keep header at LayoutOrder 0).
	for _, child in scroll:GetChildren() do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	local collectedCount = 0
	for _ in snap.collectedIds do
		collectedCount += 1
	end
	refs.collectedHeader.Text = string.format("Collected %d / %d", collectedCount, BabyData.count())

	local caravanActive = snap.activeCaravan and not snap.activeCaravan.resolved
	for i, owned in snap.babies do
		local def = BabyData.get(owned.babyId)
		if not def then
			continue
		end
		local rarity = Rarity.get(def.rarity)
		local role = Roles.get(def.role)
		local income = BabyData.incomePerSecond(owned.babyId)

		local row = Make("Frame", {
			Size = UDim2.new(1, 0, 0, 52),
			BackgroundColor3 = Theme.Colors.PanelLight,
			LayoutOrder = i,
			Parent = scroll,
		}, {
			Theme.corner(10),
			Theme.stroke(2, rarity.color),
			Theme.pad(8),
			Make("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				Padding = UDim.new(0, 8),
				VerticalAlignment = Enum.VerticalAlignment.Center,
			}),
		})

		-- Art thumbnail: the baby's real 2D artwork if provided, else a rarity tile.
		local thumb = Make(def.image and "ImageLabel" or "Frame", {
			Size = UDim2.new(0, 40, 0, 40),
			BackgroundColor3 = rarity.color,
			BackgroundTransparency = def.image and 1 or 0.25,
			Parent = row,
		}, { Theme.corner(8) })
		if def.image then
			thumb.Image = def.image
			thumb.ScaleType = Enum.ScaleType.Fit
		end

		Make("Frame", {
			Size = UDim2.new(0, 6, 1, 0),
			BackgroundColor3 = role.color,
			Parent = row,
		}, { Theme.corner(3) })

		Make("TextLabel", {
			Size = UDim2.new(0, 250, 1, 0),
			BackgroundTransparency = 1,
			Font = Theme.BodyFont,
			RichText = true,
			Text = string.format(
				"<b>%s</b>\n<font color='#%s'>%s</font> · %s · 💰%.0f/s",
				def.name,
				rarity.color:ToHex(),
				def.rarity,
				role.displayName,
				income
			),
			TextColor3 = Theme.Colors.Text,
			TextSize = 14,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Center,
			Parent = row,
		})

		-- Place / Recall toggle.
		local placeBtn = button(
			owned.placed and "Recall" or "Place",
			owned.placed and Theme.Colors.Warn or Theme.Colors.Good,
			function()
				local fn = owned.placed and "RecallBaby" or "PlaceBaby"
				local res = Net.func(fn):InvokeServer(owned.uid)
				if res and not res.ok and res.reason then
					Notifications.show(res.reason, "warn")
				end
			end
		)
		placeBtn.Size = UDim2.new(0, 86, 0, 34)
		placeBtn.AutomaticSize = Enum.AutomaticSize.None
		placeBtn.Parent = row

		-- Caravan load toggle (disabled while a run is active).
		if not caravanActive then
			local isSel = selected[owned.uid] == true
			local loadBtn = button(isSel and "✓ Loaded" or "Load", isSel and Theme.Colors.Accent or Theme.Colors.PanelLight, function()
				selected[owned.uid] = not selected[owned.uid] or nil
				refreshBabies(State.current)
			end)
			loadBtn.Size = UDim2.new(0, 86, 0, 34)
			loadBtn.AutomaticSize = Enum.AutomaticSize.None
			loadBtn.Parent = row
		end
	end

	if #snap.babies == 0 then
		Make("TextLabel", {
			Size = UDim2.new(1, 0, 0, 40),
			BackgroundTransparency = 1,
			Font = Theme.BodyFont,
			Text = "No babies yet — hatch one to get started!",
			TextColor3 = Theme.Colors.SubText,
			TextSize = 15,
			LayoutOrder = 1,
			Parent = scroll,
		})
	end
end

--========================================================================--
--  CARAVAN PANEL
--========================================================================--
local function buildCaravanPanel(parent: ScreenGui)
	local _, scroll = makePanel("caravan", "🚚 Caravan Run", parent)
	refs.caravanScroll = scroll
end

local function caravanRow(scroll: ScrollingFrame, order: number, text: string): TextLabel
	return Make("TextLabel", {
		Size = UDim2.new(1, 0, 0, 22),
		BackgroundTransparency = 1,
		Font = Theme.BodyFont,
		Text = text,
		TextColor3 = Theme.Colors.SubText,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		LayoutOrder = order,
		Parent = scroll,
	})
end

local function refreshCaravan(snap: any)
	local scroll = refs.caravanScroll
	if not scroll then
		return
	end
	for _, child in scroll:GetChildren() do
		if not child:IsA("UIListLayout") then
			child:Destroy()
		end
	end

	-- Active run view.
	if snap.activeCaravan and not snap.activeCaravan.resolved then
		local run = snap.activeCaravan
		local remaining = math.max(0, (run.startedAt + run.duration) - os.time())
		caravanRow(scroll, 1, string.format("Pot at stake: 💰 %s", fmt(run.potValue)))
		caravanRow(scroll, 2, string.format("Vehicle: %s · Insurance: %s", run.vehicleId, run.insuranceId))

		if remaining > 0 then
			refs.caravanTimer = caravanRow(scroll, 3, string.format("⏳ En route — %ds remaining…", remaining))
		else
			caravanRow(scroll, 3, "✅ Arrived! Choose how to settle:")
			local actions = Make("Frame", {
				Size = UDim2.new(1, 0, 0, 44),
				BackgroundTransparency = 1,
				LayoutOrder = 4,
				Parent = scroll,
			}, {
				Make("UIListLayout", {
					FillDirection = Enum.FillDirection.Horizontal,
					Padding = UDim.new(0, 8),
				}),
			})
			local function settle(betray: boolean)
				local res = Net.func("ResolveCaravan"):InvokeServer(run.runId, betray)
				if res and not res.ok and res.reason then
					Notifications.show(res.reason, "warn")
				end
			end
			button("🤝 Split Fairly (+Trust)", Theme.Colors.Good, function()
				settle(false)
			end).Parent = actions
			button("😈 Betray (+50% Coins, -Trust)", Theme.Colors.Bad, function()
				settle(true)
			end).Parent = actions
		end
		return
	end

	-- Setup view: vehicle, insurance, loadout, launch.
	caravanRow(scroll, 1, "1. Pick a vehicle (owned):")
	local vehFrame = Make("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = 2,
		Parent = scroll,
	}, { Make("UIListLayout", { Padding = UDim.new(0, 6) }) })

	for _, vId in snap.ownedVehicles do
		local v = VehicleData.get(vId)
		if v then
			local sel = chosenVehicle == vId
			local b = button(
				string.format("%s  (cap %d · spd %d · def %d · fuel %d)", v.name, v.capacity, v.speed, v.defense, v.fuelCost),
				sel and Theme.Colors.Accent or Theme.Colors.PanelLight,
				function()
					chosenVehicle = vId
					refreshCaravan(State.current)
				end
			)
			b.Size = UDim2.new(1, 0, 0, 32)
			b.AutomaticSize = Enum.AutomaticSize.None
			b.TextXAlignment = Enum.TextXAlignment.Left
			b.Parent = vehFrame
		end
	end

	caravanRow(scroll, 3, "2. Buy insurance for the trip:")
	local insFrame = Make("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = 4,
		Parent = scroll,
	}, { Make("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6) }) })
	for _, insId in InsuranceData.Order do
		local ins = InsuranceData.get(insId)
		local sel = chosenInsurance == insId
		local b = button(
			string.format("%s (%d)", ins.displayName, ins.cost),
			sel and Theme.Colors.Accent2 or Theme.Colors.PanelLight,
			function()
				chosenInsurance = insId
				refreshCaravan(State.current)
			end
		)
		b.Size = UDim2.new(0, 0, 0, 32)
		b.AutomaticSize = Enum.AutomaticSize.X
		b.Parent = insFrame
	end

	-- Loadout summary.
	local count, pot = 0, 0
	for uid in selected do
		for _, owned in snap.babies do
			if owned.uid == uid then
				count += 1
				pot += BabyData.incomePerSecond(owned.babyId) * 20
			end
		end
	end
	caravanRow(scroll, 5, string.format("3. Loaded %d baby(s) — open My Babies to Load them.", count))
	caravanRow(scroll, 6, string.format("Estimated pot: 💰 %s", fmt(pot)))

	local launch = button("🚀 Launch Caravan", Theme.Colors.Accent, function()
		local uids = {}
		for uid in selected do
			table.insert(uids, uid)
		end
		local res = Net.func("StartCaravan"):InvokeServer(chosenVehicle, chosenInsurance, uids)
		if res and res.ok then
			selected = {}
			Notifications.show("Caravan launched! Come back when it arrives.", "good")
		elseif res and res.reason then
			Notifications.show(res.reason, "warn")
		end
	end)
	launch.Size = UDim2.new(1, 0, 0, 40)
	launch.AutomaticSize = Enum.AutomaticSize.None
	launch.LayoutOrder = 7
	launch.Parent = scroll
end

--========================================================================--
--  GARAGE / SHOP PANEL
--========================================================================--
local function buildShopPanel(parent: ScreenGui)
	local _, scroll = makePanel("shop", "🛒 Garage", parent)
	refs.shopScroll = scroll
end

local function refreshShop(snap: any)
	local scroll = refs.shopScroll
	if not scroll then
		return
	end
	for _, child in scroll:GetChildren() do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
	for i, v in VehicleData.List do
		local owned = table.find(snap.ownedVehicles, v.id) ~= nil
		local row = Make("Frame", {
			Size = UDim2.new(1, 0, 0, 54),
			BackgroundColor3 = Theme.Colors.PanelLight,
			LayoutOrder = i,
			Parent = scroll,
		}, {
			Theme.corner(10),
			Theme.pad(8),
			Make("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				Padding = UDim.new(0, 8),
				VerticalAlignment = Enum.VerticalAlignment.Center,
			}),
		})
		Make("TextLabel", {
			Size = UDim2.new(0, 360, 1, 0),
			BackgroundTransparency = 1,
			Font = Theme.BodyFont,
			RichText = true,
			Text = string.format(
				"<b>%s</b>\ncap %d · spd %d · def %d · fuel %d · %s",
				v.name, v.capacity, v.speed, v.defense, v.fuelCost, v.blurb
			),
			TextColor3 = Theme.Colors.Text,
			TextSize = 13,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = row,
		})
		if owned then
			Make("TextLabel", {
				Size = UDim2.new(0, 110, 1, 0),
				BackgroundTransparency = 1,
				Font = Theme.Font,
				Text = "✓ Owned",
				TextColor3 = Theme.Colors.Good,
				TextSize = 16,
				Parent = row,
			})
		else
			local b = button(string.format("Buy (%s)", fmt(v.cost)), Theme.Colors.Accent2, function()
				local res = Net.func("BuyVehicle"):InvokeServer(v.id)
				if res and not res.ok and res.reason then
					Notifications.show(res.reason, "warn")
				end
			end)
			b.Size = UDim2.new(0, 130, 0, 36)
			b.AutomaticSize = Enum.AutomaticSize.None
			b.Parent = row
		end
	end
end

--========================================================================--
--  PUBLIC
--========================================================================--
function UI.mount()
	local player = Players.LocalPlayer
	local gui = Make("ScreenGui", {
		Name = "FortuneBeastsUI",
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		IgnoreGuiInset = true,
		Parent = player:WaitForChild("PlayerGui"),
	})

	buildTopBar(gui)
	buildActionBar(gui)
	buildBabiesPanel(gui)
	buildCaravanPanel(gui)
	buildShopPanel(gui)
	Notifications.mount(gui)

	-- Re-render whenever the server pushes a new snapshot.
	State.subscribe(function(snap)
		if not snap then
			return
		end
		refs.coins.Text = string.format("💰 %s", fmt(snap.coins))
		refs.income.Text = string.format("📈 %.0f/s", incomeRate(snap))
		refs.trust.Text = string.format("🤝 Trust %d", snap.trust)
		if panels.babies.Visible then
			refreshBabies(snap)
		end
		if panels.caravan.Visible then
			refreshCaravan(snap)
		end
		if panels.shop.Visible then
			refreshShop(snap)
		end
	end)

	-- Refresh the open panel when first shown.
	for name, panel in panels do
		panel:GetPropertyChangedSignal("Visible"):Connect(function()
			if panel.Visible and State.current then
				if name == "babies" then
					refreshBabies(State.current)
				elseif name == "caravan" then
					refreshCaravan(State.current)
				elseif name == "shop" then
					refreshShop(State.current)
				end
			end
		end)
	end

	-- Live countdown for an active caravan.
	task.spawn(function()
		while true do
			task.wait(1)
			if panels.caravan.Visible and State.current then
				refreshCaravan(State.current)
			end
		end
	end)
end

return UI
