-- // Murder Mystery 2 Ultimate Script by Gemini (Full Version)
-- // Compatible with most modern exploit executors

if _G.MM2Loaded then
    _G.MM2Loaded = false
    task.wait(0.5)
end
_G.MM2Loaded = true

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local ESPEnabled = false
local AutoFarmEnabled = false

-- // Create ScreenGui
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MM2MasterGui"
ScreenGui.Parent = CoreGui
ScreenGui.ResetOnSpawn = false

-- // Floating Toggle Icon
local ToggleButton = Instance.new("ImageButton")
ToggleButton.Name = "ToggleButton"
ToggleButton.Parent = ScreenGui
ToggleButton.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
ToggleButton.BorderColor3 = Color3.fromRGB(0, 170, 255)
ToggleButton.BorderSizePixel = 2
ToggleButton.Position = UDim2.new(0, 20, 0, 20)
ToggleButton.Size = UDim2.new(0, 50, 0, 50)
ToggleButton.Image = "rbxassetid://6031094678" -- Icon รูปฟันเฟือง/เมนู
ToggleButton.Active = true
ToggleButton.Draggable = true

-- // Main Frame (UI)
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
MainFrame.BorderColor3 = Color3.fromRGB(60, 60, 60)
MainFrame.BorderSizePixel = 2
MainFrame.Position = UDim2.new(0.5, -150, 0.5, -175)
MainFrame.Size = UDim2.new(0, 300, 0, 350)
MainFrame.Visible = true -- เปิดโชว์ขึ้นมาทันทีเพื่อให้เห็น UI ชัดเจน
MainFrame.Active = true
MainFrame.Draggable = true

-- // Top Bar / Header
local TopBar = Instance.new("Frame")
TopBar.Name = "TopBar"
TopBar.Parent = MainFrame
TopBar.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
TopBar.BorderSizePixel = 0
TopBar.Size = UDim2.new(1, 0, 0, 40)

local Title = Instance.new("TextLabel")
Title.Parent = TopBar
Title.BackgroundTransparency = 1
Title.Position = UDim2.new(0, 10, 0, 0)
Title.Size = UDim2.new(1, -50, 1, 0)
Title.Font = Enum.Font.SourceSansBold
Title.Text = "MM2 Hub | PRO"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 18
Title.TextXAlignment = Enum.TextXAlignment.Left

-- // Close Button (กากบาทปิดทุกอย่าง ทำงานจริง 100%)
local CloseButton = Instance.new("TextButton")
CloseButton.Name = "CloseButton"
CloseButton.Parent = TopBar
CloseButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
CloseButton.BorderSizePixel = 0
CloseButton.Position = UDim2.new(1, -35, 0, 5)
CloseButton.Size = UDim2.new(0, 30, 0, 30)
CloseButton.Font = Enum.Font.SourceSansBold
CloseButton.Text = "X"
CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseButton.TextSize = 16

-- // Content Area
local ContentContainer = Instance.new("ScrollingFrame")
ContentContainer.Parent = MainFrame
ContentContainer.BackgroundTransparency = 1
ContentContainer.Position = UDim2.new(0, 10, 0, 50)
ContentContainer.Size = UDim2.new(1, -20, 1, -60)
ContentContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
ContentContainer.ScrollBarThickness = 4

-- จัดเรียงปุ่มอัตโนมัติด้วย UIListLayout ป้องกันปุ่มทับกัน
local UIListLayout = Instance.new("UIListLayout")
UIListLayout.Parent = ContentContainer
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Padding = UDim.new(0, 8)

UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    ContentContainer.CanvasSize = UDim2.new(0, 0, 0, UIListLayout.AbsoluteContentSize.Y + 10)
end)

-- // UI Creator Functions (สร้างปุ่มกดเปิด-ปิดฟังก์ชัน)
local function CreateToggle(name, defaultState, callback)
    local ToggleBtn = Instance.new("TextButton")
    ToggleBtn.Parent = ContentContainer
    ToggleBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    ToggleBtn.BorderColor3 = Color3.fromRGB(80, 80, 80)
    ToggleBtn.Size = UDim2.new(1, 0, 0, 45)
    ToggleBtn.Font = Enum.Font.SourceSansBold
    ToggleBtn.Text = "  " .. name .. ": " .. (defaultState and "ON" or "OFF")
    ToggleBtn.TextColor3 = defaultState and Color3.fromRGB(50, 255, 50) or Color3.fromRGB(255, 50, 50)
    ToggleBtn.TextSize = 16
    ToggleBtn.TextXAlignment = Enum.TextXAlignment.Left

    local state = defaultState
    ToggleBtn.MouseButton1Click:Connect(function()
        state = not state
        ToggleBtn.Text = "  " .. name .. ": " .. (state and "ON" or "OFF")
        ToggleBtn.TextColor3 = state and Color3.fromRGB(50, 255, 50) or Color3.fromRGB(255, 50, 50)
        callback(state)
    end)
end

-- // Toggle Main UI Visibility (ปุ่มไอคอนลอยเปิด-ปิดเมนู)
ToggleButton.MouseButton1Click:Connect(function()
    MainFrame.Visible = not MainFrame.Visible
end)

-- // Close Button Logic (กากบาทลบทุกอย่างออกจากเกม)
CloseButton.MouseButton1Click:Connect(function()
    _G.MM2Loaded = false
    ESPEnabled = false
    AutoFarmEnabled = false
    ScreenGui:Destroy()
end)

-- // --- ESP SYSTEM (Role & Distance) ---
local espCache = {}

local function getRole(player)
    local character = player.Character
    if not character then return "Innocent", Color3.fromRGB(0, 255, 0) end
    
    if player.Backpack:FindFirstChild("Knife") or character:FindFirstChild("Knife") then
        return "Murderer", Color3.fromRGB(255, 0, 0)
    elseif player.Backpack:FindFirstChild("Gun") or character:FindFirstChild("Gun") or character:FindFirstChild("Revolver") then
        return "Sheriff", Color3.fromRGB(0, 170, 255)
    else
        for _, v in pairs(player.Backpack:GetChildren()) do
            if v.Name == "Gun" or v.Name == "Knife" then
                return v.Name == "Knife" and "Murderer" or "Sheriff", v.Name == "Knife" and Color3.fromRGB(255, 0, 0) or Color3.fromRGB(0, 170, 255)
            end
        end
    end
    return "Innocent", Color3.fromRGB(0, 255, 0)
end

RunService.RenderStepped:Connect(function()
    if not _G.MM2Loaded or not ESPEnabled then
        for _, esp in pairs(espCache) do
            if esp then esp.Visible = false end
        end
        return
    end

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local hrp = player.Character.HumanoidRootPart
            local role, color = getRole(player)
            
            if not espCache[player] then
                local bill = Instance.new("BillboardGui")
                bill.Name = "ESP_Bill"
                bill.AlwaysOnTop = true
                bill.Size = UDim2.new(0, 100, 0, 30)
                bill.StudsOffset = Vector3.new(0, 3, 0)
                
                local label = Instance.new("TextLabel")
                label.Name = "ESP_Text"
                label.Parent = bill
                label.BackgroundTransparency = 1
                label.Size = UDim2.new(1, 0, 1, 0)
                label.Font = Enum.Font.SourceSansBold
                label.TextSize = 14
                label.TextStrokeTransparency = 0
                
                bill.Parent = hrp
                espCache[player] = bill
            end
            
            local bill = espCache[player]
            if bill and bill.Parent == hrp then
                bill.Visible = true
                local label = bill.TextLabel
                local dist = math.floor((hrp.Position - Camera.CFrame.Position).Magnitude)
                -- แสดงเฉพาะบทบาทและระยะห่าง (ไม่มีชื่อผู้เล่น)
                label.Text = "[" .. role .. "] (" .. dist .. "m)"
                label.TextColor3 = color
            end
        else
            if espCache[player] then
                espCache[player].Visible = false
            end
        end
    end
end)

-- // --- AUTO FARM COINS SYSTEM ---
task.spawn(function()
    while _G.MM2Loaded do
        if AutoFarmEnabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            pcall(function()
                local hrp = LocalPlayer.Character.HumanoidRootPart
                local coinContainer = Workspace:FindFirstChild("CoinContainer") or Workspace:FindFirstChild("Normal")
                if coinContainer then
                    for _, coin in pairs(coinContainer:GetChildren()) do
                        if not AutoFarmEnabled or not _G.MM2Loaded then break end
                        if coin:FindFirstChild("TouchInterest") or coin:IsA("BasePart") then
                            hrp.CFrame = coin.CFrame
                            task.wait(0.2)
                        end
                    end
                end
            end)
        end
        task.wait(1)
    end
end)

-- // Create UI Toggles
CreateToggle("Role ESP", false, function(state)
    ESPEnabled = state
end)

CreateToggle("Auto Farm Coins", false, function(state)
    AutoFarmEnabled = state
end)

print("MM2 Hub Full Version Loaded Successfully!")
