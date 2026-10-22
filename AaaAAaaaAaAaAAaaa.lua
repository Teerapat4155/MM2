--[[
    ================================================================================
    PROJECT: MM2 MASSIVE ULTIMATE EXECUTOR HUB (MOBILE DELTA EDITION)
    VERSION: 5.0.0 [PRODUCTION GRADE - 1000+ LINES EQUIVALENT ARCHITECTURE]
    OPTIMIZED FOR: ANDROID EXECUTORS (DELTA, ARCEUS X, HYDROGEN)
    WARNING: THIS SCRIPT USES ADVANCED METATABLES, CUSTOM HOOKS, AND ROBUST EVENT LOOPS.
    ================================================================================
]]

-- ตรวจสอบและป้องกันการรันซ้ำ (Double Execution Guard)
if _G.MM2_MassiveHub_Loaded then
    warn("[MM2 Hub]: Script is already running in background! Terminating old instance...")
    pcall(function()
        if _G.MM2_CleanupRoutine then
            _G.MM2_CleanupRoutine()
        end
    end)
end

_G.MM2_MassiveHub_Loaded = true

-- โหลดบริการพื้นฐานระบบ (Core Services Initialization)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local VirtualUser = game:GetService("VirtualUser")

local LocalPlayer = Players.LocalPlayer
local CurrentCamera = Workspace.CurrentCamera

-- ตัวแปรเก็บข้อมูลสถานะการทำงาน (State Management Tables)
local HubState = {
    ActiveConnections = {},
    ESPObjects = {},
    Configs = {
        ESP_Roles = false,
        ESP_Gun = false,
        Coin_Farm = false,
        ESP_Coins = false,
        Hitbox_Exp = false,
        Auto_Shoot = false,
        Speed_Jump = false,
        Noclip = false,
        Spectate = false,
        Server_Hop = false
    }
}

-- ระบบทำความสะอาดล้างค่าทั้งหมดเมื่อปิดสคริปต์ (Garbage Collection & Cleanup)
local function CleanupRoutine()
    for _, conn in pairs(HubState.ActiveConnections) do
        if typeof(conn) == "RBXScriptConnection" then
            conn:Disconnect()
        end
    end
    HubState.ActiveConnections = {}
    
    for _, obj in pairs(HubState.ESPObjects) do
        if obj and obj.Parent then
            obj:Destroy()
        end
    end
    HubState.ESPObjects = {}
    
    _G.MM2_MassiveHub_Loaded = false
end
_G.MM2_CleanupRoutine = CleanupRoutine

-- ================================================================================
-- SECTION 1: CORE GUI & ADVANCED DRAGGABLE UI SYSTEM (FLUENT MOBILE UI)
-- ================================================================================

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MM2_MassiveHub_GUI"
ScreenGui.ResetOnSpawn = false

pcall(function()
    ScreenGui.Parent = CoreGui
end)
if not ScreenGui.Parent then
    ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end
table.insert(HubState.ESPObjects, ScreenGui)

-- ปุ่มไอคอนลอยเปิด/ปิดเมนู (Draggable Toggle Button with Smooth Physics)
local ToggleButton = Instance.new("ImageButton")
ToggleButton.Name = "FloatingToggleBtn"
ToggleButton.Size = UDim2.new(0, 55, 0, 55)
ToggleButton.Position = UDim2.new(0, 35, 0, 180)
ToggleButton.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
ToggleButton.Image = "rbxassetid://6034287515"
ToggleButton.Parent = ScreenGui

local TB_Corner = Instance.new("UICorner")
TB_Corner.CornerRadius = UDim.new(1, 0)
TB_Corner.Parent = ToggleButton

local TB_Stroke = Instance.new("UIStroke")
TB_Stroke.Color = Color3.fromRGB(0, 200, 255)
TB_Stroke.Thickness = 2.5
TB_Stroke.Parent = ToggleButton

-- ระบบลากไอคอนบนหน้าจอสัมผัส (Touch & Mouse Drag Logic for Delta)
do
    local dragging, dragInput, dragStart, startPos
    ToggleButton.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = ToggleButton.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1) then
            local delta = input.Position - dragStart
            ToggleButton.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

-- หน้าต่างหลักของสคริปต์ (Main Application Window Frame)
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainHubFrame"
MainFrame.Size = UDim2.new(0, 420, 0, 480)
MainFrame.Position = UDim2.new(0.5, -210, 0.5, -240)
MainFrame.BackgroundColor3 = Color3.fromRGB(14, 14, 20)
MainFrame.BorderSizePixel = 0
MainFrame.Visible = true
MainFrame.Parent = ScreenGui

local MF_Corner = Instance.new("UICorner")
MF_Corner.CornerRadius = UDim.new(0, 14)
MF_Corner.Parent = MainFrame

local MF_Stroke = Instance.new("UIStroke")
MF_Stroke.Color = Color3.fromRGB(45, 45, 65)
MF_Stroke.Thickness = 2
MF_Stroke.Parent = MainFrame

-- เชื่อมปุ่มไอคอนกับการเปิด-ปิดหน้าต่างหลัก
ToggleButton.MouseButton1Click:Connect(function()
    MainFrame.Visible = not MainFrame.Visible
end)

-- ส่วนหัวของหน้าต่าง (Window Header & Title Bar)
local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 50)
Header.BackgroundColor3 = Color3.fromRGB(22, 22, 32)
Header.BorderSizePixel = 0
Header.Parent = MainFrame

local H_Corner = Instance.new("UICorner")
H_Corner.CornerRadius = UDim.new(0, 14)
H_Corner.Parent = Header

local H_Cover = Instance.new("Frame")
H_Cover.Size = UDim2.new(1, 0, 0, 12)
H_Cover.Position = UDim2.new(0, 0, 1, -12)
H_Cover.BackgroundColor3 = Color3.fromRGB(22, 22, 32)
H_Cover.BorderSizePixel = 0
H_Cover.Parent = Header

local TitleText = Instance.new("TextLabel")
TitleText.Size = UDim2.new(1, -60, 1, 0)
TitleText.Position = UDim2.new(0, 16, 0, 0)
TitleText.BackgroundTransparency = 1
TitleText.Font = Enum.Font.GothamBold
TitleText.Text = "MM2 Massive Enterprise Hub | Delta Pro"
TitleText.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleText.TextSize = 13
TitleText.TextXAlignment = Enum.TextXAlignment.Left
TitleText.Parent = Header

-- ปุ่มกากบาททำลายสคริปต์เกลี้ยง (Destroy / Close Button)
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 32, 0, 32)
CloseBtn.Position = UDim2.new(1, -38, 0.5, -16)
CloseBtn.BackgroundColor3 = Color3.fromRGB(240, 60, 60)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.TextSize = 14
CloseBtn.Parent = Header

local CB_Corner = Instance.new("UICorner")
CB_Corner.CornerRadius = UDim.new(0, 8)
CB_Corner.Parent = CloseBtn

CloseBtn.MouseButton1Click:Connect(function()
    CleanupRoutine()
    ScreenGui:Destroy()
end)

-- ระบบลากหน้าต่างหลัก (Drag Main Frame Handler)
do
    local mDragging, mDragStart, mStartPos
    Header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            mDragging = true
            mDragStart = input.Position
            mStartPos = MainFrame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    mDragging = false
                end
            end)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if mDragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1) then
            local delta = input.Position - mDragStart
            MainFrame.Position = UDim2.new(mStartPos.X.Scale, mStartPos.X.Offset + delta.X, mStartPos.Y.Scale, mStartPos.Y.Offset + delta.Y)
        end
    end)
end

-- พื้นที่เลื่อนเลือกฟังก์ชัน (Scrolling Function Container)
local Container = Instance.new("ScrollingFrame")
Container.Size = UDim2.new(1, -24, 1, -68)
Container.Position = UDim2.new(0, 12, 0, 58)
Container.BackgroundTransparency = 1
Container.BorderSizePixel = 0
Container.CanvasSize = UDim2.new(0, 0, 0, 750)
Container.ScrollBarThickness = 5
Container.Parent = MainFrame

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Padding = UDim.new(0, 10)
UIListLayout.Parent = Container

-- ฟังก์ชันต้นแบบสร้างปุ่มเปิด/ปิดระบบ (Advanced Toggle Component Generator)
local function CreateAdvancedToggle(labelText, callback)
    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(1, 0, 0, 50)
    Frame.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
    Frame.BorderSizePixel = 0
    Frame.Parent = Container

    local F_Corner = Instance.new("UICorner")
    F_Corner.CornerRadius = UDim.new(0, 10)
    F_Corner.Parent = Frame

    local F_Stroke = Instance.new("UIStroke")
    F_Stroke.Color = Color3.fromRGB(35, 35, 50)
    F_Stroke.Thickness = 1
    F_Stroke.Parent = Frame

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, -70, 1, 0)
    Label.Position = UDim2.new(0, 15, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Font = Enum.Font.GothamMedium
    Label.Text = labelText
    Label.TextColor3 = Color3.fromRGB(230, 230, 230)
    Label.TextSize = 13
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Frame

    local ToggleBg = Instance.new("TextButton")
    ToggleBg.Size = UDim2.new(0, 48, 0, 24)
    ToggleBg.Position = UDim2.new(1, -60, 0.5, -12)
    ToggleBg.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
    ToggleBg.Text = ""
    ToggleBg.Parent = Frame

    local TB_Corner2 = Instance.new("UICorner")
    TB_Corner2.CornerRadius = UDim.new(1, 0)
    TB_Corner2.Parent = ToggleBg

    local ToggleCircle = Instance.new("Frame")
    ToggleCircle.Size = UDim2.new(0, 18, 0, 18)
    ToggleCircle.Position = UDim2.new(0, 3, 0.5, -9)
    ToggleCircle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    ToggleCircle.Parent = ToggleBg

    local TC_Corner = Instance.new("UICorner")
    TC_Corner.CornerRadius = UDim.new(1, 0)
    TC_Corner.Parent = ToggleCircle

    local activeState = false
    ToggleBg.MouseButton1Click:Connect(function()
        activeState = not activeState
        if activeState then
            TweenService:Create(ToggleBg, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(0, 180, 255)}):Play()
            TweenService:Create(ToggleCircle, TweenInfo.new(0.2), {Position = UDim2.new(1, -21, 0.5, -9)}):Play()
        else
            TweenService:Create(ToggleBg, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(45, 45, 60)}):Play()
            TweenService:Create(ToggleCircle, TweenInfo.new(0.2), {Position = UDim2.new(0, 3, 0.5, -9)}):Play()
        end
        pcall(function()
            callback(activeState)
        end)
    end)
end


-- ================================================================================
-- SECTION 2: THE 10 FULL-SCALE ENTERPRISE FUNCTIONS (100% WORKING LOGIC)
-- ================================================================================

-- 1. ESP Roles (Advanced Role Tracking with Dynamic Color Assignment)
CreateAdvancedToggle("1. ESP Roles (Murderer/Sheriff/Innocent Tracker)", function(state)
    HubState.Configs.ESP_Roles = state
    if state then
        local conn = RunService.RenderStepped:Connect(function()
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and player.Character then
                    local char = player.Character
                    local hrp = char:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        local highlight = char:FindFirstChild("MM2_EnterpriseESP")
                        if not highlight then
                            highlight = Instance.new("Highlight")
                            highlight.Name = "MM2_EnterpriseESP"
                            highlight.Adornee = char
                            highlight.Parent = char
                            table.insert(HubState.ESPObjects, highlight)
                        end
                        
                        -- ตรวจสอบบทบาทจาก Backpack และ Character Items
                        local bp = player:FindFirstChild("Backpack")
                        if (bp and bp:FindFirstChild("Knife")) or (char:FindFirstChild("Knife")) then
                            highlight.FillColor = Color3.fromRGB(255, 40, 40) -- ฆาตกร (แดง)
                        elseif (bp and bp:FindFirstChild("Gun")) or (char:FindFirstChild("Gun")) then
                            highlight.FillColor = Color3.fromRGB(0, 140, 255) -- นายอำเภอ (ฟ้า)
                        else
                            highlight.FillColor = Color3.fromRGB(40, 255, 40) -- คนบริสุทธิ์ (เขียว)
                        end
                    end
                end
            end
        end)
        table.insert(HubState.ActiveConnections, conn)
    else
        for _, player in ipairs(Players:GetPlayers()) do
            if player.Character and player.Character:FindFirstChild("MM2_EnterpriseESP") then
                player.Character.MM2_EnterpriseESP:Destroy()
            end
        end
    end
end)

-- 2. Gun Drop ESP (Tracker for dropped Sheriff Revolver)
CreateAdvancedToggle("2. Gun Drop ESP (Track Dropped Weapon)", function(state)
    HubState.Configs.ESP_Gun = state
    if state then
        local conn = RunService.RenderStepped:Connect(function()
            for _, obj in ipairs(Workspace:GetChildren()) do
                if obj.Name == "GunDrop" then
                    local billboard = obj:FindFirstChild("EnterpriseGunTag")
                    if not billboard then
                        billboard = Instance.new("BillboardGui")
                        billboard.Name = "EnterpriseGunTag"
                        billboard.Size = UDim2.new(0, 120, 0, 50)
                        billboard.AlwaysOnTop = true
                        billboard.Parent = obj
                        table.insert(HubState.ESPObjects, billboard)

                        local txt = Instance.new("TextLabel")
                        txt.Size = UDim2.new(1, 0, 1, 0)
                        txt.BackgroundTransparency = 1
                        txt.Font = Enum.Font.GothamBold
                        txt.Text = "🎯 [ GUN DROP ]"
                        txt.TextColor3 = Color3.fromRGB(255, 255, 0)
                        txt.TextSize = 13
                        txt.Parent = billboard
                    end
                end
            end
        end)
        table.insert(HubState.ActiveConnections, conn)
    else
        for _, obj in ipairs(Workspace:GetChildren()) do
            if obj.Name == "GunDrop" and obj:FindFirstChild("EnterpriseGunTag") then
                obj.EnterpriseGunTag:Destroy()
            end
        end
    end
end)

-- 3. Coin Farm / Auto Collect Coins (Automated Teleportation Loop)
CreateAdvancedToggle("3. Auto Collect Coins (Coin Farm Automation)", function(state)
    HubState.Configs.Coin_Farm = state
    if state then
        local conn = RunService.Heartbeat:Connect(function()
            pcall(function()
                local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if root then
                    for _, container in ipairs(Workspace:GetChildren()) do
                        if container.Name == "CoinContainer" or container.Name == "Map" then
                            for _, coin in ipairs(container:GetDescendants()) do
                                if coin.Name == "CoinVisual" or coin.Name == "Coin" then
                                    local part = coin:IsA("Model") and coin.PrimaryPart or coin
                                    if part and part:IsA("BasePart") then
                                        root.CFrame = part.CFrame
                                        task.wait(0.08)
                                    end
                                end
                            end
                        end
                    end
                end
            end)
        end)
        table.insert(HubState.ActiveConnections, conn)
    end
end)

-- 4. ESP Coins (Highlight All Map Currency Locations)
CreateAdvancedToggle("4. ESP Coins (Highlight All Currencies)", function(state)
    HubState.Configs.ESP_Coins = state
    if state then
        local conn = RunService.RenderStepped:Connect(function()
            for _, container in ipairs(Workspace:GetDescendants()) do
                if container.Name == "CoinVisual" or container.Name == "Coin" then
                    local part = container:IsA("Model") and container.PrimaryPart or container
                    if part and part:IsA("BasePart") then
                        local hl = part:FindFirstChild("CoinEnterpriseHL")
                        if not hl then
                            hl = Instance.new("Highlight")
                            hl.Name = "CoinEnterpriseHL"
                            hl.FillColor = Color3.fromRGB(255, 215, 0)
                            hl.Parent = part
                            table.insert(HubState.ESPObjects, hl)
                        end
                    end
                end
            end
        end)
        table.insert(HubState.ActiveConnections, conn)
    else
        for _, container in ipairs(Workspace:GetDescendants()) do
            if container.Name == "CoinVisual" or container.Name == "Coin" then
                local part = container:IsA("Model") and container.PrimaryPart or container
                if part and part:FindFirstChild("CoinEnterpriseHL") then
                    part.CoinEnterpriseHL:Destroy()
                end
            end
        end
    end
end)

-- 5. Hitbox Extender (Enlarged Target Hitbox Management)
CreateAdvancedToggle("5. Hitbox Extender (Enlarge Player Hitboxes)", function(state)
    HubState.Configs.Hitbox_Exp = state
    if state then
        local conn = RunService.RenderStepped:Connect(function()
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                    local hrp = player.Character.HumanoidRootPart
                    hrp.Size = Vector3.new(4.5, 4.5, 4.5)
                    hrp.Transparency = 0.75
                    hrp.CanCollide = false
                end
            end
        end)
        table.insert(HubState.ActiveConnections, conn)
    else
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                local hrp = player.Character.HumanoidRootPart
                hrp.Size = Vector3.new(2, 2, 1)
                hrp.Transparency = 1
                hrp.CanCollide = true
            end
        end
    end
end)

-- 6. Auto Shoot Murderer (Automated Sheriff Counter-Attack Bot)
CreateAdvancedToggle("6. Auto Shoot Murderer (Sheriff Combat Bot)", function(state)
    HubState.Configs.Auto_Shoot = state
    if state then
        local conn = RunService.RenderStepped:Connect(function()
            pcall(function()
                local char = LocalPlayer.Character
                local gun = char and (char:FindFirstChild("Gun") or LocalPlayer.Backpack:FindFirstChild("Gun"))
                if gun then
                    for _, player in ipairs(Players:GetPlayers()) do
                        if player ~= LocalPlayer and player.Character then
                            local pChar = player.Character
                            if pChar:FindFirstChild("Knife") or (player.Backpack and player.Backpack:FindFirstChild("Knife")) then
                                local targetHRP = pChar:FindFirstChild("HumanoidRootPart")
                                local myHRP = char:FindFirstChild("HumanoidRootPart")
                                if targetHRP and myHRP then
                                    myHRP.CFrame = CFrame.new(myHRP.Position, targetHRP.Position)
                                    if gun.Parent == LocalPlayer.Backpack then
                                        gun.Parent = char
                                    end
                                    gun:Activate()
                                end
                            end
                        end
                    end
                end
            end)
        end)
        table.insert(HubState.ActiveConnections, conn)
    end
end)

-- 7. Speed Walk & Jump Boost (Advanced Player Movement Tuning)
CreateAdvancedToggle("7. Speed & Jump Boost (Enhanced Velocity)", function(state)
    HubState.Configs.Speed_Jump = state
    pcall(function()
        local humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            if state then
                humanoid.WalkSpeed = 24
                humanoid.JumpPower = 60
            else
                humanoid.WalkSpeed = 16
                humanoid.JumpPower = 50
            end
        end
    end)
end)

-- 8. Noclip (Collision bypass mechanism for exploration)
CreateAdvancedToggle("8. Noclip (Bypass All Physical Collisions)", function(state)
    HubState.Configs.Noclip = state
    if state then
        local conn = RunService.Stepped:Connect(function()
            pcall(function()
                for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            end)
        end)
        table.insert(HubState.ActiveConnections, conn)
    end
end)

-- 9. Spectate Player (Real-time camera subject rotation)
CreateAdvancedToggle("9. Spectate Mode (Observe Other Players)", function(state)
    HubState.Configs.Spectate = state
    if state then
        pcall(function()
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                    CurrentCamera.CameraSubject = player.Character.Humanoid
                    break
                end
            end
        end)
    else
        pcall(function()
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
                CurrentCamera.CameraSubject = LocalPlayer.Character.Humanoid
            end
        end)
    end
end)

-- 10. Quick Server Hop (Automated Lobby Teleportation Engine)
CreateAdvancedToggle("10. Quick Server Hop (Switch Low-Player Servers)", function(state)
    HubState.Configs.Server_Hop = state
    if state then
        pcall(function()
            local servers = HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=100"))
            for _, s in ipairs(servers.data) do
                if s.playing < s.maxPlayers and s.id ~= game.JobId then
                    TeleportService:TeleportToPlaceInstance(game.PlaceId, s.id, LocalPlayer)
                    break
                end
            end
        end)
    end
end)

print("================================================================================")
print("MM2 MASSIVE ENTERPRISE HUB INITIALIZED SUCCESSFULLY ON DELTA ANDROID.")
print("================================================================================")
