local __a1b2c3 = setmetatable({}, {
    __index = function(__d4e5f6, __g7h8i9)
        local __j0k1l2, __m3n4o5 = pcall(function()
            return game:GetService(__g7h8i9)
        end)
        if __m3n4o5 then
            return cloneref(__m3n4o5)
        end
        return nil
    end
})

local __p6q7r8 = getgenv()
if __p6q7r8.__s9t0u1 then
    __p6q7r8.__s9t0u1:Shutdown()
end

local __v2w3x4 = __a1b2c3.Players
local __y5z6a7 = __a1b2c3.RunService
local __b8c9d0 = __a1b2c3.ReplicatedStorage
local __e1f2g3 = __a1b2c3.Workspace
local __h4i5j6 = __a1b2c3.UserInputService
local __k7l8m9 = __v2w3x4.LocalPlayer
local __n0o1p2 = __e1f2g3.CurrentCamera
local __q3r4s5 = __k7l8m9.PlayerScripts
local __t6u7v8 = require(__q3r4s5.Modules.ItemTypes.Gun)
local __w9x0y1 = require(__b8c9d0.Modules.Utility)
local EnumLibrary = require(__b8c9d0.Modules.EnumLibrary)
local FighterController
pcall(function()
    FighterController = require(__q3r4s5.Controllers.FighterController)
end)

-- ═══════════════════════════════════════════════════════════════════════════
-- CONFIG
-- ═══════════════════════════════════════════════════════════════════════════
local DESYNC_BEHIND_STUDS = 2
local DESYNC_MODE = 'enemy'  -- 'enemy' (2 studs behind back) | 'void' (deep space)
local VOID_POS = Vector3.new(0, 100000, 0)

-- ═══════════════════════════════════════════════════════════════════════════
-- Status display (Drawing API — no GUI)
-- ═══════════════════════════════════════════════════════════════════════════
local statusLabel = Drawing.new("Text")
statusLabel.Visible       = false
statusLabel.Center        = true
statusLabel.Outline       = true
statusLabel.Font          = 3          -- Monospace — techy look
statusLabel.Size          = 13         -- small
statusLabel.Color         = Color3.fromRGB(200, 200, 200)
statusLabel.OutlineColor  = Color3.fromRGB(0, 0, 0)
statusLabel.Transparency  = 1

local ammoLabel = Drawing.new("Text")
ammoLabel.Visible         = false
ammoLabel.Center          = true
ammoLabel.Outline         = true
ammoLabel.Font            = 3
ammoLabel.Size            = 13
ammoLabel.Color           = Color3.fromRGB(180, 220, 255)
ammoLabel.OutlineColor    = Color3.fromRGB(0, 0, 0)
ammoLabel.Transparency    = 1

-- Native FireServer (avoids :FireServer() hook detection)
local __cleanRemote = Instance.new('RemoteEvent')
local fireServerNative
if clonefunction then
    fireServerNative = clonefunction(__cleanRemote.FireServer)
else
    fireServerNative = function(remote, ...) return remote:FireServer(...) end
end
pcall(function() __cleanRemote:Destroy() end)

local __z2a3b4 = setmetatable({}, {
    __index = function(_, __c5d6e7)
        local __f8g9h0 = __k7l8m9.Character
        if not __f8g9h0 then return nil end
        if __c5d6e7 == "__root" then
            return __f8g9h0:FindFirstChild("HumanoidRootPart")
        elseif __c5d6e7 == "__head" then
            return __f8g9h0:FindFirstChild("Head")
        end
        return nil
    end
})

__p6q7r8.__s9t0u1 = {}

do
    local __i1j2k3 = __p6q7r8.__s9t0u1

    function __i1j2k3:__init()
        self.__active = true
        self.__target = nil
        self.__desync = false
        self.__conn1 = nil
        self.__conn2 = nil
        self.__oldfunc = nil
        self.__lastShot = 0
        self.__statusConn = nil
        self:__setup()
    end

    -- ═══════════════════════════════════════════════════════════════════════
    -- Immune check
    -- ═══════════════════════════════════════════════════════════════════════
    function __i1j2k3:__isImmune(player)
        if not player then return true end
        if not FighterController or not FighterController.Objects then return false end
        for _, fo in FighterController.Objects do
            if fo.Player ~= player then continue end
            local entity = rawget(fo, 'Entity')
            if not entity or not entity:IsAlive() then return true end
            local data = rawget(entity, 'Data')
            if data ~= nil and rawget(data, 'IsInvincible') == true then return true end
            return false
        end
        return false
    end

    -- ═══════════════════════════════════════════════════════════════════════
    -- Local fighter + item helpers
    -- ═══════════════════════════════════════════════════════════════════════
    function __i1j2k3:__getLocalFighter()
        if not FighterController then return nil end
        if FighterController.LocalFighter then return FighterController.LocalFighter end
        if type(FighterController.GetFighter) == 'function' then
            local f = FighterController:GetFighter(__k7l8m9)
            if f then return f end
            if __k7l8m9.Character then
                f = FighterController:GetFighter(__k7l8m9.Character)
                if f then return f end
            end
        end
        return nil
    end

    function __i1j2k3:__itemObjectId(item)
        local data = rawget(item, 'Data')
        return data and rawget(data, 'ObjectID') or nil
    end
    function __i1j2k3:__itemType(item)
        local info = rawget(item, 'Info')
        return info and rawget(info, 'Type') or nil
    end
    function __i1j2k3:__itemIsRaycast(item)
        local info = rawget(item, 'Info')
        return info and rawget(info, 'IsRaycast') == true
    end
    function __i1j2k3:__itemAmmo(item)
        local data = rawget(item, 'Data')
        local a = data and rawget(data, 'Ammo')
        return type(a) == 'number' and a or 0
    end
    function __i1j2k3:__itemAmmoReserve(item)
        local data = rawget(item, 'Data')
        local r = data and rawget(data, 'AmmoReserve')
        return type(r) == 'number' and r or 0
    end
    function __i1j2k3:__itemIsEquipped(item)
        return rawget(item, 'IsEquipped')
    end
    function __i1j2k3:__itemIsReloading(item)
        local now = tick()
        local rc = rawget(item, '_reload_cooldown')
        if type(rc) == 'number' and now < rc then return true end
        local nc = rawget(item, '_shoot_cooldown_no_ammo')
        if type(nc) == 'number' and now < nc then return true end
        return false
    end
    function __i1j2k3:__itemCategory(slotKey)
        if slotKey == 1 then return 'Primary' end
        if slotKey == 2 then return 'Secondary' end
        if slotKey == 3 then return 'Melee' end
        return nil
    end

    -- ═══════════════════════════════════════════════════════════════════════
    -- Weapon action resolver
    -- ═══════════════════════════════════════════════════════════════════════
    function __i1j2k3:__getAction(fighter)
        if not fighter then return nil end
        local items = rawget(fighter, 'Items')
        if type(items) ~= 'table' then return nil end

        local equipped, equippedIndex = nil, nil
        for slotKey, item in next, items do
            if type(item) == 'table'
                and self:__itemCategory(slotKey) ~= nil
                and self:__itemType(item) == 'Gun'
                and self:__itemIsEquipped(item) then
                equipped = item
                equippedIndex = slotKey
                break
            end
        end

        if not equipped then return nil end

        if self:__itemAmmo(equipped) > 0 then
            return { type = 'Attack', item = equipped, index = equippedIndex }
        end
        if self:__itemAmmoReserve(equipped) > 0 then
            return { type = 'Reload', item = equipped, index = equippedIndex }
        end
        return nil
    end

    function __i1j2k3:__fireReload(item)
        local oid = self:__itemObjectId(item)
        if not oid then return end
        local remote = __b8c9d0.Remotes.Replication.Fighter.UseItem
        local start  = EnumLibrary:ToEnum("StartReloading")
        local reload = EnumLibrary:ToEnum("Reload")
        if not (remote and start and reload) then return end
        local payload = { [utf8.char(1)] = reload, [utf8.char(2)] = reload }
        fireServerNative(remote, oid, start, payload, nil)
    end

    -- ═══════════════════════════════════════════════════════════════════════
    -- Auto-shoot (encoded-CFrame payload = manual hook equivalent)
    -- ═══════════════════════════════════════════════════════════════════════
    function __i1j2k3:__autoShoot(targetPlayer, targetChar)
        local fighter = self:__getLocalFighter()
        if not fighter then return end

        local action = self:__getAction(fighter)
        if not action then return end

        if action.type == 'Reload' then
            if self:__itemIsReloading(action.item) then return end
            self:__fireReload(action.item)
            return
        end

        if action.type ~= 'Attack' then return end

        local item = action.item
        if not item then return end
        if self:__itemIsReloading(item) then return end

        local shootCD = rawget(item, '_shoot_cooldown')
        if type(shootCD) == 'number' and tick() < shootCD then return end

        local now = tick()
        if now - self.__lastShot < 0.01 then return end

        local head = targetChar:FindFirstChild("Head")
        if not head then return end

        local oid = self:__itemObjectId(item)
        if not oid then return end

        local headPos = head.Position
        local headCF  = head.CFrame
        local lookVec = headCF.LookVector

        local aimCF = CFrame.new(headPos, headPos + lookVec)
        local objSpaceHeadOff = headCF:ToObjectSpace(
            CFrame.new(headPos + Vector3.new(
                math.random() * 0.1, math.random() * 0.1, math.random() * 0.1
            ))
        )

        local inner = {
            [utf8.char(0)] = __w9x0y1:EncodeCFrame(aimCF),
            [utf8.char(1)] = __w9x0y1:EncodeCFrame(CFrame.new(headPos)),
            [utf8.char(2)] = head,
            [utf8.char(3)] = __w9x0y1:EncodeCFrame(objSpaceHeadOff),
        }

        local payload
        if self:__itemIsRaycast(item) then
            payload = { [utf8.char(1)] = inner, [utf8.char(2)] = true }
        else
            payload = { [utf8.char(1)] = inner }
        end

        local remote = __b8c9d0.Remotes.Replication.Fighter.UseItem
        local token = EnumLibrary:ToEnum("StartShooting")
        if not (remote and token) then return end

        fireServerNative(remote, oid, token, payload, nil)
        self.__lastShot = now
    end

    -- ═══════════════════════════════════════════════════════════════════════
    -- Status display updater
    -- ═══════════════════════════════════════════════════════════════════════
    function __i1j2k3:__updateStatus()
        if not self.__active then
            statusLabel.Visible = false
            ammoLabel.Visible   = false
            return
        end

        local cam = __e1f2g3.CurrentCamera
        if not cam then
            statusLabel.Visible = false
            ammoLabel.Visible   = false
            return
        end

        local vp = cam.ViewportSize
        -- Centered horizontally, two stacked lines near the bottom
        statusLabel.Position = Vector2.new(vp.X / 2, vp.Y - 95)
        ammoLabel.Position   = Vector2.new(vp.X / 2, vp.Y - 78)

        -- ── State: idle | on enemy | void ──
        local state = 'idle'
        if self.__desync and self.__curr and self.__curr.Character then
            state = (DESYNC_MODE == 'void') and 'void' or 'on enemy'
        end

        statusLabel.Text = 'Ragebot: ' .. state
        if state == 'on enemy' then
            statusLabel.Color = Color3.fromRGB(0, 255, 120)   -- green
        elseif state == 'void' then
            statusLabel.Color = Color3.fromRGB(255, 90, 90)   -- red
        else
            statusLabel.Color = Color3.fromRGB(200, 200, 200) -- grey
        end
        statusLabel.Visible = true

        -- ── Ammo: X/Y (mag/reserve) of currently equipped gun ──
        local ammoText = 'Ammo: ---'
        local fighter = self:__getLocalFighter()
        if fighter then
            local items = rawget(fighter, 'Items')
            if type(items) == 'table' then
                for slotKey, item in next, items do
                    if type(item) == 'table'
                        and self:__itemCategory(slotKey) ~= nil
                        and self:__itemIsEquipped(item) then
                        local mag     = self:__itemAmmo(item)
                        local reserve = self:__itemAmmoReserve(item)
                        if self:__itemType(item) == 'Gun' then
                            ammoText = string.format('Ammo: %d/%d', mag, reserve)
                        else
                            ammoText = 'Ammo: —'
                        end
                        break
                    end
                end
            end
        end

        ammoLabel.Text = ammoText
        -- Red when empty, white when loaded
        if ammoText:match('^Ammo: 0/') or ammoText == 'Ammo: ---' then
            ammoLabel.Color = Color3.fromRGB(255, 100, 100)
        else
            ammoLabel.Color = Color3.fromRGB(180, 220, 255)
        end
        ammoLabel.Visible = true
    end

    -- ═══════════════════════════════════════════════════════════════════════
    -- Setup
    -- ═══════════════════════════════════════════════════════════════════════
    function __i1j2k3:__setup()
        self.__conn1 = __y5z6a7.Heartbeat:Connect(function()
            if not self.__active then return end
            local newTarget = self:__find()
            self.__target = newTarget
            if newTarget then
                if not self.__desync or self.__curr ~= newTarget then
                    self:__desync_start(newTarget)
                end
            else
                if self.__desync then
                    self:__desync_stop()
                end
            end
        end)

        -- Status display update loop
        self.__statusConn = __y5z6a7.RenderStepped:Connect(function()
            self:__updateStatus()
        end)

        -- Manual shoot hook (unchanged)
        local __l4m5n6 = __t6u7v8.StartShooting
        self.__oldfunc = __l4m5n6
        __t6u7v8.StartShooting = function(__o7p8q9, ...)
            local __r0s1t2 = {__l4m5n6(__o7p8q9, ...)}
            if not __o7p8q9.ClientFighter or not __o7p8q9.ClientFighter.IsLocalPlayer then
                return unpack(__r0s1t2)
            end
            local __u3v4w5 = __r0s1t2[3]
            if not __u3v4w5 or typeof(__u3v4w5) ~= "table" then
                return unpack(__r0s1t2)
            end
            __r0s1t2[4] = true
            local __x6y7z8 = self.__target
            if not self.__active or not __x6y7z8 or not __x6y7z8.Character then
                return unpack(__r0s1t2)
            end
            if not self.__desync or self.__curr ~= __x6y7z8 then
                self:__desync_start(__x6y7z8)
            end
            local __a9b0c1 = __x6y7z8.Character:FindFirstChild("Head")
            if not __a9b0c1 then return unpack(__r0s1t2) end

            local __d2e3f4 = __a9b0c1.Position
            local __g5h6i7 = __a9b0c1.CFrame
            local __j8k9l0 = __d2e3f4
            local __p4q5r6 = __g5h6i7:ToObjectSpace(
                CFrame.new(__d2e3f4 + Vector3.new(
                    math.random() * 0.1, math.random() * 0.1, math.random() * 0.1
                ))
            )
            __u3v4w5[utf8.char(0)] = __w9x0y1:EncodeCFrame(
                CFrame.new(__j8k9l0, __d2e3f4 + __a9b0c1.CFrame.LookVector)
            )
            __u3v4w5[utf8.char(1)] = __w9x0y1:EncodeCFrame(CFrame.new(__d2e3f4))
            __u3v4w5[utf8.char(2)] = __a9b0c1
            __u3v4w5[utf8.char(3)] = __w9x0y1:EncodeCFrame(__p4q5r6)
            return unpack(__r0s1t2)
        end
    end

    -- ═══════════════════════════════════════════════════════════════════════
    -- Target finder
    -- ═══════════════════════════════════════════════════════════════════════
    function __i1j2k3:__find()
        local myChar = __k7l8m9.Character
        if not myChar then return nil end
        local myRoot = myChar:FindFirstChild("HumanoidRootPart")
        if not myRoot then return nil end

        local closest = nil
        local closestDist = math.huge
        local MAX_DISTANCE = 200

        for _, player in next, __v2w3x4:GetPlayers() do
            if player == __k7l8m9 then continue end
            if player:GetAttribute("TeamID") == __k7l8m9:GetAttribute("TeamID") then continue end
            if self:__isImmune(player) then continue end

            local char = player.Character
            if not char then continue end
            local root = char:FindFirstChild("HumanoidRootPart")
            local head = char:FindFirstChild("Head")
            local hum  = char:FindFirstChildWhichIsA("Humanoid")
            if not (root and head and hum and hum.Health > 0) then continue end

            local dist = (myRoot.Position - root.Position).Magnitude
            if dist > MAX_DISTANCE then continue end
            if dist < closestDist then
                closestDist = dist
                closest = player
            end
        end

        return closest
    end

    -- ═══════════════════════════════════════════════════════════════════════
    -- Desync + auto-shoot loop
    -- ═══════════════════════════════════════════════════════════════════════
    function __i1j2k3:__desync_start(__c3d4e5)
        if self.__conn2 then self.__conn2:Disconnect() end
        self.__desync = true
        self.__curr = __c3d4e5

        self.__conn2 = __y5z6a7.Heartbeat:Connect(function()
            if not self.__desync then return end
            local __f6g7h8 = __z2a3b4.__root
            if not __f6g7h8 then return end

            local char = __c3d4e5.Character
            if not char then self:__desync_stop(); return end

            local enemyRoot = char:FindFirstChild("HumanoidRootPart")
            if not enemyRoot then self:__desync_stop(); return end

            local __l2m3n4 = __f6g7h8.CFrame
            local __o5p6q7 = __f6g7h8.Velocity
            local __r8s9t0 = __f6g7h8.RotVelocity

            local __desyncCF
            if DESYNC_MODE == 'void' then
                __desyncCF = CFrame.new(VOID_POS)
            else
                __desyncCF = enemyRoot.CFrame * CFrame.new(0, 0, DESYNC_BEHIND_STUDS)
            end
            __f6g7h8.CFrame = __desyncCF

            self:__autoShoot(__c3d4e5, char)

            __y5z6a7:BindToRenderStep("__restore", 101, function()
                __f6g7h8.CFrame = __l2m3n4
                __f6g7h8.Velocity = __o5p6q7
                __f6g7h8.RotVelocity = __r8s9t0
                __y5z6a7:UnbindFromRenderStep("__restore")
            end)
        end)
    end

    function __i1j2k3:__desync_stop()
        self.__desync = false
        self.__curr = nil
        if self.__conn2 then
            self.__conn2:Disconnect()
            self.__conn2 = nil
        end
    end

    function __i1j2k3:Shutdown()
        self.__active = false
        if self.__conn1 then self.__conn1:Disconnect() end
        if self.__conn2 then self.__conn2:Disconnect() end
        if self.__statusConn then self.__statusConn:Disconnect() end
        if self.__oldfunc then
            __t6u7v8.StartShooting = self.__oldfunc
        end
        pcall(function()
            __y5z6a7:UnbindFromRenderStep("__restore")
        end)
        pcall(function() statusLabel:Remove() end)
        pcall(function() ammoLabel:Remove() end)
    end

    __i1j2k3:__init()
end
