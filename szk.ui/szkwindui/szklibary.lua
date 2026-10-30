--[[
    NovaUI - librería de UI para Roblox hecha desde cero
    Uso:
        local NovaUI = loadstring(...)()   -- o pega este script y usa 'return Library'
        local Window = NovaUI:CreateWindow({ Title = "Mi UI", Author = "yo", Icon = "✦" })
        local Tab = Window:Tab({ Title = "Principal", Icon = "⌂" })
        Tab:Button({ Title = "Hola", Callback = function() end })
]]

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local Library = { Flags = {}, Windows = {} }

--------------------------------------------------------------------
-- Temas
--------------------------------------------------------------------
Library.Themes = {
    Dark = {
        Background = Color3.fromHex("#101010"),
        Panel      = Color3.fromHex("#18181b"),
        Element    = Color3.fromHex("#212125"),
        Hover      = Color3.fromHex("#2b2b30"),
        Stroke     = Color3.fromHex("#3a3a42"),
        Text       = Color3.fromHex("#FFFFFF"),
        SubText    = Color3.fromHex("#a1a1aa"),
        Accent     = Color3.fromHex("#0091FF"),
        Good       = Color3.fromHex("#33C759"),
    },
    Midnight = {
        Background = Color3.fromHex("#0a0f1e"),
        Panel      = Color3.fromHex("#0c1e42"),
        Element    = Color3.fromHex("#132a58"),
        Hover      = Color3.fromHex("#1b3770"),
        Stroke     = Color3.fromHex("#2f4f8f"),
        Text       = Color3.fromHex("#dbeafe"),
        SubText    = Color3.fromHex("#8fb0e8"),
        Accent     = Color3.fromHex("#2563eb"),
        Good       = Color3.fromHex("#33C759"),
    },
    Rose = {
        Background = Color3.fromHex("#1f0308"),
        Panel      = Color3.fromHex("#3a0a18"),
        Element    = Color3.fromHex("#4c1424"),
        Hover      = Color3.fromHex("#5e1c30"),
        Stroke     = Color3.fromHex("#8a3350"),
        Text       = Color3.fromHex("#fdf2f8"),
        SubText    = Color3.fromHex("#d67aa6"),
        Accent     = Color3.fromHex("#e95f74"),
        Good       = Color3.fromHex("#33C759"),
    },
}

--------------------------------------------------------------------
-- Utilidades
--------------------------------------------------------------------
local function New(class, props, children)
    local inst = Instance.new(class)
    for k, v in pairs(props or {}) do
        inst[k] = v
    end
    for _, c in ipairs(children or {}) do
        c.Parent = inst
    end
    return inst
end

local function Tween(obj, time, props, style, dir)
    local t = TweenService:Create(
        obj,
        TweenInfo.new(time, style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out),
        props
    )
    t:Play()
    return t
end

local function Corner(r)
    return New("UICorner", { CornerRadius = UDim.new(0, r) })
end

local function Stroke(color, transparency, thickness)
    return New("UIStroke", {
        Color = color,
        Transparency = transparency or 0,
        Thickness = thickness or 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    })
end

local function Padding(t, l, r, b)
    return New("UIPadding", {
        PaddingTop = UDim.new(0, t),
        PaddingLeft = UDim.new(0, l or t),
        PaddingRight = UDim.new(0, r or l or t),
        PaddingBottom = UDim.new(0, b or t),
    })
end

local function List(padding, dir, ha, va)
    return New("UIListLayout", {
        Padding = UDim.new(0, padding or 0),
        FillDirection = dir or Enum.FillDirection.Vertical,
        HorizontalAlignment = ha or Enum.HorizontalAlignment.Left,
        VerticalAlignment = va or Enum.VerticalAlignment.Top,
        SortOrder = Enum.SortOrder.LayoutOrder,
    })
end

local function MakeDraggable(target, handle)
    local dragging, startPos, origin = false, nil, nil

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            startPos = input.Position
            origin = target.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    UIS.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
            local d = input.Position - startPos
            target.Position = UDim2.new(
                origin.X.Scale, origin.X.Offset + d.X,
                origin.Y.Scale, origin.Y.Offset + d.Y
            )
        end
    end)
end

-- Ícono: acepta texto/emoji ("⚙"), número o "rbxassetid://123"
local function MakeIcon(icon, size, color)
    if icon == nil or icon == "" then
        return nil
    end
    if type(icon) == "number" or tostring(icon):find("rbxassetid") then
        local id = type(icon) == "number" and ("rbxassetid://" .. icon) or icon
        return New("ImageLabel", {
            Size = UDim2.fromOffset(size, size),
            BackgroundTransparency = 1,
            Image = id,
            ImageColor3 = color,
        })
    end
    return New("TextLabel", {
        Size = UDim2.fromOffset(size, size),
        BackgroundTransparency = 1,
        Text = tostring(icon),
        TextSize = size,
        Font = Enum.Font.GothamMedium,
        TextColor3 = color,
    })
end

local function GetGuiParent(gui)
    local ok = pcall(function()
        if gethui then
            gui.Parent = gethui()
        else
            gui.Parent = game:GetService("CoreGui")
        end
    end)
    if not ok or not gui.Parent then
        gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
    end
end

--------------------------------------------------------------------
-- ScreenGui global + notificaciones
--------------------------------------------------------------------
local Gui = New("ScreenGui", {
    Name = "NovaUI",
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
})
pcall(function()
    if syn and syn.protect_gui then syn.protect_gui(Gui) end
end)
GetGuiParent(Gui)

local NotifyHolder = New("Frame", {
    Name = "Notifications",
    AnchorPoint = Vector2.new(1, 0),
    Position = UDim2.new(1, -16, 0, 16),
    Size = UDim2.new(0, 300, 1, -32),
    BackgroundTransparency = 1,
    Parent = Gui,
}, { List(8) })

function Library:Notify(o)
    o = o or {}
    local T = self.CurrentTheme or Library.Themes.Dark
    local duration = o.Duration or 4

    local outer = New("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Parent = NotifyHolder,
    })

    local card = New("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = T.Panel,
        BackgroundTransparency = 1,
        Position = UDim2.new(1, 40, 0, 0),
        ClipsDescendants = true,
        Parent = outer,
    }, { Corner(12), Stroke(T.Stroke, 0.3) })

    local inner = New("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Parent = card,
    }, { Padding(12, 14, 14, 16), List(3) })

    local icon = MakeIcon(o.Icon, 18, T.Accent)
    local titleRow = New("Frame", {
        Size = UDim2.new(1, 0, 0, 20),
        BackgroundTransparency = 1,
        Parent = inner,
    }, { List(8, Enum.FillDirection.Horizontal, nil, Enum.VerticalAlignment.Center) })
    if icon then icon.Parent = titleRow end
    New("TextLabel", {
        Size = UDim2.new(1, icon and -26 or 0, 1, 0),
        BackgroundTransparency = 1,
        Text = o.Title or "Notificación",
        Font = Enum.Font.GothamBold,
        TextSize = 15,
        TextColor3 = T.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = titleRow,
    })

    if o.Content then
        New("TextLabel", {
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            Text = o.Content,
            Font = Enum.Font.Gotham,
            TextSize = 13,
            TextWrapped = true,
            TextColor3 = T.SubText,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = inner,
        })
    end

    local bar = New("Frame", {
        AnchorPoint = Vector2.new(0, 1),
        Position = UDim2.new(0, 0, 1, 0),
        Size = UDim2.new(1, 0, 0, 3),
        BackgroundColor3 = T.Accent,
        BorderSizePixel = 0,
        Parent = card,
    })

    Tween(card, 0.35, { Position = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 0.05 })
    Tween(bar, duration, { Size = UDim2.new(0, 0, 0, 3) }, Enum.EasingStyle.Linear)

    task.delay(duration, function()
        if card.Parent then
            Tween(card, 0.3, { Position = UDim2.new(1, 40, 0, 0), BackgroundTransparency = 1 })
            task.wait(0.32)
            outer:Destroy()
        end
    end)
end

--------------------------------------------------------------------
-- Elementos (se adjuntan a Tab)
--------------------------------------------------------------------
local function AttachElements(obj, container, T, window)

    -- Base de cada elemento
    local function Base(title, desc, asButton, rightWidth)
        local f = New(asButton and "TextButton" or "Frame", {
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundColor3 = T.Element,
            Parent = container,
        }, {
            Corner(10),
            Stroke(T.Stroke, 0.6),
            Padding(10, 12),
            List(8),
            New("UISizeConstraint", { MinSize = Vector2.new(0, 42) }),
        })
        if asButton then
            f.Text = ""
            f.AutoButtonColor = false
        end

        local head = New("Frame", {
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            Parent = f,
        }, { New("UISizeConstraint", { MinSize = Vector2.new(0, 22) }) })

        local textFrame = New("Frame", {
            Size = UDim2.new(1, -(rightWidth or 0), 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            Parent = head,
        }, { List(2) })

        local titleLbl = New("TextLabel", {
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            Text = title or "Elemento",
            Font = Enum.Font.GothamMedium,
            TextSize = 15,
            TextWrapped = true,
            TextColor3 = T.Text,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = textFrame,
        })
        local descLbl = New("TextLabel", {
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            Text = desc or "",
            Visible = desc ~= nil and desc ~= "",
            Font = Enum.Font.Gotham,
            TextSize = 13,
            TextWrapped = true,
            TextColor3 = T.SubText,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = textFrame,
        })

        if asButton then
            f.MouseEnter:Connect(function() Tween(f, 0.12, { BackgroundColor3 = T.Hover }) end)
            f.MouseLeave:Connect(function() Tween(f, 0.12, { BackgroundColor3 = T.Element }) end)
        end

        return f, head, titleLbl, descLbl
    end

    local function Safe(cb, ...)
        if cb then
            local ok, err = pcall(cb, ...)
            if not ok then warn("[NovaUI] Error en callback: " .. tostring(err)) end
        end
    end

    ------------------------------------------------------------ Label / Section / Divider
    function obj:Label(o)
        o = o or {}
        local f, _, t, d = Base(o.Title or o.Text or "Label", o.Desc, false, 0)
        local api = {}
        function api:SetTitle(x) t.Text = x end
        function api:SetDesc(x) d.Text = x; d.Visible = x ~= "" end
        function api:Destroy() f:Destroy() end
        return api
    end
    obj.Paragraph = obj.Label

    function obj:Section(o)
        o = type(o) == "string" and { Title = o } or (o or {})
        local lbl = New("TextLabel", {
            Size = UDim2.new(1, 0, 0, 26),
            BackgroundTransparency = 1,
            Text = string.upper(o.Title or "Sección"),
            Font = Enum.Font.GothamBold,
            TextSize = 12,
            TextColor3 = T.Accent,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = container,
        }, { Padding(0, 4, 0, 0) })
        return { SetTitle = function(_, x) lbl.Text = string.upper(x) end, Destroy = function() lbl:Destroy() end }
    end

    function obj:Divider()
        return New("Frame", {
            Size = UDim2.new(1, 0, 0, 1),
            BackgroundColor3 = T.Stroke,
            BackgroundTransparency = 0.5,
            BorderSizePixel = 0,
            Parent = container,
        })
    end

    ------------------------------------------------------------ Button
    function obj:Button(o)
        o = o or {}
        local f, head = Base(o.Title or "Botón", o.Desc, true, 30)
        local arrow = New("TextLabel", {
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, 0, 0.5, 0),
            Size = UDim2.fromOffset(20, 20),
            BackgroundTransparency = 1,
            Text = o.Icon or "›",
            Font = Enum.Font.GothamBold,
            TextSize = 20,
            TextColor3 = T.SubText,
            Parent = head,
        })
        f.MouseButton1Click:Connect(function()
            Tween(f, 0.08, { BackgroundColor3 = T.Accent })
            task.delay(0.1, function() Tween(f, 0.2, { BackgroundColor3 = T.Element }) end)
            task.spawn(Safe, o.Callback)
        end)
        local api = {}
        function api:SetTitle(x) f:FindFirstChildWhichIsA("Frame", true) end
        function api:Destroy() f:Destroy() end
        return api
    end

    ------------------------------------------------------------ Toggle
    function obj:Toggle(o)
        o = o or {}
        local value = o.Value == true or o.Default == true
        local f, head = Base(o.Title or "Toggle", o.Desc, true, 56)

        local track = New("Frame", {
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, 0, 0.5, 0),
            Size = UDim2.fromOffset(42, 22),
            BackgroundColor3 = T.Stroke,
            Parent = head,
        }, { Corner(11) })
        local knob = New("Frame", {
            AnchorPoint = Vector2.new(0, 0.5),
            Position = UDim2.new(0, 2, 0.5, 0),
            Size = UDim2.fromOffset(18, 18),
            BackgroundColor3 = Color3.new(1, 1, 1),
            Parent = track,
        }, { Corner(9) })

        local api = { Value = value }
        local function render(instant)
            local pos = value and UDim2.new(1, -20, 0.5, 0) or UDim2.new(0, 2, 0.5, 0)
            local col = value and T.Good or T.Stroke
            if instant then
                knob.Position = pos
                track.BackgroundColor3 = col
            else
                Tween(knob, 0.15, { Position = pos })
                Tween(track, 0.15, { BackgroundColor3 = col })
            end
        end

        function api:Set(v, silent)
            value = v == true
            api.Value = value
            if o.Flag then Library.Flags[o.Flag] = value end
            render(silent)
            if not silent then task.spawn(Safe, o.Callback, value) end
        end
        function api:Get() return value end

        f.MouseButton1Click:Connect(function() api:Set(not value) end)
        if o.Flag then Library.Flags[o.Flag] = value end
        render(true)
        return api
    end

    ------------------------------------------------------------ Slider
    function obj:Slider(o)
        o = o or {}
        local vmin, vmax = o.Min or 0, o.Max or 100
        local step = o.Step or 1
        local value = math.clamp(o.Default or vmin, vmin, vmax)

        local f, head = Base(o.Title or "Slider", o.Desc, false, 60)
        local valLbl = New("TextLabel", {
            AnchorPoint = Vector2.new(1, 0),
            Position = UDim2.new(1, 0, 0, 0),
            Size = UDim2.fromOffset(56, 20),
            BackgroundTransparency = 1,
            Text = tostring(value),
            Font = Enum.Font.GothamMedium,
            TextSize = 14,
            TextColor3 = T.SubText,
            TextXAlignment = Enum.TextXAlignment.Right,
            Parent = head,
        })

        local holder = New("Frame", {
            Size = UDim2.new(1, 0, 0, 16),
            BackgroundTransparency = 1,
            Parent = f,
        })
        local track = New("Frame", {
            AnchorPoint = Vector2.new(0, 0.5),
            Position = UDim2.new(0, 0, 0.5, 0),
            Size = UDim2.new(1, 0, 0, 6),
            BackgroundColor3 = T.Stroke,
            BorderSizePixel = 0,
            Parent = holder,
        }, { Corner(3) })
        local fill = New("Frame", {
            Size = UDim2.new(0, 0, 1, 0),
            BackgroundColor3 = T.Accent,
            BorderSizePixel = 0,
            Parent = track,
        }, { Corner(3) })
        local thumb = New("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(1, 0, 0.5, 0),
            Size = UDim2.fromOffset(14, 14),
            BackgroundColor3 = Color3.new(1, 1, 1),
            Parent = fill,
        }, { Corner(7) })

        local api = { Value = value }
        local function render()
            local a = (value - vmin) / math.max(vmax - vmin, 1e-9)
            fill.Size = UDim2.new(a, 0, 1, 0)
            valLbl.Text = tostring(value)
        end

        function api:Set(v, silent)
            v = math.clamp(tonumber(v) or vmin, vmin, vmax)
            v = math.floor((v - vmin) / step + 0.5) * step + vmin
            v = tonumber(string.format("%.3f", v))
            if v == value and not silent then return end
            value = v
            api.Value = v
            if o.Flag then Library.Flags[o.Flag] = v end
            render()
            if not silent then task.spawn(Safe, o.Callback, v) end
        end
        function api:Get() return value end

        local dragging = false
        local function fromInput(input)
            local a = math.clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
            api:Set(vmin + a * (vmax - vmin))
        end
        holder.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                if window.Scroll then window.Scroll(false) end
                fromInput(input)
            end
        end)
        UIS.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
                or input.UserInputType == Enum.UserInputType.Touch) then
                fromInput(input)
            end
        end)
        UIS.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch then
                dragging = false
            end
        end)

        if o.Flag then Library.Flags[o.Flag] = value end
        render()
        return api
    end

    ------------------------------------------------------------ Input
    function obj:Input(o)
        o = o or {}
        local f, head = Base(o.Title or "Input", o.Desc, false, 160)
        local box = New("TextBox", {
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, 0, 0.5, 0),
            Size = UDim2.fromOffset(150, 28),
            BackgroundColor3 = T.Panel,
            Text = o.Default or "",
            PlaceholderText = o.Placeholder or "Escribe...",
            PlaceholderColor3 = T.SubText,
            TextColor3 = T.Text,
            Font = Enum.Font.Gotham,
            TextSize = 14,
            ClearTextOnFocus = false,
            ClipsDescendants = true,
            Parent = head,
        }, { Corner(8), Stroke(T.Stroke, 0.5), Padding(0, 8) })

        local api = { Value = box.Text }
        function api:Set(v, silent)
            box.Text = tostring(v)
            api.Value = box.Text
            if o.Flag then Library.Flags[o.Flag] = box.Text end
            if not silent then task.spawn(Safe, o.Callback, box.Text) end
        end
        function api:Get() return box.Text end

        box.FocusLost:Connect(function()
            api.Value = box.Text
            if o.Flag then Library.Flags[o.Flag] = box.Text end
            task.spawn(Safe, o.Callback, box.Text)
        end)
        return api
    end

    ------------------------------------------------------------ Dropdown
    function obj:Dropdown(o)
        o = o or {}
        local values = o.Values or {}
        local selected = o.Default
        local open = false

        local f, head = Base(o.Title or "Dropdown", o.Desc, false, 150)
        local shown = New("TextLabel", {
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, 0, 0.5, 0),
            Size = UDim2.fromOffset(140, 28),
            BackgroundColor3 = T.Panel,
            Text = "",
            Parent = head,
        }, { Corner(8), Stroke(T.Stroke, 0.5) })
        local shownText = New("TextLabel", {
            Size = UDim2.new(1, -26, 1, 0),
            Position = UDim2.new(0, 8, 0, 0),
            BackgroundTransparency = 1,
            Text = "--",
            Font = Enum.Font.Gotham,
            TextSize = 14,
            TextColor3 = T.Text,
            TextTruncate = Enum.TextTruncate.AtEnd,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = shown,
        })
        local chev = New("TextLabel", {
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, -6, 0.5, 0),
            Size = UDim2.fromOffset(14, 14),
            BackgroundTransparency = 1,
            Text = "▾",
            TextSize = 14,
            Font = Enum.Font.GothamBold,
            TextColor3 = T.SubText,
            Parent = shown,
        })
        local clickArea = New("TextButton", {
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Text = "",
            ZIndex = 5,
            Parent = head,
        })

        local listHolder = New("Frame", {
            Size = UDim2.new(1, 0, 0, 0),
            BackgroundTransparency = 1,
            ClipsDescendants = true,
            Parent = f,
        })
        local list = New("Frame", {
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            Parent = listHolder,
        }, { List(4) })

        local api = { Value = selected }
        local buttons = {}

        local function paint()
            shownText.Text = selected ~= nil and tostring(selected) or "--"
            for val, b in pairs(buttons) do
                local on = val == selected
                Tween(b, 0.12, { BackgroundColor3 = on and T.Accent or T.Panel })
            end
        end

        local function setOpen(v)
            open = v
            Tween(chev, 0.2, { Rotation = v and 180 or 0 })
            local h = v and (#values * 32 + math.max(#values - 1, 0) * 4) or 0
            Tween(listHolder, 0.2, { Size = UDim2.new(1, 0, 0, math.min(h, 160)) })
        end

        local function build()
            for _, b in pairs(buttons) do b:Destroy() end
            buttons = {}
            for _, val in ipairs(values) do
                local b = New("TextButton", {
                    Size = UDim2.new(1, 0, 0, 32),
                    BackgroundColor3 = T.Panel,
                    AutoButtonColor = false,
                    Text = tostring(val),
                    Font = Enum.Font.Gotham,
                    TextSize = 14,
                    TextColor3 = T.Text,
                    Parent = list,
                }, { Corner(8) })
                buttons[val] = b
                b.MouseButton1Click:Connect(function()
                    api:Set(val)
                    setOpen(false)
                end)
            end
            paint()
        end

        function api:Set(v, silent)
            selected = v
            api.Value = v
            if o.Flag then Library.Flags[o.Flag] = v end
            paint()
            if not silent then task.spawn(Safe, o.Callback, v) end
        end
        function api:Get() return selected end
        function api:Refresh(newValues)
            values = newValues or {}
            build()
            if open then setOpen(true) end
        end

        clickArea.MouseButton1Click:Connect(function() setOpen(not open) end)
        build()
        if o.Flag then Library.Flags[o.Flag] = selected end
        return api
    end

    ------------------------------------------------------------ Keybind
    function obj:Keybind(o)
        o = o or {}
        local key = o.Default or Enum.KeyCode.F
        local picking = false
        local f, head = Base(o.Title or "Keybind", o.Desc, false, 90)
        local btn = New("TextButton", {
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, 0, 0.5, 0),
            Size = UDim2.fromOffset(80, 28),
            BackgroundColor3 = T.Panel,
            AutoButtonColor = false,
            Text = key.Name,
            Font = Enum.Font.GothamMedium,
            TextSize = 13,
            TextColor3 = T.Text,
            Parent = head,
        }, { Corner(8), Stroke(T.Stroke, 0.5) })

        local api = { Value = key }
        function api:Set(k)
            key = k
            api.Value = k
            btn.Text = k.Name
        end

        btn.MouseButton1Click:Connect(function()
            picking = true
            btn.Text = "..."
        end)
        UIS.InputBegan:Connect(function(input, gpe)
            if picking and input.UserInputType == Enum.UserInputType.Keyboard then
                picking = false
                api:Set(input.KeyCode)
                task.spawn(Safe, o.Changed, input.KeyCode)
            elseif not gpe and not picking and input.KeyCode == key then
                task.spawn(Safe, o.Callback, key)
            end
        end)
        return api
    end
end

--------------------------------------------------------------------
-- Ventana
--------------------------------------------------------------------
function Library:CreateWindow(cfg)
    cfg = cfg or {}
    local T = Library.Themes[cfg.Theme or "Dark"] or Library.Themes.Dark
    Library.CurrentTheme = T

    local Window = { Tabs = {}, Closed = false, Minimized = false }
    local size = cfg.Size or UDim2.fromOffset(580, 400)
    local sidebarWidth = cfg.SideBarWidth or 160
    local connections = {}

    -- Contenedor principal
    local Main = New("Frame", {
        Name = "Main",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = size,
        BackgroundColor3 = T.Background,
        Active = true,
        Parent = Gui,
    }, { Corner(16), Stroke(T.Stroke, 0.3) })

    local Scale = New("UIScale", { Scale = 1, Parent = Main })

    -- Barra superior
    local Topbar = New("Frame", {
        Size = UDim2.new(1, 0, 0, 46),
        BackgroundTransparency = 1,
        Parent = Main,
    })

    local left = New("Frame", {
        Size = UDim2.new(0, 0, 1, 0),
        AutomaticSize = Enum.AutomaticSize.X,
        BackgroundTransparency = 1,
        Parent = Topbar,
    }, { Padding(0, 14, 0, 0), List(10, Enum.FillDirection.Horizontal, nil, Enum.VerticalAlignment.Center) })

    local winIcon = MakeIcon(cfg.Icon, 22, T.Accent)
    if winIcon then winIcon.Parent = left end

    local titleBox = New("Frame", {
        Size = UDim2.new(0, 0, 1, 0),
        AutomaticSize = Enum.AutomaticSize.X,
        BackgroundTransparency = 1,
        Parent = left,
    }, { List(0, nil, nil, Enum.VerticalAlignment.Center) })
    local titleLbl = New("TextLabel", {
        Size = UDim2.new(0, 0, 0, 18),
        AutomaticSize = Enum.AutomaticSize.X,
        BackgroundTransparency = 1,
        Text = cfg.Title or "NovaUI",
        Font = Enum.Font.GothamBold,
        TextSize = 16,
        TextColor3 = T.Text,
        Parent = titleBox,
    })
    if cfg.Author then
        New("TextLabel", {
            Size = UDim2.new(0, 0, 0, 14),
            AutomaticSize = Enum.AutomaticSize.X,
            BackgroundTransparency = 1,
            Text = cfg.Author,
            Font = Enum.Font.Gotham,
            TextSize = 12,
            TextColor3 = T.SubText,
            Parent = titleBox,
        })
    end

    local right = New("Frame", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -10, 0.5, 0),
        Size = UDim2.new(0, 0, 0, 30),
        AutomaticSize = Enum.AutomaticSize.X,
        BackgroundTransparency = 1,
        Parent = Topbar,
    }, { List(6, Enum.FillDirection.Horizontal, nil, Enum.VerticalAlignment.Center) })

    local function TopButton(text, order, onClick)
        local b = New("TextButton", {
            Size = UDim2.fromOffset(30, 30),
            BackgroundColor3 = T.Element,
            BackgroundTransparency = 0.4,
            AutoButtonColor = false,
            Text = text,
            Font = Enum.Font.GothamBold,
            TextSize = 16,
            TextColor3 = T.Text,
            LayoutOrder = order,
            Parent = right,
        }, { Corner(8) })
        b.MouseEnter:Connect(function() Tween(b, 0.1, { BackgroundTransparency = 0 }) end)
        b.MouseLeave:Connect(function() Tween(b, 0.1, { BackgroundTransparency = 0.4 }) end)
        b.MouseButton1Click:Connect(onClick)
        return b
    end

    -- Cuerpo
    local Body = New("Frame", {
        Position = UDim2.new(0, 0, 0, 46),
        Size = UDim2.new(1, 0, 1, -46),
        BackgroundTransparency = 1,
        Parent = Main,
    })

    local Sidebar = New("ScrollingFrame", {
        Size = UDim2.new(0, sidebarWidth, 1, 0),
        BackgroundTransparency = 1,
        ScrollBarThickness = 0,
        CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Parent = Body,
    }, { Padding(4, 8, 8, 8), List(4) })

    local Panel = New("Frame", {
        Position = UDim2.new(0, sidebarWidth, 0, 0),
        Size = UDim2.new(1, -sidebarWidth - 8, 1, -8),
        BackgroundColor3 = T.Panel,
        BackgroundTransparency = 0.2,
        ClipsDescendants = true,
        Parent = Body,
    }, { Corner(12) })

    -- Arrastrar ventana
    MakeDraggable(Main, Topbar)

    ----------------------------------------------------------------
    -- Botón flotante (mismo estilo: píldora con borde degradado)
    ----------------------------------------------------------------
    local Open = {}
    local openCfg = cfg.OpenButton or {}
    local gradientColor = openCfg.Color or ColorSequence.new(Color3.fromHex("40c9ff"), Color3.fromHex("e81cff"))

    local OpenFrame = New("Frame", {
        Name = "OpenButton",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = openCfg.Position or UDim2.new(0.5, 0, 0, 36),
        Size = UDim2.new(0, 0, 0, 44),
        AutomaticSize = Enum.AutomaticSize.X,
        BackgroundColor3 = Color3.new(0, 0, 0),
        BackgroundTransparency = 0.25,
        Visible = false,
        ZIndex = 50,
        Parent = Gui,
    }, {
        Corner(22),
        Padding(0, 4, 4, 0),
        List(4, Enum.FillDirection.Horizontal, nil, Enum.VerticalAlignment.Center),
    })

    local openStroke = New("UIStroke", {
        Thickness = openCfg.StrokeThickness or 2,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Color = Color3.new(1, 1, 1),
        Parent = OpenFrame,
    })
    local openGradient = New("UIGradient", { Color = gradientColor, Parent = openStroke })

    -- Zona para arrastrar
    local dragZone = New("Frame", {
        Size = UDim2.fromOffset(36, 36),
        BackgroundTransparency = 1,
        LayoutOrder = 1,
        Parent = OpenFrame,
    }, {
        New("TextLabel", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0.5, 0, 0.5, 0),
            Size = UDim2.fromOffset(18, 18),
            BackgroundTransparency = 1,
            Text = "✥",
            TextSize = 16,
            Font = Enum.Font.GothamBold,
            TextColor3 = T.SubText,
        }),
    })

    New("Frame", {
        Size = UDim2.new(0, 1, 0, 28),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BackgroundTransparency = 0.85,
        BorderSizePixel = 0,
        LayoutOrder = 2,
        Parent = OpenFrame,
    })

    local openBtn = New("TextButton", {
        Size = UDim2.new(0, 0, 0, 36),
        AutomaticSize = Enum.AutomaticSize.X,
        BackgroundColor3 = Color3.new(1, 1, 1),
        BackgroundTransparency = 1,
        AutoButtonColor = false,
        Text = "",
        LayoutOrder = 3,
        Parent = OpenFrame,
    }, {
        Corner(18),
        Padding(0, 12),
        List(8, Enum.FillDirection.Horizontal, nil, Enum.VerticalAlignment.Center),
    })

    local openIcon = MakeIcon(openCfg.Icon or cfg.Icon, 20, T.Text)
    if openIcon then
        openIcon.Parent = openBtn
    end
    New("TextLabel", {
        Size = UDim2.new(0, 0, 1, 0),
        AutomaticSize = Enum.AutomaticSize.X,
        BackgroundTransparency = 1,
        Text = openCfg.Title or cfg.Title or "Abrir",
        Font = Enum.Font.GothamMedium,
        TextSize = 16,
        TextColor3 = T.Text,
        Parent = openBtn,
    })

    openBtn.MouseEnter:Connect(function() Tween(openBtn, 0.1, { BackgroundTransparency = 0.93 }) end)
    openBtn.MouseLeave:Connect(function() Tween(openBtn, 0.1, { BackgroundTransparency = 1 }) end)

    MakeDraggable(OpenFrame, dragZone)

    -- Gira el degradado del borde
    table.insert(connections, RunService.RenderStepped:Connect(function(dt)
        if OpenFrame.Visible then
            openGradient.Rotation = (openGradient.Rotation + dt * 90) % 360
        end
    end))

    ----------------------------------------------------------------
    -- Abrir / cerrar / minimizar
    ----------------------------------------------------------------
    function Window:Open()
        Window.Minimized = false
        OpenFrame.Visible = false
        Main.Visible = true
        Main.Size = UDim2.new(size.X.Scale, size.X.Offset * 0.92, size.Y.Scale, size.Y.Offset * 0.92)
        Tween(Main, 0.3, { Size = size })
    end

    function Window:Minimize()
        Window.Minimized = true
        Tween(Main, 0.2, {
            Size = UDim2.new(size.X.Scale, size.X.Offset * 0.92, size.Y.Scale, size.Y.Offset * 0.92),
        })
        task.delay(0.15, function()
            if Window.Minimized then
                Main.Visible = false
                OpenFrame.Visible = openCfg.Enabled ~= false
            end
        end)
    end

    function Window:Toggle()
        if Main.Visible then Window:Minimize() else Window:Open() end
    end

    function Window:Destroy()
        Window.Closed = true
        for _, c in ipairs(connections) do c:Disconnect() end
        Main:Destroy()
        OpenFrame:Destroy()
    end

    function Window:SetTitle(t) titleLbl.Text = t end
    function Window:SetScale(s) Scale.Scale = math.clamp(s, 0.4, 2) end

    function Window:EditOpenButton(o)
        o = o or {}
        if o.Color then openGradient.Color = o.Color end
        if o.StrokeThickness then openStroke.Thickness = o.StrokeThickness end
        if o.Position then OpenFrame.Position = o.Position end
        if o.Enabled ~= nil then openCfg.Enabled = o.Enabled end
    end

    TopButton("–", 1, function() Window:Minimize() end)
    TopButton("✕", 2, function() Window:Destroy() end)
    openBtn.MouseButton1Click:Connect(function() Window:Open() end)

    if cfg.ToggleKey then
        table.insert(connections, UIS.InputBegan:Connect(function(input, gpe)
            if not gpe and input.KeyCode == cfg.ToggleKey then
                Window:Toggle()
            end
        end))
    end

    ----------------------------------------------------------------
    -- Pestañas
    ----------------------------------------------------------------
    local currentTab

    local function SelectTab(tab)
        if currentTab == tab then return end
        for _, t in ipairs(Window.Tabs) do
            t.Page.Visible = false
            Tween(t.Button, 0.15, { BackgroundTransparency = 1 })
            Tween(t.Label, 0.15, { TextColor3 = T.SubText })
        end
        currentTab = tab
        tab.Page.Visible = true
        Tween(tab.Button, 0.15, { BackgroundTransparency = 0.8 })
        Tween(tab.Label, 0.15, { TextColor3 = T.Text })
    end

    function Window:Tab(o)
        o = o or {}
        local tab = {}

        local btn = New("TextButton", {
            Size = UDim2.new(1, 0, 0, 36),
            BackgroundColor3 = T.Accent,
            BackgroundTransparency = 1,
            AutoButtonColor = false,
            Text = "",
            Parent = Sidebar,
        }, {
            Corner(10),
            Padding(0, 10),
            List(8, Enum.FillDirection.Horizontal, nil, Enum.VerticalAlignment.Center),
        })
        local ic = MakeIcon(o.Icon, 16, T.SubText)
        if ic then ic.Parent = btn end
        local lbl = New("TextLabel", {
            Size = UDim2.new(1, ic and -24 or 0, 1, 0),
            BackgroundTransparency = 1,
            Text = o.Title or "Pestaña",
            Font = Enum.Font.GothamMedium,
            TextSize = 14,
            TextColor3 = T.SubText,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            Parent = btn,
        })

        local page = New("ScrollingFrame", {
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = T.Stroke,
            CanvasSize = UDim2.new(),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            Visible = false,
            Parent = Panel,
        }, { Padding(12), List(6) })

        tab.Button, tab.Label, tab.Page = btn, lbl, page
        tab.Select = function() SelectTab(tab) end

        Window.Scroll = function(enabled) page.ScrollingEnabled = enabled end
        UIS.InputEnded:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
                page.ScrollingEnabled = true
            end
        end)

        AttachElements(tab, page, T, Window)

        btn.MouseEnter:Connect(function()
            if currentTab ~= tab then Tween(btn, 0.1, { BackgroundTransparency = 0.92 }) end
        end)
        btn.MouseLeave:Connect(function()
            if currentTab ~= tab then Tween(btn, 0.1, { BackgroundTransparency = 1 }) end
        end)
        btn.MouseButton1Click:Connect(function() SelectTab(tab) end)

        table.insert(Window.Tabs, tab)
        if #Window.Tabs == 1 then SelectTab(tab) end
        return tab
    end

    function Window:SelectTab(i)
        local t = Window.Tabs[i]
        if t then SelectTab(t) end
    end

    function Window:Notify(o) return Library:Notify(o) end

    -- Animación de entrada
    Main.Size = UDim2.new(size.X.Scale, size.X.Offset * 0.9, size.Y.Scale, size.Y.Offset * 0.9)
    Tween(Main, 0.4, { Size = size }, Enum.EasingStyle.Back)

    table.insert(Library.Windows, Window)
    return Window
end

return Library
