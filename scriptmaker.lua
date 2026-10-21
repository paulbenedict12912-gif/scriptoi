-- Compact & Mobile-Optimized LinoriaLib
local repo = 'https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/'

local Library      = loadstring(game:HttpGet(repo .. 'Library.lua'))()
local ThemeManager = loadstring(game:HttpGet(repo .. 'addons/ThemeManager.lua'))()
local SaveManager  = loadstring(game:HttpGet(repo .. 'addons/SaveManager.lua'))()

local UserInputService = game:GetService('UserInputService')
local isMobile = UserInputService.TouchEnabled

-- 1. Make the base window smaller
local Window = Library:CreateWindow({
    Title        = 'Menu',
    Center       = true,
    AutoShow     = true,
    TabPadding   = 4, 
    MenuFadeTime = 0.1,
    Size         = UDim2.fromOffset(480, 320) -- Smaller, compact base size
})

-- 2. Fix Touch & Clicking issues: Apply a UI Scale so it fits
if isMobile and Library.MainFrame then
    -- Scale down the whole menu to 75% so it doesn't take up the whole screen
    local scale = Instance.new('UIScale')
    scale.Scale = 0.75
    scale.Parent = Library.MainFrame
    
    -- Fix dragging: Only allow dragging from the very top title bar.
    -- This prevents the menu from swallowing your clicks when you try to press buttons.
    Library.TitleBar.Active = true
end

local Tabs = {
    Main     = Window:AddTab('Main'),
    Settings = Window:AddTab('Settings'),
}

-- 3. Split into Left and Right to keep the UI short (no scrolling needed)
local LeftGroup  = Tabs.Main:AddLeftGroupbox('Toggles & Buttons')
local RightGroup = Tabs.Main:AddRightGroupbox('Values & Settings')

-- === LEFT SIDE ===
LeftGroup:AddToggle('MyToggle', {
    Text    = 'Enable feature',
    Default = true,
    Callback = function(v) print('[cb] Toggle:', v) end
})

local Btn = LeftGroup:AddButton({
    Text = 'Click me',
    Func = function() print('Button clicked!') end,
})
Btn:AddButton({
    Text = 'Sub button',
    Func = function() print('Sub clicked!') end,
    DoubleClick = true
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
    Callback = function(v) print('[cb] Slider:', v) end
})

RightGroup:AddDropdown('MyDropdown', {
    Values  = {'Option A', 'Option B', 'Option C'},
    Default = 1,
    Text    = 'Choose option',
    Callback = function(v) print('[cb] Dropdown:', v) end
})

RightGroup:AddInput('MyInput', {
    Default     = '',
    Text        = 'Textbox',
    Placeholder = 'Type here...',
    Callback    = function(v) print('[cb] Input:', v) end
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

-- Managers
ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ 'MenuKeybind' })
SaveManager:BuildConfigSection(Tabs.Settings)
ThemeManager:ApplyToTab(Tabs.Settings)
