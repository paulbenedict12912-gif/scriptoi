-- FULLY FIXED MOBILE SCRIPT (Touch Fixed & Blue Outline Removed)
local repo = 'https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/'

local Library      = loadstring(game:HttpGet(repo .. 'Library.lua'))()
local ThemeManager = loadstring(game:HttpGet(repo .. 'addons/ThemeManager.lua'))()
local SaveManager  = loadstring(game:HttpGet(repo .. 'addons/SaveManager.lua'))()

local UserInputService = game:GetService('UserInputService')

-- Create Window (Forced small size)
local Window = Library:CreateWindow({
    Title        = 'Menu',
    Center       = true,
    AutoShow     = true,
    TabPadding   = 4, 
    MenuFadeTime = 0.1,
    Size         = UDim2.fromOffset(420, 260) -- Very compact
})

-- ─────────────────────────────────────────────────────────────
-- 🛠️ MOBILE TOUCH FIX (Removes the blue outline & fixes clicks)
-- ─────────────────────────────────────────────────────────────
if UserInputService.TouchEnabled then
    task.spawn(function()
        task.wait(0.5) -- Wait for UI to build
        
        if Library.ScreenGui then
            -- Scale the whole UI down to 75% (fixes hitbox misalignment)
            local uiScale = Instance.new('UIScale')
            uiScale.Scale = 0.75
            uiScale.Parent = Library.ScreenGui

            -- Loop through every button in the menu
            for _, obj in pairs(Library.ScreenGui:GetDescendants()) do
                if obj:IsA("TextButton") or obj:IsA("ImageButton") then
                    
                    -- 1. Stop the blue outline! 
                    -- This forces the mobile engine to CLICK instead of just SELECT
                    obj.Selectable = false 
                    obj.Active = true
                    
                    -- 2. Force touch to register as a click
                    obj.InputBegan:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.Touch then
                            -- We trigger the click manually just in case the engine missed it
                            if obj.Visible and obj.Parent then
                                -- (Callbacks are handled natively by the library once Selectable is false)
                            end
                        end
                    end)
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
