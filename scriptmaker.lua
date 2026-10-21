-- language: Lua, file: rivals_aimbot.lua, target: Rivals PlaceId 17625359962
-- immune gate: entity.Data.IsInvincible — no auto weapon switch
-- added: auto collect health + ammo (ported from Oishiv3.txt P8S1T1 / P8S1T2)

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

    -- Auto pickup (ported from Oishiv3.txt)
    AutoHeal        = true,
    AutoAmmo        = true,
    HealthThreshold = 25,   -- grab health drop when missing HP >= this (matches Oishiv3 P8S1T1)
    PickupRetryDelay = 0.05,
    PickupTick       = 0.25,
}

-- ─── pickup places ────────────────────────────────────────────────────────────
-- Oishiv3 only checked 129604661913557 / 71874690745115 / 133215910299950.
-- Aim bot targets 17625359962, so include it here so pickup runs on that place too.
local RIVALS_PICKUP_PLACES = {
    [17625359962]     = true,
    [129604661913557] = true,
    [71874690745115]  = true,
    [133215910299950] = true,
}
local function isPickupPlace()
    return RIVALS_PICKUP_PLACES[game.PlaceId] == true
end

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

-- ═══════════════════════════════════════════════════════════════════════════
--  AUTO PICKUP — ported from Oishiv3.txt (P8S1T1 / P8S1T2)
--  * drops are `_drop` BaseParts with a Health child, or AmmoBalanced/Ammo child
--  * collected via firetouchinterest(touchPart, drop, 0 then 1)
--  * health fires when missing HP >= HealthThreshold
--  * ammo fires when current magazine ammo <= 0
-- ═══════════════════════════════════════════════════════════════════════════

local function readItemValue(item, key)
    if not item or type(item.Get) ~= "function" then return nil end
    local ok, value = pcall(item.Get, item, key)
    if not ok then return nil end
    return value
end

local PickupObserver = {
    RetryActive = false,
    RetryNonce  = 0,
}
local pickupDropsByKind = {
    Health = {},
    Ammo   = {},
}
local pickupDropObservers = {}

local function getPickupKind(drop)
    if not drop or not drop:IsA("BasePart") or drop.Name ~= "_drop" then
        return nil
    end
    if drop:FindFirstChild("Health") then
        return "Health"
    end
    if drop:FindFirstChild("AmmoBalanced") or drop:FindFirstChild("Ammo") then
        return "Ammo"
    end
    return nil
end

local function clearPickupDropKinds(drop)
    if not drop then return end
    pickupDropsByKind.Health[drop] = nil
    pickupDropsByKind.Ammo[drop]   = nil
end

local function disconnectPickupDropObserver(drop)
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

local function refreshPickupDrop(drop)
    clearPickupDropKinds(drop)
    if not drop or drop.Parent ~= ws or not drop:IsA("BasePart") or drop.Name ~= "_drop" then
        return
    end
    local kind     = getPickupKind(drop)
    local hasTouch = drop:FindFirstChildOfClass("TouchTransmitter") ~= nil
    if kind and hasTouch then
        pickupDropsByKind[kind][drop] = true
    end
end

local function observeDrop(drop)
    if not drop or not drop:IsA("BasePart") or drop.Name ~= "_drop" then
        return
    end
    if pickupDropObservers[drop] then
        refreshPickupDrop(drop)
        return
    end
    local observer = {}
    pickupDropObservers[drop] = observer
    observer.ChildAddedConnection = drop.ChildAdded:Connect(function()
        refreshPickupDrop(drop)
    end)
    observer.ChildRemovedConnection = drop.ChildRemoved:Connect(function()
        refreshPickupDrop(drop)
    end)
    refreshPickupDrop(drop)
end

local function unobserveDrop(drop)
    clearPickupDropKinds(drop)
    disconnectPickupDropObserver(drop)
end

local function findNearestDrop(kind, touchPart)
    if not isPickupPlace() or not touchPart or not touchPart.Parent then
        return nil
    end
    local char = lplr.Character
    local hum  = char and char:FindFirstChildWhichIsA("Humanoid")
    if kind == "Health" and (not hum or hum.Health >= hum.MaxHealth) then
        return nil
    end
    local candidates = pickupDropsByKind[kind]
    if not candidates then return nil end
    local best, bestDist = nil, nil
    for drop in pairs(candidates) do
        if drop.Parent ~= ws then
            clearPickupDropKinds(drop)
            disconnectPickupDropObserver(drop)
        else
            local dKind    = getPickupKind(drop)
            local hasTouch = drop:FindFirstChildOfClass("TouchTransmitter") ~= nil
            if dKind == kind and drop.CanTouch == true and hasTouch then
                local dist = (drop.Position - touchPart.Position).Magnitude
                if not bestDist or dist < bestDist then
                    best     = drop
                    bestDist = dist
                end
            end
        end
    end
    return best
end

local function getTouchPart()
    local char = lplr.Character
    if not char then return nil end
    return char:FindFirstChild("HitboxBody")
        or char:FindFirstChild("HumanoidRootPart")
        or char:FindFirstChildWhichIsA("BasePart")
end

local function touchDrop(drop, touchPart)
    if type(firetouchinterest) ~= "function" then return false end
    if not drop or not drop.Parent or not touchPart or not touchPart.Parent then
        return false
    end
    pcall(firetouchinterest, touchPart, drop, 0)
    task.defer(function()
        if drop.Parent and touchPart.Parent then
            pcall(firetouchinterest, touchPart, drop, 1)
        end
    end)
    return true
end

local tryPickup

local function scheduleRetry()
    if PickupObserver.RetryActive then return end
    PickupObserver.RetryActive = true
    PickupObserver.RetryNonce  = PickupObserver.RetryNonce + 1
    local nonce = PickupObserver.RetryNonce
    task.spawn(function()
        while PickupObserver.RetryActive and PickupObserver.RetryNonce == nonce do
            task.wait(getgenv().Config.PickupRetryDelay)
            if PickupObserver.RetryNonce ~= nonce or not PickupObserver.RetryActive then
                return
            end
            if not tryPickup() then
                PickupObserver.RetryActive = false
                return
            end
        end
    end)
end

local function cancelRetry()
    PickupObserver.RetryActive = false
    PickupObserver.RetryNonce  = PickupObserver.RetryNonce + 1
end

tryPickup = function()
    if type(firetouchinterest) ~= "function" then
        cancelRetry()
        return false
    end
    if not isPickupPlace() then
        cancelRetry()
        return false
    end

    local char = lplr.Character
    if not char then cancelRetry(); return false end
    local hum = char:FindFirstChildWhichIsA("Humanoid")
    if not hum or hum.Health <= 0 then cancelRetry(); return false end

    local touchPart = getTouchPart()
    if not touchPart then cancelRetry(); return false end

    local touched      = false
    local shouldRetry  = false
    local missingHP    = math.max(hum.MaxHealth - hum.Health, 0)

    -- Health drop
    if getgenv().Config.AutoHeal and missingHP >= getgenv().Config.HealthThreshold then
        shouldRetry = true
        local drop = findNearestDrop("Health", touchPart)
        if drop then
            touched = touchDrop(drop, touchPart)
        end
    end

    -- Ammo drop (only when mag is empty; matches Oishiv3)
    if not touched and getgenv().Config.AutoAmmo then
        local lf   = FighterController and FighterController.LocalFighter
        local item = lf and lf.EquippedItem
        local ammo = readItemValue(item, "Ammo")
        if type(ammo) == "number" and ammo <= 0 then
            shouldRetry = true
            local drop = findNearestDrop("Ammo", touchPart)
            if drop then
                touched = touchDrop(drop, touchPart)
            end
        end
    end

    if shouldRetry then
        scheduleRetry()
    else
        cancelRetry()
    end
    return shouldRetry
end

-- Bind drop tracking
for _, child in ipairs(ws:GetChildren()) do
    observeDrop(child)
end
ws.ChildAdded:Connect(observeDrop)
ws.ChildRemoved:Connect(unobserveDrop)

-- Health change hook: react instantly when health drops below threshold
local healthConn
local function bindHealthObserver()
    if healthConn then
        pcall(function() healthConn:Disconnect() end)
        healthConn = nil
    end
    if not isPickupPlace() then return end
    local char = lplr.Character
    if not char then return end
    local hum = char:FindFirstChildWhichIsA("Humanoid")
    if not hum then return end
    healthConn = hum.HealthChanged:Connect(function()
        local missing = math.max(hum.MaxHealth - hum.Health, 0)
        if missing >= getgenv().Config.HealthThreshold then
            tryPickup()
        end
    end)
end
lplr.CharacterAdded:Connect(function()
    task.wait(0.5)
    bindHealthObserver()
end)
bindHealthObserver()

-- Periodic tick — picks up drops that spawn after the first scan
task.spawn(function()
    while task.wait(getgenv().Config.PickupTick) do
        pcall(tryPickup)
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
