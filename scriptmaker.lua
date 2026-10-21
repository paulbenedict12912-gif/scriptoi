
-- Compact Collectible UI
-- For your own Roblox Studio experience.
-- Put in StarterPlayer > StarterPlayerScripts as a LocalScript.
--
-- Tag collectible Parts or Models with "Collectible"
-- using Studio's Tag Editor.

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local previous = playerGui:FindFirstChild("CompactCollectibleUI")
if previous then previous:Destroy() end

local gui = Instance.new("ScreenGui")
gui.Name = "CompactCollectibleUI"
gui.ResetOnSpawn = false
gui.DisplayOrder = 100
gui.Parent = playerGui

local C = {
    blue = Color3.fromRGB(48, 130, 255),
    blueDark = Color3.fromRGB(25, 75, 155),
    green = Color3.fromRGB(35, 190, 105),
    red = Color3.fromRGB(205, 60, 75),
    bg = Color3.fromRGB(22, 24, 31),
    panel = Color3.fromRGB(34, 37, 46),
    input = Color3.fromRGB(14, 16, 22),
    text = Color3.fromRGB(240, 243, 250),
    muted = Color3.fromRGB(145, 153, 171)
}

local function make(class, props, parent)
    local object = Instance.new(class)
    for key, value in pairs(props) do
        object[key] = value
    end
    object.Parent = parent
    return object
end

local function round(object, radius)
    make("UICorner", {
        CornerRadius = UDim.new(0, radius)
    }, object)
end

local function stroke(object, color, thickness)
    return make("UIStroke", {
        Color = color,
        Thickness = thickness or 1,
        Transparency = 0.2
    }, object)
end

local function animate(object, properties, duration)
    local tween = TweenService:Create(
        object,
        TweenInfo.new(duration or 0.13, Enum.EasingStyle.Quad,
            Enum.EasingDirection.Out),
        properties
    )
    tween:Play()
    return tween
end

local function createButton(parent, name, text, size, position)
    local button = make("TextButton", {
        Name = name,
        Size = size,
        Position = position,
        BackgroundColor3 = C.red,
        BorderSizePixel = 0,
        Text = text,
        TextColor3 = C.text,
        Font = Enum.Font.GothamBold,
        TextSize = 10,
        AutoButtonColor = false,
        Active = true
    }, parent)
    round(button, 5)
    local border = stroke(button, Color3.fromRGB(100, 105, 125))

    button.Activated:Connect(function()
        animate(button, {
            Size = size - UDim2.fromOffset(2, 2)
        }, 0.06)
        task.delay(0.07, function()
            if button.Parent then
                animate(button, {Size = size}, 0.1)
            end
        end)
    end)

    return button, border
end

local function setToggle(button, enabled)
    animate(button, {
        BackgroundColor3 = enabled and C.green or C.red
    }, 0.16)
end

-- Floating show/hide button
local floating = make("TextButton", {
    Name = "FloatingButton",
    Size = UDim2.fromOffset(36, 36),
    Position = UDim2.new(0, 9, 0.45, 0),
    BackgroundColor3 = C.blue,
    BorderSizePixel = 0,
    Text = "UI",
    TextColor3 = C.text,
    TextSize = 11,
    Font = Enum.Font.GothamBold,
    AutoButtonColor = false,
    Active = true
}, gui)
round(floating, 18)
stroke(floating, Color3.fromRGB(130, 180, 255), 1)

-- Compact window
local window = make("Frame", {
    Name = "Window",
    Size = UDim2.fromOffset(225, 235),
    Position = UDim2.new(0.5, -112, 0.5, -117),
    BackgroundColor3 = C.bg,
    BorderSizePixel = 0,
    ClipsDescendants = true,
    Active = true
}, gui)
round(window, 8)
stroke(window, Color3.fromRGB(75, 85, 110), 1)

-- Draggable title bar
local header = make("Frame", {
    Size = UDim2.new(1, 0, 0, 27),
    BackgroundColor3 = C.panel,
    BorderSizePixel = 0,
    Active = true
}, window)
round(header, 8)

make("TextLabel", {
    Position = UDim2.fromOffset(9, 0),
    Size = UDim2.new(1, -18, 1, 0),
    BackgroundTransparency = 1,
    Text = "COLLECTIBLE TOOL",
    TextColor3 = C.text,
    TextSize = 10,
    Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Left
}, header)

-- Scrollable editable textbox
local scroll = make("ScrollingFrame", {
    Name = "CodeScroll",
    Position = UDim2.fromOffset(7, 34),
    Size = UDim2.new(1, -14, 1, -113),
    BackgroundColor3 = C.input,
    BorderSizePixel = 0,
    ScrollBarThickness = 4,
    ScrollingDirection = Enum.ScrollingDirection.XY,
    CanvasSize = UDim2.fromOffset(0, 0),
    ElasticBehavior = Enum.ElasticBehavior.WhenScrollable,
    Active = true
}, window)
round(scroll, 5)

local codeBox = make("TextBox", {
    Name = "ScriptTextbox",
    Position = UDim2.fromOffset(4, 4),
    Size = UDim2.new(1, -8, 0, 150),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    Text = "-- Press Start, then tap a collectible.",
    PlaceholderText = "Generated code...",
    PlaceholderColor3 = C.muted,
    TextColor3 = Color3.fromRGB(170, 215, 255),
    TextSize = 10,
    Font = Enum.Font.Code,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Top,
    TextWrapped = false,
    ClearTextOnFocus = false,
    MultiLine = true,
    TextEditable = true,
    Active = true
}, scroll)

local function updateCanvas()
    local lines, longest = 0, 0
    for line in (codeBox.Text .. "\n"):gmatch("(.-)\n") do
        lines += 1
        longest = math.max(longest, #line)
    end

    local width = math.max(scroll.AbsoluteSize.X - 8, longest * 6.3 + 12)
    local height = math.max(scroll.AbsoluteSize.Y - 8, lines * 13 + 12)
    codeBox.Size = UDim2.fromOffset(width, height)
    scroll.CanvasSize = UDim2.fromOffset(width + 8, height + 8)
end

codeBox:GetPropertyChangedSignal("Text"):Connect(updateCanvas)
scroll:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateCanvas)

-- Fly row
local flyButton = createButton(
    window, "FlyButton", "FLY",
    UDim2.fromOffset(66, 27),
    UDim2.new(0, 7, 1, -70)
)

local speedBox = make("TextBox", {
    Name = "FlySpeed",
    Position = UDim2.new(0, 79, 1, -70),
    Size = UDim2.fromOffset(48, 27),
    BackgroundColor3 = C.input,
    BorderSizePixel = 0,
    Text = "50",
    PlaceholderText = "Speed",
    TextColor3 = C.text,
    TextSize = 10,
    Font = Enum.Font.Gotham,
    ClearTextOnFocus = false
}, window)
round(speedBox, 5)
stroke(speedBox, C.blueDark)

-- Bottom row
local startButton = createButton(
    window, "StartButton", "START",
    UDim2.new(0.3333, -6, 0, 28),
    UDim2.new(0, 7, 1, -36)
)

local locanButton = createButton(
    window, "LocanButton", "LOCAN",
    UDim2.new(0.3333, -6, 0, 28),
    UDim2.new(0.3333, 2, 1, -36)
)

local copyButton = createButton(
    window, "CopyButton", "COPY",
    UDim2.new(0.3333, -7, 0, 28),
    UDim2.new(0.6666, 1, 1, -36)
)

floating.Activated:Connect(function()
    window.Visible = not window.Visible
end)

-- Dragging: header only, so text scrolling still works.
local dragging = false
local dragInput, dragStart, startPosition

header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch
        or input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragInput = input
        dragStart = input.Position
        startPosition = window.Position
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and (
        input.UserInputType == Enum.UserInputType.Touch
        or input.UserInputType == Enum.UserInputType.MouseMovement
    ) then
        local delta = input.Position - dragStart
        window.Position = UDim2.new(
            startPosition.X.Scale,
            startPosition.X.Offset + delta.X,
            startPosition.Y.Scale,
            startPosition.Y.Offset + delta.Y
        )
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input == dragInput then
        dragging = false
        dragInput = nil
    end
end)

-- Selection
local selecting = false
local selectedTarget
local selectedPart
local highlight
local selectionConnection

local function clearHighlight()
    if highlight then
        highlight:Destroy()
        highlight = nil
    end
end

local function findPart(target)
    if not target or not target.Parent then return nil end
    if target:IsA("BasePart") then return target end
    if target:IsA("Model") then
        return target.PrimaryPart
            or target:FindFirstChildWhichIsA("BasePart", true)
    end
    return nil
end

local function getTaggedAncestor(part)
    local current = part
    while current and current ~= workspace do
        if CollectionService:HasTag(current, "Collectible") then
            return current
        end
        current = current.Parent
    end
    return nil
end

local function showSelection(target)
    clearHighlight()
    highlight = Instance.new("Highlight")
    highlight.Name = "SelectionHighlight"
    highlight.Adornee = target
    highlight.FillColor = C.blue
    highlight.OutlineColor = C.blue
    highlight.FillTransparency = 0.82
    highlight.OutlineTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = gui
end

local function isInsideWindow(position)
    if not window.Visible then return false end
    local p, s = window.AbsolutePosition, window.AbsoluteSize
    return position.X >= p.X and position.X <= p.X + s.X
        and position.Y >= p.Y and position.Y <= p.Y + s.Y
end

local function selectAt(position)
    local camera = workspace.CurrentCamera
    if not camera then return end

    local inset = GuiService:GetGuiInset()
    local viewportPoint = Vector2.new(position.X - inset.X, position.Y - inset.Y)
    local ray = camera:ViewportPointToRay(viewportPoint.X, viewportPoint.Y)

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {
        player.Character,
        gui
    }

    local result = workspace:Raycast(ray.Origin, ray.Direction * 1200, params)
    if not result then return end

    local hit = result.Instance
    if not hit:IsA("BasePart") then return end

    -- Prefer a tagged collectible so a model can be tracked as one item.
    local tagged = getTaggedAncestor(hit)
    selectedTarget = tagged or hit
    selectedPart = findPart(selectedTarget)

    if selectedPart then
        showSelection(selectedTarget)
    end

    -- Selection intentionally does not replace textbox text.
end

startButton.Activated:Connect(function()
    selecting = not selecting
    setToggle(startButton, selecting)

    if selectionConnection then
        selectionConnection:Disconnect()
        selectionConnection = nil
    end

    if selecting then
        selectionConnection = UserInputService.InputBegan:Connect(function(input, processed)
            if processed or not selecting then return end
            if input.UserInputType ~= Enum.UserInputType.Touch
                and input.UserInputType ~= Enum.UserInputType.MouseButton1 then
                return
            end
            if isInsideWindow(input.Position) then return end
            selectAt(input.Position)
        end)
    end
end)

-- Reacquire a tagged collectible after the original disappears.
local function findReplacement()
    if not selectedTarget then return nil end

    local oldName = selectedTarget.Name
    local oldClass = selectedTarget.ClassName
    local oldPosition

    local oldPart = findPart(selectedTarget)
    if oldPart then oldPosition = oldPart.Position end

    local best, bestDistance = nil, math.huge

    for _, item in ipairs(CollectionService:GetTagged("Collectible")) do
        if item.Parent and item.Name == oldName and item.ClassName == oldClass then
            local part = findPart(item)
            if part then
                local distance = oldPosition and (part.Position - oldPosition).Magnitude or 0
                if distance < bestDistance then
                    best = item
                    bestDistance = distance
                end
            end
        end
    end

    return best
end

local function generateCode(target)
    local part = findPart(target)
    if not part then
        return "-- The selected item has no BasePart."
    end

    return string.format([[
-- Example for your own Roblox Studio game
-- Selected item: %s
-- Tag respawning collectibles "Collectible"

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

local itemName = %q

local function findItem()
    for _, item in ipairs(CollectionService:GetTagged("Collectible")) do
        if item.Name == itemName then
            return item
        end
    end
end

local item = findItem()
if item then
    local part = item:IsA("BasePart") and item
        or item:FindFirstChildWhichIsA("BasePart", true)

    local character = player.Character or player.CharacterAdded:Wait()
    local root = character:WaitForChild("HumanoidRootPart")

    if part then
        root.CFrame = part.CFrame * CFrame.new(0, 3, 0)
    end
end
]], target:GetFullName(), target.Name)
end

locanButton.Activated:Connect(function()
    if locanButton.BackgroundColor3 == C.green then
        setToggle(locanButton, false)
        return
    end

    setToggle(locanButton, true)

    if not selectedTarget then
        codeBox.Text = "-- Press Start and select an item first."
    else
        codeBox.Text = generateCode(selectedTarget)
    end

    scroll.CanvasPosition = Vector2.zero
    updateCanvas()
end)

copyButton.Activated:Connect(function()
    local enabled = copyButton.BackgroundColor3 ~= C.green
    setToggle(copyButton, enabled)

    -- Ordinary Roblox LocalScripts do not expose a clipboard API.
    codeBox:CaptureFocus()
    codeBox.CursorPosition = 1
    codeBox.SelectionStart = #codeBox.Text + 1
end)

-- Fly toward selected target.
-- Collision is not disabled here: noclip is game-specific and should
-- be implemented with server-authorized movement in your own experience.
local flyEnabled = false
local flyConnection
local flySpeed = 50

local function stopFly()
    flyEnabled = false
    setToggle(flyButton, false)

    if flyConnection then
        flyConnection:Disconnect()
        flyConnection = nil
    end
end

speedBox.FocusLost:Connect(function()
    local number = tonumber(speedBox.Text)
    if number then
        flySpeed = math.clamp(number, 1, 200)
    end
    speedBox.Text = tostring(flySpeed)
end)

flyButton.Activated:Connect(function()
    if flyEnabled then
        stopFly()
        return
    end

    if not selectedTarget then
        codeBox.Text = "-- Select an item with Start first."
        updateCanvas()
        return
    end

    local number = tonumber(speedBox.Text)
    if number then
        flySpeed = math.clamp(number, 1, 200)
    end
    speedBox.Text = tostring(flySpeed)

    flyEnabled = true
    setToggle(flyButton, true)

    flyConnection = RunService.Heartbeat:Connect(function(dt)
        if not flyEnabled then return end

        local target = selectedTarget
        if not target or not target.Parent then
            target = findReplacement()
            if target then
                selectedTarget = target
                selectedPart = findPart(target)
                showSelection(target)
            else
                -- Stay enabled while waiting for the tagged item to respawn.
                return
            end
        end

        local part = findPart(target)
        local character = player.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")

        if not part or not root then return end

        local destination = part.Position + Vector3.new(0, 3, 0)
        local delta = destination - root.Position
        local distance = delta.Magnitude

        if distance > 2 then
            local step = math.min(distance, flySpeed * dt)
            root.CFrame = CFrame.new(
                root.Position + delta.Unit * step,
                destination
            )
        end
    end)
end)

player.CharacterAdded:Connect(function()
    stopFly()
end)

-- Responsive window size
local function resize()
    local camera = workspace.CurrentCamera
    if not camera then return end

    local viewport = camera.ViewportSize
    local width = math.min(225, viewport.X - 18)
    local height = math.min(235, viewport.Y - 40)

    window.Size = UDim2.fromOffset(width, height)
    window.Position = UDim2.new(0.5, -width / 2, 0.5, -height / 2)
    updateCanvas()
end

resize()

local function bindCamera(camera)
    if camera then
        camera:GetPropertyChangedSignal("ViewportSize"):Connect(resize)
    end
end

bindCamera(workspace.CurrentCamera)
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    bindCamera(workspace.CurrentCamera)
    resize()
end)
