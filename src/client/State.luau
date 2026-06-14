--!strict
-- Client-side mirror of the player's profile. The server is authoritative; this
-- just caches the latest StateUpdate snapshot and fires listeners when it changes
-- so the UI can re-render.

local State = {}

State.current = nil :: any

local listeners: { (any) -> () } = {}

function State.set(snapshot: any)
	State.current = snapshot
	for _, fn in listeners do
		task.spawn(fn, snapshot)
	end
end

-- Subscribe to changes. Fires immediately with the current snapshot if present.
function State.subscribe(fn: (any) -> ()): () -> ()
	table.insert(listeners, fn)
	if State.current then
		task.spawn(fn, State.current)
	end
	return function()
		local i = table.find(listeners, fn)
		if i then
			table.remove(listeners, i)
		end
	end
end

return State
