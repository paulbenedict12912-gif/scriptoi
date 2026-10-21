--// [K]vk Executor UI — Roblox
--// PC: RightShift to toggle | Mobile: draggable float button
--// Anti-cheat: protect_gui + gethui + randomized instance names

local UIS        = game:GetService("UserInputService")
local TweenSvc   = game:GetService("TweenService")
local Players    = game:GetService("Players")
local CoreGui    = game:GetService("CoreGui")
local RunService = game:GetService("RunService")

local LP = Players.LocalPlayer
local ENV = getfenv and getfenv() or _ENV

--// ─── executor funcs with fallbacks ──────────────────────────────
local function pick(...)
    for _, v in ipairs({...}) do if v then return v end end
end

local loadstr  = ENV.loadstring or loadstring
local protect  = pick(ENV.protect_gui, syn and syn.protect_gui, protect_gui)
local gethui   = pick(ENV.gethui, gethui)
local setclip  = pick(ENV.setclipboard, ENV.toclipboard, setclipboard)
local getclip  = pick(ENV.getclipboard, getclipboard)

--// ─── random name generator (avoid signature detection) ──────────
local CH = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
local function rname(n)
    n = n or math.random(14, 22)
    local t = {}
    for i = 1, n do
        local k = math.random(1, #CH)
        t[i] = CH:sub(k, k)
    end
    return table.concat(t)
end

--// ─── parent for the GUI ─────────────────────────────────────────
local function getSafeParent()
    if gethui then
        local ok, h = pcall(gethui)
        if ok and h then return h end
    end
    local ok, cg = pcall(function() return CoreGui end)
    if ok and cg then return cg end
    return LP:WaitForChild("PlayerGui")
end

local PARENT = getSafeParent()

--// ─── ScreenGui ──────────────────────────────────────────────────
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name              = rname()
ScreenGui.ResetOnSpawn      = false
ScreenGui.IgnoreGuiInset    = true
ScreenGui.ZIndexBehavior    = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder      = 999999
ScreenGui.Enabled           = true

if protect then pcall(protect, ScreenGui) end
ScreenGui.Parent = PARENT

--// ─── screen / device detection ──────────────────────────────────
local isMobile = UIS.TouchEnabled and not UIS.KeyboardEnabled
local cam = workspace.CurrentCamera
local function vp()
    if cam then return cam.ViewportSize end
    return Vector2.new(1920, 1080)
end

--// ─── color theme ────────────────────────────────────────────────
local C = {
    bg      = Color3.fromRGB(18, 18, 22),
    panel   = Color3.fromRGB(26, 26, 32),
    sub     = Color3.fromRGB(36, 36, 44),
    stroke  = Color3.fromRGB(58, 58, 70),
    accent  = Color3.fromRGB(94, 124, 255),
    accent2 = Color3.fromRGB(130, 155, 255),
    text    = Color3.fromRGB(232, 232, 240),
    dim     = Color3.fromRGB(150, 150, 165),
    ok      = Color3.fromRGB(90, 210, 130),
    err     = Color3.fromRGB(240, 90, 100),
    warn    = Color3.fromRGB(240, 190, 90),
}

--// ─── helpers ────────────────────────────────────────────────────
local function corner(obj, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 8)
    c.Parent = obj
end

local function stroke(obj, col, th)
    local s = Instance.new("UIStroke")
    s.Color = col or C.stroke
    s.Thickness = th or 1
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = obj
end

local function padding(obj, p)
    local u = Instance.new("UIPadding")
    local v = UDim.new(0, p)
    u.PaddingTop, u.PaddingBottom = v, v
    u.PaddingLeft, u.PaddingRight = v, v
    u.Parent = obj
end

--// ─── drag system (works mouse + touch) ──────────────────────────
local function makeDraggable(frame, handle)
    handle = handle or frame
    local dragging, dragStart, startPos

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging   = true
            dragStart  = input.Position
            startPos   = frame.Position
        end
    end)

    handle.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)

    UIS.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)

    UIS.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end

--// ─── main window ────────────────────────────────────────────────
local mobileW, mobileH = 0.85, 0.6
local pcW, pcH = 620, 460

local Main = Instance.new("Frame")
Main.Name = rname()
Main.Parent = ScreenGui
Main.AnchorPoint = Vector2.new(0.5, 0.5)
Main.Position = UDim2.new(0.5, 0, 0.5, 0)
Main.BackgroundColor3 = C.bg
Main.BorderSizePixel = 0
Main.ClipsDescendants = true
Main.Visible = false
corner(Main, 10)
stroke(Main, C.stroke, 1)

if isMobile then
    Main.Size = UDim2.new(mobileW, 0, mobileH, 0)
else
    Main.Size = UDim2.fromOffset(pcW, pcH)
end

--// top bar
local TopBar = Instance.new("Frame")
TopBar.Name = rname()
TopBar.Parent = Main
TopBar.Size = UDim2.new(1, 0, 0, 34)
TopBar.BackgroundColor3 = C.panel
TopBar.BorderSizePixel = 0
corner(TopBar, 10)

-- patch bottom corners of topbar (only top corners rounded)
local TopBarCover = Instance.new("Frame")
TopBarCover.Parent = TopBar
TopBarCover.Position = UDim2.new(0, 0, 1, -8)
TopBarCover.Size = UDim2.new(1, 0, 0, 8)
TopBarCover.BackgroundColor3 = C.panel
TopBarCover.BorderSizePixel = 0

local Title = Instance.new("TextLabel")
Title.Parent = TopBar
Title.BackgroundTransparency = 1
Title.Position = UDim2.new(0, 14, 0, 0)
Title.Size = UDim2.new(1, -80, 1, 0)
Title.Font = Enum.Font.GothamMedium
Title.Text = "[K]vk executor"
Title.TextSize = 14
Title.TextColor3 = C.text
Title.TextXAlignment = Enum.TextXAlignment.Left

local CloseBtn = Instance.new("TextButton")
CloseBtn.Parent = TopBar
CloseBtn.AnchorPoint = Vector2.new(1, 0.5)
CloseBtn.Position = UDim2.new(1, -8, 0.5, 0)
CloseBtn.Size = UDim2.fromOffset(24, 24)
CloseBtn.BackgroundColor3 = C.sub
CloseBtn.BorderSizePixel = 0
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.Text = "×"
CloseBtn.TextSize = 16
CloseBtn.TextColor3 = C.text
CloseBtn.AutoButtonColor = false
corner(CloseBtn, 6)

CloseBtn.MouseEnter:Connect(function()
    TweenSvc:Create(CloseBtn, TweenInfo.new(0.15), {BackgroundColor3 = C.err}):Play()
end)
CloseBtn.MouseLeave:Connect(function()
    TweenSvc:Create(CloseBtn, TweenInfo.new(0.15), {BackgroundColor3 = C.sub}):Play()
end)
CloseBtn.MouseButton1Click:Connect(function()
    Main.Visible = false
end)

makeDraggable(Main, TopBar)

--// ─── tab bar ────────────────────────────────────────────────────
local TabBar = Instance.new("Frame")
TabBar.Parent = Main
TabBar.Position = UDim2.new(0, 10, 0, 42)
TabBar.Size = UDim2.new(1, -20, 0, 28)
TabBar.BackgroundTransparency = 1

local function makeTab(text, x, w)
    local t = Instance.new("TextButton")
    t.Parent = TabBar
    t.Position = UDim2.new(0, x, 0, 0)
    t.Size = UDim2.new(0, w, 1, 0)
    t.BackgroundColor3 = C.sub
    t.BorderSizePixel = 0
    t.Font = Enum.Font.GothamMedium
    t.Text = text
    t.TextSize = 12
    t.TextColor3 = C.text
    t.AutoButtonColor = false
    corner(t, 6)
    return t
end

local TabExec = makeTab("execute", 0, 80)
local TabOut  = makeTab("console", 88, 80)

local function selectTab(which)
    local active, inactive = (which == "exec") and TabExec or TabOut,
                             (which == "exec") and TabOut  or TabExec
    active.BackgroundColor3 = C.accent
    inactive.BackgroundColor3 = C.sub
end

--// ─── editor area ────────────────────────────────────────────────
local EditorFrame = Instance.new("Frame")
EditorFrame.Parent = Main
EditorFrame.Position = UDim2.new(0, 10, 0, 78)
EditorFrame.Size = UDim2.new(1, -20, 1, -140)
EditorFrame.BackgroundColor3 = C.panel
EditorFrame.BorderSizePixel = 0
corner(EditorFrame, 8)
stroke(EditorFrame, C.stroke, 1)

local Editor = Instance.new("TextBox")
Editor.Parent = EditorFrame
Editor.BackgroundTransparency = 1
Editor.Position = UDim2.new(0, 8, 0, 8)
Editor.Size = UDim2.new(1, -16, 1, -16)
Editor.Font = Enum.Font.Code
Editor.Text = "-- paste or loadstring your script here\n-- example: print(\"hello roblox\")"
Editor.PlaceholderText = "paste or loadstring your script here"
Editor.TextSize = isMobile and 13 or 14
Editor.TextColor3 = C.text
Editor.PlaceholderColor3 = C.dim
Editor.TextXAlignment = Enum.TextXAlignment.Left
Editor.TextYAlignment = Enum.TextYAlignment.Top
Editor.TextWrapped = true
Editor.MultiLine = true
Editor.ClearTextOnFocus = false
Editor.TextEditable = true

--// ─── console area ───────────────────────────────────────────────
local ConsoleFrame = Instance.new("Frame")
ConsoleFrame.Parent = Main
ConsoleFrame.Position = EditorFrame.Position
ConsoleFrame.Size = EditorFrame.Size
ConsoleFrame.BackgroundColor3 = C.panel
ConsoleFrame.BorderSizePixel = 0
ConsoleFrame.Visible = false
corner(ConsoleFrame, 8)
stroke(ConsoleFrame, C.stroke, 1)

local ConsoleScroll = Instance.new("ScrollingFrame")
ConsoleScroll.Parent = ConsoleFrame
ConsoleScroll.BackgroundTransparency = 1
ConsoleScroll.Position = UDim2.new(0, 8, 0, 8)
ConsoleScroll.Size = UDim2.new(1, -16, 1, -16)
ConsoleScroll.BorderSizePixel = 0
ConsoleScroll.ScrollBarThickness = 6
ConsoleScroll.ScrollBarImageColor3 = C.accent
ConsoleScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
ConsoleScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y

local ConsoleLayout = Instance.new("UIListLayout")
ConsoleLayout.Parent = ConsoleScroll
ConsoleLayout.Padding = UDim.new(0, 4)
ConsoleLayout.SortOrder = Enum.SortOrder.LayoutOrder

local consoleLines = {}

local function logLine(text, color)
    color = color or C.text
    local lbl = Instance.new("TextLabel")
    lbl.Parent = ConsoleScroll
    lbl.BackgroundTransparency = 1
    lbl.Size = UDim2.new(1, 0, 0, 0)
    lbl.AutomaticSize = Enum.AutomaticSize.Y
    lbl.Font = Enum.Font.Code
    lbl.TextSize = 12
    lbl.TextColor3 = color
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.TextYAlignment = Enum.TextYAlignment.Top
    lbl.TextWrapped = true
    lbl.Text = text
    table.insert(consoleLines, lbl)
    task.wait()
    ConsoleScroll.CanvasPosition = Vector2.new(0, math.max(0, ConsoleLayout.AbsoluteContentSize.Y - ConsoleScroll.AbsoluteSize.Y))
end

local function clearConsole()
    for _, v in ipairs(consoleLines) do v:Destroy() end
    consoleLines = {}
end

--// ─── bottom buttons ─────────────────────────────────────────────
local BtnRow = Instance.new("Frame")
BtnRow.Parent = Main
BtnRow.AnchorPoint = Vector2.new(0, 1)
BtnRow.Position = UDim2.new(0, 10, 1, -10)
BtnRow.Size = UDim2.new(1, -20, 0, 40)
BtnRow.BackgroundTransparency = 1

local function makeBtn(text, x, w, color)
    local b = Instance.new("TextButton")
    b.Parent = BtnRow
    b.Position = UDim2.new(0, x, 0, 0)
    b.Size = UDim2.new(0, w, 1, 0)
    b.BackgroundColor3 = color or C.sub
    b.BorderSizePixel = 0
    b.Font = Enum.Font.GothamSemibold
    b.Text = text
    b.TextSize = 13
    b.TextColor3 = C.text
    b.AutoButtonColor = false
    corner(b, 8)
    b.MouseEnter:Connect(function()
        TweenSvc:Create(b, TweenInfo.new(0.15), {BackgroundColor3 = C.accent2}):Play()
    end)
    b.MouseLeave:Connect(function()
        TweenSvc:Create(b, TweenInfo.new(0.15), {BackgroundColor3 = color or C.sub}):Play()
    end)
    return b
end

local bW = isMobile and 92 or 110
local ExecuteBtn = makeBtn("execute", 0, bW, C.accent)
local ClearBtn   = makeBtn("clear", bW + 6, 84)
local CopyBtn    = makeBtn("copy", bW + 96, 84)
local PasteBtn   = makeBtn("paste", bW + 186, 84)

--// ─── execute logic ──────────────────────────────────────────────
local function executeCode(code)
    if not code or code == "" then
        logLine("[!] nothing to execute", C.warn)
        return
    end

    if not loadstr then
        logLine("[x] no loadstring available in this executor", C.err)
        return
    end

    logLine("> executing...", C.dim)

    local fn, err = loadstr(code)
    if not fn then
        logLine("[compile error] " .. tostring(err), C.err)
        return
    end

    local ok, res = pcall(fn)
    if ok then
        if res ~= nil then
            logLine("[ok] " .. tostring(res), C.ok)
        else
            logLine("[ok] script finished", C.ok)
        end
    else
        logLine("[runtime error] " .. tostring(res), C.err)
    end
end

ExecuteBtn.MouseButton1Click:Connect(function()
    selectTab("out")
    executeCode(Editor.Text)
end)

ClearBtn.MouseButton1Click:Connect(function()
    Editor.Text = ""
end)

CopyBtn.MouseButton1Click:Connect(function()
    if setclip then
        pcall(setclip, Editor.Text)
    else
        pcall(function()
            if setclipboard then setclipboard(Editor.Text) end
        end)
    end
end)

PasteBtn.MouseButton1Click:Connect(function()
    if getclip then
        local ok, txt = pcall(getclip)
        if ok and txt and txt ~= "" then
            Editor.Text = txt
        end
    end
end)

TabExec.MouseButton1Click:Connect(function()
    selectTab("exec")
    EditorFrame.Visible = true
    ConsoleFrame.Visible = false
end)

TabOut.MouseButton1Click:Connect(function()
    selectTab("out")
    EditorFrame.Visible = false
    ConsoleFrame.Visible = true
end)

selectTab("exec")

--// ─── floating toggle button ─────────────────────────────────────
local FloatBtn = Instance.new("TextButton")
FloatBtn.Name = rname()
FloatBtn.Parent = ScreenGui
FloatBtn.BackgroundColor3 = C.accent
FloatBtn.BorderSizePixel = 0
FloatBtn.Font = Enum.Font.GothamBold
FloatBtn.Text = "K"
FloatBtn.TextSize = 20
FloatBtn.TextColor3 = Color3.fromRGB(255,255,255)
FloatBtn.AutoButtonColor = false
FloatBtn.Visible = true

local floatSize = isMobile and 52 or 44
FloatBtn.Size = UDim2.fromOffset(floatSize, floatSize)
FloatBtn.Position = UDim2.new(0, isMobile and 20 or 30, 0.5, 0)
corner(FloatBtn, floatSize / 2)
stroke(FloatBtn, C.accent2, 1)

-- drag float button
local fbDragging, fbStart, fbStartPos, fbMoved
FloatBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        fbDragging = true
        fbMoved = false
        fbStart = input.Position
        fbStartPos = FloatBtn.Position
    end
end)

UIS.InputChanged:Connect(function(input)
    if not fbDragging then return end
    if input.UserInputType == Enum.UserInputType.MouseMovement
    or input.UserInputType == Enum.UserInputType.Touch then
        local delta = input.Position - fbStart
        if delta.Magnitude > 4 then fbMoved = true end
        FloatBtn.Position = UDim2.new(
            fbStartPos.X.Scale, fbStartPos.X.Offset + delta.X,
            fbStartPos.Y.Scale, fbStartPos.Y.Offset + delta.Y
        )
    end
end)

UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        fbDragging = false
    end
end)

FloatBtn.MouseButton1Click:Connect(function()
    if fbMoved then return end
    Main.Visible = not Main.Visible
end)

--// ─── PC: RightShift toggle ──────────────────────────────────────
UIS.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.RightShift then
        Main.Visible = not Main.Visible
    end
end)

--// ─── initial log ────────────────────────────────────────────────
logLine("[K]vk executor ready", C.accent2)
logLine(isMobile and "device: mobile" or "device: pc (RShift toggles ui)", C.dim)
logLine("paste or loadstring, then hit execute", C.dim)
