--[[
	StealService
	The heist loop:
	1. Thief holds F on someone's EXPOSED beast (ProximityPrompt, server validates everything)
	2. Beast sticks to the thief's back; thief walks slower
	3. Owner gets a loud RAID ALERT and can chase
	4. If the OWNER gets within grabBackDistance of the thief -> beast drops home
	5. If the thief dies or leaves -> beast returns home
	6. If the thief reaches THEIR OWN capture zone -> ownership transfers,
	   victim gets 60s of protection

	All rules checked on the server. The client is never trusted.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local GameConfig = require(ReplicatedStorage.FB_Modules.GameConfig)
local BeastConfig = require(ReplicatedStorage.FB_Modules.BeastConfig)

local StealService = {}

local carrying = {} -- [thief Player] = record being carried
local services

local function dprint(...)
	if GameConfig.debug then
		print("[FB][Steal]", ...)
	end
end

local function getRoot(player)
	local character = player.Character
	return character and character:FindFirstChild("HumanoidRootPart")
end

local function getHumanoid(player)
	local character = player.Character
	return character and character:FindFirstChildOfClass("Humanoid")
end

-- Stop carrying: unweld and restore walk speed. Does NOT decide where the beast goes.
local function detach(thief)
	local record = carrying[thief]
	if not record then
		return nil
	end
	carrying[thief] = nil
	local body = record.model and record.model.PrimaryPart
	if body then
		local weld = body:FindFirstChild("FB_CarryWeld")
		if weld then
			weld:Destroy()
		end
	end
	local humanoid = getHumanoid(thief)
	if humanoid then
		humanoid.WalkSpeed = GameConfig.baseWalkSpeed
	end
	return record
end

-- Beast escapes the thief and goes back to its owner's pad
local function dropAndReturn(thief, reason)
	local record = detach(thief)
	if not record then
		return
	end
	if record.model and record.model.Parent then
		services.Beast.returnBeast(record)
		services.PlayerData.alert(
			record.owner,
			"✅ Your " .. BeastConfig.get(record.beastId).displayName .. " is back home! (" .. reason .. ")",
			"info"
		)
	end
	services.PlayerData.alert(thief, "💨 You dropped the beast! (" .. reason .. ")", "warn")
	dprint(("%s dropped the beast: %s"):format(thief.Name, reason))
end

-- ============ THE STEAL ATTEMPT (prompt already held for stealTime) ============

function StealService.trySteal(thief, record)
	local beastDef = BeastConfig.get(record.beastId)
	local victim = record.owner

	-- Server-side validation, every rule from the design doc:
	if victim == thief then
		return -- your own beast; use E to move it instead
	end
	if record.carriedBy then
		services.PlayerData.alert(thief, "❌ Someone is already carrying that beast!", "warn")
		return
	end
	if record.slotType ~= "exposed" then
		services.PlayerData.alert(thief, "🔒 That beast is in a vault. Vaulted beasts can't be stolen!", "warn")
		return
	end
	if carrying[thief] then
		services.PlayerData.alert(thief, "❌ You're already carrying a beast! Get it home first!", "warn")
		return
	end
	if services.PlayerData.isProtected(victim) then
		services.PlayerData.alert(
			thief,
			"🛡️ " .. victim.DisplayName .. " is protected right now. Try later!",
			"warn"
		)
		return
	end
	local thiefRoot = getRoot(thief)
	local body = record.model.PrimaryPart
	if not thiefRoot or not body then
		return
	end
	if (thiefRoot.Position - body.Position).Magnitude > GameConfig.stealMaxDistance + 6 then
		dprint(thief.Name .. " too far away - steal rejected")
		return
	end

	-- ============ SUCCESS: attach beast to the thief's back ============
	record.carriedBy = thief
	carrying[thief] = record

	body.Anchored = false
	for _, part in ipairs(record.model:GetDescendants()) do
		if part:IsA("BasePart") then
			part.CanCollide = false
			part.Massless = true
		end
	end
	record.model:PivotTo(thiefRoot.CFrame * CFrame.new(0, 2.6, 1.6))
	local weld = Instance.new("WeldConstraint")
	weld.Name = "FB_CarryWeld"
	weld.Part0 = body
	weld.Part1 = thiefRoot
	weld.Parent = body

	local humanoid = getHumanoid(thief)
	if humanoid then
		humanoid.WalkSpeed = GameConfig.baseWalkSpeed * beastDef.carrySpeedMultiplier
	end

	-- RAID ALERT for the victim + heads up for everyone
	services.PlayerData.alert(
		victim,
		("🚨 RAID! %s is stealing your %s! CHASE THEM!"):format(thief.DisplayName, beastDef.displayName),
		"raid"
	)
	services.PlayerData.alert(
		thief,
		("😈 You grabbed %s's %s! Run to your CAPTURE ZONE!"):format(victim.DisplayName, beastDef.displayName),
		"gold"
	)
	dprint(("%s stole %s from %s - the chase is on!"):format(thief.Name, record.beastId, victim.Name))
end

-- ============ THE CHASE (checked every 0.2s) ============

local function watchCarriers()
	while true do
		task.wait(0.2)
		-- Snapshot the list first: handlers below add/remove entries in
		-- `carrying`, and mutating a table while pairs()-ing it can error.
		local thieves = {}
		for thief in pairs(carrying) do
			table.insert(thieves, thief)
		end
		for _, thief in ipairs(thieves) do
			local record = carrying[thief]
			if not record then
				continue
			end
			-- Beast's model vanished (owner left etc.) -> just stop carrying
			if not record.model or not record.model.Parent then
				detach(thief)
				continue
			end
			if not record.owner.Parent then
				-- Victim left the game; their beasts get destroyed by BeastService
				detach(thief)
				continue
			end

			local thiefRoot = getRoot(thief)
			if not thiefRoot then
				dropAndReturn(thief, "thief lost their character")
				continue
			end

			-- Owner caught up? Beast escapes!
			local victimRoot = getRoot(record.owner)
			if victimRoot and (victimRoot.Position - thiefRoot.Position).Magnitude <= GameConfig.grabBackDistance then
				services.PlayerData.alert(record.owner, "💪 You caught the thief! Beast recovered!", "gold")
				dropAndReturn(thief, "the owner caught you")
				continue
			end

			-- Thief reached their own capture zone? Ownership transfers!
			local plot = services.Plot.getPlot(thief)
			if plot then
				local zonePosition = plot.captureZone.Position
				local flat =
					Vector3.new(thiefRoot.Position.X - zonePosition.X, 0, thiefRoot.Position.Z - zonePosition.Z)
				if flat.Magnitude <= 7 then
					local victim = record.owner
					local beastName = BeastConfig.get(record.beastId).displayName
					detach(thief)
					if services.Beast.transferBeast(record, thief) then
						services.PlayerData.giveProtection(
							victim,
							GameConfig.postTheftProtectionSeconds,
							"you were robbed"
						)
						services.PlayerData.alert(
							victim,
							("💔 %s got away with your %s! You're protected for %ds."):format(
								thief.DisplayName,
								beastName,
								GameConfig.postTheftProtectionSeconds
							),
							"raid"
						)
						services.PlayerData.alert(thief, ("🏆 %s is YOURS now!"):format(beastName), "gold")
					else
						-- Thief's base is full: beast escapes home instead
						services.Beast.returnBeast(record)
						services.PlayerData.alert(
							victim,
							"✅ Your " .. beastName .. " is back home! (the thief's base was full)",
							"info"
						)
						services.PlayerData.alert(thief, "💨 Your base is full! The beast escaped home!", "warn")
						dprint(thief.Name .. " couldn't claim - base full, beast returned")
					end
				end
			end
		end
	end
end

-- ============ LIFECYCLE ============

function StealService.init(injectedServices)
	services = injectedServices

	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function(character)
			local humanoid = character:WaitForChild("Humanoid")
			humanoid.Died:Connect(function()
				if carrying[player] then
					dropAndReturn(player, "you died")
				end
			end)
		end)
	end)

	Players.PlayerRemoving:Connect(function(player)
		if carrying[player] then
			dropAndReturn(player, "thief left the game")
		end
	end)

	task.spawn(watchCarriers)
end

return StealService
