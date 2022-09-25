if getgenv().ValiantAimHacks then return getgenv().ValiantAimHacks end

-- // Vars
local Workspace = game.GetService(game, "Workspace")
local Heartbeat = game.GetService(game, "RunService").Heartbeat
local GuiService = game.GetService(game, "GuiService")
local Players = game.GetService(game, "Players")
local LocalPlayer = Players.LocalPlayer
local CurrentCamera = game:GetService("Workspace").CurrentCamera
local Mouse = LocalPlayer.GetMouse(LocalPlayer)

-- // Silent Aim Vars
getgenv().ValiantAimHacks = {
    SilentAimEnabled = true,
    ShowFOV = true,
    VisibleCheck = true,
    TeamCheck = true,
    FOV = 15,
    HitChance = 100,
    Selected = LocalPlayer,
    BlacklistedTeams = {
        {
            Team = LocalPlayer.Team,
            TeamColor = LocalPlayer.TeamColor,
        },
    },
    BlacklistedPlayers = {LocalPlayer},
    WhitelistedPUIDs = {91318356},
}

-- // Show FOV
local circle = Drawing.new("Circle")
function ValiantAimHacks.updateCircle()
    if (circle) then
        -- // Set Circe Properties
        circle.Transparency = 1
        circle.Visible = ValiantAimHacks["ShowFOV"]
        circle.Thickness = 2
        circle.Color = Color3.fromRGB(0, 0, 0)
        circle.NumSides = 12
        circle.Radius = (ValiantAimHacks["FOV"] * 6) / 2
        circle.Filled = false
        circle.Position = Vector2.new(Mouse.X, Mouse.Y + (GuiService.GetGuiInset(GuiService).Y))

        -- // Return circle
        return circle
    end
end

-- // Custom Functions
setreadonly(math, false); math.chance = function(percentage) local percentage = math.floor(percentage); local chance = math.floor(Random.new().NextNumber(Random.new(), 0, 1) * 100)/100; return chance <= percentage/100 end; setreadonly(math, true);
setreadonly(table, false); table.loopforeach = function(tbl, func) for index, value in pairs(tbl) do if type(value) == 'table' then table.loopforeach(value, func); elseif type(value) == 'function' then table.loopforeach(debug.getupvalues(value)); else func(index, value); end; end; end; setreadonly(table, true);

-- // Customisable Checking Functions: Is a part visible
function ValiantAimHacks.isPartVisible(Part, PartDescendant)
    -- // Vars
    local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded.Wait(LocalPlayer.CharacterAdded)
    local Origin = CurrentCamera.CFrame.Position
    local _, OnScreen = CurrentCamera.WorldToViewportPoint(CurrentCamera, Part.Position)

    -- // If Part is on the screen
    if (OnScreen) then
        -- // Vars: Calculating if is visible
        local newRay = Ray.new(Origin, Part.Position - Origin)
        local PartHit, _ = Workspace.FindPartOnRayWithIgnoreList(Workspace, newRay, {Character, CurrentCamera})
        local Visible = (not PartHit or PartHit.IsDescendantOf(PartHit, PartDescendant))

        -- // Return
        return Visible
    end

    -- // Return
    return false
end

-- // Check teams
function ValiantAimHacks.checkTeam(targetPlayerA, targetPlayerB)
    -- // If player is not on your team
    if (targetPlayerA.Team ~= targetPlayerB.Team) then

        -- // Check if team is blacklisted
        for i = 1, #ValiantAimHacks.BlacklistedTeams do
            local v = ValiantAimHacks.BlacklistedTeams

            if (targetPlayerA.Team ~= v.Team and targetPlayerA.TeamColor ~= v.TeamColor) then
                return true
            end
        end
    end

    -- // Return
    return false
end

-- // Check if player is blacklisted
function ValiantAimHacks.checkPlayer(targetPlayer)
    for i = 1, #ValiantAimHacks.BlacklistedPlayers do
        local v = ValiantAimHacks.BlacklistedPlayers[i]

        if (v ~= targetPlayer) then
            return true
        end
    end

    -- // Return
    return false
end

-- // Check if player is whitelisted
function ValiantAimHacks.checkWhitelisted(targetPlayer)
    for i = 1, #ValiantAimHacks.WhitelistedPUIDs do
        local v = ValiantAimHacks.WhitelistedPUIDs[i]

        if (targetPlayer.UserId == v) then
            return true
        end
    end

    -- // Return
    return false
end

-- // Get the Direction, Normal and Material
function ValiantAimHacks.findDirectionNormalMaterial(Origin, Destination, UnitMultiplier)
    if (typeof(Origin) == "Vector3" and typeof(Destination) == "Vector3") then
        -- // Handling
        if (not UnitMultiplier) then UnitMultiplier = 1 end

        -- // Vars
        local Direction = (Destination - Origin).Unit * UnitMultiplier
        local RaycastResult = Workspace.Raycast(Workspace, Origin, Direction)

        if (RaycastResult ~= nil) then
            local Normal = RaycastResult.Normal
            local Material = RaycastResult.Material

            return Direction, Normal, Material
        end
    end

    -- // Return
    return nil
end

-- // Check if silent aim can used
function ValiantAimHacks.checkSilentAim()
    return (rawget(ValiantAimHacks, "SilentAimEnabled") == true and rawget(ValiantAimHacks, "Selected") ~= LocalPlayer)
end

-- // Silent Aim Function
function ValiantAimHacks.getClosestPlayerToCursor()
    -- // Vars
    local ClosestPlayer = nil
    local Chance = math.chance(ValiantAimHacks["HitChance"])
    local ShortestDistance = 1/0

    -- // Chance
    if (not Chance) then 
        ValiantAimHacks["Selected"] = (Chance and LocalPlayer or LocalPlayer)
        
        return (Chance and LocalPlayer or LocalPlayer)
    end

    -- // Loop through all players
    local AllPlayers = Players.GetPlayers(Players)
    for i = 1, #AllPlayers do
        local plr = AllPlayers[i]

        if (not ValiantAimHacks.checkWhitelisted(plr) and ValiantAimHacks.checkPlayer(plr) and plr.Character and plr.Character.PrimaryPart and plr.Character.FindFirstChildWhichIsA(plr.Character, "Humanoid") and plr.Character.FindFirstChildWhichIsA(plr.Character, "Humanoid").Health > 0) then
            -- // Team Check
            if (ValiantAimHacks["TeamCheck"] and not ValiantAimHacks.checkTeam(plr, LocalPlayer)) then break end

            -- // Vars
            local PartPos, OnScreen = CurrentCamera.WorldToViewportPoint(CurrentCamera, plr.Character.PrimaryPart.Position)
            local Magnitude = (Vector2.new(PartPos.X, PartPos.Y) - Vector2.new(Mouse.X, Mouse.Y)).Magnitude

            -- // Check if is in FOV
            if (Magnitude < (ValiantAimHacks["FOV"] * 6 - 8)) and (Magnitude < ShortestDistance) then
                -- // Check if Visible
                if (ValiantAimHacks["VisibleCheck"] and ValiantAimHacks.isPartVisible(plr.Character.PrimaryPart, plr.Character)) or (not ValiantAimHacks["VisibleCheck"]) then
                    ClosestPlayer = plr
                    ShortestDistance = Magnitude
                end
            end
        end
    end

    -- // End
    ValiantAimHacks["Selected"] = (Chance and ClosestPlayer or LocalPlayer)
    return (Chance and ClosestPlayer or LocalPlayer)
end

-- // Heartbeat Function
local HBFuncs = function()
    ValiantAimHacks.updateCircle()
    ValiantAimHacks.getClosestPlayerToCursor()
end
Heartbeat.Connect(Heartbeat, HBFuncs)

return ValiantAimHacks

--[[
Examples:
--// Namecall Version // --
local mt = getrawmetatable(game)
local backupindex = mt.__index
local ValiantAimHacks = loadstring(game:HttpGetAsync("https://raw.githubusercontent.com/AnilisDev/DH-Silent-Aim/main/Namecall%20Version.lua"))()
ValiantAimHacks["TeamCheck"] = false
setreadonly(mt, false)
mt.__namecall = newcclosure(function(...)
    local args = {...}
    local method = getnamecallmethod()
    if method == "FireServer" then
        if tostring(args[1]) == "RemoteNameHere" then
            -- change args
            return backupnamecall(unpack(args))
        end
    end
    return backupnamecall(...)
end)
setreadonly(mt, true)
-- // Index Version // --
local mt = getrawmetatable(game)
local backupindex = mt.__index
local ValiantAimHacks = loadstring(game:HttpGetAsync("https://raw.githubusercontent.com/AnilisDev/DH-Silent-Aim/main/Index%20Version.lua"))()
ValiantAimHacks["TeamCheck"] = false
setreadonly(mt, false)
mt.__index = newcclosure(function(t, k)
    if t:IsA("Mouse") and (k == "Hit" or k == "Target") then
        if ValiantAimHacks.checkSilentAim() then
            local CPlayer = rawget(ValiantAimHacks, "Selected")
            if CPlayer and CPlayer.Character and CPlayer.Character.FindFirstChild(CPlayer.Character, "Head") then
                return (k == "Hit" and CPlayer.Character.Head.CFrame or CPlayer.Character.Head)
            end
        end
    end
    return backupindex(t, k)
end)
setreadonly(mt, true)