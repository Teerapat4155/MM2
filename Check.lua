-- ดูสถานะจริงๆ ของเกม
task.spawn(function()
    while task.wait(2) do
        local gm = Workspace:FindFirstChild("GameManager") or ReplicatedStorage:FindFirstChild("GameManager", true)
        if gm and gm:FindFirstChild("Status") then
            print("📌 สถานะจริงคือ: [" .. gm.Status.Value .. "]")
        end
    end
end)
