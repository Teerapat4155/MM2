--[[
    ============================================================
    MM2 KILL COMMANDS (Mobile Friendly)
    ✅ 4 ปุ่ม: ฆ่าทุกคน / ฆ่าคนที่เลือก / ฆ่าฆาตกร / ฆ่านายอำเภอ
    ✅ ใช้งานได้ตอนเป็น ฆาตกร (Murderer) เท่านั้น (ต้องมีมีด)
    ============================================================
]]

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace        = game:GetService("Workspace")
local CoreGui          = game:GetService("CoreGui")
local LocalPlayer      = Players.LocalPlayer

if getgenv().MM2Kill_Cleanup then pcall(function() getgenv().MM2Kill_Cleanup() end) end

local Connections = {}
local function addConn(c) table.insert(Connections, c); return c end
local function getHRP(c) return c and c:FindFirstChild("HumanoidRootPart") end
local function getHum(c) return c and c:FindFirstChildOfClass("Humanoid") end
local function alive(p) local c=p.Character local h=getHum(c) return c and h and h.Health>0 end

getgenv().MM2Kill_Cleanup = function()
    for _, conn in ipairs(Connections) do pcall(function() conn:Disconnect() end) end
    table.clear(Connections)
    pcall(function() if _G.MM2Kill_GUI then _G.MM2Kill_GUI:Destroy() _G.MM2Kill_GUI=nil end end)
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

-- ===== ฟังก์ชันฆ่า 1 คน =====
local function killOne(targetPlayer)
    if not targetPlayer or not alive(targetPlayer) then return false end
    local myChar = LocalPlayer.Character
    local myHRP = getHRP(myChar)
    if not myHRP then return false end
    -- ต้องเป็นฆาตกรถึงจะฆ่าได้
    if getRole(LocalPlayer) ~= "Murderer" then return false, "not_murderer" end
    -- หามีด
    local knife = myChar:FindFirstChildOfClass("Tool")
    if not knife then
        local bp = LocalPlayer:FindFirstChildOfClass("Backpack")
        if bp then
            for _, t in ipairs(bp:GetChildren()) do
                if t:IsA("Tool") then
                    local h = getHum(myChar)
                    if h then h:EquipTool(t) end
                    knife = t
                    break
                end
            end
        end
    end
    if not knife then return false, "no_knife" end
    local tHRP = getHRP(targetPlayer.Character)
    if not tHRP then return false end
    pcall(function()
        -- เทเลพอร์ตไปใกล้เป้าหมายแล้วใช้ firetouchinterest ฆ่า
        tHRP.CFrame = myHRP.CFrame * CFrame.new(0, 0, -2)
        task.wait(0.05)
        knife:Activate()
        local handle = knife:FindFirstChild("Handle") or knife:FindFirstChildWhichIsA("BasePart")
        if handle and firetouchinterest then
            firetouchinterest(handle, tHRP, 0)
            task.wait(0.05)
            firetouchinterest(handle, tHRP, 1)
        end
        -- ยิง Remote เพิ่มเติม
        for _, d in ipairs(knife:GetDescendants()) do
            if d:IsA("RemoteEvent") then
                pcall(function() d:FireServer(targetPlayer.Character) end)
            end
        end
    end)
    return true
end

-- ===== ฆ่าทุกคน =====
local function killEveryone()
    if getRole(LocalPlayer) ~= "Murderer" then return false, "not_murderer" end
    task.spawn(function()
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and alive(p) then
                killOne(p)
                task.wait(0.15)
            end
        end
    end)
    return true
end

-- ===== ฆ่าตามบทบาท =====
local function killByRole(roleName)
    if getRole(LocalPlayer) ~= "Murderer" then return false, "not_murderer" end
    local found = false
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and alive(p) and getRole(p) == roleName then
            found = true
            task.spawn(function() killOne(p) end)
        end
    end
    return found
end

-- ===== UI (มือถือ) =====
local parentUI = nil
pcall(function() parentUI = gethui and gethui() end)
if not parentUI then pcall(function() parentUI = CoreGui end) end
if not parentUI then parentUI = LocalPlayer:WaitForChild("PlayerGui") end

local SG = Instance.new("ScreenGui")
SG.Name = "MM2Kill_GUI"; SG.ResetOnSpawn = false; SG.DisplayOrder = 999; SG.Parent = parentUI
_G.MM2Kill_GUI = SG

local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, 300, 0, 320)
Main.Position = UDim2.new(0.5, -150, 0.5, -160)
Main.BackgroundColor3 = Color3.fromRGB(16, 16, 24)
Main.Visible = true
Main.Parent = SG
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 14)
local ms = Instance.new("UIStroke", Main); ms.Color = Color3.fromRGB(255, 60, 60); ms.Thickness = 1.5

-- Title
local TB = Instance.new("Frame"); TB.Size = UDim2.new(1, 0, 0, 44); TB.BackgroundColor3 = Color3.fromRGB(26, 26, 40); TB.Parent = Main
Instance.new("UICorner", TB).CornerRadius = UDim.new(0, 14)
local cov = Instance.new("Frame"); cov.Size = UDim2.new(1, 0, 0.5, 0); cov.Position = UDim2.new(0, 0, 0.5, 0); cov.BackgroundColor3 = Color3.fromRGB(26, 26, 40); cov.BorderSizePixel = 0; cov.Parent = TB
local Ttl = Instance.new("TextLabel"); Ttl.Size = UDim2.new(1, -46, 1, 0); Ttl.Position = UDim2.new(0, 12, 0, 0)
Ttl.BackgroundTransparency = 1; Ttl.Text = "⚔️ MM2 KILL COMMANDS"; Ttl.Font = Enum.Font.GothamBold; Ttl.TextSize = 15
Ttl.TextColor3 = Color3.fromRGB(255, 60, 60); Ttl.TextXAlignment = Enum.TextXAlignment.Left; Ttl.Parent = TB
local XBtn = Instance.new("TextButton"); XBtn.Size = UDim2.new(0, 32, 0, 32); XBtn.Position = UDim2.new(1, -38, 0, 6)
XBtn.BackgroundColor3 = Color3.fromRGB(220, 50, 50); XBtn.Text = "X"; XBtn.Font = Enum.Font.GothamBold; XBtn.TextSize = 14
XBtn.TextColor3 = Color3.new(1, 1, 1); XBtn.Parent = TB; Instance.new("UICorner", XBtn).CornerRadius = UDim.new(0, 8)
addConn(XBtn.MouseButton1Click:Connect(function() getgenv().MM2Kill_Cleanup() end))

-- ลากเมนู
local mD, mDS, mSP = false, nil, nil
addConn(TB.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then mD = true; mDS = i.Position; mSP = Main.Position end end))
addConn(UserInputService.InputChanged:Connect(function(i) if mD and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then local d = i.Position - mDS; Main.Position = UDim2.new(mSP.X.Scale, mSP.X.Offset + d.X, mSP.Y.Scale, mSP.Y.Offset + d.Y) end end))
addConn(TB.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then mD = false end end))

-- สถานะแจ้งเตือน
local Status = Instance.new("TextLabel")
Status.Size = UDim2.new(1, -20, 0, 24); Status.Position = UDim2.new(0, 10, 0, 50)
Status.BackgroundTransparency = 1; Status.Text = "⚠️ ต้องเป็น ฆาตกร (Murderer) ถึงจะใช้ได้"; Status.Font = Enum.Font.GothamSemibold
Status.TextSize = 12; Status.TextColor3 = Color3.fromRGB(255, 200, 80); Status.TextWrapped = true; Status.Parent = Main

-- สร้างปุ่มใหญ่ๆ
local function makeButton(y, text, color, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -24, 0, 44); btn.Position = UDim2.new(0, 12, 0, y)
    btn.BackgroundColor3 = color; btn.Text = text; btn.Font = Enum.Font.GothamBold; btn.TextSize = 14
    btn.TextColor3 = Color3.new(1, 1, 1); btn.AutoButtonColor = false; btn.Parent = Main
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 10)
    local st = Instance.new("UIStroke", btn); st.Color = Color3.fromRGB(255, 255, 255); st.Thickness = 0.5; st.Transparency = 0.5
    btn.MouseButton1Click:Connect(function()
        local ok, err = callback()
        if ok == false and err == "not_murderer" then
            Status.Text = "❌ ต้องเป็น ฆาตกร (มีมีด) ถึงจะฆ่าได้!"
            Status.TextColor3 = Color3.fromRGB(255, 80, 80)
        elseif ok == false and err == "no_knife" then
            Status.Text = "❌ ไม่พบมีด! ต้องเป็นฆาตกรก่อน"
            Status.TextColor3 = Color3.fromRGB(255, 80, 80)
        elseif ok == false then
            Status.Text = "❌ ไม่พบเป้าหมาย"
            Status.TextColor3 = Color3.fromRGB(255, 80, 80)
        else
            Status.Text = "✅ " .. text .. " ทำงานแล้ว!"
            Status.TextColor3 = Color3.fromRGB(80, 255, 120)
        end
        task.delay(3, function() Status.Text = "⚠️ ต้องเป็น ฆาตกร (Murderer) ถึงจะใช้ได้"; Status.TextColor3 = Color3.fromRGB(255, 200, 80) end)
    end)
    return btn
end

-- Dropdown เลือกเป้าหมาย (สำหรับ ฆ่าคนที่เลือก)
local SelectedTarget = nil
local DropBtn = Instance.new("TextButton")
DropBtn.Size = UDim2.new(1, -24, 0, 38); DropBtn.Position = UDim2.new(0, 12, 0, 82)
DropBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 60); DropBtn.Text = "👤 เลือกเป้าหมาย..."; DropBtn.Font = Enum.Font.GothamSemibold
DropBtn.TextSize = 13; DropBtn.TextColor3 = Color3.fromRGB(220, 220, 235); DropBtn.Parent = Main
Instance.new("UICorner", DropBtn).CornerRadius = UDim.new(0, 8)

local DropList = Instance.new("Frame")
DropList.Size = UDim2.new(1, -24, 0, 120); DropList.Position = UDim2.new(0, 12, 0, 124)
DropList.BackgroundColor3 = Color3.fromRGB(30, 30, 45); DropList.Visible = false; DropList.ZIndex = 50; DropList.Parent = Main
Instance.new("UICorner", DropList).CornerRadius = UDim.new(0, 8)
local DropScroll = Instance.new("ScrollingFrame")
DropScroll.Size = UDim2.new(1, -8, 1, -8); DropScroll.Position = UDim2.new(0, 4, 0, 4)
DropScroll.BackgroundTransparency = 1; DropScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
DropScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y; DropScroll.ScrollBarThickness = 3; DropScroll.ZIndex = 51; DropScroll.Parent = DropList
Instance.new("UIListLayout", DropScroll).Padding = UDim.new(0, 2)

local function refreshDrop()
    for _, c in ipairs(DropScroll:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            local b = Instance.new("TextButton")
            b.Size = UDim2.new(1, 0, 0, 24); b.BackgroundColor3 = Color3.fromRGB(50, 50, 72)
            b.Text = "  " .. p.Name .. "  [" .. getRole(p) .. "]"; b.Font = Enum.Font.Gotham; b.TextSize = 11
            b.TextColor3 = Color3.fromRGB(220, 220, 235); b.TextXAlignment = Enum.TextXAlignment.Left
            b.ZIndex = 52; b.Parent = DropScroll; Instance.new("UICorner", b).CornerRadius = UDim.new(0, 4)
            b.MouseButton1Click:Connect(function()
                SelectedTarget = p.Name
                DropBtn.Text = "🎯 " .. p.Name
                DropList.Visible = false
            end)
        end
    end
end
DropBtn.MouseButton1Click:Connect(function()
    DropList.Visible = not DropList.Visible
    if DropList.Visible then refreshDrop() end
end)

-- 4 ปุ่มคำสั่งฆ่า
makeButton(130, "💀 ฆ่าทุกคน (Kill All)", Color3.fromRGB(200, 40, 40), function()
    return killEveryone()
end)
makeButton(180, "🎯 ฆ่าคนที่เลือก (Kill Selected)", Color3.fromRGB(180, 60, 200), function()
    if not SelectedTarget then return false end
    local p = Players:FindFirstChild(SelectedTarget)
    if not p then return false end
    task.spawn(function() killOne(p) end)
    return true
end)
makeButton(230, "🔪 ฆ่าฆาตกร (Kill Murderer)", Color3.fromRGB(255, 80, 80), function()
    return killByRole("Murderer")
end)
makeButton(280, "🔫 ฆ่านายอำเภอ (Kill Sheriff)", Color3.fromRGB(60, 120, 255), function()
    return killByRole("Sheriff")
end)

-- อัปเดตสถานะตอนเป็นฆาตกร
addConn(RunService.Heartbeat:Connect(function()
    if getRole(LocalPlayer) == "Murderer" then
        Status.Text = "✅ คุณเป็นฆาตกรแล้ว ใช้คำสั่งได้เลย!"
        Status.TextColor3 = Color3.fromRGB(80, 255, 120)
    end
end))

print("[MM2 Kill Commands] ✅ โหลดสำเร็จ! ต้องเป็นฆาตกรถึงจะใช้งานได้")
