-- AUTO COIN SYSTEM + AFK MODE
local CollectedCoins = {}
local CurrentCoinTarget = nil
local StuckTimer = COINcal LastPosition = Vector3.new(0, 0, 0)
local NoMoveTimer = 0

-- รีเซ็ตค่าทุกครั้งที่ตัวละครเกิดใหม่
addConnection(LocalPlayer.CharacterAdded:Connect(function()
    table.clear(CollectedCoins)
    CurrentCoinTarget = nil
    StuckTimer = 0
    NoMoveTimer = 0
    LastPosition = Vector3.new(math.huge, math.huge, math.huge)
    print("✅ AFK Auto Coin พร้อมทำงาน - วางโทรศัพท์ทิ้งไว้ได้เลย")
end))

-- ลูปหลัก ทำงานต่อเนื่อง ไม่ต้องแตะหน้าจอ
addConnection(RunService.Heartbeat:Connect(function(deltaTime)
    -- ถ้าปิดอยู่ ข้ามไป
    if not State.AutoCoin then
        CurrentCoinTarget = nil
        StuckTimer = 0
        NoMoveTimer = 0
        return
    end

    local myChar = LocalPlayer.Character
    local myHRP = getHRP(myChar)
    if not myHRP then return end

    -- ป้องกันติดค้าง: ถ้ายืนอยู่กับที่นานเกินไป → รีเซ็ตเป้าหมาย
    local distanceMoved = (myHRP.Position - LastPosition).Magnitude
    if distanceMoved < 0.1 then
        NoMoveTimer += deltaTime
        if NoMoveTimer > 4 then
            -- ยืนนิ่งเกิน 4 วินาที → หาเหรียญใหม่ทันที
            CurrentCoinTarget = nil
            StuckTimer = 0
            NoMoveTimer = 0
            table.clear(CollectedCoins)
        end
    else
        NoMoveTimer = 0
        LastPosition = myHRP.Position
    end

    -- หนีฆาตกรอัตโนมัติ
    for _, player in ipairs(Players:GetPlayers()) do
        if getRole(player) == "Murderer" and isAlive(player) then
            local tHRP = getHRP(player.Character)
            if tHRP and (myHRP.Position - tHRP.Position).Magnitude <= 15 then
                local fleeDir = (myHRP.Position - tHRP.Position).Unit * State.SpeedValue
                myHRP.Velocity = Vector3.new(fleeDir.X, 0.8, fleeDir.Z)
                CurrentCoinTarget = nil
                return
            end
        end
    end

    -- หาเหรียญใหม่
    if not CurrentCoinTarget or not CurrentCoinTarget.Parent then
        StuckTimer = 0
        local coinContainer = Workspace:FindFirstChild("CoinContainer")
        if not coinContainer then return end
        
        local nearestCoin, nearestDist = nil, math.huge
        
        for _, coin in ipairs(coinContainer:GetDescendants()) do
            if coin.Name == "Coin" or coin.Name == "Cola" or coin:FindFirstChild("CoinVisual") then
                local coinPart = coin:IsA("BasePart") and coin or coin:FindFirstChildWhichIsA("BasePart")
                if coinPart and not CollectedCoins[coin] then
                    local dist = (myHRP.Position - coinPart.Position).Magnitude
                    if dist < nearestDist and dist < 150 then
                        nearestDist = dist
                        nearestCoin = coinPart
                    end
                end
            end
        end
        
        if nearestCoin then
            CurrentCoinTarget = nearestCoin
        else
            table.clear(CollectedCoins)
        end
        return
    end

    -- เก็บเหรียญเมื่อใกล้พอ
    local dist = (myHRP.Position - CurrentCoinTarget.Position).Magnitude
    if dist <= 3 then
        CollectedCoins[CurrentCoinTarget] = true
        CurrentCoinTarget = nil
        StuckTimer = 0
        return
    end

    -- ป้องกันวนลูปเดิมที่เดิม
    StuckTimer += deltaTime
    if StuckTimer > 3 then
        CurrentCoinTarget = nil
        StuckTimer = 0
        return
    end

    -- เคลื่อนที่ไปหาเหรียญ — คงที่ ไม่สะดุด
    local dir = (CurrentCoinTarget.Position - myHRP.Position).Unit
    myHRP.Velocity = Vector3.new(dir.X * State.SpeedValue, math.max(dir.Y * State.SpeedValue, 0.5), dir.Z * State.SpeedValue)
end))
