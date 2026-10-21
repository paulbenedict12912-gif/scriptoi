
-- Mobile Block Selector UI
-- For a Roblox Studio experience you own.

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local old = playerGui:FindFirstChild("MobileBlockUI")
if old then
    old:Destroy()
end

local gui = Instance.new("ScreenGui")
gui.Name = "MobileBlockUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.Parent = playerGui

local function make(class, props, parent)
    local obj = Instance.new(class)
    for k, v in pairs(props) do
        obj[k] = v
    end
    obj.Parent = parent
    return obj
end

local function corner(obj, radius)
    make("UICorner", {
        CornerRadius = UDim.new(0, radius)
    }, obj)
end

local function outline(obj, color)
    make("UIStroke", {
        Color = color,
        Thickness = 1
    }, obj)
end

local blue = Color3.fromRGB(45, 125, 255)
local green = Color3.fromRGB(35, 190, 95)
local red = Color3.fromRGB(205, 55, 65)
local dark = Color3.fromRGB(25, 27, 33)
local panel = Color3.fromRGB(34, 37, 45)
local white = Color3.fromRGB(240, 240, 245)

-- Floating show/hide button
local float = make("TextButton", {
    Name = "FloatingButton",
    Size = UDim2.fromOffset(43, 43),
    Position = UDim2.new(0, 12, 0.45, 0),
    BackgroundColor3 = blue,
    Text = "UI",
    TextColor3 = white,
    TextSize = 14,
    Font = Enum.Font.GothamBold,
    AutoButtonColor = true
}, gui)
corner(float, 22)
outline(float, Color3.fromRGB(100, 165, 255))

-- Main window
local window = make("Frame", {
    Name = "MainWindow",
    Size = UDim2.fromOffset(260, 245),
    Position = UDim2.new(0.5, -130, 0.5, -122),
    BackgroundColor3 = dark,
    BorderSizePixel = 0,
    Active = true
}, gui)
corner(window, 8)
outline(window, Color3.fromRGB(65, 70, 85))

-- Draggable title bar
local titleBar = make("Frame", {
    Size = UDim2.new(1, 0, 0, 30),
    BackgroundColor3 = panel,
    BorderSizePixel = 0,
    Active = true
}, window)
corner(titleBar, 8)

make("TextLabel", {
    Size = UDim2.new(1, -12, 1, 0),
    Position = UDim2.fromOffset(10, 0),
    BackgroundTransparency = 1,
    Text = "Block Selector",
    TextColor3 = white,
    TextSize = 12,
    Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Left
}, titleBar)

-- Scrollable script textbox
local codeBox = make("TextBox", {
    Name = "ScriptTextbox",
    Position = UDim2.fromOffset(8, 38),
    Size = UDim2.new(1, -16, 1, -91),
    BackgroundColor3 = Color3.fromRGB(17, 19, 24),
    TextColor3 = Color3.fromRGB(190, 220, 255),
    PlaceholderText = "-- Select a block to generate code",
    PlaceholderColor3 = Color3.fromRGB(125, 130, 145),
    Text = "",
    TextSize = 11,
    Font = Enum.Font.Code,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Top,
    TextWrapped = false,
    ClearTextOnFocus = false,
    MultiLine = true,
    TextEditable = true
}, window)
corner(codeBox, 5)
outline(codeBox, Color3.fromRGB(60, 65, 80))

local scroll = make("ScrollingFrame", {
    Name = "TextScroll",
    Position = codeBox.Position,
    Size = codeBox.Size,
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ScrollBarThickness = 4,
    CanvasSize = UDim2.new(),
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
    Visible = false
}, window)

-- Three compact buttons
local buttonNames = {"Start", "Locan", "Copy"}
local buttons = {}

for i, name in ipairs(buttonNames) do
    local b = make("TextButton", {
        Name = name .. "Button",
        Position = UDim2.new(0, 8 + (i - 1) * 84, 1, -43),
        Size = UDim2.fromOffset(78, 33),
        BackgroundColor3 = red,
        Text = name,
        TextColor3 = white,
        TextSize = 11,
        Font = Enum.Font.GothamBold,
        AutoButtonColor = true
    }, window)
    corner(b, 5)
    buttons[name] = b
end

local function setState(button, enabled)
    button.BackgroundColor3 = enabled and green or red
end

float.Activated:Connect(function()
    window.Visible = not window.Visible
end)

-- Drag support for touch and mouse
local dragging = false
local dragInput
local dragStart
local startPosition

local function beginDrag(input)
    dragging = true
    dragStart = input.Position
    startPosition = window.Position
    dragInput = input
end

titleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        beginDrag(input)
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if not dragging then return end

    if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then
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
    end
end)

-- Selection state
local selecting = false
local selectedPart
local highlight
local clickConnection

local function clearSelection()
    if highlight then
        highlight:Destroy()
        highlight = nil
    end
    selectedPart = nil
end

local function generateCode(part)
    local relativeName = part:GetFullName()
    local pos = part.Position
    local size = part.Size
    local color = part.Color

    return string.format(
        "-- Generated LocalScript example\n" ..
        "-- Selected instance: %s\n" ..
        "-- This references a part already present in the game.\n\n" ..
        "local part = workspace:FindFirstChild(%q, true)\n\n" ..
        "if part and part:IsA('BasePart') then\n" ..
        "    -- Example local visual change\n" ..
        "    part.LocalTransparencyModifier = 0\n" ..
        "end\n\n" ..
        "-- Selected part properties at generation time:\n" ..
        "-- Position: Vector3.new(%.3f, %.3f, %.3f)\n" ..
        "-- Size: Vector3.new(%.3f, %.3f, %.3f)\n" ..
        "-- Color: Color3.new(%.3f, %.3f, %.3f)\n",
        relativeName,
        part.Name,
        pos.X, pos.Y, pos.Z,
        size.X, size.Y, size.Z,
        color.R, color.G, color.B
    )
end

buttons.Start.Activated:Connect(function()
    selecting = not selecting
    setState(buttons.Start, selecting)

    if clickConnection then
        clickConnection:Disconnect()
        clickConnection = nil
    end

    if selecting then
        clickConnection = UserInputService.InputBegan:Connect(function(input, processed)
            if processed or not selecting then return end
            if input.UserInputType ~= Enum.UserInputType.Touch
                and input.UserInputType ~= Enum.UserInputType.MouseButton1 then
                return
            end

            local camera = workspace.CurrentCamera
            if not camera then return end

            local position = input.Position
            local ray = camera:ViewportPointToRay(position.X, position.Y)

            local params = RaycastParams.new()
            params.FilterType = Enum.RaycastFilterType.Exclude
            params.FilterDescendantsInstances = {player.Character, gui}

            local result = workspace:Raycast(ray.Origin, ray.Direction * 1000, params)

            if result and result.Instance:IsA("BasePart") then
                clearSelection()
                selectedPart = result.Instance

                highlight = Instance.new("Highlight")
                highlight.Name = "SelectedBlockHighlight"
                highlight.Adornee = selectedPart
                highlight.FillColor = blue
                highlight.OutlineColor = blue
                highlight.FillTransparency = 0.8
                highlight.OutlineTransparency = 0
                highlight.Parent = gui

                codeBox.Text = generateCode(selectedPart)
            end
        end)
    end
end)

-- Locan: generate/update a LocalScript representation
buttons.Locan.Activated:Connect(function()
    local enabled = buttons.Locan.BackgroundColor3 ~= green
    setState(buttons.Locan, enabled)

    if selectedPart and selectedPart.Parent then
        codeBox.Text = generateCode(selectedPart)
    else
        codeBox.Text = "-- No block selected.\n-- Press Start, then tap a block."
    end
end)

-- Copy: toggle color and request clipboard copy if supported
buttons.Copy.Activated:Connect(function()
    local enabled = buttons.Copy.BackgroundColor3 ~= green
    setState(buttons.Copy, enabled)

    -- Roblox LocalScripts do not have a standard clipboard API.
    -- Select and copy the textbox manually if clipboard access is unavailable.
    codeBox:CaptureFocus()
    codeBox.CursorPosition = 1
end)

-- Keep window usable on smaller screens
local function resize()
    local camera = workspace.CurrentCamera
    if not camera then return end

    local viewport = camera.ViewportSize
    local width = math.min(260, math.max(220, viewport.X - 24))
    local height = math.min(245, math.max(200, viewport.Y - 70))

    window.Size = UDim2.fromOffset(width, height)
    window.Position = UDim2.new(0.5, -width / 2, 0.5, -height / 2)
end

resize()

if workspace.CurrentCamera then
    workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(resize)
end
