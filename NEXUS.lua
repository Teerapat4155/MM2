--[[
    ============================================================
    ⚡ NEXUS AIMBOT PRO — Universal Mobile (Delta Android)
    ✅ Aimbot: เช็คเลือด → ล็อคหัว + เช็คกำแพง (ในฟังก์ชันเดียว)
    ✅ ESP: กล่องสี่เหลี่ยม + ระยะทาง (m) ด้วย Drawing API
    ✅ FOV: วงกลมปรับได้ = ระยะล็อค Aimbot
    ✅ UI ระดับพรีเมียม + Icon ลอย (ลาก/แตะแยกกัน) + X ปิดทุกอย่าง
    ============================================================
]]

if _G.NexusAimbot_Unload then pcall(function() _G.NexusAimbot_Unload() end) end

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local CoreGui          = game:GetService("CoreGui")
local LocalPlayer      = Players.LocalPlayer
local Camera           = workspace.CurrentCamera

local Settings = {
    Aimbot       = false,
    FOV          = 180,
    Smoothness   = 4,
    WallCheck    = true,   -- เช็คกำแพง (ในฟังก์ชัน Aimbot เดียว)
    ESP          = false,
    TeamCheck    = false,
}

local Connections = {}
local Drawings    = {}   -- เก็บ Drawing object ทั้งหมดเพื่อ cleanup
local ESPData     = {}   -- [player] = {box, text}
local IsAlive     = true

local function addConn(c) table.insert(Connections, c); return c end
local function getHRP(c) return c and c:FindFirstChild("HumanoidRootPart") end
local function getHum(c) return c and c:FindFirstChildOfClass("Humanoid") end

-- ===== UNLOAD (ปุ่ม X: ปิดทุกอย่างเลย) =====
local function Unload()
    IsAlive = false
    for k in pairs(Settings) do Settings[k] = false end
    for _, conn in ipairs(Connections) do pcall(function() conn:Disconnect() end) end
    table.clear(Connections)
    for _, d in pairs(Drawings) do pcall(function() if d and d.Remove then d:Remove() end end) end
    table.clear(Drawings)
    for _, data in pairs(ESPData) do
        pcall(function() if data.box then data.box:Remove() end end)
        pcall(function() if data.text then data.text:Remove() end end)
    end
    table.clear(ESPData)
    pcall(function() if _G.Nexus_GUI then _G.Nexus_GUI:Destroy() _G.Nexus_GUI = nil end end)
    _G.NexusAimbot_Unload = nil
    print("[Nexus Aimbot] ✅ ปิดทุกอย่างเรียบร้อย")
end
_G.NexusAimbot_Unload = Unload

-- ===== UI PARENT (fallback) =====
local parentUI = nil
pcall(function() parentUI = gethui and gethui() end)
if not parentUI then pcall(function() parentUI = CoreGui end) end
if not parentUI then parentUI = LocalPlayer:WaitForChild("PlayerGui") end

local SG = Instance.new("ScreenGui")
SG.Name = "Nexus_GUI"; SG.ResetOnSpawn = false; SG.DisplayOrder = 999; SG.Parent = parentUI
_G.Nexus_GUI = SG

-- สีธีมพรีเมียม
local ACCENT    = Color3.fromRGB(0, 255, 140)
local ACCENT_D  = Color3.fromRGB(0, 180, 100)
local BG_DARK   = Color3.fromRGB(15, 15, 22)
local BG_PANEL  = Color3.fromRGB(24, 24, 34)
local BG_BTN    = Color3.fromRGB(35, 35, 50)
local TEXT_W    = Color3.fromRGB(235, 235, 245)
local TEXT_GRAY = Color3.fromRGB(140, 140, 160)

-- ===== FOV CIRCLE (Drawing) =====
local FOVCircle = Drawing.new("Circle")
FOVCircle.Visible = false
FOVCircle.Filled = false
FOVCircle.Thickness = 1.5
FOVCircle.Color = ACCENT
FOVCircle.Transparency = 0.9
FOVCircle.Radius = Settings.FOV
FOVCircle.NumSides = 64
table.insert(Drawings, FOVCircle)

-- ===== ICON ลอย (ขนาดพอดี ไม่ใหญ่ไม่เล็ก 48px) =====
local Icon = Instance.new("TextButton")
Icon.Size = UDim2.new(0, 48, 0, 48)
Icon.Position = UDim2.new(0, 15, 0.4, 0)
Icon.BackgroundColor3 = BG_PANEL
Icon.Text = "N"
Icon.Font = Enum.Font.GothamBold
Icon.TextSize = 20
Icon.TextColor3 = ACCENT
Icon.AutoButtonColor = false
Icon.Parent = SG
Instance.new("UICorner", Icon).CornerRadius = UDim.new(1, 0)
local icoStroke = Instance.new("UIStroke", Icon); icoStroke.Color = ACCENT; icoStroke.Thickness = 2

-- ลาก/แตะ Icon แยกกันชัดเจน
local iDrag, iStart, iPos, iMoved = false, nil, nil, false
addConn(Icon.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
        iDrag = true; iMoved = false; iStart = i.Position; iPos = Icon.Position
    end
end))
addConn(UserInputService.InputChanged:Connect(function(i)
    if iDrag and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
        local d = i.Position - iStart
        if d.Magnitude > 5 then iMoved = true; Icon.Position = UDim2.new(iPos.X.Scale, iPos.X.Offset + d.X, iPos.Y.Scale, iPos.Y.Offset + d.Y) end
    end
end))

-- ===== MAIN WINDOW =====
local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, 300, 0, 360)
Main.Position = UDim2.new(0.5, -150, 0.5, -180)
Main.BackgroundColor3 = BG_DARK
Main.Visible = false
Main.Parent = SG
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 14)
local mStroke = Instance.new("UIStroke", Main); mStroke.Color = ACCENT_D; mStroke.Thickness = 1.5

-- Title bar
local TB = Instance.new("Frame")
TB.Size = UDim2.new(1, 0, 0, 44); TB.BackgroundColor3 = BG_PANEL; TB.Parent = Main
Instance.new("UICorner", TB).CornerRadius = UDim.new(0, 14)
local tbCov = Instance.new("Frame"); tbCov.Size = UDim2.new(1,0,0.5,0); tbCov.Position=UDim2.new(0,0,0.5,0); tbCov.BackgroundColor3=BG_PANEL; tbCov.BorderSizePixel=0; tbCov.Parent=TB

local Ttl = Instance.new("TextLabel")
Ttl.Size = UDim2.new(1, -80, 1, 0); Ttl.Position = UDim2.new(0, 14, 0, 0)
Ttl.BackgroundTransparency = 1; Ttl.Text = "⚡ NEXUS AIMBOT PRO"
Ttl.Font = Enum.Font.GothamBold; Ttl.TextSize = 14; Ttl.TextColor3 = ACCENT
Ttl.TextXAlignment = Enum.TextXAlignment.Left; Ttl.Parent = TB
local Sub = Instance.new("TextLabel")
Sub.Size = UDim2.new(1, -80, 0, 14); Sub.Position = UDim2.new(0, 14, 0, 24)
Sub.BackgroundTransparency = 1; Sub.Text = "Universal · Mobile Optimized"
Sub.Font = Enum.Font.Gotham; Sub.TextSize = 10; Sub.TextColor3 = TEXT_GRAY
Sub.TextXAlignment = Enum.TextXAlignment.Left; Sub.Parent = TB

-- ปุ่ม X (ปิดทุกอย่าง)
local XBtn = Instance.new("TextButton")
XBtn.Size = UDim2.new(0, 30, 0, 30); XBtn.Position = UDim2.new(1, -38, 0, 7)
XBtn.BackgroundColor3 = Color3.fromRGB(210, 50, 60); XBtn.Text = "✕"
XBtn.Font = Enum.Font.GothamBold; XBtn.TextSize = 14; XBtn.TextColor3 = Color3.new(1,1,1)
XBtn.AutoButtonColor = false; XBtn.Parent = TB
Instance.new("UICorner", XBtn).CornerRadius = UDim.new(0, 8)
addConn(XBtn.MouseButton1Click:Connect(function() Unload() end))
addConn(XBtn.MouseEnter:Connect(function() TweenService:Create(XBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(255,70,80)}):Play() end))
addConn(XBtn.MouseLeave:Connect(function() TweenService:Create(XBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(210,50,60)}):Play() end))

-- ลาก Main ด้วย TitleBar
local mDrag, mStart, mPos = false, nil, nil
addConn(TB.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then mDrag=true; mStart=i.Position; mPos=Main.Position end end))
addConn(UserInputService.InputChanged:Connect(function(i) if mDrag and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then local d=i.Position-mStart; Main.Position=UDim2.new(mPos.X.Scale,mPos.X.Offset+d.X,mPos.Y.Scale,mPos.Y.Offset+d.Y) end end))
addConn(TB.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then mDrag=false end end))

-- แตะ Icon เปิด/ปิด Main (เฉพาะตอนไม่ได้ลาก)
addConn(Icon.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
        if iDrag and not iMoved then Main.Visible = not Main.Visible end
        iDrag = false
    end
end))

-- Content
local Scroll = Instance.new("ScrollingFrame")
Scroll.Size = UDim2.new(1, -16, 1, -54); Scroll.Position = UDim2.new(0, 8, 0, 50)
Scroll.BackgroundTransparency = 1; Scroll.CanvasSize = UDim2.new(0,0,0,420)
Scroll.ScrollBarThickness = 3; Scroll.ScrollBarImageColor3 = ACCENT_D; Scroll.Parent = Main
local L = Instance.new("UIListLayout"); L.Padding = UDim.new(0, 7); L.SortOrder = Enum.SortOrder.LayoutOrder; L.Parent = Scroll
Instance.new("UIPadding", Scroll).PaddingBottom = UDim.new(0, 10)

local yIdx = 0
local function section(text)
    yIdx = yIdx + 1
    local l = Instance.new("TextLabel"); l.Size = UDim2.new(1,-6,0,20); l.BackgroundTransparency = 1
    l.Text = "— " .. text .. " —"; l.Font = Enum.Font.GothamBold; l.TextSize = 11; l.TextColor3 = ACCENT
    l.TextXAlignment = Enum.TextXAlignment.Left; l.LayoutOrder = yIdx; l.Parent = Scroll
end

local function toggle(name, stateKey, color)
    yIdx = yIdx + 1
    local row = Instance.new("Frame"); row.Size = UDim2.new(1,-4,0,38); row.BackgroundColor3 = BG_BTN
    row.LayoutOrder = yIdx; row.Parent = Scroll; Instance.new("UICorner", row).CornerRadius = UDim.new(0,8)
    local lbl = Instance.new("TextLabel"); lbl.Size = UDim2.new(1,-60,1,0); lbl.Position = UDim2.new(0,12,0,0)
    lbl.BackgroundTransparency = 1; lbl.Text = name; lbl.Font = Enum.Font.GothamSemibold; lbl.TextSize = 12
    lbl.TextColor3 = TEXT_W; lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Parent = row
    local btn = Instance.new("TextButton"); btn.Size = UDim2.new(0,44,0,22); btn.Position = UDim2.new(1,-50,0.5,-11)
    btn.BackgroundColor3 = Settings[stateKey] and (color or ACCENT) or Color3.fromRGB(60,60,80)
    btn.Text = ""; btn.AutoButtonColor = false; btn.Parent = row; Instance.new("UICorner", btn).CornerRadius = UDim.new(1,0)
    local dot = Instance.new("Frame"); dot.Size = UDim2.new(0,16,0,16)
    dot.Position = Settings[stateKey] and UDim2.new(1,-19,0.5,-8) or UDim2.new(0,3,0.5,-8)
    dot.BackgroundColor3 = Color3.new(1,1,1); dot.Parent = row; Instance.new("UICorner", dot).CornerRadius = UDim.new(1,0)
    btn.MouseButton1Click:Connect(function()
        Settings[stateKey] = not Settings[stateKey]
        TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Settings[stateKey] and (color or ACCENT) or Color3.fromRGB(60,60,80)}):Play()
        TweenService:Create(dot, TweenInfo.new(0.2), {Position = Settings[stateKey] and UDim2.new(1,-19,0.5,-8) or UDim2.new(0,3,0.5,-8)}):Play()
    end)
end

local function slider(name, stateKey, minv, maxv, suffix)
    yIdx = yIdx + 1
    local row = Instance.new("Frame"); row.Size = UDim2.new(1,-4,0,52); row.BackgroundColor3 = BG_BTN
    row.LayoutOrder = yIdx; row.Parent = Scroll; Instance.new("UICorner", row).CornerRadius = UDim.new(0,8)
    local lbl = Instance.new("TextLabel"); lbl.Size = UDim2.new(1,-70,0,18); lbl.Position = UDim2.new(0,12,0,6)
    lbl.BackgroundTransparency = 1; lbl.Text = name; lbl.Font = Enum.Font.GothamSemibold; lbl.TextSize = 12
    lbl.TextColor3 = TEXT_W; lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Parent = row
    local vl = Instance.new("TextLabel"); vl.Size = UDim2.new(0,55,0,18); vl.Position = UDim2.new(1,-62,0,6)
    vl.BackgroundTransparency = 1; vl.Text = tostring(Settings[stateKey])..(suffix or ""); vl.Font = Enum.Font.GothamBold; vl.TextSize = 12
    vl.TextColor3 = ACCENT; vl.TextXAlignment = Enum.TextXAlignment.Right; vl.Parent = row
    local track = Instance.new("Frame"); track.Size = UDim2.new(1,-24,0,5); track.Position = UDim2.new(0,12,0,34)
    track.BackgroundColor3 = Color3.fromRGB(50,50,70); track.Parent = row; Instance.new("UICorner", track).CornerRadius = UDim.new(1,0)
    local fill = Instance.new("Frame"); fill.Size = UDim2.new(0,0,1,0); fill.BackgroundColor3 = ACCENT; fill.Parent = track
    local knob = Instance.new("TextButton"); knob.Size = UDim2.new(0,16,0,16); knob.Position = UDim2.new(0,-5,0.5,-8)
    knob.BackgroundColor3 = Color3.new(1,1,1); knob.Text = ""; knob.Parent = track; Instance.new("UICorner", knob).CornerRadius = UDim.new(1,0)
    local dragging = false
    local function set(x)
        local p = math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        local v = math.floor(minv + (maxv - minv) * p + 0.5); Settings[stateKey] = v
        vl.Text = tostring(v)..(suffix or ""); fill.Size = UDim2.new(p,0,1,0); knob.Position = UDim2.new(p,-8,0.5,-8)
        if stateKey == "FOV" then FOVCircle.Radius = v end
    end
    addConn(knob.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then dragging=true end end))
    addConn(track.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then dragging=true; set(i.Position.X) end end))
    addConn(UserInputService.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then dragging=false end end))
    addConn(UserInputService.InputChanged:Connect(function(i) if dragging and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then set(i.Position.X) end end))
    local p0 = (Settings[stateKey]-minv)/(maxv-minv); fill.Size = UDim2.new(p0,0,1,0); knob.Position = UDim2.new(p0,-8,0.5,-8)
end

-- สร้าง UI ควบคุม
section("🎯 AIMBOT")
toggle("เปิด Aimbot (ล็อคหัว)", "Aimbot", ACCENT)
toggle("เช็คกำแพง (Wall Check)", "WallCheck", Color3.fromRGB(80,160,255))
slider("FOV (วงล็อค)", "FOV", 50, 600, "")
slider("ความนุ่ม (Smooth)", "Smoothness", 1, 20, "")
section("👁️ ESP")
toggle("เปิด ESP (กล่อง+ระยะ)", "ESP", Color3.fromRGB(200,100,255))
section("⚙️ MISC")
toggle("เช็คทีม (Team Check)", "TeamCheck", Color3.fromRGB(255,180,60))

-- ============================================================
-- AIMBOT CORE — ฟังก์ชันเดียว: เช็คเลือด → ล็อคหัว + เช็คกำแพง
-- ============================================================
local function GetTarget()
    local closest = nil
    local shortest = math.huge
    local cam = Camera
    local vpSize = cam.ViewportSize
    local center = Vector2.new(vpSize.X/2, vpSize.Y/2)
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local hum = getHum(p.Character)
            local hrp = getHRP(p.Character)
            local head = p.Character:FindFirstChild("Head")
            -- ✅ เช็คเลือด: ยังมีเลือด (มี Humanoid และ Health>0) ถึงจะล็อค
            if hum and hum.Health > 0 and hrp and head then
                if Settings.TeamCheck and p.Team == LocalPlayer.Team then continue end
                local screenPos, onScreen = cam:WorldToViewportPoint(head.Position)
                if onScreen then
                    local dist2D = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
                    if dist2D <= Settings.FOV and dist2D < shortest then
                        -- ✅ เช็คกำแพง (ในฟังก์ชันเดียวกัน): ถ้าเปิด WallCheck จะไม่ล็อคนอกกำแพง
                        local visible = true
                        if Settings.WallCheck then
                            local rp = RaycastParams.new()
                            rp.FilterDescendantsInstances = {LocalPlayer.Character, cam}
                            rp.FilterType = Enum.RaycastFilterType.Exclude
                            local hit = workspace:Raycast(cam.CFrame.Position, (head.Position - cam.CFrame.Position), rp)
                            if hit and not hit.Instance:IsDescendantOf(p.Character) then
                                visible = false
                            end
                        end
                        if visible then
                            shortest = dist2D
                            closest = p
                        end
                    end
                end
            end
        end
    end
    return closest
end

-- ============================================================
-- ESP — กล่องสี่เหลี่ยม + ระยะทาง (m) ด้วย Drawing API
-- ============================================================
local function SetupESP(p)
    local box = Drawing.new("Square")
    box.Visible = false; box.Color = ACCENT; box.Thickness = 1.2; box.Filled = false
    local text = Drawing.new("Text")
    text.Visible = false; text.Color = Color3.fromRGB(255,255,255); text.Size = 13
    text.Center = true; text.Outline = true; text.OutlineColor = Color3.fromRGB(0,0,0)
    ESPData[p] = {box = box, text = text}
    local conn = RunService.RenderStepped:Connect(function()
        if not IsAlive then return end
        if not Settings.ESP or not p.Character or not getHRP(p.Character) then
            box.Visible = false; text.Visible = false; return
        end
        local char = p.Character
        local hrp = char.HumanoidRootPart
        local head = char:FindFirstChild("Head") or hrp
        local rootPos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
        if onScreen then
            local topPos = Camera:WorldToViewportPoint(head.Position + Vector3.new(0,0.5,0))
            local botPos = Camera:WorldToViewportPoint(hrp.Position - Vector3.new(0,3,0))
            local h = math.abs(topPos.Y - botPos.Y)
            local w = h / 2
            box.Size = Vector2.new(w, h)
            box.Position = Vector2.new(rootPos.X - w/2, topPos.Y)
            box.Visible = true
            local dist = (Camera.CFrame.Position - hrp.Position).Magnitude
            text.Text = p.Name .. "  " .. math.floor(dist) .. "m"
            text.Position = Vector2.new(rootPos.X, botPos.Y + 4)
            text.Visible = true
        else
            box.Visible = false; text.Visible = false
        end
    end)
    table.insert(Connections, conn)
end
for _, p in ipairs(Players:GetPlayers()) do if p ~= LocalPlayer then SetupESP(p) end end
addConn(Players.PlayerAdded:Connect(SetupESP))
addConn(Players.PlayerRemoving:Connect(function(p)
    if ESPData[p] then
        pcall(function() ESPData[p].box:Remove() end)
        pcall(function() ESPData[p].text:Remove() end)
        ESPData[p] = nil
    end
end))

-- ============================================================
-- MAIN LOOP — Aimbot + FOV Circle
-- ============================================================
addConn(RunService.RenderStepped:Connect(function()
    if not IsAlive then return end
    local vp = Camera.ViewportSize
    FOVCircle.Position = Vector2.new(vp.X/2, vp.Y/2)
    FOVCircle.Radius = Settings.FOV
    FOVCircle.Visible = Settings.Aimbot
    if not Settings.Aimbot then return end
    local target = GetTarget()
    if target and target.Character then
        local head = target.Character:FindFirstChild("Head")
        if head then
            Camera.CFrame = Camera.CFrame:Lerp(
                CFrame.new(Camera.CFrame.Position, head.Position),
                1 / math.max(Settings.Smoothness, 1)
            )
        end
    end
end))

print("[Nexus Aimbot Pro] ✅ โหลดสำเร็จ! แตะไอคอน N เพื่อเปิดเมนู")
