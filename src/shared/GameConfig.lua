--[[
	GameConfig
	One place for every tunable number in the game.
	Change a value here, press Play, and the whole game uses it.
]]

local GameConfig = {
	-- ========== ECONOMY ==========
	incomeTickSeconds = 10, -- how often beasts pay out
	exposedIncomeMultiplier = 1, -- exposed beasts earn 100%
	vaultIncomeMultiplier = 0.5, -- vaulted beasts earn 50%
	startingCoins = 100,

	-- ========== PLOTS ==========
	maxPlayersSupported = 8,
	exposedSlotsPerPlot = 6,
	vaultSlotsPerPlot = 2,

	-- ========== STEALING ==========
	stealMaxDistance = 12, -- studs; also used as the ProximityPrompt range
	beginnerProtectionSeconds = 180, -- new players cannot be robbed for 3 minutes
	postTheftProtectionSeconds = 60, -- after being robbed, safe for 1 minute
	grabBackDistance = 6, -- if the owner gets this close to the thief, the beast is dropped and returned

	-- ========== CARAVAN ==========
	caravanJoinWindowSeconds = 20, -- time for a 2nd player to join
	caravanWagonSpeed = 14, -- studs per second
	caravanEscortDistance = 25, -- members must stay this close or the wagon pauses
	caravanChoiceTimeoutSeconds = 30, -- no answer = Split Fair
	caravanCooldownSeconds = 15, -- per-player cooldown between caravans
	soloCaravanReward = 50,
	twoPlayerCaravanRewardPool = 120,
	fairSplitEachReward = 60, -- both split fair
	betrayerReward = 90, -- one betrays
	betrayedReward = 30,
	bothBetrayEachReward = 40, -- both betray = reduced reward

	-- ========== TRUST / OATHBREAKER ==========
	fairSplitTrustGain = 5,
	betrayalTrustLoss = 10,
	oathbreakerDurationSeconds = 600, -- single betrayer
	bothBetrayOathbreakerSeconds = 300, -- both betray = shorter mark

	-- ========== MARKET (coin prices; DebtDragon is "free" but has consequences) ==========
	marketPrices = {
		VaultTurtle = 60,
		TrustOwl = 80,
		DebtDragon = 0,
	},
	hatchPrice = 150, -- Mystery Egg: random baby from the 300-strong catalog

	-- ========== MISC ==========
	baseWalkSpeed = 20,
	debug = true, -- set false to silence [FB] debug prints
}

return GameConfig
