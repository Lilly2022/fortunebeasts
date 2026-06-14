--!strict
-- Shared visual style for the UI — playful, rounded, candy colours to match the
-- squishy concept art.

local Theme = {}

Theme.Font = Enum.Font.FredokaOne
Theme.BodyFont = Enum.Font.GothamMedium

Theme.Colors = {
	Panel = Color3.fromRGB(34, 30, 48),
	PanelLight = Color3.fromRGB(52, 46, 72),
	Accent = Color3.fromRGB(245, 90, 160), -- bubblegum pink
	Accent2 = Color3.fromRGB(245, 180, 60), -- coin gold
	Good = Color3.fromRGB(96, 200, 120),
	Warn = Color3.fromRGB(240, 150, 60),
	Bad = Color3.fromRGB(225, 80, 80),
	Text = Color3.fromRGB(245, 245, 250),
	SubText = Color3.fromRGB(180, 180, 200),
	Coin = Color3.fromRGB(245, 200, 70),
}

function Theme.corner(radius: number): UICorner
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius)
	return c
end

function Theme.pad(px: number): UIPadding
	local p = Instance.new("UIPadding")
	p.PaddingTop = UDim.new(0, px)
	p.PaddingBottom = UDim.new(0, px)
	p.PaddingLeft = UDim.new(0, px)
	p.PaddingRight = UDim.new(0, px)
	return p
end

function Theme.stroke(thickness: number, color: Color3): UIStroke
	local s = Instance.new("UIStroke")
	s.Thickness = thickness
	s.Color = color
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	return s
end

return Theme
