--[[
    ============================================================
    MM2 PULSE HUB CONFIG → STANDALONE SCRIPT (MOBILE EDITION)
    ✅ ดัดแปลงจาก PulseHubMM2_config.json + PulseFarmMM2_config.json
    ✅ ปรับให้เหมาะกับ Delta Executor บน Android (มือถือ)
    ✅ เอา Auto Fling Sheriff ออกแล้ว (ไม่วิ่งตาม Sheriff → เก็บเหรียญได้ปกติ)
    ============================================================
]]

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local Workspace        = game:GetService("Workspace")
local VirtualUser      = game:GetService("VirtualUser")
local CoreGui          = game:GetService("CoreGui")
local LocalPlayer      = Players.LocalPlayer

local IS_MOBILE = UserInputService.TouchEnabled
local UI_SCALE  = IS_MOBILE and 1.15 or 1

local CONFIG = {
    FarmSpeed       = 22,
    AvoidMurderer   = true,
    MurdererRange   = 30,
    SkipCoinRange   = 20,
    AuraRange       = 250,
    AutoFlingSheriff= false, -- ❌ ปิดไว้ถาวร เอาออกแล้ว
    AntiAFK         = true,
    NoClip          = true,
    WalkSpeed       = 22,
    ColorMurderer   = Color3.fromRGB(102, 43, 43),
    ColorSheriff    = Color3.fromRGB(38, 52, 74),
    ColorInnocent   = Color3.fromRGB(38, 110, 28),
    ColorHero       = Color3.fromRGB(126, 110, 55),
}

if getgenv().PulseMM2_Cleanup then
    pcall(function() getgenv().PulseMM2_Cleanup() end)
end

local State = {
    AutoCoin  = true,
    AuraKill  = true,
    ESP       = true,
    AntiAFK   = CONFIG.AntiAFK,
    NoClip    = CONFIG.NoClip,
    Speed     = false,
}

local Connections = {}
local TargetCoin = nil
local ResumeTime = 0
local ESPObjects = {}
local OriginalCanCollide = {}

local function addConn(conn) table.insert(Connections, conn); return conn end
local function getHRP(c) return c and c:FindFirstChild("HumanoidRootPart") end
local function getHum(c) return c and c:FindFirstChildOfClass("Humanoid") end
local function alive(p) local c=p.Character local h=getHum(c) return c and h and h.Health>0 end

getgenv().PulseMM2_Cleanup = function()
    for k in pairs(State) do State[k] = false end
    local c = LocalPlayer.Character
    if c then
        local h = getHum(c); if h then h.WalkSpeed = 16 end
        for part, orig in pairs(OriginalCanCollide) do
            if part and part.Parent then pcall(function() part.CanCollide = orig end) end
        end
    end
    for _, esp in pairs(ESPObjects) do pcall(function() if esp then esp:Destroy() end end) end
    table.clear(ESPObjects)
    for _, conn in ipairs(Connections) do pcall(function() conn:Disconnect() end) end
    table.clear(Connections)
    pcall(function() if _G.PulseMM2_GUI then _G.PulseMM2_GUI:Destroy() _G.PulseMM2_GUI=nil end end)
end

local function checkContainer(container)
    if not container then return nil end
    local hasTool = false
    for _, item in ipairs(container:GetChildren()) do
        if item:IsA("Tool") then
            local name = string.lower(item.Name)
            if name:find("gun") or name:find("revolver") or name:find("sheriff") then return "Sheriff" end
            if name:find("knife") or name:find("murderer") or name:find("blade") then return "Murderer" end
            hasTool = true
        end
    end
    if hasTool then return "Murderer" end
    return nil
end
local function getRole(p)
    if not p or not p.Character then return "Innocent" end
    local r = checkContainer(p:FindFirstChildOfClass("Backpack"))
    if r then return r end
    r = checkContainer(p.Character)
    return r or "Innocent"
end

local parentUI = nil
pcall(function() parentUI = gethui and gethui() end)
if not parentUI then pcall(function() parentUI = CoreGui end) end
if not parentUI then parentUI = LocalPlayer:WaitForChild("PlayerGui") end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "PulseMM2_GUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.DisplayOrder = 999
ScreenGui.Parent = parentUI
_G.PulseMM2_GUI = ScreenGui

local cam = workspace.CurrentCamera
local vw, vh = cam.ViewportSize.X, cam.ViewportSize.Y
local menuW = math.min(290 * UI_SCALE, vw - 20)
local menuH = math.min(340 * UI_SCALE, vh - 40)

local FloatBtn = Instance.new("TextButton")
FloatBtn.Size = UDim2.new(0, 52, 0, 52)
FloatBtn.Position = UDim2.new(0, 12, 0.4, 0)
FloatBtn.BackgroundColor3 = Color3.fromRGB(28, 28, 42)
FloatBtn.Text = "P"
FloatBtn.Font = Enum.Font.GothamBold
FloatBtn.TextSize = 18
FloatBtn.TextColor3 = Color3.fromRGB(255, 80, 80)
FloatBtn.AutoButtonColor = false
FloatBtn.Parent = ScreenGui
Instance.new("UICorner", FloatBtn).CornerRadius = UDim.new(1, 0)
local fst = Instance.new("UIStroke", FloatBtn); fst.Color = Color3.fromRGB(255, 80, 80); fst.Thickness = 2

local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, menuW, 0, menuH)
Main.Position = UDim2.new(0.5, -menuW/2, 0.5, -menuH/2)
Main.BackgroundColor3 = Color3.fromRGB(18, 18, 26)
Main.Visible = true
Main.Parent = ScreenGui
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 12)
local mst = Instance.new("UIStroke", Main); mst.Color = Color3.fromRGB(255, 80, 80); mst.Thickness = 1.5

local dragging, dragStart, startPos, dragMoved = false, nil, nil, false
addConn(FloatBtn.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
        dragging = true; dragMoved = false; dragStart = i.Position; startPos = FloatBtn.Position
    end
end))
addConn(UserInputService.InputChanged:Connect(function(i)
    if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
        local d = i.Position - dragStart
        if d.Magnitude > 6 then
            dragMoved = true
            FloatBtn.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end
end))
addConn(FloatBtn.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
        if dragging and not dragMoved then Main.Visible = not Main.Visible end
        dragging = false
    end
end))

local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 42)
TitleBar.BackgroundColor3 = Color3.fromRGB(28, 28, 42)
TitleBar.Parent = Main
Instance.new("UICorner", TitleBar).CornerRadius = UDim.new(0, 12)
local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -48, 1, 0); Title.Position = UDim2.new(0, 12, 0, 0)
Title.BackgroundTransparency = 1; Title.Text = "PULSE MM2 (Mobile)"
Title.Font = Enum.Font.GothamBold; Title.TextSize = 14; Title.TextColor3 = Color3.fromRGB(255, 80, 80)
Title.TextXAlignment = Enum.TextXAlignment.Left; Title.Parent = TitleBar

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 32, 0, 32); CloseBtn.Position = UDim2.new(1, -38, 0, 5)
CloseBtn.BackgroundColor3 = Color3.fromRGB(220, 50, 50); CloseBtn.Text = "X"
CloseBtn.Font = Enum.Font.GothamBold; CloseBtn.TextSize = 15; CloseBtn.TextColor3 = Color3.new(1, 1, 1)
CloseBtn.AutoButtonColor = false; CloseBtn.Parent = TitleBar
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 8)
addConn(CloseBtn.MouseButton1Click:Connect(function() getgenv().PulseMM2_Cleanup() end))

local mDrag, mDragStart, mStartPos = false, nil, nil
addConn(TitleBar.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
        mDrag = true; mDragStart = i.Position; mStartPos = Main.Position
    end
end))
addConn(UserInputService.InputChanged:Connect(function(i)
    if mDrag and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
        local d = i.Position - mDragStart
        Main.Position = UDim2.new(mStartPos.X.Scale, mStartPos.X.Offset + d.X, mStartPos.Y.Scale, mStartPos.Y.Offset + d.Y)
    end
end))
addConn(TitleBar.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then mDrag = false end
end))

local Scroll = Instance.new("ScrollingFrame")
Scroll.Size = UDim2.new(1, -12, 1, -52); Scroll.Position = UDim2.new(0, 6, 0, 46)
Scroll.BackgroundTransparency = 1; Scroll.CanvasSize = UDim2.new(0, 0, 0, 400)
Scroll.ScrollBarThickness = 5; Scroll.ScrollingDirection = Enum.ScrollingDirection.Y
Scroll.Parent = Main
local L = Instance.new("UIListLayout"); L.SortOrder = Enum.SortOrder.LayoutOrder; L.Padding = UDim.new(0, 8); L.Parent = Scroll
local Pad = Instance.new("UIPadding"); Pad.PaddingBottom = UDim.new(0, 10); Pad.Parent = Scroll

local function createToggle(name, stateKey, color)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -6, 0, 42); row.BackgroundColor3 = Color3.fromRGB(30, 30, 44)
    row.Parent = Scroll; Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)
    local lbl = Instance.new("TextLabel"); lbl.Size = UDim2.new(1, -65, 1, 0); lbl.Position = UDim2.new(0, 12, 0, 0)
    lbl.BackgroundTransparency = 1; lbl.Text = name; lbl.Font = Enum.Font.GothamSemibold; lbl.TextSize = 13
    lbl.TextColor3 = Color3.fromRGB(220, 220, 235); lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Parent = row
    local btn = Instance.new("TextButton"); btn.Size = UDim2.new(0, 52, 0, 26); btn.Position = UDim2.new(1, -58, 0.5, -13)
    btn.BackgroundColor3 = State[stateKey] and (color or Color3.fromRGB(60, 200, 90)) or Color3.fromRGB(60, 60, 80)
    btn.Text = ""; btn.AutoButtonColor = false; btn.Parent = row
    Instance.new("UICorner", btn).CornerRadius = UDim.new(1, 0)
    local dot = Instance.new("Frame"); dot.Size = UDim2.new(0, 18, 0, 18)
    dot.Position = State[stateKey] and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 4, 0.5, -9)
    dot.BackgroundColor3 = Color3.fromRGB(220, 220, 220); dot.Parent = row; Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)
    btn.MouseButton1Click:Connect(function()
        State[stateKey] = not State[stateKey]
        btn.BackgroundColor3 = State[stateKey] and (color or Color3.fromRGB(60, 200, 90)) or Color3.fromRGB(60, 60, 80)
        dot.Position = State[stateKey] and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 4, 0.5, -9)
    end)
end

createToggle("Auto Coin Farm (22, หลบฆาตกร)", "AutoCoin", Color3.fromRGB(255, 215, 0))
createToggle("Kill Aura (ฆาตกร 250ม.)", "AuraKill", Color3.fromRGB(255, 80, 80))
createToggle("ESP Role (สีตาม config)", "ESP", Color3.fromRGB(160, 80, 255))
createToggle("Anti-AFK", "AntiAFK", Color3.fromRGB(100, 200, 255))
createToggle("Noclip (ตาม config)", "NoClip", Color3.fromRGB(255, 180, 40))
createToggle("Speed Boost (22)", "Speed", Color3.fromRGB(80, 220, 200))

-- ===== ANTI-AFK =====
addConn(LocalPlayer.Idled:Connect(function()
    if not State.AntiAFK then return end
    local ok = pcall(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new(0, 0))
    end)
    if not ok then
        pcall(function() LocalPlayer.Idled:Fire() end)
    end
end))

-- ===== SPEED =====
addConn(RunService.Heartbeat:Connect(function()
    local h = getHum(LocalPlayer.Character)
    if h then h.WalkSpeed = (State.Speed or State.AutoCoin) and CONFIG.WalkSpeed or 16 end
end))

-- ===== NOCLIP =====
addConn(RunService.Stepped:Connect(function()
    local c = LocalPlayer.Character; if not c then return end
    local hrp = getHRP(c); local safeY = hrp and hrp.Position.Y > -40
    for _, part in ipairs(c:GetDescendants()) do
        if part:IsA("BasePart") then
            if OriginalCanCollide[part] == nil then OriginalCanCollide[part] = part.CanCollide end
            part.CanCollide = not (State.NoClip and safeY)
        end
    end
end))

-- ===== KILL AURA =====
addConn(RunService.Heartbeat:Connect(function()
    if not State.AuraKill then return end
    if getRole(LocalPlayer) ~= "Murderer" then return end
    local myChar = LocalPlayer.Character; local myHRP = getHRP(myChar); if not myHRP then return end
    local knife = myChar:FindFirstChildOfClass("Tool")
    if not knife then
        local bp = LocalPlayer:FindFirstChildOfClass("Backpack")
        if bp then for _, t in ipairs(bp:GetChildren()) do if t:IsA("Tool") then
            local h = getHum(myChar); if h then h:EquipTool(t) end; knife = t; break
        end end end
    end
    if not knife then return end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and alive(p) then
            local tHRP = getHRP(p.Character)
            if tHRP and (myHRP.Position - tHRP.Position).Magnitude <= CONFIG.AuraRange then
                pcall(function()
                    tHRP.CFrame = myHRP.CFrame * CFrame.new(0, 0, -2)
                    knife:Activate()
                    local handle = knife:FindFirstChild("Handle")
                    if handle and firetouchinterest then
                        firetouchinterest(handle, tHRP, 0)
                        task.wait()
                        firetouchinterest(handle, tHRP, 1)
                    end
                end)
            end
        end
    end
end))

-- ❌ AUTO FLING SHERIFF ถูกเอาออกแล้ว (ไม่วิ่งตาม Sheriff → เก็บเหรียญได้ปกติ)

-- ===== ESP =====
addConn(RunService.RenderStepped:Connect(function()
    if not State.ESP then
        for _, esp in pairs(ESPObjects) do pcall(function() if esp then esp.Enabled = false end end) end
        return
    end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and alive(p) and p.Character and getHRP(p.Character) then
            pcall(function()
                local char = p.Character
                local box = char:FindFirstChild("Pulse_ESP")
                if not box then
                    box = Instance.new("Highlight"); box.Name = "Pulse_ESP"
                    box.FillTransparency = 0.5; box.OutlineTransparency = 0; box.Parent = char
                    table.insert(ESPObjects, box)
                end
                box.Enabled = true
                local role = getRole(p)
                local col = CONFIG.ColorInnocent
                if role == "Murderer" then col = CONFIG.ColorMurderer
                elseif role == "Sheriff" then col = CONFIG.ColorSheriff end
                box.FillColor = col; box.OutlineColor = col
            end)
        end
    end
end))

-- ===== AUTO COIN FARM =====
addConn(RunService.Heartbeat:Connect(function(deltaTime)
    if not State.AutoCoin then TargetCoin = nil; return end
    if tick() < ResumeTime then return end
    local char = LocalPlayer.Character; if not char then return end
    local hrp = getHRP(char); local hum = getHum(char)
    if not hrp or not hum or hum.Health <= 0 then return end
    hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)

    local murdererHRP = nil
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and alive(p) and getRole(p) == "Murderer" then
            local mHRP = getHRP(p.Character)
            if mHRP and (hrp.Position - mHRP.Position).Magnitude <= CONFIG.MurdererRange then murdererHRP = mHRP end
        end
    end

    for _, obj in ipairs(Workspace:GetChildren()) do
        if obj:IsA("BasePart") and obj.Velocity and obj.Velocity.Magnitude > 15 then
            local nm = obj.Name:lower()
            if nm:find("knife") or nm:find("blade") or nm:find("thrown") then
                local toObj = obj.Position - hrp.Position
                if toObj.Magnitude < 18 then
                    local dodgeDir = Vector3.new(-toObj.Z, 0, toObj.X).Unit
                    hrp.CFrame = CFrame.new(hrp.Position + dodgeDir * 6)
                end
            end
        end
    end

    if hrp.Position.Y < -35 then
        hrp.CFrame = CFrame.new(hrp.Position.X, 10, hrp.Position.Z); TargetCoin = nil; return
    end

    local coinContainer = Workspace:FindFirstChild("CoinContainer") or Workspace:FindFirstChild("Normal")
    if not coinContainer then
        for _, v in ipairs(Workspace:GetChildren()) do
            if v:FindFirstChild("CoinContainer") or string.find(string.lower(v.Name), "coin") then
                coinContainer = v:FindFirstChild("CoinContainer") or v; break
            end
        end
    end
    if not coinContainer then return end

    if not TargetCoin or not TargetCoin.Parent then
        local nearest, distN = nil, math.huge
        for _, coin in ipairs(coinContainer:GetDescendants()) do
            if coin:IsA("BasePart") and coin.Position.Y > -30 then
                local skip = false
                if murdererHRP and (coin.Position - murdererHRP.Position).Magnitude <= CONFIG.SkipCoinRange then skip = true end
                if not skip then
                    local d = (hrp.Position - coin.Position).Magnitude
                    if d < distN then distN = d; nearest = coin end
                end
            end
        end
        TargetCoin = nearest
    end
    if not TargetCoin then
        if murdererHRP then
            local flee = (hrp.Position - murdererHRP.Position).Unit
            hrp.CFrame = hrp.CFrame:Lerp(CFrame.new(hrp.Position + flee * 25), 0.2)
        end
        return
    end

    local coinPos = TargetCoin.Position
    local dist = (hrp.Position - coinPos).Magnitude
    if dist <= 1.2 then TargetCoin = nil; ResumeTime = tick() + 1; return end

    local targetY = math.min(coinPos.Y, hrp.Position.Y + 3.5)
    local targetPos = Vector3.new(coinPos.X, targetY, coinPos.Z)
    local step = math.min(dist, CONFIG.FarmSpeed * deltaTime * 60)
    hrp.CFrame = CFrame.new(hrp.Position:Lerp(targetPos, step / dist))
end))

print("[PulseMM2 Mobile] ✅ โหลดสำเร็จ! เอา Auto Fling Sheriff ออกแล้ว → เก็บเหรียญได้ปกติ")
