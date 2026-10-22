--[[
    ============================================================
    DOORS - MOBILE ULTIMATE CUSTOM ESP SCRIPT (FIXED EDITION)
    - สีเขียว: กุญแจ (Key)
    - สีชมพู: หนังสือ (Book)
    - สีเหลือง: กล่องไฟ/ฟิวส์ (Breaker Pole)
    - สีแดง: มอนสเตอร์ (Rush, Ambush, Seek, Figure ฯลฯ)
    ✅ แก้ไขแล้ว: ลาก/กดแยกกัน, Highlight ติดทั้งโมเดล,
       throttle สแกน 0.2วิ, pcall กัน error, ลบ false positive
    ============================================================
]]

--// SERVICES
local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local TweenService      = game:GetService("TweenService")
local Workspace         = game:GetService("Workspace")
local CoreGui           = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

--// CONFIG / COLORS
local ESP_SETTINGS = {
    Monster = Color3.fromRGB(255, 50, 50),   -- สีแดง (มอนสเตอร์)
    Key     = Color3.fromRGB(50, 255, 50),   -- สีเขียว (กุญแจ)
    Book    = Color3.fromRGB(255, 105, 180), -- สีชมพู (หนังสือ)
    Breaker = Color3.fromRGB(255, 255, 0),   -- สีเหลือง (กล่องไฟ)
}

-- รายชื่อมอนสเตอร์ (เอา "Hide" ออก เพราะไม่ใช่มอนสเตอร์ ช่วยลด false positive)
local MONSTER_LIST = {
    ["Rush"] = true, ["Ambush"] = true, ["Seek"] = true, ["Figure"] = true,
    ["Screech"] = true, ["Eyes"] = true, ["Halt"] = true, ["Dupe"] = true,
    ["Timothy"] = true, ["Jack"] = true, ["Glitch"] = true, ["Dread"] = true,
    ["Snare"] = true, ["Giggle"] = true, ["Grumble"] = true, ["Queen Grumble"] = true,
    ["Gloombats"] = true, ["Blitz"] = true, ["Lookman"] = true, ["A-60"] = true,
    ["A-90"] = true, ["A-120"] = true,
}

local ToggleState = { Monster = true, Key = true, Book = true, Breaker = true }

-- ESP_Objects เก็บทั้ง highlight และหมวดหมู่ (แก้ปัญหาเทียบสีผิด)
local ESP_Objects = {}   -- [target] = { hl = Highlight, cat = "Monster"|"Key"|... }
local Connections = {}
local IsRunning = true
local LastScan = 0

local function addConnection(conn) table.insert(Connections, conn); return conn end

--// CLEANUP
local function fullCleanup()
    IsRunning = false
    for _, data in pairs(ESP_Objects) do pcall(function() if data.hl then data.hl:Destroy() end end) end
    ESP_Objects = {}
    for _, conn in ipairs(Connections) do pcall(function() conn:Disconnect() end) end
    Connections = {}
    if _G.Doors_ESP_GUI then pcall(function() _G.Doors_ESP_GUI:Destroy() end) _G.Doors_ESP_GUI = nil end
    print("[DOORS ESP] ปิดการทำงานเรียบร้อย!")
end
pcall(function() if _G.Doors_ESP_Cleanup then _G.Doors_ESP_Cleanup() end end)
_G.Doors_ESP_Cleanup = fullCleanup

--// UI PARENT (fallback 3 ชั้นสำหรับมือถือ)
local parentUI = nil
pcall(function() parentUI = gethui and gethui() end)
if not parentUI then pcall(function() parentUI = CoreGui end) end
if not parentUI then parentUI = LocalPlayer:WaitForChild("PlayerGui") end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "Doors_ESP_GUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder = 999
ScreenGui.Parent = parentUI
_G.Doors_ESP_GUI = ScreenGui

--// ลากเมนู (รองรับ Touch)
local function makeDraggable(frame, dragArea)
    local dragging, dragStart, startPos
    addConnection(dragArea.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true; dragStart = input.Position; startPos = frame.Position
        end
    end))
    addConnection(UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end))
    addConnection(dragArea.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
    end))
end

--// ไอคอนลอย (แก้ปัญหาลากแล้วกดตามด้วย: แยก drag กับ click ด้วย moved threshold)
local Icon = Instance.new("TextButton")
Icon.Name = "ToggleIcon"
Icon.Size = UDim2.new(0, 55, 0, 55)
Icon.Position = UDim2.new(0, 20, 0.25, 0)
Icon.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
Icon.Text = "DOORS"
Icon.Font = Enum.Font.GothamBold
Icon.TextSize = 11
Icon.TextColor3 = Color3.fromRGB(255, 100, 100)
Icon.AutoButtonColor = false
Icon.Parent = ScreenGui
Instance.new("UICorner", Icon).CornerRadius = UDim.new(0, 14)
local IconStroke = Instance.new("UIStroke", Icon); IconStroke.Color = Color3.fromRGB(255, 100, 100); IconStroke.Thickness = 2

local menuOpen = false
local iDrag, iDragStart, iStartPos, iMoved = false, nil, nil, false
addConnection(Icon.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
        iDrag = true; iMoved = false; iDragStart = i.Position; iStartPos = Icon.Position
    end
end))
addConnection(UserInputService.InputChanged:Connect(function(i)
    if iDrag and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
        local d = i.Position - iDragStart
        if d.Magnitude > 6 then iMoved = true; Icon.Position = UDim2.new(iStartPos.X.Scale, iStartPos.X.Offset + d.X, iStartPos.Y.Scale, iStartPos.Y.Offset + d.Y) end
    end
end))
addConnection(Icon.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
        if iDrag and not iMoved then menuOpen = not menuOpen; Main.Visible = menuOpen end
        iDrag = false
    end
end))

--// เมนูหลัก
local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, 260, 0, 240)
Main.Position = UDim2.new(0.5, -130, 0.5, -120)
Main.BackgroundColor3 = Color3.fromRGB(18, 18, 26)
Main.Visible = false
Main.Parent = ScreenGui
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 12)
local MainStroke = Instance.new("UIStroke", Main); MainStroke.Color = Color3.fromRGB(80, 80, 120); MainStroke.Thickness = 1.5

local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 40)
TitleBar.BackgroundColor3 = Color3.fromRGB(28, 28, 42)
TitleBar.Parent = Main
Instance.new("UICorner", TitleBar).CornerRadius = UDim.new(0, 12)
local TitleBarCover = Instance.new("Frame")
TitleBarCover.Size = UDim2.new(1, 0, 0.5, 0); TitleBarCover.Position = UDim2.new(0, 0, 0.5, 0)
TitleBarCover.BackgroundColor3 = Color3.fromRGB(28, 28, 42); TitleBarCover.BorderSizePixel = 0; TitleBarCover.Parent = TitleBar
makeDraggable(Main, TitleBar)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -50, 1, 0); Title.Position = UDim2.new(0, 12, 0, 0)
Title.BackgroundTransparency = 1; Title.Text = "DOORS MOBILE ESP"
Title.Font = Enum.Font.GothamBold; Title.TextSize = 13
Title.TextColor3 = Color3.fromRGB(255, 100, 100); Title.TextXAlignment = Enum.TextXAlignment.Left; Title.Parent = TitleBar

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 28, 0, 28); CloseBtn.Position = UDim2.new(1, -36, 0, 6)
CloseBtn.BackgroundColor3 = Color3.fromRGB(220, 50, 50); CloseBtn.Text = "X"
CloseBtn.Font = Enum.Font.GothamBold; CloseBtn.TextSize = 14; CloseBtn.TextColor3 = Color3.fromRGB(255,255,255)
CloseBtn.AutoButtonColor = false; CloseBtn.Parent = TitleBar
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 6)
CloseBtn.MouseButton1Click:Connect(fullCleanup)

local Content = Instance.new("ScrollingFrame")
Content.Size = UDim2.new(1, -16, 1, -52); Content.Position = UDim2.new(0, 8, 0, 46)
Content.BackgroundTransparency = 1; Content.ScrollBarThickness = 3
Content.CanvasSize = UDim2.new(0, 0, 0, 0); Content.AutomaticCanvasSize = Enum.AutomaticSize.Y
Content.Parent = Main
local ContentLayout = Instance.new("UIListLayout"); ContentLayout.Padding = UDim.new(0, 8); ContentLayout.SortOrder = Enum.SortOrder.LayoutOrder; ContentLayout.Parent = Content

--// Toggle (เก็บ category ล้าง ESP ได้แม่นยำ)
local yIdx = 0
local function createMenuToggle(name, stateKey, color)
    yIdx = yIdx + 1
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 35); row.BackgroundColor3 = Color3.fromRGB(30, 30, 44)
    row.LayoutOrder = yIdx; row.Parent = Content
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -55, 1, 0); lbl.Position = UDim2.new(0, 8, 0, 0)
    lbl.BackgroundTransparency = 1; lbl.Text = name; lbl.Font = Enum.Font.GothamSemibold; lbl.TextSize = 11
    lbl.TextColor3 = Color3.fromRGB(220, 220, 235); lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Parent = row
    local toggle = Instance.new("TextButton")
    toggle.Size = UDim2.new(0, 38, 0, 20); toggle.Position = UDim2.new(1, -44, 0.5, -10)
    toggle.BackgroundColor3 = ToggleState[stateKey] and color or Color3.fromRGB(60, 60, 80)
    toggle.Text = ""; toggle.AutoButtonColor = false; toggle.Parent = row
    Instance.new("UICorner", toggle).CornerRadius = UDim.new(1, 0)
    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 14, 0, 14)
    knob.Position = ToggleState[stateKey] and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)
    knob.BackgroundColor3 = Color3.fromRGB(220, 220, 220); knob.Parent = toggle
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)
    toggle.MouseButton1Click:Connect(function()
        ToggleState[stateKey] = not ToggleState[stateKey]
        if ToggleState[stateKey] then
            TweenService:Create(toggle, TweenInfo.new(0.2), {BackgroundColor3 = color}):Play()
            TweenService:Create(knob, TweenInfo.new(0.2), {Position = UDim2.new(1, -17, 0.5, -7)}):Play()
        else
            TweenService:Create(toggle, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(60, 60, 80)}):Play()
            TweenService:Create(knob, TweenInfo.new(0.2), {Position = UDim2.new(0, 3, 0.5, -7)}):Play()
            -- ล้าง ESP ของหมวดหมู่นั้นๆ (ใช้ category ไม่ใช่เทียบสี)
            for target, data in pairs(ESP_Objects) do
                if data.cat == stateKey then
                    pcall(function() if data.hl then data.hl:Destroy() end end)
                    ESP_Objects[target] = nil
                end
            end
        end
    end)
end

createMenuToggle("🔴 มอนสเตอร์", "Monster", ESP_SETTINGS.Monster)
createMenuToggle("🟢 กุญแจ", "Key", ESP_SETTINGS.Key)
createMenuToggle("🟣 หนังสือ", "Book", ESP_SETTINGS.Book)
createMenuToggle("🟡 กล่องไฟ", "Breaker", ESP_SETTINGS.Breaker)

--// ESP CORE (Highlight ติดทั้งโมเดล ไม่ใช่แค่ Part เดียว)
local function createESP(target, color, category)
    if not target or ESP_Objects[target] then return end
    if not (target:IsA("Model") or target:IsA("BasePart")) then return end
    pcall(function()
        local highlight = Instance.new("Highlight")
        highlight.Name = "DoorsESP_Item"
        highlight.Adornee = target
        highlight.FillColor = color
        highlight.OutlineColor = color
        highlight.FillTransparency = 0.4
        highlight.OutlineTransparency = 0
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        -- parent ไปที่ target (ถ้าโดนลบ highlight ก็หายไปเองอัตโนมัติ) fallback ไป CoreGui
        local ok = pcall(function() highlight.Parent = target end)
        if not ok then highlight.Parent = parentUI end
        ESP_Objects[target] = { hl = highlight, cat = category }
    end)
end

local function cleanupInvalidESP()
    for target, data in pairs(ESP_Objects) do
        if not target or not target.Parent or not target:IsDescendantOf(game) then
            pcall(function() if data.hl then data.hl:Destroy() end end)
            ESP_Objects[target] = nil
        end
    end
end

--// ตรวจจับวัตถุ (ห่อ pcall กัน error ตอนวัตถุถูกลบ)
local function checkObject(obj)
    local ok, result = pcall(function()
        if not obj or not obj.Parent then return nil end
        local nm = obj.Name
        local nmLower = string.lower(nm)
        -- มอนสเตอร์
        if ToggleState.Monster and MONSTER_LIST[nm] then
            return { obj = obj, color = ESP_SETTINGS.Monster, cat = "Monster" }
        end
        -- กุญแจ (ลด false positive: ต้องมี "key" และไม่ใช่คำอื่น)
        if ToggleState.Key and nmLower:find("key") and not nmLower:find("monkey") and not nmLower:find("turkey") and not nmLower:find("donkey") then
            return { obj = obj, color = ESP_SETTINGS.Key, cat = "Key" }
        end
        -- หนังสือ
        if ToggleState.Book and (nmLower == "book" or nmLower:find("livehintbook") or nmLower:find("librarybook")) then
            return { obj = obj, color = ESP_SETTINGS.Book, cat = "Book" }
        end
        -- กล่องไฟ/ฟิวส์
        if ToggleState.Breaker and (nmLower:find("breaker") or nmLower == "fuse" or nmLower:find("fuse")) then
            return { obj = obj, color = ESP_SETTINGS.Breaker, cat = "Breaker" }
        end
        return nil
    end)
    if ok and result then return result end
    return nil
end

--// ลูปสแกน throttle ทุก 0.2 วินาที (ไม่แลคบนมือถือ)
addConnection(RunService.Heartbeat:Connect(function()
    if not IsRunning then return end
    local now = tick()
    if now - LastScan < 0.2 then return end
    LastScan = now
    cleanupInvalidESP()

    -- สแกนในห้องปัจจุบัน
    local rooms = Workspace:FindFirstChild("CurrentRooms")
    if rooms then
        for _, room in ipairs(rooms:GetChildren()) do
            for _, obj in ipairs(room:GetDescendants()) do
                local found = checkObject(obj)
                if found then createESP(found.obj, found.color, found.cat) end
            end
        end
    end

    -- สแกน Workspace root ด้วย (มอนสเตอร์บางตัว + ของที่อยู่นอก CurrentRooms)
    for _, obj in ipairs(Workspace:GetChildren()) do
        local found = checkObject(obj)
        if found then createESP(found.obj, found.color, found.cat) end
        -- ถ้าเป็น Folder/Model อื่นๆ ที่อาจมีของอยู่ข้างใน (เช่น Rooms) สแกนลึกอีกชั้น
        if obj:IsA("Folder") or obj:IsA("Model") then
            for _, child in ipairs(obj:GetChildren()) do
                local f2 = checkObject(child)
                if f2 then createESP(f2.obj, f2.color, f2.cat) end
            end
        end
    end
end))

print("[DOORS ESP MOBILE] ✅ โหลดเรียบร้อย! แก้ไขแล้วทุกปัญหา — แตะไอคอน DOORS เพื่อเปิดเมนู")
