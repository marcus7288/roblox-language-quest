--[[
  MUNDO ESPAÑOL — Roblox Unlock System
  =====================================
  HOW TO SET UP:
  1. In Roblox Studio, create a Part for each locked door (e.g. "Door_Unit2")
  2. Insert a SurfaceGui or BillboardGui on each door Part
  3. Add a TextLabel ("LOCKED — Enter code at terminal") and a ProximityPrompt
  4. Place this LocalScript inside StarterPlayerScripts
  5. Place a "Terminal" Part in the center of each zone with a ProximityPrompt
  6. Customize UNLOCK_CODES below — generate them with your web app

  ARCHITECTURE:
  - Each zone is gated by a door Part named "Door_Unit{N}"
  - A terminal Part named "Terminal_Unit{N}" triggers the code prompt
  - Unlock codes are checked locally (fine for MVP; use RemoteFunction for prod)
--]]

local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ── Configuration ────────────────────────────────────────────────────────────

-- Generate these with your web app's generateCode() function
-- Format: "RBX-XXX-XXX"  (student name + unit id + score hash)
-- For the MVP, you can use a shared class code here; per-student in v2
local VALID_CODES: { [number]: { string } } = {
  [2] = { "RBX-A3F-K91", "RBX-B72-Q44" },  -- Unit 2 unlock codes
  [3] = { "RBX-C18-M55", "RBX-D90-Z02" },  -- Unit 3 unlock codes
}

-- Map door names to unit numbers
local DOORS: { [string]: number } = {
  ["Door_Unit2"] = 2,
  ["Door_Unit3"] = 3,
}

local unlockedUnits: { [number]: boolean } = {}

-- ── UI Builder ───────────────────────────────────────────────────────────────

local function createCodeDialog(unitNumber: number): (ScreenGui, TextBox)
  local gui = Instance.new("ScreenGui")
  gui.Name         = "UnlockDialog"
  gui.ResetOnSpawn = false

  local frame = Instance.new("Frame")
  frame.Size            = UDim2.new(0, 380, 0, 240)
  frame.Position        = UDim2.new(0.5, -190, 0.5, -120)
  frame.BackgroundColor3 = Color3.fromRGB(13, 13, 26)
  frame.BorderSizePixel = 3
  frame.Parent          = gui

  -- Pixel-style border effect
  local stroke = Instance.new("UIStroke")
  stroke.Color     = Color3.fromRGB(249, 115, 22)
  stroke.Thickness = 3
  stroke.Parent    = frame

  local title = Instance.new("TextLabel")
  title.Text              = "🔒 UNIT " .. unitNumber .. " LOCKED"
  title.Size              = UDim2.new(1, 0, 0, 40)
  title.Position          = UDim2.new(0, 0, 0, 16)
  title.Font              = Enum.Font.Code
  title.TextSize          = 16
  title.TextColor3        = Color3.fromRGB(249, 115, 22)
  title.BackgroundTransparency = 1
  title.Parent            = frame

  local instructions = Instance.new("TextLabel")
  instructions.Text              = "Enter your unlock code from the web app:"
  instructions.Size              = UDim2.new(1, -32, 0, 30)
  instructions.Position          = UDim2.new(0, 16, 0, 60)
  instructions.Font              = Enum.Font.Code
  instructions.TextSize          = 13
  instructions.TextColor3        = Color3.fromRGB(120, 120, 150)
  instructions.BackgroundTransparency = 1
  instructions.Parent            = frame

  local inputBox = Instance.new("TextBox")
  inputBox.Size              = UDim2.new(1, -32, 0, 44)
  inputBox.Position          = UDim2.new(0, 16, 0, 98)
  inputBox.BackgroundColor3  = Color3.fromRGB(5, 5, 15)
  inputBox.BorderSizePixel   = 2
  inputBox.Font              = Enum.Font.Code
  inputBox.TextSize          = 18
  inputBox.TextColor3        = Color3.fromRGB(255, 255, 255)
  inputBox.PlaceholderText   = "RBX-XXX-XXX"
  inputBox.PlaceholderColor3 = Color3.fromRGB(60, 60, 80)
  inputBox.Text              = ""
  inputBox.ClearTextOnFocus  = false
  inputBox.Parent            = frame

  local inputStroke = Instance.new("UIStroke")
  inputStroke.Color     = Color3.fromRGB(249, 115, 22)
  inputStroke.Thickness = 2
  inputStroke.Parent    = inputBox

  local submitBtn = Instance.new("TextButton")
  submitBtn.Text              = "▶ UNLOCK"
  submitBtn.Size              = UDim2.new(0.5, -20, 0, 40)
  submitBtn.Position          = UDim2.new(0, 16, 0, 160)
  submitBtn.BackgroundColor3  = Color3.fromRGB(249, 115, 22)
  submitBtn.Font              = Enum.Font.Code
  submitBtn.TextSize          = 13
  submitBtn.TextColor3        = Color3.fromRGB(0, 0, 0)
  submitBtn.Parent            = frame

  local cancelBtn = Instance.new("TextButton")
  cancelBtn.Text              = "✕ CANCEL"
  cancelBtn.Size              = UDim2.new(0.5, -20, 0, 40)
  cancelBtn.Position          = UDim2.new(0.5, 4, 0, 160)
  cancelBtn.BackgroundColor3  = Color3.fromRGB(30, 30, 50)
  cancelBtn.Font              = Enum.Font.Code
  cancelBtn.TextSize          = 13
  cancelBtn.TextColor3        = Color3.fromRGB(150, 150, 170)
  cancelBtn.Parent            = frame

  local feedback = Instance.new("TextLabel")
  feedback.Size              = UDim2.new(1, -32, 0, 20)
  feedback.Position          = UDim2.new(0, 16, 0, 210)
  feedback.Font              = Enum.Font.Code
  feedback.TextSize          = 12
  feedback.TextColor3        = Color3.fromRGB(239, 68, 68)
  feedback.BackgroundTransparency = 1
  feedback.Text              = ""
  feedback.Parent            = frame

  -- Wire up buttons
  cancelBtn.MouseButton1Click:Connect(function()
    gui:Destroy()
  end)

  submitBtn.MouseButton1Click:Connect(function()
    local entered = string.upper(inputBox.Text:gsub("%s", ""))
    local valid   = false

    if VALID_CODES[unitNumber] then
      for _, code in ipairs(VALID_CODES[unitNumber]) do
        if entered == code then
          valid = true
          break
        end
      end
    end

    if valid then
      feedback.TextColor3 = Color3.fromRGB(16, 185, 129)
      feedback.Text = "✓ Correct! Unlocking..."
      task.wait(0.8)
      gui:Destroy()
      unlockDoor(unitNumber)
    else
      feedback.Text = "✗ Invalid code. Check the web app and try again."
      inputBox.Text = ""
    end
  end)

  gui.Parent = playerGui
  return gui, inputBox
end

-- ── Door Logic ────────────────────────────────────────────────────────────────

function unlockDoor(unitNumber: number)
  unlockedUnits[unitNumber] = true

  for doorName, doorUnit in pairs(DOORS) do
    if doorUnit == unitNumber then
      local door = workspace:FindFirstChild(doorName)
      if door then
        -- Tween the door upward out of the way
        local tween = TweenService:Create(
          door,
          TweenInfo.new(1.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
          { Position = door.Position + Vector3.new(0, 20, 0), Transparency = 1 }
        )
        tween:Play()
        tween.Completed:Connect(function()
          door.CanCollide = false
        end)
      end
    end
  end
end

-- ── Proximity Prompt Connections ──────────────────────────────────────────────

local function connectTerminal(terminal: BasePart, unitNumber: number)
  local prompt = terminal:FindFirstChildOfClass("ProximityPrompt")
  if not prompt then
    prompt = Instance.new("ProximityPrompt")
    prompt.ActionText   = "Enter Code"
    prompt.ObjectText   = "Unit " .. unitNumber .. " Terminal"
    prompt.MaxActivationDistance = 8
    prompt.Parent = terminal
  end

  prompt.Triggered:Connect(function(triggeringPlayer)
    if triggeringPlayer ~= player then return end
    if unlockedUnits[unitNumber] then
      -- Already unlocked — show a message
      local note = Instance.new("ScreenGui")
      note.Name = "AlreadyUnlocked"
      local label = Instance.new("TextLabel")
      label.Text = "✓ Unit " .. unitNumber .. " already unlocked!"
      label.Size = UDim2.new(0, 300, 0, 50)
      label.Position = UDim2.new(0.5, -150, 0.1, 0)
      label.Font = Enum.Font.Code
      label.TextSize = 15
      label.TextColor3 = Color3.fromRGB(16, 185, 129)
      label.BackgroundTransparency = 1
      label.Parent = note
      note.Parent = playerGui
      task.wait(2)
      note:Destroy()
      return
    end
    createCodeDialog(unitNumber)
  end)
end

-- ── Initialize ────────────────────────────────────────────────────────────────

local function init()
  -- Connect all terminals in the workspace
  for terminalName, unitNumber in pairs({
    ["Terminal_Unit2"] = 2,
    ["Terminal_Unit3"] = 3,
  }) do
    local terminal = workspace:WaitForChild(terminalName, 10)
    if terminal then
      connectTerminal(terminal, unitNumber)
    else
      warn("[MundoEspañol] Terminal not found: " .. terminalName)
    end
  end
end

init()

--[[
  SETUP CHECKLIST (Roblox Studio):
  ─────────────────────────────────
  □ Create Parts named: Door_Unit2, Door_Unit3
  □ Create Parts named: Terminal_Unit2, Terminal_Unit3
  □ Make doors solid (CanCollide = true) and a visible color
  □ Place this script in StarterPlayerScripts
  □ Update VALID_CODES with codes generated by your web app
  □ Playtest: walk up to terminal → enter code → door opens

  FOR PRODUCTION:
  □ Move code validation to a RemoteFunction + server Script
  □ Store unlocked state in DataStoreService for persistence
  □ Integrate with Supabase via an HttpService proxy endpoint
--]]
