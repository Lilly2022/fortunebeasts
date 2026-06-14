--!strict
-- Central tunables for the whole game. Keep gameplay numbers here so balancing
-- never means hunting through service code.

local GameConfig = {}

-- Economy ------------------------------------------------------------------
GameConfig.StartingCoins = 250
GameConfig.HatchCost = 100 -- coins per egg
GameConfig.IncomeTickSeconds = 1 -- how often passive income is granted

-- Raising / placement ------------------------------------------------------
-- A baby kept safely in the vault earns the base rate. Placing it out in the
-- open ("外放") earns more but exposes it to being stolen.
GameConfig.VaultIncomeMultiplier = 1.0
GameConfig.OpenIncomeMultiplier = 2.0
GameConfig.MaxPlacedBabies = 6 -- slots out in the open
GameConfig.BaseBabyCapacity = 24 -- vault storage cap

-- Offline earnings ---------------------------------------------------------
GameConfig.OfflineIncomeEnabled = true
GameConfig.OfflineIncomeCapSeconds = 8 * 60 * 60 -- earn at most 8h while away
GameConfig.OfflineIncomeRate = 0.5 -- offline babies earn at half rate

-- Squish (解压) ------------------------------------------------------------
GameConfig.SquishKey = Enum.KeyCode.E
GameConfig.SquishCooldown = 0.15
GameConfig.SquishComboWindow = 1.5 -- seconds to chain squishes for a combo
GameConfig.SquishCoinReward = 1 -- tiny coin trickle per squish (stress-relief fun)

-- Caravan runs (运娃) ------------------------------------------------------
GameConfig.CaravanBaseDuration = 30 -- seconds for a run before speed factor
GameConfig.CaravanAmbushChance = 0.35 -- base chance of an ambush event
GameConfig.CaravanBetrayBonus = 1.5 -- a betrayer takes this share of the pot

-- Stealing / raids (偷娃 / 护娃) -------------------------------------------
GameConfig.StealCooldown = 60 -- seconds between steal attempts
GameConfig.BaseStealSuccess = 0.5 -- before defense/raid stat adjustments

-- Trust & reputation (信任 / 信誉) ----------------------------------------
GameConfig.StartingTrust = 80
GameConfig.MaxTrust = 100
GameConfig.BetrayTrustPenalty = 25
GameConfig.HonestTrustGain = 3

-- Persistence --------------------------------------------------------------
GameConfig.DataStoreName = "FortuneBeasts_PlayerData_v1"
GameConfig.AutoSaveSeconds = 120

return GameConfig
