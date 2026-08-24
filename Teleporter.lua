local KEY = "ABC123"
local VALID_FOR = 168 * 60 * 60 --7 day  

local createdAt = os.time()

if os.time() - createdAt > VALID_FOR then
    warn("Key expired!")
    return
end

print("Key is valid!")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Player = Players.LocalPlayer

--==================================================
-- Character
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
-- Rayfield
--==================================================

local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local Window = Rayfield:CreateWindow({
	Name = "Unish's Teleporter Hub",
	LoadingTitle = "Teleporter",
	LoadingSubtitle = "Unish_dai",
	ConfigurationSaving = {
		Enabled = false
	},
	UIScale = 0.1 -- Sets compact UI size cleanly via native library option
})

--==================================================
-- Rayfield UI Dynamic Scale Override + Toggle
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

		-- Lower this number to make the UI even smaller (e.g., 0.3 to 0.4 for Xeno-style mini frames)
		scale.Scale = 0.31

		-- RightShift = Show / Hide
		UserInputService.InputBegan:Connect(function(input, gameProcessed)
			if gameProcessed then return end

			if input.KeyCode == Enum.KeyCode.RightShift then
				rayfieldGui.Enabled = not rayfieldGui.Enabled
			end
		end)
	end
end)

local Tab = Window:CreateTab("Teleport", 4483362458)

--==================================================
-- Variables
--==================================================

local savedPosition = nil
local positionSaved = false
local isHolding = false

--==================================================
-- Save Position
--==================================================

Tab:CreateButton({
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

--==================================================
-- Teleport Toggle
--==================================================

Tab:CreateToggle({
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

--==================================================
-- Teleport / Position Loop
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
-- Clear Position
--==================================================

Tab:CreateButton({
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

--==================================================
-- Info
--==================================================

Tab:CreateParagraph({
	Title = "Teleport Position Saver",
	Content = "Save your location, then enable TELEPORT to remain at that position."
})
