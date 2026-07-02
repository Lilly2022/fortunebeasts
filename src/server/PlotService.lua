--[[
	PlotService
	Builds 8 player plots in a ring around the market and assigns one
	to each player who joins.

	Each plot has:
	- a floor + name sign
	- 6 EXPOSED pads (front) - beasts here earn 100% but can be stolen
	- a small VAULT hut with 2 pads - beasts here earn 50% but are SAFE
	- a CAPTURE ZONE - thieves must carry stolen beasts here to claim them
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.FB_Modules.GameConfig)

local PlotService = {}

local plots = {} -- [index] = { model, owner, exposedPads = {}, vaultPads = {}, captureZone, signText }
local plotByPlayer = {} -- [player] = plot table
local services

local function dprint(...)
	if GameConfig.debug then
		print("[FB][Plot]", ...)
	end
end

local function part(props)
	local p = Instance.new("Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for key, value in pairs(props) do
		p[key] = value
	end
	return p
end

-- Flat cylinder pad lying on the ground
local function makePad(cf, diameter, color, name)
	return part({
		Name = name,
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.4, diameter, diameter),
		CFrame = cf * CFrame.Angles(0, 0, math.rad(90)),
		Color = color,
		Material = Enum.Material.SmoothPlastic,
	})
end

local function buildPlot(index, plotCF)
	local model = Instance.new("Model")
	model.Name = "Plot" .. index

	local floor = part({
		Name = "Floor",
		Size = Vector3.new(60, 1, 60),
		CFrame = plotCF * CFrame.new(0, 0.5, 0),
		Color = Color3.fromRGB(196, 178, 145),
		Material = Enum.Material.WoodPlanks,
	})
	floor.Parent = model

	-- Name sign at the front edge (facing the market)
	local signPost = part({
		Name = "Sign",
		Size = Vector3.new(10, 4, 1),
		CFrame = plotCF * CFrame.new(0, 3, -29),
		Color = Color3.fromRGB(120, 90, 60),
		Material = Enum.Material.Wood,
	})
	signPost.Parent = model
	local surfaceGui = Instance.new("SurfaceGui")
	surfaceGui.Face = Enum.NormalId.Front
	surfaceGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	surfaceGui.PixelsPerStud = 30
	local signText = Instance.new("TextLabel")
	signText.Size = UDim2.new(1, 0, 1, 0)
	signText.BackgroundTransparency = 1
	signText.Text = "🏠 Unclaimed"
	signText.TextScaled = true
	signText.Font = Enum.Font.FredokaOne
	signText.TextColor3 = Color3.new(1, 1, 1)
	signText.Parent = surfaceGui
	surfaceGui.Parent = signPost

	-- 6 exposed pads: 2 rows of 3 in the front half
	local exposedPads = {}
	for slot = 1, GameConfig.exposedSlotsPerPlot do
		local row = math.ceil(slot / 3) -- 1 or 2
		local column = ((slot - 1) % 3) - 1 -- -1, 0, 1
		local pad = makePad(
			plotCF * CFrame.new(column * 14, 1.2, -18 + row * 8),
			6,
			Color3.fromRGB(235, 220, 130),
			"ExposedPad" .. slot
		)
		pad:SetAttribute("SlotType", "exposed")
		pad:SetAttribute("SlotIndex", slot)
		pad.Parent = model
		exposedPads[slot] = pad
	end

	-- Vault hut at the back with 2 pads inside
	local vaultFloor = part({
		Name = "VaultFloor",
		Size = Vector3.new(20, 0.4, 12),
		CFrame = plotCF * CFrame.new(0, 1.2, 20),
		Color = Color3.fromRGB(110, 110, 120),
		Material = Enum.Material.Slate,
	})
	vaultFloor.Parent = model
	local wallColor = Color3.fromRGB(90, 90, 100)
	for _, wall in ipairs({
		{ Vector3.new(20, 8, 1), CFrame.new(0, 5, 26) }, -- back
		{ Vector3.new(1, 8, 12), CFrame.new(-10, 5, 20) }, -- left
		{ Vector3.new(1, 8, 12), CFrame.new(10, 5, 20) }, -- right
		{ Vector3.new(20, 1, 12), CFrame.new(0, 9.5, 20) }, -- roof
		{ Vector3.new(7, 8, 1), CFrame.new(-6.5, 5, 14) }, -- front-left (leaves a doorway)
		{ Vector3.new(7, 8, 1), CFrame.new(6.5, 5, 14) }, -- front-right
	}) do
		local wallPart = part({
			Name = "VaultWall",
			Size = wall[1],
			CFrame = plotCF * wall[2],
			Color = wallColor,
			Material = Enum.Material.Slate,
		})
		wallPart.Parent = model
	end
	local vaultPads = {}
	for slot = 1, GameConfig.vaultSlotsPerPlot do
		local pad = makePad(
			plotCF * CFrame.new((slot - 1.5) * 9, 1.6, 21),
			5,
			Color3.fromRGB(140, 200, 255),
			"VaultPad" .. slot
		)
		pad:SetAttribute("SlotType", "vault")
		pad:SetAttribute("SlotIndex", slot)
		pad.Parent = model
		vaultPads[slot] = pad
	end

	-- Capture zone: thieves bring stolen beasts here
	local captureZone = makePad(plotCF * CFrame.new(-22, 1.2, 2), 10, Color3.fromRGB(255, 120, 120), "CaptureZone")
	captureZone.Material = Enum.Material.Neon
	captureZone.Parent = model
	local captureBillboard = Instance.new("BillboardGui")
	captureBillboard.Size = UDim2.new(0, 180, 0, 36)
	captureBillboard.StudsOffset = Vector3.new(0, 4, 0)
	captureBillboard.AlwaysOnTop = true
	captureBillboard.MaxDistance = 120
	local captureText = Instance.new("TextLabel")
	captureText.Size = UDim2.new(1, 0, 1, 0)
	captureText.BackgroundTransparency = 1
	captureText.Text = "🎯 Capture Zone"
	captureText.TextScaled = true
	captureText.Font = Enum.Font.FredokaOne
	captureText.TextColor3 = Color3.new(1, 1, 1)
	captureText.TextStrokeTransparency = 0.2
	captureText.Parent = captureBillboard
	captureBillboard.Parent = captureZone

	model.Parent = workspace.FB_Map.Plots

	return {
		index = index,
		model = model,
		owner = nil,
		exposedPads = exposedPads,
		vaultPads = vaultPads,
		captureZone = captureZone,
		signText = signText,
	}
end

-- ============ PUBLIC API ============

function PlotService.getPlot(player)
	return plotByPlayer[player]
end

function PlotService.getPad(player, slotType, slotIndex)
	local plot = plotByPlayer[player]
	if not plot then
		return nil
	end
	if slotType == "exposed" then
		return plot.exposedPads[slotIndex]
	end
	return plot.vaultPads[slotIndex]
end

-- ============ LIFECYCLE ============

function PlotService.init(injectedServices)
	services = injectedServices

	local plotsFolder = Instance.new("Folder")
	plotsFolder.Name = "Plots"
	plotsFolder.Parent = workspace.FB_Map

	-- 8 plots in a ring, angled so none sit on the caravan route corridor
	local ringRadius = 150
	for index = 1, GameConfig.maxPlayersSupported do
		local angle = math.rad(22.5 + (index - 1) * 45)
		local position = Vector3.new(math.cos(angle) * ringRadius, 0, math.sin(angle) * ringRadius)
		-- Plot faces the market center
		local plotCF = CFrame.lookAt(position, Vector3.new(0, 0, 0))
		plots[index] = buildPlot(index, plotCF)
	end
	dprint(#plots .. " plots built")

	local function assignPlot(player)
		for _, plot in ipairs(plots) do
			if plot.owner == nil then
				plot.owner = player
				plotByPlayer[player] = plot
				plot.signText.Text = "🏠 " .. player.DisplayName .. "'s Base"
				dprint(("Plot %d assigned to %s"):format(plot.index, player.Name))
				return
			end
		end
		warn("[FB][Plot] No free plot for " .. player.Name .. " (server full?)")
	end

	Players.PlayerAdded:Connect(assignPlot)
	for _, player in ipairs(Players:GetPlayers()) do
		if not plotByPlayer[player] then
			assignPlot(player)
		end
	end

	Players.PlayerRemoving:Connect(function(player)
		local plot = plotByPlayer[player]
		if plot then
			plot.owner = nil
			plot.signText.Text = "🏠 Unclaimed"
			plotByPlayer[player] = nil
			dprint(("Plot %d freed (%s left)"):format(plot.index, player.Name))
		end
	end)
end

return PlotService
