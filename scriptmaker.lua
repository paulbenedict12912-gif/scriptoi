-- ─────────────────────────────────────────────────────────────
-- FETCH THE OFFICIAL (AND FULLY FORMATTED) LIBRARY
-- ─────────────────────────────────────────────────────────────
local repo = 'https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/'
local source = game:HttpGet(repo .. 'Library.lua')

-- ─────────────────────────────────────────────────────────────
-- 🛠️ MOBILE TOUCH PATCHES
-- ─────────────────────────────────────────────────────────────
-- 1. Inject touch tracking so sliders and pickers know when your finger is down
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

-- 2. Replace mouse held-down checks with our touch tracker
source = source:gsub("InputService:IsMouseButtonPressed%(Enum%.UserInputType%.MouseButton1%)", "isTouching")

-- 3. Replace strict mouse clicks with Touch OR Mouse
source = source:gsub("Input%.UserInputType == Enum%.UserInputType%.MouseButton1", "(Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch)")
source = source:gsub("Input%.UserInputType ~= Enum%.UserInputType%.MouseButton1", "(Input.UserInputType ~= Enum.UserInputType.MouseButton1 and Input.UserInputType ~= Enum.UserInputType.Touch)")

-- 4. Fix dragging and hovering by updating Mouse coordinates to track your finger
source = source:gsub("Mouse%.X", "game:GetService('UserInputService'):GetMouseLocation().X")
source = source:gsub("Mouse%.Y", "game:GetService('UserInputService'):GetMouseLocation().Y")

-- Load the patched library
local Library = loadstring(source)()

-- ─────────────────────────────────────────────────────────────
-- 🛠️ UI SETUP (Compact Size & No Blue Outline)
-- ─────────────────────────────────────────────────────────────
local Window = Library:CreateWindow({
    Title        = 'Menu',
    Center       = true,
    AutoShow     = true,
    TabPadding   = 4, 
    MenuFadeTime = 0.1,
    Size         = UDim2.fromOffset(420, 260) -- Forces a smaller UI
})

-- Wait for UI to build, then shrink it and remove the selection outlines
task.spawn(function()
    task.wait(0.5)
    if Library.ScreenGui then
        Library.ScreenGui.IgnoreGuiInset = true
        
        -- Make the whole UI 75% smaller
        local uiScale = Instance.new('UIScale')
        uiScale.Scale = 0.75
        uiScale.Parent = Library.ScreenGui

        -- Remove the blue selection outline so taps press instantly
        for _, obj in pairs(Library.ScreenGui:GetDescendants()) do
            if obj:IsA("GuiButton") then
                obj.Selectable = false 
            end
        end
    end
end)

-- ─────────────────────────────────────────────────────────────
-- BUILD YOUR MENU
-- ─────────────────────────────────────────────────────────────
local Tabs = {
    Main     = Window:AddTab('Main'),
    Settings = Window:AddTab('Settings'),
}

-- Split into Left and Right to keep it short
local LeftGroup  = Tabs.Main:AddLeftGroupbox('Features')
local RightGroup = Tabs.Main:AddRightGroupbox('Values')

-- === LEFT SIDE ===
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

-- === RIGHT SIDE ===
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

-- === SETTINGS TAB ===
local MenuGroup = Tabs.Settings:AddLeftGroupbox('Menu')
MenuGroup:AddButton('Unload', function() Library:Unload() end)
MenuGroup:AddLabel('Menu bind'):AddKeyPicker('MenuKeybind', {
    Default = 'End', NoUI = true, Text = 'Menu keybind'
})
Library.ToggleKeybind = Options.MenuKeybind
