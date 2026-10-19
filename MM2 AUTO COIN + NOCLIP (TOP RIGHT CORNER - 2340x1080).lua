--[[
    ============================================================
    MM2 AUTO COIN + NOCLIP (TOP RIGHT CORNER - 2340x1080)
    ✅ Auto Coin: วิ่งลอยเก็บเหรียญ (เก็บเหรียญบนหัวและชั้นสองได้)
    ✅ Noclip: เดินทะลุกำแพงอัตโนมัติเมื่อเปิด
    ✅ ล็อกความเร็วที่ 25
    ✅ ตำแหน่ง: มุมขวาบน (จอ 2340x1080)
    ============================================================
]]

-- SERVICES
local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local CoreGui           = game:GetService("CoreGui")
local UserInputService  = game:GetService("UserInputService")
local TweenService      = game:GetService("TweenService")
local Workspace         = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer

-- CHECK EXECUTOR
if not getgenv then
    print("❌ Executor ของคุณไม่รองรับ")
    return
end

-- ป้องกันรันซ้ำ
if getgenv().MM2_AutoCoin_GUI then
    pcall(function() getgenv().MM2_AutoCoin_GUI:Destroy() end)
end

-- ตัวแปรสถานะ
local State = {
    AutoCoin    = false,
    SpeedValue  = 25,
}

local Connections = {}

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

-- ดึงบทบาทผู้เล่น (ใช้เช็คหนีฆาตกร)
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
ScreenGui.Name = "MM2_AutoCoin_Only"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
if gethui then
    ScreenGui.Parent = gethui()
else
    ScreenGui.Parent = CoreGui
end
getgenv().MM2_AutoCoin_GUI = ScreenGui

-- SPEED LOOP (ล็อกความเร็วที่ 25 เมื่อเปิด Auto Coin)
addConnection(RunService.Heartbeat:Connect(function()
    local char = LocalPlayer.Character
    local hum = char and getHumanoid(char)
    if hum then
        hum.WalkSpeed = State.AutoCoin and State.SpeedValue or 16
    end
end))

-- NOCLIP LOOP (เดินทะลุกำแพงอัตโนมัติเมื่อเปิดใช้งาน)
local originalCanCollide = {}
addConnection(RunService.Stepped:Connect(function()
    local char = LocalPlayer.Character
    if not char then return end
    for _, part in ipairs(char:GetChildren()) do
        if part:IsA("BasePart") then
            if State.AutoCoin then
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

-- AUTO COIN SYSTEM (เก็บเหรียญรอบตัวและบนชั้นสอง/บนหัวได้อิสระ)
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
    
    -- หนีฆาตกรอัตโนมัติ
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
                    if dist < nearestDist and dist < 150 then
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
    
    -- เคลื่อนที่ลอยตรง (พุ่งขึ้นบนหรือลงล่างได้อย่างอิสระ)
    local dir = (CurrentCoinTarget.Position - myHRP.Position).Unit
    local speed = State.SpeedValue
    myHRP.Velocity = Vector3.new(dir.X * speed, dir.Y * speed, dir.Z * speed)
end))

-- MAIN FRAME (ขนาดกะทัดรัด ล็อกตำแหน่งมุมขวาบนสำหรับจอ 2340x1080)
local Main = Instance.new("Frame")
Main.Name = "MainFrame"
Main.Size = UDim2.new(0, 240, 0, 85)
Main.Position = UDim2.new(1, -255, 0, 15) -- มุมขวาบน เว้นขอบจอ 15 พิกเซล
Main.BackgroundColor3 = Color3.fromRGB(18, 18, 26)
Main.BorderSizePixel = 0
Main.Visible = true
Main.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 12)
MainCorner.Parent = Main

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(255, 215, 0)
MainStroke.Thickness = 1
MainStroke.Parent = Main

-- แถบชื่อเมนู
local TitleBar = Instance.new("Frame")
TitleBar.Name = "TitleBar"
TitleBar.Size = UDim2.new(1, 0, 0, 32)
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
Title.Size = UDim2.new(1, -40, 1, 0)
Title.Position = UDim2.new(0, 10, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "MM2 AUTO COIN"
Title.Font = Enum.Font.GothamBold
Title.TextSize = 13
Title.TextColor3 = Color3.fromRGB(255, 215, 0)
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TitleBar

-- ปุ่มปิด
local CloseBtn = Instance.new("TextButton")
CloseBtn.Name = "CloseBtn"
CloseBtn.Size = UDim2.new(0, 22, 0, 22)
CloseBtn.Position = UDim2.new(1, -26, 0, 5)
CloseBtn.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
CloseBtn.BorderSizePixel = 0
CloseBtn.Text = "X"
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 12
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.AutoButtonColor = false
CloseBtn.Parent = TitleBar

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 5)
CloseCorner.Parent = CloseBtn

CloseBtn.MouseEnter:Connect(function()
    TweenService:Create(CloseBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(255, 70, 70)}):Play()
end)
CloseBtn.MouseLeave:Connect(function()
    TweenService:Create(CloseBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(220, 50, 50)}):Play()
end)

-- พื้นที่สวิตช์
local Content = Instance.new("Frame")
Content.Name = "Content"
Content.Size = UDim2.new(1, -12, 1, -38)
Content.Position = UDim2.new(0, 6, 0, 34)
Content.BackgroundTransparency = 1
Content.BorderSizePixel = 0
Content.Parent = Main

local ToggleContainer = Instance.new("Frame")
ToggleContainer.Size = UDim2.new(1, 0, 1, -6)
ToggleContainer.Position = UDim2.new(0, 0, 0, 3)
ToggleContainer.BackgroundColor3 = Color3.fromRGB(30, 30, 44)
ToggleContainer.Parent = Content
Instance.new("UICorner", ToggleContainer).CornerRadius = UDim.new(0, 6)

local ToggleLbl = Instance.new("TextLabel")
ToggleLbl.Size = UDim2.new(1, -55, 1, 0)
ToggleLbl.Position = UDim2.new(0, 8, 0, 0)
ToggleLbl.BackgroundTransparency = 1
ToggleLbl.Text = "เปิด Auto Coin"
ToggleLbl.Font = Enum.Font.GothamSemibold
ToggleLbl.TextSize = 12
ToggleLbl.TextColor3 = Color3.fromRGB(220, 220, 235)
ToggleLbl.TextXAlignment = Enum.TextXAlignment.Left
ToggleLbl.Parent = ToggleContainer

local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(0, 38, 0, 20)
ToggleBtn.Position = UDim2.new(1, -44, 0.5, -10)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
ToggleBtn.BorderSizePixel = 0
ToggleBtn.Text = ""
ToggleBtn.AutoButtonColor = false
ToggleBtn.Parent = ToggleContainer
Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(1, 0)

local ToggleDot = Instance.new("Frame")
ToggleDot.Size = UDim2.new(0, 14, 0, 14)
ToggleDot.Position = UDim2.new(0, 3, 0.5, -7)
ToggleDot.BackgroundColor3 = Color3.fromRGB(220, 220, 220)
ToggleDot.Parent = ToggleBtn
Instance.new("UICorner", ToggleDot).CornerRadius = UDim.new(1, 0)

local function UpdateToggle()
    if State.AutoCoin then
        TweenService:Create(ToggleBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(255, 215, 0)}):Play()
        TweenService:Create(ToggleDot, TweenInfo.new(0.2), {Position = UDim2.new(1, -17, 0.5, -7)}):Play()
    else
        TweenService:Create(ToggleBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(60, 60, 80)}):Play()
        TweenService:Create(ToggleDot, TweenInfo.new(0.2), {Position = UDim2.new(0, 3, 0.5, -7)}):Play()
    end
end

ToggleBtn.MouseButton1Click:Connect(function()
    State.AutoCoin = not State.AutoCoin
    UpdateToggle()
end)

CloseBtn.MouseButton1Click:Connect(function()
    pcall(function() ScreenGui:Destroy() end)
end)

print("✅ MM2 Auto Coin + Noclip Loaded Successfully!")
