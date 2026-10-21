-- ─────────────────────────────────────────────────────────────
-- FETCH THE OFFICIAL LIBRARY & PATCH FOR MOBILE TOUCH
-- ─────────────────────────────────────────────────────────────
local repo = 'https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/'
local source = game:HttpGet(repo .. 'Library.lua')

-- 1. Inject touch tracking (Global so the library can read it)
local trackingCode = [[
_G.isTouching = false
game:GetService('UserInputService').InputBegan:Connect(function(i) 
    if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then _G.isTouching = true end 
end)
game:GetService('UserInputService').InputEnded:Connect(function(i) 
    if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then _G.isTouching = false end 
end)
]]
source = trackingCode .. "\n" .. source

-- 2. Patch mouse held-down checks to our global tracker
source = source:gsub("InputService:IsMouseButtonPressed%(Enum%.UserInputType%.MouseButton1%)", "_G.isTouching")

-- 3. Patch strict mouse clicks to accept Touch
source = source:gsub("Input%.UserInputType == Enum%.UserInputType%.MouseButton1", "(Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch)")
source = source:gsub("Input%.UserInputType ~= Enum%.UserInputType%.MouseButton1", "(Input.UserInputType ~= Enum.UserInputType.MouseButton1 and Input.UserInputType ~= Enum.UserInputType.Touch)")

-- 4. Patch mouse position for dragging and sliders
source = source:gsub("Mouse%.X", "game:GetService('UserInputService'):GetMouseLocation().X")
source = source:gsub("Mouse%.Y", "game:GetService('UserInputService'):GetMouseLocation().Y")

local Library = loadstring(source)()
local UserInputService = game:GetService('UserInputService')

-- ─────────────────────────────────────────────────────────────
-- UI SETUP (Wider & Longer)
-- ─────────────────────────────────────────────────────────────
local Window = Library:CreateWindow({
    Title        = 'Menu',
    Center       = true,
    AutoShow     = true,
    TabPadding   = 4, 
    MenuFadeTime = 0.1,
    Size         = UDim2.fromOffset(660, 400) -- Wider + longer
})

-- Instantly disable the blue selection outline
local function RemoveBlueOutline(obj)
    if obj:IsA("GuiButton") then
        obj.Selectable = false
    end
end

for _, obj in pairs(Library.ScreenGui:GetDescendants()) do
    RemoveBlueOutline(obj)
end
Library.ScreenGui.DescendantAdded:Connect(RemoveBlueOutline)

-- Global UI scale object (used by the scaler below)
local uiScale = Instance.new('UIScale')
uiScale.Scale = 0.75
uiScale.Parent = Library.ScreenGui

-- ─────────────────────────────────────────────────────────────
-- 🛠️ CUSTOM EXTERNAL TOGGLE BUTTON
-- ─────────────────────────────────────────────────────────────
local ToggleGui = Instance.new("ScreenGui")
ToggleGui.Name = "CustomToggleGui"
ToggleGui.ResetOnSpawn = false
ToggleGui.IgnoreGuiInset = true
ToggleGui.DisplayOrder = 999
local protect = syn and syn.protect_gui or (function(gui) gui.Parent = game:GetService("CoreGui") end)
protect(ToggleGui)

-- Outer Frame (Black border)
local BtnOuter = Instance.new("Frame")
BtnOuter.Name = "ToggleBtnOuter"
BtnOuter.Parent = ToggleGui
BtnOuter.Size = UDim2.fromOffset(56, 20)
BtnOuter.Position = UDim2.new(0, 15, 0.35, 0)
BtnOuter.BackgroundColor3 = Color3.new(0, 0, 0)
BtnOuter.BorderColor3 = Color3.new(0, 0, 0)

-- Inner Frame (Matches UI exact style)
local BtnInner = Instance.new("Frame")
BtnInner.Name = "ToggleBtnInner"
BtnInner.Parent = BtnOuter
BtnInner.Size = UDim2.new(1, 0, 1, 0)
BtnInner.BackgroundColor3 = Library.MainColor
BtnInner.BorderColor3 = Library.OutlineColor
BtnInner.BorderMode = Enum.BorderMode.Inset

-- UI Gradient
local BtnGradient = Instance.new("UIGradient")
BtnGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(212, 212, 212))
})
BtnGradient.Rotation = 90
BtnGradient.Parent = BtnInner

-- Clickable Area
local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Name = "ToggleBtn"
ToggleBtn.Parent = BtnInner
ToggleBtn.Size = UDim2.new(1, 0, 1, 0)
ToggleBtn.BackgroundTransparency = 1
ToggleBtn.TextColor3 = Library.FontColor
ToggleBtn.Font = Library.Font
ToggleBtn.TextSize = 13
ToggleBtn.Text = "Close"
ToggleBtn.AutoButtonColor = false
ToggleBtn.Selectable = false
ToggleBtn.Active = true

-- Button Logic
local isUIVisible = true
ToggleBtn.MouseButton1Click:Connect(function()
    isUIVisible = not isUIVisible
    ToggleBtn.Text = isUIVisible and "Close" or "Toggle"
    Library:Toggle()
end)

-- ─────────────────────────────────────────────────────────────
-- 🎚️ COOL SCALER — sits right under the title bar
-- ─────────────────────────────────────────────────────────────
local MIN_SCALE, MAX_SCALE = 0.5, 1.4
local ACCENT = Library.AccentColor or Color3.fromRGB(0, 200, 120)
local FONT   = Library.FontColor or Color3.fromRGB(240, 240, 240)

-- Push the tab content down so the scaler has its own row
local TabContainer = Library.MainFrame:FindFirstChild('TabContainer')
if TabContainer then
    TabContainer.Position = UDim2.new(0, 3, 0, 56)
    TabContainer.Size     = UDim2.new(1, -6, 1, -60)
end

local ScalerBar = Instance.new('Frame')
ScalerBar.Name = 'ScalerBar'
ScalerBar.Parent = Library.MainFrame
ScalerBar.Position = UDim2.new(0, 3, 0, 30)
ScalerBar.Size = UDim2.new(1, -6, 0, 24)
ScalerBar.BackgroundColor3 = Library.MainColor
ScalerBar.BorderColor3 = Library.OutlineColor
ScalerBar.BorderMode = Enum.BorderMode.Inset
ScalerBar.ZIndex = 2

local barGrad = Instance.new('UIGradient')
barGrad.Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(218, 218, 218))
barGrad.Rotation = 90
barGrad.Parent = ScalerBar

-- "SCALE" tag
local ScaleLabel = Instance.new('TextLabel')
ScaleLabel.Parent = ScalerBar
ScaleLabel.BackgroundTransparency = 1
ScaleLabel.Position = UDim2.new(0, 8, 0, 0)
ScaleLabel.Size = UDim2.new(0, 42, 1, 0)
ScaleLabel.Font = Enum.Font.Code
ScaleLabel.Text = 'SCALE'
ScaleLabel.TextSize = 10
ScaleLabel.TextXAlignment = Enum.TextXAlignment.Left
ScaleLabel.TextColor3 = FONT
ScaleLabel.TextTransparency = 0.35
ScaleLabel.ZIndex = 3

-- Slider track
local Track = Instance.new('Frame')
Track.Parent = ScalerBar
Track.Position = UDim2.new(0, 92, 0, 9)
Track.Size = UDim2.new(1, -144, 0, 6)
Track.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
Track.BorderSizePixel = 0
Track.ZIndex = 2
local trackCorner = Instance.new('UICorner')
trackCorner.CornerRadius = UDim.new(1, 0)
trackCorner.Parent = Track

-- Slider fill (gradient)
local Fill = Instance.new('Frame')
Fill.Parent = Track
Fill.Size = UDim2.new(0.5, 0, 1, 0)
Fill.BackgroundColor3 = Color3.new(1, 1, 1)
Fill.BorderSizePixel = 0
local fillCorner = Instance.new('UICorner')
fillCorner.CornerRadius = UDim.new(1, 0)
fillCorner.Parent = Fill
local fillGrad = Instance.new('UIGradient')
fillGrad.Color = ColorSequence.new(ACCENT, ACCENT:Lerp(Color3.new(1, 1, 1), 0.55))
fillGrad.Rotation = 0
fillGrad.Parent = Fill

-- Soft glow behind the knob
local Glow = Instance.new('Frame')
Glow.Parent = ScalerBar
Glow.Size = UDim2.fromOffset(20, 20)
Glow.BackgroundColor3 = ACCENT
Glow.BackgroundTransparency = 0.78
Glow.BorderSizePixel = 0
Glow.Position = UDim2.new(0.5, -10, 0, 2)
Glow.ZIndex = 3
local glowCorner = Instance.new('UICorner')
glowCorner.CornerRadius = UDim.new(1, 0)
glowCorner.Parent = Glow

-- Knob
local Knob = Instance.new('Frame')
Knob.Parent = ScalerBar
Knob.Size = UDim2.fromOffset(12, 12)
Knob.Position = UDim2.new(0.5, -6, 0, 6)
Knob.BackgroundColor3 = Color3.new(1, 1, 1)
Knob.BorderSizePixel = 0
Knob.ZIndex = 4
local knobCorner = Instance.new('UICorner')
knobCorner.CornerRadius = UDim.new(1, 0)
knobCorner.Parent = Knob
local knobStroke = Instance.new('UIStroke')
knobStroke.Color = ACCENT
knobStroke.Thickness = 1.5
knobStroke.Parent = Knob

-- Percentage readout (click it to reset to 100%)
local PercentBtn = Instance.new('TextButton')
PercentBtn.Parent = ScalerBar
PercentBtn.Position = UDim2.new(1, -48, 0, 0)
PercentBtn.Size = UDim2.new(0, 44, 1, 0)
PercentBtn.BackgroundTransparency = 1
PercentBtn.Font = Enum.Font.Code
PercentBtn.TextSize = 11
PercentBtn.Text = '75%'
PercentBtn.TextXAlignment = Enum.TextXAlignment.Right
PercentBtn.TextColor3 = FONT
PercentBtn.AutoButtonColor = false
PercentBtn.Selectable = false
PercentBtn.ZIndex = 4

-- Invisible, taller hit area so it's easy to grab on mobile
local HitArea = Instance.new('Frame')
HitArea.Parent = ScalerBar
HitArea.Position = UDim2.new(0, 92, 0, 2)
HitArea.Size = UDim2.new(1, -144, 0, 20)
HitArea.BackgroundTransparency = 1
HitArea.ZIndex = 5
HitArea.Active = true

-- ── SetScale ────────────────────────────────────────────────
local function SetScale(value)
    value = math.clamp(value, MIN_SCALE, MAX_SCALE)
    uiScale.Scale = value

    local alpha = (value - MIN_SCALE) / (MAX_SCALE - MIN_SCALE)
    Fill.Size     = UDim2.new(alpha, 0, 1, 0)
    Glow.Position = UDim2.new(alpha, -10, 0, 2)
    Knob.Position = UDim2.new(alpha, -6, 0, 6)
    PercentBtn.Text = tostring(math.floor(value * 100 + 0.5)) .. '%'
end

-- ── − / + step buttons ──────────────────────────────────────
local function MakeStepButton(text, xOffset, delta)
    local btn = Instance.new('TextButton')
    btn.Parent = ScalerBar
    btn.Position = UDim2.new(0, xOffset, 0, 4)
    btn.Size = UDim2.fromOffset(16, 16)
    btn.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
    btn.BackgroundTransparency = 0.25
    btn.BorderSizePixel = 0
    btn.Text = text
    btn.Font = Enum.Font.Code
    btn.TextSize = 14
    btn.TextColor3 = FONT
    btn.AutoButtonColor = false
    btn.Selectable = false
    btn.Active = true
    btn.ZIndex = 4

    local c = Instance.new('UICorner')
    c.CornerRadius = UDim.new(0, 4)
    c.Parent = btn

    local s = Instance.new('UIStroke')
    s.Color = Library.OutlineColor
    s.Thickness = 1
    s.Parent = btn

    btn.MouseEnter:Connect(function()
        btn.BackgroundTransparency = 0
        btn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
    end)
    btn.MouseLeave:Connect(function()
        btn.BackgroundTransparency = 0.25
        btn.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
    end)
    btn.MouseButton1Click:Connect(function()
        SetScale(uiScale.Scale + delta)
    end)
    return btn
end

MakeStepButton('-', 50, -0.05)
MakeStepButton('+', 68,  0.05)

PercentBtn.MouseButton1Click:Connect(function()
    SetScale(1)
end)

-- ── Drag logic ──────────────────────────────────────────────
local draggingScaler = false
local dragStartX, dragStartScale, dragTrackWidth = 0, 1, 1

local function GetPointerX(input)
    if input and input.UserInputType == Enum.UserInputType.Touch then
        return input.Position.X
    end
    return UserInputService:GetMouseLocation().X
end

HitArea.InputBegan:Connect(function(input)
    if input.UserInputType ~= Enum.UserInputType.MouseButton1
    and input.UserInputType ~= Enum.UserInputType.Touch then return end

    dragTrackWidth = math.max(Track.AbsoluteSize.X, 1)
    dragStartX = GetPointerX(input)

    -- jump straight to the clicked position
    local relX = math.clamp((dragStartX - Track.AbsolutePosition.X) / dragTrackWidth, 0, 1)
    SetScale(MIN_SCALE + relX * (MAX_SCALE - MIN_SCALE))

    dragStartScale = uiScale.Scale
    draggingScaler = true
end)

UserInputService.InputChanged:Connect(function(input)
    if not draggingScaler then return end
    if input.UserInputType == Enum.UserInputType.MouseMovement
    or input.UserInputType == Enum.UserInputType.Touch then
        local delta = GetPointerX(input) - dragStartX
        SetScale(dragStartScale + (delta / dragTrackWidth) * (MAX_SCALE - MIN_SCALE))
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        draggingScaler = false
    end
end)

-- Initial value
SetScale(0.75)

-- ─────────────────────────────────────────────────────────────
-- 🛠️ COOL RESIZER (Bottom Right)
-- ─────────────────────────────────────────────────────────────
local Resizer = Instance.new("TextButton")
Resizer.Name = "WindowResizer"
Resizer.Parent = Library.MainFrame
Resizer.AnchorPoint = Vector2.new(1, 1)
Resizer.Position = UDim2.new(1, -3, 1, -3)
Resizer.Size = UDim2.fromOffset(16, 16)
Resizer.BackgroundTransparency = 1
Resizer.Text = "◢"
Resizer.TextColor3 = Library.OutlineColor
Resizer.TextSize = 14
Resizer.Font = Enum.Font.Code
Resizer.Selectable = false
Resizer.Active = true
Resizer.ZIndex = 10

local resizing = false
local startSize
local startPos

Resizer.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        resizing = true
        startSize = Library.MainFrame.Size
        startPos = input.Position
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if resizing and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - startPos
        local scale = math.max(uiScale.Scale, 0.1)
        local newWidth  = math.clamp(startSize.X.Offset + (delta.X / scale), 420, 1100)
        local newHeight = math.clamp(startSize.Y.Offset + (delta.Y / scale), 280, 1000)
        Library.MainFrame.Size = UDim2.fromOffset(newWidth, newHeight)
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        resizing = false
    end
end)

-- ─────────────────────────────────────────────────────────────
-- BUILD YOUR MENU
-- ─────────────────────────────────────────────────────────────
local Tabs = {
    Main     = Window:AddTab('Main'),
    Settings = Window:AddTab('Settings'),
}

local LeftGroup  = Tabs.Main:AddLeftGroupbox('Features')
local RightGroup = Tabs.Main:AddRightGroupbox('Values')

-- LEFT SIDE
LeftGroup:AddToggle('MyToggle', {
    Text    = 'Enable feature',
    Default = true,
})

LeftGroup:AddButton({
    Text = 'Click me',
    Func = function() Library:Notify('Button clicked!') end,
}):AddButton({
    Text = 'Sub button',
    Func = function() Library:Notify('Sub clicked!') end,
})

LeftGroup:AddLabel('Keybind'):AddKeyPicker('MyKey', {
    Default = 'MB2',
    Mode    = 'Toggle',
    Text    = 'Example keybind'
})

-- RIGHT SIDE
RightGroup:AddSlider('MySlider', {
    Text = 'Slider value',
    Default = 50, Min = 0, Max = 100, Rounding = 0,
})

RightGroup:AddDropdown('MyDropdown', {
    Values  = {'Option A', 'Option B', 'Option C'},
    Default = 1,
    Text    = 'Choose option',
})

RightGroup:AddInput('MyInput', {
    Default     = '',
    Text        = 'Textbox',
    Placeholder = 'Type here...',
})

RightGroup:AddLabel('Color'):AddColorPicker('MyColor', {
    Default = Color3.fromRGB(0, 200, 120),
    Title   = 'Pick a color'
})

-- SETTINGS TAB
local MenuGroup = Tabs.Settings:AddLeftGroupbox('Menu')
MenuGroup:AddButton('Unload', function() 
    ToggleGui:Destroy()
    Library:Unload() 
end)

MenuGroup:AddLabel('Menu bind'):AddKeyPicker('MenuKeybind', {
    Default = 'End', NoUI = true, Text = 'Menu keybind'
})
Library.ToggleKeybind = Options.MenuKeybind
