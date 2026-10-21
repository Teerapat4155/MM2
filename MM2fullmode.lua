--[[
    ============================================================
    MM2 PULSE HUB FULL CONFIG → STANDALONE SCRIPT (MOBILE 2340x1080)
    ✅ ครบทุกฟังก์ชันตาม config (PulseHubMM2_config + PulseFarmMM2_config)
    ✅ 1 ฟังก์ชัน = 1 สวิช (ไม่รวมกัน) แยกเป็นแท็บชัดเจน
    ✅ UI ขนาดเหมาะกับจอ 2340×1080 (Delta Android)
    ============================================================
]]

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local Workspace        = game:GetService("Workspace")
local ReplicatedStorage= game:GetService("ReplicatedStorage")
local VirtualUser      = game:GetService("VirtualUser")
local CoreGui          = game:GetService("CoreGui")
local LocalPlayer      = Players.LocalPlayer

if getgenv().PulseFull_Cleanup then pcall(function() getgenv().PulseFull_Cleanup() end) end

-- ===== STATE (ทุกฟังก์ชันมีสวิชตัวเอง ตามค่า default จาก config) =====
local S = {
    -- FARM (Auto Farm)
    AutoFarm          = true,   -- Auto Farm/-/Auto Farm = true
    FarmMethodFast    = true,   -- Farm Method = Fast
    AvoidMurderer     = true,   -- Avoid Murderer = true
    RespawnOnFull     = true,   -- Auto-Respawn on full bag = true
    PickUpGun         = false,  -- Pick Up Gun = false (PulseFarm pickGun=false)
    ShootOnFull       = true,   -- Shoot Murderer on full bag = true
    AutoOpenBoxes     = true,   -- Boxes auto open
    RejoinOnFull      = true,   -- farm.rejoin = true
    -- COMBAT
    KillAura          = true,   -- killAura = true
    AutoFlingSheriff  = false,  -- autoFlingSheriff (default ปิด เพราะรบกวนฟาร์ม)
    AutoShootMurder   = true,   -- Auto Shoot Murder = true
    AutoPickupGun     = false,  -- Auto Pickup Gun = false
    SilentAim         = false,  -- Silent Aim = false
    Wallbang          = true,   -- Wallbang = true
    AutoThrowKnife    = false,  -- Auto Throw = false
    AntiFling         = false,  -- antiFling = false
    -- ESP
    ESP_Enable        = true,   -- Enable Role ESP = true
    ESP_Murderer      = true,
    ESP_Sheriff       = true,
    ESP_Innocent      = true,
    ESP_Hero          = true,
    ESP_Box           = false,  -- Player Box = false
    ESP_Tracers       = false,  -- Tracers = false
    ESP_HealthBar     = false,  -- Health Bar = false
    ESP_Name          = false,  -- Player Name = false
    ESP_Distance      = false,  -- Distance = false
    -- MOVEMENT
    WalkSpeed         = false,  -- default 16
    JumpPower         = false,
    Fly               = false,  -- fly.on = false
    NoClip            = true,   -- No Clip = true
    Bhop              = false,  -- Bhop = false
    Spin              = false,  -- spin.on = false
    Invisible         = false,  -- invis.on = false
    InfJump           = false,  -- infJump = false
    -- SERVER / MISC
    AntiAFK           = true,   -- Anti AFK = true
    AutoVoteMap       = true,   -- vote.auto = true
    AutoDupe          = true,   -- Auto Dupe = true
    XRay              = false,  -- xray.on = false
}
local Sliders = {
    FarmSpeed    = 22,   -- farm.speed = 22
    AuraRange    = 250,  -- Max Distance = 250
    WalkSpeedVal = 22,
    JumpPowerVal = 50,
    FlySpeed     = 60,   -- fly.speed = 60
    BoxDelay     = 1,    -- Open Delay = 1
}

local Connections = {}
local ESPHighlights = {}
local ESPTracers = {}
local OriginalCanCollide = {}
local TargetCoin = nil
local ResumeTime = 0
local Flying = false

local function addConn(c) table.insert(Connections, c); return c end
local function getHRP(c) return c and c:FindFirstChild("HumanoidRootPart") end
local function getHum(c) return c and c:FindFirstChildOfClass("Humanoid") end
local function alive(p) local c=p.Character local h=getHum(c) return c and h and h.Health>0 end

getgenv().PulseFull_Cleanup = function()
    for k in pairs(S) do S[k] = false end
    local c = LocalPlayer.Character
    if c then
        local h = getHum(c)
        if h then h.WalkSpeed=16; h.JumpPower=50 end
        for part, orig in pairs(OriginalCanCollide) do
            if part and part.Parent then pcall(function() part.CanCollide=orig end) end
        end
        for _, d in ipairs(c:GetDescendants()) do
            if d:IsA("BasePart") then pcall(function() d.LocalTransparencyModifier=0 end) end
        end
    end
    for _, e in pairs(ESPHighlights) do pcall(function() if e then e:Destroy() end end) end
    for _, t in pairs(ESPTracers) do pcall(function() if t then t:Destroy() end end) end
    table.clear(ESPHighlights); table.clear(ESPTracers)
    for _, conn in ipairs(Connections) do pcall(function() conn:Disconnect() end) end
    table.clear(Connections)
    pcall(function() if _G.PulseFull_GUI then _G.PulseFull_GUI:Destroy() _G.PulseFull_GUI=nil end end)
end

-- ===== ROLE DETECTION =====
local function checkContainer(container)
    if not container then return nil end
    local hasTool = false
    for _, item in ipairs(container:GetChildren()) do
        if item:IsA("Tool") then
            local nm = string.lower(item.Name)
            if nm:find("gun") or nm:find("revolver") or nm:find("sheriff") then return "Sheriff" end
            if nm:find("knife") or nm:find("murderer") or nm:find("blade") or nm:find("scythe") or nm:find("dagger") then return "Murderer" end
            if not (nm:find("radio") or nm:find("teddy") or nm:find("icecream") or nm:find("toy") or nm:find("balloon")) then hasTool = true end
        end
    end
    if hasTool then return "Murderer" end
    return nil
end
local function getRole(p)
    if not p or not p.Character then return "Innocent" end
    local r = checkContainer(p:FindFirstChildOfClass("Backpack"))
    if r then return r end
    return checkContainer(p.Character) or "Innocent"
end

-- ===== UI (ขนาด 2340×1080 landscape) =====
local parentUI = nil
pcall(function() parentUI = gethui and gethui() end)
if not parentUI then pcall(function() parentUI = CoreGui end) end
if not parentUI then parentUI = LocalPlayer:WaitForChild("PlayerGui") end

local SG = Instance.new("ScreenGui")
SG.Name = "PulseFull_GUI"; SG.ResetOnSpawn = false; SG.DisplayOrder = 999; SG.Parent = parentUI
_G.PulseFull_GUI = SG

local cam = workspace.CurrentCamera
local vw, vh = cam.ViewportSize.X, cam.ViewportSize.Y
-- จอ 2340×1080 landscape: เมนูกว้าง ~460 สูง ~720
local MW = math.min(460, vw*0.42); local MH = math.min(720, vh-40)

local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, MW, 0, MH); Main.Position = UDim2.new(0.5, -MW/2, 0.5, -MH/2)
Main.BackgroundColor3 = Color3.fromRGB(16,16,24); Main.Visible = true; Main.Parent = SG
Instance.new("UICorner", Main).CornerRadius = UDim.new(0,14)
local ms = Instance.new("UIStroke", Main); ms.Color = Color3.fromRGB(255,80,80); ms.Thickness = 1.5

-- Title
local TB = Instance.new("Frame"); TB.Size=UDim2.new(1,0,0,46); TB.BackgroundColor3=Color3.fromRGB(26,26,40); TB.Parent=Main
Instance.new("UICorner", TB).CornerRadius = UDim.new(0,14)
local cov = Instance.new("Frame"); cov.Size=UDim2.new(1,0,0.5,0); cov.Position=UDim2.new(0,0,0.5,0); cov.BackgroundColor3=Color3.fromRGB(26,26,40); cov.BorderSizePixel=0; cov.Parent=TB
local Ttl = Instance.new("TextLabel"); Ttl.Size=UDim2.new(1,-50,1,0); Ttl.Position=UDim2.new(0,14,0,0)
Ttl.BackgroundTransparency=1; Ttl.Text="⚡ PULSE MM2 — FULL CONFIG"; Ttl.Font=Enum.Font.GothamBold; Ttl.TextSize=16
Ttl.TextColor3=Color3.fromRGB(255,80,80); Ttl.TextXAlignment=Enum.TextXAlignment.Left; Ttl.Parent=TB
local XBtn = Instance.new("TextButton"); XBtn.Size=UDim2.new(0,34,0,34); XBtn.Position=UDim2.new(1,-40,0,6)
XBtn.BackgroundColor3=Color3.fromRGB(220,50,50); XBtn.Text="X"; XBtn.Font=Enum.Font.GothamBold; XBtn.TextSize=15
XBtn.TextColor3=Color3.new(1,1,1); XBtn.Parent=TB; Instance.new("UICorner",XBtn).CornerRadius=UDim.new(0,8)
addConn(XBtn.MouseButton1Click:Connect(function() getgenv().PulseFull_Cleanup() end))

-- ลากเมนู
local mD,mDS,mSP=false,nil,nil
addConn(TB.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then mD=true;mDS=i.Position;mSP=Main.Position end end))
addConn(UserInputService.InputChanged:Connect(function(i) if mD and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then local d=i.Position-mDS; Main.Position=UDim2.new(mSP.X.Scale,mSP.X.Offset+d.X,mSP.Y.Scale,mSP.Y.Offset+d.Y) end end))
addConn(TB.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then mD=false end end))

-- แท็บ
local Tabs = {"Farm","Combat","ESP","Movement","Misc"}
local TabBtns = {}
local TabFrames = {}
local TabBar = Instance.new("Frame"); TabBar.Size=UDim2.new(1,0,0,40); TabBar.Position=UDim2.new(0,0,0,46); TabBar.BackgroundColor3=Color3.fromRGB(20,20,30); TabBar.Parent=Main
local TabLayout = Instance.new("UIListLayout"); TabLayout.FillDirection=Enum.FillDirection.Horizontal; TabLayout.Parent=TabBar
for i, name in ipairs(Tabs) do
    local b = Instance.new("TextButton"); b.Size=UDim2.new(1/#Tabs, -2, 1, -4); b.Position=UDim2.new(0,0,0,2)
    b.BackgroundColor3 = i==1 and Color3.fromRGB(255,80,80) or Color3.fromRGB(35,35,50)
    b.Text=name; b.Font=Enum.Font.GothamBold; b.TextSize=13; b.TextColor3=Color3.new(1,1,1); b.Parent=TabBar
    Instance.new("UICorner", b).CornerRadius=UDim.new(0,6)
    local f = Instance.new("ScrollingFrame"); f.Size=UDim2.new(1,-12,1,-98); f.Position=UDim2.new(0,6,0,92)
    f.BackgroundTransparency=1; f.CanvasSize=UDim2.new(0,0,0,800); f.ScrollBarThickness=4; f.Visible=(i==1); f.Parent=Main
    local L=Instance.new("UIListLayout"); L.Padding=UDim.new(0,6); L.SortOrder=Enum.SortOrder.LayoutOrder; L.Parent=f
    Instance.new("UIPadding", f).PaddingBottom=UDim.new(0,10)
    TabFrames[name]=f; TabBtns[name]=b
    b.MouseButton1Click:Connect(function()
        for tn, tf in pairs(TabFrames) do tf.Visible=(tn==name) end
        for tn, btn in pairs(TabBtns) do btn.BackgroundColor3=(tn==name) and Color3.fromRGB(255,80,80) or Color3.fromRGB(35,35,50) end
    end)
end

local yIdx = {Farm=0,Combat=0,ESP=0,Movement=0,Misc=0}
local function section(tab, text)
    yIdx[tab]=yIdx[tab]+1
    local l=Instance.new("TextLabel"); l.Size=UDim2.new(1,-6,0,22); l.BackgroundTransparency=1
    l.Text="— "..text.." —"; l.Font=Enum.Font.GothamBold; l.TextSize=12; l.TextColor3=Color3.fromRGB(255,140,60)
    l.TextXAlignment=Enum.TextXAlignment.Left; l.LayoutOrder=yIdx[tab]; l.Parent=TabFrames[tab]
end
local function toggle(tab, name, stateKey, color)
    yIdx[tab]=yIdx[tab]+1
    local row=Instance.new("Frame"); row.Size=UDim2.new(1,-6,0,40); row.BackgroundColor3=Color3.fromRGB(28,28,42)
    row.LayoutOrder=yIdx[tab]; row.Parent=TabFrames[tab]; Instance.new("UICorner",row).CornerRadius=UDim.new(0,8)
    local lbl=Instance.new("TextLabel"); lbl.Size=UDim2.new(1,-65,1,0); lbl.Position=UDim2.new(0,12,0,0)
    lbl.BackgroundTransparency=1; lbl.Text=name; lbl.Font=Enum.Font.GothamSemibold; lbl.TextSize=12.5
    lbl.TextColor3=Color3.fromRGB(225,225,240); lbl.TextXAlignment=Enum.TextXAlignment.Left; lbl.Parent=row
    local btn=Instance.new("TextButton"); btn.Size=UDim2.new(0,50,0,26); btn.Position=UDim2.new(1,-56,0.5,-13)
    btn.BackgroundColor3 = S[stateKey] and (color or Color3.fromRGB(60,200,90)) or Color3.fromRGB(60,60,80)
    btn.Text=""; btn.AutoButtonColor=false; btn.Parent=row; Instance.new("UICorner",btn).CornerRadius=UDim.new(1,0)
    local dot=Instance.new("Frame"); dot.Size=UDim2.new(0,18,0,18)
    dot.Position = S[stateKey] and UDim2.new(1,-20,0.5,-9) or UDim2.new(0,4,0.5,-9)
    dot.BackgroundColor3=Color3.new(1,1,1); dot.Parent=row; Instance.new("UICorner",dot).CornerRadius=UDim.new(1,0)
    btn.MouseButton1Click:Connect(function()
        S[stateKey]=not S[stateKey]
        btn.BackgroundColor3 = S[stateKey] and (color or Color3.fromRGB(60,200,90)) or Color3.fromRGB(60,60,80)
        dot.Position = S[stateKey] and UDim2.new(1,-20,0.5,-9) or UDim2.new(0,4,0.5,-9)
    end)
end
local function slider(tab, name, stateKey, minv, maxv, suffix)
    yIdx[tab]=yIdx[tab]+1
    local row=Instance.new("Frame"); row.Size=UDim2.new(1,-6,0,52); row.BackgroundColor3=Color3.fromRGB(28,28,42)
    row.LayoutOrder=yIdx[tab]; row.Parent=TabFrames[tab]; Instance.new("UICorner",row).CornerRadius=UDim.new(0,8)
    local lbl=Instance.new("TextLabel"); lbl.Size=UDim2.new(1,-70,0,18); lbl.Position=UDim2.new(0,10,0,4)
    lbl.BackgroundTransparency=1; lbl.Text=name; lbl.Font=Enum.Font.GothamSemibold; lbl.TextSize=12
    lbl.TextColor3=Color3.fromRGB(225,225,240); lbl.TextXAlignment=Enum.TextXAlignment.Left; lbl.Parent=row
    local vl=Instance.new("TextLabel"); vl.Size=UDim2.new(0,60,0,18); vl.Position=UDim2.new(1,-65,0,4)
    vl.BackgroundTransparency=1; vl.Text=tostring(Sliders[stateKey])..(suffix or ""); vl.Font=Enum.Font.GothamBold; vl.TextSize=12
    vl.TextColor3=Color3.fromRGB(255,180,60); vl.TextXAlignment=Enum.TextXAlignment.Right; vl.Parent=row
    local track=Instance.new("Frame"); track.Size=UDim2.new(1,-20,0,6); track.Position=UDim2.new(0,10,0,34)
    track.BackgroundColor3=Color3.fromRGB(50,50,70); track.Parent=row; Instance.new("UICorner",track).CornerRadius=UDim.new(1,0)
    local fill=Instance.new("Frame"); fill.Size=UDim2.new(0,0,1,0); fill.BackgroundColor3=Color3.fromRGB(255,180,60); fill.Parent=track
    local knob=Instance.new("TextButton"); knob.Size=UDim2.new(0,16,0,16); knob.Position=UDim2.new(0,-4,0.5,-8)
    knob.BackgroundColor3=Color3.new(1,1,1); knob.Text=""; knob.Parent=track; Instance.new("UICorner",knob).CornerRadius=UDim.new(1,0)
    local dragging=false
    local function set(x)
        local p=math.clamp((x-track.AbsolutePosition.X)/track.AbsoluteSize.X,0,1)
        local v=math.floor(minv+(maxv-minv)*p+0.5); Sliders[stateKey]=v
        vl.Text=tostring(v)..(suffix or ""); fill.Size=UDim2.new(p,0,1,0); knob.Position=UDim2.new(p,-8,0.5,-8)
    end
    addConn(knob.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then dragging=true end end))
    addConn(track.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then dragging=true; set(i.Position.X) end end))
    addConn(UserInputService.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then dragging=false end end))
    addConn(UserInputService.InputChanged:Connect(function(i) if dragging and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then set(i.Position.X) end end))
    local p0=(Sliders[stateKey]-minv)/(maxv-minv); fill.Size=UDim2.new(p0,0,1,0); knob.Position=UDim2.new(p0,-8,0.5,-8)
end

-- ===== สร้างสวิชทุกฟังก์ชัน (1 ฟังก์ชัน 1 สวิช) =====
-- TAB FARM
section("Farm","Auto Coin Farm")
toggle("Farm","Auto Farm (เก็บเหรียญอัตโนมัติ)","AutoFarm",Color3.fromRGB(255,215,0))
toggle("Farm","หลบฆาตกร (Avoid Murderer)","AvoidMurderer",Color3.fromRGB(255,150,50))
toggle("Farm","รีสปอร์นตอนกระเป๋าเต็ม","RespawnOnFull",Color3.fromRGB(100,200,255))
toggle("Farm","รีจอยตอนกระเป๋าเต็ม (Rejoin)","RejoinOnFull",Color3.fromRGB(150,100,255))
toggle("Farm","หยิบปืนอัตโนมัติ (Pick Up Gun)","PickUpGun",Color3.fromRGB(80,180,255))
toggle("Farm","ยิงฆาตกรตอนกระเป๋าเต็ม (Shoot On Full)","ShootOnFull",Color3.fromRGB(255,80,80))
toggle("Farm","เปิดกล่องอัตโนมัติ (Auto Open Boxes)","AutoOpenBoxes",Color3.fromRGB(200,150,255))
section("Farm","ความเร็ว")
slider("Farm","ความเร็วเก็บเหรียญ (Farm Speed)","FarmSpeed",10,60,"")
slider("Farm","ดีเลย์เปิดกล่อง (Box Delay)","BoxDelay",1,10," วิ")

-- TAB COMBAT
section("Combat","ฆาตกร (Murderer)")
toggle("Combat","Kill Aura (ออร่าฆ่า 250ม.)","KillAura",Color3.fromRGB(255,80,80))
toggle("Combat","โยนมีดอัตโนมัติ (Auto Throw)","AutoThrowKnife",Color3.fromRGB(255,120,60))
section("Combat","นายอำเภอ (Sheriff)")
toggle("Combat","ยิงฆาตกรอัตโนมัติ (Auto Shoot)","AutoShootMurder",Color3.fromRGB(80,140,255))
toggle("Combat","หยิบปืนอัตโนมัติ (Auto Pickup Gun)","AutoPickupGun",Color3.fromRGB(80,180,255))
toggle("Combat","ซายเลนต์เอม (Silent Aim)","SilentAim",Color3.fromRGB(180,80,255))
toggle("Combat","ยิงทะลุกำแพง (Wallbang)","Wallbang",Color3.fromRGB(120,200,200))
toggle("Combat","เหวี่ยงนายอำเภอ (Auto Fling Sheriff)","AutoFlingSheriff",Color3.fromRGB(255,60,120))
toggle("Combat","ต้านการถูกเหวี่ยง (Anti Fling)","AntiFling",Color3.fromRGB(100,255,150))
section("Combat","ระยะ")
slider("Combat","ระยะ Kill Aura (Aura Range)","AuraRange",50,500," ม.")

-- TAB ESP
section("ESP","เปิด/ปิดทั่วไป")
toggle("ESP","เปิด ESP ทั้งหมด (Enable ESP)","ESP_Enable",Color3.fromRGB(160,80,255))
section("ESP","แสดงตามบทบาท (แต่ละบทบาทมีสวิชตัวเอง)")
toggle("ESP","แสดง ฆาตกร (Murderer)","ESP_Murderer",Color3.fromRGB(255,60,60))
toggle("ESP","แสดง นายอำเภอ (Sheriff)","ESP_Sheriff",Color3.fromRGB(60,120,255))
toggle("ESP","แสดง คนบริสุทธิ์ (Innocent)","ESP_Innocent",Color3.fromRGB(60,220,100))
toggle("ESP","แสดง ฮีโร่ (Hero)","ESP_Hero",Color3.fromRGB(255,215,0))
section("ESP","รูปแบบการแสดง (แต่ละแบบมีสวิชตัวเอง)")
toggle("ESP","กล่องล้อมตัว (Box ESP)","ESP_Box",Color3.fromRGB(255,150,60))
toggle("ESP","เส้นลากจากจอ (Tracers)","ESP_Tracers",Color3.fromRGB(100,200,255))
toggle("ESP","แสดงแถบเลือด (Health Bar)","ESP_HealthBar",Color3.fromRGB(80,255,120))
toggle("ESP","แสดงชื่อ (Player Name)","ESP_Name",Color3.fromRGB(220,220,255))
toggle("ESP","แสดงระยะห่าง (Distance)","ESP_Distance",Color3.fromRGB(255,200,100))

-- TAB MOVEMENT
section("Movement","ความเร็ว/การกระโดด")
toggle("Movement","เพิ่มความเร็ววิ่ง (Walk Speed)","WalkSpeed",Color3.fromRGB(80,220,200))
slider("Movement","ค่าความเร็ววิ่ง","WalkSpeedVal",16,200,"")
toggle("Movement","เพิ่มกำลังกระโดด (Jump Power)","JumpPower",Color3.fromRGB(120,255,150))
slider("Movement","ค่ากำลังกระโดด","JumpPowerVal",50,200,"")
section("Movement","ระบบเคลื่อนที่พิเศษ (แต่ละอย่างมีสวิชตัวเอง)")
toggle("Movement","บิน (Fly)","Fly",Color3.fromRGB(150,150,255))
slider("Movement","ความเร็วบิน (Fly Speed)","FlySpeed",20,120,"")
toggle("Movement","ทะลุกำแพง (No Clip)","NoClip",Color3.fromRGB(255,180,40))
toggle("Movement","กระโดดต่อเนื่อง (Bhop)","Bhop",Color3.fromRGB(100,200,255))
toggle("Movement","หมุนตัว (Spin)","Spin",Color3.fromRGB(255,100,200))
toggle("Movement","โปร่งแสง (Invisible)","Invisible",Color3.fromRGB(180,180,220))
toggle("Movement","กระโดดไม่จำกัด (Inf Jump)","InfJump",Color3.fromRGB(200,255,100))

-- TAB MISC
section("Misc","ระบบช่วยเหลือ")
toggle("Misc","ป้องกันหลุดเกม (Anti AFK)","AntiAFK",Color3.fromRGB(100,200,255))
toggle("Misc","โหวตแผนที่อัตโนมัติ (Auto Vote)","AutoVoteMap",Color3.fromRGB(255,200,80))
toggle("Misc","ดูปไอเทมอัตโนมัติ (Auto Dupe)","AutoDupe",Color3.fromRGB(200,100,255))
toggle("Misc","เอกซเรย์ (X-Ray)","XRay",Color3.fromRGB(100,255,200))

-- ปุ่มลอยซ่อนเมนู
local FloatBtn = Instance.new("TextButton")
FloatBtn.Size=UDim2.new(0,54,0,54); FloatBtn.Position=UDim2.new(0,10,0.5,-27)
FloatBtn.BackgroundColor3=Color3.fromRGB(28,28,42); FloatBtn.Text="P"; FloatBtn.Font=Enum.Font.GothamBold
FloatBtn.TextSize=20; FloatBtn.TextColor3=Color3.fromRGB(255,80,80); FloatBtn.AutoButtonColor=false; FloatBtn.Parent=SG
Instance.new("UICorner",FloatBtn).CornerRadius=UDim.new(1,0)
local fst=Instance.new("UIStroke",FloatBtn); fst.Color=Color3.fromRGB(255,80,80); fst.Thickness=2
local fD,fDS,fSP,fM=false,nil,nil,false
addConn(FloatBtn.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then fD=true;fM=false;fDS=i.Position;fSP=FloatBtn.Position end end))
addConn(UserInputService.InputChanged:Connect(function(i) if fD and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then local d=i.Position-fDS; if d.Magnitude>6 then fM=true; FloatBtn.Position=UDim2.new(fSP.X.Scale,fSP.X.Offset+d.X,fSP.Y.Scale,fSP.Y.Offset+d.Y) end end end))
addConn(FloatBtn.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then if fD and not fM then Main.Visible=not Main.Visible end; fD=false end end))

-- ==================== ฟังก์ชันการทำงานทุกตัว ====================

-- ANTI-AFK
addConn(LocalPlayer.Idled:Connect(function()
    if not S.AntiAFK then return end
    pcall(function() VirtualUser:CaptureController() VirtualUser:ClickButton2(Vector2.new(0,0)) end)
end))

-- SPEED / JUMP / BHOP / INF JUMP
addConn(RunService.Heartbeat:Connect(function()
    local h=getHum(LocalPlayer.Character); if not h then return end
    h.WalkSpeed = S.WalkSpeed and Sliders.WalkSpeedVal or 16
    h.JumpPower = S.JumpPower and Sliders.JumpPowerVal or 50
    if S.Bhop and h.MoveDirection.Magnitude>0 and h.FloorMaterial~=Enum.Material.Air then
        h:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end))
if S.InfJump then
    addConn(UserInputService.JumpRequest:Connect(function()
        local h=getHum(LocalPlayer.Character); if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
    end))
end

-- INVISIBLE
addConn(RunService.RenderStepped:Connect(function()
    local c=LocalPlayer.Character; if not c then return end
    for _, d in ipairs(c:GetDescendants()) do
        if d:IsA("BasePart") or d:IsA("Decal") then
            pcall(function() d.LocalTransparencyModifier = S.Invisible and 1 or 0 end)
        end
    end
end))

-- SPIN
addConn(RunService.RenderStepped:Connect(function()
    if not S.Spin then return end
    local hrp=getHRP(LocalPlayer.Character); if hrp then hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(15), 0) end
end))

-- FLY (WASD + Space/Shift บนมือถือใช้ปุ่ม jump)
local flyVel = nil
addConn(RunService.Heartbeat:Connect(function()
    if not S.Fly then Flying=false; return end
    local hrp=getHRP(LocalPlayer.Character); local h=getHum(LocalPlayer.Character)
    if not hrp or not h then return end
    Flying=true
    hrp.AssemblyLinearVelocity = Vector3.new(0,0,0)
    local cf = workspace.CurrentCamera.CFrame
    local dir = Vector3.new(0,0,0)
    if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + cf.LookVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - cf.LookVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir = dir - cf.RightVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir = dir + cf.RightVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0,1,0) end
    if dir.Magnitude>0 then hrp.CFrame = hrp.CFrame + (dir.Unit * Sliders.FlySpeed * 0.1) end
end))

-- NOCLIP + ANTI-FLING
addConn(RunService.Stepped:Connect(function()
    local c=LocalPlayer.Character; if not c then return end
    local hrp=getHRP(c); local safeY=hrp and hrp.Position.Y>-40
    for _, part in ipairs(c:GetDescendants()) do
        if part:IsA("BasePart") then
            if OriginalCanCollide[part]==nil then OriginalCanCollide[part]=part.CanCollide end
            if S.NoClip and safeY then part.CanCollide=false else part.CanCollide=OriginalCanCollide[part] end
            if S.AntiFling then pcall(function() part.AssemblyLinearVelocity=Vector3.new(0,0,0); part.RotVelocity=Vector3.new(0,0,0) end) end
        end
    end
end))

-- KILL AURA (ฆาตกร)
addConn(RunService.Heartbeat:Connect(function()
    if not S.KillAura then return end
    if getRole(LocalPlayer)~="Murderer" then return end
    local myChar=LocalPlayer.Character; local myHRP=getHRP(myChar); if not myHRP then return end
    local knife=myChar:FindFirstChildOfClass("Tool")
    if not knife then
        local bp=LocalPlayer:FindFirstChildOfClass("Backpack")
        if bp then for _, t in ipairs(bp:GetChildren()) do if t:IsA("Tool") then local h=getHum(myChar); if h then h:EquipTool(t) end; knife=t; break end end end
    end
    if not knife then return end
    for _, p in ipairs(Players:GetPlayers()) do
        if p~=LocalPlayer and alive(p) then
            local tHRP=getHRP(p.Character)
            if tHRP and (myHRP.Position-tHRP.Position).Magnitude<=Sliders.AuraRange then
                pcall(function()
                    tHRP.CFrame=myHRP.CFrame*CFrame.new(0,0,-2)
                    knife:Activate()
                    local handle=knife:FindFirstChild("Handle")
                    if handle and firetouchinterest then firetouchinterest(handle,tHRP,0); task.wait(); firetouchinterest(handle,tHRP,1) end
                end)
            end
        end
    end
end))

-- AUTO SHOOT MURDER (Sheriff / Silent Aim)
addConn(RunService.Heartbeat:Connect(function()
    if not (S.AutoShootMurder or S.SilentAim) then return end
    local myRole=getRole(LocalPlayer)
    if myRole~="Sheriff" and myRole~="Hero" then return end
    local myChar=LocalPlayer.Character; local myHRP=getHRP(myChar); if not myHRP then return end
    local gun=myChar:FindFirstChildOfClass("Tool")
    if not gun then
        local bp=LocalPlayer:FindFirstChildOfClass("Backpack")
        if bp then for _, t in ipairs(bp:GetChildren()) do if t:IsA("Tool") and string.find(string.lower(t.Name),"gun") then local h=getHum(myChar); if h then h:EquipTool(t) end; gun=t; break end end end
    end
    if not gun then return end
    local target, tdist = nil, math.huge
    for _, p in ipairs(Players:GetPlayers()) do
        if p~=LocalPlayer and alive(p) and getRole(p)=="Murderer" then
            local tHRP=getHRP(p.Character)
            if tHRP then local d=(myHRP.Position-tHRP.Position).Magnitude; if d<tdist then tdist=d; target=p end end
        end
    end
    if target then
        local tHRP=getHRP(target.Character)
        if tHRP then
            pcall(function()
                myHRP.CFrame=CFrame.new(myHRP.Position, tHRP.Position)
                for _, d in ipairs(gun:GetDescendants()) do
                    if d:IsA("RemoteEvent") or d:IsA("RemoteFunction") then
                        if d:IsA("RemoteEvent") then d:FireServer(tHRP.Position) else d:InvokeServer(tHRP.Position) end
                    end
                end
                gun:Activate()
            end)
        end
    end
end))

-- AUTO FLING SHERIFF (แยกสวิชตัวเอง default ปิด)
addConn(RunService.Heartbeat:Connect(function()
    if not S.AutoFlingSheriff then return end
    local myHRP=getHRP(LocalPlayer.Character); if not myHRP then return end
    for _, p in ipairs(Players:GetPlayers()) do
        if p~=LocalPlayer and alive(p) and getRole(p)=="Sheriff" then
            local tHRP=getHRP(p.Character)
            if tHRP then pcall(function() myHRP.CFrame=tHRP.CFrame*CFrame.new(0,0,2); myHRP.AssemblyLinearVelocity=myHRP.CFrame.LookVector*350+Vector3.new(0,100,0) end) end
        end
    end
end))

-- ESP (Highlight + Tracer)
local ESPColors = {
    Murderer = Color3.fromRGB(102,43,43),
    Sheriff  = Color3.fromRGB(38,52,74),
    Innocent = Color3.fromRGB(38,110,28),
    Hero     = Color3.fromRGB(126,110,55),
}
addConn(RunService.RenderStepped:Connect(function()
    if not S.ESP_Enable then
        for _, e in pairs(ESPHighlights) do pcall(function() if e then e.Enabled=false end end) end
        for _, t in pairs(ESPTracers) do pcall(function() if t then t.Enabled=false end end) end
        return
    end
    for _, p in ipairs(Players:GetPlayers()) do
        if p~=LocalPlayer and alive(p) and p.Character and getHRP(p.Character) then
            pcall(function()
                local char=p.Character; local role=getRole(p)
                local showRole = (role=="Murderer" and S.ESP_Murderer) or (role=="Sheriff" and S.ESP_Sheriff) or (role=="Innocent" and S.ESP_Innocent) or (role=="Hero" and S.ESP_Hero)
                local col=ESPColors[role] or Color3.fromRGB(150,150,150)
                local hl=char:FindFirstChild("PulseHL")
                if showRole and S.ESP_Box then
                    if not hl then hl=Instance.new("Highlight"); hl.Name="PulseHL"; hl.FillTransparency=0.6; hl.Parent=char; table.insert(ESPHighlights,hl) end
                    hl.Enabled=true; hl.FillColor=col; hl.OutlineColor=col
                elseif hl then hl.Enabled=false end
                -- Tracer
                local tr=ESPTracers[p]
                if showRole and S.ESP_Tracers then
                    if not tr then
                        tr=Instance.new("Beam"); tr.Width0=0.08; tr.Width1=0.08; tr.FaceCamera=true
                        local a0=Instance.new("Attachment", workspace.Terrain); local a1=Instance.new("Attachment", char:FindFirstChild("HumanoidRootPart"))
                        tr.Attachment0=a0; tr.Attachment1=a1; tr.Parent=workspace.Terrain; ESPTracers[p]=tr
                    end
                    tr.Enabled=true; tr.Color=ColorSequence.new(col)
                    local hrp=getHRP(LocalPlayer.Character); if hrp and tr.Attachment0 then tr.Attachment0.Position=hrp.Position end
                elseif tr then tr.Enabled=false end
            end)
        end
    end
end))

-- AUTO COIN FARM
addConn(RunService.Heartbeat:Connect(function(deltaTime)
    if not S.AutoFarm then TargetCoin=nil; return end
    if tick()<ResumeTime then return end
    local char=LocalPlayer.Character; if not char then return end
    local hrp=getHRP(char); local hum=getHum(char)
    if not hrp or not hum or hum.Health<=0 then return end
    hrp.AssemblyLinearVelocity=Vector3.new(0,0,0)

    local murdererHRP=nil
    if S.AvoidMurderer then
        for _, p in ipairs(Players:GetPlayers()) do
            if p~=LocalPlayer and alive(p) and getRole(p)=="Murderer" then
                local mHRP=getHRP(p.Character)
                if mHRP and (hrp.Position-mHRP.Position).Magnitude<=30 then murdererHRP=mHRP end
            end
        end
    end

    -- หลบมีดปา
    for _, obj in ipairs(Workspace:GetChildren()) do
        if obj:IsA("BasePart") and obj.Velocity and obj.Velocity.Magnitude>15 then
            local nm=obj.Name:lower()
            if nm:find("knife") or nm:find("blade") or nm:find("thrown") then
                local toObj=obj.Position-hrp.Position
                if toObj.Magnitude<18 then local dd=Vector3.new(-toObj.Z,0,toObj.X).Unit; hrp.CFrame=CFrame.new(hrp.Position+dd*6) end
            end
        end
    end

    if hrp.Position.Y<-35 then hrp.CFrame=CFrame.new(hrp.Position.X,10,hrp.Position.Z); TargetCoin=nil; return end

    local coinContainer=Workspace:FindFirstChild("CoinContainer") or Workspace:FindFirstChild("Normal")
    if not coinContainer then
        for _, v in ipairs(Workspace:GetChildren()) do
            if v:FindFirstChild("CoinContainer") or string.find(string.lower(v.Name),"coin") then coinContainer=v:FindFirstChild("CoinContainer") or v; break end
        end
    end
    if not coinContainer then return end

    if not TargetCoin or not TargetCoin.Parent then
        local nearest, distN=nil, math.huge
        for _, coin in ipairs(coinContainer:GetDescendants()) do
            if coin:IsA("BasePart") and coin.Position.Y>-30 then
                local skip=false
                if murdererHRP and (coin.Position-murdererHRP.Position).Magnitude<=20 then skip=true end
                if not skip then local d=(hrp.Position-coin.Position).Magnitude; if d<distN then distN=d; nearest=coin end end
            end
        end
        TargetCoin=nearest
    end
    if not TargetCoin then
        if murdererHRP then local flee=(hrp.Position-murdererHRP.Position).Unit; hrp.CFrame=hrp.CFrame:Lerp(CFrame.new(hrp.Position+flee*25),0.2) end
        return
    end

    local coinPos=TargetCoin.Position
    local dist=(hrp.Position-coinPos).Magnitude
    if dist<=1.2 then TargetCoin=nil; ResumeTime=tick()+1; return end

    local targetY=math.min(coinPos.Y, hrp.Position.Y+3.5)
    local targetPos=Vector3.new(coinPos.X, targetY, coinPos.Z)
    local step=math.min(dist, Sliders.FarmSpeed*deltaTime*60)
    hrp.CFrame=CFrame.new(hrp.Position:Lerp(targetPos, step/dist))
end))

-- AUTO OPEN BOXES + AUTO VOTE + AUTO DUPE (เช็คทุก 2 วินาที)
task.spawn(function()
    while wait(2) do
        if S.AutoOpenBoxes then
            pcall(function()
                for _, v in ipairs(ReplicatedStorage:GetDescendants()) do
                    if v:IsA("RemoteEvent") and (string.find(string.lower(v.Name),"box") or string.find(string.lower(v.Name),"open")) then v:FireServer("Halloween2026Box") end
                end
            end)
        end
        if S.AutoVoteMap then
            pcall(function()
                for _, v in ipairs(ReplicatedStorage:GetDescendants()) do
                    if v:IsA("RemoteEvent") and string.find(string.lower(v.Name),"vote") then v:FireServer() end
                end
            end)
        end
        if S.AutoDupe then
            pcall(function()
                for _, v in ipairs(ReplicatedStorage:GetDescendants()) do
                    if v:IsA("RemoteEvent") and string.find(string.lower(v.Name),"dupe") then v:FireServer() end
                end
            end)
        end
    end
end)

print("[Pulse MM2 Full] ✅ โหลดสำเร็จ! ครบทุกฟังก์ชันตาม config — แตะปุ่ม P ซ่อน/แสดงเมนู")
