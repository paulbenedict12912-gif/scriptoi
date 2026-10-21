-- language: Lua, file: rivals_full.lua, target: Rivals PlaceId 17625359962
-- immune filter + desync aimbot + floating drag toggle

local repS = cloneref(game:GetService("ReplicatedStorage"))
local plrs = cloneref(game:GetService("Players"))
local runS = cloneref(game:GetService("RunService"))
local ws   = cloneref(game:GetService("Workspace"))
local uis  = cloneref(game:GetService("UserInputService"))
local lplr = plrs.LocalPlayer
local util = require(repS.Modules.Utility)
local enum = require(repS.Modules.EnumLibrary)
local FighterController  = require(lplr.PlayerScripts.Controllers.FighterController)
local SpectateController = require(lplr.PlayerScripts.Controllers:WaitForChild("SpectateController"))

getgenv().Config = {
    Enabled    = true,
    FireRate   = 0.0005,
    WeaponSlot = "Melee"  -- "Primary" | "Secondary" | "Melee"
}

local slots = { Primary = 1, Secondary = 2, Melee = 3 }
local function getSlotNumber() return slots[getgenv().Config.WeaponSlot] or 3 end

-- ─── auto equip ───────────────────────────────────────────────────────────────
task.spawn(function()
    local lf = FighterController.LocalFighter
    while not lf do task.wait(0.1); lf = FighterController.LocalFighter end
    pcall(function() lf:EquipItem(getSlotNumber()) end)
end)

task.spawn(function()
    while true do
        task.wait(1)
        if not getgenv().Config.Enabled then continue end
        local lf = FighterController.LocalFighter
        if lf then pcall(function() lf:EquipItem(getSlotNumber()) end) end
    end
end)

-- ─── deflection tracker ───────────────────────────────────────────────────────
local lastFire   = 0
local deflecting = {}

plrs.PlayerRemoving:Connect(function(p) deflecting[p] = nil end)

local function updateDeflection()
    if not FighterController or not FighterController.Objects then return end
    for _, fo in FighterController.Objects do
        local p = fo.Player
        if not p then continue end
        if not fo.Entity or not fo.Entity:IsAlive() or fo:Get("IsSpectating") then
            deflecting[p] = false; continue
        end
        local eq       = fo.EquippedItem
        local isKatana = eq and eq.ViewModel and eq.ViewModel.Name == "Katana"
        deflecting[p]  = isKatana
            and ((eq._attack_cooldown and eq._attack_cooldown > tick()) or false)
            or false
    end
end

-- ─── immune check ─────────────────────────────────────────────────────────────
local IMMUNE_KEYS = {
    "IsInvincible",
    "Invincible",
    "IsRespawning",
    "IsSpectating",
    "IsImmune",
    "SpawnProtect",
}

local function isImmune(player)
    if not FighterController or not FighterController.Objects then return true end
    for _, fo in FighterController.Objects do
        if fo.Player ~= player then continue end
        if not fo.Entity or not fo.Entity:IsAlive() then return true end
        if fo:Get("IsSpectating") then return true end
        for _, key in IMMUNE_KEYS do
            local ok, val = pcall(function() return fo:Get(key) end)
            if ok and val then return true end
        end
        local char = player.Character
        if char then
            for _, key in IMMUNE_KEYS do
                if char:GetAttribute(key) then return true end
            end
            local hum = char:FindFirstChildWhichIsA("Humanoid")
            if hum and hum.Health <= 0 then return true end
        end
        for _, key in IMMUNE_KEYS do
            if player:GetAttribute(key) then return true end
        end
        return false
    end
    return true
end

-- ─── enemy check ─────────────────────────────────────────────────────────────
local function isEnemy(player)
    if player == lplr then return false end
    local duel       = SpectateController.CurrentDuelSubject
    local localDueler = duel and duel:GetDueler(lplr)
    local localTeam   = localDueler and localDueler:Get("TeamID") or nil
    if localTeam and duel and duel.Duelers then
        for _, dueler in duel.Duelers do
            if dueler.Player == player then
                return dueler:Get("TeamID") ~= localTeam
            end
        end
    end
    local pTeam = player:GetAttribute("TeamID")
    local lTeam = lplr:GetAttribute("TeamID")
    if pTeam and lTeam then return pTeam ~= lTeam end
    return true
end

-- ─── closest non-immune enemy ─────────────────────────────────────────────────
local function getClosestTarget()
    local char = lplr.Character
    if not char then return nil, nil, nil end
    local myRoot = char:FindFirstChild("HumanoidRootPart")
    if not myRoot then return nil, nil, nil end

    local best, bestRoot, bestHead, bestDist = nil, nil, nil, 500

    for _, p in plrs:GetPlayers() do
        if not isEnemy(p)  then continue end
        if isImmune(p)     then continue end
        local pChar = p.Character
        if not pChar then continue end
        local pRoot = pChar:FindFirstChild("HumanoidRootPart")
        local pHead = pChar:FindFirstChild("Head")
        local pHum  = pChar:FindFirstChildWhichIsA("Humanoid")
        if not (pRoot and pHead and pHum and pHum.Health > 0) then continue end
        local dist = (myRoot.Position - pRoot.Position).Magnitude
        if dist < bestDist then
            bestDist = dist
            best     = p
            bestRoot = pRoot
            bestHead = pHead
        end
    end
    return best, bestRoot, bestHead
end

-- ─── knife viewmodel check ────────────────────────────────────────────────────
local function hasKnifeViewModel(targetPlayer)
    if not targetPlayer then return false end
    local viewModels = ws:FindFirstChild("ViewModels")
    if not viewModels then return false end
    for _, m in viewModels:GetChildren() do
        if m:IsA("Model")
           and string.find(m.Name, targetPlayer.Name, 1, true)
           and string.find(m.Name, "Knife", 1, true) then
            return true
        end
    end
    return false
end

-- ─── heartbeat ────────────────────────────────────────────────────────────────
runS.Heartbeat:Connect(function()
    updateDeflection()

    local targetPlayer, targetRoot, targetHead = getClosestTarget()
    local desyncCF = nil

    if targetRoot and targetHead then
        local desyncPos = hasKnifeViewModel(targetPlayer)
            and (targetRoot.CFrame * CFrame.new(0, 6, 0)).Position
            or  (targetRoot.CFrame * CFrame.new(0, 1, 2)).Position
        desyncCF = CFrame.lookAt(desyncPos, targetHead.Position)
    end

    if desyncCF and lplr.Character then
        local myRoot = lplr.Character:FindFirstChild("HumanoidRootPart")
        if myRoot then
            local oldCF     = myRoot.CFrame
            local oldVel    = myRoot.Velocity
            local oldRotVel = myRoot.RotVelocity
            myRoot.CFrame   = desyncCF
            runS:BindToRenderStep("__restore", 101, function()
                if myRoot then
                    myRoot.CFrame      = oldCF
                    myRoot.Velocity    = oldVel
                    myRoot.RotVelocity = oldRotVel
                end
                runS:UnbindFromRenderStep("__restore")
            end)
        end
    end

    if not getgenv().Config.Enabled then return end
    if not targetPlayer or not targetHead or not targetRoot then return end
    if deflecting[targetPlayer] then return end
    if not lplr.Character or not lplr.Character:FindFirstChild("HumanoidRootPart") then return end
    if not FighterController or not FighterController.LocalFighter then return end
    local item = FighterController.LocalFighter.EquippedItem
    if not item then return end
    if tick() - lastFire < getgenv().Config.FireRate then return end
    lastFire = tick()

    local originPos        = desyncCF and desyncCF.Position or targetRoot.Position
    local randomOffset     = Vector3.new(
        (math.random() - 0.5) * 0.1,
        (math.random() - 0.5) * 0.1,
        (math.random() - 0.5) * 0.1
    )
    local aimedPos         = targetHead.Position + randomOffset
    local aimCF            = CFrame.lookAt(originPos, targetHead.Position)
    local objSpaceHeadOff  = targetHead.CFrame:ToObjectSpace(CFrame.new(aimedPos))

    local cameradata = {}
    cameradata[utf8.char(1)] = {
        [utf8.char(0)] = util:EncodeCFrame(aimCF),
        [utf8.char(1)] = util:EncodeCFrame(targetHead.CFrame),
        [utf8.char(2)] = targetHead,
        [utf8.char(3)] = util:EncodeCFrame(objSpaceHeadOff)
    }

    repS.Remotes.Replication.Fighter.UseItem:FireServer(
        item:Get("ObjectID"),
        enum:ToEnum("StartShooting"),
        cameradata,
        nil
    )
end)

-- ─── floating toggle button ───────────────────────────────────────────────────
local pg = lplr:WaitForChild("PlayerGui")

local sg = Instance.new("ScreenGui")
sg.Name                = "RivalsToggle"
sg.ResetOnSpawn        = false
sg.DisplayOrder        = 999
sg.IgnoreGuiInset      = true
sg.Parent              = pg

local btn = Instance.new("TextButton")
btn.Size                   = UDim2.new(0, 58, 0, 28)
btn.AnchorPoint            = Vector2.new(0, 0)
btn.BackgroundColor3       = Color3.fromRGB(18, 18, 18)
btn.BackgroundTransparency = 0.25
btn.TextColor3             = Color3.fromRGB(255, 255, 255)
btn.Font                   = Enum.Font.GothamBold
btn.TextSize               = 12
btn.Text                   = "on 😐"
btn.BorderSizePixel        = 0
btn.AutoButtonColor        = false
btn.ClipsDescendants       = false
btn.Parent                 = sg

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent       = btn

-- init position bottom-left on first frame so ViewportSize is ready
task.defer(function()
    local vp     = workspace.CurrentCamera.ViewportSize
    btn.Position = UDim2.new(0, 10, 0, math.floor(vp.Y * 0.5) - 14)
end)

-- ─── drag state ───────────────────────────────────────────────────────────────
local dragging    = false
local dragInput   = nil
local dragOrigin  = nil
local btnOrigin   = nil
local DRAG_THRESH = 5

local function inputPos(input)
    return Vector2.new(input.Position.X, input.Position.Y)
end

local function isTrigger(input)
    return input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch
end

local function isMoveType(input)
    return input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch
end

local function applyState()
    if getgenv().Config.Enabled then
        btn.Text             = "on 😐"
        btn.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
    else
        btn.Text             = "off 😁"
        btn.BackgroundColor3 = Color3.fromRGB(45, 12, 12)
    end
end

btn.InputBegan:Connect(function(input)
    if not isTrigger(input) then return end
    dragging   = true
    dragInput  = input
    dragOrigin = inputPos(input)
    local abs  = btn.AbsolutePosition
    btn.Position = UDim2.new(0, abs.X, 0, abs.Y)
    btnOrigin  = btn.Position
end)

uis.InputChanged:Connect(function(input)
    if not dragging then return end
    if not isMoveType(input) then return end
    if input.UserInputType == Enum.UserInputType.Touch
    and dragInput and input ~= dragInput then return end

    local delta = inputPos(input) - dragOrigin
    if delta.Magnitude < DRAG_THRESH then return end

    local vp   = workspace.CurrentCamera.ViewportSize
    local newX = math.clamp(btnOrigin.X.Offset + delta.X, 0, vp.X - btn.AbsoluteSize.X)
    local newY = math.clamp(btnOrigin.Y.Offset + delta.Y, 0, vp.Y - btn.AbsoluteSize.Y)
    btn.Position = UDim2.new(0, newX, 0, newY)
end)

uis.InputEnded:Connect(function(input)
    if not dragging then return end
    if not isTrigger(input) then return end
    if input.UserInputType == Enum.UserInputType.Touch
    and dragInput and input ~= dragInput then return end

    local delta = (inputPos(input) - dragOrigin).Magnitude
    if delta < DRAG_THRESH then
        getgenv().Config.Enabled = not getgenv().Config.Enabled
        applyState()
    end

    dragging  = false
    dragInput = nil
end)
