--!strict
-- Small shared helpers.

local Util = {}

local uidCounter = 0

-- Reasonably-unique id for owned babies / caravan runs.
function Util.uid(prefix: string?): string
	uidCounter += 1
	return string.format("%s%d_%d", prefix or "id", os.clock() // 1, uidCounter)
end

-- Weighted random pick. `weights` maps key -> positive weight. Returns a key.
function Util.weightedPick<T>(weights: { [T]: number }): T
	local total = 0
	for _, w in weights do
		total += w
	end
	local roll = math.random() * total
	local cursor = 0
	local last: T
	for key, w in weights do
		last = key
		cursor += w
		if roll <= cursor then
			return key
		end
	end
	return last
end

function Util.round(n: number): number
	return math.floor(n + 0.5)
end

function Util.clamp(n: number, lo: number, hi: number): number
	return math.max(lo, math.min(hi, n))
end

return Util
