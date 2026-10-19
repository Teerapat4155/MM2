--[[
    ============================================================
    MM2 AUTO COIN + AFK MODE — CLEAN & STRUCTURED VERSION
    ✅ รันทันทีเมื่อกด Execute | ไม่ต้องมีคำสั่ง Start
    ✅ Auto Coin + หนีฆาตกร + ทะลุกำแพง + AFK Mode
    ✅ ปุ่มเปิด-ปิด + ปิดระบบทั้งหมด
    ============================================================
]]

-- ==============================================
-- 1. SERVICES & VARIABLES — ทำงานทันทีเมื่อรัน
-- ==============================================
local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local CoreGui           = game:GetService("CoreGui")
local UserInputService  = game:GetService("UserInputService")
local TweenService      = game:GetService("TweenService")
local Workspace         = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer

-- ตรวจสอบสภาพแวดล้อม
if not getgenv then
    print("❌ Executor ไม่รองรับ getgenv")
    return
end

-- เคลียร์ของเก่าก่อน
if getgenv().MM2_AutoCoin_Cleanup then
    pcall(function() getgenv().MM2_AutoCoin_Cleanup() end)
end

-- ตัวแปรสถานะหลัก
local State = {
    AutoCoin    = false,
    SpeedValue  = 25,
    LastDebug   = 0
}
local Connections = {}

-- ==============================================
-- 2. HELPER FUNCTIONS — ประกาศไว้ก่อน ใช้งานทีหลัง
-- ==============================================
local function addConnection(conn)
    table.insert(Connections, conn)
    return conn
end

local function getHRP(char)
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function getHumanoid(char)
    return char and char:FindFirstChild("Humanoid")
end

local function isAlive(player)
    local hum = getHumanoid(player.Character)
    return hum and hum.Health > 0
end

local function getRole(player)
    local char = player.Character
    if not char then return "Innocent" end
    local role = char:FindFirstChild("Role")
    return role and role.Value or "Innocent"
end

local function makeDraggable(frame, dragArea)
    local dragging, input, startPos, startFrame
    dragArea = dragArea or frame
    addConnection(dragArea.InputBegan:Connect(function(t)
        if t.UserInputType == Enum.UserInputType.MouseButton1 or t.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            startPos = t.Position
            startFrame = frame.Position
        end
    end))
    addConnection(dragArea.InputChanged:Connect(function(t)
        if t.UserInputType == Enum.UserInputType.MouseMovement or t.UserInputType == Enum.UserInputType.Touch then
            input = t
        end
    end))
    addConnection(UserInputService.InputChanged:Connect(function(t)
        if t == input and dragging then
            local d = t.Position - startPos
            frame.Position = UDim2.new(
                startFrame.X.Scale, startFrame.X.Offset + d.X,
                startFrame.Y.Scale, startFrame.Y.Offset + d.Y
            )
        end
    end))
    addConnection(UserInputService.InputEnded:Connect(function()
        dragging = false
    end))
end

-- ==============================================
-- 3. CREATE UI — ทำงานทันทีเมื่อรัน
-- ==============================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MM2_AutoCoin_Only"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- ใส่ Parent ให้ถูกต้อง
local ok = pcall(function() if gethui then ScreenGui.Parent = gethui() end end)
if not ok or not ScreenGui.Parent then
    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    ScreenGui.Parent = pg or CoreGui
end

-- ฟังก์ชันปิดระบบทั้งหมด
getgenv().MM2_AutoCoin_Cleanup = function()
    State.AutoCoin = false
    local hum = getHumanoid(LocalPlayer.Character)
    if hum then hum.WalkSpeed = 16 end
    for _, c in ipairs(Connections) do pcall(function() c:Disconnect() end) end
    table.clear(Connections)
    pcall(function() ScreenGui:Destroy() end)
    print("❌ ปิดระบบเรียบร้อย")
end

-- ==============================================
-- 4. SYSTEM LOOPS — :Connect() = เริ่มทำงานเองทันที
-- ==============================================

-- ควบคุมความเร็ว
addConnection(RunService.Heartbeat:Connect(function()
    local hum = getHumanoid(LocalPlayer.Character)
    if hum then
        hum.WalkSpeed = State.AutoCoin and State.SpeedValue or 16
    end
end))

-- Noclip ทะลุกำแพง
addConnection(RunService.Stepped:Connect(function()
    local char = LocalPlayer.Character
    if not char then return end
    for _, part in ipairs(char:GetChildren()) do
        if part:IsA("BasePart") then
            part.CanCollide = not State.AutoCoin
        end
    end
end))

-- ตัวแปรระบบเก็บเหรียญ
local CollectedCoins = {}
local CurrentCoinTarget = nil
local StuckTimer = 0
local LastPos = Vector3.new(0, 0, 0)
local NoMoveTimer = 0

-- รีเซ็ตตอนเกิดใหม่
addConnection(LocalPlayer.CharacterAdded:Connect(function()
    table.clear(CollectedCoins)
    CurrentCoinTarget = nil
    StuckTimer = 0
    NoMoveTimer = 0
    LastPos = Vector3.new(math.huge, math.huge, math.huge)
    print("✅ พร้อมทำงาน — AFK Mode")
end))

-- ลูปหลักเก็บเหรียญ — ทำงานเองทุกเฟรม
addConnection(RunService.Heartbeat:Connect(function(deltaTime)
    if not State.AutoCoin then
        CurrentCoinTarget = nil
        StuckTimer = 0
        NoMoveTimer = 0
        return
    end

    -- แสดงสถานะทุก 3 วินาที
    if os.time() - State.LastDebug > 3 then
        State.LastDebug = os.time()
        print("🟢 กำลังทำงาน...")
    end

    local myHRP = getHRP(LocalPlayer.Character)
    if not myHRP then return end

    -- ป้องกันติดค้าง
    if (myHRP.Position - LastPos).Magnitude < 0.1 then
        NoMoveTimer += deltaTime
        if NoMoveTimer > 4 then
            CurrentCoinTarget = nil
            NoMoveTimer = 0
            table.clear(CollectedCoins)
        end
    else
        NoMoveTimer = 0
        LastPos = myHRP.Position
    end

    -- หนีฆาตกร
    for _, p in ipairs(Players:GetPlayers()) do
        if getRole(p) == "Murderer" and isAlive(p) then
            local theirHRP = getHRP(p.Character)
            if theirHRP and (myHRP.Position - theirHRP.Position).Magnitude <= 15 then
                local dir = (myHRP.Position - theirHRP.Position).Unit * State.SpeedValue
                myHRP.Velocity = Vector3.new(dir.X, 0.8, dir.Z)
                CurrentCoinTarget = nil
                return
            end
        end
    end

    -- หาเหรียญ
    if not CurrentCoinTarget or not CurrentCoinTarget.Parent then
        StuckTimer = 0
        local coinContainer = Workspace:FindFirstChild("CoinContainer")
        if not coinContainer then return end
        local nearestCoin, nearestDist = nil, math.huge
        for _, coin in ipairs(coinContainer:GetDescendants()) do
            if coin.Name == "Coin" or coin.Name == "Cola" or coin:FindFirstChild("CoinVisual") then
                local part = coin:IsA("BasePart") and coin or coin:FindFirstChildWhichIsA("BasePart")
                if part and not CollectedCoins[coin] then
                    local d = (myHRP.Position - part.Position).Magnitude
                    if d < nearestDist and d < 150 then
                        nearestDist = d
                        nearestCoin = part
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

    -- เก็บเหรียญเมื่อใกล้
    local dist = (myHRP.Position - CurrentCoinTarget.Position).Magnitude
    if dist <= 3 then
        CollectedCoins[CurrentCoinTarget] = true
        CurrentCoinTarget = nil
        StuckTimer = 0
        return
    end

    -- รีเซ็ตถ้าติด
    StuckTimer += deltaTime
    if StuckTimer > 3 then
        CurrentCoinTarget = nil
        StuckTimer = 0
        return
    end

    -- เคลื่อนที่ไปหาเหรียญ
    local dir = (CurrentCoinTarget.Position - myHRP.Position).Unit
    myHRP.Velocity = Vector3.new(
        dir.X * State.SpeedValue,
        math.max(dir.Y * State.SpeedValue, 0.5),
        dir.Z * State.SpeedValue
    )
end))

-- ==============================================
-- 5. BUILD UI — สร้างหน้าต่าง ควบคุม ปุ่ม
-- ==============================================

-- กล่องหลัก
local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, 240, 0, 85)
Main.Position = UDim2.new(1, -255, 0, 15)
Main.BackgroundColor3 = Color3.fromRGB(18, 18, 26)
Main.Parent = ScreenGui
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 12)
local stroke = Instance.new("UIStroke", Main)
stroke.Color = Color3.fromRGB(255, 215, 0)
stroke.Thickness = 1

-- แถบชื่อ (ลากได้)
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 32)
TitleBar.BackgroundColor3 = Color3.fromRGB(28, 28, 42)
TitleBar.Parent = Main
Instance.new("UICorner", TitleBar).CornerRadius = UDim.new(0, 12)
local cover = Instance.new("Frame", TitleBar)
cover.Size = UDim2.new(1, 0, 0.5, 0)
cover.Position = UDim2.new(0, 0, 0.5, 0)
cover.BackgroundColor3 = Color3.fromRGB(28, 28, 42)
makeDraggable(Main, TitleBar)

-- ชื่อเมนู
local Title = Instance.new("TextLabel")
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
CloseBtn.Size = UDim2.new(0, 22, 0, 22)
CloseBtn.Position = UDim2.new(1, -26, 0, 5)
CloseBtn.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
CloseBtn.Text = "X"
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 12
CloseBtn.TextColor3 = Color3.new(1,1,1)
CloseBtn.AutoButtonColor = false
CloseBtn.Parent = TitleBar
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 5)
CloseBtn.MouseEnter:Connect(function()
    TweenService:Create(CloseBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(255,70,70)}):Play()
end)
CloseBtn.MouseLeave:Connect(function()
    TweenService:Create(CloseBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(220,50,50)}):Play()
end)

-- สวิตช์เปิดปิด
local ToggleContainer = Instance.new("Frame")
ToggleContainer.Size = UDim2.new(1, -12, 1, -12)
ToggleContainer.Position = UDim2.new(0, 6, 0, 38)
ToggleContainer.BackgroundColor3 = Color3.fromRGB(30, 30, 44)
ToggleContainer.Parent = Main
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
    print(State.AutoCoin and "✅ เปิด Auto Coin" or "❌ ปิด Auto Coin")
    UpdateToggle()
end)

CloseBtn.MouseButton1Click:Connect(function()
    pcall(function() getgenv().MM2_AutoCoin_Cleanup() end)
end)

-- ==============================================
-- ✅ พร้อมทำงานทันทีที่รัน
-- ==============================================
print("✅ MM2 Auto Coin Loaded! UI ที่มุมขวาบน")
