-- Mobile-optimized LinoriaLib example (touch support + compact UI)
local repo = 'https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/'

local Library     = loadstring(game:HttpGet(repo .. 'Library.lua'))()
local ThemeManager = loadstring(game:HttpGet(repo .. 'addons/ThemeManager.lua'))()
local SaveManager  = loadstring(game:HttpGet(repo .. 'addons/SaveManager.lua'))()

local UserInputService = game:GetService('UserInputService')
local isMobile = UserInputService.TouchEnabled

local Window = Library:CreateWindow({
    Title        = 'Example Menu',
    Center       = true,
    AutoShow     = true,
    TabPadding   = 6,          -- tighter tabs
    MenuFadeTime = 0.2,
})

-- ─────────────────────────────────────────────────────────────
-- MOBILE SUPPORT: auto-fit scaling + touch dragging
-- ─────────────────────────────────────────────────────────────
if isMobile and Library.MainFrame then
    local frame    = Library.MainFrame
    local viewport = workspace.CurrentCamera.ViewportSize

    -- 1) Auto-scale to fit viewport (max 85% of screen)
    local sizeX = frame.Size.X.Scale * viewport.X + frame.Size.X.Offset
    local sizeY = frame.Size.Y.Scale * viewport.Y + frame.Size.Y.Offset
    local scale = math.min(
        (viewport.X * 0.85) / sizeX,
        (viewport.Y * 0.85) / sizeY,
        1
    )
    if scale < 0.99 then
        local uiScale    = Instance.new('UIScale')
        uiScale.Scale    = scale
        uiScale.Parent   = frame
    end

    -- 2) Touch drag support (top ~12% of frame = title bar)
    local dragging, dragStart, startPos

    frame.InputBegan:Connect(function(input, processed)
        if processed then return end
        if input.UserInputType ~= Enum.UserInputType.Touch then return end
        if UserInputService:GetFocusedTextBox() then return end

        local relY = (input.Position.Y - frame.AbsolutePosition.Y)
                     / math.max(frame.AbsoluteSize.Y, 1)
        if relY > 0.12 then return end  -- only drag from title bar

        dragging  = true
        dragStart = input.Position
        startPos  = frame.Position

        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end)

    frame.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType ~= Enum.UserInputType.Touch then return end
        local delta = input.Position - dragStart
        frame.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end)
end

-- ─────────────────────────────────────────────────────────────
-- TABS (kept short for mobile)
-- ─────────────────────────────────────────────────────────────
local Tabs = {
    Main     = Window:AddTab('Main'),
    Settings = Window:AddTab('Settings'),
}

-- === MAIN TAB ===
local Features = Tabs.Main:AddLeftGroupbox('Features')

Features:AddToggle('MyToggle', {
    Text    = 'Enable feature',
    Default = true,
    Callback = function(v) print('[cb] Toggle:', v) end
})

local Btn = Features:AddButton({
    Text = 'Click me',
    Func = function() print('Button clicked!') end,
    Tooltip = 'Example button'
})
Btn:AddButton({
    Text = 'Sub button',
    Func = function() print('Sub clicked!') end,
    DoubleClick = true
})

Features:AddSlider('MySlider', {
    Text = 'Slider value',
    Default = 50, Min = 0, Max = 100, Rounding = 0,
    Callback = function(v) print('[cb] Slider:', v) end
})

Features:AddDropdown('MyDropdown', {
    Values  = {'Option A', 'Option B', 'Option C'},
    Default = 1,
    Text    = 'Choose option',
    Callback = function(v) print('[cb] Dropdown:', v) end
})

Features:AddInput('MyInput', {
    Default     = 'Text',
    Text        = 'Textbox',
    Placeholder = 'Type here...',
    Callback    = function(v) print('[cb] Input:', v) end
})

Features:AddLabel('Color'):AddColorPicker('MyColor', {
    Default = Color3.fromRGB(0, 200, 120),
    Title   = 'Pick a color'
})

Features:AddLabel('Keybind'):AddKeyPicker('MyKey', {
    Default = 'MB2',
    Mode    = 'Toggle',
    Text    = 'Example keybind'
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
ThemeManager:SetFolder('MyScriptHub')
SaveManager:SetFolder('MyScriptHub/specific-game')
SaveManager:BuildConfigSection(Tabs.Settings)
ThemeManager:ApplyToTab(Tabs.Settings)
SaveManager:LoadAutoloadConfig()
