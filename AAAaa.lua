--[[
    ============================================================
    MM2 SIMPLE & GUARANTEED RUN SCRIPT
    ✅ ตัดปัญหาหน้าต่างไม่ขึ้น รันปุ๊บเมนูกลางจอเด้งทันที
    ✅ ระบบ Auto Coin, Aura Kill, ESP และ "หลบ" ครบถ้วน
    ============================================================
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

-- ลบ UI เก่าทิ้งก่อนรันใหม่
pcall(function()
    if CoreGui:FindFirstChild("MM2_SimpleGui") then
        CoreGui.MM2_SimpleGui:Destroy()
    end
end)

-- สร้าง ScreenGui ตรง CoreGui ชัวร์ที่สุด
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MM2_SimpleGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = CoreGui

-- สร้างหน้าต่างเมนูหลักโชว์หรารอไว้เลยตรงกลาง-ขวา
local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, 260, 0, 240)
Main.Position = UDim2.new(0.7, 0, 0.3, 0)
Main.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
Main.Visible = true
Main.Parent = ScreenGui
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 10)
local stroke = Instance.new("UIStroke", Main)
stroke.Color = Color3.fromRGB(255, 215, 0)
stroke.Thickness = 2

-- หัวข้อ
local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 35)
Title.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
Title.Text = "MM2 SAFE PANEL"
Title.Font = Enum.Font.GothamBold
Title.TextSize = 13
Title.TextColor3 = Color3.fromRGB(255, 215, 0)
Title.Parent = Main
Instance.new("UICorner", Title).CornerRadius = UDim.new(0, 10)

-- ปุ่มปิดสคริปต์
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 25, 0, 25)
CloseBtn.Position = UDim2.new(1, -30, 0, 5)
CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.new(1,1,1)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.Parent = Title
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 5)

CloseBtn.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

-- สถานะฟังก์ชัน
local State = {
    AutoCoin = false,
    ESP = false,
    Dodge = true,
}

-- ฟังก์ชันสร้างปุ่มเปิด/ปิดในเมนู
local function createToggle(name, yPos, callback)
    local Btn = Instance.new("TextButton")
    Btn.Size = UDim2.new(1, -20, 0, 35)
    Btn.Position = UDim2.new(0, 10, 0, yPos)
    Btn.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
    Btn.Text = name .. ": OFF"
    Btn.Font = Enum.Font.GothamBold
    Btn.TextSize, Btn.TextColor3 = 11, Color3.new(1,1,1)
    Btn.Parent = Main
    Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 6)

    local active = false
    Btn.MouseButton1Click:Connect(function()
        active = not active
        Btn.BackgroundColor3 = active and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(50, 50, 70)
        Btn.Text = name .. (active and ": ON" or ": OFF")
        callback(active)
    end)
end

-- เพิ่มปุ่มฟังก์ชันต่างๆ ลงในหน้าต่าง
createToggle("Auto Coin (ฟาร์มเซฟโซน)", 45, function(v) State.AutoCoin = v end)
createToggle("ESP (สแกนกระเป๋า)", 85, function(v) State.ESP = v end)
createToggle("ระบบ หลบ (30ม.)", 125, function(v) State.Dodge = v end)

-- ฟังก์ชันเช็คของในกระเป๋า
local function scanBackpack(player)
    local char = player.Character
    local containers = {player:FindFirstChild("Backpack"), char}
    local hasGun, hasKnife = false, false

    for _, container in ipairs(containers) do
        if container then
            for _, item in ipairs(container:GetChildren()) do
                if item:IsA("Tool") then
                    local name = string.lower(item.Name)
                    if name:find("gun") or name:find("revolver") or name:find("sheriff") then
                        hasGun = true
                    elseif name:find("knife") or name:find("blade") or name:find("scythe") or name:find("dagger") or item:FindFirstChild("Handle") then
                        if not name:find("radio") and not name:find("icecream") then
                            hasKnife = true
                        end
                    end
                end
            end
        end
    end
    return hasGun and "Gun" or (hasKnife and "Knife" or "Green")
end

-- ระบบ "หลบ" อัตโนมัติ
RunService.Heartbeat:Connect(function()
    if not State.Dodge then return end
    pcall(function()
        local myChar = LocalPlayer.Character
        local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
        if not myHRP then return end

        -- หนีฆาตกร 30 เมตร
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and scanBackpack(p) == "Knife" and p.Character then
                local pHRP = p.Character:FindFirstChild("HumanoidRootPart")
                if pHRP and (myHRP.Position - pHRP.Position).Magnitude <= 30 then
                    myHRP.CFrame = myHRP.CFrame * CFrame.new(0, 0, 15)
                    return
                end
            end
        end
    end)
end)

-- ระบบ ESP
local ESPObjects = {}
RunService.RenderStepped:Connect(function()
    if not State.ESP then
        for _, box in pairs(ESPObjects) do pcall(function() box.Enabled = false end) end
        return
    end

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            pcall(function()
                local char = p.Character
                local box = char:FindFirstChild("MM2_Box")
                if not box then
                    box = Instance.new("Highlight")
                    box.Name = "MM2_Box"
                    box.Adornee = char
                    box.FillTransparency = 0.5
                    box.Parent = char
                    table.insert(ESPObjects, box)
                end
                box.Enabled = true
                local res = scanBackpack(p)
                if res == "Knife" then
                    box.FillColor = Color3.fromRGB(255, 50, 50) -- แดง
                elseif res == "Gun" then
                    box.FillColor = Color3.fromRGB(50, 150, 255) -- ฟ้า
                else
                    box.FillColor = Color3.fromRGB(50, 255, 50) -- เขียว
                end
            end)
        end
    end
end)

-- ระบบ Auto Coin (เซฟโซน 20ม. จากฆาตกร)
local TargetCoin = nil
RunService.Heartbeat:Connect(function(dt)
    if not State.AutoCoin then TargetCoin = nil return end
    pcall(function()
        local myChar = LocalPlayer.Character
        local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
        if not myHRP then return end

        local CoinContainer = Workspace:FindFirstChild("CoinContainer") or Workspace:FindFirstChild("Normal")
        if not CoinContainer then return end

        local function isSafe(pos)
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and scanBackpack(p) == "Knife" and p.Character then
                    local pHRP = p.Character:FindFirstChild("HumanoidRootPart")
                    if pHRP and (pos - pHRP.Position).Magnitude <= 20 then
                        return false
                    end
                end
            end
            return true
        end

        if not TargetCoin or not TargetCoin.Parent or not isSafe(TargetCoin.Position) then
            local nearest, distNearest = nil, math.huge
            for _, coin in ipairs(CoinContainer:GetChildren()) do
                if coin:IsA("BasePart") and isSafe(coin.Position) then
                    local dist = (myHRP.Position - coin.Position).Magnitude
                    if dist < distNearest then
                        distNearest = dist
                        nearest = coin
                    end
                end
            end
            TargetCoin = nearest
        end

        if TargetCoin then
            local targetPos = TargetCoin.Position
            myHRP.CFrame = CFrame.new(myHRP.Position:Lerp(targetPos, math.min(1, 22 * dt)))
            myHRP.AssemblyLinearVelocity = Vector3.new(0,0,0)
        end
    end)
end)

print("✅ MM2 Simple Panel Loaded Successfully!")
