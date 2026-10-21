-- language: Lua, file: rivals_aimbot.lua, target: Rivals PlaceId 17625359962
-- immune gate: entity.Data.IsInvincible — no auto weapon switch

local repS = cloneref(game:GetService("ReplicatedStorage"))
local plrs = cloneref(game:GetService("Players"))
local runS = cloneref(game:GetService("RunService"))
local ws   = cloneref(game:GetService("Workspace"))
local lplr = plrs.LocalPlayer
local util = require(repS.Modules.Utility)
local enum = require(repS.Modules.EnumLibrary)
local FighterController  = require(lplr.PlayerScripts.Controllers.FighterController)
local SpectateController = require(lplr.PlayerScripts.Controllers:WaitForChild("SpectateController"))

getgenv().Config = {
    Enabled  = true,
    FireRate = 0.0005,
}

-- ─── deflection tracker ───────────────────────────────────────────────────────
local lastFire   = 0
local deflecting = {}

plrs.PlayerRemoving:Connect(function(p)
    deflecting[p] = nil
end)

local function updateDeflection()
    if not FighterController or not FighterController.Objects then return end
    for _, fo in FighterController.Objects do
        local p = fo.Player
        if not p then continue end
        if not fo.Entity or not fo.Entity:IsAlive() then
            deflecting[p] = false; continue
        end
        local eq = fo.EquippedItem
        local isKatana = eq and eq.ViewModel and eq.ViewModel.Name == "Katana"
        deflecting[p] = isKatana
            and ((eq._attack_cooldown and eq._attack_cooldown > tick()) or false)
            or false
    end
end

-- ─── immune check ─────────────────────────────────────────────────────────────
local function isImmune(player)
    if not FighterController or not FighterController.Objects then return true end
    for _, fo in FighterController.Objects do
        if fo.Player ~= player then continue end
        local entity = rawget(fo, 'Entity')
        if not entity or not entity:IsAlive() then return true end
        local data = rawget(entity, 'Data')
        if data ~= nil and rawget(data, 'IsInvincible') == true then return true end
        local char = player.Character
        if char then
            local hum = char:FindFirstChildWhichIsA("Humanoid")
            if hum and hum.Health <= 0 then return true end
        end
        return false
    end
    return true
end

-- ─── team / enemy check ──────────────────────────────────────────────────────
local function isEnemy(player)
    if player == lplr then return false end
    local duel = SpectateController.CurrentDuelSubject
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
        if not isEnemy(p) then continue end
        if isImmune(p) then continue end
        local pChar = p.Character
        if not pChar then continue end
        local pRoot = pChar:FindFirstChild("HumanoidRootPart")
        local pHead = pChar:FindFirstChild("Head")
        local pHum  = pChar:FindFirstChildWhichIsA("Humanoid")
        if not (pRoot and pHead and pHum and pHum.Health > 0) then continue end
        local dist = (myRoot.Position - pRoot.Position).Magnitude
        if dist < bestDist then
            bestDist = dist; best = p; bestRoot = pRoot; bestHead = pHead
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
           and string.find(m.Name, "Knife",           1, true) then
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

    local originPos = desyncCF and desyncCF.Position or targetRoot.Position
    local randomOffset = Vector3.new(
        (math.random() - 0.5) * 0.1,
        (math.random() - 0.5) * 0.1,
        (math.random() - 0.5) * 0.1
    )
    local aimedPos        = targetHead.Position + randomOffset
    local aimCF           = CFrame.lookAt(originPos, targetHead.Position)
    local objSpaceHeadOff = targetHead.CFrame:ToObjectSpace(CFrame.new(aimedPos))
    local cameradata      = {}
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
