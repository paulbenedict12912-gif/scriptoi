-- language: Lua, file: rivals_aimbot.lua, target: Rivals PlaceId 17625359962
-- immune gate: entity.Data.IsInvincible — no auto weapon switch
-- auto pickup: 1:1 port of Oishiv3.txt LocalPickupObserver / UpdateRivalsPickupFeatures

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
    AutoHeal = true,
    AutoAmmo = true,
}

-- ─── deflection tracker ───────────────────────────────────────────────────────
local lastFire   = 0
local deflecting = {}
plrs.PlayerRemoving:Connect(function(p) deflecting[p] = nil end)

local function updateDeflection()
    if not FighterController or not FighterController.Objects then return end
    for _, fo in FighterController.Objects do
        local p = fo.Player
        if p then
            if not fo.Entity or not fo.Entity:IsAlive() then
                deflecting[p] = false
            else
                local eq = fo.EquippedItem
                local isKatana = eq and eq.ViewModel and eq.ViewModel.Name == "Katana"
                deflecting[p] = isKatana
                    and ((eq._attack_cooldown and eq._attack_cooldown > tick()) or false)
                    or false
            end
        end
    end
end

-- ─── immune check ─────────────────────────────────────────────────────────────
local function isImmune(player)
    if not FighterController or not FighterController.Objects then return true end
    for _, fo in FighterController.Objects do
        if fo.Player == player then
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
        if isEnemy(p) and not isImmune(p) then
            local pChar = p.Character
            if pChar then
                local pRoot = pChar:FindFirstChild("HumanoidRootPart")
                local pHead = pChar:FindFirstChild("Head")
                local pHum  = pChar:FindFirstChildWhichIsA("Humanoid")
                if pRoot and pHead and pHum and pHum.Health > 0 then
                    local dist = (myRoot.Position - pRoot.Position).Magnitude
                    if dist < bestDist then
                        bestDist = dist; best = p; bestRoot = pRoot; bestHead = pHead
                    end
                end
            end
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

-- ═══════════════════════════════════════════════════════════════════════════
--  AUTO PICKUP — 1:1 port of Oishiv3.txt LocalPickupObserver
--  Triggers (all three, matching the source):
--    1. RefreshPickupDrop → UpdateRivalsPickupFeatures()   (drop spawn)
--    2. AmmoChanged (_value_changed_events.Ammo) → Update   (mag hits 0)
--    3. HealthChanged below threshold      → Update         (damaged)
--  Retry loop runs every 0.05s only while shouldRetry is true.
-- ═══════════════════════════════════════════════════════════════════════════

local RIVALS_PICKUP_PLACES = {
    [17625359962]     = true,   -- aimbot target place
    [129604661913557] = true,   -- RIVALS shared match
    [71874690745115]  = true,
    [133215910299950] = true,
}

local function IsRivalsPickupPlace()
    return RIVALS_PICKUP_PLACES[game.PlaceId] == true
end

local function ReadItemValue(item, key)
    if not item or type(item.Get) ~= 'function' then
        return nil
    end
    local ok, value = pcall(item.Get, item, key)
    if not ok then
        return nil
    end
    return value
end

local function GetRivalsPickupKind(drop)
    if not drop or not drop:IsA('BasePart') or drop.Name ~= '_drop' then
        return nil
    end
    if drop:FindFirstChild('Health') then
        return 'Health'
    end
    if drop:FindFirstChild('AmmoBalanced') or drop:FindFirstChild('Ammo') then
        return 'Ammo'
    end
    return nil
end

local function GetRivalsPickupTouchPart()
    local char = lplr.Character
    if not char then return nil end
    local root = char:FindFirstChild('HumanoidRootPart')
    if not root then return nil end
    return char:FindFirstChild('HitboxBody')
        or root
        or char:FindFirstChildWhichIsA('BasePart')
end

local function TouchRivalsPickupDrop(drop, touchPart)
    if not drop or not drop.Parent or not touchPart or not touchPart.Parent then
        return false
    end
    firetouchinterest(touchPart, drop, 0)
    task.defer(function()
        if drop.Parent and touchPart.Parent then
            firetouchinterest(touchPart, drop, 1)
        end
    end)
    return true
end

local UpdateRivalsPickupFeatures

local LocalPickupObserver = {
    RetryActive = false,
    RetryDelay  = 0.05,
    RetryNonce  = 0,
}

do
    local pickupDropsByKind = { Health = {}, Ammo = {} }
    local pickupDropObservers = {}

    local function ClearPickupDropKinds(drop)
        if not drop then return end
        pickupDropsByKind.Health[drop] = nil
        pickupDropsByKind.Ammo[drop]   = nil
    end

    local function DisconnectPickupDropObserver(drop)
        local observer = pickupDropObservers[drop]
        if not observer then return end
        if observer.ChildAddedConnection then
            pcall(function() observer.ChildAddedConnection:Disconnect() end)
        end
        if observer.ChildRemovedConnection then
            pcall(function() observer.ChildRemovedConnection:Disconnect() end)
        end
        pickupDropObservers[drop] = nil
    end

    local function RefreshPickupDrop(drop)
        ClearPickupDropKinds(drop)
        if not drop or drop.Parent ~= ws or not drop:IsA('BasePart') or drop.Name ~= '_drop' then
            return
        end
        local dropKind        = GetRivalsPickupKind(drop)
        local hasTouchInterest = drop:FindFirstChildOfClass('TouchTransmitter') ~= nil
        if dropKind and hasTouchInterest then
            pickupDropsByKind[dropKind][drop] = true
            if UpdateRivalsPickupFeatures then
                UpdateRivalsPickupFeatures()
            end
        end
    end

    function LocalPickupObserver.ObserveDrop(drop)
        if not drop or not drop:IsA('BasePart') or drop.Name ~= '_drop' then
            return
        end
        if pickupDropObservers[drop] then
            RefreshPickupDrop(drop)
            return
        end
        local observer = {}
        pickupDropObservers[drop] = observer
        observer.ChildAddedConnection = drop.ChildAdded:Connect(function()
            RefreshPickupDrop(drop)
        end)
        observer.ChildRemovedConnection = drop.ChildRemoved:Connect(function()
            RefreshPickupDrop(drop)
        end)
        RefreshPickupDrop(drop)
    end

    function LocalPickupObserver.UnobserveDrop(drop)
        ClearPickupDropKinds(drop)
        DisconnectPickupDropObserver(drop)
    end

    function LocalPickupObserver.ResetDropTracking()
        for drop in pairs(pickupDropObservers) do
            DisconnectPickupDropObserver(drop)
        end
        for drop in pairs(pickupDropsByKind.Health) do
            pickupDropsByKind.Health[drop] = nil
        end
        for drop in pairs(pickupDropsByKind.Ammo) do
            pickupDropsByKind.Ammo[drop] = nil
        end
    end

    function LocalPickupObserver.FindNearestDrop(pickupKind, touchPart)
        if not IsRivalsPickupPlace() or not touchPart or not touchPart.Parent then
            return nil
        end
        local char = lplr.Character
        local hum  = char and char:FindFirstChildWhichIsA('Humanoid')
        if pickupKind == 'Health' and (not hum or hum.Health >= hum.MaxHealth) then
            return nil
        end
        local nearestDrop      = nil
        local nearestDistance  = nil
        local candidateDrops   = pickupDropsByKind[pickupKind]
        if not candidateDrops then
            return nil
        end
        for drop in pairs(candidateDrops) do
            if drop.Parent ~= ws then
                ClearPickupDropKinds(drop)
                DisconnectPickupDropObserver(drop)
            else
                local dropKind        = GetRivalsPickupKind(drop)
                local hasTouchInterest = drop:FindFirstChildOfClass('TouchTransmitter') ~= nil
                if dropKind == pickupKind and drop.CanTouch == true and hasTouchInterest then
                    local distance = (drop.Position - touchPart.Position).Magnitude
                    if not nearestDistance or distance < nearestDistance then
                        nearestDrop     = drop
                        nearestDistance = distance
                    end
                end
            end
        end
        return nearestDrop
    end
end

function LocalPickupObserver.CancelRetry()
    LocalPickupObserver.RetryActive = false
    LocalPickupObserver.RetryNonce  = LocalPickupObserver.RetryNonce + 1
end

function LocalPickupObserver.SyncRetry(shouldRetry)
    if not shouldRetry then
        LocalPickupObserver.CancelRetry()
        return
    end
    if LocalPickupObserver.RetryActive then
        return
    end
    LocalPickupObserver.RetryActive = true
    LocalPickupObserver.RetryNonce  = LocalPickupObserver.RetryNonce + 1
    local retryNonce = LocalPickupObserver.RetryNonce
    task.spawn(function()
        while LocalPickupObserver.RetryActive and LocalPickupObserver.RetryNonce == retryNonce do
            task.wait(LocalPickupObserver.RetryDelay)
            if LocalPickupObserver.RetryNonce ~= retryNonce or not LocalPickupObserver.RetryActive then
                return
            end
            local ok, keep = pcall(UpdateRivalsPickupFeatures)
            if not ok or not keep then
                LocalPickupObserver.RetryActive = false
                return
            end
        end
    end)
end

UpdateRivalsPickupFeatures = function()
    if type(firetouchinterest) ~= 'function' then
        LocalPickupObserver.CancelRetry()
        return false
    end
    if not IsRivalsPickupPlace() then
        LocalPickupObserver.CancelRetry()
        return false
    end
    local char = lplr.Character
    if not char then
        LocalPickupObserver.CancelRetry()
        return false
    end
    local hum  = char:FindFirstChildWhichIsA('Humanoid')
    local root = char:FindFirstChild('HumanoidRootPart')
    if not hum or not root or hum.Health <= 0 then
        LocalPickupObserver.CancelRetry()
        return false
    end
    local touchPart = GetRivalsPickupTouchPart()
    if not touchPart then
        LocalPickupObserver.CancelRetry()
        return false
    end

    local touchedDrop  = false
    local shouldRetry  = false
    local missingHealth = math.max(hum.MaxHealth - hum.Health, 0)

    if getgenv().Config.AutoHeal and missingHealth >= 25 then
        shouldRetry = true
        local healthDrop = LocalPickupObserver.FindNearestDrop('Health', touchPart)
        if healthDrop then
            touchedDrop = TouchRivalsPickupDrop(healthDrop, touchPart)
        end
    end

    local lf    = FighterController and FighterController.LocalFighter
    local item  = lf and lf.EquippedItem or nil
    local ammo  = ReadItemValue(item, 'Ammo')
    if not touchedDrop and getgenv().Config.AutoAmmo and type(ammo) == 'number' and ammo <= 0 then
        shouldRetry = true
        local ammoDrop = LocalPickupObserver.FindNearestDrop('Ammo', touchPart)
        if ammoDrop then
            TouchRivalsPickupDrop(ammoDrop, touchPart)
        end
    end

    LocalPickupObserver.SyncRetry(shouldRetry)
    return shouldRetry
end

-- Bind drops already in workspace + future drops
for _, child in ipairs(ws:GetChildren()) do
    LocalPickupObserver.ObserveDrop(child)
end
ws.ChildAdded:Connect(function(child) LocalPickupObserver.ObserveDrop(child) end)
ws.ChildRemoved:Connect(function(child) LocalPickupObserver.UnobserveDrop(child) end)

-- Health observer (RefreshLocalPickupHealthObserver)
local healthConn
local function RefreshLocalPickupHealthObserver()
    if healthConn then
        pcall(function() healthConn:Disconnect() end)
        healthConn = nil
    end
    if not IsRivalsPickupPlace() then return end
    local char = lplr.Character
    if not char then return end
    local hum = char:FindFirstChildWhichIsA('Humanoid')
    if not hum then return end
    healthConn = hum.HealthChanged:Connect(function()
        local missingHealth = math.max(hum.MaxHealth - hum.Health, 0)
        if missingHealth >= 25 then
            UpdateRivalsPickupFeatures()
        end
    end)
end
RefreshLocalPickupHealthObserver()

-- Ammo observer (AttachWeaponInfoItemObservers.AmmoChanged branch)
local ammoConn
local boundItem
local function RefreshAmmoObserver()
    if ammoConn then
        pcall(function() ammoConn:Disconnect() end)
        ammoConn = nil
    end
    local lf   = FighterController and FighterController.LocalFighter
    local item = lf and lf.EquippedItem
    if item == boundItem then return end
    boundItem = item
    if not item then return end
    local events = rawget(item, '_value_changed_events')
    if type(events) ~= 'table' then return end
    local ammoEvent = events.Ammo
    if ammoEvent and type(ammoEvent.Connect) == 'function' then
        ammoConn = ammoEvent:Connect(function(newAmmo)
            local ammo = type(newAmmo) == 'number' and newAmmo or ReadItemValue(item, 'Ammo')
            if type(ammo) == 'number' and ammo <= 0 then
                UpdateRivalsPickupFeatures()
            end
        end)
    end
end

if FighterController and FighterController.LocalFighter then
    RefreshAmmoObserver()
end

lplr.CharacterAdded:Connect(function()
    task.wait(0.5)
    RefreshLocalPickupHealthObserver()
    RefreshAmmoObserver()
end)

-- Keep ammo observer aligned with current fighter/equipped item.
task.spawn(function()
    while task.wait(1) do
        RefreshAmmoObserver()
        if not healthConn then RefreshLocalPickupHealthObserver() end
    end
end)

-- ─── heartbeat (aimbot) ──────────────────────────────────────────────────────
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
