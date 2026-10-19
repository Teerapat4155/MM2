--[[
    ============================================================
    MM2 AUTO COIN — FORCE GUI FIX (บังคับแสดงผล)
    ============================================================
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- เคลียร์ของเก่าถ้ามี
if _G.MM2_GUI_Test then
    pcall(function() _G.MM2_GUI_Test:Destroy() end)
end

-- สร้าง ScreenGui บังคับใส่ PlayerGui ตรงๆ
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MM2_ForcedGUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = PlayerGui
_G.MM2_GUI_Test = ScreenGui

-- สร้างกรอบ UI หลักให้เห็นชัดเจน
local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, 240, 0, 85)
Main.Position = UDim2.new(1, -255, 0, 15)
Main.BackgroundColor3 = Color3.fromRGB(18, 18, 26)
Main.Parent = ScreenGui

local UICorner = Instance.new("UICorner", Main)
UICorner.CornerRadius = UDim.new(0, 12)

local UIStroke = Instance.new("UIStroke", Main)
UIStroke.Color = Color3.fromRGB(255, 215, 0)
UIStroke.Thickness = 1.5

-- แถบหัวข้อ
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 32)
TitleBar.BackgroundColor3 = Color3.fromRGB(28, 28, 42)
TitleBar.Parent = Main

local TitleCorner = Instance.new("UICorner", TitleBar)
TitleCorner.CornerRadius = UDim.new(0, 12)

local TitleCover = Instance.new("Frame", TitleBar)
TitleCover.Size = UDim2.new(1, 0, 0.5, 0)
TitleCover.Position = UDim2.new(0, 0, 0.5, 0)
TitleCover.BackgroundColor3 = Color3.fromRGB(28, 28, 42)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -40, 1, 0)
Title.Position = UDim2.new(0, 10, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "MM2 AUTO COIN (TEST)"
Title.Font = Enum.Font.GothamBold
Title.TextSize = 12
Title.TextColor3 = Color3.fromRGB(255, 215, 0)
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TitleBar

-- ปุ่มปิด
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 22, 0, 22)
CloseBtn.Position = UDim2.new(1, -26, 0, 5)
CloseBtn.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
CloseBtn.Text = "X"
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 12
CloseBtn.TextColor3 = Color3.new(1,1,1)
CloseBtn.Parent = TitleBar
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 5)

CloseBtn.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
    print("❌ ปิด UI ทดสอบแล้ว")
end)

-- กล่องสถานะเปิดปิด
local ToggleContainer = Instance.new("Frame")
ToggleContainer.Size = UDim2.new(1, -12, 1, -12)
ToggleContainer.Position = UDim2.new(0, 6, 0, 38)
ToggleContainer.BackgroundColor3 = Color3.fromRGB(30, 30, 44)
ToggleContainer.Parent = Main
Instance.new("UICorner", ToggleContainer).CornerRadius = UDim.new(0, 6)

local ToggleLbl = Instance.new("TextLabel")
ToggleLbl.Size = UDim2.new(1, -55, 1, 0)
ToggleLbl.Position = UDim2.new(0, 8, 0, 0)
ToggleLbl.BackgroundTransparency = 1
ToggleLbl.Text = "สถานะ: พร้อมใช้งาน"
ToggleLbl.Font = Enum.Font.GothamSemibold
ToggleLbl.TextSize = 12
ToggleLbl.TextColor3 = Color3.fromRGB(220, 220, 235)
ToggleLbl.TextXAlignment = Enum.TextXAlignment.Left
ToggleLbl.Parent = ToggleContainer

print("✅ บังคับรัน GUI สำเร็จ! เช็คที่มุมขวาบนดูครับ")
