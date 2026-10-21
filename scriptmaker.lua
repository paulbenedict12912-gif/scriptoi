
-- Mobile Block Selector UI + Fly
-- Place in StarterPlayer > StarterPlayerScripts as a LocalScript
-- For your own Roblox Studio experience.

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local old = playerGui:FindFirstChild("MobileBlockUI")
if old then old:Destroy() end

local gui = Instance.new("ScreenGui")
gui.Name = "MobileBlockUI"
gui.ResetOnSpawn = false
gui.DisplayOrder = 100
gui.Parent = playerGui

local function make(className, props, parent)
    local object = Instance.new(className)
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

local BLUE = Color3.fromRGB(45, 125, 255)
local GREEN = Color3.fromRGB(35, 180, 85)
local RED = Color3.fromRGB(200, 55, 65)
local DARK = Color3.fromRGB(25, 27, 33)
local PANEL = Color3.fromRGB(38, 41, 49)
local WHITE = Color3.fromRGB(245, 245, 250)

local function makeButton(parent, name, text, position, size)
    local button = make("TextButton", {
        Name = name,
        Position = position,
        Size = size,
        BackgroundColor3 = RED,
        BorderSizePixel = 0,
        Text = text,
        TextColor3 = WHITE,
        TextSize = 11,
        Font = Enum.Font.GothamBold,
        AutoButtonColor = true,
        Active = true
    }, parent)
    round(button, 5)
    return button
end

-- Floating show/hide button
local floating = make("TextButton", {
    Name = "FloatingButton",
    Position = UDim2.new(0, 12, 0.45, 0),
    Size = UDim2.fromOffset(44, 44),
    BackgroundColor3 = BLUE,
    BorderSizePixel = 0,
    Text = "UI",
    TextColor3 = WHITE,
    TextSize = 14,
    Font = Enum.Font.GothamBold,
    Active = true
}, gui)
round(floating, 22)

-- Main window
local window = make("Frame", {
    Name = "MainWindow",
    Size = UDim2.fromOffset(260, 290),
    Position = UDim2.new(0.5, -130, 0.5, -145),
    BackgroundColor3 = DARK,
    BorderSizePixel = 0,
    Active = true,
    ClipsDescendants = true
}, gui)
round(window, 8)

-- Header
local header = make("Frame", {
    Name = "Header",
    Size = UDim2.new(1, 0, 0, 32),
    BackgroundColor3 = PANEL,
    BorderSizePixel = 0,
    Active = true
}, window)
round(header, 8)

make("TextLabel", {
    Position = UDim2.fromOffset(10, 0),
    Size = UDim2.new(1, -20, 1, 0),
    BackgroundTransparency = 1,
    Text = "Block Selector",
    TextColor3 = WHITE,
    TextSize = 12,
    Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Left
}, header)

-- Scrollable code textbox
local scroll = make("ScrollingFrame", {
    Name = "CodeScroll",
    Position = UDim2.fromOffset(8, 40),
    Size = UDim2.new(1, -16, 1, -137),
    BackgroundColor3 = Color3.fromRGB(16, 18, 23),
    BorderSizePixel = 0,
    ScrollBarThickness = 6,
    ScrollingDirection = Enum.ScrollingDirection.XY,
    CanvasSize = UDim2.fromOffset(0, 0),
    ElasticBehavior = Enum.ElasticBehavior.WhenScrollable,
    Active = true,
    ClipsDescendants = true
}, window)
round(scroll, 5)

local codeBox = make("TextBox", {
    Name = "ScriptTextbox",
    Position = UDim2.fromOffset(5, 5),
    Size = UDim2.new(1, -10, 0, 220),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    Text = "-- Tap Start, then select a block.",
    PlaceholderText = "-- Generated code appears here",
    PlaceholderColor3 = Color3.fromRGB(125, 130, 145),
    TextColor3 = Color3.fromRGB(190, 220, 255),
    TextSize = 11,
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
    local lines = 1
    local longest = 0

    for line in (codeBox.Text .. "\n"):gmatch("(.-)\n") do
        lines += 1
        longest = math.max(longest, #line)
    end

    local wantedHeight = math.max(
        scroll.AbsoluteSize.Y - 10,
        lines * 15 + 12
    )
    local wantedWidth = math.max(
        scroll.AbsoluteSize.X - 10,
        longest * 7 + 15
    )

    codeBox.Size = UDim2.fromOffset(wantedWidth, wantedHeight)
    scroll.CanvasSize = UDim2.fromOffset(
        wantedWidth + 10,
        wantedHeight + 10
    )
end

codeBox:GetPropertyChangedSignal("Text"):Connect(updateCanvas)
scroll:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateCanvas)

-- Fly row: button and speed textbox side by side
local flyButton = makeButton(
    window,
    "FlyButton",
    "Fly",
    UDim2.new(0, 8, 1, -87),
    UDim2.fromOffset(78, 30)
)

local speedBox = make("TextBox", {
    Name = "FlySpeed",
    Position = UDim2.new(0, 92, 1, -87),
    Size = UDim2.fromOffset(78, 30),
    BackgroundColor3 = Color3.fromRGB(17, 19, 24),
    BorderSizePixel = 0,
    Text = "50",
    PlaceholderText = "Speed",
    TextColor3 = WHITE,
    PlaceholderColor3 = Color3.fromRGB(125, 130, 145),
    TextSize = 11,
    Font = Enum.Font.Gotham,
    ClearTextOnFocus = false
}, window)
round(speedBox, 5)

-- Bottom row
local startButton = makeButton(
    window, "StartButton", "Start",
    UDim2.new(0, 8, 1, -45),
    UDim2.new(0.3333, -8, 0, 33)
)

local locanButton = makeButton(
    window, "LocanButton", "Locan",
    UDim2.new(0.3333, 1, 1, -45),
    UDim2.new(0.3333, -8, 0, 33)
)

local copyButton = makeButton(
    window, "CopyButton", "Copy",
    UDim2.new(0.6666, 2, 1, -45),
    UDim2.new(0.3333, -10, 0, 33)
)

local function setToggle(button, enabled)
    button.BackgroundColor3 = enabled and GREEN or RED
end

floating.Activated:Connect(function()
    window.Visible = not window.Visible
end)

-- Drag window from header only
local dragging = false
local dragInput
local dragStart
local windowStart

header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragInput = input
        dragStart = input.Position
        windowStart = window.Position
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and (
        input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch
    ) then
        local delta = input.Position - dragStart

        window.Position = UDim2.new(
            windowStart.X.Scale,
            windowStart.X.Offset + delta.X,
            windowStart.Y.Scale,
            windowStart.Y.Offset + delta.Y
        )
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input == dragInput then
        dragging = false
        dragInput = nil
    end
end)

-- Target selection
local selecting = false
local selectedPart
local selectedTarget
local highlight
local inputConnection

local function clearHighlight()
    if highlight then
        highlight:Destroy()
        highlight = nil
    end
end

local function getTargetFromPart(part)
    local model = part:FindFirstAncestorOfClass("Model")

    if model and model ~= player.Character then
        return model
    end

    return part
end

local function findTargetPart(target)
    if not target then return nil end

    if target:IsA("BasePart") then
        return target
    elseif target:IsA("Model") then
        return target.PrimaryPart
            or target:FindFirstChildWhichIsA("BasePart", true)
    end

    return nil
end

local function makeHighlight(target)
    clearHighlight()

    highlight = Instance.new("Highlight")
    highlight.Name = "BlockSelectionHighlight"
    highlight.Adornee = target
    highlight.FillColor = BLUE
    highlight.OutlineColor = BLUE
    highlight.FillTransparency = 0.82
    highlight.OutlineTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = gui
end

local function selectAtScreenPosition(screenPosition)
    local camera = workspace.CurrentCamera
    if not camera then return end

    local inset = GuiService:GetGuiInset()
    local viewportPosition = Vector2.new(
        screenPosition.X - inset.X,
        screenPosition.Y - inset.Y
    )

    local ray = camera:ViewportPointToRay(
        viewportPosition.X,
        viewportPosition.Y
    )

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude

    local excluded = {gui}
    if player.Character then
        table.insert(excluded, player.Character)
    end
    params.FilterDescendantsInstances = excluded
    params.IgnoreWater = true

    local result = workspace:Raycast(
        ray.Origin,
        ray.Direction * 1500,
        params
    )

    if not result or not result.Instance:IsA("BasePart") then
        return
    end

    selectedPart = result.Instance
    selectedTarget = getTargetFromPart(selectedPart)
    makeHighlight(selectedTarget)

    -- Selection does not modify the textbox.
end

startButton.Activated:Connect(function()
    selecting = not selecting
    setToggle(startButton, selecting)

    if inputConnection then
        inputConnection:Disconnect()
        inputConnection = nil
    end

    if not selecting then return end

    inputConnection = UserInputService.InputBegan:Connect(function(input, processed)
        if not selecting or processed then return end

        if input.UserInputType ~= Enum.UserInputType.Touch
            and input.UserInputType ~= Enum.UserInputType.MouseButton1 then
            return
        end

        if window.Visible then
            local p = input.Position
            local pos = window.AbsolutePosition
            local size = window.AbsoluteSize

            if p.X >= pos.X and p.X <= pos.X + size.X
                and p.Y >= pos.Y and p.Y <= pos.Y + size.Y then
                return
            end
        end

        selectAtScreenPosition(input.Position)
    end)
end)

-- Generate teleport example for selected target
local function generateCode(target)
    local part = findTargetPart(target)
    if not part then
        return "-- Selected target has no BasePart."
    end

    return string.format([[
-- Generated example for your own Roblox Studio experience
local targetName = %q
local partName = %q

local target = workspace:FindFirstChild(targetName, true)

if target then
    local part

    if target:IsA("BasePart") then
        part = target
    elseif target:IsA("Model") then
        part = target.PrimaryPart
            or target:FindFirstChild(partName, true)
    end

    if part and part:IsA("BasePart") then
        local player = game:GetService("Players").LocalPlayer
        local character = player.Character
            or player.CharacterAdded:Wait()
        local root = character:WaitForChild("HumanoidRootPart")

        root.CFrame = part.CFrame * CFrame.new(0, 3, 0)
    end
end
]], target.Name, part.Name)
end

locanButton.Activated:Connect(function()
    local enabled = locanButton.BackgroundColor3 ~= GREEN
    setToggle(locanButton, enabled)

    if not enabled then return end

    if not selectedTarget or not selectedTarget.Parent then
        codeBox.Text = "-- No valid target selected.\n-- Press Start, then tap a block or coin."
    else
        codeBox.Text = generateCode(selectedTarget)
    end

    scroll.CanvasPosition = Vector2.new(0, 0)
    updateCanvas()
end)

-- Copy button: Roblox LocalScripts have no standard clipboard API.
copyButton.Activated:Connect(function()
    local enabled = copyButton.BackgroundColor3 ~= GREEN
    setToggle(copyButton, enabled)

    codeBox:CaptureFocus()
    codeBox.CursorPosition = 1
    codeBox.SelectionStart = #codeBox.Text + 1
end)

-- Fly toward selected target
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
    local value = tonumber(speedBox.Text)

    if value then
        flySpeed = math.clamp(value, 1, 200)
    end

    speedBox.Text = tostring(flySpeed)
end)

flyButton.Activated:Connect(function()
    if flyEnabled then
        stopFly()
        return
    end

    if not selectedTarget or not selectedTarget.Parent then
        codeBox.Text = "-- Select a block first using Start."
        updateCanvas()
        return
    end

    local speed = tonumber(speedBox.Text)
    if speed then
        flySpeed = math.clamp(speed, 1, 200)
    end
    speedBox.Text = tostring(flySpeed)

    local target = selectedTarget
    local targetPart = findTargetPart(target)
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")

    if not targetPart or not root then
        codeBox.Text = "-- Target or character is not ready."
        updateCanvas()
        return
    end

    flyEnabled = true
    setToggle(flyButton, true)

    flyConnection = RunService.Heartbeat:Connect(function(dt)
        if not flyEnabled then return end

        if not target.Parent or not root.Parent then
            stopFly()
            return
        end

        local currentPart = findTargetPart(target)
        if not currentPart then
            stopFly()
            return
        end

        local destination = currentPart.Position + Vector3.new(0, 3, 0)
        local offset = destination - root.Position
        local distance = offset.Magnitude

        if distance < 2 then
            stopFly()
            return
        end

        local step = math.min(distance, flySpeed * dt)
        root.CFrame = CFrame.new(
            root.Position + offset.Unit * step,
            destination
        )
    end)
end)

player.CharacterAdded:Connect(function()
    stopFly()
end)

-- Responsive layout
local function resize()
    local camera = workspace.CurrentCamera
    if not camera then return end

    local viewport = camera.ViewportSize
    local width = math.min(260, math.max(200, viewport.X - 24))
    local height = math.min(290, math.max(245, viewport.Y - 50))

    window.Size = UDim2.fromOffset(width, height)
    window.Position = UDim2.new(
        0.5, -width / 2,
        0.5, -height / 2
    )

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
