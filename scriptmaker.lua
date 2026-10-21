-- Language: Luau
-- File: HalloweenCandyCollector.client.lua
-- Target: Roblox Studio game you control

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local enabled = false
local speed = 55

local function getCharacter()
    local character = player.Character
    if not character then return end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local root = character:FindFirstChild("HumanoidRootPart")

    if humanoid and root then
        return character, humanoid, root
    end
end

local function findCandy()
    local character = player.Character
    if not character then return nil end

    local root = character:FindFirstChild("HumanoidRootPart")
    if not root then return nil end

    local nearest, nearestDistance

    for _, item in workspace:GetDescendants() do
        if item:IsA("BasePart")
            and (item.Name:lower():find("candy")
                or item.Name:lower():find("cane")) then

            local distance = (item.Position - root.Position).Magnitude

            if not nearestDistance or distance < nearestDistance then
                nearest = item
                nearestDistance = distance
            end
        end
    end

    return nearest
end

local function flyToCandy(target)
    local character, humanoid, root = getCharacter()
    if not character or not target then return end

    humanoid:ChangeState(Enum.HumanoidStateType.Physics)

    local attachment = Instance.new("Attachment")
    attachment.Parent = root

    local velocity = Instance.new("LinearVelocity")
    velocity.Attachment0 = attachment
    velocity.MaxForce = math.huge
    velocity.RelativeTo = Enum.ActuatorRelativeTo.World
    velocity.Parent = root

    local connection
    connection = RunService.Heartbeat:Connect(function()
        if not enabled or not target.Parent or not root.Parent then
            connection:Disconnect()
            velocity:Destroy()
            attachment:Destroy()
            return
        end

        local direction = target.Position - root.Position

        if direction.Magnitude < 4 then
            connection:Disconnect()
            velocity:Destroy()
            attachment:Destroy()
            return
        end

        velocity.VectorVelocity = direction.Unit * speed
    end)
end

-- Call this from your own GUI toggle.
local function toggleAutoFarm()
    enabled = not enabled

    if enabled then
        task.spawn(function()
            while enabled do
                local candy = findCandy()

                if candy then
                    flyToCandy(candy)
                    repeat
                        task.wait(0.15)
                    until not enabled
                        or not candy.Parent
                        or (getCharacter()
                            and (candy.Position
                                - select(3, getCharacter()).Position).Magnitude < 4)
                else
                    task.wait(0.5)
                end

                task.wait(0.2)
            end
        end)
    end
end
