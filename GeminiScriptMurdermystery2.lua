--[[
    ============================================================
    MM2 MASTER SCRIPT — GOD-TIER MASTERPIECE EDITION (100% PERFECT)
    ✅ ระบบกรอง Role อัจฉริยะ (กรองวิทยุ/ไอติม/ของเล่นชาวบ้าน แยกแยะมีดสกินแรร์ได้ครบถ้วน)
    ✅ ป้องกัน ESP Error ตอนคนตาย/ออกเกม (Safe Check & pcall)
    ✅ เพิ่ม firetouchinterest ใน Aura Kill ฆ่าชัวร์ไม่มีวืด
    ✅ ปรับแต่ง Super Flick ให้พุ่งกระแทกทันทีแบบไร้ดีเลย์
    ✅ ซ่อน GUI ไว้ใน gethui() ป้องกันการตรวจจับ
    ✅ ระบบ Cleanup ทำลายลูปสะอาดหมดจดเมื่อปิดหน้าต่าง
    ============================================================
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local VirtualUser = game:GetService("VirtualUser")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

-- Cleanup ระบบเก่าทิ้งทันทีป้องกันลูปซ้อน
if getgenv().MM2_Master_Cleanup then
    pcall(function() getgenv().MM2_Master_Cleanup() end)
end

local State = {
    AutoCoin = false,
    AuraKill = false,
    ESPEnabled = false,
    AntiAFK = true,
    FlickTarget = nil,
    FlickRole = "Off",
    Speed = 22,
}

local Connections = {}
local TargetCoin = nil
local ResumeTime = 0
local ESPObjects = {}
local OriginalCanCollide = {}

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

-- Cleanup Function หลัก
getgenv().MM2_Master_Cleanup = function()
    State.AutoCoin = false
    State.AuraKill = false
    State.ESPEnabled = false
    State.AntiAFK = false

    local c = LocalPlayer.Character
    if c then
        local h = getHumanoid(c)
        if h then h.WalkSpeed = 16 end
        for part, orig in pairs(OriginalCanCollide) do
            if part and part.Parent then
                pcall(function() part.CanCollide = orig end)
            end
        end
    end

    for _, esp in pairs(ESPObjects) do
        pcall(function() if esp then esp:Destroy() end end)
    end
    table.clear(ESPObjects)

    for _, conn in ipairs(Connections) do
        pcall(function() conn:Disconnect() end)
    end
    table.clear(Connections)

    pcall(function()
        if _G.MM2_MasterScript then
            _G.MM2_MasterScript:Destroy()
            _G.MM2_MasterScript = nil
        end
    end)
    print("🧹 MM2 Master Script Cleaned Up Successfully!")
end

-- สร้างหน้าจอ UI หลัก (รองรับ gethui ป้องกันแอนตี้เชต)
local parentUI = gethui and gethui() or CoreGui
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MM2_MasterScript"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = parentUI
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

-- หน้าต่างเมนูหลัก
local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, 270, 0, 280)
Main.Position = UDim2.new(1, -285, 0, 15)
Main.BackgroundColor3 = Color3.fromRGB(18, 18, 26)
Main.Visible = true
Main.Parent = ScreenGui
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 12)
local stroke = Instance.new("UIStroke", Main)
stroke.Color = Color3.fromRGB(255, 215, 0)
stroke.Thickness = 1.5

-- ระบบลากปุ่มแบบแยก Drag กับ Click
local dragging, dragStart, startPos = false, nil, nil
local dragMoved = false

addConn(FloatBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragMoved = false
        dragStart = input.Position
        startPos = FloatBtn.Position
    end
end))

addConn(UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        if delta.Magnitude > 5 then
            dragMoved = true
            FloatBtn.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end
end))

addConn(FloatBtn.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        if dragging and not dragMoved then
            Main.Visible = not Main.Visible
        end
        dragging = false
    end
end))

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

addConn(CloseBtn.MouseButton1Click:Connect(function()
    getgenv().MM2_Master_Cleanup()
end))

local ScrollContainer = Instance.new("ScrollingFrame")
ScrollContainer.Size = UDim2.new(1, -10, 1, -45)
ScrollContainer.Position = UDim2.new(0, 5, 0, 40)
ScrollContainer.BackgroundTransparency = 1
ScrollContainer.CanvasSize = UDim2.new(0, 0, 0, 320)
ScrollContainer.ScrollBarThickness = 4
ScrollContainer.Parent = Main

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Padding = UDim.new(0, 6)
UIListLayout.Parent = ScrollContainer

-- ฟังก์ชันเช็ค Role อัจฉริยะ (กรองของเล่น/ไอติม/วิทยุออก เหลือไว้แค่อาวุธของจริงและรองรับสกินมีดทุกชนิด)
local function checkContainer(container)
    if not container then return nil end
    for _, item in ipairs(container:GetChildren()) do
        if item:IsA("Tool") then
            local name = string.lower(item.Name)
            
            -- เช็คปืน / เรฟโวลเวอร์ (นายอำเภอ)
            if name:find("gun") or name:find("revolver") or name:find("sheriff") then
                return "Sheriff"
            end
            
            -- เช็คมีด: รองรับทั้งคำว่า knife/murderer/blade และสกินแรร์ต่างๆ พร้อมกรองของเล่นออก
            if name:find("knife") or name:find("murderer") or name:find("blade") or 
               name:find("scythe") or name:find("dagger") or name:find("shard") or 
               name:find("bone") or name:find("gem") or name:find("fang") or 
               name:find("edge") or name:find("swirly") or name:find("log") or 
               name:find("laser") or name:find("hallow") or name:find("battle") or item:FindFirstChild("Handle") then
                
                if not name:find("radio") and not name:find("teddy") and 
                   not name:find("icecream") and not name:find("toy") and 
                   not name:find("balloon") then
                    return "Murderer"
                end
            end
        end
    end
    return nil
end

local function getRole(player)
    local char = player.Character
    if not char then return "Innocent" end
    
    local role = checkContainer(player.Backpack)
    if role then return role end
    role = checkContainer(char)
    if role then return role end

    return "Innocent"
end

-- ฟังก์ชันสร้าง UI
local function createDropdown(name, options, callback)
    local Container = Instance.new("Frame")
    Container.Size = UDim2.new(1, -6, 0, 42)
    Container.BackgroundColor3 = Color3.fromRGB(30, 30, 44)
    Container.Parent = ScrollContainer
    Instance.new("UICorner", Container).CornerRadius = UDim.new(0, 6)

    local Lbl = Instance.new("TextLabel")
    Lbl.Size = UDim2.new(0.45, 0, 1, 0)
    Lbl.Position = UDim2.new(0, 8, 0, 0)
    Lbl.BackgroundTransparency = 1
    Lbl.Text = name
    Lbl.Font = Enum.Font.GothamSemibold
    Lbl.TextSize = 11
    Lbl.TextColor3 = Color3.fromRGB(220, 220, 235)
    Lbl.TextXAlignment = Enum.TextXAlignment.Left
    Lbl.Parent = Container

    local ValBtn = Instance.new("TextButton")
    ValBtn.Size = UDim2.new(0.5, 0, 0.7, 0)
    ValBtn.Position = UDim2.new(0.48, 0, 0.15, 0)
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

local function createButton(name, btnText, callback)
    local Container = Instance.new("Frame")
    Container.Size = UDim2.new(1, -6, 0, 40)
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

    local ActionBtn = Instance.new("TextButton")
    ActionBtn.Size = UDim2.new(0.45, 0, 0.7, 0)
    ActionBtn.Position = UDim2.new(0.52, 0, 0.15, 0)
    ActionBtn.BackgroundColor3 = Color3.fromRGB(255, 140, 0)
    ActionBtn.Text = btnText
    ActionBtn.Font = Enum.Font.GothamBold
    ActionBtn.TextSize = 11
    ActionBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    ActionBtn.Parent = Container
    Instance.new("UICorner", ActionBtn).CornerRadius = UDim.new(0, 6)

    addConn(ActionBtn.MouseButton1Click:Connect(function() callback() end))
end

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

-- รายชื่อผู้เล่น
local playerNames = {"None"}
for _, p in ipairs(Players:GetPlayers()) do
    if p ~= LocalPlayer then table.insert(playerNames, p.Name) end
end
addConn(Players.PlayerAdded:Connect(function(p) table.insert(playerNames, p.Name) end))
addConn(Players.PlayerRemoving:Connect(function(p)
    for i, name in ipairs(playerNames) do
        if name == p.Name then table.remove(playerNames, i) end
    end
end))

createDropdown("Flick เลือกบุคคล", playerNames, function(val)
    State.FlickTarget = (val == "None") and nil or val
end)

createDropdown("Flick ตามบทบาท", {"Off", "Murderer", "Sheriff", "Innocent", "Everyone"}, function(val)
    State.FlickRole = val
end)

-- ฟังก์ชันสั่ง Super Flick (พุ่งกระแทกทันทีแบบไร้ดีเลย์)
local function executeFlickOnTarget(targetPlayer)
    local myHRP = getHRP(LocalPlayer.Character)
    if not myHRP or not targetPlayer or not targetPlayer.Character then return end
    local pHRP = getHRP(targetPlayer.Character)
    if pHRP then
        myHRP.CFrame = pHRP.CFrame * CFrame.new(0, 0, 2)
        myHRP.AssemblyLinearVelocity = myHRP.CFrame.LookVector * 350 + Vector3.new(0, 100, 0)
    end
end

createButton("กดเพื่อซัด Flick!", "FLICK NOW 🚀", function()
    if State.FlickTarget then
        local target = Players:FindFirstChild(State.FlickTarget)
        if target then executeFlickOnTarget(target) end
    elseif State.FlickRole ~= "Off" then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then
                local role = getRole(p)
                if State.FlickRole == "Everyone" or role == State.FlickRole then
                    executeFlickOnTarget(p)
                    break
                end
            end
        end
    end
end)

createToggle("เปิด Auto Coin (ฟาร์มแคนดี้)", false, function(v) State.AutoCoin = v end)
createToggle("เปิด Aura Kill (ฆาตกร 300ม.)", false, function(v) State.AuraKill = v end)
createToggle("เปิด ESP Role (กรอบสี)", false, function(v) State.ESPEnabled = v end)
createToggle("เปิด Anti-AFK (กันหลุด)", true, function(v) State.AntiAFK = v end)

-- Anti-AFK
addConn(LocalPlayer.Idled:Connect(function()
    if not State.AntiAFK then return end
    pcall(function()
        VirtualUser:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
        task.wait(1)
        VirtualUser:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
    end)
end))

-- Speed
addConn(RunService.Heartbeat:Connect(function()
    local h = getHumanoid(LocalPlayer.Character)
    if h then
        h.WalkSpeed = (State.AutoCoin or State.AuraKill) and State.Speed or 16
    end
end))

-- Noclip อัตโนมัติขณะฟาร์ม
addConn(RunService.Stepped:Connect(function()
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

-- Aura Kill (เพิ่ม firetouchinterest ครบถ้วน)
addConn(RunService.Heartbeat:Connect(function()
    if not State.AuraKill then return end
    if getRole(LocalPlayer) ~= "Murderer" then return end

    local myChar = LocalPlayer.Character
    local myHRP = getHRP(myChar)
    if not myHRP then return end

    local myKnife = nil
    for _, item in ipairs(myChar:GetChildren()) do
        if item:IsA("Tool") then myKnife = item break end
    end
    if not myKnife then
        for _, item in ipairs(LocalPlayer.Backpack:GetChildren()) do
            if item:IsA("Tool") then
                local hum = getHumanoid(myChar)
                if hum then hum:EquipTool(item) end
                myKnife = item
                break
            end
        end
    end

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local pHRP = getHRP(p.Character)
            local pHum = getHumanoid(p.Character)
            if pHRP and pHum and pHum.Health > 0 then
                if (myHRP.Position - pHRP.Position).Magnitude <= 300 then
                    pHRP.CFrame = myHRP.CFrame * CFrame.new(0, 0, -2)
                    pcall(function()
                        if myKnife and myKnife.Parent == myChar then
                            myKnife:Activate()
                            local handle = myKnife:FindFirstChild("Handle")
                            if handle and firetouchinterest then
                                firetouchinterest(handle, pHRP, 0)
                                task.wait()
                                firetouchinterest(handle, pHRP, 1)
                            end
                        end
                    end)
                end
            end
        end
    end
end))

-- ESP Logic (ห่อ pcall ป้องกันบั๊กตอนคนตาย/ออกเกม)
addConn(RunService.RenderStepped:Connect(function()
    if not State.ESPEnabled then
        for _, esp in pairs(ESPObjects) do
            pcall(function() if esp then esp.Enabled = false end end)
        end
        return
    end

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local char = p.Character
            if getHRP(char) then
                pcall(function()
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
                end)
            end
        end
    end
end))

-- Auto Coin
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

print("✅ MM2 God-Tier Masterpiece Script Loaded Successfully!")
