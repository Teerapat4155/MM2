-- =============================================================================
-- MM2 APEX HUNTER EDITION | ปรับปรุง: แก้ตัวลอย + หน่วง 1วินาทีเมื่อเก็บเหรียญ
-- =============================================================================

-- SERVICES
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser = game:GetService("VirtualUser")

local LocalPlayer = Players.LocalPlayer
local localMouse = LocalPlayer:GetMouse()

-- STATE
local State = {
    AntiAFK = true,
    Noclip = false,
    Speed = false,
    Aura = false,
    ESP = false,
    AutoCoin = false,
    FlingMurderer = false,
    FlingSheriff = false,
    FlingInnocent = false,
    AuraRange = 300,
    SelectedTarget = nil,
    SpeedValue = 25,
}

local Connections = {}
local Highlights = {}
local IsDead = false

local function addConnection(conn)
    table.insert(Connections, conn)
    return conn
end

-- ANTI-AFK SYSTEM
addConnection(LocalPlayer.Idled:Connect(function()
    if State.AntiAFK then
        pcall(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new(0, 0))
        end)
    end
end))

-- UTILITY: accurate role detection
local function getRoleRaw(plr)
    if not plr or not plr.Character then return "Innocent" end
    local char = plr.Character

    for _, item in ipairs(char:GetChildren()) do
        if item:IsA("Tool") then
            local name = item.Name:lower()
            if name:find("gun") or name:find("revolver") or name:find("sheriff") then
                return "Sheriff"
            elseif name:find("knife") or name:find("blade") or name:find("murderer") or name:find("cuchillo") then
                return "Murderer"
            end
        end
    end

    local bp = plr:FindFirstChildOfClass("Backpack")
    if bp then
        local hasGun, hasKnife = false, false
        for _, item in ipairs(bp:GetChildren()) do
            if item:IsA("Tool") then
                local name = item.Name:lower()
                if name:find("gun") or name:find("revolver") then hasGun = true end
                if name:find("knife") or name:find("blade") then hasKnife = true end
            end
        end
        if hasKnife and not hasGun then
            return "Murderer"
        elseif hasGun and not hasKnife then
            return "Sheriff"
        end
    end
    return "Innocent"
end

local RoleCache = {}
local LastRoleUpdate = 0

local function getRole(plr)
    if not plr then return "Innocent" end
    if RoleCache[plr] == nil then
        RoleCache[plr] = getRoleRaw(plr)
    end
    return RoleCache[plr]
end

addConnection(RunService.Heartbeat:Connect(function()
    if IsDead then return end
    local tick = os.clock()
    if tick - LastRoleUpdate < 0.5 then return end
    LastRoleUpdate = tick
    for _, plr in ipairs(Players:GetPlayers()) do
        RoleCache[plr] = getRoleRaw(plr)
    end
end))

addConnection(Players.PlayerRemoving:Connect(function(plr)
    RoleCache[plr] = nil
end))

local function hookCharAdded(plr)
    addConnection(plr.CharacterAdded:Connect(function()
        RoleCache[plr] = nil
    end))
end
for _, plr in ipairs(Players:GetPlayers()) do hookCharAdded(plr) end
addConnection(Players.PlayerAdded:Connect(hookCharAdded))

-- HELPERS
local function getHRP(char)
    return char and char:FindFirstChild("HumanoidRootPart")
end
local function getHum(char)
    return char and char:FindFirstChildOfClass("Humanoid")
end
local function alive(plr)
    local char = plr.Character
    local hum = getHum(char)
    return char and hum and hum.Health > 0
end

-- GOD FLING
local spinAngle = 0
local function godFling(targetHRP)
    if not targetHRP then return end
    local myChar = LocalPlayer.Character
    local myHRP = getHRP(myChar)
    local myHum = getHum(myChar)
    if not myHRP or not myHum or myHum.Health <= 0 then return end
    pcall(function()
        spinAngle = spinAngle + 180
        local offset = Vector3.new(
            math.cos(math.rad(spinAngle)) * 1.2,
            0.5,
            math.sin(math.rad(spinAngle)) * 1.2
        )
        myHRP.CFrame = targetHRP.CFrame + offset
        myHRP.Velocity = Vector3.new(0, 50, 0)
        myHRP.RotVelocity = Vector3.new(0, 999999, 0)
        targetHRP.Velocity = Vector3.new(
            math.random(-9999999, 9999999),
            9999999,
            math.random(-9999999, 9999999)
        )
        targetHRP.RotVelocity = Vector3.new(
            math.random(-9999999, 9999999),
            9999999,
            math.random(-9999999, 9999999)
        )
    end)
end

-- AURA KILL & AUTO-EQUIP SYSTEM
local function getAndEquipKnife()
    local myChar = LocalPlayer.Character
    if not myChar then return nil end
    local function findKnife(container)
        if not container then return nil end
        for _, tool in ipairs(container:GetChildren()) do
            if tool:IsA("Tool") then
                return tool
            end
        end
        return nil
    end

    local activeTool = myChar:FindFirstChildOfClass("Tool")
    if activeTool then return activeTool end
    local bp = LocalPlayer:FindFirstChildOfClass("Backpack")
    local knife = findKnife(bp) or findKnife(myChar)
    if knife then
        pcall(function()
            local hum = getHum(myChar)
            if hum then hum:EquipTool(knife) end
        end)
        return knife
    end
    return nil
end

local function executeKill(targetChar, targetHRP)
    if not targetChar then return end
    local targetHum = getHum(targetChar)
    if not targetHum or targetHum.Health <= 0 then return end

    local myChar = LocalPlayer.Character
    local knife = myChar and myChar:FindFirstChildOfClass("Tool")
    local handle = knife and (knife:FindFirstChild("Handle") or knife:FindFirstChildWhichIsA("BasePart"))

    if handle and targetHRP then
        pcall(function() firetouchinterest(handle, targetHRP, 0) end)
        task.wait()
        pcall(function() firetouchinterest(handle, targetHRP, 1) end)
    end

    if handle then
        pcall(function()
            local old = handle.CFrame
            handle.CFrame = targetHRP.CFrame
            task.wait(0.02)
            handle.CFrame = old
        end)
    end

    if knife then
        pcall(function()
            for _, desc in ipairs(knife:GetDescendants()) do
                if desc:IsA("RemoteEvent") then
                    desc:FireServer(targetHRP)
                end
            end
        end)
        pcall(function() knife:Activate() end)
    end
end

-- ESP SYSTEM
local ROLE_COLORS = {
    Murderer = Color3.fromRGB(255, 40, 40),
    Sheriff = Color3.fromRGB(40, 120, 255),
    Innocent = Color3.fromRGB(40, 255, 80),
}

local function shouldShowESP(targetRole, myRole)
    if myRole == "Murderer" then return true end
    if myRole == "Sheriff" then return targetRole == "Murderer" end
    return false
end

local function clearHighlights()
    for plr, hl in pairs(Highlights) do
        pcall(function() hl:Destroy() end)
        Highlights[plr] = nil
    end
end

local function updateESP()
    if not State.ESP then
        clearHighlights()
        return
    end
    local myRole = getRole(LocalPlayer)
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and alive(plr) then
            local role = getRole(plr)
            local char = plr.Character
            if char then
                local hl = Highlights[plr]
                if not hl or hl.Parent ~= char then
                    if hl then pcall(function() hl:Destroy() end) end
                    hl = Instance.new("Highlight")
                    hl.Name = "ESP_" .. plr.Name
                    hl.FillTransparency = 0.45
                    hl.OutlineTransparency = 0
                    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                    hl.Parent = char
                    Highlights[plr] = hl
                end
                hl.FillColor = ROLE_COLORS[role] or Color3.new(1, 1, 1)
                hl.OutlineColor = ROLE_COLORS[role] or Color3.new(1, 1, 1)
                hl.Enabled = shouldShowESP(role, myRole)
            else
                local hl = Highlights[plr]
                if hl then pcall(function() hl:Destroy() end)
                Highlights[plr] = nil
            end
        end
    end
end

-- LOOPS
local OriginalCanCollide = {}
addConnection(RunService.Stepped:Connect(function()
    if IsDead then return end
    if State.Noclip or State.FlingMurderer or State.FlingSheriff or State.FlingInnocent then
        local char = LocalPlayer.Character
        if char then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    if OriginalCanCollide[part] == nil then
                        OriginalCanCollide[part] = part.CanCollide
                    end
                    pcall(function() part.CanCollide = false end)
                end
            end
        end
    else
        for part, canCollide in pairs(OriginalCanCollide) do
            if part and part.Parent then
                pcall(function() part.CanCollide = canCollide end)
            end
        end
        OriginalCanCollide = {}
    end
end))

addConnection(RunService.Heartbeat:Connect(function()
    if IsDead then return end
    if State.Speed then
        local char = LocalPlayer.Character
        local hum = getHum(char)
        if hum then pcall(function() hum.WalkSpeed = State.SpeedValue end) end
    end
end))

local _G_espTick = 0
addConnection(RunService.RenderStepped:Connect(function()
    if IsDead then return end
    _G_espTick = (_G_espTick or 0) + 1
    if _G_espTick % 12 == 0 then
        updateESP()
    end
end))

-- AURA KILL LOOP
local _G_auraTick = 0
addConnection(RunService.Heartbeat:Connect(function()
    if IsDead then return end
    if not State.Aura then return end
    if getRole(LocalPlayer) ~= "Murderer" then return end

    _G_auraTick = (_G_auraTick or 0) + 1
    if _G_auraTick % 6 == 0 then
        local myChar = LocalPlayer.Character
        local hasAnyTool = myChar:FindFirstChildOfClass("Tool") or (LocalPlayer:FindFirstChildOfClass("Backpack") and LocalPlayer.Backpack:FindFirstChildOfClass("Tool"))
        if hasAnyTool then
            getAndEquipKnife()
            local myHRP = getHRP(myChar)
            if myHRP then
                for _, plr in ipairs(Players:GetPlayers()) do
                    if plr ~= LocalPlayer and alive(plr) then
                        local tChar = plr.Character
                        local tHRP = getHRP(tChar)
                        if tHRP then
                            local dist = (myHRP.Position - tHRP.Position).Magnitude
                            if dist <= State.AuraRange then
                                task.spawn(executeKill, tChar, tHRP)
                            end
                        end
                    end
                end
            end
        end
    end
end))

-- AUTO COIN FARM LOOP ✅ ปรับปรุงแล้ว: แก้ตัวลอย + หน่วง 1 วินาที
addConnection(RunService.Heartbeat:Connect(function(deltaTime)
    if IsDead then return end
    if not State.AutoCoin then return end

    local char = LocalPlayer.Character
    if not char then return end
    local hrp = getHRP(char)
    local hum = getHum(char)
    if not hrp or not hum or hum.Health <= 0 then return end

    hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
    hrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)

    local murdererHRP = nil
    for _, plr in ipairs(Players:GetPlayers()) do
        if getRole(plr) == "Murderer" then
            local mChar = plr.Character
            local mHRP = getHRP(mChar)
            if mHRP then
                local distToMurderer = (hrp.Position - mHRP.Position).Magnitude
                if distToMurderer <= 15 then
                    murdererHRP = mHRP
                end
            end
        end
    end

    local coinContainer = Workspace:FindFirstChild("CoinContainer") or Workspace:FindFirstChild("Normal")
    if not coinContainer then
        for _, v in ipairs(Workspace:GetChildren()) do
            if v:FindFirstChild("CoinContainer") or v.Name:lower():find("coin") then
                coinContainer = v
                break
            end
        end
    end

    if coinContainer then
        local nearestCoin = nil
        local shortestDist = math.huge

        for _, coin in ipairs(coinContainer:GetDescendants()) do
            if coin.Name == "Coin" or coin:FindFirstChild("CoinVisual") or coin:IsA("BasePart") then
                local coinPart = coin:IsA("BasePart") and coin or coin:FindFirstChildWhichIsA("BasePart")
                if coinPart then
                    local skipThisCoin = false
                    if murdererHRP then
                        if (coinPart.Position - murdererHRP.Position).Magnitude <= 15 then
                            skipThisCoin = true
                        end
                    end

                    if not skipThisCoin then
                        local dist = (hrp.Position - coinPart.Position).Magnitude
                        
                        -- ⏱️ หน่วง 1 วินาทีเมื่อไปถึงเหรียญ
                        if dist < 3 then
                            task.wait(1)
                        end
                        
                        if dist < shortestDist then
                            shortestDist = dist
                            nearestCoin = coinPart
                        end
                    end
                end
            end
        end

        if nearestCoin then
            -- ✅ แก้จุดลอย: ใช้ความสูงจากเหรียญจริง บวกเล็กน้อยพอดีพื้น
            local targetPos = Vector3.new(
                nearestCoin.Position.X,
                nearestCoin.Position.Y + 0.3,
                nearestCoin.Position.Z
            )
            
            local alpha = math.clamp(25 * deltaTime, 0, 1)
            if murdererHRP then
                local fleeDir = (hrp.Position - murdererHRP.Position).Unit
                local fleePos = hrp.Position + (fleeDir * 20)
                hrp.CFrame = hrp.CFrame:Lerp(CFrame.new(fleePos), 0.2)
            else
                hrp.CFrame = hrp.CFrame:Lerp(CFrame.new(targetPos), alpha)
            end
        end
    end
end))

-- FLING LOOP
local flingIndex = 0
local FLING_PER_FRAME = 2
addConnection(RunService.Heartbeat:Connect(function()
    if IsDead then return end
    if not (State.FlingMurderer or State.FlingSheriff or State.FlingInnocent) then
        spinAngle = 0
        return
    end

    local targets = {}
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and alive(plr) then
            local role = getRole(plr)
            if (role == "Murderer" and State.FlingMurderer)
            or (role == "Sheriff" and State.FlingSheriff)
            or (role == "Innocent" and State.FlingInnocent) then
                local tHRP = getHRP(plr.Character)
                if tHRP then table.insert(targets, tHRP) end
            end
        end
    end

    if #targets == 0 then return end
    for i = 1, FLING_PER_FRAME do
        flingIndex = (flingIndex % #targets) + 1
        godFling(targets[flingIndex])
    end
end))

addConnection(Players.PlayerRemoving:Connect(function(plr)
    local hl = Highlights[plr]
    if hl then pcall(function() hl:Destroy() end) end
    Highlights[plr] = nil
end))

-- =========================================================== UI SYSTEM ==========
-- =================================================
local UDim2 = UDim2
local Color3 = Color3
local TweenInfo = TweenInfo

pcall(function()
    if _G.MM2_Cleanup then _G.MM2_Cleanup() end
end)
pcall(function()
    if _G.MM2_UI then _G.MM2_UI:Destroy() end
end)

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MM2_Apex_UI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local gethui = nil
pcall(function() gethui = gethui end)

if gethui then
    ScreenGui.Parent = gethui()
else
    ScreenGui.Parent = game:GetService("CoreGui")
end
_G.MM2_UI = ScreenGui

-- TOGGLE ICON
local Icon = Instance.new("TextButton")
Icon.Name = "ToggleIcon"
Icon.Size = UDim2.new(0, 50, 0, 50)
Icon.Position = UDim2.new(1, -65, 1, -65)
Icon.BackgroundColor3 = Color3.fromRGB(20, 28, 40)
Icon.BorderSizePixel = 0
Icon.Font = Enum.Font.GothamBold
Icon.Text = "M"
Icon.TextSize = 22
Icon.TextColor3 = Color3.fromRGB(255, 60, 60)
Icon.AutoButtonColor = false
Icon.Parent = ScreenGui

local IconCorner = Instance.new("UICorner")
IconCorner.CornerRadius = UDim.new(0, 12)
IconCorner.Parent = Icon

local IconStroke = Instance.new("UIStroke")
IconStroke.Color = Color3.fromRGB(255, 60, 60)
IconStroke.Thickness = 1.5
IconStroke.Parent = Icon

-- MAIN FRAME
local Main = Instance.new("Frame")
Main.Name = "MainFrame"
Main.Size = UDim2.new(0, 350, 0, 400)
Main.Position = UDim2.new(0.5, -175, 0.5, -200)
Main.BackgroundColor3 = Color3.fromRGB(18, 18, 26)
Main.BorderSizePixel = 0
Main.Visible = false
Main.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 12)
MainCorner.Parent = Main

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(80, 80, 120)
MainStroke.Thickness = 1
MainStroke.Parent = Main

-- TITLE BAR
local TitleBar = Instance.new("Frame")
TitleBar.Name = "TitleBar"
TitleBar.Size = UDim2.new(1, 0, 0, 40)
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
TitleBarCover.Parent = TitleBar

local Title = Instance.new("TextLabel")
Title.Name = "Title"
Title.Size = UDim2.new(1, -50, 1, 0)
Title.Position = UDim2.new(0, 12, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "MM2 Apex Hunter"
Title.Font = Enum.Font.GothamBold
Title.TextSize = 15
Title.TextColor3 = Color3.fromRGB(255, 70, 70)
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TitleBar

local CloseBtn = Instance.new("TextButton")
CloseBtn.Name = "CloseBtn"
CloseBtn.Size = UDim2.new(0, 26, 0, 26)
CloseBtn.Position = UDim2.new(1, -34, 0.5, -13)
CloseBtn.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
CloseBtn.BorderSizePixel = 0
CloseBtn.Text = "×"
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 14
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.AutoButtonColor = false
CloseBtn.Parent = TitleBar

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 6)
CloseCorner.Parent = CloseBtn

-- MAKE DRAGGABLE
local function makeDraggable(frame, dragArea)
    local dragging, dragStart, startPos = false, nil, nil
    dragArea.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType.Touch) then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)
    dragArea.InputEnded:Connect(function() dragging = false end)
end
makeDraggable(Icon, Icon)
makeDraggable(Main, TitleBar)

-- CONTENT
local Content = Instance.new("ScrollingFrame")
Content.Name = "Content"
Content.Size = UDim2.new(1, -16, 1, -52)
Content.Position = UDim2.new(0, 8, 0, 46)
Content.BackgroundTransparency = 1
Content.BorderSizePixel = 0
Content.ScrollBarThickness = 3
Content.CanvasSize = UDim2.new(0, 0, 0, 0)
Content.AutomaticCanvasSize = Enum.AutomaticSize.Y
Content.ScrollBarColor = Color3.fromRGB(100, 100, 140)
Content.Parent = Main

local ContentLayout = Instance.new("UIListLayout")
ContentLayout.Padding = UDim.new(0, 6)
ContentLayout.SortOrder = Enum.SortOrder.LayoutOrder
ContentLayout.Parent = Content

local ContentPadding = Instance.new("UIPadding")
ContentPadding.PaddingTop = UDim.new(0, 8)
ContentPadding.Parent = Content

local yIndex = 0
local function sectionLabel(text)
    yIndex = yIndex + 1
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 0, 22)
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.GothamBold
    lbl.Text = text
    lbl.TextSize = 12
    lbl.TextColor3 = Color3.fromRGB(255, 90, 90)
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.LayoutOrder = yIndex
    lbl.Parent = Content
    return lbl
end

local function createToggle(name, stateKey, color)
    yIndex = yIndex + 1
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 36)
    row.BackgroundColor3 = Color3.fromRGB(30, 30, 44)
    row.BorderSizePixel = 0
    row.LayoutOrder = yIndex
    row.Parent = Content

    local rc = Instance.new("UICorner")
    rc.CornerRadius = UDim.new(0, 6)
    rc.Parent = row

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0.6, 0, 1, 0)
    lbl.Position = UDim2.new(0, 10, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.GothamSemibold
    lbl.Text = name
    lbl.TextSize = 13
    lbl.TextColor3 = Color3.fromRGB(220, 220, 235)
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = row

    local toggle = Instance.new("TextButton")
    toggle.Size = UDim2.new(0, 40, 0, 22)
    toggle.Position = UDim2.new(1, -48, 0.5, -11)
    toggle.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
    toggle.BorderSizePixel = 0
    toggle.Text = ""
    toggle.AutoButtonColor = false
    toggle.Parent = row

    local tc = Instance.new("UICorner")
    tc.CornerRadius = UDim.new(0, 11)
    tc.Parent = toggle

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 16, 0, 16)
    knob.Position = UDim2.new(0, 3, 0.5, -8)
    knob.BackgroundColor3 = Color3.fromRGB(220, 220, 220)
    knob.Parent = toggle

    local kc = Instance.new("UICorner")
    kc.CornerRadius = UDim.new(0, 8)
    kc.Parent = knob

    local onColor = color or Color3.fromRGB(60, 200, 90)
    local function updateVisual()
        if State[stateKey] then
            TweenService:Create(toggle, TweenInfo.new(0.2), {BackgroundColor3 = onColor}):Play()
            TweenService:Create(knob, TweenInfo.new(0.2), {Position = UDim2.new(1, -19, 0.5, -8)}):Play()
        else
            TweenService:Create(toggle, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(60, 60, 80)}):Play()
            TweenService:Create(knob, TweenInfo.new(0.2), {Position = UDim2.new(0, 3, 0.5, -8)}):Play()
        end
    end
    updateVisual()
    toggle.MouseButton1Click:Connect(function()
        State[stateKey] = not State[stateKey]
        updateVisual()
        if stateKey == "ESP" and not State.ESP then
            clearHighlights()
        end
    end)
    return row
end

local function createSlider(name, stateKey, minVal, maxVal, suffix)
    yIndex = yIndex + 1
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 48)
    row.BackgroundColor3 = Color3.fromRGB(30, 30, 44)
    row.BorderSizePixel = 0
    row.LayoutOrder = yIndex
    row.Parent = Content

    local rc = Instance.new("UICorner")
    rc.CornerRadius = UDim.new(0, 6)
    rc.Parent = row

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0.7, 0, 0, 18)
    lbl.Position = UDim2.new(0, 10, 0, 4)
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.GothamSemibold
    lbl.Text = name
    lbl.TextSize = 12
    lbl.TextColor3 = Color3.fromRGB(220, 220, 235)
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = row

    local valLbl = Instance.new("TextLabel")
    valLbl.Size = UDim2.new(0.3, -10, 0, 18)
    valLbl.Position = UDim2.new(1, -5, 0, 4)
    valLbl.BackgroundTransparency = 1
    valLbl.Font = Enum.Font.GothamBold
    valLbl.Text = tostring(State[stateKey]) .. (suffix or "")
    valLbl.TextSize = 12
    valLbl.TextColor3 = Color3.fromRGB(255, 120, 70)
    valLbl.TextXAlignment = Enum.TextXAlignment.Right
    valLbl.Parent = row

    local track = Instance.new("Frame")
    track.Size = UDim2.new(1, -20, 0, 6)
    track.Position = UDim2.new(0, 10, 0, 32)
    track.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
    track.Parent = row

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new(0, 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(255, 120, 60)
    fill.Parent = track

    local fc = Instance.new("UICorner")
    fc.CornerRadius = UDim.new(0, 3)
    fc.Parent = fill

    local knob = Instance.new("TextButton")
    knob.Size = UDim2.new(0, 14, 0, 14)
    knob.Position = UDim2.new(0, 7, 0.5, -7)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.Text = ""
    knob.AutoButtonColor = false
    knob.Parent = track

    local kc = Instance.new("UICorner")
    kc.CornerRadius = UDim.new(0, 7)
    kc.Parent = knob

    local function setFromX(absX)
        local tPos = track.AbsolutePosition.X
        local tSize = track.AbsoluteSize.X
        local p = math.clamp((absX - tPos) / tSize, 0, 1)
        local val = minVal + (maxVal - minVal) * p
        State[stateKey] = val
        valLbl.Text = tostring(math.floor(val + 0.5)) .. (suffix or "")
        fill.Size = UDim2.new(p, 0, 1, 0)
        knob.Position = UDim2.new(p, -7, 0.5, -7)
    end

    local dragging = false
    knob.MouseButton1Down:Connect(function() dragging = true end)
    UserInputService.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType.Touch then
            if input.Position.X >= knob.AbsolutePosition.X and input.Position.X <= knob.AbsolutePosition.X + knob.AbsoluteSize.X then
                dragging = true
            end
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType.Touch) then
            setFromX(input.Position.X)
        end
    end)
    UserInputService.InputEnded:Connect(function() dragging = false end)

    local p0 = (State[stateKey] - minVal) / (maxVal - minVal)
    fill.Size = UDim2.new(p0, 0, 1, 0)
    knob.Position = UDim2.new(p0, -7, 0.5, -7)
    return row
end

-- BUILD SECTIONS
sectionLabel("🛡️ ระบบป้องกัน")
createToggle("กันตัดการเชื่อมต่อ (Anti-AFK)", "AntiAFK", Color3.fromRGB(100, 255, 100))

sectionLabel("⚔️ ระบบออร่าฆาตกร")
createToggle("ออร่าฆ่าอัตโนมัติ (300ม.)", "Aura", Color3.fromRGB(255, 80, 80))
createSlider("ระยะออร่าฆ่า", "AuraRange", 10, 500, " ม.")

sectionLabel("🪙 ระบบฟาร์มเหรียญ")
createToggle("ฟาร์มเหรียญอัตโนมัติ (เดินราบเรียบ)", "AutoCoin", Color3.fromRGB(255, 215, 0))

sectionLabel("💥 ระบบดีด/ผลัก")
createToggle("ดีดฆาตกรออกนอกพื้นที่", "FlingMurderer", Color3.fromRGB(255, 60, 60))
createToggle("ดีดนายอำเภอออกนอกพื้นที่", "FlingSheriff", Color3.fromRGB(60, 120, 255))
createToggle("ดีดชาวบ้านออกนอกพื้นที่", "FlingInnocent", Color3.fromRGB(60, 220, 100))

sectionLabel("👁️ ระบบมองทะลุ")
createToggle("แสดงสถานะคนในเกม (ESP)", "ESP", Color3.fromRGB(160, 80, 255))

sectionLabel("🏃 ปรับแต่งตัวละคร")
createToggle("ทะลุผ่านกำแพง", "Noclip", Color3.fromRGB(255, 180, 40))
createToggle("ปรับความเร็วเดิน", "Speed", Color3.fromRGB(220, 200, 100))
createSlider("ระดับความเร็ว", "SpeedValue", 16, 200, "")

-- ICON CLICK LOGIC
local uiOpen = false
local iconPressTime = nil
local iconPressPos = nil
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType.Touch then
        if Icon.AbsolutePosition then
            iconPressTime = tick()
            iconPressPos = input.Position
        end
    end
end)
UserInputService.InputEnded:Connect(function(input, gp)
    if gp then return end
    if iconPressTime and iconPressPos then
        local duration = tick() - iconPressTime
        local moved = (input.Position - iconPressPos).Magnitude
        if duration < 0.35 and moved < 6 then
            uiOpen = not uiOpen
            Main.Visible = uiOpen
        end
    end
    iconPressTime = nil
    iconPressPos = nil
end)

-- ICON HOVER
Icon.MouseEnter:Connect(function()
    TweenService:Create(Icon, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(40, 40, 55)}):Play()
end)
Icon.MouseLeave:Connect(function()
    TweenService:Create(Icon, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(20, 28, 40)}):Play()
end)

-- FULL CLEANUP
local function fullCleanup()
    IsDead = true
    for k, v in pairs(State) do
        if type(State[k]) == "boolean" and k ~= "AntiAFK" and k ~= "Aura" then State[k] = false end
    end
    clearHighlights()
    for _, conn in pairs(Connections) do
        pcall(function() conn:Disconnect() end)
    end
    Connections = {}
    task.wait(0.05)
    pcall(function() LocalPlayer.Character.Humanoid.WalkSpeed = 16 end)
    pcall(function() ScreenGui:Destroy() end)
    _G.MM2_UI = nil
    _G.MM2_Cleanup = nil
end

CloseBtn.MouseButton1Click:Connect(fullCleanup)
_G.MM2_Cleanup = fullCleanup

print("[MM2 Apex Hunter] ✅ โหลดสำเร็จ! แก้ไข: เดินเก็บเหรียญไม่ลอย + หน่วง 1 วินาทีเมื่อเก็บเสร็จ")
