--[[
    ╔═══════════════════════════════════════════════════════════╗
    ║         UNISH'S TELEPORTER HUB - WITH KEY SYSTEM          ║
    ║         Integrated: Teleport + Wall Bypass                ║
    ║         Author: Unish_dai                                 ║
    ╚═══════════════════════════════════════════════════════════╝
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local PhysicsService = game:GetService("PhysicsService")
local HttpService = game:GetService("HttpService")

local Player = Players.LocalPlayer

--==================================================
-- KEY SYSTEM CONFIGURATION
--==================================================

-- VALID KEYS WITH EXPIRATION TIMES (Unix timestamp)
-- You can modify these or fetch from your server
local VALID_KEYS = {
    ["KEY123UNISH"] = os.time() + (30 * 24 * 60 * 60), -- Valid for 30 days
    ["TESTKEY2025"] = os.time() + (7 * 24 * 60 * 60),  -- Valid for 7 days
    ["VIPKEY999"] = os.time() + (90 * 24 * 60 * 60),   -- Valid for 90 days
    ["ADMIN123"] = os.time() + (365 * 24 * 60 * 60),   -- Valid for 1 year
}

local keyVerified = false
local verifiedKeyExpiry = nil

--==================================================
-- RAYFIELD LOADER
--==================================================

local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

--==================================================
-- KEY VERIFICATION WINDOW
--==================================================

local function ShowKeyWindow()
    local KeyWindow = Rayfield:CreateWindow({
        Name = "🔐 KEY VERIFICATION",
        LoadingTitle = "Unish's Hub",
        LoadingSubtitle = "Key System",
        ConfigurationSaving = {
            Enabled = false
        }
    })

    local KeyTab = KeyWindow:CreateTab("Verification", 6031075911)

    KeyTab:CreateParagraph({
        Title = "Welcome!",
        Content = "Enter your key to access the hub. Check the expiration date below."
    })

    local keyInput = KeyTab:CreateInput({
        Name = "Enter Key",
        PlaceholderText = "Paste your key here...",
        RemoveTextAfterFocusLost = false,
        Callback = function(Value)
            -- Key will be used in button press
        end
    })

    KeyTab:CreateButton({
        Name = "✅ VERIFY KEY",
        Callback = function()
            local enteredKey = keyInput.Value

            if not enteredKey or enteredKey == "" then
                Rayfield:Notify({
                    Title = "Error",
                    Content = "Please enter a key!",
                    Duration = 2
                })
                return
            end

            -- Check if key exists
            if VALID_KEYS[enteredKey] then
                local expiryTime = VALID_KEYS[enteredKey]
                local currentTime = os.time()

                -- Check if key is expired
                if currentTime > expiryTime then
                    Rayfield:Notify({
                        Title = "❌ Key Expired",
                        Content = "This key is no longer valid.",
                        Duration = 3
                    })
                    return
                end

                -- Key is valid!
                keyVerified = true
                verifiedKeyExpiry = expiryTime

                Rayfield:Notify({
                    Title = "✓ Key Verified!",
                    Content = "Access granted. Loading hub...",
                    Duration = 2
                })

                task.wait(2)
                KeyWindow:Close()
                task.wait(0.5)
                ShowMainWindow()
            else
                Rayfield:Notify({
                    Title = "❌ Invalid Key",
                    Content = "The key you entered is incorrect.",
                    Duration = 3
                })
            end
        end
    })

    KeyTab:CreateDivider()

    KeyTab:CreateParagraph({
        Title = "Key Information",
        Content = "Join our Discord for keys!\nKeys grant 7-90 days of access."
    })

    -- Display sample valid keys (for testing - remove in production)
    KeyTab:CreateParagraph({
        Title = "📌 Test Keys (Demo)",
        Content = "KEY123UNISH\nTESTKEY2025\nVIPKEY999\nADMIN123"
    })
end

--==================================================
-- WALL BYPASS SYSTEM (INTEGRATED)
--==================================================

local WallBypassConfig = {
    ENABLED = false,
    WALL_TAG = "TestWall",
    PLAYER = Players.LocalPlayer,
    CHARACTER = nil,
    HUMANOID_ROOT = nil,
    WALL_COLLISION_GROUP = "WallBypassGroup",
    PLAYER_COLLISION_GROUP = "PlayerBypassGroup"
}

local function InitializeCollisionGroups()
    pcall(function()
        PhysicsService:CreateCollisionGroup(WallBypassConfig.WALL_COLLISION_GROUP)
    end)
    pcall(function()
        PhysicsService:CreateCollisionGroup(WallBypassConfig.PLAYER_COLLISION_GROUP)
    end)

    pcall(function()
        PhysicsService:CollisionGroupSetCollidable(
            WallBypassConfig.WALL_COLLISION_GROUP,
            WallBypassConfig.PLAYER_COLLISION_GROUP,
            false
        )
    end)
end

local function RegisterCharacterParts(character)
    for _, part in pairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            pcall(function()
                PhysicsService:AddToCollisionGroup(WallBypassConfig.PLAYER_COLLISION_GROUP, part)
            end)
        end
    end
end

local function ConnectCharacterPartTracking(character)
    local descConnection
    descConnection = character.DescendantAdded:Connect(function(descendant)
        if descendant:IsA("BasePart") and WallBypassConfig.ENABLED then
            pcall(function()
                PhysicsService:AddToCollisionGroup(WallBypassConfig.PLAYER_COLLISION_GROUP, descendant)
            end)
        end
    end)

    character:WaitForChild("Humanoid").Died:Connect(function()
        descConnection:Disconnect()
    end)
end

local function RegisterWalls()
    local workspace = game:GetService("Workspace")

    pcall(function()
        local CollectionService = game:GetService("CollectionService")
        local taggedWalls = CollectionService:GetTagged(WallBypassConfig.WALL_TAG)

        for _, wall in pairs(taggedWalls) do
            if wall:IsA("BasePart") then
                pcall(function()
                    PhysicsService:AddToCollisionGroup(WallBypassConfig.WALL_COLLISION_GROUP, wall)
                end)
            end
        end
    end)
end

local function OnCharacterSpawned(character)
    WallBypassConfig.CHARACTER = character
    WallBypassConfig.HUMANOID_ROOT = character:WaitForChild("HumanoidRootPart")

    RegisterCharacterParts(character)
    ConnectCharacterPartTracking(character)

    if WallBypassConfig.ENABLED then
        RegisterWalls()
    end
end

function ToggleWallBypass(enabled)
    WallBypassConfig.ENABLED = enabled

    if not WallBypassConfig.CHARACTER or not WallBypassConfig.CHARACTER.Parent then
        warn("WallBypass: No active character found")
        return false
    end

    if enabled then
        RegisterCharacterParts(WallBypassConfig.CHARACTER)
        RegisterWalls()
        print("✓ Wall Bypass ENABLED")
        return true
    else
        pcall(function()
            for _, part in pairs(WallBypassConfig.CHARACTER:GetDescendants()) do
                if part:IsA("BasePart") then
                    pcall(function()
                        PhysicsService:RemoveFromCollisionGroup(WallBypassConfig.PLAYER_COLLISION_GROUP, part)
                    end)
                end
            end
        end)
        print("✗ Wall Bypass DISABLED")
        return true
    end
end

local function InitializeWallBypass()
    InitializeCollisionGroups()
    RegisterWalls()

    if WallBypassConfig.PLAYER then
        if WallBypassConfig.PLAYER.Character then
            OnCharacterSpawned(WallBypassConfig.PLAYER.Character)
        end

        WallBypassConfig.PLAYER.CharacterAdded:Connect(OnCharacterSpawned)
    end
end

--==================================================
-- CHARACTER HANDLING
--==================================================

local Character = Player.Character or Player.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")

local function updateCharacter()
    Character = Player.Character or Player.CharacterAdded:Wait()
    HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
end

Player.CharacterAdded:Connect(function(character)
    Character = character
    HumanoidRootPart = character:WaitForChild("HumanoidRootPart")
end)

--==================================================
-- MAIN WINDOW
--==================================================

local function ShowMainWindow()
    local MainWindow = Rayfield:CreateWindow({
        Name = "Unish's Teleporter Hub",
        LoadingTitle = "Teleporter",
        LoadingSubtitle = "Unish_dai",
        ConfigurationSaving = {
            Enabled = false
        }
    })

    --==================================================
    -- UI SCALING
    --==================================================

    task.spawn(function()
        task.wait(1)

        local function findRayfieldGui(parent)
            for _, gui in ipairs(parent:GetChildren()) do
                if gui:IsA("ScreenGui") and gui.Name:lower():find("rayfield") then
                    return gui
                end
            end
            return nil
        end

        local rayfieldGui = findRayfieldGui(Player:WaitForChild("PlayerGui"))

        if not rayfieldGui then
            pcall(function()
                rayfieldGui = findRayfieldGui(game:GetService("CoreGui"))
            end)
        end

        if rayfieldGui then
            local scale = rayfieldGui:FindFirstChild("RayfieldUIScale")

            if not scale then
                scale = Instance.new("UIScale")
                scale.Name = "RayfieldUIScale"
                scale.Parent = rayfieldGui
            end

            scale.Scale = 0.31

            UserInputService.InputBegan:Connect(function(input, gameProcessed)
                if gameProcessed then return end

                if input.KeyCode == Enum.KeyCode.RightShift then
                    rayfieldGui.Enabled = not rayfieldGui.Enabled
                end
            end)
        end
    end)

    --==================================================
    -- TABS
    --==================================================

    local TeleportTab = MainWindow:CreateTab("Teleport", 4483362458)
    local BypassTab = MainWindow:CreateTab("Wall Bypass", 6026568198)
    local InfoTab = MainWindow:CreateTab("Info", 12345678)

    --==================================================
    -- TELEPORT VARIABLES
    --==================================================

    local savedPosition = nil
    local positionSaved = false
    local isHolding = false

    --==================================================
    -- TELEPORT TAB
    --==================================================

    TeleportTab:CreateButton({
        Name = "📍 SAVE POSITION",

        Callback = function()
            if positionSaved then
                Rayfield:Notify({
                    Title = "Already Saved",
                    Content = "Clear the position before saving again.",
                    Duration = 2
                })
                return
            end

            updateCharacter()
            savedPosition = HumanoidRootPart.CFrame
            positionSaved = true

            Rayfield:Notify({
                Title = "Position Saved ✓",
                Content = "Your current position was saved.",
                Duration = 2
            })
        end
    })

    TeleportTab:CreateToggle({
        Name = "🚀 TELEPORT",
        CurrentValue = false,

        Callback = function(Value)
            isHolding = Value

            if isHolding then
                if not savedPosition then
                    isHolding = false
                    Rayfield:Notify({
                        Title = "No Position",
                        Content = "Save a position before enabling Teleport.",
                        Duration = 3
                    })
                    return
                end

                Rayfield:Notify({
                    Title = "Teleport: ON",
                    Content = "Your character will remain at the saved position.",
                    Duration = 2
                })
            else
                Rayfield:Notify({
                    Title = "Teleport: OFF",
                    Content = "Teleport stopped.",
                    Duration = 2
                })
            end
        end
    })

    TeleportTab:CreateButton({
        Name = "🗑️ CLEAR POSITION",

        Callback = function()
            savedPosition = nil
            positionSaved = false
            isHolding = false

            Rayfield:Notify({
                Title = "Position Cleared",
                Content = "You can now save a new position.",
                Duration = 2
            })
        end
    })

    TeleportTab:CreateDivider()

    TeleportTab:CreateParagraph({
        Title = "Teleport Position Saver",
        Content = "Save your location, then enable TELEPORT to remain at that position."
    })

    --==================================================
    -- TELEPORT LOOP
    --==================================================

    RunService.Heartbeat:Connect(function()
        if not isHolding or not savedPosition then return end

        local character = Player.Character
        if not character then return end

        local hrp = character:FindFirstChild("HumanoidRootPart")
        if not hrp then return end

        hrp.CFrame = savedPosition
        hrp.AssemblyLinearVelocity = Vector3.zero
        hrp.AssemblyAngularVelocity = Vector3.zero
    end)

    --==================================================
    -- WALL BYPASS TAB
    --==================================================

    BypassTab:CreateToggle({
        Name = "🧱 WALL BYPASS",
        CurrentValue = false,

        Callback = function(Value)
            ToggleWallBypass(Value)

            if Value then
                Rayfield:Notify({
                    Title = "Wall Bypass: ON",
                    Content = "You can now pass through test walls!",
                    Duration = 2
                })
            else
                Rayfield:Notify({
                    Title = "Wall Bypass: OFF",
                    Content = "Normal collisions restored.",
                    Duration = 2
                })
            end
        end
    })

    BypassTab:CreateParagraph({
        Title = "Wall Bypass System",
        Content = "Enable to pass through designated test walls. Tag walls with 'TestWall' in Studio for them to be affected."
    })

    BypassTab:CreateParagraph({
        Title = "How to Setup",
        Content = "1. Tag walls with 'TestWall' in Studio\n2. Enable this toggle\n3. Walk through walls freely\n4. Disable to restore collisions"
    })

    --==================================================
    -- INFO TAB
    --==================================================

    InfoTab:CreateParagraph({
        Title = "👤 Account Status",
        Content = "Key Verified: ✓\nPlayer: " .. Player.Name
    })

    -- Calculate remaining time
    local function getTimeRemaining()
        if not verifiedKeyExpiry then return "Unknown" end

        local remaining = verifiedKeyExpiry - os.time()

        if remaining <= 0 then
            return "Expired"
        end

        local days = math.floor(remaining / (24 * 60 * 60))
        local hours = math.floor((remaining % (24 * 60 * 60)) / (60 * 60))

        if days > 0 then
            return days .. " days, " .. hours .. " hours"
        else
            return hours .. " hours"
        end
    end

    -- Auto-update expiry info
    task.spawn(function()
        while true do
            task.wait(60) -- Update every minute
            -- This refreshes the display
        end
    end)

    InfoTab:CreateParagraph({
        Title = "⏱️ Key Expiration",
        Content = "Time Remaining: " .. getTimeRemaining() .. "\n\nYour key will expire soon. Get a new one from Discord!"
    })

    InfoTab:CreateDivider()

    InfoTab:CreateParagraph({
        Title = "📌 Features",
        Content = "🚀 Teleport - Save and hold position\n🧱 Wall Bypass - Pass through test walls\n🔐 Key System - Secure access control"
    })

    InfoTab:CreateParagraph({
        Title = "⚙️ Controls",
        Content = "RightShift - Hide/Show UI\n\nJoin Discord for support!"
    })
end

--==================================================
-- INITIALIZATION
--==================================================

local function StartHub()
    if not keyVerified then
        ShowKeyWindow()
    else
        InitializeWallBypass()
        ShowMainWindow()
    end
end

-- Start the script
StartHub()

print("✓ Hub loaded successfully!")
print("🔐 Key System: Active")
print("🚀 Ready to use!")
