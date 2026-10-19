--[[
    ============================================================
    MM2 AUTO COIN + AFK MODE — FULL FIXED VERSION
    ✅ เปลี่ยนวิธีเคลื่อนที่ให้เชื่อถือได้มากขึ้น
    ✅ เพิ่มข้อความแจ้งเตือนชัดเจนที่คอนโซล
    ✅ SpeedValue = 20 (เปลี่ยนได้ที่จุดเดียวด้านบน)
    ✅ รองรับมือถือ Delta / Fluxus / Arceus X
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
    print("❌ Executor ไม่รองรับ getgenv")
    return
end

-- ป้องกันรันซ้ำและเคลียร์ของเก่า
if getgenv().MM2_AutoCoin_Cleanup then
    pcall(function() getgenv().MM2_AutoCoin_Cleanup() end)
end

-- ==============================================
-- 📍 จุดเดียวที่ต้องแก้ ถ้าอยากเปลี่ยนความเร็ว
-- ==============================================
local State = {
    AutoCoin    = false,
    SpeedValue  = 20,   -- ✅ เปลี่ยนเลขตรงนี้ได้เลย
    LastDebug   = 0
}

local Connections = {}

-- HELPER FUNCTIONS
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

-- CREATE UI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MM2_AutoCoin_Only"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

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

-- SPEED LOOP
addConnection(RunService.Heartbeat:Connect(function()
    local hum = getHumanoid(LocalPlayer.Character)
    if hum then
        hum.WalkSpeed = State.AutoCoin and State.SpeedValue or 16
    end
end))

-- NOCLIP
addConnection(RunService.Stepped:Connect(function()
    local char = LocalPlayer.Character
    if not char then return end
    for _, descendant in ipairs(char:GetDescendants()) do
        if descendant:IsA("BasePart") then
            descendant.CanCollide = not State.AutoCoin
            descendant.CanTouch = not State.AutoCoin
        end
    end
end))

-- AUTO COIN SYSTEM
local CollectedCoins = {}
local CurrentCoinTarget = nil
local StuckTimer = 0
local LastPos = Vector3.new(0, 0, 0)
local NoMoveTimer = 0

addConnection(LocalPlayer.CharacterAdded:Connect(function()
    table.clear(CollectedCoins)
    CurrentCoinTarget = nil
    StuckTimer = 0
    NoMoveTimer = 0
    LastPos = Vector3.new(math.huge, math.huge, math.huge)
    print("✅ พร้อมทำงาน — AFK Mode")
end))

-- ลูปหลัก — ปรับปรุงใหม่ ใช้ Move + Velocity คู่กัน เพิ่มความมั่นใจ
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
        print("🟢 กำลังทำงาน... หาเหรียญ")
    end

    local myChar = LocalPlayer.Character
    local myHRP = getHRP(myChar)
    local myHum = getHumanoid(myChar)
    if not myHRP or not myHum then return end

    -- เช็คว่ามีเหรียญจริงไหม
    local coinContainer = Workspace:FindFirstChild("CoinContainer")
    if not coinContainer then
        if os.time() - State.LastDebug > 3 then
            print("⚠️ ยังไม่พบ CoinContainer รอเริ่มเกม...")
        end
        return
    end
    
    local coinCount = #coinContainer:GetDescendants()
    if coinCount == 0 then
        return
    end

    -- ป้องกันติดค้าง
    if (myHRP.Position - LastPos).Magnitude < 0.15 then
        NoMoveTimer += deltaTime
        if NoMoveTimer > 4 then
            CurrentCoinTarget = nil
            NoMoveTimer = 0
            table.clear(CollectedCoins)
            print("🔄 รีเซ็ตเป้าหมาย เพราะติดค้าง")
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
                local dir = (myHRP.Position - theirHRP.Position).Unit
                myHRP.Velocity = Vector3.new(dir.X * State.SpeedValue, 0.8, dir.Z * State.SpeedValue)
                CurrentCoinTarget = nil
                print("⚠️ หนีฆาตกร!")
                return
            end
        end
    end

    -- หาเหรียญใหม่
    if not CurrentCoinTarget or not CurrentCoinTarget.Parent then
        StuckTimer = 0
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
            print("✅ เจอเหรียญ ระยะ: " .. math.floor(nearestDist) .. " สต.")
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
        print("🪙 เก็บเหรียญสำเร็จ!")
        return
    end

    -- รีเซ็ตถ้าติดนานเกินไป
    StuckTimer += deltaTime
    if StuckTimer > 3 then
        CurrentCoinTarget = nil
        StuckTimer = 0
        return
    end

    -- ✅ เคลื่อนที่ — ใช้ทั้ง Move และ Velocity คู่กัน
    local dir = (CurrentCoinTarget.Position - myHRP.Position).Unit
    local moveVec = Vector3.new(dir.X * State.SpeedValue, 0, dir.Z * State.SpeedValue)
    
    -- วิธีที่ 1: ใช้ Humanoid:Move
    myHum:Move(moveVec.X, moveVec.Y, moveVec.Z)
    
    -- วิธีที่ 2: ใช้ Velocity สำรอง ถ้าอันแรกไม่ได้ผล
    myHRP.Velocity = Vector3.new(dir.X * State.SpeedValue, math.max(dir.Y * State.SpeedValue, 0.5), dir.Z * State.SpeedValue)
end))

-- ==================== UI ====================
local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, 240, 0, 85)
Main.Position = UDim2.new(1, -255, 0, 15)
Main.BackgroundColor3 = Color3.fromRGB(18, 18, 26)
Main.Parent = ScreenGui
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 12)
local stroke = Instance.new("UIStroke", Main)
stroke.Color = Color3.fromRGB(255, 215, 0)
stroke.Thickness = 1

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
    print(State.AutoCoin and "✅ เปิด Auto Coin — เริ่มทำงาน" or "❌ ปิด Auto Coin")
    UpdateToggle()
end)

CloseBtn.MouseButton1Click:Connect(function()
    pcall(function() getgenv().MM2_AutoCoin_Cleanup() end)
end)

print("✅ MM2 Auto Coin Loaded! UI ที่มุมขวาบน")
print("💡 กดเปิดสวิตช์ แล้วดูข้อความที่คอนโซล ถ้ายังไม่ขยับ บอกข้อความที่ขึ้นมาทางนี้นะครับ!")
