--[[
    Aimbot UI (Linoria v2)
    Ported from ObfuscatedUE.lua.txt feature/config names.
    PC + Mobile support.
]]

local repo = 'https://raw.githubusercontent.com/wally-rblx/LinoriaLib/main/'
local Library      = loadstring(game:HttpGet(repo .. 'Library.lua'))()
local ThemeManager = loadstring(game:HttpGet(repo .. 'addons/ThemeManager.lua'))()
local SaveManager  = loadstring(game:HttpGet(repo .. 'addons/SaveManager.lua'))()

local UIS       = game:GetService("UserInputService")
local RS        = game:GetService("RunService")
local Players   = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local Camera    = Workspace.CurrentCamera
local LP        = Players.LocalPlayer

local IsMobile = UIS.TouchEnabled and not UIS.KeyboardEnabled

--------------------------------------------------------------------------------
-- WINDOW + MAIN TAB
--------------------------------------------------------------------------------
local Window = Library:CreateWindow({
    Title       = 'Aimbot UI',
    Center      = true,
    AutoShow    = true,
    TabPadding  = 8,
    MenuFadeTime= 0.2
})

local Tabs = {
    Main = Window:AddTab('Main', 'crosshair'),
}

local Options = Library.Options

--------------------------------------------------------------------------------
-- GROUP: AIMBOT SETTINGS  (left)
--------------------------------------------------------------------------------
local G_Aimbot = Tabs.Main:AddLeftGroupbox('Aimbot')

G_Aimbot:AddToggle('AimbotEnabled', {
    Text    = 'Enable Aimbot',
    Default = false,
    Tooltip = 'Master switch for the aimbot',
})

G_Aimbot:AddKeyPicker('AimbotKey', {
    Default          = 'MB2',
    Mode             = 'Hold',
    Text             = 'Aimbot Key',
    NoUI             = false,
    SyncToggleState  = false,
})

G_Aimbot:AddDropdown('AimbotTargetPart', {
    Values  = { 'Head', 'HumanoidRootPart', 'UpperTorso', 'LowerTorso',
                'Torso', 'LeftArm', 'RightArm', 'LeftLeg', 'RightLeg' },
    Default = 'Head',
    Multi   = false,
    Text    = 'Target Part',
    Tooltip = 'Body part the aimbot locks onto',
})

G_Aimbot:AddSlider('AimbotSmoothing', {
    Text     = 'Smoothing',
    Default  = 4,
    Min      = 1,
    Max      = 100,
    Rounding = 0,
    Compact  = false,
    Tooltip  = 'Higher = slower / more legit aim',
})

G_Aimbot:AddSlider('AimbotMaxDistance', {
    Text     = 'Max Distance',
    Default  = 1000,
    Min      = 10,
    Max      = 5000,
    Rounding = 0,
    Tooltip  = 'Do not target players farther than this',
})

G_Aimbot:AddToggle('AimbotTeamCheck', {
    Text    = 'Team Check',
    Default = true,
    Tooltip = 'Skip teammates',
})

G_Aimbot:AddToggle('AimbotWallCheck', {
    Text    = 'Wall Check (Visible Only)',
    Default = true,
    Tooltip = 'Only target players you can see',
})

G_Aimbot:AddToggle('AimbotIgnoreProtected', {
    Text    = 'Ignore Protected',
    Default = true,
    Tooltip = 'Skip protected / kata players',
})

G_Aimbot:AddToggle('AimbotMatchAxis', {
    Text    = 'Match Axis',
    Default = false,
    Tooltip = 'Lock camera axis to target axis',
})

--------------------------------------------------------------------------------
-- GROUP: AIMBOT FOV  (right)
--------------------------------------------------------------------------------
local G_Fov = Tabs.Main:AddRightGroupbox('Aimbot FOV')

G_Fov:AddToggle('AimbotShowFov', {
    Text    = 'Show FOV',
    Default = true,
    Tooltip = 'Draw the aimbot FOV circle',
})

G_Fov:AddSlider('AimbotFov', {
    Text     = 'FOV Size',
    Default  = 120,
    Min      = 10,
    Max      = 1000,
    Rounding = 0,
    Tooltip  = 'Radius of the FOV circle',
})

G_Fov:AddSlider('AimbotRadius', {
    Text     = 'Aimbot Radius',
    Default  = 0,
    Min      = 0,
    Max      = 100,
    Rounding = 0,
    Tooltip  = 'Extra radius offset',
})

G_Fov:AddSlider('AimbotFovRotation', {
    Text     = 'FOV Rotation',
    Default  = 0,
    Min      = 0,
    Max      = 360,
    Rounding = 0,
    Tooltip  = 'Base rotation of the FOV circle',
})

G_Fov:AddSlider('AimbotFovRotationSpeed', {
    Text     = 'FOV Rotation Speed',
    Default  = 0,
    Min      = 0,
    Max      = 10,
    Rounding = 2,
    Tooltip  = '0 = static, higher = spins',
})

G_Fov:AddColorPicker('AimbotFovFill', {
    Title        = 'FOV Fill',
    Default      = Color3.fromRGB(255, 255, 255),
    Transparency = 0.8,
})

G_Fov:AddColorPicker('AimbotFovOutline', {
    Title        = 'FOV Outline',
    Default      = Color3.fromRGB(255, 255, 255),
    Transparency = 0.5,
})

--------------------------------------------------------------------------------
-- GROUP: TARGET HIGHLIGHT  (left, under Aimbot)
--------------------------------------------------------------------------------
local G_Highlight = Tabs.Main:AddLeftGroupbox('Target Highlight')

G_Highlight:AddToggle('AimbotFill', {
    Text    = 'Fill',
    Default = true,
    Tooltip = 'Highlight fill on the target',
})

G_Highlight:AddColorPicker('AimbotFillColor1', {
    Title = 'Fill Color 1', Default = Color3.fromRGB(255, 255, 255), Transparency = 0.5,
})
G_Highlight:AddColorPicker('AimbotFillColor2', {
    Title = 'Fill Color 2', Default = Color3.fromRGB(200, 200, 200), Transparency = 0.5,
})
G_Highlight:AddColorPicker('AimbotFillColor3', {
    Title = 'Fill Color 3', Default = Color3.fromRGB(150, 150, 150), Transparency = 0.5,
})

G_Highlight:AddToggle('AimbotOutline', {
    Text    = 'Outline',
    Default = true,
    Tooltip = 'Highlight outline on the target',
})

G_Highlight:AddColorPicker('AimbotOutlineColor1', {
    Title = 'Outline Color 1', Default = Color3.fromRGB(255, 255, 255), Transparency = 0.5,
})
G_Highlight:AddColorPicker('AimbotOutlineColor2', {
    Title = 'Outline Color 2', Default = Color3.fromRGB(200, 200, 200), Transparency = 0.5,
})
G_Highlight:AddColorPicker('AimbotOutlineColor3', {
    Title = 'Outline Color 3', Default = Color3.fromRGB(150, 150, 150), Transparency = 0.5,
})

--------------------------------------------------------------------------------
-- GROUP: AIM BEHAVIOR  (right, under FOV)
--------------------------------------------------------------------------------
local G_Behavior = Tabs.Main:AddRightGroupbox('Aim Behavior')

G_Behavior:AddSlider('AimbotDelaySmooth', {
    Text     = 'Delay Smooth',
    Default  = 0,
    Min      = 0,
    Max      = 1,
    Rounding = 2,
    Tooltip  = 'Extra delay applied to smoothing',
})

G_Behavior:AddSlider('AimbotDelayPosition', {
    Text     = 'Delay Position',
    Default  = 0,
    Min      = 0,
    Max      = 1,
    Rounding = 2,
    Tooltip  = 'Extra delay applied to the aim position',
})

G_Behavior:AddToggle('AimbotMobileAim', {
    Text    = 'Mobile Touch Aim',
    Default = true,
    Tooltip = 'While a finger is held on the right half of the screen, the aimbot will track',
})

--------------------------------------------------------------------------------
-- FOV CIRCLE RENDER
--------------------------------------------------------------------------------
local FovGui = Instance.new('ScreenGui')
FovGui.Name          = 'AimbotFov'
FovGui.ResetOnSpawn  = false
FovGui.IgnoreGuiInset= true
do
    local ok = pcall(function() FovGui.Parent = game:GetService('CoreGui') end)
    if not ok then FovGui.Parent = LP:WaitForChild('PlayerGui') end
end

local FovFrame = Instance.new('Frame')
FovFrame.BackgroundTransparency = 1
FovFrame.AnchorPoint = Vector2.new(0.5, 0.5)
FovFrame.Position    = UDim2.new(0.5, 0, 0.5, 0)
FovFrame.Parent      = FovGui

local FovCircle = Instance.new('Frame')
FovCircle.BorderSizePixel       = 0
FovCircle.BackgroundTransparency= 0.8
FovCircle.Size                  = UDim2.new(1, 0, 1, 0)
FovCircle.Parent                = FovFrame

Instance.new('UICorner', FovCircle).CornerRadius = UDim.new(0.5, 0)

local FovStroke = Instance.new('UIStroke')
FovStroke.Thickness = 1
FovStroke.Parent    = FovCircle

RS.RenderStepped:Connect(function()
    if not Options.AimbotShowFov.Value then
        FovFrame.Visible = false
        return
    end
    FovFrame.Visible = true

    local size = Options.AimbotFov.Value * 2
    FovFrame.Size     = UDim2.new(0, size, 0, size)
    FovFrame.Position = UDim2.new(0.5, 0, 0.5, 0)

    FovCircle.BackgroundColor3      = Options.AimbotFovFill.Value
    FovCircle.BackgroundTransparency= Options.AimbotFovFill.Transparency
    FovStroke.Color                 = Options.AimbotFovOutline.Value
    FovStroke.Transparency          = Options.AimbotFovOutline.Transparency

    local rot = Options.AimbotFovRotation.Value +
                (tick() * Options.AimbotFovRotationSpeed.Value * 60) % 360
    FovFrame.Rotation = rot
end)

--------------------------------------------------------------------------------
-- TOUCH AIM TRACKING (mobile)
--------------------------------------------------------------------------------
local TouchAiming = false
if IsMobile then
    UIS.TouchStarted:Connect(function(input)
        if input.Position.X > Camera.ViewportSize.X / 2 then
            TouchAiming = true
        end
    end)
    UIS.TouchEnded:Connect(function(input)
        if input.Position.X > Camera.ViewportSize.X / 2 then
            TouchAiming = false
        end
    end)
end

--------------------------------------------------------------------------------
-- TARGET ACQUISITION
--------------------------------------------------------------------------------
local CurrentTarget = nil

local function IsPlayerVisible(player, part)
    if not Options.AimbotWallCheck.Value then return true end
    local ray = RaycastParams.new()
    ray.FilterType = Enum.RaycastFilterType.Exclude
    ray.FilterDescendantsInstances = {
        LP.Character,
        player.Character,
        FovGui
    }
    local hit = Workspace:Raycast(Camera.CFrame.Position, part.Position - Camera.CFrame.Position, ray)
    return hit == nil or hit.Instance:IsDescendantOf(player.Character)
end

local function IsProtected(player)
    -- Common FFA/kata check names. Extend as needed.
    for _, n in ipairs({'Kata', 'Protected', 'KataProtected', 'Safe'}) do
        local v = player:FindFirstChild(n) or (player.Character and player.Character:FindFirstChild(n))
        if v then return true end
    end
    return false
end

local function GetClosestTarget()
    local fov      = Options.AimbotFov.Value
    local maxDist  = Options.AimbotMaxDistance.Value
    local partName = Options.AimbotTargetPart.Value
    local screenC  = Camera.ViewportSize / 2
    local best, bestDist = nil, fov

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr == LP then continue end
        local char = plr.Character
        if not char then continue end
        local hum = char:FindFirstChildOfClass('Humanoid')
        if not hum or hum.Health <= 0 then continue end

        if Options.AimbotTeamCheck.Value and plr.Team == LP.Team then continue end
        if Options.AimbotIgnoreProtected.Value and IsProtected(plr) then continue end

        local part = char:FindFirstChild(partName)
        if not part then continue end

        if LP.Character and LP.Character:FindFirstChild('HumanoidRootPart') then
            local dist = (LP.Character.HumanoidRootPart.Position - part.Position).Magnitude
            if dist > maxDist then continue end
        end

        local sp, onScreen = Camera:WorldToViewportPoint(part.Position)
        if onScreen then
            local screenDist = (Vector2.new(sp.X, sp.Y) - screenC).Magnitude
            if screenDist < bestDist and IsPlayerVisible(plr, part) then
                bestDist = screenDist
                best = { Player = plr, Part = part }
            end
        end
    end

    return best
end

local function IsAimActive()
    if IsMobile and Options.AimbotMobileAim.Value then
        return TouchAiming
    end
    return Options.AimbotKey:GetState()
end

--------------------------------------------------------------------------------
-- AIM LOOP  (runs after the default camera so we can override it)
--------------------------------------------------------------------------------
RS:BindToRenderStep('Aimbot', Enum.RenderPriority.Camera.Value + 1, function(dt)
    if not Options.AimbotEnabled.Value or not IsAimActive() then
        CurrentTarget = nil
        return
    end

    CurrentTarget = GetClosestTarget()
    if not CurrentTarget then return end

    local targetPos = CurrentTarget.Part.Position

    -- Smoothing 1..100 → alpha 1..0.01
    local smooth = math.clamp(Options.AimbotSmoothing.Value, 1, 100)
    local alpha  = 1 / smooth

    if Options.AimbotDelaySmooth.Value > 0 then
        alpha = alpha * (1 - Options.AimbotDelaySmooth.Value)
    end

    local currentCF = Camera.CFrame
    local desiredCF = CFrame.new(currentCF.Position, targetPos)

    if Options.AimbotMatchAxis.Value then
        local targetCF = CurrentTarget.Part.CFrame
        desiredCF = CFrame.new(currentCF.Position, targetPos) * (targetCF - targetCF.Position)
    end

    Camera.CFrame = currentCF:Lerp(desiredCF, alpha)
end)

--------------------------------------------------------------------------------
-- SAVE / LOAD  (mirrors the original SaveManager style)
--------------------------------------------------------------------------------
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({
    'AimbotKey',
    'AimbotMobileAim',
})
SaveManager:SetFolder('AimbotUI')
SaveManager:BuildConfigSection(Tabs.Main)
SaveManager:LoadAutoloadConfig()

ThemeManager:SetLibrary(Library)
ThemeManager:ApplyToTab(Tabs.Main)

--------------------------------------------------------------------------------
-- CLEANUP
--------------------------------------------------------------------------------
Library:OnUnload(function()
    if FovGui then FovGui:Destroy() end
    RS:UnbindFromRenderStep('Aimbot')
end)

Library:Notify(
    IsMobile
        and 'Aimbot UI loaded. Use the floating button to open/close.'
        or  'Aimbot UI loaded. RightShift to toggle.',
    3
)
