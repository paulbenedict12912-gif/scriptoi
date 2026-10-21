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

-- ─────────────────────────────────────────────────────────────
-- UI SETUP (Wider & Longer)
-- ─────────────────────────────────────────────────────────────
local Window = Library:CreateWindow({
    Title        = 'Menu',
    Center       = true,
    AutoShow     = true,
    TabPadding   = 4, 
    MenuFadeTime = 0.1,
    Size         = UDim2.fromOffset(580, 320) -- Made wider and longer
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

if Library.ScreenGui then
    local uiScale = Instance.new('UIScale')
    uiScale.Scale = 0.75
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

-- Resizer Logic
local UserInputService = game:GetService("UserInputService")
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
        local newWidth = math.clamp(startSize.X.Offset + (delta.X * 2), 300, 1000)
        local newHeight = math.clamp(startSize.Y.Offset + (delta.Y * 2), 200, 1000)
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
