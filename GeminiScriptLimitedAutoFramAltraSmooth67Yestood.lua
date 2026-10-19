--[[
    ============================================================
    MM2 MASTER SCRIPT — 2340x1080 RESOLUTION OPTIMIZED
    ✅ ปรับสเกลไอคอนลอยและหน้าต่างให้พอดีเป๊ะกับจอ 2340x1080
    ✅ Auto Coin (เข้ากลาง + หน่วง 1 วิ + กันตกแมพ)
    ✅ Smart Aura Kill (เช็ค Murder อัตโนมัติ + ดึงมีด + 300ม.)
    ✅ ESP Box (กรอบสีตามบทบาท คลีนๆ ไม่มีชื่อรกตา)
    ✅ Anti-AFK ป้องกันหลุดจากเซิร์ฟเวอร์
    ============================================================
]]

local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local TweenService      = game:GetService("TweenService")
local Workspace         = game:GetService("Workspace")
local VirtualUser       = game:GetService("VirtualUser")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- เคลียร์ของเก่าก่อนรัน
if _G.MM2_MasterScript then
    pcall(function() _G.MM2_MasterScript:Destroy() end)
end

if getgenv().MM2_Master_Cleanup then
    pcall(function() getgenv().MM2_Master_Cleanup() end)
end

local State = {
    AutoCoin    = false,
    AuraKill    = false,
    ESPEnabled  = false,
    AntiAFK     = true,
    Speed       = 22,
}

local Connections = {}
local TargetCoin = nil
local ResumeTime = 0
local OriginalCanCollide = {}
local ESPObjects = {}

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

-- ฟังก์ชันทำให้ UI หรือปุ่มลอยลากได้
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

-- สร้าง ScreenGui หลัก
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MM2_MasterScript"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = PlayerGui
_G.MM2_MasterScript = ScreenGui

-- ฟังก์ชันเช็ค Role แม่นยำ
local function getRole(player)
    local char = player.Character
    if not char then return "Innocent" end
    for _, item in ipairs(player.Backpack:GetChildren()) do
        if item.Name == "Knife" then return "Murderer" end
        if item.Name == "Gun" or item.Name == "Revolver" then return "Sheriff" end
    end
    for _, item in ipairs(char:GetChildren()) do
        if item:IsA("Tool") then
            if item.Name == "Knife" then return "Murderer" end
            if item.Name == "Gun" or item.Name == "Revolver" then return "Sheriff" end
        end
    end
    return "Innocent"
end

-- ==============================================
-- 🧹 CLEANUP SYSTEM
-- ==============================================
getgenv().MM2_Master_Cleanup = function()
    State.AutoCoin = false
    State.AuraKill = false
    State.ESPEnabled = false
    State.AntiAFK = false
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

    for _, esp in pairs(ESPObjects) do
        pcall(function() esp:Destroy() end)
    end
    table.clear(ESPObjects)

    for _, cnn in ipairs(Connections) do pcall(function() cnn:Disconnect() end) end
    table.clear(Connections)
    pcall(function() ScreenGui:Destroy() end)
    print("❌ ปิดระบบทั้งหมดเรียบร้อย")
end

-- ==============================================
-- ⚡ SYSTEM LOOPS & ANTI-AFK
-- ==============================================

-- Anti-AFK System
addConnection(LocalPlayer.Idled:Connect(function()
    if not State.AntiAFK then return end
    pcall(function()
        VirtualUser:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
        task.wait(1)
        VirtualUser:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
    end)
end))

-- Speed Control
addConnection(RunService.Heartbeat:Connect(function()
    local h = getHumanoid(LocalPlayer.Character)
    if h then
        h.WalkSpeed = (State.AutoCoin or State.AuraKill) and State.Speed or 16
    end
end))

-- Noclip + Safe Y
addConnection(RunService.Stepped:Connect(function()
    local c = LocalPlayer.Character
    if not c then return end
    local hrp = getHRP(c)
    local isSafeY = hrp and hrp.Position.Y > -40

    for _, part in ipairs(c:GetDescendants()) do
        if part:IsA("BasePart") then
            if OriginalCanCollide[part] == nil then
                OriginalCanCollide[part] = part.CanCollide
            end
            part.CanCollide = not ((State.AutoCoin or State.AuraKill) and isSafeY)
        end
    end
end))

-- 🔪 AURA KILL
addConnection(RunService.Heartbeat:Connect(function()
    if not State.AuraKill then return end
    
    local myRole = getRole(LocalPlayer)
    if myRole ~= "Murderer" then return end

    local myChar = LocalPlayer.Character
    local myHRP = getHRP(myChar)
    if not myHRP then return end

    local myKnife = myChar:FindFirstChild("Knife")
    if not myKnife then
        local backpackKnife = LocalPlayer.Backpack:FindFirstChild("Knife")
        if backpackKnife then
            local hum = getHumanoid(myChar)
            if hum then hum:EquipTool(backpackKnife) end
        end
        return
    end

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local pChar = p.Character
            local pHRP = getHRP(pChar)
            local pHum = getHumanoid(pChar)
            if pHRP and pHum and pHum.Health > 0 then
                local dist = (myHRP.Position - pHRP.Position).Magnitude
                if dist <= 300 then
                    pHRP.CFrame = myHRP.CFrame * CFrame.new(0, 0, -2)
                    pcall(function()
                        myKnife:Activate()
                    end)
                end
            end
        end
    end
end))

-- 👀 ESP SYSTEM (Clean Box)
addConnection(RunService.RenderStepped:Connect(function()
    if not State.ESPEnabled then
        for _, esp in pairs(ESPObjects) do
            if esp then esp.Enabled = false end
        end
        return
    end

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local char = p.Character
            local hrp = getHRP(char)
            if hrp then
                local box = char:FindFirstChild("MM2_ESP_Box")
                if not box then
                    box = Instance.new("Highlight")
                    box.Name = "MM2_ESP_Box"
                    box.Adornee = char
                    box.FillTransparency = 0.5
                    box.OutlineTransparency = 0
                    box.Parent = char
                    table.insert(ESPObjects, box)
                end

                box.Enabled = true
                local role = getRole(p)

                if role == "Murderer" then
                    box.FillColor = Color3.fromRGB(255, 50, 50)
                    box.OutlineColor = Color3.fromRGB(255, 0, 0)
                elseif role == "Sheriff" then
                    box.FillColor = Color3.fromRGB(50, 150, 255)
                    box.OutlineColor = Color3.fromRGB(0, 100, 255)
                else
                    box.FillColor = Color3.fromRGB(50, 255, 50)
                    box.OutlineColor = Color3.fromRGB(0, 255, 0)
                end
            end
        end
    end
end))

-- 🪙 AUTO COIN LOOP
addConnection(RunService.Heartbeat:Connect(function(deltaTime)
    if not State.AutoCoin then
        TargetCoin = nil
        ResumeTime = 0
        return
    end

    local DELAY_SECONDS = 1
    if tick() < ResumeTime then return end

    local myHRP = getHRP(LocalPlayer.Character)
    local myHum = getHumanoid(LocalPlayer.Character)
    if not myHRP or not myHum then return end

    if myHRP.Position.Y < -35 then
        myHRP.CFrame = CFrame.new(myHRP.Position.X, 10, myHRP.Position.Z)
        TargetCoin = nil
        return
    end

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

    if not TargetCoin or not TargetCoin.Parent then
        local nearest, distNearest = nil, math.huge
        for _, coin in ipairs(CoinContainer:GetChildren()) do
            if coin:IsA("BasePart") then
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

    local targetPos = Vector3.new(coinPos.X, math.max(coinPos.Y, myPos.Y - 2), coinPos.Z)
    local step = math.min(dist, State.Speed * deltaTime * 60)
    myHRP.CFrame = CFrame.new(myPos:Lerp(targetPos, step / dist))
    myHRP.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
    myHRP.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
end))

-- ==============================================
-- 🎨 UI DESIGN (ปรับสเกลพอดีจอ 2340x1080)
-- ==============================================

-- 1. ปุ่มวงกลมลอยได้ (Floating Button) วางตำแหน่งหลบมุมจอสวยๆ
local FloatBtn = Instance.new("TextButton")
FloatBtn.Size = UDim2.new(0, 48, 0, 48)
FloatBtn.Position = UDim2.new(0, 15, 0.35, 0)
FloatBtn.BackgroundColor3 = Color3.fromRGB(28, 28, 42)
FloatBtn.Text = "MM2"
FloatBtn.Font = Enum.Font.GothamBold
FloatBtn.TextSize = 12
FloatBtn.TextColor3 = Color3.fromRGB(255, 215, 0)
FloatBtn.Parent = ScreenGui

local FloatCorner = Instance.new("UICorner", FloatBtn)
FloatCorner.CornerRadius = UDim.new(1, 0)

local FloatStroke = Instance.new("UIStroke", FloatBtn)
FloatStroke.Color = Color3.fromRGB(255, 215, 0)
FloatStroke.Thickness = 2
makeDraggable(FloatBtn, FloatBtn)

-- 2. หน้าต่างหลัก (Main Frame) ขยายสัดส่วนพอดีเป๊ะ
local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, 260, 0, 240)
Main.Position = UDim2.new(1, -275, 0, 15)
Main.BackgroundColor3 = Color3.fromRGB(18, 18, 26)
Main.Visible = true
Main.Parent = ScreenGui
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 12)
local stroke = Instance.new("UIStroke", Main)
stroke.Color = Color3.fromRGB(255, 215, 0)
stroke.Thickness = 1.5

FloatBtn.MouseButton1Click:Connect(function()
    Main.Visible = not Main.Visible
end)

local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 35)
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
Title.Position = UDim2.new(0, 12, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "MM2 MASTER PANEL"
Title.Font = Enum.Font.GothamBold
Title.TextSize = 13
Title.TextColor3 = Color3.fromRGB(255, 215, 0)
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TitleBar

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 24, 0, 24)
CloseBtn.Position = UDim2.new(1, -28, 0, 5)
CloseBtn.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
CloseBtn.Text = "X"
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 12
CloseBtn.TextColor3 = Color3.new(1,1,1)
CloseBtn.Parent = TitleBar
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 6)

CloseBtn.MouseButton1Click:Connect(function()
    pcall(function() getgenv().MM2_Master_Cleanup() end)
end)

local function createToggle(name, posY, defaultState, callback)
    local Container = Instance.new("Frame")
    Container.Size = UDim2.new(1, -16, 0, 36)
    Container.Position = UDim2.new(0, 8, 0, posY)
    Container.BackgroundColor3 = Color3.fromRGB(30, 30, 44)
    Container.Parent = Main
    Instance.new("UICorner", Container).CornerRadius = UDim.new(0, 6)

    local Lbl = Instance.new("TextLabel")
    Lbl.Size = UDim2.new(1, -55, 1, 0)
    Lbl.Position = UDim2.new(0, 10, 0, 0)
    Lbl.BackgroundTransparency = 1
    Lbl.Text = name
    Lbl.Font = Enum.Font.GothamSemibold
    Lbl.TextSize = 11
    Lbl.TextColor3 = Color3.fromRGB(220, 220, 235)
    Lbl.TextXAlignment = Enum.TextXAlignment.Left
    Lbl.Parent = Container

    local Btn = Instance.new("TextButton")
    Btn.Size = UDim2.new(0, 38, 0, 20)
    Btn.Position = UDim2.new(1, -44, 0.5, -10)
    Btn.BackgroundColor3 = defaultState and Color3.fromRGB(255, 215, 0) or Color3.fromRGB(60, 60, 80)
    Btn.Text = ""
    Btn.Parent = Container
    Instance.new("UICorner", Btn).CornerRadius = UDim.new(1, 0)

    local Dot = Instance.new("Frame")
    Dot.Size = UDim2.new(0, 14, 0, 14)
    Dot.Position = defaultState and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)
    Dot.BackgroundColor3 = Color3.fromRGB(220, 220, 220)
    Dot.Parent = Btn
    Instance.new("UICorner", Dot).CornerRadius = UDim.new(1, 0)

    local active = defaultState
    Btn.MouseButton1Click:Connect(function()
        active = not active
        if active then
            TweenService:Create(Btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(255, 215, 0)}):Play()
            TweenService:Create(Dot, TweenInfo.new(0.2), {Position = UDim2.new(1, -17, 0.5, -7)}):Play()
        else
            TweenService:Create(Btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(60, 60, 80)}):Play()
            TweenService:Create(Dot, TweenInfo.new(0.2), {Position = UDim2.new(0, 3, 0.5, -7)}):Play()
        end
        callback(active)
    end)
end

createToggle("เปิด Auto Coin (ฟาร์มแคนดี้)", 42, false, function(v) State.AutoCoin = v end)
createToggle("เปิด Aura Kill (ฆาตกร 300ม.)", 82, false, function(v) State.AuraKill = v end)
createToggle("เปิด ESP Role (กรอบสีตามบทบาท)", 122, false, function(v) State.ESPEnabled = v end)
createToggle("เปิด Anti-AFK (กันหลุด)", 162, true, function(v) State.AntiAFK = v end)

print("✅ MM2 Master Script (2340x1080 Optimized) Loaded Successfully!")
