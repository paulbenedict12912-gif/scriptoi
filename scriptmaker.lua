-- ─────────────────────────────────────────────────────────────
-- FETCH THE OFFICIAL LIBRARY & PATCH FOR MOBILE TOUCH
-- ─────────────────────────────────────────────────────────────
local repo = 'https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/'
local source = game:HttpGet(repo .. 'Library.lua')

-- 1. Inject touch tracking
local trackingCode = [[
local isTouching = false
game:GetService('UserInputService').InputBegan:Connect(function(i) 
    if i.UserInputType == Enum.UserInputType.Touch then isTouching = true end 
end)
game:GetService('UserInputService').InputEnded:Connect(function(i) 
    if i.UserInputType == Enum.UserInputType.Touch then isTouching = false end 
end)
]]
source = trackingCode .. "\n" .. source

-- 2. Patch mouse checks to accept Touch
source = source:gsub("InputService:IsMouseButtonPressed%(Enum%.UserInputType%.MouseButton1%)", "isTouching")
source = source:gsub("Input%.UserInputType == Enum%.UserInputType%.MouseButton1", "(Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch)")
source = source:gsub("Input%.UserInputType ~= Enum%.UserInputType%.MouseButton1", "(Input.UserInputType ~= Enum.UserInputType.MouseButton1 and Input.UserInputType ~= Enum.UserInputType.Touch)")

-- 3. Patch mouse position for dragging and sliders
source = source:gsub("Mouse%.X", "game:GetService('UserInputService'):GetMouseLocation().X")
source = source:gsub("Mouse%.Y", "game:GetService('UserInputService'):GetMouseLocation().Y")

local Library = loadstring(source)()

-- ─────────────────────────────────────────────────────────────
-- UI SETUP (Wider Size & No Blue Outline)
-- ─────────────────────────────────────────────────────────────
local Window = Library:CreateWindow({
    Title        = 'Menu',
    Center       = true,
    AutoShow     = true,
    TabPadding   = 4, 
    MenuFadeTime = 0.1,
    Size         = UDim2.fromOffset(500, 280) -- Made wider (was 420)
})

-- Shrink the UI and remove the blue selection outline
task.spawn(function()
    task.wait(0.5)
    if Library.ScreenGui then
        Library.ScreenGui.IgnoreGuiInset = true
        
        local uiScale = Instance.new('UIScale')
        uiScale.Scale = 0.75
        uiScale.Parent = Library.ScreenGui

        for _, obj in pairs(Library.ScreenGui:GetDescendants()) do
            if obj:IsA("GuiButton") then
                obj.Selectable = false 
            end
        end
    end
end)

-- ─────────────────────────────────────────────────────────────
-- 🛠️ CUSTOM EXTERNAL TOGGLE BUTTON
-- ─────────────────────────────────────────────────────────────
local ToggleGui = Instance.new("ScreenGui")
ToggleGui.Name = "CustomToggleGui"
ToggleGui.ResetOnSpawn = false
ToggleGui.IgnoreGuiInset = true
ToggleGui.DisplayOrder = 100 -- Keeps it above the game
ToggleGui.Parent = game:GetService("CoreGui")

local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Name = "ToggleBtn"
ToggleBtn.Parent = ToggleGui
ToggleBtn.Size = UDim2.fromOffset(80, 30)
ToggleBtn.Position = UDim2.new(0, 15, 0.35, 0) -- Left side, slightly middle-up
ToggleBtn.BackgroundColor3 = Library.MainColor
ToggleBtn.TextColor3 = Library.FontColor
ToggleBtn.Font = Library.Font
ToggleBtn.TextSize = 15
ToggleBtn.Text = "Close" -- Starts as Close because AutoShow = true
ToggleBtn.AutoButtonColor = false
ToggleBtn.Selectable = false
ToggleBtn.Active = true

-- Add the matching outline from the UI
local UIStroke = Instance.new("UIStroke")
UIStroke.Color = Library.OutlineColor
UIStroke.Thickness = 1
UIStroke.Parent = ToggleBtn

-- Handle clicking/tapping the button
local isUIVisible = true

ToggleBtn.MouseButton1Click:Connect(function()
    isUIVisible = not isUIVisible
    
    if isUIVisible then
        ToggleBtn.Text = "Close"
    else
        ToggleBtn.Text = "Toggle"
    end
    
    Library:Toggle() -- Calls the library's show/hide function
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
    ToggleGui:Destroy() -- Also destroy the toggle button
    Library:Unload() 
end)

MenuGroup:AddLabel('Menu bind'):AddKeyPicker('MenuKeybind', {
    Default = 'End', NoUI = true, Text = 'Menu keybind'
})
Library.ToggleKeybind = Options.MenuKeybind
