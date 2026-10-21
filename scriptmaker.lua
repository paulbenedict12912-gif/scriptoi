-- ─────────────────────────────────────────────────────────────
-- FETCH THE OFFICIAL LIBRARY & PATCH FOR MOBILE TOUCH
-- ─────────────────────────────────────────────────────────────
local repo = 'https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/'
local source = game:HttpGet(repo .. 'Library.lua')

-- 1. Inject touch tracking (global so the library can read it)
--    _G.lastInputPos updates on BOTH mouse and touch, so sliders/drag work everywhere
local trackingCode = [[
_G.isTouching = false
_G.lastInputPos = Vector2.new(0, 0)
local __UIS = game:GetService('UserInputService')
__UIS.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then
        _G.isTouching = true
        _G.lastInputPos = i.Position
    end
end)
__UIS.InputChanged:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseMovement then
        _G.lastInputPos = i.Position
    end
end)
__UIS.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then
        _G.isTouching = false
    end
end)
]]
source = trackingCode .. "\n" .. source

-- 2. Patch "IsMouseButtonPressed(MouseButton1)" loops → our global touch tracker.
--    Pattern requires a word prefix so it never mangles "UserInputService:..." calls.
source = source:gsub("[%w_]+:IsMouseButtonPressed%(Enum%.UserInputType%.MouseButton1%)", "_G.isTouching")

-- 3. Patch MouseButton1 equality checks to accept Touch
source = source:gsub("Input%.UserInputType%s*==%s*Enum%.UserInputType%.MouseButton1",
    "(Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch)")
source = source:gsub("Input%.UserInputType%s*~=%s*Enum%.UserInputType%.MouseButton1",
    "(Input.UserInputType ~= Enum.UserInputType.MouseButton1 and Input.UserInputType ~= Enum.UserInputType.Touch)")

-- 4. ⭐ CRITICAL: Patch MouseMovement → Touch.
--    Without this, drag on title bar & slider drag don't fire on mobile (drags send "Touch").
source = source:gsub("Input%.UserInputType%s*==%s*Enum%.UserInputType%.MouseMovement",
    "(Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch)")
source = source:gsub("Input%.UserInputType%s*~=%s*Enum%.UserInputType%.MouseMovement",
    "(Input.UserInputType ~= Enum.UserInputType.MouseMovement and Input.UserInputType ~= Enum.UserInputType.Touch)")

-- 5. Replace Mouse.X/Mouse.Y with the live input position (works for mouse AND touch)
source = source:gsub("Mouse%.X", "_G.lastInputPos.X")
source = source:gsub("Mouse%.Y", "_G.lastInputPos.Y")

local Library = loadstring(source)()

-- ─────────────────────────────────────────────────────────────
-- UI SETUP (Wider & Longer)
-- ─────────────────────────────────────────────────────────────
local Window = Library:CreateWindow({
    Title        = 'Menu',
    Center       = true,
    AutoShow     = true,
    TabPadding   = 4,
    MenuFadeTime = 0.1,
    Size         = UDim2.fromOffset(640, 370) -- bigger than before
})

-- Instantly disable blue selection outline
local function RemoveBlueOutline(obj)
    if obj:IsA("GuiButton") then obj.Selectable = false end
end
for _, obj in pairs(Library.ScreenGui:GetDescendants()) do RemoveBlueOutline(obj) end
Library.ScreenGui.DescendantAdded:Connect(RemoveBlueOutline)

if Library.ScreenGui then
    local uiScale = Instance.new('UIScale')
    uiScale.Scale = 0.78
    uiScale.Parent = Library.ScreenGui
end

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

local BtnOuter = Instance.new("Frame")
BtnOuter.Name = "ToggleBtnOuter"
BtnOuter.Parent = ToggleGui
BtnOuter.Size = UDim2.fromOffset(64, 22)      -- slightly bigger tap target
BtnOuter.Position = UDim2.new(0, 15, 0.35, 0)
BtnOuter.BackgroundColor3 = Color3.new(0, 0, 0)
BtnOuter.BorderColor3 = Color3.new(0, 0, 0)

local BtnInner = Instance.new("Frame")
BtnInner.Name = "ToggleBtnInner"
BtnInner.Parent = BtnOuter
BtnInner.Size = UDim2.new(1, 0, 1, 0)
BtnInner.BackgroundColor3 = Library.MainColor
BtnInner.BorderColor3 = Library.OutlineColor
BtnInner.BorderMode = Enum.BorderMode.Inset

local BtnGradient = Instance.new("UIGradient")
BtnGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(212, 212, 212))
})
BtnGradient.Rotation = 90
BtnGradient.Parent = BtnInner

local ToggleBtn = Instance.new("TextButton")
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

local isUIVisible = true
ToggleBtn.MouseButton1Click:Connect(function()
    isUIVisible = not isUIVisible
    ToggleBtn.Text = isUIVisible and "Close" or "Toggle"
    Library:Toggle()
end)

-- ─────────────────────────────────────────────────────────────
-- 🛠️ COOL RESIZER (Bottom Right) — works on touch now
-- ─────────────────────────────────────────────────────────────
local Resizer = Instance.new("TextButton")
Resizer.Name = "WindowResizer"
Resizer.Parent = Library.MainFrame
Resizer.AnchorPoint = Vector2.new(1, 1)
Resizer.Position = UDim2.new(1, -3, 1, -3)
Resizer.Size = UDim2.fromOffset(22, 22)       -- bigger touch target
Resizer.BackgroundTransparency = 1
Resizer.Text = "◢"
Resizer.TextColor3 = Library.OutlineColor
Resizer.TextSize = 16
Resizer.Font = Enum.Font.Code
Resizer.Selectable = false
Resizer.Active = true

local UserInputService = game:GetService("UserInputService")
local resizing = false
local startSize, startPos

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
        local newWidth  = math.clamp(startSize.X.Offset + delta.X, 300, 1100)
        local newHeight = math.clamp(startSize.Y.Offset + delta.Y, 200, 1000)
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

local MenuGroup = Tabs.Settings:AddLeftGroupbox('Menu')
MenuGroup:AddButton('Unload', function()
    ToggleGui:Destroy()
    Library:Unload()
end)

MenuGroup:AddLabel('Menu bind'):AddKeyPicker('MenuKeybind', {
    Default = 'End', NoUI = true, Text = 'Menu keybind'
})
Library.ToggleKeybind = Options.MenuKeybind
