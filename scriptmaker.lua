-- FULLY FIXED MOBILE SCRIPT (Compact & Touch Enabled)
local repo = 'https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/'

local Library      = loadstring(game:HttpGet(repo .. 'Library.lua'))()
local ThemeManager = loadstring(game:HttpGet(repo .. 'addons/ThemeManager.lua'))()
local SaveManager  = loadstring(game:HttpGet(repo .. 'addons/SaveManager.lua'))()

local UserInputService = game:GetService('UserInputService')

-- Create Window (Forcing a very small size)
local Window = Library:CreateWindow({
    Title        = 'Menu',
    Center       = true,
    AutoShow     = true,
    TabPadding   = 4, 
    MenuFadeTime = 0.1,
    Size         = UDim2.fromOffset(460, 280) -- Forces a smaller base size
})

-- ─────────────────────────────────────────────────────────────
-- 🛠️ MOBILE TOUCH FIX (Crucial for Buttons & Color Pickers)
-- ─────────────────────────────────────────────────────────────
if UserInputService.TouchEnabled then
    task.spawn(function()
        task.wait(0.2) -- Wait for UI to load
        if Library.MainFrame then
            -- 1. Force UI to scale down to 75% so it fits better
            local uiScale = Instance.new('UIScale')
            uiScale.Scale = 0.75
            uiScale.Parent = Library.MainFrame
            
            -- 2. Fix Touches: The main frame swallows your taps! 
            -- We disable it, but keep the top title bar active so you can still drag it.
            Library.MainFrame.Active = false
            Library.TitleBar.Active = true
            
            -- 3. Fix Color Picker & Dropdowns: Force all buttons to be Active
            for _, obj in pairs(Library.ScreenGui:GetDescendants()) do
                if obj:IsA("TextButton") or obj:IsA("ImageButton") then
                    obj.Active = true
                end
            end
        end
    end)
end

local Tabs = {
    Main     = Window:AddTab('Main'),
    Settings = Window:AddTab('Settings'),
}

-- Split into Left and Right to keep it short (No long scrolling)
local LeftGroup  = Tabs.Main:AddLeftGroupbox('Features')
local RightGroup = Tabs.Main:AddRightGroupbox('Values')

-- === LEFT SIDE ===
LeftGroup:AddToggle('MyToggle', {
    Text    = 'Enable feature',
    Default = true,
})

LeftGroup:AddButton({
    Text = 'Click me',
    Func = function() print('Button clicked!') end,
}):AddButton({
    Text = 'Sub button',
    Func = function() print('Sub clicked!') end,
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

-- Managers
ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ 'MenuKeybind' })
SaveManager:BuildConfigSection(Tabs.Settings)
ThemeManager:ApplyToTab(Tabs.Settings)
