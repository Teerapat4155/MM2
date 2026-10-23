--[=========================================================-]
--|                 ROBLOX UNIVERSAL MOBILE                   |
--|            AIMBOT (VISIBLE CHECK) + BOX ESP             |
--|               Optimized for Delta (2340x1080)           |
--[=========================================================-]

if _G.LoadedScript then
    _G.LoadedScript()
end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Camera = workspace.CurrentCamera

local Connections = {}
local ESPTable = {}

local Settings = {
    Aimbot = false,
    FOV = 120,
    Smoothness = 5,
    VisibleCheck = true,
    ESP = false
}

local Drawing = Drawing or {}
if not Drawing.new then
    warn("[Warning]: Drawing API is not fully supported by this executor.")
end

-- สร้าง ScreenGui หลัก
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "FullProAimbotESPScript"
ScreenGui.Parent = PlayerGui
ScreenGui.ResetOnSpawn = false

_G.LoadedScript = function()
    ScreenGui:Destroy()
    for _, conn in ipairs(Connections) do
        if typeof(conn) == "RBXScriptConnection" then
            conn:Disconnect()
        elseif type(conn) == "table" and conn.Disconnect then
            conn:Disconnect()
        end
    end
end

-- ==================== 1. วงกลม FOV ====================
local FOVCircle = Drawing.new("Circle")
FOVCircle.Visible = false
FOVCircle.Filled = false
FOVCircle.Thickness = 1.5
FOVCircle.Color = Color3.fromRGB(0, 255, 0)
FOVCircle.Transparency = 0.8
FOVCircle.Radius = Settings.FOV

-- ==================== 2. ปุ่มไอคอนลอย (Floating Toggle Button) ====================
local ToggleButton = Instance.new("ImageButton")
ToggleButton.Name = "FloatingButton"
ToggleButton.Size = UDim2.new(0, 55, 0, 55)
ToggleButton.Position = UDim2.new(0, 30, 0, 180)
ToggleButton.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
ToggleButton.BorderSizePixel = 0
ToggleButton.Image = "rbxassetid://6031091004"
ToggleButton.Parent = ScreenGui

local UICornerBtn = Instance.new("UICorner")
UICornerBtn.CornerRadius = UDim.new(1, 0)
UICornerBtn.Parent = ToggleButton

local UIStrokeBtn = Instance.new("UIStroke")
UIStrokeBtn.Color = Color3.fromRGB(0, 255, 0)
UIStrokeBtn.Thickness = 2.5
UIStrokeBtn.Parent = ToggleButton

-- ระบบลากไอคอนด้วยนิ้วมือ
local dragging, dragStart, startPos
table.insert(Connections, ToggleButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = ToggleButton.Position
    end
end))

table.insert(Connections, UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        ToggleButton.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end))

table.insert(Connections, UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end))

-- ==================== 3. หน้าต่างเมนูหลัก (Main Window UI) ====================
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainWindow"
MainFrame.Size = UDim2.new(0, 310, 0, 370)
MainFrame.Position = UDim2.new(0.5, -155, 0.5, -185)
MainFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
MainFrame.BorderSizePixel = 0
MainFrame.Visible = false
MainFrame.Parent = ScreenGui

local UICornerMain = Instance.new("UICorner")
UICornerMain.CornerRadius = UDim.new(0, 10)
UICornerMain.Parent = MainFrame

local UIStrokeMain = Instance.new("UIStroke")
UIStrokeMain.Color = Color3.fromRGB(0, 255, 0)
UIStrokeMain.Thickness = 1.5
UIStrokeMain.Parent = MainFrame

table.insert(Connections, ToggleButton.MouseButton1Click:Connect(function()
    MainFrame.Visible = not MainFrame.Visible
end))

local TitleBar = Instance.new("TextLabel")
TitleBar.Size = UDim2.new(1, 0, 0, 40)
TitleBar.BackgroundColor3 = Color3.fromRGB(24, 24, 24)
TitleBar.Text = "  Delta Pro | Aimbot & ESP"
TitleBar.TextColor3 = Color3.fromRGB(0, 255, 0)
TitleBar.TextSize = 13
TitleBar.Font = Enum.Font.SourceSansBold
TitleBar.TextXAlignment = Enum.TextXAlignment.Left
TitleBar.Parent = MainFrame

local UICornerTitle = Instance.new("UICorner")
UICornerTitle.CornerRadius = UDim.new(0, 10)
UICornerTitle.Parent = TitleBar

-- ปุ่มกากบาทปิดทุกอย่าง (Unload)
local CloseButton = Instance.new("TextButton")
CloseButton.Size = UDim2.new(0, 30, 0, 30)
CloseButton.Position = UDim2.new(1, -35, 0, 5)
CloseButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
CloseButton.Text = "X"
CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseButton.TextSize = 14
CloseButton.Font = Enum.Font.SourceSansBold
CloseButton.Parent = TitleBar

local UICornerClose = Instance.new("UICorner")
UICornerClose.CornerRadius = UDim.new(0, 6)
UICornerClose.Parent = CloseButton

table.insert(Connections, CloseButton.MouseButton1Click:Connect(function()
    FOVCircle:Remove()
    for _, esp in pairs(ESPTable) do
        if esp.Box then esp.Box:Remove() end
        if esp.Text then esp.Text:Remove() end
    end
    ScreenGui:Destroy()
end))

-- ==================== UI Builder Functions ====================
local ContentContainer = Instance.new("ScrollingFrame")
ContentContainer.Size = UDim2.new(1, -20, 1, -55)
ContentContainer.Position = UDim2.new(0, 10, 0, 48)
ContentContainer.BackgroundTransparency = 1
ContentContainer.CanvasSize = UDim2.new(0, 0, 0, 400)
ContentContainer.ScrollBarThickness = 3
ContentContainer.Parent = MainFrame

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Padding = UDim.new(0, 8)
UIListLayout.Parent = ContentContainer

local function CreateToggle(name, default, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 36)
    btn.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
    btn.Text = "  " .. name .. ": " .. (default and "ON" or "OFF")
    btn.TextColor3 = default and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(140, 140, 140)
    btn.TextSize = 13
    btn.Font = Enum.Font.SourceSansSemibold
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.Parent = ContentContainer

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = btn

    local state = default
    table.insert(Connections, btn.MouseButton1Click:Connect(function()
        state = not state
        btn.Text = "  " .. name .. ": " .. (state and "ON" or "OFF")
        btn.TextColor3 = state and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(140, 140, 140)
        callback(state)
    end))
end

local function CreateSlider(name, min, max, default, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 48)
    frame.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
    frame.Parent = ContentContainer

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = frame

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -10, 0, 22)
    label.Position = UDim2.new(0, 5, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = "  " .. name .. ": " .. default
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextSize = 12
    label.Font = Enum.Font.SourceSansSemibold
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame

    local sliderBar = Instance.new("TextButton")
    sliderBar.Size = UDim2.new(1, -20, 0, 6)
    sliderBar.Position = UDim2.new(0, 10, 0, 32)
    sliderBar.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    sliderBar.Text = ""
    sliderBar.Parent = frame

    local barCorner = Instance.new("UICorner")
    barCorner.CornerRadius = UDim.new(1, 0)
    barCorner.Parent = sliderBar

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
    fill.BorderSizePixel = 0
    fill.Parent = sliderBar

    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(1, 0)
    fillCorner.Parent = fill

    local sliding = false
    table.insert(Connections, sliderBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            sliding = true
        end
    end))

    table.insert(Connections, UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            sliding = false
        end
    end))

    table.insert(Connections, UserInputService.InputChanged:Connect(function(input)
        if sliding and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local pos = math.clamp((input.Position.X - sliderBar.AbsolutePosition.X) / sliderBar.AbsoluteSize.X, 0, 1)
            fill.Size = UDim2.new(pos, 0, 1, 0)
            local val = math.floor(min + ((max - min) * pos))
            label.Text = "  " .. name .. ": " .. val
            callback(val)
        end
    end))
end

-- ==================== สร้างเมนูควบคุมการทำงาน ====================
CreateToggle("Aimbot Enable", Settings.Aimbot, function(state)
    Settings.Aimbot = state
    FOVCircle.Visible = state
end)

CreateSlider("Aimbot FOV", 30, 500, Settings.FOV, function(val)
    Settings.FOV = val
    FOVCircle.Radius = val
end)

CreateSlider("Smoothness", 1, 20, Settings.Smoothness, function(val)
    Settings.Smoothness = val
end)

CreateToggle("Visible Check (No Wall)", Settings.VisibleCheck, function(state)
    Settings.VisibleCheck = state
end)

CreateToggle("ESP Box & Distance", Settings.ESP, function(state)
    Settings.ESP = state
end)

-- ==================== ฟังก์ชันประมวลผล Aimbot ====================
local function IsVisible(targetPart)
    if not Settings.VisibleCheck then return true end
    local origin = Camera.CFrame.Position
    local direction = (targetPart.Position - origin)
    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {LocalPlayer.Character, Camera}
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    
    local raycastResult = workspace:Raycast(origin, direction, raycastParams)
    if raycastResult then
        if raycastResult.Instance:IsDescendantOf(targetPart.Parent) then
            return true
        end
        return false
    end
    return true
end

local function GetClosestPlayerInFOV()
    local closestPlayer = nil
    local shortestDistance = Settings.FOV
    local viewportSize = Camera.ViewportSize
    local screenCenter = Vector2.new(viewportSize.X / 2, viewportSize.Y / 2)

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
            if humanoid and humanoid.Health > 0 then
                local rootPart = player.Character.HumanoidRootPart
                local screenPos, onScreen = Camera:WorldToViewportPoint(rootPart.Position)

                if onScreen then
                    local magnitude = (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Magnitude
                    if magnitude < shortestDistance then
                        if IsVisible(rootPart) then
                            shortestDistance = magnitude
                            closestPlayer = player
                        end
                    end
                end
            end
        end
    end
    return closestPlayer
end

-- ==================== ระบบ ESP กล่องเขียว + ระยะทาง ====================
local function SetupESP(player)
    local box = Drawing.new("Square")
    box.Visible = false
    box.Color = Color3.fromRGB(0, 255, 0)
    box.Thickness = 1
    box.Filled = false

    local distanceText = Drawing.new("Text")
    distanceText.Visible = false
    distanceText.Color = Color3.fromRGB(0, 255, 0)
    distanceText.Size = 12
    distanceText.Center = true
    distanceText.Outline = true

    ESPTable[player] = {Box = box, Text = distanceText}

    local renderConnection
    renderConnection = RunService.RenderStepped:Connect(function()
        if not Settings.ESP or not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") or not player.Character:FindFirstChildOfClass("Humanoid") or player.Character.Humanoid.Health <= 0 then
            box.Visible = false
            distanceText.Visible = false
            return
        end

        local character = player.Character
        local rootPart = character.HumanoidRootPart
        local head = character:FindFirstChild("Head") or rootPart

        local rootPos, onScreen = Camera:WorldToViewportPoint(rootPart.Position)
        if onScreen then
            local topPos = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
            local bottomPos = Camera:WorldToViewportPoint(rootPart.Position - Vector3.new(0, 3, 0))
            
            local height = math.abs(topPos.Y - bottomPos.Y)
            local width = height / 2

            box.Size = Vector2.new(width, height)
            box.Position = Vector2.new(rootPos.X - width / 2, topPos.Y)
            box.Visible = true

            local distance = (Camera.CFrame.Position - rootPart.Position).Magnitude
            distanceText.Text = math.floor(distance) .. "m"
            distanceText.Position = Vector2.new(rootPos.X, bottomPos.Y + 5)
            distanceText.Visible = true
        else
            box.Visible = false
            distanceText.Visible = false
        end
    end)

    table.insert(Connections, {
        Disconnect = function()
            box:Remove()
            distanceText:Remove()
            if renderConnection then renderConnection:Disconnect() end
        end
    })
end

for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then
        coroutine.wrap(SetupESP)(player)
    end
end
table.insert(Connections, Players.PlayerAdded:Connect(SetupESP))

table.insert(Connections, Players.PlayerRemoving:Connect(function(player)
    if ESPTable[player] then
        if ESPTable[player].Box then ESPTable[player].Box:Remove() end
        if ESPTable[player].Text then ESPTable[player].Text:Remove() end
        ESPTable[player] = nil
    end
end))

-- ==================== ลูปหลัก Aimbot (Realtime) ====================
table.insert(Connections, RunService.RenderStepped:Connect(function()
    local viewportSize = Camera.ViewportSize
    FOVCircle.Position = Vector2.new(viewportSize.X / 2, viewportSize.Y / 2)
    FOVCircle.Radius = Settings.FOV
    FOVCircle.Visible = Settings.Aimbot

    if not Settings.Aimbot then return end

    local target = GetClosestPlayerInFOV()
    if target and target.Character and target.Character:FindFirstChild("Head") then
        local targetHead = target.Character.Head
        Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, targetHead.Position), 1 / math.max(Settings.Smoothness, 1))
    end
end))
