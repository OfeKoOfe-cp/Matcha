loadstring(game:HttpGet("https://raw.githubusercontent.com/nvqren/Matcha-Waifu/refs/heads/main/Waifu%20UI/WaifuUI.lua"))()

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local WAYPOINTS = {
    Vector3.new(690, 290, -475),
    Vector3.new(690, 524, -475),
    Vector3.new(690, 724, -475),
    Vector3.new(-1, 589, -402),
    Vector3.new(-4, 724, 420),
    Vector3.new(-4, 518, 420),
}

local WAIT_AT = { [2] = 2 }
local COOLDOWN_AT = 4

local currentWaypoint = 1
local cooldownUntil = 0
local needsCooldown = false

local myTab = UI:Tab("Asylum Life")

local main = myTab:Section("Auto Escape")
main:Toggle("Enable Auto Escape", false)
main:Slider("Fly Speed", 94, 1, 10, 200, "")
main:Button("Reset Path", function()
    currentWaypoint = 1
    cooldownUntil = 0
end)

local info = myTab:Section("Status")
local statusLabel = info:Label("Status: Idle")
local cooldownLabel = info:Label("")

local function isAlive()
    local character = LocalPlayer.Character
    if not character then return false end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return false end
    return humanoid.Health > 0
end

local function set_noclip()
    local character = LocalPlayer.Character
    if character then
        for _, v in next, character:GetChildren() do
            if v:IsA("Part") or v:IsA("MeshPart") or v:IsA("BasePart") then
                v.CanCollide = false
            end
        end
    end
end

while true do
    local enabled = UI:GetValue("Asylum Life.Auto Escape.Enable Auto Escape")
    local speed = UI:GetValue("Asylum Life.Auto Escape.Fly Speed") or 74

    if enabled then
        if not isAlive() then
            if cooldownUntil > 0 then
                local remaining = cooldownUntil - tick()
                if remaining > 0 then
                    statusLabel:Set("Status: Dead, waiting for cooldown")
                    cooldownLabel:Set("Cooldown: " .. math.floor(remaining) .. "s")
                    task.wait(1)
                else
                    currentWaypoint = COOLDOWN_AT + 1
                    cooldownUntil = 0
                    cooldownLabel:Set("")
                    statusLabel:Set("Status: Cooldown done, resuming")
                end
            else
                currentWaypoint = 1
                needsCooldown = false
                statusLabel:Set("Status: Dead, restarting")
                task.wait(1)
            end
        else
            local character = LocalPlayer.Character
            local root = character:FindFirstChild("HumanoidRootPart")
            if root then
                set_noclip()

                local target = WAYPOINTS[currentWaypoint]
                if target then
                    local pos = root.Position
                    local direction = target - pos
                    local distance = direction.Magnitude

                    if distance < 5 then
                        local waitTime = WAIT_AT[currentWaypoint]
                        if waitTime then
                            statusLabel:Set("Status: Waiting " .. waitTime .. "s at WP" .. currentWaypoint)
                            root.Velocity = Vector3.new(0, 0, 0)
                            pcall(function() root.AssemblyLinearVelocity = Vector3.new(0, 0, 0) end)
                            task.wait(waitTime)
                        end

                        if currentWaypoint == COOLDOWN_AT and needsCooldown then
                            while cooldownUntil > tick() and UI:GetValue("Asylum Life.Auto Escape.Enable Auto Escape") do
                                local remaining = math.ceil(cooldownUntil - tick())
                                statusLabel:Set("Status: Hiding at safe spot")
                                cooldownLabel:Set("Cooldown: " .. remaining .. "s")
                                root.Velocity = Vector3.new(0, 0, 0)
                                pcall(function() root.AssemblyLinearVelocity = Vector3.new(0, 0, 0) end)
                                set_noclip()
                                if remaining % 30 == 0 then
                                    pcall(function() keypress(32) end)
                                    task.wait(0.1)
                                    pcall(function() keyrelease(32) end)
                                end
                                task.wait()
                            end
                            cooldownUntil = 0
                            needsCooldown = false
                            cooldownLabel:Set("")
                            statusLabel:Set("Status: Cooldown done, resuming")
                        end

                        currentWaypoint = currentWaypoint + 1
                        if currentWaypoint > #WAYPOINTS then
                            statusLabel:Set("Status: Waiting for teleport back...")
                            root.Velocity = Vector3.new(0, 0, 0)
                            pcall(function() root.AssemblyLinearVelocity = Vector3.new(0, 0, 0) end)
                            local exitDist = (root.Position - WAYPOINTS[#WAYPOINTS]).Magnitude
                            while exitDist < 50 and UI:GetValue("Asylum Life.Auto Escape.Enable Auto Escape") do
                                task.wait(0.5)
                                pcall(function() exitDist = (root.Position - WAYPOINTS[#WAYPOINTS]).Magnitude end)
                            end
                            currentWaypoint = 1
                            needsCooldown = true
                            cooldownUntil = tick() + 90
                            statusLabel:Set("Status: Escaped, 90s cooldown started")
                        else
                            statusLabel:Set("Status: Waypoint " .. currentWaypoint .. "/" .. #WAYPOINTS)
                        end
                    else
                        root.Velocity = direction.Unit * speed
                        statusLabel:Set("Status: Flying to WP" .. currentWaypoint .. " (" .. math.floor(distance) .. ")")
                    end
                end
            else
                statusLabel:Set("Status: No RootPart")
                task.wait(1)
            end
        end
    else
        currentWaypoint = 1
        cooldownUntil = 0
        needsCooldown = false
        cooldownLabel:Set("")
        statusLabel:Set("Status: Idle")
    end

    task.wait()
end
