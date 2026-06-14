--!strict
-- Insurance plans (保险系统). Reduce your losses when a caravan is ambushed,
-- a baby is stolen, a vehicle breaks down, or a teammate betrays you.
-- Higher tiers pay out more but cost more up front — "buy insurance, cry less".

export type InsuranceId = "none" | "basic" | "standard" | "full"

export type InsuranceDef = {
	id: InsuranceId,
	displayName: string,
	cost: number, -- premium paid per caravan run
	payoutRatio: number, -- fraction of lost value reimbursed (0..1)
	blurb: string,
}

local InsuranceData = {}

InsuranceData.Order = { "none", "basic", "standard", "full" } :: { InsuranceId }

InsuranceData.Info = {
	none = { id = "none", displayName = "No Cover", cost = 0, payoutRatio = 0, blurb = "Living dangerously." },
	basic = { id = "basic", displayName = "Basic Cover", cost = 150, payoutRatio = 0.3, blurb = "Cheap peace of mind — 30% back." },
	standard = { id = "standard", displayName = "Standard Cover", cost = 400, payoutRatio = 0.5, blurb = "Best value — 50% back." },
	full = { id = "full", displayName = "Full Cover", cost = 900, payoutRatio = 0.7, blurb = "Sleep easy — 70% back." },
} :: { [string]: InsuranceDef }

function InsuranceData.get(id: InsuranceId): InsuranceDef
	return InsuranceData.Info[id]
end

return InsuranceData
