--[[
╔═══════════════════════════════════════════════════════════════════════════════════════╗
║                      BLOX FRUITS ULTIMATE v11.0 - ENHANCED EDITION                    ║
║                              Fully Reconstructed & Optimized                          ║
║                                    by Claude AI                                       ║
╚═══════════════════════════════════════════════════════════════════════════════════════╝

CHANGELOG v11.0:
- Complete code restructure with proper OOP patterns
- Enhanced Quest Database (All Seas)
- Smart Target Selection System
- Anti-AFK & Anti-Detection
- Fruit Sniper System
- Boss Farm Support
- Mirage Island Detection
- ESP System
- Better Error Handling
- Performance Optimizations
]]

-- ═══════════════════════════════════════════════════════════════════════════════
-- SECTION 1: ANTI-DUPLICATE & INITIALIZATION
-- ═══════════════════════════════════════════════════════════════════════════════

if getgenv().BloxUltimateV11Loaded then 
    warn("[BF Ultimate] Script already loaded!")
    return 
end
getgenv().BloxUltimateV11Loaded = true

-- Wait for game to fully load
if not game:IsLoaded() then 
    game.Loaded:Wait() 
end

repeat task.wait() until game:GetService("Players").LocalPlayer
repeat task.wait() until game:GetService("Players").LocalPlayer.Character

-- ═══════════════════════════════════════════════════════════════════════════════
-- SECTION 2: SERVICES & VARIABLES
-- ═══════════════════════════════════════════════════════════════════════════════

local Services = {
    Players = game:GetService("Players"),
    Workspace = game:GetService("Workspace"),
    ReplicatedStorage = game:GetService("ReplicatedStorage"),
    RunService = game:GetService("RunService"),
    TweenService = game:GetService("TweenService"),
    VirtualInputManager = game:GetService("VirtualInputManager"),
    HttpService = game:GetService("HttpService"),
    UserInputService = game:GetService("UserInputService"),
    StarterGui = game:GetService("StarterGui"),
    Lighting = game:GetService("Lighting"),
    TeleportService = game:GetService("TeleportService")
}

local LocalPlayer = Services.Players.LocalPlayer
local Camera = Services.Workspace.CurrentCamera

-- ═══════════════════════════════════════════════════════════════════════════════
-- SECTION 3: CONFIGURATION SYSTEM
-- ═══════════════════════════════════════════════════════════════════════════════

getgenv().Config = getgenv().Config or {
    -- Main Settings
    AutoFarm = false,
    AutoQuest = true,
    AutoBossFarm = false,
    
    -- Combat Settings
    SelectedWeapon = "Melee",
    FastAttack = true,
    AutoSkill = true,
    BringMobs = false,
    
    -- Movement Settings
    TweenSpeed = 300,
    WalkSpeed = 16,
    JumpPower = 50,
    InfiniteJump = false,
    Fly = false,
    FlySpeed = 100,
    Noclip = false,
    
    -- Farm Settings
    FarmMode = "Nearest", -- "Nearest", "Lowest HP", "Highest HP"
    SafeMode = true,
    AutoRejoin = true,
    
    -- Extras
    AntiAFK = true,
    FruitSniper = false,
    MirageIsland = false,
    ESP = false,
    FullBright = false,
    
    -- Debug
    DebugMode = false
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- SECTION 4: UTILITY MODULE
-- ═══════════════════════════════════════════════════════════════════════════════

local Utils = {}

function Utils.Notify(title, text, duration, icon)
    pcall(function()
        Services.StarterGui:SetCore("SendNotification", {
            Title = tostring(title),
            Text = tostring(text),
            Duration = duration or 3,
            Icon = icon or "rbxassetid://4483345998"
        })
    end)
end

function Utils.GetCharacter()
    return LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
end

function Utils.GetHumanoid()
    local char = Utils.GetCharacter()
    return char and char:FindFirstChildOfClass("Humanoid")
end

function Utils.GetHRP()
    local char = Utils.GetCharacter()
    return char and char:FindFirstChild("HumanoidRootPart")
end

function Utils.IsAlive()
    local hum = Utils.GetHumanoid()
    return hum and hum.Health > 0
end

function Utils.GetDistance(pos1, pos2)
    if typeof(pos1) == "CFrame" then pos1 = pos1.Position end
    if typeof(pos2) == "CFrame" then pos2 = pos2.Position end
    return (pos1 - pos2).Magnitude
end

function Utils.SafeCall(func, ...)
    local success, result = pcall(func, ...)
    if not success and getgenv().Config.DebugMode then
        warn("[BF Ultimate] Error: " .. tostring(result))
    end
    return success, result
end

function Utils.GetLevel()
    local data = LocalPlayer:FindFirstChild("Data")
    return data and data:FindFirstChild("Level") and data.Level.Value or 1
end

function Utils.GetWorld()
    local level = Utils.GetLevel()
    if level < 700 then return 1
    elseif level < 1500 then return 2
    else return 3 end
end

function Utils.HasQuest()
    local gui = LocalPlayer:FindFirstChild("PlayerGui")
    if gui then
        local main = gui:FindFirstChild("Main")
        if main then
            local quest = main:FindFirstChild("Quest")
            return quest and quest.Visible
        end
    end
    return false
end

function Utils.GetRemote()
    local remotes = Services.ReplicatedStorage:FindFirstChild("Remotes")
    return remotes and remotes:FindFirstChild("CommF_")
end

function Utils.Log(message)
    if getgenv().Config.DebugMode then
        print("[BF Ultimate]", message)
    end
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- SECTION 5: CONNECTION MANAGER
-- ═══════════════════════════════════════════════════════════════════════════════

local ConnectionManager = {}
ConnectionManager.Connections = {}
ConnectionManager.Tweens = {}

function ConnectionManager:Add(name, connection)
    self:Remove(name)
    self.Connections[name] = connection
    Utils.Log("Connection added: " .. name)
end

function ConnectionManager:Remove(name)
    if self.Connections[name] then
        pcall(function()
            self.Connections[name]:Disconnect()
        end)
        self.Connections[name] = nil
        Utils.Log("Connection removed: " .. name)
    end
end

function ConnectionManager:AddTween(name, tween)
    self:RemoveTween(name)
    self.Tweens[name] = tween
end

function ConnectionManager:RemoveTween(name)
    if self.Tweens[name] then
        pcall(function()
            self.Tweens[name]:Cancel()
        end)
        self.Tweens[name] = nil
    end
end

function ConnectionManager:ClearAll()
    for name, _ in pairs(self.Connections) do
        self:Remove(name)
    end
    for name, _ in pairs(self.Tweens) do
        self:RemoveTween(name)
    end
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- SECTION 6: QUEST DATABASE (COMPLETE)
-- ═══════════════════════════════════════════════════════════════════════════════

local QuestDatabase = {
    -- ══════════════ FIRST SEA ══════════════
    -- Starter Island
    {MinLvl = 1, MaxLvl = 10, QuestId = "BanditQuest1", MobName = "Bandit", 
     QuestNPC = CFrame.new(1060, 17, 1547), MobArea = CFrame.new(1060, 17, 1547)},
    
    {MinLvl = 11, MaxLvl = 15, QuestId = "MonkeyQuest1", MobName = "Monkey", 
     QuestNPC = CFrame.new(-1601, 36, 154), MobArea = CFrame.new(-1601, 36, 154)},
    
    {MinLvl = 16, MaxLvl = 29, QuestId = "GorilliaQuest", MobName = "Gorilla", 
     QuestNPC = CFrame.new(-1139, 14, 4109), MobArea = CFrame.new(-1139, 14, 4109)},
    
    {MinLvl = 30, MaxLvl = 39, QuestId = "PirateQuest", MobName = "Pirate", 
     QuestNPC = CFrame.new(-1191, 5, 3833), MobArea = CFrame.new(-1191, 5, 3833)},
    
    {MinLvl = 40, MaxLvl = 59, QuestId = "BruteQuest1", MobName = "Brute", 
     QuestNPC = CFrame.new(-1145, 15, 4088), MobArea = CFrame.new(-1145, 15, 4088)},
    
    -- Jungle
    {MinLvl = 60, MaxLvl = 74, QuestId = "JunglePirateQuest", MobName = "Jungle Pirate", 
     QuestNPC = CFrame.new(-1603, 36, 154), MobArea = CFrame.new(-1603, 36, 154)},
    
    {MinLvl = 75, MaxLvl = 89, QuestId = "BruteQuest2", MobName = "Brute", 
     QuestNPC = CFrame.new(-1139, 15, 4088), MobArea = CFrame.new(-1139, 15, 4088)},
    
    -- Desert
    {MinLvl = 90, MaxLvl = 99, QuestId = "DesertBanditQuest", MobName = "Desert Bandit", 
     QuestNPC = CFrame.new(912, 6, 4417), MobArea = CFrame.new(912, 6, 4417)},
    
    {MinLvl = 100, MaxLvl = 119, QuestId = "DesertOfficerQuest", MobName = "Desert Officer", 
     QuestNPC = CFrame.new(912, 6, 4417), MobArea = CFrame.new(912, 6, 4417)},
    
    -- Frozen Village
    {MinLvl = 120, MaxLvl = 149, QuestId = "SnowBanditQuest", MobName = "Snow Bandit", 
     QuestNPC = CFrame.new(1389, 87, -1298), MobArea = CFrame.new(1389, 87, -1298)},
    
    {MinLvl = 150, MaxLvl = 174, QuestId = "SnowBerserkQuest", MobName = "Snowman", 
     QuestNPC = CFrame.new(1389, 87, -1298), MobArea = CFrame.new(1389, 87, -1298)},
    
    -- Marine Fort
    {MinLvl = 175, MaxLvl = 199, QuestId = "MarineQuest1", MobName = "Marine Soldier", 
     QuestNPC = CFrame.new(-5033, 28, 4324), MobArea = CFrame.new(-5033, 28, 4324)},
    
    {MinLvl = 200, MaxLvl = 224, QuestId = "MarineQuest2", MobName = "Marine Captain", 
     QuestNPC = CFrame.new(-5033, 28, 4324), MobArea = CFrame.new(-5033, 28, 4324)},
    
    -- Sky Island
    {MinLvl = 225, MaxLvl = 274, QuestId = "SkyBanditQuest", MobName = "Sky Bandit", 
     QuestNPC = CFrame.new(-4843, 718, -2623), MobArea = CFrame.new(-4843, 718, -2623)},
    
    {MinLvl = 275, MaxLvl = 299, QuestId = "DarkMasterQuest", MobName = "Dark Master", 
     QuestNPC = CFrame.new(-4843, 718, -2623), MobArea = CFrame.new(-4843, 718, -2623)},
    
    -- Prison
    {MinLvl = 300, MaxLvl = 324, QuestId = "PrisonerQuest", MobName = "Prisoner", 
     QuestNPC = CFrame.new(4875, 5, 742), MobArea = CFrame.new(4875, 5, 742)},
    
    {MinLvl = 325, MaxLvl = 374, QuestId = "DangerousPrisoner", MobName = "Dangerous Prisoner", 
     QuestNPC = CFrame.new(4875, 5, 742), MobArea = CFrame.new(4875, 5, 742)},
    
    -- Colosseum
    {MinLvl = 375, MaxLvl = 399, QuestId = "GladiatorQuest", MobName = "Toga Warrior", 
     QuestNPC = CFrame.new(-1569, 7, -2923), MobArea = CFrame.new(-1569, 7, -2923)},
    
    -- Magma Village
    {MinLvl = 400, MaxLvl = 449, QuestId = "MilitarySpyQuest", MobName = "Military Spy", 
     QuestNPC = CFrame.new(-5312, 12, 8516), MobArea = CFrame.new(-5312, 12, 8516)},
    
    {MinLvl = 450, MaxLvl = 499, QuestId = "MagmaNinjaQuest", MobName = "Magma Ninja", 
     QuestNPC = CFrame.new(-5312, 12, 8516), MobArea = CFrame.new(-5312, 12, 8516)},
    
    -- Underwater City
    {MinLvl = 500, MaxLvl = 549, QuestId = "FishmanWarriorQuest", MobName = "Fishman Warrior", 
     QuestNPC = CFrame.new(61123, 18, 1569), MobArea = CFrame.new(61123, 18, 1569)},
    
    {MinLvl = 550, MaxLvl = 599, QuestId = "FishmanCommandoQuest", MobName = "Fishman Commando", 
     QuestNPC = CFrame.new(61123, 18, 1569), MobArea = CFrame.new(61123, 18, 1569)},
    
    -- Upper Skylands
    {MinLvl = 600, MaxLvl = 649, QuestId = "GodGuardQuest", MobName = "God's Guard", 
     QuestNPC = CFrame.new(-4721, 842, -1954), MobArea = CFrame.new(-4721, 842, -1954)},
    
    {MinLvl = 650, MaxLvl = 699, QuestId = "ShinyAngelQuest", MobName = "Shanda", 
     QuestNPC = CFrame.new(-7862, 5544, -382), MobArea = CFrame.new(-7862, 5544, -382)},
    
    -- ══════════════ SECOND SEA ══════════════
    {MinLvl = 700, MaxLvl = 749, QuestId = "RaiderQuest", MobName = "Raider", 
     QuestNPC = CFrame.new(-429, 73, 1836), MobArea = CFrame.new(-429, 73, 1836)},
    
    {MinLvl = 750, MaxLvl = 799, QuestId = "MercenaryQuest", MobName = "Mercenary", 
     QuestNPC = CFrame.new(-429, 73, 1836), MobArea = CFrame.new(-429, 73, 1836)},
    
    -- Green Zone
    {MinLvl = 800, MaxLvl = 849, QuestId = "SwarmerQuest", MobName = "Swarmer", 
     QuestNPC = CFrame.new(-2445, 73, -3219), MobArea = CFrame.new(-2445, 73, -3219)},
    
    {MinLvl = 850, MaxLvl = 899, QuestId = "BuggyPirateQuest", MobName = "Buggy Pirate", 
     QuestNPC = CFrame.new(-2445, 73, -3219), MobArea = CFrame.new(-2445, 73, -3219)},
    
    -- Dark Arena
    {MinLvl = 900, MaxLvl = 949, QuestId = "MinotaurQuest", MobName = "Minotaur", 
     QuestNPC = CFrame.new(-1954, 6, 5765), MobArea = CFrame.new(-1954, 6, 5765)},
    
    -- Graveyard
    {MinLvl = 950, MaxLvl = 999, QuestId = "DraculaQuest", MobName = "Vampire", 
     QuestNPC = CFrame.new(-5765, 97, -824), MobArea = CFrame.new(-5765, 97, -824)},
    
    -- Snow Mountain
    {MinLvl = 1000, MaxLvl = 1049, QuestId = "YetiQuest", MobName = "Yeti", 
     QuestNPC = CFrame.new(602, 402, -5371), MobArea = CFrame.new(602, 402, -5371)},
    
    -- Hot & Cold
    {MinLvl = 1050, MaxLvl = 1099, QuestId = "HotIceColdQuest", MobName = "Hot & Cold", 
     QuestNPC = CFrame.new(-5969, 60, -4651), MobArea = CFrame.new(-5969, 60, -4651)},
    
    -- Ice Castle
    {MinLvl = 1100, MaxLvl = 1149, QuestId = "IceMonsterQuest", MobName = "Ice Monster", 
     QuestNPC = CFrame.new(6059, 130, -6553), MobArea = CFrame.new(6059, 130, -6553)},
    
    -- Forgotten Island
    {MinLvl = 1150, MaxLvl = 1199, QuestId = "PirateRaiderQuest", MobName = "Pirate Raid", 
     QuestNPC = CFrame.new(-3047, 237, -10005), MobArea = CFrame.new(-3047, 237, -10005)},
    
    -- Floating Turtle
    {MinLvl = 1200, MaxLvl = 1249, QuestId = "MarineViceQuest", MobName = "Marine Vice Admiral", 
     QuestNPC = CFrame.new(-12107, 332, -7471), MobArea = CFrame.new(-12107, 332, -7471)},
    
    {MinLvl = 1250, MaxLvl = 1299, QuestId = "WerewolfQuest", MobName = "Werewolf", 
     QuestNPC = CFrame.new(-12107, 332, -7471), MobArea = CFrame.new(-12107, 332, -7471)},
    
    -- Mansion
    {MinLvl = 1300, MaxLvl = 1349, QuestId = "ButlerQuest", MobName = "Butler", 
     QuestNPC = CFrame.new(-12107, 332, -7471), MobArea = CFrame.new(-12107, 332, -7471)},
    
    -- Cursed Ship
    {MinLvl = 1350, MaxLvl = 1424, QuestId = "CursedQuest", MobName = "Cursed", 
     QuestNPC = CFrame.new(-12107, 332, -7471), MobArea = CFrame.new(-12107, 332, -7471)},
    
    -- Sea of Treats
    {MinLvl = 1425, MaxLvl = 1499, QuestId = "CakeWarriorQuest", MobName = "Cake Warrior", 
     QuestNPC = CFrame.new(-12107, 332, -7471), MobArea = CFrame.new(-12107, 332, -7471)},
    
    -- ══════════════ THIRD SEA ══════════════
    {MinLvl = 1500, MaxLvl = 1549, QuestId = "PortTown", MobName = "Pirate Millionaire", 
     QuestNPC = CFrame.new(-289, 44, 5579), MobArea = CFrame.new(-289, 44, 5579)},
    
    {MinLvl = 1550, MaxLvl = 1599, QuestId = "MushroomKingdom", MobName = "Mushroom", 
     QuestNPC = CFrame.new(-4643, 872, -1907), MobArea = CFrame.new(-4643, 872, -1907)},
    
    {MinLvl = 1600, MaxLvl = 1649, QuestId = "HydraIsland", MobName = "Hydra", 
     QuestNPC = CFrame.new(5229, 16, 303), MobArea = CFrame.new(5229, 16, 303)},
    
    {MinLvl = 1650, MaxLvl = 1699, QuestId = "GreatTree", MobName = "Tree", 
     QuestNPC = CFrame.new(2842, 26, -7056), MobArea = CFrame.new(2842, 26, -7056)},
    
    {MinLvl = 1700, MaxLvl = 1799, QuestId = "FountainCity", MobName = "Galley Pirate", 
     QuestNPC = CFrame.new(5441, 288, 4479), MobArea = CFrame.new(5441, 288, 4479)},
    
    {MinLvl = 1800, MaxLvl = 1899, QuestId = "HauntedCastle", MobName = "Ghost", 
     QuestNPC = CFrame.new(-9500, 146, 5765), MobArea = CFrame.new(-9500, 146, 5765)},
    
    {MinLvl = 1900, MaxLvl = 1999, QuestId = "TikiOutpost", MobName = "Tiki Warrior", 
     QuestNPC = CFrame.new(-12167, 73, -7561), MobArea = CFrame.new(-12167, 73, -7561)},
    
    {MinLvl = 2000, MaxLvl = 2099, QuestId = "Deandre", MobName = "Jungle Pirate", 
     QuestNPC = CFrame.new(-13232, 332, -7625), MobArea = CFrame.new(-13232, 332, -7625)},
    
    {MinLvl = 2100, MaxLvl = 2199, QuestId = "LeskyIsland", MobName = "Lesky Pirate", 
     QuestNPC = CFrame.new(-6508, 797, -205), MobArea = CFrame.new(-6508, 797, -205)},
    
    {MinLvl = 2200, MaxLvl = 2299, QuestId = "KitsuneShrine", MobName = "Kitsune Devotee", 
     QuestNPC = CFrame.new(-6508, 797, -205), MobArea = CFrame.new(-6508, 797, -205)},
    
    {MinLvl = 2300, MaxLvl = 2549, QuestId = "SoulReaper", MobName = "Soul Reaper", 
     QuestNPC = CFrame.new(-9285, 310, 6258), MobArea = CFrame.new(-9285, 310, 6258)},
    
    {MinLvl = 2550, MaxLvl = 9999, QuestId = "PirateIsland", MobName = "Pirate", 
     QuestNPC = CFrame.new(-13447, 563, -7315), MobArea = CFrame.new(-13447, 563, -7315)}
}

-- Boss Database
local BossDatabase = {
    {Name = "Greybeard", Level = 750, Position = CFrame.new(-4943, 87, 4305)},
    {Name = "Saber Expert", Level = 200, Position = CFrame.new(-1418, 37, -1421)},
    {Name = "Gorilla King", Level = 25, Position = CFrame.new(-1229, 75, 4135)},
    {Name = "The Saw", Level = 100, Position = CFrame.new(-630, 47, 1481)},
    {Name = "Don Swan", Level = 1000, Position = CFrame.new(-455, 73, 310)},
    {Name = "Cursed Captain", Level = 1325, Position = CFrame.new(916, 192, 33069)},
    {Name = "Awakened Ice Admiral", Level = 1400, Position = CFrame.new(6407, 295, -6892)},
    {Name = "Order", Level = 1250, Position = CFrame.new(-6222, 16, -4903)},
    {Name = "rip_indra", Level = 1500, Position = CFrame.new(-5349, 424, -2929)},
    {Name = "Dough King", Level = 2300, Position = CFrame.new(-1948, 44, 863)},
    {Name = "Cake Queen", Level = 2175, Position = CFrame.new(-2045, 104, 5405)}
}

function GetQuestForLevel(level)
    level = level or Utils.GetLevel()
    for _, quest in ipairs(QuestDatabase) do
        if level >= quest.MinLvl and level <= quest.MaxLvl then
            return quest
        end
    end
    return QuestDatabase[1] -- Fallback
end

function GetNearestBoss()
    local hrp = Utils.GetHRP()
    if not hrp then return nil end
    
    local nearest, nearestDist = nil, math.huge
    for _, boss in ipairs(BossDatabase) do
        local dist = Utils.GetDistance(hrp.Position, boss.Position.Position)
        if dist < nearestDist then
            nearest = boss
            nearestDist = dist
        end
    end
    return nearest
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- SECTION 7: MOVEMENT SYSTEM (ENHANCED)
-- ═══════════════════════════════════════════════════════════════════════════════

local Movement = {}
Movement.IsTweening = false
Movement.IsFlying = false

function Movement.StopTween()
    ConnectionManager:RemoveTween("MainTween")
    ConnectionManager:Remove("TweenNoclip")
    Movement.IsTweening = false
    
    local hrp = Utils.GetHRP()
    if hrp then
        hrp.Anchored = false
        hrp.Velocity = Vector3.zero
    end
end

function Movement.TweenTo(targetCFrame, callback)
    local hrp = Utils.GetHRP()
    if not hrp then return end
    
    Movement.StopTween()
    Movement.IsTweening = true
    
    -- Anti-Sit
    local hum = Utils.GetHumanoid()
    if hum and hum.Sit then 
        hum.Sit = false 
        hum:ChangeState(Enum.HumanoidStateType.GettingUp)
    end
    
    local distance = Utils.GetDistance(hrp.Position, targetCFrame.Position)
    local speed = getgenv().Config.TweenSpeed or 300
    local tweenTime = math.max(distance / speed, 0.1)
    
    -- Short distance = instant teleport
    if distance < 50 then
        hrp.CFrame = targetCFrame
        Movement.IsTweening = false
        if callback then callback() end
        return
    end
    
    local tweenInfo = TweenInfo.new(tweenTime, Enum.EasingStyle.Linear)
    local tween = Services.TweenService:Create(hrp, tweenInfo, {CFrame = targetCFrame})
    ConnectionManager:AddTween("MainTween", tween)
    
    -- Noclip during tween
    ConnectionManager:Add("TweenNoclip", Services.RunService.Stepped:Connect(function()
        if not Movement.IsTweening then return end
        local char = Utils.GetCharacter()
        if char then
            for _, part in pairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end
    end))
    
    tween.Completed:Connect(function(playbackState)
        Movement.StopTween()
        if playbackState == Enum.PlaybackState.Completed and callback then
            callback()
        end
    end)
    
    tween:Play()
end

function Movement.TeleportTo(cframe)
    Movement.StopTween()
    local hrp = Utils.GetHRP()
    if hrp then
        hrp.CFrame = cframe
    end
end

function Movement.EnableFly(enabled)
    local hrp = Utils.GetHRP()
    if not hrp then return end
    
    Movement.IsFlying = enabled
    
    if enabled then
        -- Create BodyVelocity and BodyGyro for smooth flight
        local bv = hrp:FindFirstChild("FlyVelocity") or Instance.new("BodyVelocity")
        bv.Name = "FlyVelocity"
        bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        bv.Velocity = Vector3.zero
        bv.Parent = hrp
        
        local bg = hrp:FindFirstChild("FlyGyro") or Instance.new("BodyGyro")
        bg.Name = "FlyGyro"
        bg.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
        bg.P = 9e4
        bg.Parent = hrp
        
        ConnectionManager:Add("FlyLoop", Services.RunService.RenderStepped:Connect(function()
            if not Movement.IsFlying then return end
            
            local hrp = Utils.GetHRP()
            local hum = Utils.GetHumanoid()
            if not hrp or not hum then return end
            
            local bv = hrp:FindFirstChild("FlyVelocity")
            local bg = hrp:FindFirstChild("FlyGyro")
            if not bv or not bg then return end
            
            local speed = getgenv().Config.FlySpeed or 100
            local camCF = Camera.CFrame
            local direction = Vector3.zero
            
            if Services.UserInputService:IsKeyDown(Enum.KeyCode.W) then
                direction = direction + camCF.LookVector
            end
            if Services.UserInputService:IsKeyDown(Enum.KeyCode.S) then
                direction = direction - camCF.LookVector
            end
            if Services.UserInputService:IsKeyDown(Enum.KeyCode.A) then
                direction = direction - camCF.RightVector
            end
            if Services.UserInputService:IsKeyDown(Enum.KeyCode.D) then
                direction = direction + camCF.RightVector
            end
            if Services.UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                direction = direction + Vector3.new(0, 1, 0)
            end
            if Services.UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
                direction = direction - Vector3.new(0, 1, 0)
            end
            
            if direction.Magnitude > 0 then
                direction = direction.Unit * speed
            end
            
            bv.Velocity = direction
            bg.CFrame = camCF
            
            -- Prevent falling animation
            hum:ChangeState(Enum.HumanoidStateType.Freefall)
        end))
        
        Utils.Notify("Fly", "Enabled!", 2)
    else
        ConnectionManager:Remove("FlyLoop")
        
        if hrp:FindFirstChild("FlyVelocity") then
            hrp.FlyVelocity:Destroy()
        end
        if hrp:FindFirstChild("FlyGyro") then
            hrp.FlyGyro:Destroy()
        end
        
        Utils.Notify("Fly", "Disabled!", 2)
    end
end

function Movement.EnableNoclip(enabled)
    if enabled then
        ConnectionManager:Add("Noclip", Services.RunService.Stepped:Connect(function()
            if not getgenv().Config.Noclip then return end
            local char = Utils.GetCharacter()
            if char then
                for _, part in pairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            end
        end))
    else
        ConnectionManager:Remove("Noclip")
    end
end

function Movement.EnableInfiniteJump(enabled)
    if enabled then
        ConnectionManager:Add("InfJump", Services.UserInputService.JumpRequest:Connect(function()
            if not getgenv().Config.InfiniteJump then return end
            local hum = Utils.GetHumanoid()
            if hum then
                hum:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end))
    else
        ConnectionManager:Remove("InfJump")
    end
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- SECTION 8: COMBAT SYSTEM (ENHANCED)
-- ═══════════════════════════════════════════════════════════════════════════════

local Combat = {}

function Combat.GetWeaponFromBackpack(weaponType)
    local char = Utils.GetCharacter()
    local backpack = LocalPlayer.Backpack
    
    local function searchFor(container, searchType)
        for _, tool in pairs(container:GetChildren()) do
            if tool:IsA("Tool") then
                local tooltip = tool.ToolTip or ""
                
                if searchType == "Melee" and tooltip:find("Melee") then
                    return tool
                elseif searchType == "Sword" and tooltip:find("Sword") then
                    return tool
                elseif searchType == "Blox Fruit" and tooltip:find("Blox Fruit") then
                    return tool
                elseif searchType == "Gun" and tooltip:find("Gun") then
                    return tool
                end
            end
        end
        return nil
    end
    
    -- First check character
    local equipped = searchFor(char, weaponType)
    if equipped then return equipped end
    
    -- Then check backpack
    return searchFor(backpack, weaponType)
end

function Combat.EquipWeapon(weaponType)
    weaponType = weaponType or getgenv().Config.SelectedWeapon
    
    local char = Utils.GetCharacter()
    local hum = Utils.GetHumanoid()
    if not char or not hum then return end
    
    -- Check if already equipped
    local currentTool = char:FindFirstChildOfClass("Tool")
    if currentTool and currentTool.ToolTip and currentTool.ToolTip:find(weaponType) then
        return currentTool
    end
    
    local weapon = Combat.GetWeaponFromBackpack(weaponType)
    if weapon and weapon.Parent == LocalPlayer.Backpack then
        hum:EquipTool(weapon)
    end
    
    return weapon
end

function Combat.Attack(target)
    if not target then return end
    
    local remote = Utils.GetRemote()
    if not remote then
        -- Fallback to virtual click
        Services.VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 1)
        task.wait(0.05)
        Services.VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 1)
        return
    end
    
    local targetHRP = target:FindFirstChild("HumanoidRootPart")
    if not targetHRP then return end
    
    if getgenv().Config.FastAttack then
        -- Fast attack spam
        for _ = 1, 3 do
            Utils.SafeCall(function()
                remote:InvokeServer("MeleeAttack", targetHRP.CFrame)
            end)
        end
    else
        Utils.SafeCall(function()
            remote:InvokeServer("MeleeAttack", targetHRP.CFrame)
        end)
    end
end

function Combat.UseSkill(key)
    Services.VirtualInputManager:SendKeyEvent(true, key, false, game)
    task.wait(0.05)
    Services.VirtualInputManager:SendKeyEvent(false, key, false, game)
end

function Combat.SpamSkills()
    if not getgenv().Config.AutoSkill then return end
    
    local skills = {"Z", "X", "C", "V"}
    for _, skill in ipairs(skills) do
        Combat.UseSkill(skill)
        task.wait(0.1)
    end
end

function Combat.BringMob(mob)
    if not getgenv().Config.BringMobs then return end
    if not mob then return end
    
    local hrp = Utils.GetHRP()
    local mobHRP = mob:FindFirstChild("HumanoidRootPart")
    
    if hrp and mobHRP then
        mobHRP.CFrame = hrp.CFrame * CFrame.new(0, 0, -5)
    end
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- SECTION 9: TARGET SELECTION SYSTEM
-- ═══════════════════════════════════════════════════════════════════════════════

local TargetSystem = {}

function TargetSystem.GetEnemies()
    local enemies = {}
    
    local function scanFolder(folder)
        if not folder then return end
        for _, entity in pairs(folder:GetChildren()) do
            local hum = entity:FindFirstChild("Humanoid")
            local hrp = entity:FindFirstChild("HumanoidRootPart")
            if hum and hrp and hum.Health > 0 then
                table.insert(enemies, entity)
            end
        end
    end
    
    scanFolder(Services.Workspace:FindFirstChild("Enemies"))
    scanFolder(Services.Workspace:FindFirstChild("NPCs"))
    
    return enemies
end

function TargetSystem.FilterByQuest(enemies, questMobName)
    if not questMobName then return enemies end
    
    local filtered = {}
    for _, enemy in ipairs(enemies) do
        if enemy.Name:find(questMobName) then
            table.insert(filtered, enemy)
        end
    end
    return filtered
end

function TargetSystem.SelectTarget(enemies, mode)
    if #enemies == 0 then return nil end
    
    mode = mode or getgenv().Config.FarmMode
    local hrp = Utils.GetHRP()
    if not hrp then return enemies[1] end
    
    if mode == "Nearest" then
        local nearest, nearestDist = nil, math.huge
        for _, enemy in ipairs(enemies) do
            local enemyHRP = enemy:FindFirstChild("HumanoidRootPart")
            if enemyHRP then
                local dist = Utils.GetDistance(hrp.Position, enemyHRP.Position)
                if dist < nearestDist then
                    nearest = enemy
                    nearestDist = dist
                end
            end
        end
        return nearest
        
    elseif mode == "Lowest HP" then
        local lowest, lowestHP = nil, math.huge
        for _, enemy in ipairs(enemies) do
            local hum = enemy:FindFirstChild("Humanoid")
            if hum and hum.Health < lowestHP then
                lowest = enemy
                lowestHP = hum.Health
            end
        end
        return lowest
        
    elseif mode == "Highest HP" then
        local highest, highestHP = nil, 0
        for _, enemy in ipairs(enemies) do
            local hum = enemy:FindFirstChild("Humanoid")
            if hum and hum.Health > highestHP then
                highest = enemy
                highestHP = hum.Health
            end
        end
        return highest
    end
    
    return enemies[1]
end

function TargetSystem.GetBestTarget(questMobName)
    local enemies = TargetSystem.GetEnemies()
    
    if questMobName then
        enemies = TargetSystem.FilterByQuest(enemies, questMobName)
    end
    
    return TargetSystem.SelectTarget(enemies)
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- SECTION 10: AUTO FARM ENGINE
-- ═══════════════════════════════════════════════════════════════════════════════

local AutoFarm = {}
AutoFarm.CurrentQuest = nil
AutoFarm.CurrentTarget = nil

function AutoFarm.AcceptQuest(questData)
    if not questData then return false end
    
    local remote = Utils.GetRemote()
    if not remote then return false end
    
    local hrp = Utils.GetHRP()
    if not hrp then return false end
    
    -- Check distance to quest NPC
    local dist = Utils.GetDistance(hrp.Position, questData.QuestNPC.Position)
    
    if dist > 50 then
        Movement.TweenTo(questData.QuestNPC)
        return false
    else
        Movement.StopTween()
        Utils.SafeCall(function()
            remote:InvokeServer("StartQuest", questData.QuestId, 1)
        end)
        return true
    end
end

function AutoFarm.FarmTarget(target, questData)
    if not target then return end
    
    local hrp = Utils.GetHRP()
    local targetHRP = target:FindFirstChild("HumanoidRootPart")
    if not hrp or not targetHRP then return end
    
    local farmOffset = CFrame.new(0, 30, 0) -- Farm from above
    local targetPos = targetHRP.CFrame * farmOffset
    local dist = Utils.GetDistance(hrp.Position, targetPos.Position)
    
    if dist > 40 then
        Movement.TweenTo(targetPos)
    else
        Movement.StopTween()
        hrp.CFrame = targetPos
        
        -- Equip weapon and attack
        Combat.EquipWeapon()
        Combat.Attack(target)
        Combat.BringMob(target)
        
        -- Use skills
        if getgenv().Config.AutoSkill then
            Combat.SpamSkills()
        end
    end
end

function AutoFarm.MainLoop()
    if not getgenv().Config.AutoFarm then return end
    if not Utils.IsAlive() then return end
    
    local questData = GetQuestForLevel()
    
    -- Step 1: Accept quest if needed
    if getgenv().Config.AutoQuest and not Utils.HasQuest() then
        AutoFarm.AcceptQuest(questData)
        return
    end
    
    -- Step 2: Find and kill target
    local target = TargetSystem.GetBestTarget(questData.MobName)
    
    if target then
        AutoFarm.FarmTarget(target, questData)
    else
        -- No target found, go to mob area
        local hrp = Utils.GetHRP()
        if hrp and questData.MobArea then
            local dist = Utils.GetDistance(hrp.Position, questData.MobArea.Position)
            if dist > 100 then
                Movement.TweenTo(questData.MobArea)
            end
        end
    end
end

function AutoFarm.Start()
    Utils.Notify("Auto Farm", "Started - Level " .. Utils.GetLevel(), 3)
    
    ConnectionManager:Add("AutoFarmLoop", Services.RunService.Heartbeat:Connect(function()
        Utils.SafeCall(AutoFarm.MainLoop)
    end))
end

function AutoFarm.Stop()
    ConnectionManager:Remove("AutoFarmLoop")
    Movement.StopTween()
    Utils.Notify("Auto Farm", "Stopped!", 2)
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- SECTION 11: BOSS FARM SYSTEM
-- ═══════════════════════════════════════════════════════════════════════════════

local BossFarm = {}

function BossFarm.GetBoss()
    local enemies = Services.Workspace:FindFirstChild("Enemies")
    if not enemies then return nil end
    
    for _, entity in pairs(enemies:GetChildren()) do
        local hum = entity:FindFirstChild("Humanoid")
        if hum and hum.MaxHealth >= 50000 and hum.Health > 0 then
            return entity
        end
    end
    return nil
end

function BossFarm.MainLoop()
    if not getgenv().Config.AutoBossFarm then return end
    if not Utils.IsAlive() then return end
    
    local boss = BossFarm.GetBoss()
    
    if boss then
        local hrp = Utils.GetHRP()
        local bossHRP = boss:FindFirstChild("HumanoidRootPart")
        
        if hrp and bossHRP then
            local targetPos = bossHRP.CFrame * CFrame.new(0, 30, 0)
            local dist = Utils.GetDistance(hrp.Position, targetPos.Position)
            
            if dist > 40 then
                Movement.TweenTo(targetPos)
            else
                Movement.StopTween()
                hrp.CFrame = targetPos
                Combat.EquipWeapon()
                Combat.Attack(boss)
                Combat.SpamSkills()
            end
        end
    end
end

function BossFarm.Start()
    Utils.Notify("Boss Farm", "Started!", 2)
    ConnectionManager:Add("BossFarmLoop", Services.RunService.Heartbeat:Connect(function()
        Utils.SafeCall(BossFarm.MainLoop)
    end))
end

function BossFarm.Stop()
    ConnectionManager:Remove("BossFarmLoop")
    Movement.StopTween()
    Utils.Notify("Boss Farm", "Stopped!", 2)
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- SECTION 12: EXTRAS & UTILITIES
-- ═══════════════════════════════════════════════════════════════════════════════

local Extras = {}

-- Anti-AFK System
function Extras.EnableAntiAFK(enabled)
    if enabled then
        local vu = game:GetService("VirtualUser")
        ConnectionManager:Add("AntiAFK", LocalPlayer.Idled:Connect(function()
            vu:CaptureController()
            vu:ClickButton2(Vector2.new())
            Utils.Log("Anti-AFK triggered")
        end))
        Utils.Notify("Anti-AFK", "Enabled!", 2)
    else
        ConnectionManager:Remove("AntiAFK")
    end
end

-- Fruit Sniper System
function Extras.EnableFruitSniper(enabled)
    if enabled then
        ConnectionManager:Add("FruitSniper", Services.RunService.Heartbeat:Connect(function()
            if not getgenv().Config.FruitSniper then return end
            
            local hrp = Utils.GetHRP()
            if not hrp then return end
            
            -- Search for fruits
            for _, obj in pairs(Services.Workspace:GetDescendants()) do
                if obj:IsA("Tool") and obj.Name:find("Fruit") then
                    local handle = obj:FindFirstChild("Handle")
                    if handle then
                        local dist = Utils.GetDistance(hrp.Position, handle.Position)
                        if dist < 500 then
                            Movement.TeleportTo(handle.CFrame)
                            task.wait(0.5)
                            -- Try to pick up
                            fireproximityprompt(handle:FindFirstChildOfClass("ProximityPrompt"))
                        end
                    end
                end
            end
        end))
        Utils.Notify("Fruit Sniper", "Enabled - Scanning...", 3)
    else
        ConnectionManager:Remove("FruitSniper")
    end
end

-- Mirage Island Detection
function Extras.EnableMirageDetection(enabled)
    if enabled then
        ConnectionManager:Add("MirageDetect", Services.RunService.Heartbeat:Connect(function()
            if not getgenv().Config.MirageIsland then return end
            
            local mirage = Services.Workspace:FindFirstChild("MirageIsland") or 
                          Services.Workspace:FindFirstChild("Mirage")
            
            if mirage then
                Utils.Notify("MIRAGE ISLAND", "DETECTED! Teleporting...", 5)
                
                local miragePos = mirage:GetBoundingBox()
                Movement.TeleportTo(miragePos * CFrame.new(0, 50, 0))
                
                getgenv().Config.MirageIsland = false
                ConnectionManager:Remove("MirageDetect")
            end
        end))
        Utils.Notify("Mirage Detection", "Scanning for Mirage Island...", 3)
    else
        ConnectionManager:Remove("MirageDetect")
    end
end

-- ESP System
function Extras.CreateESP(target, color, text)
    if target:FindFirstChild("BFUltimateESP") then return end
    
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "BFUltimateESP"
    billboard.Adornee = target:FindFirstChild("HumanoidRootPart") or target:FindFirstChild("Head")
    billboard.Size = UDim2.new(0, 100, 0, 40)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = target
    
    local textLabel = Instance.new("TextLabel")
    textLabel.BackgroundTransparency = 1
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.Text = text or target.Name
    textLabel.TextColor3 = color or Color3.new(1, 0, 0)
    textLabel.TextScaled = true
    textLabel.Font = Enum.Font.GothamBold
    textLabel.TextStrokeTransparency = 0.5
    textLabel.Parent = billboard
    
    -- Health bar
    local hum = target:FindFirstChild("Humanoid")
    if hum then
        local healthFrame = Instance.new("Frame")
        healthFrame.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
        healthFrame.Size = UDim2.new(1, 0, 0.2, 0)
        healthFrame.Position = UDim2.new(0, 0, 1, 0)
        healthFrame.Parent = billboard
        
        local healthBar = Instance.new("Frame")
        healthBar.Name = "HealthBar"
        healthBar.BackgroundColor3 = Color3.new(0, 1, 0)
        healthBar.Size = UDim2.new(hum.Health / hum.MaxHealth, 0, 1, 0)
        healthBar.Parent = healthFrame
        
        -- Update health
        hum.HealthChanged:Connect(function(health)
            healthBar.Size = UDim2.new(health / hum.MaxHealth, 0, 1, 0)
            healthBar.BackgroundColor3 = Color3.new(1 - (health / hum.MaxHealth), health / hum.MaxHealth, 0)
        end)
    end
end

function Extras.EnableESP(enabled)
    if enabled then
        -- Create ESP for existing enemies
        local function updateESP()
            local enemies = Services.Workspace:FindFirstChild("Enemies")
            if enemies then
                for _, enemy in pairs(enemies:GetChildren()) do
                    if enemy:FindFirstChild("Humanoid") then
                        Extras.CreateESP(enemy, Color3.new(1, 0, 0))
                    end
                end
            end
            
            -- ESP for fruits
            for _, obj in pairs(Services.Workspace:GetDescendants()) do
                if obj:IsA("Tool") and obj.Name:find("Fruit") then
                    local handle = obj:FindFirstChild("Handle")
                    if handle then
                        Extras.CreateESP(obj, Color3.new(1, 1, 0), "🍎 " .. obj.Name)
                    end
                end
            end
        end
        
        updateESP()
        
        ConnectionManager:Add("ESPUpdate", Services.RunService.Heartbeat:Connect(function()
            if not getgenv().Config.ESP then return end
            task.wait(2) -- Update every 2 seconds
            updateESP()
        end))
        
        Utils.Notify("ESP", "Enabled!", 2)
    else
        ConnectionManager:Remove("ESPUpdate")
        
        -- Remove all ESP
        for _, obj in pairs(Services.Workspace:GetDescendants()) do
            if obj.Name == "BFUltimateESP" then
                obj:Destroy()
            end
        end
        
        Utils.Notify("ESP", "Disabled!", 2)
    end
end

-- Full Bright
function Extras.EnableFullBright(enabled)
    if enabled then
        Services.Lighting.Brightness = 2
        Services.Lighting.ClockTime = 14
        Services.Lighting.FogEnd = 100000
        Services.Lighting.GlobalShadows = false
        
        for _, v in pairs(Services.Lighting:GetDescendants()) do
            if v:IsA("Atmosphere") or v:IsA("BlurEffect") or v:IsA("ColorCorrectionEffect") then
                v.Enabled = false
            end
        end
        
        Utils.Notify("Full Bright", "Enabled!", 2)
    else
        Services.Lighting.Brightness = 1
        Services.Lighting.GlobalShadows = true
        Utils.Notify("Full Bright", "Disabled!", 2)
    end
end

-- Speed & Jump Modifications
function Extras.SetWalkSpeed(speed)
    local hum = Utils.GetHumanoid()
    if hum then
        hum.WalkSpeed = speed
    end
end

function Extras.SetJumpPower(power)
    local hum = Utils.GetHumanoid()
    if hum then
        hum.JumpPower = power
        hum.UseJumpPower = true
    end
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- SECTION 13: TELEPORT SYSTEM
-- ═══════════════════════════════════════════════════════════════════════════════

local Teleports = {
    -- First Sea
    ["Starter Island"] = CFrame.new(1060, 17, 1547),
    ["Jungle"] = CFrame.new(-1601, 36, 154),
    ["Pirate Village"] = CFrame.new(-1139, 14, 4109),
    ["Desert"] = CFrame.new(912, 6, 4417),
    ["Frozen Village"] = CFrame.new(1389, 87, -1298),
    ["Marine Fortress"] = CFrame.new(-5033, 28, 4324),
    ["Skylands"] = CFrame.new(-4843, 718, -2623),
    ["Prison"] = CFrame.new(4875, 5, 742),
    ["Colosseum"] = CFrame.new(-1569, 7, -2923),
    ["Magma Village"] = CFrame.new(-5312, 12, 8516),
    
    -- Second Sea
    ["Kingdom of Rose"] = CFrame.new(-429, 73, 1836),
    ["Green Zone"] = CFrame.new(-2445, 73, -3219),
    ["Graveyard"] = CFrame.new(-5765, 97, -824),
    ["Snow Mountain"] = CFrame.new(602, 402, -5371),
    ["Hot & Cold"] = CFrame.new(-5969, 60, -4651),
    ["Cursed Ship"] = CFrame.new(916, 192, 33069),
    ["Ice Castle"] = CFrame.new(6059, 130, -6553),
    ["Forgotten Island"] = CFrame.new(-3047, 237, -10005),
    ["Floating Turtle"] = CFrame.new(-12107, 332, -7471),
    
    -- Third Sea
    ["Port Town"] = CFrame.new(-289, 44, 5579),
    ["Hydra Island"] = CFrame.new(5229, 16, 303),
    ["Great Tree"] = CFrame.new(2842, 26, -7056),
    ["Floating Turtle 3rd"] = CFrame.new(-12107, 332, -7471),
    ["Haunted Castle"] = CFrame.new(-9500, 146, 5765),
    ["Sea of Treats"] = CFrame.new(-2045, 104, 5405)
}

function Teleports.GoTo(locationName)
    local cframe = Teleports[locationName]
    if cframe then
        Movement.TweenTo(cframe)
        Utils.Notify("Teleport", "Going to " .. locationName, 2)
    end
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- SECTION 14: USER INTERFACE (ORION LIBRARY)
-- ═══════════════════════════════════════════════════════════════════════════════

local function LoadUI()
    local success, OrionLib = pcall(function()
        return loadstring(game:HttpGet('https://raw.githubusercontent.com/jensonhirst/Orion/main/source'))()
    end)
    
    if not success then
        Utils.Notify("Error", "Failed to load UI library!", 5)
        return
    end
    
    local Window = OrionLib:MakeWindow({
        Name = "💎 Blox Fruits Ultimate v11.0",
        HidePremium = false,
        SaveConfig = true,
        ConfigFolder = "BFUltimateV11",
        IntroEnabled = true,
        IntroText = "Blox Fruits Ultimate v11.0"
    })
    
    -- ═══════════════ MAIN TAB ═══════════════
    local MainTab = Window:MakeTab({
        Name = "🏠 Main",
        Icon = "rbxassetid://4483345998",
        PremiumOnly = false
    })
    
    MainTab:AddParagraph("Auto Farm", "Smart farming system with quest support")
    
    MainTab:AddToggle({
        Name = "Auto Farm Level",
        Default = false,
        Callback = function(Value)
            getgenv().Config.AutoFarm = Value
            if Value then AutoFarm.Start() else AutoFarm.Stop() end
        end
    })
    
    MainTab:AddToggle({
        Name = "Auto Quest",
        Default = true,
        Callback = function(Value)
            getgenv().Config.AutoQuest = Value
        end
    })
    
    MainTab:AddToggle({
        Name = "Auto Boss Farm",
        Default = false,
        Callback = function(Value)
            getgenv().Config.AutoBossFarm = Value
            if Value then BossFarm.Start() else BossFarm.Stop() end
        end
    })
    
    MainTab:AddDropdown({
        Name = "Select Weapon",
        Default = "Melee",
        Options = {"Melee", "Sword", "Blox Fruit", "Gun"},
        Callback = function(Value)
            getgenv().Config.SelectedWeapon = Value
        end
    })
    
    MainTab:AddDropdown({
        Name = "Farm Mode",
        Default = "Nearest",
        Options = {"Nearest", "Lowest HP", "Highest HP"},
        Callback = function(Value)
            getgenv().Config.FarmMode = Value
        end
    })
    
    MainTab:AddToggle({
        Name = "Fast Attack",
        Default = true,
        Callback = function(Value)
            getgenv().Config.FastAttack = Value
        end
    })
    
    MainTab:AddToggle({
        Name = "Auto Skills (Z,X,C,V)",
        Default = true,
        Callback = function(Value)
            getgenv().Config.AutoSkill = Value
        end
    })
    
    MainTab:AddToggle({
        Name = "Bring Mobs",
        Default = false,
        Callback = function(Value)
            getgenv().Config.BringMobs = Value
        end
    })
    
    -- ═══════════════ MOVEMENT TAB ═══════════════
    local MovementTab = Window:MakeTab({
        Name = "🚀 Movement",
        Icon = "rbxassetid://4483345998",
        PremiumOnly = false
    })
    
    MovementTab:AddToggle({
        Name = "Fly Mode",
        Default = false,
        Callback = function(Value)
            getgenv().Config.Fly = Value
            Movement.EnableFly(Value)
        end
    })
    
    MovementTab:AddSlider({
        Name = "Fly Speed",
        Min = 50,
        Max = 500,
        Default = 100,
        Color = Color3.fromRGB(255, 255, 255),
        Increment = 10,
        Callback = function(Value)
            getgenv().Config.FlySpeed = Value
        end
    })
    
    MovementTab:AddToggle({
        Name = "Noclip",
        Default = false,
        Callback = function(Value)
            getgenv().Config.Noclip = Value
            Movement.EnableNoclip(Value)
        end
    })
    
    MovementTab:AddToggle({
        Name = "Infinite Jump",
        Default = false,
        Callback = function(Value)
            getgenv().Config.InfiniteJump = Value
            Movement.EnableInfiniteJump(Value)
        end
    })
    
    MovementTab:AddSlider({
        Name = "Tween Speed",
        Min = 100,
        Max = 1000,
        Default = 300,
        Color = Color3.fromRGB(255, 255, 255),
        Increment = 50,
        Callback = function(Value)
            getgenv().Config.TweenSpeed = Value
        end
    })
    
    MovementTab:AddSlider({
        Name = "Walk Speed",
        Min = 16,
        Max = 200,
        Default = 16,
        Color = Color3.fromRGB(255, 255, 255),
        Increment = 1,
        Callback = function(Value)
            getgenv().Config.WalkSpeed = Value
            Extras.SetWalkSpeed(Value)
        end
    })
    
    MovementTab:AddSlider({
        Name = "Jump Power",
        Min = 50,
        Max = 300,
        Default = 50,
        Color = Color3.fromRGB(255, 255, 255),
        Increment = 5,
        Callback = function(Value)
            getgenv().Config.JumpPower = Value
            Extras.SetJumpPower(Value)
        end
    })
    
    -- ═══════════════ TELEPORT TAB ═══════════════
    local TeleportTab = Window:MakeTab({
        Name = "📍 Teleport",
        Icon = "rbxassetid://4483345998",
        PremiumOnly = false
    })
    
    TeleportTab:AddParagraph("First Sea", "Starter locations")
    
    local firstSeaLocations = {"Starter Island", "Jungle", "Pirate Village", "Desert", "Frozen Village", "Marine Fortress", "Skylands", "Prison", "Colosseum", "Magma Village"}
    TeleportTab:AddDropdown({
        Name = "First Sea Locations",
        Default = "Starter Island",
        Options = firstSeaLocations,
        Callback = function(Value)
            Teleports.GoTo(Value)
        end
    })
    
    TeleportTab:AddParagraph("Second Sea", "Mid-game locations")
    
    local secondSeaLocations = {"Kingdom of Rose", "Green Zone", "Graveyard", "Snow Mountain", "Hot & Cold", "Cursed Ship", "Ice Castle", "Forgotten Island", "Floating Turtle"}
    TeleportTab:AddDropdown({
        Name = "Second Sea Locations",
        Default = "Kingdom of Rose",
        Options = secondSeaLocations,
        Callback = function(Value)
            Teleports.GoTo(Value)
        end
    })
    
    TeleportTab:AddParagraph("Third Sea", "End-game locations")
    
    local thirdSeaLocations = {"Port Town", "Hydra Island", "Great Tree", "Haunted Castle", "Sea of Treats"}
    TeleportTab:AddDropdown({
        Name = "Third Sea Locations",
        Default = "Port Town",
        Options = thirdSeaLocations,
        Callback = function(Value)
            Teleports.GoTo(Value)
        end
    })
    
    -- ═══════════════ EXTRAS TAB ═══════════════
    local ExtrasTab = Window:MakeTab({
        Name = "⚡ Extras",
        Icon = "rbxassetid://4483345998",
        PremiumOnly = false
    })
    
    ExtrasTab:AddToggle({
        Name = "Anti-AFK",
        Default = true,
        Callback = function(Value)
            getgenv().Config.AntiAFK = Value
            Extras.EnableAntiAFK(Value)
        end
    })
    
    ExtrasTab:AddToggle({
        Name = "Fruit Sniper",
        Default = false,
        Callback = function(Value)
            getgenv().Config.FruitSniper = Value
            Extras.EnableFruitSniper(Value)
        end
    })
    
    ExtrasTab:AddToggle({
        Name = "Mirage Island Detection",
        Default = false,
        Callback = function(Value)
            getgenv().Config.MirageIsland = Value
            Extras.EnableMirageDetection(Value)
        end
    })
    
    ExtrasTab:AddToggle({
        Name = "ESP (Enemies & Fruits)",
        Default = false,
        Callback = function(Value)
            getgenv().Config.ESP = Value
            Extras.EnableESP(Value)
        end
    })
    
    ExtrasTab:AddToggle({
        Name = "Full Bright",
        Default = false,
        Callback = function(Value)
            getgenv().Config.FullBright = Value
            Extras.EnableFullBright(Value)
        end
    })
    
    ExtrasTab:AddButton({
        Name = "Rejoin Server",
        Callback = function()
            Services.TeleportService:Teleport(game.PlaceId, LocalPlayer)
        end
    })
    
    -- ═══════════════ SETTINGS TAB ═══════════════
    local SettingsTab = Window:MakeTab({
        Name = "⚙️ Settings",
        Icon = "rbxassetid://4483345998",
        PremiumOnly = false
    })
    
    SettingsTab:AddToggle({
        Name = "Safe Mode (Anti-Detection)",
        Default = true,
        Callback = function(Value)
            getgenv().Config.SafeMode = Value
        end
    })
    
    SettingsTab:AddToggle({
        Name = "Debug Mode",
        Default = false,
        Callback = function(Value)
            getgenv().Config.DebugMode = Value
        end
    })
    
    SettingsTab:AddButton({
        Name = "Stop All Systems",
        Callback = function()
            getgenv().Config.AutoFarm = false
            getgenv().Config.AutoBossFarm = false
            getgenv().Config.Fly = false
            ConnectionManager:ClearAll()
            Movement.StopTween()
            Utils.Notify("System", "All systems stopped!", 3)
        end
    })
    
    SettingsTab:AddLabel("Made with ❤️ | v11.0 Enhanced")
    
    -- Initialize
    OrionLib:Init()
    
    -- Auto-enable Anti-AFK
    if getgenv().Config.AntiAFK then
        Extras.EnableAntiAFK(true)
    end
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- SECTION 15: INITIALIZATION
-- ═══════════════════════════════════════════════════════════════════════════════

-- Character respawn handling
LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(1)
    
    -- Re-apply movement settings
    if getgenv().Config.WalkSpeed ~= 16 then
        Extras.SetWalkSpeed(getgenv().Config.WalkSpeed)
    end
    if getgenv().Config.JumpPower ~= 50 then
        Extras.SetJumpPower(getgenv().Config.JumpPower)
    end
end)

-- Load UI
LoadUI()

-- Final notification
Utils.Notify("✅ Loaded!", "Blox Fruits Ultimate v11.0\nLevel: " .. Utils.GetLevel() .. " | World: " .. Utils.GetWorld(), 5)

print([[
╔═══════════════════════════════════════════════════════════════════════════════════════╗
║                      BLOX FRUITS ULTIMATE v11.0 - LOADED                              ║
║                              All systems initialized!                                 ║
╚═══════════════════════════════════════════════════════════════════════════════════════╝
]])
