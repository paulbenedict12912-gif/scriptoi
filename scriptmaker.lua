
-- Mobile Block Selector UI
-- Place in StarterPlayer > StarterPlayerScripts as a LocalScript
-- Intended for your own Roblox Studio experience.

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

-- Floating UI toggle
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
    Size = UDim2.fromOffset(260, 260),
    Position = UDim2.new(0.5, -130, 0.5, -130),
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

-- Scrolling container
local scroll = make("ScrollingFrame", {
    Name = "CodeScroll",
    Position = UDim2.fromOffset(8, 40),
    Size = UDim2.new(1, -16, 1, -91),
    BackgroundColor3 = Color3.fromRGB(16, 18, 23),
    BorderSizePixel = 0,
    ScrollBarThickness = 6,
    ScrollingDirection = Enum.ScrollingDirection.XY,
    AutomaticCanvasSize = Enum.AutomaticSize.None,
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
    AutomaticSize = Enum.AutomaticSize.None,
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

    local lineHeight = 15
    local wantedHeight = math.max(scroll.AbsoluteSize.Y - 10, lines * lineHeight + 12)
    local wantedWidth = math.max(scroll.AbsoluteSize.X - 10, longest * 7 + 15)

    codeBox.Size = UDim2.fromOffset(wantedWidth, wantedHeight)
    scroll.CanvasSize = UDim2.fromOffset(wantedWidth + 10, wantedHeight + 10)
end

codeBox:GetPropertyChangedSignal("Text"):Connect(updateCanvas)
scroll:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateCanvas)

-- Buttons
local startButton = makeButton(
    window, "StartButton", "Start",
    UDim2.new(0, 8, 1, -43), UDim2.new(0.3333, -8, 0, 33)
)

local locanButton = makeButton(
    window, "LocanButton", "Locan",
    UDim2.new(0.3333, 1, 1, -43), UDim2.new(0.3333, -8, 0, 33)
)

local copyButton = makeButton(
    window, "CopyButton", "Copy",
    UDim2.new(0.6666, 2, 1, -43), UDim2.new(0.3333, -10, 0, 33)
)

local function setToggle(button, enabled)
    button.BackgroundColor3 = enabled and GREEN or RED
end

floating.Activated:Connect(function()
    window.Visible = not window.Visible
end)

-- Drag only from header. Do not drag while editing the textbox.
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
    if not dragging then return end

    if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then

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

-- Selection state
local selecting = false
local selectedPart = nil
local selectedTarget = nil
local highlight = nil
local inputConnection = nil

local function clearHighlight()
    if highlight then
        highlight:Destroy()
        highlight = nil
    end
end

local function getTargetFromPart(part)
    -- Preserve a model as the target if the hit part belongs to one.
    local model = part:FindFirstAncestorOfClass("Model")

    if model and model ~= player.Character then
        return model
    end

    return part
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

local function findTargetPart(target)
    if target:IsA("BasePart") then
        return target
    end

    if target:IsA("Model") then
        if target.PrimaryPart then
            return target.PrimaryPart
        end

        return target:FindFirstChildWhichIsA("BasePart", true)
    end

    return nil
end

local function selectAtScreenPosition(screenPosition)
    local camera = workspace.CurrentCamera
    if not camera then return end

    -- Convert screen coordinates to viewport coordinates.
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

    if not result then return end

    local part = result.Instance
    if not part:IsA("BasePart") then return end

    selectedPart = part
    selectedTarget = getTargetFromPart(part)

    makeHighlight(selectedTarget)

    -- Do NOT modify the textbox here.
    -- Selection should never overwrite user text.
end

startButton.Activated:Connect(function()
    selecting = not selecting
    setToggle(startButton, selecting)

    if inputConnection then
        inputConnection:Disconnect()
        inputConnection = nil
    end

    if not selecting then
        return
    end

    inputConnection = UserInputService.InputBegan:Connect(function(input, processed)
        if not selecting or processed then return end

        if input.UserInputType ~= Enum.UserInputType.Touch
            and input.UserInputType ~= Enum.UserInputType.MouseButton1 then
            return
        end

        -- Don't select through interactions with this UI.
        if window.Visible then
            local pos = input.Position
            local absPos = window.AbsolutePosition
            local absSize = window.AbsoluteSize

            local insideWindow =
                pos.X >= absPos.X and pos.X <= absPos.X + absSize.X
                and pos.Y >= absPos.Y and pos.Y <= absPos.Y + absSize.Y

            if insideWindow then return end
        end

        selectAtScreenPosition(input.Position)
    end)
end)

-- Locan generates code only when explicitly pressed.
local function generateCode(target)
    local targetPart = findTargetPart(target)
    if not targetPart then
        return "-- The selected target has no BasePart."
    end

    local fullName = target:GetFullName()
    local partName = targetPart.Name

    return string.format([[
-- Generated example for your own Roblox Studio experience
-- Selected target: %s

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

        -- Example: teleport beside the selected target.
        root.CFrame = part.CFrame * CFrame.new(0, 3, 0)
    end
end
]], fullName, target.Name, partName)
end

locanButton.Activated:Connect(function()
    local enabled = locanButton.BackgroundColor3 ~= GREEN
    setToggle(locanButton, enabled)

    if not enabled then return end

    if not selectedTarget or not selectedTarget.Parent then
        codeBox.Text = "-- No valid target selected.\n-- Press Start, then tap a block or coin."
        updateCanvas()
        return
    end

    -- This is the only place selection-generated code changes the textbox.
    codeBox.Text = generateCode(selectedTarget)
    scroll.CanvasPosition = Vector2.new(0, 0)
    updateCanvas()
end)

-- Clipboard API is not provided by standard Roblox LocalScripts.
copyButton.Activated:Connect(function()
    local enabled = copyButton.BackgroundColor3 ~= GREEN
    setToggle(copyButton, enabled)

    -- Preserve the existing text and allow manual selection/copy.
    codeBox:CaptureFocus()
    codeBox.CursorPosition = 1
    codeBox.SelectionStart = #codeBox.Text + 1
end)

-- Responsive window size
local function resize()
    local camera = workspace.CurrentCamera
    if not camera then return end

    local viewport = camera.ViewportSize
    local width = math.min(260, math.max(200, viewport.X - 24))
    local height = math.min(260, math.max(205, viewport.Y - 50))

    window.Size = UDim2.fromOffset(width, height)
    window.Position = UDim2.new(0.5, -width / 2, 0.5, -height / 2)

    updateCanvas()
end

resize()

if workspace.CurrentCamera then
    workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(resize)
end

workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(resize)
