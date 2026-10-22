-- [[ Mobile Universal Script (Delta Android) - Exact Fit ESP ]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- ป้องกันรันซ้ำซ้อน
if _G.MobileScriptLoaded then
    _G.MobileScriptLoaded()
end

local Connections = {}

-- ตัวแปรตั้งค่าฟังก์ชัน
local Config = {
    ESPEnabled = false,
    ScreenAimbotEnabled = false,
    TargetAimbotEnabled = false,
    SelectedTargetName = "None",
    WallCheckEnabled = true
}

-- สร้าง ScreenGui หลัก
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MobileUniversalUI"
ScreenGui.Parent = CoreGui
_G.MobileScriptLoaded = function()
    ScreenGui:Destroy()
end

-- ==================== 1. สร้างไอคอนเปิด-ปิด UI (ลากเลื่อนได้) ====================
local OpenIcon = Instance.new("TextButton")
OpenIcon.Name = "OpenIcon"
OpenIcon.Parent = ScreenGui
OpenIcon.BackgroundColor3 = Color3.fromRGB(30, 144, 255)
OpenIcon.Position = UDim2.new(0, 20, 0.3, 0)
OpenIcon.Size = UDim2.new(0, 50, 0, 50)
OpenIcon.Font = Enum.Font.GothamBold
OpenIcon.Text = "DELTA"
OpenIcon.TextColor3 = Color3.fromRGB(255, 255, 255)
OpenIcon.TextSize = 10
OpenIcon.Draggable = true
OpenIcon.Visible = true

local IconCorner = Instance.new("UICorner")
IconCorner.CornerRadius = UDim.new(1, 0)
IconCorner.Parent = OpenIcon

local IconStroke = Instance.new("UIStroke")
IconStroke.Parent = OpenIcon
IconStroke.Color = Color3.fromRGB(255, 255, 255)
IconStroke.Thickness = 2

-- ==================== 2. สร้าง UI เมนูหลัก ====================
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
MainFrame.BorderSizePixel = 0
MainFrame.Position = UDim2.new(0.5, -160, 0.5, -180)
MainFrame.Size = UDim2.new(0, 320, 0, 390)
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Visible = false

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 12)
UICorner.Parent = MainFrame

OpenIcon.MouseButton1Click:Connect(function()
    MainFrame.Visible = not MainFrame.Visible
end)

local TopBar = Instance.new("Frame")
TopBar.Parent = MainFrame
TopBar.BackgroundColor3 = Color3.fromRGB(35, 35, 48)
TopBar.Size = UDim2.new(1, 0, 0, 40)
TopBar.BorderSizePixel = 0

local TopBarCorner = Instance.new("UICorner")
TopBarCorner.CornerRadius = UDim.new(0, 12)
TopBarCorner.Parent = TopBar

local Title = Instance.new("TextLabel")
Title.Parent = TopBar
Title.BackgroundTransparency = 1
Title.Position = UDim2.new(0, 15, 0, 0)
Title.Size = UDim2.new(0.7, 0, 1, 0)
Title.Font = Enum.Font.GothamBold
Title.Text = "⚡ DELTA MOBILE HUB"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 15
Title.TextXAlignment = Enum.TextXAlignment.Left

local CloseBtn = Instance.new("TextButton")
CloseBtn.Parent = TopBar
CloseBtn.BackgroundColor3 = Color3.fromRGB(230, 50, 50)
CloseBtn.Position = UDim2.new(1, -35, 0.5, -12)
CloseBtn.Size = UDim2.new(0, 24, 0, 24)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.TextSize = 14

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 6)
CloseCorner.Parent = CloseBtn

CloseBtn.MouseButton1Click:Connect(function()
    for _, conn in pairs(Connections) do
        if conn then conn:Disconnect() end
    end
    for p, _ in pairs(ESPCache) do
        RemoveESP(p)
    end
    ScreenGui:Destroy()
    _G.MobileScriptLoaded = nil
end)

local ContentContainer = Instance.new("ScrollingFrame")
ContentContainer.Parent = MainFrame
ContentContainer.BackgroundTransparency = 1
ContentContainer.Position = UDim2.new(0, 10, 0, 50)
ContentContainer.Size = UDim2.new(1, -20, 1, -60)
ContentContainer.CanvasSize = UDim2.new(0, 0, 1.3, 0)
ContentContainer.ScrollBarThickness = 3

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.Parent = ContentContainer
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Padding = UDim.new(0, 10)

-- ฟังก์ชันสร้าง Toggle สวิตช์แบบ Realtime
local function createToggle(name, callback)
    local ToggleFrame = Instance.new("Frame")
    ToggleFrame.Parent = ContentContainer
    ToggleFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 48)
    ToggleFrame.Size = UDim2.new(1, 0, 0, 45)
    
    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 8)
    Corner.Parent = ToggleFrame
    
    local Label = Instance.new("TextLabel")
    Label.Parent = ToggleFrame
    Label.BackgroundTransparency = 1
    Label.Position = UDim2.new(0, 12, 0, 0)
    Label.Size = UDim2.new(0.7, 0, 1, 0)
    Label.Font = Enum.Font.GothamMedium
    Label.Text = name
    Label.TextColor3 = Color3.fromRGB(220, 220, 220)
    Label.TextSize = 13
    Label.TextXAlignment = Enum.TextXAlignment.Left
    
    local SwitchBtn = Instance.new("TextButton")
    SwitchBtn.Parent = ToggleFrame
    SwitchBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 75)
    SwitchBtn.Position = UDim2.new(1, -55, 0.5, -12)
    SwitchBtn.Size = UDim2.new(0, 45, 0, 24)
    SwitchBtn.Text = ""
    
    local SwitchCorner = Instance.new("UICorner")
    SwitchCorner.CornerRadius = UDim.new(1, 0)
    SwitchCorner.Parent = SwitchBtn
    
    local Circle = Instance.new("Frame")
    Circle.Parent = SwitchBtn
    Circle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Circle.Position = UDim2.new(0, 2, 0.5, -10)
    Circle.Size = UDim2.new(0, 20, 0, 20)
    
    local CircleCorner = Instance.new("UICorner")
    CircleCorner.CornerRadius = UDim.new(1, 0)
    CircleCorner.Parent = Circle
    
    local enabled = false
    SwitchBtn.MouseButton1Click:Connect(function()
        enabled = not enabled
        if enabled then
            SwitchBtn.BackgroundColor3 = Color3.fromRGB(0, 220, 100)
            Circle:TweenPosition(UDim2.new(1, -22, 0.5, -10), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.15, true)
        else
            SwitchBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 75)
            Circle:TweenPosition(UDim2.new(0, 2, 0.5, -10), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.15, true)
        end
        callback(enabled)
    end)
end

-- ฟังก์ชัน Dropdown เลือกชื่อผู้เล่นแบบเลื่อนหา
local function createPlayerDropdown()
    local DropdownFrame = Instance.new("Frame")
    DropdownFrame.Parent = ContentContainer
    DropdownFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 48)
    DropdownFrame.Size = UDim2.new(1, 0, 0, 80)
    
    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 8)
    Corner.Parent = DropdownFrame
    
    local Label = Instance.new("TextLabel")
    Label.Parent = DropdownFrame
    Label.BackgroundTransparency = 1
    Label.Position = UDim2.new(0, 12, 0, 5)
    Label.Size = UDim2.new(1, -24, 0, 25)
    Label.Font = Enum.Font.GothamMedium
    Label.Text = "Target Select: [ เลือกผู้เล่น ]"
    Label.TextColor3 = Color3.fromRGB(220, 220, 220)
    Label.TextSize = 13
    Label.TextXAlignment = Enum.TextXAlignment.Left
    
    local ScrollList = Instance.new("ScrollingFrame")
    ScrollList.Parent = DropdownFrame
    ScrollList.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
    ScrollList.Position = UDim2.new(0, 12, 0, 32)
    ScrollList.Size = UDim2.new(1, -24, 0, 40)
    ScrollList.CanvasSize = UDim2.new(0, 0, 0, 0)
    ScrollList.ScrollBarThickness = 3
    
    local ListLayout = Instance.new("UIListLayout")
    ListLayout.Parent = ScrollList
    ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    ListLayout.Padding = UDim.new(0, 4)
    
    local function updatePlayerList()
        for _, child in ipairs(ScrollList:GetChildren()) do
            if child:IsA("TextButton") then child:Destroy() end
        end
        
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then
                local PBtn = Instance.new("TextButton")
                PBtn.Parent = ScrollList
                PBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
                PBtn.Size = UDim2.new(1, -4, 0, 25)
                PBtn.Font = Enum.Font.Gotham
                PBtn.Text = "  " .. p.Name
                PBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
                PBtn.TextSize = 12
                PBtn.TextXAlignment = Enum.TextXAlignment.Left
                
                local BtnCorner = Instance.new("UICorner")
                BtnCorner.CornerRadius = UDim.new(0, 4)
                BtnCorner.Parent = PBtn
                
                PBtn.MouseButton1Click:Connect(function()
                    Config.SelectedTargetName = p.Name
                    Label.Text = "Target: " .. p.Name
                end)
            end
        end
        ScrollList.CanvasSize = UDim2.new(0, 0, 0, #Players:GetPlayers() * 29)
    end
    
    updatePlayerList()
    table.insert(Connections, Players.PlayerAdded:Connect(updatePlayerList))
    table.insert(Connections, Players.PlayerRemoving:Connect(updatePlayerList))
end

-- ==================== สร้างเมนูใน UI ====================
createToggle("1. ESP (กล่องเขียว + ระยะทาง)", function(state)
    Config.ESPEnabled = state
end)

createPlayerDropdown()
createToggle("2. Aimbot (ล็อคตามชื่อที่เลือก)", function(state)
    Config.TargetAimbotEnabled = state
end)

createToggle("3. Aimbot (ล็อคตามหน้าจออัตโนมัติ)", function(state)
    Config.ScreenAimbotEnabled = state
end)

createToggle("4. WallCheck (ไม่ล็อคคนหลังกำแพง)", function(state)
    Config.WallCheckEnabled = state
end)


-- ==================== ระบบ ESP Cache (ขนาดพอดีตัวละครเป๊ะๆ) ====================
ESPCache = {}

function CreateESP(player)
    if ESPCache[player] then return ESPCache[player] end

    local box = Drawing.new("Square")
    box.Visible = false
    box.Color = Color3.fromRGB(46, 204, 113)
    box.Thickness = 1.2
    box.Filled = false

    local distText = Drawing.new("Text")
    distText.Visible = false
    distText.Color = Color3.fromRGB(46, 204, 113)
    distText.Size = 12
    distText.Center = true
    distText.Outline = true

    local cache = {Box = box, DistanceText = distText}
    ESPCache[player] = cache
    return cache
end

function RemoveESP(player)
    if ESPCache[player] then
        if ESPCache[player].Box then ESPCache[player].Box:Remove() end
        if ESPCache[player].DistanceText then ESPCache[player].DistanceText:Remove() end
        ESPCache[player] = nil
    end
end

for _, p in ipairs(Players:GetPlayers()) do
    if p ~= LocalPlayer then CreateESP(p) end
end
table.insert(Connections, Players.PlayerAdded:Connect(CreateESP))
table.insert(Connections, Players.PlayerRemoving:Connect(RemoveESP))


-- ==================== ฟังก์ชันตรวจสอบการมองเห็น (WallCheck) ====================
local function IsVisible(targetPart, character)
    if not Config.WallCheckEnabled then return true end
    
    local origin = Camera.CFrame.Position
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    raycastParams.FilterDescendantsInstances = {LocalPlayer.Character, character}
    
    local raycastResult = workspace:Raycast(origin, targetPart.Position - origin, raycastParams)
    
    if not raycastResult or raycastResult.Instance:IsDescendantOf(character) then
        return true
    end
    
    return false
end


-- ==================== ลูปหลักการทำงานแบบ Realtime ====================
table.insert(Connections, RunService.RenderStepped:Connect(function()
    
    -- 1. อัปเดต ESP (ปรับคำนวณจากขอบเขตตัวละครจริง Model:GetBoundingBox)
    for player, cache in pairs(ESPCache) do
        local char = player.Character
        local hum = char and char:FindFirstChild("Humanoid")
        
        if Config.ESPEnabled and char and hum and hum.Health > 0 then
            local cf, size = char:GetBoundingBox()
            local topCFrame = cf + Vector3.new(0, size.Y / 2, 0)
            local bottomCFrame = cf - Vector3.new(0, size.Y / 2, 0)
            
            local topPos, topOnScreen = Camera:WorldToViewportPoint(topCFrame.Position)
            local bottomPos, bottomOnScreen = Camera:WorldToViewportPoint(bottomCFrame.Position)
            
            if topOnScreen or bottomOnScreen then
                local height = math.abs(bottomPos.Y - topPos.Y)
                local width = height / 2
                
                cache.Box.Size = Vector2.new(width, height)
                cache.Box.Position = Vector2.new(topPos.X - width / 2, topPos.Y)
                cache.Box.Visible = true
                
                local rootPart = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Head")
                if rootPart then
                    local dist = (Camera.CFrame.Position - rootPart.Position).Magnitude
                    cache.DistanceText.Text = math.floor(dist) .. "m"
                    cache.DistanceText.Position = Vector2.new(topPos.X, bottomPos.Y + 2)
                    cache.DistanceText.Visible = true
                else
                    cache.DistanceText.Visible = false
                end
            else
                cache.Box.Visible = false
                cache.DistanceText.Visible = false
            end
        else
            cache.Box.Visible = false
            cache.DistanceText.Visible = false
        end
    end
    
    -- 2. Target Aimbot (พร้อมระบบ WallCheck)
    if Config.TargetAimbotEnabled and Config.SelectedTargetName ~= "None" then
        local targetPlayer = Players:FindFirstChild(Config.SelectedTargetName)
        if targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("Head") then
            local char = targetPlayer.Character
            local head = char.Head
            local hum = char:FindFirstChild("Humanoid")
            
            if hum and hum.Health > 0 and IsVisible(head, char) then
                Camera.CFrame = CFrame.new(Camera.CFrame.Position, head.Position)
            end
        end
    end
    
    -- 3. Screen Aimbot (พร้อมระบบ WallCheck)
    if Config.ScreenAimbotEnabled and not Config.TargetAimbotEnabled then
        local bestTarget = nil
        local minDist = math.huge
        local centerScreen = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("Head") then
                local char = p.Character
                local head = char.Head
                local hum = char:FindFirstChild("Humanoid")
                
                if hum and hum.Health > 0 and IsVisible(head, char) then
                    local screenPos, onScreen = Camera:WorldToViewportPoint(head.Position)
                    if onScreen then
                        local dist = (Vector2.new(screenPos.X, screenPos.Y) - centerScreen).Magnitude
                        if dist < minDist then
                            minDist = dist
                            bestTarget = head
                        end
                    end
                end
            end
        end
        
        if bestTarget then
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, bestTarget.Position)
        end
    end
end))

print("Delta Mobile Hub (Exact-Fit ESP) Loaded Successfully!")
