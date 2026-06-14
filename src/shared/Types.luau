--!strict
-- Shared type definitions for a player's saved profile and the snapshot the
-- client renders from. Keeping these in one module means the DataStore schema
-- and the client UI agree on shape.

export type OwnedBaby = {
	uid: string, -- unique instance id (a player can own duplicates)
	babyId: string, -- references BabyData.ById
	level: number,
	placed: boolean, -- true = out in the open earning more (and stealable)
}

export type CaravanRun = {
	runId: string,
	vehicleId: string,
	insuranceId: string,
	babyUids: { string },
	potValue: number, -- coins at stake
	startedAt: number, -- os.time when launched
	duration: number, -- seconds
	resolved: boolean,
}

export type Profile = {
	coins: number,
	trust: number,
	infamy: number,
	babies: { OwnedBaby },
	ownedVehicles: { string }, -- vehicle ids unlocked (always includes "cart")
	activeCaravan: CaravanRun?,
	collectedIds: { [string]: boolean }, -- dex: which baby ids have been owned
	lastSeen: number, -- os.time of last save, for offline earnings
	stats: {
		babiesHatched: number,
		caravansCompleted: number,
		betrayals: number,
		timesRaided: number,
	},
}

return {}
