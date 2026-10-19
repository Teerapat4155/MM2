--[[
    ============================================================
    MM2 AUTO COIN — ANTI-VOID & ANTI-WALL FIX
    ✅ ล็อกแกน Y ไม่ให้ร่วงตกแมพ / ทะลุพื้นตาย
    ✅ กรองเฉพาะเหรียญที่อยู่บนพื้นจริง ไม่หลุดออกนอกแมพ
    ✅ เข้ากลางเหรียญสมูท + หน่วงเวลาตามวินาทีที่ตั้งไว้
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

if not getgenv then
    print("❌ Executor ไม่รองรับ")
    return
end

if getgenv().MM2_AutoCoin_Cleanup then
    pcall(function() getgenv().MM2_AutoCoin_Cleanup() end)
end

local State = {
    Enabled = false,
    Speed   = 22,
}
local Connections = {}
local TargetCoin = nil
local ResumeTime = 0
local OriginalCanCollide = {}

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

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MM2_AutoCoin"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local ok = pcall(function() if gethui then ScreenGui.Parent = gethui() end end)
if not ok or not ScreenGui.Parent then
    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    ScreenGui.Parent = pg or CoreGui
end

getgenv().MM2_AutoCoin_Cleanup = function()
    State.Enabled = false
    TargetCoin = nil
    ResumeTime = 0
    OriginalCanCollide = {}
    local h = getHumanoid(LocalPlayer.Character)
    if h then h.WalkSpeed = 16 end
    local c = LocalPlayer.Character
    if c then
        for part, orig in pairs(OriginalCanCollide) do
            if part and part.Parent then
                pcall(function() part.CanCollide = orig end)
            end
        end
    end
    for _, cnn in ipairs(Connections) do pcall(function() cnn:Disconnect() end) end
    table.clear(Connections)
    pcall(function() ScreenGui:Destroy() end)
    print("❌ ปิดระบบ Auto Coin เรียบร้อย")
end

-- SPEED
addConnection(RunService.Heartbeat:Connect(function()
    local h = getHumanoid(LocalPlayer.Character)
    if h then
        h.WalkSpeed = State.Enabled and State.Speed or 16
    end
end))

-- NOCLIP (ปิดการทะลุกำแพงชั่วคราวเมื่อตัวละครตกต่ำกว่าพิกัดความปลอดภัย ป้องกันร่วงแมพ)
addConnection(RunService.Stepped:Connect(function()
    local c = LocalPlayer.Character
    if not c then return end
    local hrp = getHRP(c)
    -- ถ้าตัวละครร่วงต่ำกว่าพิกัด Y โลก (-50) ให้ปิด Noclip ทันทีเพื่อกันตาย
    local isSafeY = hrp and hrp.Position.Y > -40

    for _, part in ipairs(c:GetDescendants()) do
        if part:IsA("BasePart") then
            if OriginalCanCollide[part] == nil then
                OriginalCanCollide[part] = part.CanCollide
            end
            part.CanCollide = not (State.Enabled and isSafeY)
        end
    end
end))

addConnection(LocalPlayer.CharacterAdded:Connect(function()
    TargetCoin = nil
    ResumeTime = 0
    OriginalCanCollide = {}
end))

-- ==============================================
-- ✅ ลูปหลัก: ป้องกันตกแมพ + ล็อกความปลอดภัย
-- ==============================================
addConnection(RunService.Heartbeat:Connect(function(deltaTime)
    if not State.Enabled then
        TargetCoin = nil
        ResumeTime = 0
        return
    end

    local DELAY_SECONDS = 1 -- ปรับเวลาหน่วงตรงนี้ได้ (หน่วยเป็นวินาที)

    if tick() < ResumeTime then
        return 
    end

    local myHRP = getHRP(LocalPlayer.Character)
    local myHum = getHumanoid(LocalPlayer.Character)
    if not myHRP or not myHum then return end

    -- ระบบป้องกันตกแมพฉุกเฉิน: ถ้าเผลอร่วงไปต่ำกว่า -35 ให้รีบดีดตัวกลับขึ้นมาบนฟ้าทันที
    if myHRP.Position.Y < -35 then
        myHRP.CFrame = CFrame.new(myHRP.Position.X, 10, myHRP.Position.Z)
        TargetCoin = nil
        return
    end

    -- หา CoinContainer
    local CoinContainer = Workspace:FindFirstChild("CoinContainer") or Workspace:FindFirstChild("Normal")
    if not CoinContainer then
        for _, v in ipairs(Workspace:GetChildren()) do
            if v:FindFirstChild("CoinContainer") or string.find(string.lower(v.Name), "coin") then
                CoinContainer = v:FindFirstChild("CoinContainer") or v
                break
            end
        end
    end
    if not CoinContainer then return end

    -- หาเป้าหมายที่อยู่บนพื้นจริง (กรองเหรียญที่หลุดออกนอกแมพหรือต่ำเกินไปออก)
    if not TargetCoin or not TargetCoin.Parent then
        local nearest, distNearest = nil, math.huge
        for _, coin in ipairs(CoinContainer:GetChildren()) do
            if coin:IsA("BasePart") then
                -- เช็คว่าเหรียญต้องไม่ต่ำกว่าระดับพื้นแมพ ( Y > -30 )
                if coin.Position.Y > -30 then
                    local dist = (myHRP.Position - coin.Position).Magnitude
                    if dist < distNearest then
                        distNearest = dist
                        nearest = coin
                    end
                end
            end
        end
        TargetCoin = nearest
    end

    if not TargetCoin then return end

    local coinPos = TargetCoin.Position
    local myPos = myHRP.Position
    local dist = (myPos - coinPos).Magnitude

    if dist <= 1.2 then
        TargetCoin = nil
        ResumeTime = tick() + DELAY_SECONDS
        return
    end

    -- ล็อกความสูงให้อยู่ในระดับพอดีกับเหรียญ ไม่ให้มุดลงใต้พื้น
    local targetPos = Vector3.new(coinPos.X, math.max(coinPos.Y, myPos.Y - 2), coinPos.Z)
    local step = math.min(dist, State.Speed * deltaTime * 60)
    myHRP.CFrame = CFrame.new(myPos:Lerp(targetPos, step / dist))
    myHRP.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
    myHRP.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
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
ToggleLbl.Text = "เปิด Auto Coin + Noclip"
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
    if State.Enabled then
        TweenService:Create(ToggleBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(255, 215, 0)}):Play()
        TweenService:Create(ToggleDot, TweenInfo.new(0.2), {Position = UDim2.new(1, -17, 0.5, -7)}):Play()
    else
        TweenService:Create(ToggleBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(60, 60, 80)}):Play()
        TweenService:Create(ToggleDot, TweenInfo.new(0.2), {Position = UDim2.new(0, 3, 0.5, -7)}):Play()
    end
end

ToggleBtn.MouseButton1Click:Connect(function()
    State.Enabled = not State.Enabled
    print(State.Enabled and "✅ เปิดระบบ Auto Coin (ป้องกันตกแมพและทะลุกำแพง)" or "❌ ปิดระบบ")
    UpdateToggle()
end)

CloseBtn.MouseButton1Click:Connect(function()
    pcall(function() getgenv().MM2_AutoCoin_Cleanup() end)
end)

print("✅ MM2 Auto Coin Loaded!")
print("🛡️ อัปเดตระบบกันตกแมพและกรองพิกัดพื้นเรียบร้อย!")
