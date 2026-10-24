local SZK = { Themes = {}, Windows = {}, Flags = {}, ConfigFolder = "SZK_Configs", CurrentTheme = nil, Icons = {} }

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer and LocalPlayer:GetMouse()

local FONT_TITLE = Enum.Font.Garamond
local FONT_BODY  = Enum.Font.GothamMedium
local FONT_BOLD  = Enum.Font.GothamBold

SZK.IconSources = {
	"https://raw.githubusercontent.com/SZKHUB/SZKSCRIPT/refs/heads/main/OLDICONS1",
	"https://raw.githubusercontent.com/SZKHUB/SZKSCRIPT/refs/heads/main/OLDICONS2",
	"https://raw.githubusercontent.com/SZKHUB/SZKSCRIPT/refs/heads/main/OLDICONS3",
	"https://raw.githubusercontent.com/SZKHUB/SZKSCRIPT/refs/heads/main/OLDICONS4",
	"https://raw.githubusercontent.com/SZKHUB/SZKSCRIPT/refs/heads/main/NEWICONS1",
	"https://raw.githubusercontent.com/SZKHUB/SZKSCRIPT/refs/heads/main/NEWICON2",
	"https://raw.githubusercontent.com/SZKHUB/SZKSCRIPT/refs/heads/main/NEWICON3",
	"https://raw.githubusercontent.com/SZKHUB/SZKSCRIPT/refs/heads/main/NEWICONS4",
	"https://raw.githubusercontent.com/SZKHUB/SZKSCRIPT/refs/heads/main/NEWICON5",
	"https://raw.githubusercontent.com/SZKHUB/SZKSCRIPT/refs/heads/main/NEWICON6",
}

function SZK:LoadIcons()
	for _, url in ipairs(SZK.IconSources) do
		local ok, data = pcall(function() return loadstring(game:HttpGet(url))() end)
		if ok and type(data) == "table" then
			for name, id in pairs(data) do SZK.Icons[name] = id end
		end
	end
	return SZK.Icons
end
SZK:LoadIcons()

function SZK:FetchJSON(url)
	if type(url) ~= "string" or url == "" then return nil end
	local ok, raw = pcall(function() return game:HttpGet(url) end)
	if not ok or not raw then return nil end
	local dOk, data = pcall(function() return HttpService:JSONDecode(raw) end)
	if not dOk then return nil end
	return data
end

function SZK:CreateWindowFromURL(url)
	local cfg = SZK:FetchJSON(url)
	if not cfg then
		warn("[SZK] No se pudo cargar config desde URL: " .. tostring(url))
		return nil
	end
	return SZK:CreateWindow(cfg)
end

local function GetUrlExtension(url, allowed, fallback)
	local clean = string.match(url, "^[^%?#]+") or url
	local ext = string.match(clean, "%.([%a%d]+)$")
	if ext then
		ext = string.lower(ext)
		for _, a in ipairs(allowed) do if a == ext then return ext end end
	end
	return fallback
end

local function NormalizeImageSource(input)
	if input == nil then return "" end
	if type(input) == "number" then return "rbxassetid://" .. tostring(input) end
	if type(input) ~= "string" or input == "" then return "" end
	if string.match(input, "^rbxassetid://") or string.match(input, "^rbxthumb://") or string.match(input, "^rbxasset://") then return input end
	if string.match(input, "^%d+$") then return "rbxassetid://" .. input end
	if string.match(input, "^https?://") then
		if writefile and isfile and getcustomasset and makefolder and isfolder then
			local ext = GetUrlExtension(input, {"png","jpg","jpeg","gif","webp","bmp"}, "png")
			local safeName = string.gsub(input, "[^%w]", "_")
			local cacheFolder = "SZK_Cache"
			local cachePath = cacheFolder .. "/" .. safeName .. "." .. ext
			local ok = pcall(function()
				if not isfolder(cacheFolder) then makefolder(cacheFolder) end
				if not isfile(cachePath) then writefile(cachePath, game:HttpGet(input)) end
			end)
			if ok then
				local aOk, aId = pcall(function() return getcustomasset(cachePath) end)
				if aOk and aId then return aId end
			end
		end
		return ""
	end
	return input
end

local function ResolveIcon(key)
	if not key then return "", false end
	if type(key) == "number" then return "rbxassetid://" .. tostring(key), true end
	if type(key) == "string" then
		if string.match(key, "^rbxassetid://") or string.match(key, "^%d+$") then return NormalizeImageSource(key), true end
		if string.match(key, "^https?://") then return NormalizeImageSource(key), true end
		if SZK.Icons[key] then return NormalizeImageSource(SZK.Icons[key]), true end
		return key, false
	end
	return "", false
end

local function Round(radius, parent)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius)
	c.Parent = parent
	return c
end

local function Outline(parent, color, thickness, transparency)
	local s = Instance.new("UIStroke")
	s.Color = color or Color3.fromRGB(60, 60, 65)
	s.Thickness = thickness or 1
	s.Transparency = transparency or 0.2
	s.Parent = parent
	return s
end

local function Shade(color, amount)
	if typeof(color) ~= "Color3" then return Color3.fromRGB(20, 20, 24) end
	amount = amount or 0.07
	local lum = 0.299 * color.R + 0.587 * color.G + 0.114 * color.B
	if lum > 0.5 then
		return Color3.new(math.max(0, color.R - amount), math.max(0, color.G - amount), math.max(0, color.B - amount))
	end
	return Color3.new(math.min(1, color.R + amount), math.min(1, color.G + amount), math.min(1, color.B + amount))
end

local function ContrastText(color)
	if typeof(color) ~= "Color3" then return Color3.new(0, 0, 0) end
	local lum = 0.299 * color.R + 0.587 * color.G + 0.114 * color.B
	return lum > 0.5 and Color3.fromRGB(0, 0, 0) or Color3.fromRGB(255, 255, 255)
end

local function Tween(obj, t, props)
	local anim = TweenService:Create(obj, TweenInfo.new(t, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), props)
	anim:Play()
	return anim
end

local function Ripple(button, color)
	button.ClipsDescendants = true
	pcall(function()
		button.MouseButton1Click:Connect(function()
			local mx, my = Mouse and Mouse.X or 0, Mouse and Mouse.Y or 0
			local circle = Instance.new("Frame")
			circle.BackgroundColor3 = color or Color3.new(1, 1, 1)
			circle.BackgroundTransparency = 0.7
			circle.BorderSizePixel = 0
			circle.AnchorPoint = Vector2.new(0.5, 0.5)
			circle.ZIndex = (button.ZIndex or 1) + 5
			circle.Size = UDim2.fromOffset(0, 0)
			circle.Position = UDim2.fromOffset(mx - button.AbsolutePosition.X, my - button.AbsolutePosition.Y)
			circle.Parent = button
			Round(200, circle)
			local target = math.max(button.AbsoluteSize.X, button.AbsoluteSize.Y) * 1.8
			Tween(circle, 0.45, { Size = UDim2.fromOffset(target, target), BackgroundTransparency = 1 })
			task.delay(0.45, function() if circle.Parent then circle:Destroy() end end)
		end)
	end)
end

local function Img(parent, source, size, color, transparency, z)
	local resolved, isCustom = ResolveIcon(source)
	if resolved == "" then return nil end
	local image = Instance.new("ImageLabel")
	image.Size = size or UDim2.fromOffset(16, 16)
	image.BackgroundTransparency = 1
	image.Image = resolved
	image.ScaleType = isCustom and Enum.ScaleType.Crop or Enum.ScaleType.Stretch
	image.ImageColor3 = isCustom and Color3.new(1,1,1) or (color or Color3.new(1,1,1))
	image.ImageTransparency = transparency or 0
	image.ZIndex = z or 8
	image.Parent = parent
	if isCustom then image:SetAttribute("SZKCustomIcon", true) end
	return image
end

local function TintIfAllowed(img, color)
	if img and not img:GetAttribute("SZKCustomIcon") then img.ImageColor3 = color end
end

local function NormalizeArgs(first, ...)
	if type(first) == "table" then return first end
	return nil, first, ...
end

local function BuildTheme(name, accent, outline, toggle, slider, text, placeholder, bg, elemBg, icon)
	return {
		Name = name,
		Accent = Color3.fromHex(accent),
		Outline = Color3.fromHex(outline or accent),
		Text = Color3.fromHex(text or "#EBEBEB"),
		Placeholder = Color3.fromHex(placeholder or "#919191"),
		Icon = Color3.fromHex(icon or outline or accent),
		Toggle = Color3.fromHex(toggle or accent),
		Slider = Color3.fromHex(slider or accent),
		ElementBackground = Color3.fromHex(elemBg or "#0A0A0D"),
		Background = Color3.fromHex(bg or "#050507"),
	}
end

SZK.Themes.SZKHUB    = BuildTheme("SZKHUB",    "#FFFFFF", "#8C8C8C", "#FFFFFF", "#FFFFFF", "#F0F0F0", "#969696", "#000000", "#141414", "#FFFFFF")
SZK.Themes.Rojo      = BuildTheme("Rojo",      "#FF1A1A", "#FF2A2A", "#FF1A1A", "#FF1A1A", "#F0F0F0", "#9A9A9A", "#000000", "#0A0A0A", "#FF1A1A")
SZK.Themes.Dorado    = BuildTheme("Dorado",    "#D4AF37", "#F0D580", "#D4AF37", "#F0D580", "#FFF8E7", "#C9B98A", "#0A0805", "#15110A", "#F0D580")
SZK.Themes.Esmeralda = BuildTheme("Esmeralda", "#50C878", "#7FFFA0", "#50C878", "#7FFFA0", "#E7FFEE", "#8AB99A", "#000A05", "#0A1A0F", "#7FFFA0")
SZK.Themes.Diamante  = BuildTheme("Diamante",  "#B9F2FF", "#E0FFFF", "#B9F2FF", "#E0FFFF", "#E8FCFF", "#8AB9C9", "#000A0F", "#0A1419", "#E0FFFF")
SZK.Themes.Zafiro    = BuildTheme("Zafiro",    "#0F52BA", "#4A90E2", "#0F52BA", "#4A90E2", "#E7F0FF", "#8AA0C9", "#000510", "#0A0F1A", "#4A90E2")
SZK.Themes.Amatista  = BuildTheme("Amatista",  "#9966CC", "#C9A0FF", "#9966CC", "#C9A0FF", "#F0E7FF", "#B09AC9", "#0A0010", "#150A1A", "#C9A0FF")
SZK.Themes.Rubi      = BuildTheme("Rubi",      "#E0115F", "#FF4D8B", "#E0115F", "#FF4D8B", "#FFE5EE", "#C98AA5", "#0A0005", "#1A0A10", "#FF4D8B")
SZK.Themes.Naranja   = BuildTheme("Naranja",   "#FF8C00", "#FFB347", "#FF8C00", "#FFB347", "#FFF3E0", "#C9A08A", "#0A0500", "#1A0F0A", "#FFB347")

-- [NUEVOS TEMAS RGB] Blanco, Negro, Rojo, Amarillo, Azul, Morado, Rosado
SZK.Themes.Blanco = BuildTheme("Blanco",
    "#333333", "#B0B0B0", "#3A7BD5", "#3A7BD5", "#1A1A1A", "#707070", "#FFFFFF", "#F0F0F0", "#333333"
)
SZK.Themes.Negro = BuildTheme("Negro",
    "#404040", "#202020", "#606060", "#606060", "#E8E8E8", "#808080", "#000000", "#0A0A0A", "#404040"
)
SZK.Themes.RojoPuro = BuildTheme("RojoPuro",
    "#FF0000", "#FF3333", "#FF0000", "#FF0000", "#FFE5E5", "#B38080", "#0A0000", "#1A0505", "#FF3333"
)
SZK.Themes.Amarillo = BuildTheme("Amarillo",
    "#FFFF00", "#FFFF66", "#FFFF00", "#FFFF00", "#FFFCE0", "#B3B370", "#0A0A00", "#1A1A05", "#FFFF66"
)
SZK.Themes.Azul = BuildTheme("Azul",
    "#0000FF", "#4D4DFF", "#0000FF", "#0000FF", "#E0E0FF", "#7070B3", "#00000A", "#05051A", "#4D4DFF"
)
SZK.Themes.Morado = BuildTheme("Morado",
    "#800080", "#B34DB3", "#800080", "#800080", "#F0E0F0", "#A070A0", "#0A000A", "#1A051A", "#B34DB3"
)
SZK.Themes.Rosado = BuildTheme("Rosado",
    "#FFC0CB", "#FFD6DD", "#FFC0CB", "#FFC0CB", "#FFE5F0", "#B3808A", "#0A0505", "#1A0F10", "#FFD6DD"
)

SZK.ThemeOrder = {
    "SZKHUB", "Rojo", "Dorado", "Esmeralda", "Diamante", "Zafiro", "Amatista", "Rubi", "Naranja",
    "Blanco", "Negro", "RojoPuro", "Amarillo", "Azul", "Morado", "Rosado"
}

local MainGui = Instance.new("ScreenGui")
MainGui.Name = "SZKLibrary"
MainGui.ResetOnSpawn = false
MainGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
MainGui.Parent = (gethui and gethui()) or CoreGui

local NotificationHolder = Instance.new("Frame")
NotificationHolder.Size = UDim2.new(0, 270, 1, -20)
NotificationHolder.Position = UDim2.new(1, -280, 0, 10)
NotificationHolder.BackgroundTransparency = 1
NotificationHolder.ZIndex = 100
NotificationHolder.Parent = MainGui

local NotifList = Instance.new("UIListLayout")
NotifList.VerticalAlignment = Enum.VerticalAlignment.Bottom
NotifList.Padding = UDim.new(0, 8)
NotifList.Parent = NotificationHolder

local ActiveNotifications = {}

function SZK:GetThemes() return SZK.Themes end
function SZK:SetTheme(name) for _, w in ipairs(SZK.Windows) do if w.SetTheme then w:SetTheme(name) end end end
function SZK:GetFlag(name) return SZK.Flags[name] end
function SZK:SetFlag(name, value) SZK.Flags[name] = value end

function SZK:SaveConfig(name)
	name = tostring(name or "default")
	if not (writefile and HttpService) then return false end
	pcall(function() if makefolder and isfolder and not isfolder(SZK.ConfigFolder) then makefolder(SZK.ConfigFolder) end end)
	local payload = {}
	for k, v in pairs(SZK.Flags) do
		if typeof(v) == "Color3" then payload[k] = {__color=true,R=v.R,G=v.G,B=v.B}
		elseif typeof(v) == "EnumItem" then payload[k] = {__enum=true,EnumType=tostring(v.EnumType),Name=v.Name}
		else payload[k] = v end
	end
	local ok, encoded = pcall(function() return HttpService:JSONEncode(payload) end)
	if not ok then return false end
	return (pcall(function() writefile(SZK.ConfigFolder .. "/" .. name .. ".json", encoded) end))
end

function SZK:LoadConfig(name)
	name = tostring(name or "default")
	if not (readfile and isfile and HttpService) then return false end
	local path = SZK.ConfigFolder .. "/" .. name .. ".json"
	if not isfile(path) then return false end
	local ok, raw = pcall(function() return readfile(path) end)
	if not ok or not raw then return false end
	local dOk, data = pcall(function() return HttpService:JSONDecode(raw) end)
	if not dOk or type(data) ~= "table" then return false end
	for k, v in pairs(data) do
		if type(v) == "table" and v.__color then SZK.Flags[k] = Color3.new(v.R, v.G, v.B)
		elseif type(v) == "table" and v.__enum then local r = Enum[v.EnumType]; SZK.Flags[k] = (r and r[v.Name]) or v
		else SZK.Flags[k] = v end
	end
	return true
end

function SZK:Notify(config)
	config = config or {}
	local title = config.Title or "Notification"
	local content = config.Content or config.Text or ""
	local duration = config.Duration or 3.5
	local ntype = config.Type or "Info"
	local buttons = config.Buttons
	local iconKey = config.Icon
	local colors = {Success=Color3.fromRGB(52,199,89), Error=Color3.fromRGB(235,64,52), Warning=Color3.fromRGB(255,176,32), Info=Color3.fromRGB(80,140,255)}
	local accent = colors[ntype] or colors.Info
	local T = SZK.CurrentTheme or SZK.Themes.SZKHUB

	local slot = Instance.new("Frame")
	slot.Size = UDim2.new(1, 0, 0, 0)
	slot.BackgroundTransparency = 1
	slot.Parent = NotificationHolder
	local frame = Instance.new("Frame")
	frame.Position = UDim2.new(1, 40, 0, 0)
	frame.Size = UDim2.new(1, 0, 1, 0)
	frame.BackgroundColor3 = T.ElementBackground
	frame.BackgroundTransparency = 0.08
	frame.ClipsDescendants = true
	frame.Parent = slot
	Round(6, frame)
	local stroke = Outline(frame, T.Outline, 1.2, 0.4)
	local bar = Instance.new("Frame")
	bar.Size = UDim2.new(0, 3, 1, -16)
	bar.Position = UDim2.new(0, 0, 0, 8)
	bar.BackgroundColor3 = accent
	bar.ZIndex = 2
	bar.Parent = frame
	Round(2, bar)

	local icon
	if ResolveIcon(iconKey) ~= "" then
		local badge = Instance.new("Frame")
		badge.Size = UDim2.fromOffset(32, 32)
		badge.Position = UDim2.new(0, 16, 0, 14)
		badge.BackgroundColor3 = accent
		badge.BackgroundTransparency = 0.82
		badge.ZIndex = 3
		badge.Parent = frame
		Round(16, badge)
		icon = Img(badge, iconKey, UDim2.fromOffset(16, 16), accent, 0, 4)
		if icon then icon.AnchorPoint = Vector2.new(0.5, 0.5); icon.Position = UDim2.new(0.5, 0, 0.5, 0) end
	end

	local tLbl = Instance.new("TextLabel")
	tLbl.Text = title
	tLbl.Font = FONT_TITLE
	tLbl.TextSize = 15
	tLbl.TextColor3 = T.Text
	tLbl.Position = UDim2.new(0, icon and 58 or 20, 0, 14)
	tLbl.Size = UDim2.new(1, icon and -70 or -34, 0, 18)
	tLbl.BackgroundTransparency = 1
	tLbl.TextXAlignment = Enum.TextXAlignment.Left
	tLbl.Parent = frame

	local cLbl = Instance.new("TextLabel")
	cLbl.Text = content
	cLbl.Font = FONT_BODY
	cLbl.TextSize = 11
	cLbl.TextColor3 = T.Placeholder
	cLbl.Position = UDim2.new(0, icon and 58 or 20, 0, 34)
	cLbl.Size = UDim2.new(1, icon and -70 or -34, 0, 30)
	cLbl.BackgroundTransparency = 1
	cLbl.TextXAlignment = Enum.TextXAlignment.Left
	cLbl.TextYAlignment = Enum.TextYAlignment.Top
	cLbl.TextWrapped = true
	cLbl.Parent = frame

	if buttons and #buttons > 0 then
		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, -34, 0, 26)
		row.Position = UDim2.new(0, icon and 58 or 20, 0, 66)
		row.BackgroundTransparency = 1
		row.Parent = frame
		local rl = Instance.new("UIListLayout")
		rl.FillDirection = Enum.FillDirection.Horizontal
		rl.Padding = UDim.new(0, 6)
		rl.Parent = row
		for _, b in ipairs(buttons) do
			local nb = Instance.new("TextButton")
			nb.Size = UDim2.fromOffset(0, 24)
			nb.AutomaticSize = Enum.AutomaticSize.X
			nb.BackgroundColor3 = b.Primary and accent or Shade(T.ElementBackground)
			nb.Text = "  " .. (b.Text or "Ok") .. "  "
			nb.Font = FONT_BOLD
			nb.TextSize = 11
			nb.TextColor3 = T.Text
			nb.Parent = row
			Round(4, nb)
			Ripple(nb, Color3.new(1,1,1))
			nb.MouseButton1Click:Connect(function()
				if b.Callback then pcall(b.Callback) end
				if b.CloseOnClick ~= false and slot.Parent then slot:Destroy() end
			end)
		end
	end

	table.insert(ActiveNotifications, {Frame=frame, Slot=slot, Stroke=stroke, Icon=icon, Title=tLbl, Content=cLbl, Bar=bar})
	Tween(slot, 0.3, { Size = UDim2.new(1, 0, 0, (buttons and #buttons > 0) and 94 or 68) })
	Tween(frame, 0.35, { Position = UDim2.new(0, 0, 0, 0) })
	if not (buttons and #buttons > 0) then
		task.delay(duration, function()
			if not slot.Parent then return end
			Tween(frame, 0.25, { Position = UDim2.new(1, 40, 0, 0), BackgroundTransparency = 1 })
			local out = Tween(slot, 0.25, { Size = UDim2.new(1, 0, 0, 0) })
			out.Completed:Connect(function()
				for i, it in ipairs(ActiveNotifications) do if it.Slot == slot then table.remove(ActiveNotifications, i) break end end
				slot:Destroy()
			end)
		end)
	end
end

function SZK:CreateWindow(config)
	config = config or {}
	local themeName = config.Theme or "SZKHUB"
	local title = config.Title or "SZKHUB"
	local description = config.Description or "SZK"

	local size = config.Size or Vector2.new(600, 410)
	if type(size) == "table" and size.X and size.Y then
		size = Vector2.new(tonumber(size.X) or 600, tonumber(size.Y) or 410)
	elseif typeof(size) == "UDim2" then
		size = Vector2.new(size.X.Offset, size.Y.Offset)
	elseif typeof(size) ~= "Vector2" then
		size = Vector2.new(600, 410)
	end

	local toggleKey = config.ToggleKey or Enum.KeyCode.RightShift
	if type(toggleKey) == "string" then
		toggleKey = Enum.KeyCode[toggleKey] or Enum.KeyCode.RightShift
	end

	local showThemeSelector = config.ThemeSelector == true
	local bgImage = config.BackgroundImage
	local bgTransparency = math.clamp(tonumber(config.BackgroundImageTransparency or config.BackgroundTransparency) or 0, 0, 1)
	local panelTransparency = math.clamp(tonumber(config.Transparency) or 0.85, 0.02, 0.95)
	local openButtonText = config.OpenButtonText or "OPEN SZK"

	local Theme = SZK.Themes[themeName] or SZK.Themes.SZKHUB
	SZK.CurrentTheme = Theme
	local Registered = {}
	local DependentRows = {}

	local function CheckDependents()
		for _, dep in ipairs(DependentRows) do
			local ok = true
			if dep.Check then
				local co, cr = pcall(dep.Check)
				ok = co and cr
			end
			dep.Row.Visible = ok and true or false
		end
	end

	local function ApplyDependsOn(row, cfg)
		if not cfg or not cfg.DependsOn then return end
		local dep = cfg.DependsOn
		local toggleObj = dep.Toggle or dep[1]
		local expected = dep.Value
		if expected == nil then expected = dep[2] end
		if expected == nil then expected = true end
		local check
		if type(dep) == "function" then check = dep
		elseif toggleObj and toggleObj.Get then check = function() return toggleObj:Get() == expected end end
		if check then
			table.insert(DependentRows, { Row = row, Check = check })
			row.Visible = check() and true or false
		end
	end

	local OpenPopups = {}
	local function RegisterPopup(f, t) table.insert(OpenPopups, {Frame=f, Trigger=t}) end
	local function CloseAllPopups(except)
		for _, p in ipairs(OpenPopups) do
			if p.Frame.Visible and p.Trigger ~= except then p.Frame.Visible = false end
		end
	end

	local resolvedBgImage = NormalizeImageSource(bgImage or "")
	local hasBackground = resolvedBgImage ~= ""
	local mainBgTrans = 0.35
	local elementTrans = 0.3
	local overlayTrans = 0.9

	local Window = { Tabs = {}, Connections = {} }
	local function Track(conn) table.insert(Window.Connections, conn); return conn end

	local WindowGui = Instance.new("ScreenGui")
	WindowGui.Name = "SZKWindow"
	WindowGui.ResetOnSpawn = false
	WindowGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	WindowGui.DisplayOrder = MainGui.DisplayOrder
	WindowGui.Parent = (gethui and gethui()) or CoreGui

	local MainFrame = Instance.new("Frame")
	MainFrame.Size = UDim2.fromOffset(0, 0)
	MainFrame.Position = UDim2.new(0.5, 0, 0.5, 18)
	MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	MainFrame.BackgroundColor3 = Theme.Background
	MainFrame.BackgroundTransparency = mainBgTrans
	MainFrame.ClipsDescendants = true
	MainFrame.Visible = false
	MainFrame.Parent = WindowGui
	Round(6, MainFrame)
	local MainStroke = Outline(MainFrame, Theme.Outline, 1, 0.35)

	task.spawn(function()
		while MainFrame and MainFrame.Parent do
			TweenService:Create(MainStroke, TweenInfo.new(1.4), {Transparency = 0.7}):Play()
			task.wait(1.4)
			if not MainFrame.Parent then break end
			TweenService:Create(MainStroke, TweenInfo.new(1.4), {Transparency = 0.35}):Play()
			task.wait(1.4)
		end
	end)

	local WindowScale = Instance.new("UIScale")
	WindowScale.Parent = MainFrame

	local function GetViewport()
		local cam = workspace.CurrentCamera
		return cam and cam.ViewportSize or Vector2.new(1280, 720)
	end
	local function RecalculateScale()
		local vp = GetViewport()
		local sX = math.max(vp.X - 24, 1) / size.X
		local sY = math.max(vp.Y - 90, 1) / size.Y
		WindowScale.Scale = math.clamp(math.min(sX, sY, 1), 0.5, 1)
	end
	RecalculateScale()
	Track(workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(RecalculateScale))

	local BgImageLabel = Instance.new("ImageLabel")
	BgImageLabel.Size = UDim2.fromScale(1, 1)
	BgImageLabel.BackgroundTransparency = 1
	BgImageLabel.Image = resolvedBgImage
	BgImageLabel.ImageTransparency = bgTransparency
	BgImageLabel.ScaleType = Enum.ScaleType.Crop
	BgImageLabel.ZIndex = 0
	BgImageLabel.Visible = hasBackground
	BgImageLabel.Parent = MainFrame

	local Overlay = Instance.new("Frame")
	Overlay.Size = UDim2.fromScale(1, 1)
	Overlay.BackgroundColor3 = Theme.Background
	Overlay.BackgroundTransparency = overlayTrans
	Overlay.BorderSizePixel = 0
	Overlay.ZIndex = 1
	Overlay.Parent = MainFrame

	local HeaderBar = Instance.new("Frame")
	HeaderBar.Size = UDim2.new(1, 0, 0, 58)
	HeaderBar.BackgroundColor3 = Theme.Background
	HeaderBar.BackgroundTransparency = 0.35
	HeaderBar.ZIndex = 3
	HeaderBar.Parent = MainFrame

	local TitleLabel = Instance.new("TextLabel")
	TitleLabel.Text = title
	TitleLabel.Font = FONT_TITLE
	TitleLabel.TextSize = 23
	TitleLabel.TextColor3 = Theme.Text
	TitleLabel.Position = UDim2.new(0, 20, 0, 6)
	TitleLabel.Size = UDim2.new(1, -100, 0, 28)
	TitleLabel.BackgroundTransparency = 1
	TitleLabel.TextTruncate = Enum.TextTruncate.AtEnd
	TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
	TitleLabel.ZIndex = 4
	TitleLabel.Parent = HeaderBar

	local DescLabel = Instance.new("TextLabel")
	DescLabel.Text = description
	DescLabel.Font = FONT_BODY
	DescLabel.TextSize = 9
	DescLabel.TextColor3 = Theme.Placeholder
	DescLabel.Position = UDim2.new(0, 20, 0, 34)
	DescLabel.Size = UDim2.new(1, -100, 0, 14)
	DescLabel.BackgroundTransparency = 1
	DescLabel.TextTruncate = Enum.TextTruncate.AtEnd
	DescLabel.TextXAlignment = Enum.TextXAlignment.Left
	DescLabel.ZIndex = 4
	DescLabel.Parent = HeaderBar

	local Controls = Instance.new("Frame")
	local ctrlW = showThemeSelector and 140 or 72
	Controls.Size = UDim2.fromOffset(ctrlW, 28)
	Controls.Position = UDim2.new(1, -ctrlW - 14, 0, 14)
	Controls.BackgroundTransparency = 1
	Controls.ZIndex = 6
	Controls.Parent = HeaderBar
	local ControlsLayout = Instance.new("UIListLayout")
	ControlsLayout.FillDirection = Enum.FillDirection.Horizontal
	ControlsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	ControlsLayout.Padding = UDim.new(0, 6)
	ControlsLayout.Parent = Controls

	local ThemeBtn
	if showThemeSelector then
		ThemeBtn = Instance.new("TextButton")
		ThemeBtn.Size = UDim2.fromOffset(84, 28)
		ThemeBtn.BackgroundColor3 = Theme.ElementBackground
		ThemeBtn.BackgroundTransparency = 0.2
		ThemeBtn.AutoButtonColor = false
		ThemeBtn.Text = themeName
		ThemeBtn.Font = FONT_BODY
		ThemeBtn.TextSize = 11
		ThemeBtn.TextColor3 = Theme.Text
		ThemeBtn.ZIndex = 7
		ThemeBtn.Parent = Controls
		Round(6, ThemeBtn)
		Outline(ThemeBtn, Theme.Outline, 1, 0.4)
	end

	local MinBtn = Instance.new("TextButton")
	MinBtn.Size = UDim2.fromOffset(28, 28)
	MinBtn.BackgroundColor3 = Theme.ElementBackground
	MinBtn.BackgroundTransparency = 0.2
	MinBtn.Text = "—"
	MinBtn.Font = FONT_BOLD
	MinBtn.TextSize = 16
	MinBtn.TextColor3 = Theme.Text
	MinBtn.AutoButtonColor = false
	MinBtn.ZIndex = 7
	MinBtn.Parent = Controls
	Round(6, MinBtn)

	local CloseBtn = Instance.new("TextButton")
	CloseBtn.Size = UDim2.fromOffset(28, 28)
	CloseBtn.BackgroundColor3 = Theme.ElementBackground
	CloseBtn.BackgroundTransparency = 0.2
	CloseBtn.Text = ""
	CloseBtn.AutoButtonColor = false
	CloseBtn.ZIndex = 7
	CloseBtn.Parent = Controls
	Round(6, CloseBtn)
	local CloseStroke = Outline(CloseBtn, Theme.Outline, 1, 0.1)
	local closeBars = {}
	for _, rot in ipairs({45, -45}) do
		local bar = Instance.new("Frame")
		bar.Size = UDim2.new(0, 12, 0, 2)
		bar.AnchorPoint = Vector2.new(0.5, 0.5)
		bar.Position = UDim2.new(0.5, 0, 0.5, 0)
		bar.Rotation = rot
		bar.BackgroundColor3 = Theme.Placeholder
		bar.BorderSizePixel = 0
		bar.ZIndex = 8
		bar.Parent = CloseBtn
		Round(1, bar)
		table.insert(closeBars, bar)
	end
	local function closeHover(on)
		local info = TweenInfo.new(0.15)
		TweenService:Create(CloseBtn, info, {
			BackgroundColor3 = on and Color3.fromRGB(220,60,60) or Theme.ElementBackground,
			BackgroundTransparency = on and 0.1 or 0.2,
		}):Play()
		TweenService:Create(CloseStroke, info, {Color = on and Color3.fromRGB(220,60,60) or Theme.Outline}):Play()
		for _, b in ipairs(closeBars) do
			TweenService:Create(b, info, {BackgroundColor3 = on and Theme.Text or Theme.Placeholder}):Play()
		end
	end
	CloseBtn.MouseEnter:Connect(function() closeHover(true) end)
	CloseBtn.MouseLeave:Connect(function() closeHover(false) end)

	local function MakeDividerLine(parent, size_, pos)
		local l = Instance.new("Frame")
		l.Size = size_
		l.Position = pos
		l.BackgroundColor3 = Theme.Accent
		l.BorderSizePixel = 0
		l.ZIndex = 3
		l.Parent = parent
		local g = Instance.new("UIGradient")
		g.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.5, 0),
			NumberSequenceKeypoint.new(1, 1),
		})
		g.Parent = l
		return l
	end

	local HeaderLine = MakeDividerLine(MainFrame, UDim2.new(1, -40, 0, 1), UDim2.new(0, 20, 0, 58))

	local HeaderDiamond = Instance.new("Frame")
	HeaderDiamond.Size = UDim2.fromOffset(7, 7)
	HeaderDiamond.Position = UDim2.new(0.5, -3, 0, 55)
	HeaderDiamond.BackgroundColor3 = Theme.Accent
	HeaderDiamond.BorderSizePixel = 0
	HeaderDiamond.Rotation = 45
	HeaderDiamond.ZIndex = 4
	HeaderDiamond.Parent = MainFrame

	local SIDE_W, TOP_H, FOOT_H, SIDE_PAD_TOP = 168, 62, 12, 8

	local SideBg = Instance.new("Frame")
	SideBg.Size = UDim2.new(0, SIDE_W, 1, -(TOP_H + FOOT_H))
	SideBg.Position = UDim2.new(0, 0, 0, TOP_H)
	SideBg.BackgroundColor3 = Theme.Background
	SideBg.BackgroundTransparency = 0.4
	SideBg.BorderSizePixel = 0
	SideBg.ZIndex = 1
	SideBg.Parent = MainFrame

	local Sidebar = Instance.new("ScrollingFrame")
	Sidebar.Position = UDim2.new(0, 0, 0, TOP_H + SIDE_PAD_TOP)
	Sidebar.Size = UDim2.new(0, SIDE_W, 1, -(TOP_H + SIDE_PAD_TOP + FOOT_H))
	Sidebar.BackgroundTransparency = 1
	Sidebar.BorderSizePixel = 0
	Sidebar.ScrollBarThickness = 0
	Sidebar.CanvasSize = UDim2.new()
	Sidebar.AutomaticCanvasSize = Enum.AutomaticSize.Y
	Sidebar.ZIndex = 2
	Sidebar.Parent = MainFrame
	local SideList = Instance.new("UIListLayout")
	SideList.Padding = UDim.new(0, 4)
	SideList.SortOrder = Enum.SortOrder.LayoutOrder
	SideList.HorizontalAlignment = Enum.HorizontalAlignment.Center
	SideList.Parent = Sidebar
	local SidePad = Instance.new("UIPadding")
	SidePad.PaddingTop = UDim.new(0, 2)
	SidePad.PaddingBottom = UDim.new(0, 8)
	SidePad.Parent = Sidebar

	local VLine = Instance.new("Frame")
	VLine.Size = UDim2.new(0, 1, 1, -(TOP_H + FOOT_H + 16))
	VLine.Position = UDim2.new(0, SIDE_W, 0, TOP_H + 8)
	VLine.BackgroundColor3 = Theme.Outline
	VLine.BorderSizePixel = 0
	VLine.ZIndex = 2
	VLine.Parent = MainFrame
	local VLineGrad = Instance.new("UIGradient")
	VLineGrad.Rotation = 90
	VLineGrad.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.5, 0.2),
		NumberSequenceKeypoint.new(1, 1),
	})
	VLineGrad.Parent = VLine

	local PageHost = Instance.new("Frame")
	PageHost.Position = UDim2.new(0, SIDE_W + 1, 0, TOP_H)
	PageHost.Size = UDim2.new(1, -(SIDE_W + 1), 1, -(TOP_H + FOOT_H))
	PageHost.BackgroundColor3 = Theme.Background
	PageHost.BackgroundTransparency = 0.85
	PageHost.BorderSizePixel = 0
	PageHost.ClipsDescendants = true
	PageHost.ZIndex = 1
	PageHost.Parent = MainFrame

	local ThemePopup = Instance.new("Frame")
	ThemePopup.Size = UDim2.fromOffset(180, 280)
	ThemePopup.BackgroundColor3 = Theme.ElementBackground
	ThemePopup.BackgroundTransparency = 0.05
	ThemePopup.Visible = false
	ThemePopup.ZIndex = 50
	ThemePopup.Parent = WindowGui
	Round(6, ThemePopup)
	Outline(ThemePopup, Theme.Outline, 1, 0.15)

	local ThemeScroll = Instance.new("ScrollingFrame")
	ThemeScroll.Size = UDim2.new(1, -8, 1, -8)
	ThemeScroll.Position = UDim2.new(0, 4, 0, 4)
	ThemeScroll.BackgroundTransparency = 1
	ThemeScroll.ScrollBarThickness = 3
	ThemeScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	ThemeScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	ThemeScroll.ZIndex = 51
	ThemeScroll.Parent = ThemePopup
	local ThemeList = Instance.new("UIListLayout")
	ThemeList.Padding = UDim.new(0, 4)
	ThemeList.Parent = ThemeScroll

	local FloatBtn = Instance.new("TextButton")
	FloatBtn.Name = "MainButton"
	FloatBtn.AnchorPoint = Vector2.new(0.5, 0)
	FloatBtn.Size = UDim2.fromOffset(140, 34)
	FloatBtn.Position = UDim2.new(0.5, 0, 0, 12)
	FloatBtn.BackgroundColor3 = Theme.Accent
	FloatBtn.Text = openButtonText
	FloatBtn.TextColor3 = ContrastText(Theme.Accent)
	FloatBtn.Font = Enum.Font.GothamBlack
	FloatBtn.TextSize = 12
	FloatBtn.AutoButtonColor = false
	FloatBtn.BorderSizePixel = 0
	FloatBtn.Active = true
	FloatBtn.Visible = false
	FloatBtn.ZIndex = 10
	FloatBtn.Parent = WindowGui
	Round(10, FloatBtn)
	local FloatStroke = Outline(FloatBtn, Theme.Outline, 1, 0.6)

	FloatBtn.MouseEnter:Connect(function()
		Tween(FloatBtn, 0.12, { BackgroundColor3 = Shade(Theme.Accent, 0.12) })
		Tween(FloatStroke, 0.12, { Transparency = 0.3 })
	end)
	FloatBtn.MouseLeave:Connect(function()
		Tween(FloatBtn, 0.12, { BackgroundColor3 = Theme.Accent })
		Tween(FloatStroke, 0.12, { Transparency = 0.6 })
	end)

	local winOpen = true
	local isAnimating = false

	local function OpenWindow()
		if isAnimating then return end
		isAnimating = true
		FloatBtn.Visible = false
		MainFrame.Visible = true
		local targetScale = WindowScale.Scale
		WindowScale.Scale = targetScale * 0.94
		MainFrame.Size = UDim2.fromOffset(size.X, size.Y)
		MainFrame.BackgroundTransparency = mainBgTrans
		Tween(WindowScale, 0.22, { Scale = targetScale })
		local t = Tween(MainFrame, 0.1, { BackgroundTransparency = mainBgTrans })
		t.Completed:Connect(function() isAnimating = false end)
		winOpen = true
	end

	local function CloseWindow()
		if isAnimating then return end
		isAnimating = true
		CloseAllPopups()
		local t = Tween(MainFrame, 0.18, { BackgroundTransparency = 1 })
		t.Completed:Connect(function()
			MainFrame.Visible = false
			FloatBtn.Visible = true
			isAnimating = false
		end)
		winOpen = false
	end

	local function ToggleWindow() if winOpen then CloseWindow() else OpenWindow() end end

	MinBtn.MouseButton1Click:Connect(CloseWindow)
	CloseBtn.MouseButton1Click:Connect(CloseWindow)
	FloatBtn.MouseButton1Click:Connect(OpenWindow)

	Track(UserInputService.InputBegan:Connect(function(input, gpe)
		if not gpe and input.KeyCode == toggleKey then ToggleWindow() end
	end))

	Track(UserInputService.InputBegan:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
		task.defer(function()
			local pos = input.Position
			for _, p in ipairs(OpenPopups) do
				if p.Frame.Visible then
					local abs, sz = p.Frame.AbsolutePosition, p.Frame.AbsoluteSize
					local inF = pos.X >= abs.X and pos.X <= abs.X + sz.X and pos.Y >= abs.Y and pos.Y <= abs.Y + sz.Y
					local inT = false
					if p.Trigger then
						local ta, ts = p.Trigger.AbsolutePosition, p.Trigger.AbsoluteSize
						inT = pos.X >= ta.X and pos.X <= ta.X + ts.X and pos.Y >= ta.Y and pos.Y <= ta.Y + ts.Y
					end
					if not inF and not inT then p.Frame.Visible = false end
				end
			end
		end)
	end))

	local function EnableDrag(handle, target)
		local dragging, startPos, startInput
		Track(handle.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging = true
				startPos = target.Position
				startInput = input.Position
			end
		end))
		Track(UserInputService.InputChanged:Connect(function(input)
			if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
				local d = input.Position - startInput
				target.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
			end
		end))
		Track(UserInputService.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
		end))
	end
	EnableDrag(HeaderBar, MainFrame)
	EnableDrag(FloatBtn, FloatBtn)

	local GRIP_ANGLE = -20
	local MIN_W, MIN_H, MAX_W, MAX_H = 480, 320, 1000, 700

	local ResizeGrip = Instance.new("TextButton")
	ResizeGrip.Size = UDim2.fromOffset(30, 30)
	ResizeGrip.AnchorPoint = Vector2.new(1, 1)
	ResizeGrip.Position = UDim2.new(1, -2, 1, -2)
	ResizeGrip.BackgroundTransparency = 1
	ResizeGrip.Text = ""
	ResizeGrip.AutoButtonColor = false
	ResizeGrip.ZIndex = 20
	ResizeGrip.Parent = MainFrame

	local gripLines = {}
	do
		local rad = math.rad(GRIP_ANGLE)
		local nx, ny = -math.sin(rad), math.cos(rad)
		local lengths = {16, 12, 8}
		for i = 1, 3 do
			local off = (i - 2) * 5
			local line = Instance.new("Frame")
			line.Size = UDim2.new(0, lengths[i], 0, 2)
			line.AnchorPoint = Vector2.new(0.5, 0.5)
			line.Position = UDim2.new(0.5, 4 + nx * off, 0.5, 4 + ny * off)
			line.Rotation = GRIP_ANGLE
			line.BackgroundColor3 = Theme.Placeholder
			line.BorderSizePixel = 0
			line.ZIndex = 21
			line.Parent = ResizeGrip
			Round(1, line)
			table.insert(gripLines, line)
		end
	end

	local function gripColor(c)
		for _, l in ipairs(gripLines) do
			TweenService:Create(l, TweenInfo.new(0.12), {BackgroundColor3 = c}):Play()
		end
	end

	local resizing, rStartInput, rStartW, rStartH, rStartPos
	ResizeGrip.MouseEnter:Connect(function() if not resizing then gripColor(Theme.Accent) end end)
	ResizeGrip.MouseLeave:Connect(function() if not resizing then gripColor(Theme.Placeholder) end end)
	ResizeGrip.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			resizing = true
			rStartInput = Vector2.new(input.Position.X, input.Position.Y)
			rStartW, rStartH = MainFrame.Size.X.Offset, MainFrame.Size.Y.Offset
			rStartPos = MainFrame.Position
			gripColor(Theme.Accent)
		end
	end)
	Track(UserInputService.InputChanged:Connect(function(input)
		if resizing and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local s = WindowScale.Scale
			local d = (Vector2.new(input.Position.X, input.Position.Y) - rStartInput) / s
			local vp = GetViewport()
			local w = math.clamp(rStartW + d.X, MIN_W, math.max(MIN_W, math.min(MAX_W, (vp.X - 12) / s)))
			local h = math.clamp(rStartH + d.Y, MIN_H, math.max(MIN_H, math.min(MAX_H, (vp.Y - 12) / s)))
			size = Vector2.new(w, h)
			MainFrame.Size = UDim2.fromOffset(size.X, size.Y)
			MainFrame.Position = UDim2.new(
				rStartPos.X.Scale, rStartPos.X.Offset + s * (w - rStartW) / 2,
				rStartPos.Y.Scale, rStartPos.Y.Offset + s * (h - rStartH) / 2
			)
		end
	end))
	Track(UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			resizing = false
			gripColor(Theme.Placeholder)
		end
	end))

	-- UpdateTheme: aplica colores con tween fluido cuando animate=true
	local function UpdateTheme(name, animate)
		local T = SZK.Themes[name] or SZK.Themes.SZKHUB
		SZK.CurrentTheme = T
		Theme = T

		local tweenInfo = TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		local function tp(obj, prop, color)
			if animate then
				TweenService:Create(obj, tweenInfo, {[prop] = color}):Play()
			else
				obj[prop] = color
			end
		end

		tp(MainFrame, "BackgroundColor3", T.Background)
		MainFrame.BackgroundTransparency = mainBgTrans
		tp(Overlay, "BackgroundColor3", T.Background)
		tp(HeaderBar, "BackgroundColor3", T.Background)
		tp(TitleLabel, "TextColor3", T.Text)
		tp(DescLabel, "TextColor3", T.Placeholder)
		tp(MainStroke, "Color", T.Outline)
		tp(CloseStroke, "Color", T.Outline)
		tp(MinBtn, "TextColor3", T.Text)
		tp(MinBtn, "BackgroundColor3", T.ElementBackground)
		tp(CloseBtn, "BackgroundColor3", T.ElementBackground)
		for _, b in ipairs(closeBars) do tp(b, "BackgroundColor3", T.Placeholder) end
		tp(HeaderLine, "BackgroundColor3", T.Accent)
		tp(HeaderDiamond, "BackgroundColor3", T.Accent)
		tp(VLine, "BackgroundColor3", T.Outline)
		tp(SideBg, "BackgroundColor3", T.Background)
		tp(PageHost, "BackgroundColor3", T.Background)
		tp(ThemePopup, "BackgroundColor3", T.ElementBackground)
		if ThemeBtn then
			ThemeBtn.Text = T.Name
			tp(ThemeBtn, "TextColor3", T.Text)
			tp(ThemeBtn, "BackgroundColor3", T.ElementBackground)
		end

		-- [NUEVO] El botón flotante OPEN SZK sigue al tema
		tp(FloatBtn, "BackgroundColor3", T.Accent)
		tp(FloatBtn, "TextColor3", ContrastText(T.Accent))
		tp(FloatStroke, "Color", T.Outline)

		for _, item in ipairs(Registered) do
			if item.Type == "TabBtn" then
				local active = item.Active
				item.Label.TextColor3 = active and T.Text or T.Placeholder
				if item.Deco then
					item.Deco:FindFirstChildOfClass("Frame").BackgroundColor3 = T.Accent
					local topLine = item.Deco:FindFirstChild("TopLine")
					if topLine then topLine.BackgroundColor3 = T.Accent end
					local botLine = item.Deco:FindFirstChild("BotLine")
					if botLine then botLine.BackgroundColor3 = T.Accent end
					local dia = item.Deco:FindFirstChild("Diamond")
					if dia then dia.BackgroundColor3 = T.Accent end
				end
				if item.Icon then TintIfAllowed(item.Icon, active and T.Accent or T.Placeholder) end
			elseif item.Type == "Element" then
				item.Instance.BackgroundColor3 = item.CustomButtonColor or T.ElementBackground
				item.Instance.BackgroundTransparency = elementTrans
				if item.Stroke then
					item.Stroke.Color = T.Outline
					item.Stroke.Transparency = 0.3
				end
				if item.Label then item.Label.TextColor3 = T.Text end
				if item.Icon then TintIfAllowed(item.Icon, T.Icon) end
				if item.AccentBar then item.AccentBar.BackgroundColor3 = T.Accent end
				if item.SubColor then
					item.SubColor.BackgroundColor3 = item.SubRole == "Slider" and T.Slider or (item.State and item.State() and T.Toggle or Color3.fromRGB(60, 60, 65))
				end
				if item.SubBg then item.SubBg.BackgroundColor3 = Shade(T.ElementBackground) end
				if item.SubText then
					item.SubText.TextColor3 = T.Text
					if item.SubText:IsA("TextBox") then item.SubText.PlaceholderColor3 = T.Placeholder end
				end
				if item.Extras then
					for _, extra in ipairs(item.Extras) do
						if extra.Kind == "Text" then extra.Object.TextColor3 = T.Text
						elseif extra.Kind == "Placeholder" and extra.Object:IsA("TextBox") then extra.Object.PlaceholderColor3 = T.Placeholder
						elseif extra.Kind == "Icon" then TintIfAllowed(extra.Object, T.Icon)
						elseif extra.Kind == "Elevated" then extra.Object.BackgroundColor3 = Shade(T.ElementBackground)
						elseif extra.Kind == "Outline" and extra.Object:IsA("UIStroke") then extra.Object.Color = T.Outline
						elseif extra.Kind == "Accent" then extra.Object.BackgroundColor3 = T.Accent end
					end
				end
			elseif item.Type == "Section" then
				item.Label.TextColor3 = T.Placeholder
				if item.Icon then TintIfAllowed(item.Icon, T.Icon) end
			end
		end

		for _, n in ipairs(ActiveNotifications) do
			if n.Frame and n.Frame.Parent then
				n.Frame.BackgroundColor3 = T.ElementBackground
				if n.Stroke then n.Stroke.Color = T.Outline end
				if n.Icon then TintIfAllowed(n.Icon, T.Icon) end
				if n.Title then n.Title.TextColor3 = T.Text end
				if n.Content then n.Content.TextColor3 = T.Placeholder end
			end
		end
	end

	if showThemeSelector then
		for _, tName in ipairs(SZK.ThemeOrder) do
			if SZK.Themes[tName] then
				local btn = Instance.new("TextButton")
				btn.Size = UDim2.new(1, -8, 0, 30)
				btn.BackgroundColor3 = SZK.Themes[tName].Accent
				btn.BackgroundTransparency = 0.82
				btn.AutoButtonColor = false
				btn.Text = tName
				btn.Font = FONT_BODY
				btn.TextSize = 12
				btn.TextColor3 = SZK.Themes[tName].Text
				btn.TextXAlignment = Enum.TextXAlignment.Left
				btn.ZIndex = 52
				btn.Parent = ThemeScroll
				Round(4, btn)
				local pad = Instance.new("UIPadding")
				pad.PaddingLeft = UDim.new(0, 10)
				pad.Parent = btn
				btn.MouseEnter:Connect(function() Tween(btn, 0.12, { BackgroundTransparency = 0.55 }) end)
				btn.MouseLeave:Connect(function() Tween(btn, 0.12, { BackgroundTransparency = 0.82 }) end)
				btn.MouseButton1Click:Connect(function()
					UpdateTheme(tName, true)
					ThemePopup.Visible = false
				end)
			end
		end
		RegisterPopup(ThemePopup, ThemeBtn)
		ThemeBtn.MouseButton1Click:Connect(function()
			if ThemePopup.Visible then ThemePopup.Visible = false; return end
			CloseAllPopups(ThemeBtn)
			local abs, asz = ThemeBtn.AbsolutePosition, ThemeBtn.AbsoluteSize
			local vp = GetViewport()
			local x = math.clamp(abs.X + asz.X - 180, 6, math.max(6, vp.X - 186))
			local belowY = abs.Y + asz.Y + 5
			local y = belowY + 280 <= vp.Y - 6 and belowY or math.max(6, abs.Y - 285)
			ThemePopup.Position = UDim2.fromOffset(x, y)
			ThemePopup.Visible = true
		end)
	end

	function Window:SetSize(v)
		if typeof(v) == "Vector2" then
			size = Vector2.new(math.clamp(v.X, MIN_W, MAX_W), math.clamp(v.Y, MIN_H, MAX_H))
			MainFrame.Size = UDim2.fromOffset(size.X, size.Y)
			RecalculateScale()
		end
	end

	function Window:SetBackgroundImage(src, trans)
		local resolved = NormalizeImageSource(src or "")
		BgImageLabel.Image = resolved
		BgImageLabel.Visible = resolved ~= ""
		if trans then BgImageLabel.ImageTransparency = tonumber(trans) or 0 end
		hasBackground = resolved ~= ""
	end

	function Window:SetOpenButtonText(text)
		FloatBtn.Text = tostring(text or "OPEN SZK")
	end

	function Window:SetTitle(text)
		TitleLabel.Text = tostring(text or "")
	end

	function Window:SetDescription(text)
		DescLabel.Text = tostring(text or "")
	end

	function Window:SetButtonVisible(v)
		FloatBtn.Visible = v and true or false
	end

	function Window:SetTheme(name) UpdateTheme(name, true) end
	function Window:Minimize() CloseWindow() end
	function Window:Restore() OpenWindow() end
	function Window:Destroy()
		for _, c in ipairs(self.Connections) do pcall(function() c:Disconnect() end) end
		for i, w in ipairs(SZK.Windows) do if w == self then table.remove(SZK.Windows, i) break end end
		WindowGui:Destroy()
	end

	function Window:Dialog(cfg)
		cfg = cfg or {}
		local Overlay2 = Instance.new("Frame")
		Overlay2.Size = UDim2.fromScale(1, 1)
		Overlay2.BackgroundColor3 = Color3.new(0, 0, 0)
		Overlay2.BackgroundTransparency = 0.45
		Overlay2.ZIndex = 200
		Overlay2.Parent = MainFrame

		local Popup = Instance.new("Frame")
		Popup.Size = UDim2.fromOffset(300, 0)
		Popup.AutomaticSize = Enum.AutomaticSize.Y
		Popup.Position = UDim2.fromScale(0.5, 0.5)
		Popup.AnchorPoint = Vector2.new(0.5, 0.5)
		Popup.BackgroundColor3 = Theme.ElementBackground
		Popup.BackgroundTransparency = 0.03
		Popup.ZIndex = 201
		Popup.Parent = Overlay2
		Round(6, Popup)
		Outline(Popup, Theme.Outline, 1, 0.15)

		local pad = Instance.new("UIPadding")
		pad.PaddingTop = UDim.new(0, 16)
		pad.PaddingBottom = UDim.new(0, 16)
		pad.PaddingLeft = UDim.new(0, 16)
		pad.PaddingRight = UDim.new(0, 16)
		pad.Parent = Popup

		local layout = Instance.new("UIListLayout")
		layout.Padding = UDim.new(0, 10)
		layout.Parent = Popup

		local tl = Instance.new("TextLabel")
		tl.Size = UDim2.new(1, 0, 0, 22)
		tl.BackgroundTransparency = 1
		tl.Text = cfg.Title or "Dialog"
		tl.Font = FONT_TITLE
		tl.TextSize = 18
		tl.TextColor3 = Theme.Text
		tl.TextXAlignment = Enum.TextXAlignment.Left
		tl.ZIndex = 202
		tl.Parent = Popup

		local cl = Instance.new("TextLabel")
		cl.Size = UDim2.new(1, 0, 0, 0)
		cl.AutomaticSize = Enum.AutomaticSize.Y
		cl.BackgroundTransparency = 1
		cl.Text = cfg.Content or cfg.Text or ""
		cl.Font = FONT_BODY
		cl.TextSize = 13
		cl.TextColor3 = Theme.Placeholder
		cl.TextWrapped = true
		cl.TextXAlignment = Enum.TextXAlignment.Left
		cl.ZIndex = 202
		cl.Parent = Popup

		local btnRow = Instance.new("Frame")
		btnRow.Size = UDim2.new(1, 0, 0, 34)
		btnRow.BackgroundTransparency = 1
		btnRow.ZIndex = 202
		btnRow.Parent = Popup
		local bl = Instance.new("UIListLayout")
		bl.FillDirection = Enum.FillDirection.Horizontal
		bl.HorizontalAlignment = Enum.HorizontalAlignment.Right
		bl.Padding = UDim.new(0, 8)
		bl.Parent = btnRow

		local function Close() Overlay2:Destroy() end
		for _, b in ipairs(cfg.Buttons or {{Title="Confirmar"}}) do
			local bb = Instance.new("TextButton")
			bb.Size = UDim2.fromOffset(0, 34)
			bb.AutomaticSize = Enum.AutomaticSize.X
			bb.BackgroundColor3 = b.Primary and Theme.Accent or Shade(Theme.ElementBackground)
			bb.Text = "   " .. (b.Title or "Button") .. "   "
			bb.Font = FONT_BOLD
			bb.TextSize = 13
			bb.TextColor3 = b.Primary and Theme.Background or Theme.Text
			bb.ZIndex = 203
			bb.Parent = btnRow
			Round(4, bb)
			bb.MouseButton1Click:Connect(function()
				if b.Callback then pcall(b.Callback) end
				if b.CloseOnClick ~= false then Close() end
			end)
		end
		return { Close = Close }
	end

	function Window:CreateTab(tabConfig, maybeIcon)
		local cfg = NormalizeArgs(tabConfig)
		local tabName, tabIcon
		if cfg then tabName = cfg.Name or cfg.Title or "Tab"; tabIcon = cfg.Icon
		else tabName = tabConfig or "Tab"; tabIcon = maybeIcon end

		local page = Instance.new("ScrollingFrame")
		page.Size = UDim2.fromScale(1, 1)
		page.BackgroundTransparency = 1
		page.Visible = false
		page.ScrollBarThickness = 3
		page.CanvasSize = UDim2.new()
		page.AutomaticCanvasSize = Enum.AutomaticSize.Y
		page.ZIndex = 5
		page.Parent = PageHost
		local pageLayout = Instance.new("UIListLayout")
		pageLayout.Padding = UDim.new(0, 8)
		pageLayout.SortOrder = Enum.SortOrder.LayoutOrder
		pageLayout.Parent = page
		local pagePad = Instance.new("UIPadding")
		pagePad.PaddingTop = UDim.new(0, 12)
		pagePad.PaddingBottom = UDim.new(0, 14)
		pagePad.PaddingLeft = UDim.new(0, 16)
		pagePad.PaddingRight = UDim.new(0, 18)
		pagePad.Parent = page

		local tabBtn = Instance.new("TextButton")
		tabBtn.Size = UDim2.new(1, -16, 0, 28)
		tabBtn.BackgroundColor3 = Theme.Accent
		tabBtn.BackgroundTransparency = 1
		tabBtn.Text = ""
		tabBtn.AutoButtonColor = false
		tabBtn.ZIndex = 6
		tabBtn.Parent = Sidebar

		local deco = Instance.new("Frame")
		deco.Size = UDim2.fromScale(1, 1)
		deco.BackgroundTransparency = 1
		deco.Visible = false
		deco.ZIndex = 1
		deco.Parent = tabBtn

		local glow = Instance.new("Frame")
		glow.Size = UDim2.fromScale(1, 1)
		glow.BackgroundColor3 = Theme.Accent
		glow.BorderSizePixel = 0
		glow.ZIndex = 1
		glow.Parent = deco
		local gg = Instance.new("UIGradient")
		gg.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.5, 0.86),
			NumberSequenceKeypoint.new(1, 1),
		})
		gg.Parent = glow

		local topLine = Instance.new("Frame")
		topLine.Name = "TopLine"
		topLine.Size = UDim2.new(1, 0, 0, 1)
		topLine.BackgroundColor3 = Theme.Accent
		topLine.BorderSizePixel = 0
		topLine.ZIndex = 2
		topLine.Parent = deco
		local tg = Instance.new("UIGradient")
		tg.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.5, 0),
			NumberSequenceKeypoint.new(1, 1),
		})
		tg.Parent = topLine

		local botLine = Instance.new("Frame")
		botLine.Name = "BotLine"
		botLine.Size = UDim2.new(1, 0, 0, 1)
		botLine.Position = UDim2.new(0, 0, 1, -1)
		botLine.BackgroundColor3 = Theme.Accent
		botLine.BorderSizePixel = 0
		botLine.ZIndex = 2
		botLine.Parent = deco
		local bg2 = Instance.new("UIGradient")
		bg2.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.5, 0),
			NumberSequenceKeypoint.new(1, 1),
		})
		bg2.Parent = botLine

		local diamond = Instance.new("Frame")
		diamond.Name = "Diamond"
		diamond.Size = UDim2.fromOffset(5, 5)
		diamond.Position = UDim2.new(1, -17, 0.5, -3)
		diamond.BackgroundColor3 = Theme.Accent
		diamond.BorderSizePixel = 0
		diamond.Rotation = 45
		diamond.ZIndex = 3
		diamond.Parent = deco

		local tabRow = Instance.new("Frame")
		tabRow.Size = UDim2.fromScale(1, 1)
		tabRow.BackgroundTransparency = 1
		tabRow.ZIndex = 3
		tabRow.Parent = tabBtn
		local tabRowPad = Instance.new("UIPadding")
		tabRowPad.PaddingLeft = UDim.new(0, 40)
		tabRowPad.Parent = tabRow

		local tIcon
		local resolvedTabIcon, tabIconCustom = ResolveIcon(tabIcon)
		if resolvedTabIcon ~= "" then
			tIcon = Instance.new("ImageLabel")
			tIcon.Size = UDim2.fromOffset(16, 16)
			tIcon.Position = UDim2.new(0, -26, 0.5, -8)
			tIcon.BackgroundTransparency = 1
			tIcon.Image = resolvedTabIcon
			tIcon.ScaleType = Enum.ScaleType.Crop
			tIcon.ImageColor3 = tabIconCustom and Color3.new(1,1,1) or Theme.Placeholder
			tIcon.ZIndex = 4
			tIcon.Parent = tabRow
		end

		local tLabel = Instance.new("TextLabel")
		tLabel.Size = UDim2.new(1, -10, 1, 0)
		tLabel.BackgroundTransparency = 1
		tLabel.Text = tabName
		tLabel.Font = FONT_TITLE
		tLabel.TextSize = 17
		tLabel.TextColor3 = Theme.Placeholder
		tLabel.TextXAlignment = Enum.TextXAlignment.Left
		tLabel.ZIndex = 4
		tLabel.Parent = tabRow

		local tabData = { Type="TabBtn", Instance=tabBtn, Label=tLabel, Icon=tIcon, Deco=deco, Active=false, Page=page }
		table.insert(Registered, tabData)

		local function Activate()
			for _, item in ipairs(Registered) do
				if item.Type == "TabBtn" then
					item.Active = false
					item.Page.Visible = false
					item.Label.TextColor3 = Theme.Placeholder
					if item.Deco then item.Deco.Visible = false end
					if item.Icon then TintIfAllowed(item.Icon, Theme.Placeholder) end
				end
			end
			tabData.Active = true
			page.Visible = true
			tLabel.TextColor3 = Theme.Text
			deco.Visible = true
			if tIcon then TintIfAllowed(tIcon, Theme.Accent) end
		end

		tabBtn.MouseButton1Click:Connect(Activate)
		Ripple(tabBtn, Theme.Accent)
		if #Window.Tabs == 0 then task.defer(Activate) end

		local Tab = {}
		Window.Tabs[tabName] = Tab

		local function RegisterRow(height)
			local frame = Instance.new("Frame")
			frame.Size = UDim2.new(1, 0, 0, height or 42)
			frame.BackgroundColor3 = Theme.ElementBackground
			frame.BackgroundTransparency = elementTrans
			frame.ClipsDescendants = true
			frame.ZIndex = 6
			frame.Parent = page
			Round(4, frame)
			local stroke = Outline(frame, Theme.Outline, 1, 0.3)
			local accentBar = Instance.new("Frame")
			accentBar.Size = UDim2.new(0, 0, 1, 0)
			accentBar.BackgroundColor3 = Theme.Accent
			accentBar.BorderSizePixel = 0
			accentBar.ZIndex = 7
			accentBar.Parent = frame
			return frame, stroke, accentBar
		end

		local function AttachIcon(row, cfg, label)
			local icon = cfg and cfg.Icon
			if not icon then return nil end
			local position = cfg.IconPosition or "Left"
			local image = Img(row, icon, UDim2.fromOffset(16, 16), Theme.Icon, 0, 8)
			if not image then return nil end
			image.AnchorPoint = Vector2.new(position == "Right" and 1 or 0, 0.5)
			image.Position = position == "Right" and UDim2.new(1, -12, 0.5, 0) or UDim2.new(0, 14, 0.5, 0)
			if label and position == "Left" then
				label.Position = UDim2.new(0, 38, label.Position.Y.Scale, label.Position.Y.Offset)
				label.Size = UDim2.new(label.Size.X.Scale, label.Size.X.Offset - 30, label.Size.Y.Scale, label.Size.Y.Offset)
			elseif label and position == "Right" then
				label.Size = UDim2.new(label.Size.X.Scale, label.Size.X.Offset - 30, label.Size.Y.Scale, label.Size.Y.Offset)
			end
			return image
		end

		function Tab:CreateSection(secConfig)
			local cfg = NormalizeArgs(secConfig)
			local name = cfg and (cfg.Name or cfg.Title) or secConfig or "Section"

			local container = Instance.new("Frame")
			container.Size = UDim2.new(1, 0, 0, 0)
			container.AutomaticSize = Enum.AutomaticSize.Y
			container.BackgroundTransparency = 1
			container.ZIndex = 6
			container.Parent = page
			local layout = Instance.new("UIListLayout")
			layout.Padding = UDim.new(0, 8)
			layout.Parent = container

			local header = Instance.new("Frame")
			header.Size = UDim2.new(1, 0, 0, 24)
			header.BackgroundTransparency = 1
			header.ZIndex = 6
			header.Parent = container

			local hLabel = Instance.new("TextLabel")
			hLabel.Size = UDim2.new(1, -12, 0, 20)
			hLabel.Position = UDim2.new(0, 0, 0, 0)
			hLabel.BackgroundTransparency = 1
			hLabel.Text = tostring(name)
			hLabel.Font = FONT_TITLE
			hLabel.TextSize = 18
			hLabel.TextColor3 = Theme.Accent
			hLabel.TextXAlignment = Enum.TextXAlignment.Left
			hLabel.ZIndex = 7
			hLabel.Parent = header
			local sectionIcon = cfg and AttachIcon(header, cfg, hLabel)
			table.insert(Registered, {Type="Section", Label=hLabel, Icon=sectionIcon})

			local hLine = Instance.new("Frame")
			hLine.Size = UDim2.new(1, 0, 0, 1)
			hLine.Position = UDim2.new(0, 0, 1, -2)
			hLine.BackgroundColor3 = Theme.Outline
			hLine.BorderSizePixel = 0
			hLine.ZIndex = 7
			hLine.Parent = header
			local hg2 = Instance.new("UIGradient")
			hg2.Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0),
				NumberSequenceKeypoint.new(1, 1),
			})
			hg2.Parent = hLine

			local Section = {}

			function Section:CreateToggle(tConfig)
				local c = NormalizeArgs(tConfig) or {}
				local name = c.Name or c.Title or "Toggle"
				local desc = c.Desc or c.Description or c.Content or ""
				local default = c.Default
				if default == nil then default = c.Value or false end
				local callback = c.Callback or function() end
				local flag = c.Flag
				if flag and SZK.Flags[flag] ~= nil then default = SZK.Flags[flag] end

				local rowH = (desc ~= "" and 78 or 46)
				local row, stroke, accentBar = RegisterRow(rowH)
				row.Parent = container
				ApplyDependsOn(row, c)

				local lbl = Instance.new("TextLabel")
				lbl.Size = UDim2.new(1, -78, 0, 18)
				lbl.Position = UDim2.new(0, 14, 0, 10)
				lbl.BackgroundTransparency = 1
				lbl.Text = name
				lbl.Font = FONT_BOLD
				lbl.TextSize = 13
				lbl.TextColor3 = Theme.Text
				lbl.TextXAlignment = Enum.TextXAlignment.Left
				lbl.ZIndex = 7
				lbl.Parent = row
				local elementIcon = AttachIcon(row, c, lbl)

				if desc ~= "" then
					local d = Instance.new("TextLabel")
					d.Size = UDim2.new(1, -24, 0, 28)
					d.Position = UDim2.new(0, 14, 0, 34)
					d.BackgroundTransparency = 1
					d.Text = desc
					d.Font = FONT_BODY
					d.TextSize = 11
					d.TextColor3 = Theme.Placeholder
					d.TextXAlignment = Enum.TextXAlignment.Left
					d.TextYAlignment = Enum.TextYAlignment.Top
					d.TextWrapped = true
					d.ZIndex = 7
					d.Parent = row
				end

				local sw, sh, ks, ins = 42, 22, 18, 2
				local track = Instance.new("TextButton")
				track.AnchorPoint = Vector2.new(1, 0)
				track.Position = UDim2.new(1, -14, 0, 8)
				track.Size = UDim2.fromOffset(sw, sh)
				track.BackgroundColor3 = default and Theme.Toggle or Color3.fromRGB(60,60,65)
				track.Text = ""
				track.AutoButtonColor = false
				track.ZIndex = 8
				track.Parent = row
				Round(sh, track)

				local knob = Instance.new("Frame")
				knob.AnchorPoint = Vector2.new(0, 0.5)
				knob.Position = UDim2.new(0, ins, 0.5, 0)
				knob.Size = UDim2.fromOffset(ks, ks)
				knob.BackgroundColor3 = Color3.fromRGB(255,255,255)
				knob.ZIndex = 9
				knob.Parent = track
				Round(ks, knob)

				local state = default
				if flag then SZK.Flags[flag] = state end

				local function refresh(anim)
					local pos = state and UDim2.new(1, -(ins + ks), 0.5, 0) or UDim2.new(0, ins, 0.5, 0)
					local col = state and Theme.Toggle or Color3.fromRGB(60,60,65)
					if anim then
						Tween(knob, 0.16, {Position = pos})
						Tween(track, 0.16, {BackgroundColor3 = col})
					else
						knob.Position = pos
						track.BackgroundColor3 = col
					end
				end
				refresh(false)

				track.MouseButton1Click:Connect(function()
					state = not state
					if flag then SZK.Flags[flag] = state end
					refresh(true)
					callback(state)
					CheckDependents()
				end)

				table.insert(Registered, {Type="Element", Instance=row, Stroke=stroke, Label=lbl, Icon=elementIcon, SubColor=track, State=function() return state end})
				local obj = {}
				function obj:Set(v) state = v; if flag then SZK.Flags[flag] = state end; refresh(true); callback(state); CheckDependents() end
				function obj:Get() return state end
				return obj
			end

			function Section:CreateSlider(sConfig)
				local c = NormalizeArgs(sConfig) or {}
				local name = c.Name or c.Title or "Slider"
				local min = c.Min or 0
				local max = c.Max or 100
				local default = c.Default or c.Value or min
				local callback = c.Callback or function() end

				local row, stroke, accentBar = RegisterRow(54)
				row.Parent = container
				ApplyDependsOn(row, c)

				local lbl = Instance.new("TextLabel")
				lbl.Size = UDim2.new(1, -20, 0, 18)
				lbl.Position = UDim2.new(0, 14, 0, 4)
				lbl.BackgroundTransparency = 1
				lbl.Text = name
				lbl.Font = FONT_BODY
				lbl.TextSize = 12
				lbl.TextColor3 = Theme.Text
				lbl.TextXAlignment = Enum.TextXAlignment.Left
				lbl.ZIndex = 7
				lbl.Parent = row
				local elementIcon = AttachIcon(row, c, lbl)

				local valLbl = Instance.new("TextLabel")
				valLbl.Size = UDim2.fromOffset(50, 18)
				valLbl.Position = UDim2.new(1, -62, 0, 4)
				valLbl.BackgroundTransparency = 1
				valLbl.Text = tostring(default)
				valLbl.Font = FONT_BOLD
				valLbl.TextSize = 12
				valLbl.TextColor3 = Theme.Accent
				valLbl.TextXAlignment = Enum.TextXAlignment.Right
				valLbl.ZIndex = 7
				valLbl.Parent = row

				local track = Instance.new("Frame")
				track.Size = UDim2.new(1, -28, 0, 3)
				track.Position = UDim2.new(0, 14, 0, 34)
				track.BackgroundColor3 = Shade(Theme.ElementBackground)
				track.ZIndex = 7
				track.Parent = row

				local fill = Instance.new("Frame")
				local t0 = (default - min) / math.max(max - min, 1)
				fill.Size = UDim2.new(t0, 0, 1, 0)
				fill.BackgroundColor3 = Theme.Slider
				fill.ZIndex = 8
				fill.Parent = track

				local handle = Instance.new("Frame")
				handle.Size = UDim2.fromOffset(10, 10)
				handle.AnchorPoint = Vector2.new(0.5, 0.5)
				handle.Position = UDim2.new(t0, 0, 0.5, 0)
				handle.Rotation = 45
				handle.BackgroundColor3 = Theme.Slider
				handle.ZIndex = 9
				handle.Parent = track
				Outline(handle, Color3.new(1,1,1), 1, 0.3)

				local dragging = false
				local function apply(v)
					v = math.clamp(math.floor(v + 0.5), min, max)
					valLbl.Text = tostring(v)
					local t = (v - min) / math.max(max - min, 1)
					fill.Size = UDim2.new(t, 0, 1, 0)
					handle.Position = UDim2.new(t, 0, 0.5, 0)
					callback(v)
				end
				local function fromX(x)
					local abs, sz = track.AbsolutePosition.X, track.AbsoluteSize.X
					if sz <= 0 then return end
					apply(min + math.clamp((x - abs) / sz, 0, 1) * (max - min))
				end

				track.InputBegan:Connect(function(i)
					if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
						dragging = true; fromX(i.Position.X)
					end
				end)
				Track(UserInputService.InputChanged:Connect(function(i)
					if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then fromX(i.Position.X) end
				end))
				Track(UserInputService.InputEnded:Connect(function() dragging = false end))

				table.insert(Registered, {Type="Element", Instance=row, Stroke=stroke, Label=lbl, Icon=elementIcon, SubColor=fill, SubRole="Slider", Extras={{Kind="Accent", Object=handle}}})
				local obj = {}
				function obj:Set(v) apply(v) end
				function obj:Get() return tonumber(valLbl.Text) end
				return obj
			end

			function Section:CreateButton(bConfig)
				local c = NormalizeArgs(bConfig) or {}
				local name = c.Name or c.Title or "Button"
				local description = c.Description or c.Desc
				local icon = c.Icon
				local callback = c.Callback or function() end
				local customColor = c.Color or c.ButtonColor
				if type(customColor) == "string" then
					local ok, col = pcall(function() return Color3.fromHex(customColor) end)
					customColor = ok and col or nil
				elseif typeof(customColor) ~= "Color3" then customColor = nil end
				local baseColor = customColor or Theme.ElementBackground
				local hoverColor = customColor and Shade(customColor, 0.12) or Shade(Theme.ElementBackground, 0.06)

				local row = Instance.new("TextButton")
				row.Size = UDim2.new(1, 0, 0, description and 56 or 42)
				row.BackgroundColor3 = baseColor
				row.BackgroundTransparency = elementTrans
				row.Text = ""
				row.AutoButtonColor = false
				row.ZIndex = 6
				row.Parent = container
				ApplyDependsOn(row, c)
				Round(4, row)
				local stroke = Outline(row, Theme.Outline, 1, 0.35)

				local iconImg
				if icon then
					iconImg = Img(row, icon, UDim2.fromOffset(18, 18), Theme.Icon, 0, 8)
					if iconImg then iconImg.Position = UDim2.new(0, 14, 0.5, -9) end
				end

				local titleLbl = Instance.new("TextLabel")
				titleLbl.Position = UDim2.new(0, icon and 42 or 16, 0, description and 12 or 0)
				titleLbl.Size = UDim2.new(1, -(icon and 42 or 16) - 14, 0, description and 18 or row.Size.Y.Offset)
				titleLbl.BackgroundTransparency = 1
				titleLbl.Text = name
				titleLbl.Font = FONT_BOLD
				titleLbl.TextSize = 13
				titleLbl.TextColor3 = Theme.Text
				titleLbl.TextXAlignment = Enum.TextXAlignment.Left
				titleLbl.ZIndex = 7
				titleLbl.Parent = row

				local descLbl
				if description then
					descLbl = Instance.new("TextLabel")
					descLbl.Position = UDim2.new(0, icon and 42 or 16, 0, 30)
					descLbl.Size = UDim2.new(1, -(icon and 42 or 16) - 14, 0, 16)
					descLbl.BackgroundTransparency = 1
					descLbl.Text = description
					descLbl.Font = FONT_BODY
					descLbl.TextSize = 11
					descLbl.TextColor3 = Theme.Placeholder
					descLbl.TextXAlignment = Enum.TextXAlignment.Left
					descLbl.ZIndex = 7
					descLbl.Parent = row
				end

				row.MouseEnter:Connect(function() Tween(row, 0.12, {BackgroundColor3 = hoverColor}) end)
				row.MouseLeave:Connect(function() Tween(row, 0.12, {BackgroundColor3 = baseColor}) end)
				row.MouseButton1Click:Connect(function() callback() end)
				Ripple(row, Theme.Accent)

				local extras = {}
				if descLbl then table.insert(extras, {Kind="Text", Object=descLbl}) end
				if iconImg then table.insert(extras, {Kind="Icon", Object=iconImg}) end
				table.insert(Registered, {Type="Element", Instance=row, Stroke=stroke, Label=titleLbl, CustomButtonColor=customColor, Extras=#extras > 0 and extras or nil})
			end

			function Section:CreateBanner(bnConfig)
				local c = NormalizeArgs(bnConfig) or {}
				local resolved = ResolveIcon(c.Image or c.Banner)
				local hasImage = resolved ~= ""
				local frame = Instance.new("Frame")
				frame.Size = UDim2.new(1, 0, 0, c.Height or 120)
				frame.BackgroundColor3 = Theme.ElementBackground
				frame.BackgroundTransparency = elementTrans
				frame.ClipsDescendants = true
				frame.ZIndex = 6
				frame.Visible = hasImage
				frame.Parent = container
				ApplyDependsOn(frame, c)
				Round(4, frame)
				local stroke = Outline(frame, Theme.Outline, 1, 0.3)
				local img = Instance.new("ImageLabel")
				img.Size = UDim2.fromScale(1, 1)
				img.BackgroundTransparency = 1
				img.Image = resolved
				img.ScaleType = Enum.ScaleType.Crop
				img.ZIndex = 7
				img.Parent = frame
				table.insert(Registered, {Type="Element", Instance=frame, Stroke=stroke})
				local obj = {}
				function obj:SetImage(src)
					local r = ResolveIcon(src)
					img.Image = r
					frame.Visible = (r ~= "")
				end
				function obj:SetHeight(h)
					if tonumber(h) then frame.Size = UDim2.new(1, 0, 0, tonumber(h)) end
				end
				function obj:Get() return img.Image end
				function obj:Remove()
					if frame and frame.Parent then frame:Destroy() end
				end
				return obj
			end

			function Section:CreateHero(hConfig)
				local c = NormalizeArgs(hConfig) or {}
				local frame = Instance.new("Frame")
				frame.Size = UDim2.new(1, 0, 0, c.Height or 176)
				frame.BackgroundColor3 = Theme.ElementBackground
				frame.BackgroundTransparency = elementTrans
				frame.ClipsDescendants = true
				frame.ZIndex = 6
				frame.Parent = container
				ApplyDependsOn(frame, c)
				Round(6, frame)
				local stroke = Outline(frame, Theme.Outline, 1, 0.3)
				local accentBar = Instance.new("Frame")
				accentBar.Size = UDim2.new(1, 0, 0, 2)
				accentBar.BackgroundColor3 = Theme.Accent
				accentBar.ZIndex = 7
				accentBar.Parent = frame

				local titleLbl = Instance.new("TextLabel")
				titleLbl.Size = UDim2.new(1, -32, 0, 22)
				titleLbl.Position = UDim2.new(0, 16, 0, 20)
				titleLbl.BackgroundTransparency = 1
				titleLbl.Text = c.Title or c.Name or ""
				titleLbl.Font = FONT_TITLE
				titleLbl.TextSize = 18
				titleLbl.TextColor3 = Theme.Text
				titleLbl.TextXAlignment = Enum.TextXAlignment.Left
				titleLbl.ZIndex = 8
				titleLbl.Parent = frame

				local contentLbl = Instance.new("TextLabel")
				contentLbl.Size = UDim2.new(1, -32, 1, -62)
				contentLbl.Position = UDim2.new(0, 16, 0, 50)
				contentLbl.BackgroundTransparency = 1
				contentLbl.Text = c.Content or c.Description or c.Text or ""
				contentLbl.Font = FONT_BODY
				contentLbl.TextSize = 12
				contentLbl.TextColor3 = Theme.Placeholder
				contentLbl.TextWrapped = true
				contentLbl.TextXAlignment = Enum.TextXAlignment.Left
				contentLbl.TextYAlignment = Enum.TextYAlignment.Top
				contentLbl.ZIndex = 8
				contentLbl.Parent = frame
				table.insert(Registered, {Type="Element", Instance=frame, Stroke=stroke, AccentBar=accentBar, Label=titleLbl, Extras={{Kind="Text", Object=contentLbl}}})
				local obj = {}
				function obj:SetText(t, b) if t then titleLbl.Text = t end; if b then contentLbl.Text = b end end
				return obj
			end

			function Section:CreateDropdown(dConfig)
				local c = NormalizeArgs(dConfig) or {}
				local name = c.Name or c.Title or "Dropdown"
				local options = c.Options or {}
				local multi = c.Multi == true
				local default = c.Default
				if default == nil then default = c.Value end
				local callback = c.Callback or function() end
				local flag = c.Flag

				local selected
				if multi then
					selected = {}
					if type(default) == "table" then for _, v in ipairs(default) do selected[v] = true end
					elseif default ~= nil then selected[default] = true end
				else selected = default end

				local row, stroke, accentBar = RegisterRow(40)
				row.Parent = container
				ApplyDependsOn(row, c)

				local lbl = Instance.new("TextLabel")
				lbl.Size = UDim2.new(0.4, 0, 1, 0)
				lbl.Position = UDim2.new(0, 14, 0, 0)
				lbl.BackgroundTransparency = 1
				lbl.Text = name
				lbl.Font = FONT_BODY
				lbl.TextSize = 13
				lbl.TextColor3 = Theme.Text
				lbl.TextXAlignment = Enum.TextXAlignment.Left
				lbl.ZIndex = 7
				lbl.Parent = row
				local elementIcon = AttachIcon(row, c, lbl)

				local sel = Instance.new("TextButton")
				sel.Size = UDim2.new(0.55, -12, 0, 26)
				sel.Position = UDim2.new(0.42, 0, 0.5, -13)
				sel.BackgroundColor3 = Shade(Theme.ElementBackground)
				sel.Text = ""
				sel.ZIndex = 7
				sel.Parent = row
				Round(4, sel)

				local function format()
					if multi then
						local parts = {}
						for _, o in ipairs(options) do
							local v = type(o) == "table" and (o.Value or o.Text) or o
							local txt = type(o) == "table" and (o.Text or o.Value) or tostring(o)
							if selected[v] then table.insert(parts, tostring(txt)) end
						end
						if #parts == 0 then return "Seleccionar..." end
						if #parts <= 2 then return table.concat(parts, ", ") end
						return string.format("%d seleccionados", #parts)
					end
					return selected ~= nil and tostring(selected) or "Seleccionar..."
				end

				local selLbl = Instance.new("TextLabel")
				selLbl.Size = UDim2.new(1, -20, 1, 0)
				selLbl.Position = UDim2.new(0, 10, 0, 0)
				selLbl.BackgroundTransparency = 1
				selLbl.Text = format()
				selLbl.Font = FONT_BODY
				selLbl.TextSize = 12
				selLbl.TextColor3 = Theme.Text
				selLbl.TextXAlignment = Enum.TextXAlignment.Left
				selLbl.TextTruncate = Enum.TextTruncate.AtEnd
				selLbl.ZIndex = 8
				selLbl.Parent = sel

				local list = Instance.new("ScrollingFrame")
				list.BackgroundColor3 = Theme.ElementBackground
				list.BackgroundTransparency = 0.05
				list.Visible = false
				list.ZIndex = 100
				list.ClipsDescendants = true
				list.BorderSizePixel = 0
				list.ScrollBarThickness = 3
				list.CanvasSize = UDim2.new()
				list.AutomaticCanvasSize = Enum.AutomaticSize.None
				list.Parent = WindowGui
				Round(4, list)
				Outline(list, Theme.Outline, 1, 0.15)

				local listLayout = Instance.new("UIListLayout")
				listLayout.SortOrder = Enum.SortOrder.LayoutOrder
				listLayout.Padding = UDim.new(0, 2)
				listLayout.Parent = list

				local function getMulti()
					local a = {}
					for _, o in ipairs(options) do
						local v = type(o) == "table" and (o.Value or o.Text) or o
						if selected[v] then table.insert(a, v) end
					end
					return a
				end
				local function setFlag() if flag then SZK.Flags[flag] = multi and getMulti() or selected end end
				local function build()
					for _, ch in ipairs(list:GetChildren()) do if ch:IsA("TextButton") then ch:Destroy() end end
					for i, o in ipairs(options) do
						local txt = type(o) == "table" and (o.Text or o.Value) or tostring(o)
						local v = type(o) == "table" and (o.Value or o.Text) or o
						local on = multi and selected[v] or (selected == v)
						local ob = Instance.new("TextButton")
						ob.Size = UDim2.new(1, 0, 0, 26)
						ob.BackgroundColor3 = Shade(Theme.ElementBackground)
						ob.BackgroundTransparency = on and 0.7 or 1
						ob.Text = "  " .. txt
						ob.Font = FONT_BODY
						ob.TextSize = 12
						ob.TextColor3 = on and Theme.Accent or Theme.Text
						ob.TextXAlignment = Enum.TextXAlignment.Left
						ob.ZIndex = 101
						ob.LayoutOrder = i
						ob.Parent = list
						ob.MouseButton1Click:Connect(function()
							if multi then
								selected[v] = not selected[v]
								selLbl.Text = format()
								build()
								setFlag()
								callback(getMulti())
							else
								selected = v
								selLbl.Text = txt
								list.Visible = false
								setFlag()
								callback(v)
							end
							CheckDependents()
						end)
					end
					list.CanvasSize = UDim2.new(0, 0, 0, (#options * 26) + 4)
				end
				build()
				setFlag()
				RegisterPopup(list, sel)
				sel.MouseButton1Click:Connect(function()
					if list.Visible then list.Visible = false; return end
					CloseAllPopups(sel)
					task.wait()
					local abs, asz = sel.AbsolutePosition, sel.AbsoluteSize
					local vp = GetViewport()
					local lh = math.clamp((#options * 26) + 4, 30, 200)
					local lw = math.max(asz.X, 130)
					local x = math.clamp(abs.X, 8, math.max(8, vp.X - lw - 8))
					local belowY = abs.Y + asz.Y + 4
					local y = belowY
					if belowY + lh > vp.Y - 10 then y = math.max(10, abs.Y - lh - 4) end
					list.Size = UDim2.fromOffset(lw, lh)
					list.Position = UDim2.fromOffset(x, y)
					list.Visible = true
				end)

				table.insert(Registered, {Type="Element", Instance=row, Stroke=stroke, Label=lbl, Icon=elementIcon, SubBg=sel, SubText=selLbl})
				local obj = {}
				function obj:Set(v)
					if multi then
						selected = {}
						if type(v) == "table" then for _, x in ipairs(v) do selected[x] = true end end
						selLbl.Text = format()
						build()
					else
						selected = v
						selLbl.Text = tostring(v)
					end
					setFlag()
					CheckDependents()
				end
				function obj:Get() return multi and getMulti() or selected end
				function obj:Refresh(opts) options = opts or {}; build() end
				return obj
			end

			function Section:CreateColorPicker(cpConfig)
				local c = NormalizeArgs(cpConfig) or {}
				local name = c.Name or c.Title or "Color"
				local default = c.Default or c.Value or Color3.fromRGB(220, 40, 40)
				local callback = c.Callback or function() end

				local row, stroke, accentBar = RegisterRow(40)
				row.Parent = container
				ApplyDependsOn(row, c)

				local lbl = Instance.new("TextLabel")
				lbl.Size = UDim2.new(1, -50, 1, 0)
				lbl.Position = UDim2.new(0, 14, 0, 0)
				lbl.BackgroundTransparency = 1
				lbl.Text = name
				lbl.Font = FONT_BODY
				lbl.TextSize = 13
				lbl.TextColor3 = Theme.Text
				lbl.TextXAlignment = Enum.TextXAlignment.Left
				lbl.ZIndex = 7
				lbl.Parent = row
				local elementIcon = AttachIcon(row, c, lbl)

				local swatch = Instance.new("Frame")
				swatch.Size = UDim2.fromOffset(26, 18)
				swatch.Position = UDim2.new(1, -40, 0.5, -9)
				swatch.BackgroundColor3 = default
				swatch.ZIndex = 7
				swatch.Parent = row
				Round(3, swatch)
				Outline(swatch, Color3.fromRGB(0,0,0), 1, 0.3)

				local click = Instance.new("TextButton")
				click.Size = UDim2.fromScale(1, 1)
				click.BackgroundTransparency = 1
				click.Text = ""
				click.ZIndex = 8
				click.Parent = row

				local overlay = Instance.new("Frame")
				overlay.Size = UDim2.fromScale(1, 1)
				overlay.BackgroundColor3 = Color3.new(0, 0, 0)
				overlay.BackgroundTransparency = 0.45
				overlay.Visible = false
				overlay.ZIndex = 60
				overlay.Parent = MainFrame
				local ovc = Instance.new("TextButton")
				ovc.Size = UDim2.fromScale(1, 1)
				ovc.BackgroundTransparency = 1
				ovc.Text = ""
				ovc.ZIndex = 60
				ovc.Parent = overlay
				ovc.MouseButton1Click:Connect(function() overlay.Visible = false end)

				local popup = Instance.new("Frame")
				popup.Size = UDim2.fromOffset(240, 200)
				popup.Position = UDim2.fromScale(0.5, 0.5)
				popup.AnchorPoint = Vector2.new(0.5, 0.5)
				popup.BackgroundColor3 = Theme.ElementBackground
				popup.BackgroundTransparency = 0.05
				popup.ZIndex = 61
				popup.Parent = overlay
				Round(5, popup)
				Outline(popup, Theme.Outline, 1, 0.15)

				local hue, sat, val = default:ToHSV()
				local selected = default

				local svBox = Instance.new("Frame")
				svBox.Size = UDim2.new(1, -24, 0, 110)
				svBox.Position = UDim2.new(0, 12, 0, 12)
				svBox.BackgroundColor3 = Color3.fromHSV(hue, 1, 1)
				svBox.ZIndex = 62
				svBox.Parent = popup
				Round(4, svBox)

				local white = Instance.new("Frame")
				white.Size = UDim2.fromScale(1, 1)
				white.BackgroundColor3 = Color3.new(1,1,1)
				white.ZIndex = 62
				white.Parent = svBox
				local wg = Instance.new("UIGradient")
				wg.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1)})
				wg.Parent = white

				local black = Instance.new("Frame")
				black.Size = UDim2.fromScale(1, 1)
				black.BackgroundColor3 = Color3.new(0,0,0)
				black.ZIndex = 63
				black.Parent = svBox
				local bg2 = Instance.new("UIGradient")
				bg2.Rotation = 90
				bg2.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0)})
				bg2.Parent = black

				local cursor = Instance.new("Frame")
				cursor.Size = UDim2.fromOffset(10, 10)
				cursor.AnchorPoint = Vector2.new(0.5, 0.5)
				cursor.Position = UDim2.new(sat, 0, 1 - val, 0)
				cursor.Rotation = 45
				cursor.BackgroundColor3 = Color3.new(1,1,1)
				cursor.ZIndex = 64
				cursor.Parent = svBox
				Outline(cursor, Color3.new(0,0,0), 1, 0.2)

				local hueTrack = Instance.new("Frame")
				hueTrack.Size = UDim2.new(1, -24, 0, 12)
				hueTrack.Position = UDim2.new(0, 12, 0, 130)
				hueTrack.ZIndex = 62
				hueTrack.Parent = popup
				local hg = Instance.new("UIGradient")
				hg.Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.fromHSV(0, 1, 1)),
					ColorSequenceKeypoint.new(0.166, Color3.fromHSV(0.166, 1, 1)),
					ColorSequenceKeypoint.new(0.333, Color3.fromHSV(0.333, 1, 1)),
					ColorSequenceKeypoint.new(0.5, Color3.fromHSV(0.5, 1, 1)),
					ColorSequenceKeypoint.new(0.666, Color3.fromHSV(0.666, 1, 1)),
					ColorSequenceKeypoint.new(0.833, Color3.fromHSV(0.833, 1, 1)),
					ColorSequenceKeypoint.new(1, Color3.fromHSV(1, 1, 1)),
				})
				hg.Parent = hueTrack

				local hueKnob = Instance.new("Frame")
				hueKnob.Size = UDim2.fromOffset(4, 16)
				hueKnob.AnchorPoint = Vector2.new(0.5, 0.5)
				hueKnob.Position = UDim2.new(hue, 0, 0.5, 0)
				hueKnob.BackgroundColor3 = Color3.new(1,1,1)
				hueKnob.ZIndex = 63
				hueKnob.Parent = hueTrack

				local prev = Instance.new("Frame")
				prev.Size = UDim2.fromOffset(28, 22)
				prev.Position = UDim2.new(0, 12, 0, 154)
				prev.BackgroundColor3 = selected
				prev.ZIndex = 62
				prev.Parent = popup
				Round(3, prev)
				Outline(prev, Theme.Outline, 1, 0.2)

				local closeCp = Instance.new("TextButton")
				closeCp.Size = UDim2.fromOffset(60, 22)
				closeCp.Position = UDim2.new(1, -72, 0, 154)
				closeCp.BackgroundColor3 = Shade(Theme.ElementBackground)
				closeCp.Text = "Listo"
				closeCp.Font = FONT_BOLD
				closeCp.TextSize = 12
				closeCp.TextColor3 = Theme.Text
				closeCp.ZIndex = 62
				closeCp.Parent = popup
				Round(4, closeCp)
				Outline(closeCp, Theme.Outline, 1, 0.2)

				local function recompute(fire)
					selected = Color3.fromHSV(hue, sat, val)
					svBox.BackgroundColor3 = Color3.fromHSV(hue, 1, 1)
					cursor.Position = UDim2.new(sat, 0, 1 - val, 0)
					hueKnob.Position = UDim2.new(hue, 0, 0.5, 0)
					swatch.BackgroundColor3 = selected
					prev.BackgroundColor3 = selected
					if fire then callback(selected) end
				end

				local dragSV, dragHue = false, false
				svBox.InputBegan:Connect(function(i)
					if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
						dragSV = true
						local a, s = svBox.AbsolutePosition, svBox.AbsoluteSize
						sat = math.clamp((i.Position.X - a.X) / s.X, 0, 1)
						val = 1 - math.clamp((i.Position.Y - a.Y) / s.Y, 0, 1)
						recompute(true)
					end
				end)
				hueTrack.InputBegan:Connect(function(i)
					if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
						dragHue = true
						local a, s = hueTrack.AbsolutePosition, hueTrack.AbsoluteSize
						hue = math.clamp((i.Position.X - a.X) / s.X, 0, 1)
						recompute(true)
					end
				end)
				Track(UserInputService.InputChanged:Connect(function(i)
					if i.UserInputType ~= Enum.UserInputType.MouseMovement and i.UserInputType ~= Enum.UserInputType.Touch then return end
					if dragSV then
						local a, s = svBox.AbsolutePosition, svBox.AbsoluteSize
						sat = math.clamp((i.Position.X - a.X) / s.X, 0, 1)
						val = 1 - math.clamp((i.Position.Y - a.Y) / s.Y, 0, 1)
						recompute(true)
					elseif dragHue then
						local a, s = hueTrack.AbsolutePosition, hueTrack.AbsoluteSize
						hue = math.clamp((i.Position.X - a.X) / s.X, 0, 1)
						recompute(true)
					end
				end))
				Track(UserInputService.InputEnded:Connect(function() dragSV = false; dragHue = false end))

				click.MouseButton1Click:Connect(function() overlay.Visible = true end)
				closeCp.MouseButton1Click:Connect(function() overlay.Visible = false end)

				table.insert(Registered, {Type="Element", Instance=row, Stroke=stroke, Label=lbl, Icon=elementIcon})
				local obj = {}
				function obj:Set(col) hue, sat, val = col:ToHSV(); recompute(true) end
				function obj:Get() return selected end
				return obj
			end

			function Section:CreateInput(iConfig)
				local c = NormalizeArgs(iConfig) or {}
				local name = c.Name or c.Title or "Input"
				local placeholder = c.Placeholder or "Escribir..."
				local default = c.Default or c.Value or ""
				local callback = c.Callback or function() end

				local row, stroke, accentBar = RegisterRow(40)
				row.Parent = container
				ApplyDependsOn(row, c)

				local lbl = Instance.new("TextLabel")
				lbl.Size = UDim2.new(0.4, 0, 1, 0)
				lbl.Position = UDim2.new(0, 14, 0, 0)
				lbl.BackgroundTransparency = 1
				lbl.Text = name
				lbl.Font = FONT_BODY
				lbl.TextSize = 13
				lbl.TextColor3 = Theme.Text
				lbl.TextXAlignment = Enum.TextXAlignment.Left
				lbl.ZIndex = 7
				lbl.Parent = row
				local elementIcon = AttachIcon(row, c, lbl)

				local boxFrame = Instance.new("Frame")
				boxFrame.Size = UDim2.new(0.55, -12, 0, 26)
				boxFrame.Position = UDim2.new(0.42, 0, 0.5, -13)
				boxFrame.BackgroundColor3 = Shade(Theme.ElementBackground)
				boxFrame.ZIndex = 7
				boxFrame.Parent = row
				Round(4, boxFrame)

				local box = Instance.new("TextBox")
				box.Size = UDim2.new(1, -12, 1, 0)
				box.Position = UDim2.new(0, 6, 0, 0)
				box.BackgroundTransparency = 1
				box.Text = default
				box.PlaceholderText = placeholder
				box.PlaceholderColor3 = Theme.Placeholder
				box.TextColor3 = Theme.Text
				box.Font = FONT_BODY
				box.TextSize = 12
				box.ClearTextOnFocus = false
				box.ZIndex = 8
				box.Parent = boxFrame

				box.FocusLost:Connect(function(enter)
					callback(box.Text, enter)
					CheckDependents()
				end)

				table.insert(Registered, {Type="Element", Instance=row, Stroke=stroke, Label=lbl, Icon=elementIcon, SubBg=boxFrame, SubText=box})
				local obj = {}
				function obj:Set(t) box.Text = t end
				function obj:Get() return box.Text end
				return obj
			end

			function Section:CreateKeybind(kConfig)
				local c = NormalizeArgs(kConfig) or {}
				local name = c.Name or c.Title or "Keybind"
				local default = c.Default or c.Value
				local callback = c.Callback or function() end

				local row, stroke, accentBar = RegisterRow(40)
				row.Parent = container
				ApplyDependsOn(row, c)

				local lbl = Instance.new("TextLabel")
				lbl.Size = UDim2.new(1, -90, 1, 0)
				lbl.Position = UDim2.new(0, 14, 0, 0)
				lbl.BackgroundTransparency = 1
				lbl.Text = name
				lbl.Font = FONT_BODY
				lbl.TextSize = 13
				lbl.TextColor3 = Theme.Text
				lbl.TextXAlignment = Enum.TextXAlignment.Left
				lbl.ZIndex = 7
				lbl.Parent = row
				local elementIcon = AttachIcon(row, c, lbl)

				local keyBtn = Instance.new("TextButton")
				keyBtn.Size = UDim2.fromOffset(70, 24)
				keyBtn.Position = UDim2.new(1, -82, 0.5, -12)
				keyBtn.BackgroundColor3 = Shade(Theme.ElementBackground)
				keyBtn.Text = default and default.Name or "Ninguno"
				keyBtn.Font = FONT_BOLD
				keyBtn.TextSize = 11
				keyBtn.TextColor3 = Theme.Text
				keyBtn.ZIndex = 7
				keyBtn.Parent = row
				Round(4, keyBtn)

				local current = default
				local listening = false
				local conn
				keyBtn.MouseButton1Click:Connect(function()
					if listening then return end
					listening = true
					keyBtn.Text = "..."
					if conn then conn:Disconnect() end
					conn = Track(UserInputService.InputBegan:Connect(function(input)
						if input.UserInputType == Enum.UserInputType.Keyboard then
							current = input.KeyCode
							keyBtn.Text = current.Name
							listening = false
							if conn then conn:Disconnect() end
							callback(current)
							CheckDependents()
						end
					end))
				end)

				table.insert(Registered, {Type="Element", Instance=row, Stroke=stroke, Label=lbl, Icon=elementIcon, SubBg=keyBtn, SubText=keyBtn})
				local obj = {}
				function obj:Set(k) current = k; keyBtn.Text = k and k.Name or "Ninguno" end
				function obj:Get() return current end
				return obj
			end

			function Section:CreateProgressBar(pConfig)
				local c = NormalizeArgs(pConfig) or {}
				local name = c.Name or c.Title or "Progreso"
				local min = c.Min or 0
				local max = c.Max or 100
				local default = c.Default or c.Value or min
				local showPercent = c.ShowPercent
				if showPercent == nil then showPercent = true end

				local row, stroke, accentBar = RegisterRow(48)
				row.Parent = container
				ApplyDependsOn(row, c)

				local lbl = Instance.new("TextLabel")
				lbl.Size = UDim2.new(1, -70, 0, 18)
				lbl.Position = UDim2.new(0, 14, 0, 4)
				lbl.BackgroundTransparency = 1
				lbl.Text = name
				lbl.Font = FONT_BODY
				lbl.TextSize = 12
				lbl.TextColor3 = Theme.Text
				lbl.TextXAlignment = Enum.TextXAlignment.Left
				lbl.ZIndex = 7
				lbl.Parent = row
				local elementIcon = AttachIcon(row, c, lbl)

				local pctLbl = Instance.new("TextLabel")
				pctLbl.Size = UDim2.fromOffset(50, 18)
				pctLbl.Position = UDim2.new(1, -60, 0, 4)
				pctLbl.BackgroundTransparency = 1
				pctLbl.Font = FONT_BOLD
				pctLbl.TextSize = 12
				pctLbl.TextColor3 = Theme.Accent
				pctLbl.TextXAlignment = Enum.TextXAlignment.Right
				pctLbl.Visible = showPercent
				pctLbl.ZIndex = 7
				pctLbl.Parent = row

				local track = Instance.new("Frame")
				track.Size = UDim2.new(1, -28, 0, 4)
				track.Position = UDim2.new(0, 14, 0, 28)
				track.BackgroundColor3 = Shade(Theme.ElementBackground)
				track.ZIndex = 7
				track.Parent = row

				local fill = Instance.new("Frame")
				fill.Size = UDim2.fromScale(0, 1)
				fill.BackgroundColor3 = Theme.Accent
				fill.ZIndex = 8
				fill.Parent = track

				local value = default
				local function redraw(a)
					local t = math.clamp((value - min) / math.max(max - min, 1), 0, 1)
					if a then Tween(fill, 0.25, {Size = UDim2.fromScale(t, 1)})
					else fill.Size = UDim2.fromScale(t, 1) end
					pctLbl.Text = math.floor(t * 100) .. "%"
				end
				redraw(false)

				table.insert(Registered, {Type="Element", Instance=row, Stroke=stroke, Label=lbl, Icon=elementIcon})
				local obj = {}
				function obj:Set(v, a) value = math.clamp(v, min, max); redraw(a ~= false) end
				function obj:Get() return value end
				return obj
			end

			function Section:CreateLabel(text, iconConfig)
				if type(text) == "table" then iconConfig = text; text = text.Text or text.Title or "" end
				local iconCfg = type(iconConfig) == "table" and iconConfig or {}
				local row = Instance.new("Frame")
				row.Size = UDim2.new(1, 0, 0, 26)
				row.BackgroundTransparency = 1
				row.ZIndex = 6
				row.Parent = container
				local lbl = Instance.new("TextLabel")
				lbl.Size = UDim2.new(1, -12, 1, 0)
				lbl.Position = UDim2.new(0, 2, 0, 0)
				lbl.BackgroundTransparency = 1
				lbl.Text = tostring(text)
				lbl.Font = FONT_BODY
				lbl.TextSize = 12
				lbl.TextColor3 = Theme.Placeholder
				lbl.TextXAlignment = Enum.TextXAlignment.Left
				lbl.ZIndex = 7
				lbl.Parent = row
				local labelIcon = AttachIcon(row, iconCfg, lbl)
				table.insert(Registered, {Type="Section", Label=lbl, Icon=labelIcon})
			end

			function Section:CreateParagraph(text, iconConfig)
				if type(text) == "table" then iconConfig = text; text = text.Text or text.Title or "" end
				local iconCfg = type(iconConfig) == "table" and iconConfig or {}
				local row = Instance.new("Frame")
				row.Size = UDim2.new(1, 0, 0, 0)
				row.AutomaticSize = Enum.AutomaticSize.Y
				row.BackgroundColor3 = Theme.ElementBackground
				row.BackgroundTransparency = 0.35
				row.ZIndex = 6
				row.Parent = container
				Round(4, row)
				local pad = Instance.new("UIPadding")
				pad.PaddingTop = UDim.new(0, 8)
				pad.PaddingBottom = UDim.new(0, 8)
				pad.PaddingLeft = UDim.new(0, 12)
				pad.PaddingRight = UDim.new(0, 10)
				pad.Parent = row
				local lbl = Instance.new("TextLabel")
				lbl.Size = UDim2.new(1, 0, 0, 0)
				lbl.AutomaticSize = Enum.AutomaticSize.Y
				lbl.BackgroundTransparency = 1
				lbl.Text = tostring(text)
				lbl.Font = FONT_BODY
				lbl.TextSize = 12
				lbl.TextColor3 = Theme.Text
				lbl.TextWrapped = true
				lbl.TextXAlignment = Enum.TextXAlignment.Left
				lbl.ZIndex = 7
				lbl.Parent = row
				local labelIcon = AttachIcon(row, iconCfg, lbl)
				table.insert(Registered, {Type="Section", Label=lbl, Icon=labelIcon})
			end

			function Section:CreateDivider()
				local row = Instance.new("Frame")
				row.Size = UDim2.new(1, 0, 0, 10)
				row.BackgroundTransparency = 1
				row.ZIndex = 6
				row.Parent = container
				local line = Instance.new("Frame")
				line.Size = UDim2.new(1, 0, 0, 1)
				line.Position = UDim2.new(0, 0, 0.5, 0)
				line.BackgroundColor3 = Theme.Outline
				line.BackgroundTransparency = 0.5
				line.ZIndex = 7
				line.Parent = row
				table.insert(Registered, {Type="Element", Instance=row, Extras={{Kind="Outline", Object=line}}})
				return row
			end

			return Section
		end

		function Tab:CreateDivider() return Tab:CreateSection(""):CreateDivider() end
		function Tab:CreateToggle(...) return Tab:CreateSection(""):CreateToggle(...) end
		function Tab:CreateSlider(...) return Tab:CreateSection(""):CreateSlider(...) end
		function Tab:CreateButton(...) return Tab:CreateSection(""):CreateButton(...) end
		function Tab:CreateBanner(...) return Tab:CreateSection(""):CreateBanner(...) end
		function Tab:CreateHero(...) return Tab:CreateSection(""):CreateHero(...) end
		function Tab:CreateDropdown(...) return Tab:CreateSection(""):CreateDropdown(...) end
		function Tab:CreateColorPicker(...) return Tab:CreateSection(""):CreateColorPicker(...) end
		function Tab:CreateInput(...) return Tab:CreateSection(""):CreateInput(...) end
		function Tab:CreateKeybind(...) return Tab:CreateSection(""):CreateKeybind(...) end
		function Tab:CreateProgressBar(...) return Tab:CreateSection(""):CreateProgressBar(...) end
		function Tab:CreateLabel(...) return Tab:CreateSection(""):CreateLabel(...) end
		function Tab:CreateParagraph(...) return Tab:CreateSection(""):CreateParagraph(...) end

		return Tab
	end

	UpdateTheme(themeName, false)
	OpenWindow()

	table.insert(SZK.Windows, Window)
	return Window
end

SZK.New = SZK.CreateWindow
SZK.Window = SZK.CreateWindow

function SZK:Toggle(name)
	local f = SZK.Flags[name]
	if f ~= nil then SZK.Flags[name] = not f end
	return SZK.Flags[name]
end
function SZK:Get(name) return SZK.Flags[name] end
function SZK:Set(name, val) SZK.Flags[name] = val end

function SZK:Success(t, c, d) return SZK:Notify({Title=t or "Success", Content=c or "", Type="Success", Duration=d or 3}) end
function SZK:Error(t, c, d) return SZK:Notify({Title=t or "Error", Content=c or "", Type="Error", Duration=d or 3.5}) end
function SZK:Warn(t, c, d) return SZK:Notify({Title=t or "Warning", Content=c or "", Type="Warning", Duration=d or 3}) end
function SZK:Info(t, c, d) return SZK:Notify({Title=t or "Info", Content=c or "", Type="Info", Duration=d or 3}) end

return SZK
