--[[
    ============================================================
    MM2 MASTER SCRIPT — ULTRA STABLE + SUPER FLICK REVENGE
    ✅ รวมครบทุกฟังก์ชัน + Super Flick เลือกเป้าหมายสะใจสายแค้น
    ✅ จัดระเบียบการรันปลอดภัย 100% ไม่ค้าง ไม่เงียบกริบ
    ============================================================
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local VirtualUser = game:GetService("VirtualUser")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

if _G.MM2_MasterScript then
    pcall(function() _G.MM2_MasterScript:Destroy() end)
end

local State = {
    AutoCoin = false,
    AuraKill = false,
    ESPEnabled = false,
    AntiAFK = true,
    FlickMode = "Off",
    SelectedTarget = nil,
    Speed = 22,
}

local Connections = {}
local TargetCoin = nil
local ResumeTime = 0
local ESPObjects = {}

local function addConn(conn)
    table.insert(Connections, conn)
    return conn
end

local function getHRP(char)
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function getHumanoid(char)
    return char and char:FindFirstChild("Humanoid")
end

-- สร้างหน้าจอ UI หลัก
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MM2_MasterScript"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = PlayerGui
_G.MM2_MasterScript = ScreenGui

-- ปุ่มวงกลมลอยได้
local FloatBtn = Instance.new("TextButton")
FloatBtn.Size = UDim2.new(0, 48, 0, 48)
FloatBtn.Position = UDim2.new(0, 15, 0.35, 0)
FloatBtn.BackgroundColor3 = Color3.fromRGB(28, 28, 42)
FloatBtn.Text = "MM2"
FloatBtn.Font = Enum.Font.GothamBold
FloatBtn.TextSize = 12
FloatBtn.TextColor3 = Color3.fromRGB(255, 215, 0)
FloatBtn.Parent = ScreenGui
Instance.new("UICorner", FloatBtn).CornerRadius = UDim.new(1, 0)

local FloatStroke = Instance.new("UIStroke", FloatBtn)
FloatStroke.Color = Color3.fromRGB(255, 215, 0)
FloatStroke.Thickness = 2

-- ระบบลากปุ่ม
local dragging, dragInput, dragStart, startPos
addConn(FloatBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = FloatBtn.Position
    end
end))
addConn(UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        FloatBtn.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end))
addConn(UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end))

-- หน้าต่างเมนูหลัก (ScrollingFrame)
local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, 270, 0, 260)
Main.Position = UDim2.new(1, -285, 0, 15)
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
    pcall(function() ScreenGui:Destroy() end)
end)

local ScrollContainer = Instance.new("ScrollingFrame")
ScrollContainer.Size = UDim2.new(1, -10, 1, -45)
ScrollContainer.Position = UDim2.new(0, 5, 0, 40)
ScrollContainer.BackgroundTransparency = 1
ScrollContainer.CanvasSize = UDim2.new(0, 0, 0, 280)
ScrollContainer.ScrollBarThickness = 4
ScrollContainer.Parent = Main

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Padding = UDim.new(0, 6)
UIListLayout.Parent = ScrollContainer

-- ฟังก์ชันสร้าง Dropdown เลือกผู้เล่น
local function createDropdown(name, options, callback)
    local Container = Instance.new("Frame")
    Container.Size = UDim2.new(1, -6, 0, 42)
    Container.BackgroundColor3 = Color3.fromRGB(30, 30, 44)
    Container.Parent = ScrollContainer
    Instance.new("UICorner", Container).CornerRadius = UDim.new(0, 6)

    local Lbl = Instance.new("TextLabel")
    Lbl.Size = UDim2.new(0.5, 0, 1, 0)
    Lbl.Position = UDim2.new(0, 8, 0, 0)
    Lbl.BackgroundTransparency = 1
    Lbl.Text = name
    Lbl.Font = Enum.Font.GothamSemibold
    Lbl.TextSize = 11
    Lbl.TextColor3 = Color3.fromRGB(220, 220, 235)
    Lbl.TextXAlignment = Enum.TextXAlignment.Left
    Lbl.Parent = Container

    local ValBtn = Instance.new("TextButton")
    ValBtn.Size = UDim2.new(0.45, 0, 0.7, 0)
    ValBtn.Position = UDim2.new(0.52, 0, 0.15, 0)
    ValBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 65)
    ValBtn.Text = options[1] or "None"
    ValBtn.Font = Enum.Font.GothamBold
    ValBtn.TextSize = 11
    ValBtn.TextColor3 = Color3.fromRGB(255, 215, 0)
    ValBtn.Parent = Container
    Instance.new("UICorner", ValBtn).CornerRadius = UDim.new(0, 6)

    local currentIndex = 1
    addConn(ValBtn.MouseButton1Click:Connect(function()
        if #options == 0 then return end
        currentIndex = currentIndex + 1
        if currentIndex > #options then currentIndex = 1 end
        local selected = options[currentIndex]
        ValBtn.Text = tostring(selected)
        callback(selected)
    end))
end

-- ฟังก์ชันสร้าง Toggle
local function createToggle(name, defaultState, callback)
    local Container = Instance.new("Frame")
    Container.Size = UDim2.new(1, -6, 0, 36)
    Container.BackgroundColor3 = Color3.fromRGB(30, 30, 44)
    Container.Parent = ScrollContainer
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
    addConn(Btn.MouseButton1Click:Connect(function()
        active = not active
        Btn.BackgroundColor3 = active and Color3.fromRGB(255, 215, 0) or Color3.fromRGB(60, 60, 80)
        Dot.Position = active and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)
        callback(active)
    end))
end

-- ดึงรายชื่อผู้เล่นแบบปลอดภัย
local playerNames = {"None"}
pcall(function()
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then table.insert(playerNames, p.Name) end
    end
end)

createDropdown("Flick เลือกบุคคล", playerNames, function(val)
    if val == "None" then
        State.SelectedTarget = nil
        State.FlickMode = "Off"
    else
        State.SelectedTarget = val
        State.FlickMode = "Selected"
    end
end)

createDropdown("Flick ตามบทบาท", {"Off", "Murderer", "Sheriff", "Innocent", "Everyone"}, function(val)
    if val == "Off" then
        if not State.SelectedTarget then State.FlickMode = "Off" end
    else
        State.FlickMode = val
    end
end)

createToggle("เปิด Auto Coin (ฟาร์มแคนดี้)", false, function(v) State.AutoCoin = v end)
createToggle("เปิด Aura Kill (ฆาตกร 300ม.)", false, function(v) State.AuraKill = v end)
createToggle("เปิด ESP Role (กรอบสี)", false, function(v) State.ESPEnabled = v end)
createToggle("เปิด Anti-AFK (กันหลุด)", true, function(v) State.AntiAFK = v end)

-- Anti-AFK Loop
addConn(LocalPlayer.Idled:Connect(function()
    if not State.AntiAFK then return end
    pcall(function()
        VirtualUser:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
        task.wait(1)
        VirtualUser:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
    end)
end))

-- Speed Loop
addConn(RunService.Heartbeat:Connect(function()
    local h = getHumanoid(LocalPlayer.Character)
    if h then
        h.WalkSpeed = (State.AutoCoin or State.AuraKill or State.FlickMode ~= "Off") and State.Speed or 16
    end
end))

-- Role Checker
local function getRole(player)
    local char = player.Character
    if not char then return "Innocent" end
    pcall(function()
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
    end)
    return "Innocent"
end

-- Super Flick Revenge Logic
addConn(RunService.Heartbeat:Connect(function()
    if State.FlickMode == "Off" then return end
    local myChar = LocalPlayer.Character
    local myHRP = getHRP(myChar)
    if not myHRP then return end

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local pHRP = getHRP(p.Character)
            local pHum = getHumanoid(p.Character)
            if pHRP and pHum and pHum.Health > 0 then
                local role = getRole(p)
                local shouldFlick = false

                if State.FlickMode == "Selected" and State.SelectedTarget and p.Name == State.SelectedTarget then
                    shouldFlick = true
                elseif State.FlickMode == "Murderer" and role == "Murderer" then
                    shouldFlick = true
                elseif State.FlickMode == "Sheriff" and role == "Sheriff" then
                    shouldFlick = true
                elseif State.FlickMode == "Innocent" and role == "Innocent" then
                    shouldFlick = true
                elseif State.FlickMode == "Everyone" then
                    shouldFlick = true
                end

                if shouldFlick then
                    myHRP.CFrame = pHRP.CFrame * CFrame.new(0, 0, 1)
                    myHRP.AssemblyLinearVelocity = Vector3.new(0, -350, 0)
                    break
                end
            end
        end
    end
end))

-- Aura Kill Logic
addConn(RunService.Heartbeat:Connect(function()
    if not State.AuraKill then return end
    if getRole(LocalPlayer) ~= "Murderer" then return end

    local myChar = LocalPlayer.Character
    local myHRP = getHRP(myChar)
    if not myHRP then return end

    local myKnife = myChar:FindFirstChild("Knife") or LocalPlayer.Backpack:FindFirstChild("Knife")
    if myKnife and myKnife.Parent == LocalPlayer.Backpack then
        local hum = getHumanoid(myChar)
        if hum then hum:EquipTool(myKnife) end
    end

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local pHRP = getHRP(p.Character)
            local pHum = getHumanoid(p.Character)
            if pHRP and pHum and pHum.Health > 0 then
                if (myHRP.Position - pHRP.Position).Magnitude <= 300 then
                    pHRP.CFrame = myHRP.CFrame * CFrame.new(0, 0, -2)
                    pcall(function() if myKnife and myKnife.Parent == myChar then myKnife:Activate() end end)
                end
            end
        end
    end
end))

-- ESP Logic
addConn(RunService.RenderStepped:Connect(function()
    if not State.ESPEnabled then
        for _, esp in pairs(ESPObjects) do if esp then esp.Enabled = false end end
        return
    end

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local char = p.Character
            if getHRP(char) then
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

-- Auto Coin Logic
addConn(RunService.Heartbeat:Connect(function(deltaTime)
    if not State.AutoCoin then TargetCoin = nil return end
    if tick() < ResumeTime then return end

    local myHRP = getHRP(LocalPlayer.Character)
    if not myHRP then return end

    if myHRP.Position.Y < -35 then
        myHRP.CFrame = CFrame.new(myHRP.Position.X, 10, myHRP.Position.Z)
        TargetCoin = nil
        return
    end

    local CoinContainer = Workspace:FindFirstChild("CoinContainer") or Workspace:FindFirstChild("Normal")
    if not CoinContainer then return end

    if not TargetCoin or not TargetCoin.Parent then
        local nearest, distNearest = nil, math.huge
        for _, coin in ipairs(CoinContainer:GetChildren()) do
            if coin:IsA("BasePart") and coin.Position.Y > -30 then
                local dist = (myHRP.Position - coin.Position).Magnitude
                if dist < distNearest then
                    distNearest = dist
                    nearest = coin
                end
            end
        end
        TargetCoin = nearest
    end

    if not TargetCoin then return end

    local coinPos = TargetCoin.Position
    local dist = (myHRP.Position - coinPos).Magnitude
    if dist <= 1.2 then
        TargetCoin = nil
        ResumeTime = tick() + 1
        return
    end

    local targetPos = Vector3.new(coinPos.X, math.max(coinPos.Y, myHRP.Position.Y - 2), coinPos.Z)
    local step = math.min(dist, State.Speed * deltaTime * 60)
    myHRP.CFrame = CFrame.new(myHRP.Position:Lerp(targetPos, step / dist))
    myHRP.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
end))

print("✅ MM2 Master Script (Stable + Super Flick) Loaded Successfully!")
