--[[
    ============================================================
    MM2 APEX HUNTER v5.2
    ✅ Auto Coin: วิ่งลอยต่อเนื่อง ไม่ติดกำแพง
    ✅ ความเร็วเก็บเหรียญ = แถบความเร็ววิ่ง
    ✅ มีไอคอนลอย M กดเปิด/ปิดเมนู
    ============================================================
]]

-- SERVICES
local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local CoreGui           = game:GetService("CoreGui")
local UserInputService  = game:GetService("UserInputService")
local TweenService      = game:GetService("TweenService")
local Workspace         = game:GetService("Workspace")
local VirtualUser       = game:GetService("VirtualUser")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- CHECK EXECUTOR
if not Drawing or not getgenv then
    print("❌ Executor ของคุณไม่รองรับ Drawing API")
    return
end

-- ป้องกันรันซ้ำ
if getgenv().MM2_GUI then
    pcall(function() getgenv().MM2_GUI:Destroy() end)
end

-- ตัวแปรสถานะ
local State = {
    AntiAFK         = true,
    Noclip          = false,
    Speed           = false,
    Aura            = false,
    ESP             = false,
    AutoCoin        = false,
    FlingMurderer   = false,
    FlingSheriff    = false,
    FlingInnocent   = false,
    AuraRange       = 300,
    SelectedTarget  = nil,
    SpeedValue      = 25,
}

local Connections = {}
local Highlights = {}
local IsDead = false

-- ฟังก์ชันช่วย
local function addConnection(conn)
    table.insert(Connections, conn)
    return conn
end

local function getHRP(character)
    return character and character:FindFirstChild("HumanoidRootPart")
end

local function getHumanoid(character)
    return character and character:FindFirstChild("Humanoid")
end

local function isAlive(player)
    local char = player.Character
    local hum = char and getHumanoid(char)
    return hum and hum.Health > 0
end

-- ดึงบทบาทผู้เล่น
local function getRole(player)
    local char = player.Character
    if not char then return "Innocent" end
    local roleVal = char:FindFirstChild("Role")
    return roleVal and roleVal.Value or "Innocent"
end

-- ฟังก์ชันลากได้
local function makeDraggable(frame, dragArea)
    local dragging, dragInput, startPos, startFramePos
    dragArea = dragArea or frame
    
    addConnection(dragArea.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            startPos = input.Position
            startFramePos = frame.Position
        end
    end))
    
    addConnection(dragArea.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end))
    
    addConnection(UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - startPos
            frame.Position = UDim2.new(
                startFramePos.X.Scale, startFramePos.X.Offset + delta.X,
                startFramePos.Y.Scale, startFramePos.Y.Offset + delta.Y
            )
        end
    end))
    
    addConnection(UserInputService.InputEnded:Connect(function()
        dragging = false
    end))
end

-- สร้าง ScreenGui
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MM2_Apex_Hunter"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
if gethui then
    ScreenGui.Parent = gethui()
else
    ScreenGui.Parent = CoreGui
end
getgenv().MM2_GUI = ScreenGui

-- ไอคอนลอยเปิด-ปิดเมนู
local Icon = Instance.new("TextButton")
Icon.Name = "ToggleIcon"
Icon.Size = UDim2.new(0, 50, 0, 50)
Icon.Position = UDim2.new(1, -65, 1, -65)
Icon.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
Icon.BorderSizePixel = 0
Icon.Text = "M"
Icon.Font = Enum.Font.GothamBold
Icon.TextSize = 22
Icon.TextColor3 = Color3.fromRGB(255, 60, 60)
Icon.AutoButtonColor = false
Icon.Parent = ScreenGui

local IconCorner = Instance.new("UICorner")
IconCorner.CornerRadius = UDim.new(0, 12)
IconCorner.Parent = Icon

local IconStroke = Instance.new("UIStroke")
IconStroke.Color = Color3.fromRGB(255, 60, 60)
IconStroke.Thickness = 1.5
IconStroke.Parent = Icon

makeDraggable(Icon, Icon)

-- ANTI-AFK LOOP
addConnection(RunService.Heartbeat:Connect(function()
    if State.AntiAFK then
        pcall(function() VirtualUser:ButtonDown(Enum.KeyCode.Wait) end)
    end
end))

-- NOCLIP LOOP
local originalCanCollide = {}
addConnection(RunService.Stepped:Connect(function()
    local char = LocalPlayer.Character
    if not char then return end
    for _, part in ipairs(char:GetChildren()) do
        if part:IsA("BasePart") then
            if State.Noclip then
                originalCanCollide[part] = originalCanCollide[part] ~= nil and originalCanCollide[part] or part.CanCollide
                part.CanCollide = false
            else
                if originalCanCollide[part] ~= nil then
                    part.CanCollide = originalCanCollide[part]
                end
            end
        end
    end
end))

-- SPEED LOOP
addConnection(RunService.Heartbeat:Connect(function()
    local char = LocalPlayer.Character
    local hum = char and getHumanoid(char)
    if hum then
        hum.WalkSpeed = State.Speed or State.AutoCoin and State.SpeedValue or 16
    end
end))

-- Fling Murderer Function
local spinAngle = 0
local function FlingTarget(targetHRP)
    if not targetHRP then return end
    local myHRP = getHRP(LocalPlayer.Character)
    if not myHRP then return end
    pcall(function()
        spinAngle = spinAngle + 180
        local offset = Vector3.new(math.cos(math.rad(spinAngle)) * 2, 0.5, math.sin(math.rad(spinAngle)) * 2)
        myHRP.CFrame = targetHRP.CFrame + offset
        myHRP.Velocity = Vector3.new(0, 50, 0)
        targetHRP.Velocity = Vector3.new(
            math.random(-99999, 99999),
            99999,
            math.random(-99999, 99999)
        )
        targetHRP.RotVelocity = Vector3.new(
            math.random(-99999, 99999),
            99999,
            math.random(-99999, 99999)
        )
    end)
end

-- AURA KILL LOOP
addConnection(RunService.Heartbeat:Connect(function()
    if not State.Aura then return end
    local myChar = LocalPlayer.Character
    local myHRP = getHRP(myChar)
    local myTool = myChar and myChar:FindFirstChildOfClass("Tool")
    if not myHRP or not myTool then return end
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and isAlive(player) then
            local targetHRP = getHRP(player.Character)
            if targetHRP then
                local dist = (myHRP.Position - targetHRP.Position).Magnitude
                if dist <= State.AuraRange then
                    pcall(function()
                        for _, desc in ipairs(myTool:GetDescendants()) do
                            if desc:IsA("RemoteEvent") then
                                desc:FireServer(player.Character)
                            end
                        end
                    end)
                end
            end
        end
    end
end))

-- ESP SYSTEM
local function ClearESP()
    for _, hl in pairs(Highlights) do
        pcall(function() hl:Destroy() end)
    end
    table.clear(Highlights)
end

local RoleColors = {
    Murderer  = Color3.fromRGB(255, 40, 40),
    Sheriff   = Color3.fromRGB(40, 120, 255),
    Innocent  = Color3.fromRGB(40, 255, 80),
}

addConnection(RunService.RenderStepped:Connect(function()
    if not State.ESP then ClearESP() return end
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and isAlive(player) then
            local char = player.Character
            local hrp = getHRP(char)
            if char and hrp then
                local hl = Highlights[player.UserId]
                if not hl then
                    hl = Instance.new("Highlight")
                    hl.Name = "ESP_" .. player.Name
                    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                    hl.FillTransparency = 0.5
                    hl.OutlineTransparency = 0
                    hl.Parent = CoreGui
                    Highlights[player.UserId] = hl
                end
                hl.Adornee = char
                hl.FillColor = RoleColors[getRole(player)] or Color3.new(1, 1, 1)
            end
        end
    end
end))

-- AUTO COIN SYSTEM
local CollectedCoins = {}
local CurrentCoinTarget = nil
local StuckTimer = 0

addConnection(LocalPlayer.CharacterAdded:Connect(function()
    table.clear(CollectedCoins)
    CurrentCoinTarget = nil
    StuckTimer = 0
end))

addConnection(RunService.Heartbeat:Connect(function(deltaTime)
    if not State.AutoCoin then
        CurrentCoinTarget = nil
        StuckTimer = 0
        return
    end
    
    local myChar = LocalPlayer.Character
    local myHRP = getHRP(myChar)
    if not myHRP then return end
    
    -- หนีฆาตกร
    for _, player in ipairs(Players:GetPlayers()) do
        if getRole(player) == "Murderer" and isAlive(player) then
            local tHRP = getHRP(player.Character)
            if tHRP and (myHRP.Position - tHRP.Position).Magnitude <= 15 then
                local fleeDir = (myHRP.Position - tHRP.Position).Unit * State.SpeedValue
                myHRP.Velocity = Vector3.new(fleeDir.X, 0.5, fleeDir.Z)
                CurrentCoinTarget = nil
                return
            end
        end
    end
    
    -- หาเหรียญใหม่
    if not CurrentCoinTarget or not CurrentCoinTarget.Parent then
        CurrentCoinTarget = nil
        StuckTimer = 0
        local CoinContainer = Workspace:FindFirstChild("CoinContainer") or Workspace
        local nearestCoin, nearestDist = nil, math.huge
        
        for _, coin in ipairs(CoinContainer:GetDescendants()) do
            if coin.Name == "Coin" or coin.Name == "Cola" or coin:FindFirstChild("CoinVisual") then
                local coinPart = coin:IsA("BasePart") and coin or coin:FindFirstChildWhichIsA("BasePart")
                if coinPart and not CollectedCoins[coin] then
                    local dist = (myHRP.Position - coinPart.Position).Magnitude
                    if dist < nearestDist and dist < 120 then
                        nearestDist = dist
                        nearestCoin = coinPart
                    end
                end
            end
        end
        
        if nearestCoin then
            CurrentCoinTarget = nearestCoin
        else
            table.clear(CollectedCoins)
        end
        return
    end
    
    -- วิ่งลอยไปหาเหรียญ
    local dist = (myHRP.Position - CurrentCoinTarget.Position).Magnitude
    if dist <= 2.5 then
        CollectedCoins[CurrentCoinTarget] = true
        CurrentCoinTarget = nil
        StuckTimer = 0
        return
    end
    
    -- ตรวจสอบติดค้าง
    StuckTimer += deltaTime
    if StuckTimer > 2.5 then
        CurrentCoinTarget = nil
        StuckTimer = 0
        return
    end
    
    -- เคลื่อนที่ลอยตรง
    local dir = (CurrentCoinTarget.Position - myHRP.Position).Unit
    local speed = State.SpeedValue
    myHRP.Velocity = Vector3.new(dir.X * speed, dir.Y * math.min(speed * 0.3, 6), dir.Z * speed)
end))

-- FLING LOOP
addConnection(RunService.Heartbeat:Connect(function()
    if not (State.FlingMurderer or State.FlingSheriff or State.FlingInnocent) then return end
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and isAlive(player) then
            local role = getRole(player)
            if (role == "Murderer" and State.FlingMurderer)
            or (role == "Sheriff" and State.FlingSheriff)
            or (role == "Innocent" and State.FlingInnocent) then
                local tHRP = getHRP(player.Character)
                if tHRP then FlingTarget(tHRP) end
            end
        end
    end
end))

-- MAIN FRAME
local Main = Instance.new("Frame")
Main.Name = "MainFrame"
Main.Size = UDim2.new(0, 350, 0, 400)
Main.Position = UDim2.new(0.5, -175, 0.5, -200)
Main.BackgroundColor3 = Color3.fromRGB(18, 18, 26)
Main.BorderSizePixel = 0
Main.Visible = false
Main.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 12)
MainCorner.Parent = Main

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(80, 80, 120)
MainStroke.Thickness = 1
MainStroke.Parent = Main

-- แถบชื่อเมนู
local TitleBar = Instance.new("Frame")
TitleBar.Name = "TitleBar"
TitleBar.Size = UDim2.new(1, 0, 0, 40)
TitleBar.BackgroundColor3 = Color3.fromRGB(28, 28, 42)
TitleBar.BorderSizePixel = 0
TitleBar.Parent = Main

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 12)
TitleCorner.Parent = TitleBar

local TitleBarCover = Instance.new("Frame")
TitleBarCover.Size = UDim2.new(1, 0, 0.5, 0)
TitleBarCover.Position = UDim2.new(0, 0, 0.5, 0)
TitleBarCover.BackgroundColor3 = Color3.fromRGB(28, 28, 42)
TitleBarCover.BorderSizePixel = 0
TitleBarCover.Parent = TitleBar

makeDraggable(Main, TitleBar)

-- ชื่อ
local Title = Instance.new("TextLabel")
Title.Name = "Title"
Title.Size = UDim2.new(1, -50, 1, 0)
Title.Position = UDim2.new(0, 12, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "MM2 APEX HUNTER v5.2"
Title.Font = Enum.Font.GothamBold
Title.TextSize = 15
Title.TextColor3 = Color3.fromRGB(255, 70, 70)
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TitleBar

-- ปุ่มปิด
local CloseBtn = Instance.new("TextButton")
CloseBtn.Name = "CloseBtn"
CloseBtn.Size = UDim2.new(0, 26, 0, 26)
CloseBtn.Position = UDim2.new(1, -34, 0, 7)
CloseBtn.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
CloseBtn.BorderSizePixel = 0
CloseBtn.Text = "X"
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 14
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.AutoButtonColor = false
CloseBtn.Parent = TitleBar

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 6)
CloseCorner.Parent = CloseBtn

CloseBtn.MouseEnter:Connect(function()
    TweenService:Create(CloseBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(255, 70, 70)}):Play()
end)
CloseBtn.MouseLeave:Connect(function()
    TweenService:Create(CloseBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(220, 50, 50)}):Play()
end)

-- พื้นที่เนื้อหา
local Content = Instance.new("ScrollingFrame")
Content.Name = "Content"
Content.Size = UDim2.new(1, -16, 1, -52)
Content.Position = UDim2.new(0, 8, 0, 46)
Content.BackgroundTransparency = 1
Content.BorderSizePixel = 0
Content.ScrollBarThickness = 3
Content.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 140)
Content.CanvasSize = UDim2.new(0, 0, 0, 0)
Content.AutomaticCanvasSize = Enum.AutomaticSize.Y
Content.Parent = Main

local ContentLayout = Instance.new("UIListLayout")
ContentLayout.Padding = UDim.new(0, 6)
ContentLayout.SortOrder = Enum.SortOrder.LayoutOrder
ContentLayout.Parent = Content

local ContentPad = Instance.new("UIPadding")
ContentPad.PaddingBottom = UDim.new(0, 8)
ContentPad.Parent = Content

local yOrder = 0

local function SectionLabel(text)
    yOrder += 1
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 0, 22)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 12
    lbl.TextColor3 = Color3.fromRGB(255, 90, 90)
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.LayoutOrder = yOrder
    lbl.Parent = Content
end

local function ToggleButton(text, stateKey, color)
    yOrder += 1
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, 0, 0, 36)
    container.BackgroundColor3 = Color3.fromRGB(30, 30, 44)
    container.LayoutOrder = yOrder
    container.Parent = Content
    Instance.new("UICorner", container).CornerRadius = UDim.new(0, 6)
    
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -60, 1, 0)
    lbl.Position = UDim2.new(0, 10, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.Font = Enum.Font.GothamSemibold
    lbl.TextSize = 13
    lbl.TextColor3 = Color3.fromRGB(220, 220, 235)
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = container
    
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 40, 0, 22)
    btn.Position = UDim2.new(1, -48, 0.5, -11)
    btn.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
    btn.BorderSizePixel = 0
    btn.Text = ""
    btn.AutoButtonColor = false
    btn.Parent = container
    Instance.new("UICorner", btn).CornerRadius = UDim.new(1, 0)
    
    local dot = Instance.new("Frame")
    dot.Size = UDim2.new(0, 16, 0, 16)
    dot.Position = UDim2.new(0, 3, 0.5, -8)
    dot.BackgroundColor3 = Color3.fromRGB(220, 220, 220)
    dot.Parent = btn
    Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)
    
    local activeColor = color or Color3.fromRGB(60, 200, 90)
    
    local function Update()
        if State[stateKey] then
            TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = activeColor}):Play()
            TweenService:Create(dot, TweenInfo.new(0.2), {Position = UDim2.new(1, -19, 0.5, -8)}):Play()
        else
            TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(60, 60, 80)}):Play()
            TweenService:Create(dot, TweenInfo.new(0.2), {Position = UDim2.new(0, 3, 0.5, -8)}):Play()
        end
    end
    
    btn.MouseButton1Click:Connect(function()
        State[stateKey] = not State[stateKey]
        Update()
        if stateKey == "ESP" and not State.ESP then ClearESP() end
    end)
    
    Update()
    return container
end

local function SliderControl(text, stateKey, minVal, maxVal, suffix)
    yOrder += 1
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, 0, 0, 48)
    container.BackgroundColor3 = Color3.fromRGB(30, 30, 44)
    container.LayoutOrder = yOrder
    container.Parent = Content
    Instance.new("UICorner", container).CornerRadius = UDim.new(0, 6)
    
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -70, 0, 18)
    lbl.Position = UDim2.new(0, 10, 0, 4)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.Font = Enum.Font.GothamSemibold
    lbl.TextSize = 12
    lbl.TextColor3 = Color3.fromRGB(220, 220, 235)
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = container
    
    local valLbl = Instance.new("TextLabel")
    valLbl.Size = UDim2.new(0, 60, 0, 18)
    valLbl.Position = UDim2.new(1, -65, 0, 4)
    valLbl.BackgroundTransparency = 1
    valLbl.Text = tostring(State[stateKey]) .. suffix
    valLbl.Font = Enum.Font.GothamBold
    valLbl.TextSize = 12
    valLbl.TextColor3 = Color3.fromRGB(255, 120, 60)
    valLbl.TextXAlignment = Enum.TextXAlignment.Right
    valLbl.Parent = container
    
    local track = Instance.new("Frame")
    track.Size = UDim2.new(1, -20, 0, 5)
    track.Position = UDim2.new(0, 10, 0, 32)
    track.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
    track.Parent = container
    Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)
    
    local fill = Instance.new("Frame")
    fill.Size = UDim2.new(0, 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(255, 120, 60)
    fill.Parent = track
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)
    
    local knob = Instance.new("TextButton")
    knob.Size = UDim2.new(0, 14, 0, 14)
    knob.Position = UDim2.new(0, -4, 0.5, -7)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.Text = ""
    knob.AutoButtonColor = false
    knob.Parent = track
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)
    
    local function SetValueAt(x)
        local p = math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        local val = math.floor(minVal + (maxVal - minVal) * p + 0.5)
        State[stateKey] = val
        valLbl.Text = tostring(val) .. suffix
        fill.Size = UDim2.new(p, 0, 1, 0)
        knob.Position = UDim2.new(p, -7, 0.5, -7)
    end
    
    local dragging = false
    addConnection(knob.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            SetValueAt(i.Position.X)
        end
    end))
    addConnection(UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end))
    addConnection(UserInputService.InputChanged:Connect(function(i)
        if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            SetValueAt(i.Position.X)
        end
    end))
    
    local initP = (State[stateKey] - minVal) / (maxVal - minVal)
    fill.Size = UDim2.new(initP, 0, 1, 0)
    knob.Position = UDim2.new(initP, -7, 0.5, -7)
end

-- สร้างเมนู
SectionLabel("🛡️  ระบบทั่วไป")
ToggleButton("ป้องกันหลุด (Anti-AFK)", "AntiAFK", Color3.fromRGB(100, 200, 255))

SectionLabel("⚔️  ระบบต่อสู้")
ToggleButton("ออร่าฆ่าอัตโนมัติ", "Aura", Color3.fromRGB(255, 80, 80))
SliderControl("ระยะออร่าฆ่า", "AuraRange", 10, 500, " ม.")

SectionLabel("🪙  ฟาร์มเหรียญ")
ToggleButton("ลอยเก็บเหรียญต่อเนื่อง", "AutoCoin", Color3.fromRGB(255, 215, 0))

SectionLabel("🌪️  ปั่นผู้เล่น")
ToggleButton("ปั่นฆาตกร", "FlingMurderer", Color3.fromRGB(255, 60, 60))
ToggleButton("ปั่นนายอำเภอ", "FlingSheriff", Color3.fromRGB(60, 140, 255))
ToggleButton("ปั่นคนบริสุทธิ์", "FlingInnocent", Color3.fromRGB(60, 220, 100))

SectionLabel("👁️  มองทะลุ")
ToggleButton("แสดงบทบาทผู้เล่น", "ESP", Color3.fromRGB(160, 80, 255))

SectionLabel("🏃  ตัวละคร")
ToggleButton("เดินทะลุกำแพง (Noclip)", "Noclip", Color3.fromRGB(255, 180, 40))
ToggleButton("เพิ่มความเร็ววิ่ง", "Speed", Color3.fromRGB(80, 220, 200))
SliderControl("ความเร็ววิ่ง/เก็บเหรียญ", "SpeedValue", 16, 200, "")

-- เปิด-ปิดเมนูด้วยไอคอน
local menuOpen = false
local pressStart = nil
local pressPos = nil

addConnection(Icon.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        pressStart = os.clock()
        pressPos = input.Position
    end
end))

addConnection(Icon.InputEnded:Connect(function(input)
    if pressStart and os.clock() - pressStart < 0.3 then
        if (input.Position - pressPos).Magnitude < 15 then
            menuOpen = not menuOpen
            Main.Visible = menuOpen
        end
    end
end))

CloseBtn.MouseButton1Click:Connect(function()
    Main.Visible = false
    menuOpen = false
end)

-- ฟังก์ชันเคลียร์เมื่อปิด
_G.MM2_Cleanup = function()
    for _, conn in ipairs(Connections) do
        pcall(function() conn:Disconnect() end)
    end
    Connections = {}
    ClearESP()
    pcall(function() ScreenGui:Destroy() end)
end

print("✅ MM2 APEX HUNTER v5.2 โหลดสำเร็จ!")
print("💡 กดที่ตัวอักษร M มุมขวาล่างเพื่อเปิดเมนู")
print("🪙 Auto Coin: วิ่งลอยเก็บเหรียญ — ปรับความเร็วได้จากแถบ")
