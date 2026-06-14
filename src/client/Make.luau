--!strict
-- Terse instance constructor: Make("TextLabel", { props }, { children }).
local Make = {}

function Make.new(className: string, props: { [string]: any }?, children: { Instance }?): any
	local inst = Instance.new(className)
	if props then
		for key, value in props do
			if key ~= "Parent" then
				(inst :: any)[key] = value
			end
		end
	end
	if children then
		for _, child in children do
			child.Parent = inst
		end
	end
	if props and props.Parent then
		inst.Parent = props.Parent
	end
	return inst
end

return setmetatable(Make, {
	__call = function(_, className, props, children)
		return Make.new(className, props, children)
	end,
})
