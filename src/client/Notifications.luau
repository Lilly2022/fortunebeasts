--!strict
-- Toast notifications stacked at the top-right. kind: "good" | "warn" | "bad".

local TweenService = game:GetService("TweenService")
local Make = require(script.Parent.Make)
local Theme = require(script.Parent.Theme)

local Notifications = {}

local container: Frame? = nil

function Notifications.mount(parent: ScreenGui)
	container = Make("Frame", {
		Name = "Toasts",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -16, 0, 90),
		Size = UDim2.new(0, 320, 1, -120),
		BackgroundTransparency = 1,
		Parent = parent,
	}, {
		Make("UIListLayout", {
			Padding = UDim.new(0, 8),
			HorizontalAlignment = Enum.HorizontalAlignment.Right,
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})
end

local kindColor = {
	good = Theme.Colors.Good,
	warn = Theme.Colors.Warn,
	bad = Theme.Colors.Bad,
}

function Notifications.show(text: string, kind: string?)
	if not container then
		return
	end
	local accent = kindColor[kind or "good"] or Theme.Colors.Good

	local toast = Make("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = Theme.Colors.Panel,
		BackgroundTransparency = 0,
		Parent = container,
	}, {
		Theme.corner(12),
		Theme.stroke(2, accent),
		Theme.pad(10),
		Make("UIListLayout", { Padding = UDim.new(0, 2) }),
		Make("TextLabel", {
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			Font = Theme.BodyFont,
			Text = text,
			TextColor3 = Theme.Colors.Text,
			TextSize = 15,
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left,
		}),
	})

	toast.BackgroundTransparency = 1
	TweenService:Create(toast, TweenInfo.new(0.2), { BackgroundTransparency = 0 }):Play()

	task.delay(4, function()
		local fade = TweenService:Create(toast, TweenInfo.new(0.35), { BackgroundTransparency = 1 })
		fade:Play()
		fade.Completed:Wait()
		toast:Destroy()
	end)
end

return Notifications
