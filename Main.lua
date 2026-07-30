repeat wait() until game:IsLoaded()

if game.PlaceId ~= 84515722934860 then
    return
end

print("Version 1.2.9")
print("11.35")
-- ========================================
-- Main Script - à¸£à¸§à¸¡à¸—à¸¸à¸à¸Ÿà¸±à¸‡à¸à¹Œà¸Šà¸±à¸™à¸•à¸²à¸¡à¸¥à¸³à¸”à¸±à¸š
-- ========================================

-- ========================================
-- 0. Check PlayerGui (à¸•à¹‰à¸­à¸‡à¹‚à¸«à¸¥à¸”à¸à¹ˆà¸­à¸™à¸—à¸¸à¸à¸­à¸¢à¹ˆà¸²à¸‡)
-- ========================================
do
    local Players = game:GetService("Players")

    local MINIMUM_GUI_COUNT = 50  -- à¸ˆà¸³à¸™à¸§à¸™ GUI à¸‚à¸±à¹‰à¸™à¸•à¹ˆà¸³à¸—à¸µà¹ˆà¸•à¹‰à¸­à¸‡à¸¡à¸µ
    local MAX_WAIT_TIME = 30  -- à¸£à¸­à¸ªà¸¹à¸‡à¸ªà¸¸à¸” 30 à¸§à¸´à¸™à¸²à¸—à¸µ
    local CHECK_INTERVAL = 1  -- à¹€à¸Šà¹‡à¸„à¸—à¸¸à¸ 1 à¸§à¸´à¸™à¸²à¸—à¸µ

    local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui", 10)

    if not playerGui then
        warn("âŒ PlayerGui not found - Kicking...")
        Players.LocalPlayer:Kick("PlayerGui failed to load. Please rejoin.")
        return
    end

    -- à¸£à¸­à¸ˆà¸™à¸à¸§à¹ˆà¸² GUI à¸ˆà¸°à¹‚à¸«à¸¥à¸”à¸„à¸£à¸š à¸«à¸£à¸·à¸­à¸„à¸£à¸šà¹€à¸§à¸¥à¸² 30 à¸§à¸´
    local elapsedTime = 0

    while elapsedTime < MAX_WAIT_TIME do
        local guiCount = #playerGui:GetChildren()

        if guiCount >= MINIMUM_GUI_COUNT then
            break  -- à¹‚à¸«à¸¥à¸”à¸ªà¸³à¹€à¸£à¹‡à¸ˆ à¹ƒà¸«à¹‰à¸£à¸±à¸™à¸ªà¸„à¸£à¸´à¸›à¸•à¹ˆà¸­à¹„à¸”à¹‰
        end

        task.wait(CHECK_INTERVAL)
        elapsedTime = elapsedTime + CHECK_INTERVAL
    end

    -- à¸–à¹‰à¸²à¸„à¸£à¸š 30 à¸§à¸´à¹à¸¥à¹‰à¸§à¸¢à¸±à¸‡à¹‚à¸«à¸¥à¸”à¹„à¸¡à¹ˆà¸„à¸£à¸š
    local finalCount = #playerGui:GetChildren()
    if finalCount < MINIMUM_GUI_COUNT then
        warn(string.format("âŒ PlayerGui incomplete after %ds (%d/%d) - Kicking...", MAX_WAIT_TIME, finalCount, MINIMUM_GUI_COUNT))
        Players.LocalPlayer:Kick(string.format("PlayerGui failed to load properly (%d/%d). Please rejoin.", finalCount, MINIMUM_GUI_COUNT))
        return
    end
end

-- ========================================
-- Anti-AFK (à¹‚à¸«à¸¥à¸”à¸à¹ˆà¸­à¸™à¸­à¸±à¸™à¹à¸£à¸)
-- ========================================
local Players = game:GetService("Players")
local VirtualUser = game:GetService("VirtualUser")
local VirtualInputManager = game:GetService("VirtualInputManager")

-- VirtualUser Anti-AFK (Passive)
Players.LocalPlayer.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end)

-- Random Edge Click Anti-AFK (Active)
spawn(function()
    local camera = workspace.CurrentCamera

    while true do
        -- à¸£à¸­ random 30-60 à¸§à¸´à¸™à¸²à¸—à¸µ
        task.wait(math.random(30, 60))

        pcall(function()
            local screenSize = camera.ViewportSize

            -- à¸ªà¸¸à¹ˆà¸¡à¸¡à¸¸à¸¡à¸ˆà¸­
            local edges = {
                {x = 10, y = 10},                              -- à¸¡à¸¸à¸¡à¸‹à¹‰à¸²à¸¢à¸šà¸™
                {x = screenSize.X - 10, y = 10},              -- à¸¡à¸¸à¸¡à¸‚à¸§à¸²à¸šà¸™
                {x = 10, y = screenSize.Y - 10},              -- à¸¡à¸¸à¸¡à¸‹à¹‰à¸²à¸¢à¸¥à¹ˆà¸²à¸‡
                {x = screenSize.X - 10, y = screenSize.Y - 10}, -- à¸¡à¸¸à¸¡à¸‚à¸§à¸²à¸¥à¹ˆà¸²à¸‡
                {x = screenSize.X / 2, y = 10},               -- à¸à¸¥à¸²à¸‡à¸šà¸™
                {x = screenSize.X / 2, y = screenSize.Y - 10}, -- à¸à¸¥à¸²à¸‡à¸¥à¹ˆà¸²à¸‡
            }

            -- à¸ªà¸¸à¹ˆà¸¡à¹€à¸¥à¸·à¸­à¸à¸¡à¸¸à¸¡
            local edge = edges[math.random(1, #edges)]

            -- à¸„à¸¥à¸´à¸
            VirtualInputManager:SendMouseButtonEvent(edge.x, edge.y, 0, true, game, 0)
            task.wait(0.05)
            VirtualInputManager:SendMouseButtonEvent(edge.x, edge.y, 0, false, game, 0)
        end)
    end
end)

-- ========================================
-- CONFIG (à¸£à¸­à¸‡à¸£à¸±à¸š External Config)
-- ========================================
_G.Config = _G.Config or {}
local HORST_ENABLED = _G.Config.Horst == true
local GEM_TARGET = _G.Config.GemTarget  -- nil = à¹„à¸¡à¹ˆà¸ªà¹ˆà¸‡ DONE
local UPDATE_INTERVAL = 30
local TOGGLE_RENDER3D = _G.Config.ToggleRender3D == true  -- à¸œà¸¹à¸ Render3D à¸à¸±à¸š GUI toggle

-- Secret Unit Config
local CHANGE_ACC_SECRETS = _G.Config.Change_Acc_Secrets == true  -- true = à¸ªà¹ˆà¸‡ DONE à¸«à¸¥à¸±à¸‡ Trait Reroll à¸‚à¸­à¸‡ Secret, false = à¸‚à¹‰à¸²à¸¡à¹„à¸›à¸Ÿà¸²à¸£à¹Œà¸¡à¸•à¸²à¸¡à¸›à¸à¸•à¸´

-- Summon Config
local SUMMON_CONFIG = _G.Config.SummonUnits or {}
-- à¸–à¹‰à¸²à¹€à¸›à¹‡à¸™ string à¹ƒà¸«à¹‰à¹à¸›à¸¥à¸‡à¹€à¸›à¹‡à¸™ table (à¸¢à¸à¹€à¸§à¹‰à¸™ "auto" à¸ˆà¸°à¸–à¸¹à¸ override à¸ à¸²à¸¢à¸«à¸¥à¸±à¸‡)
if type(SUMMON_CONFIG) == "string" then
    if SUMMON_CONFIG:lower() == "auto" then
        SUMMON_CONFIG = {}  -- à¸ˆà¸°à¸–à¸¹à¸ override à¹€à¸›à¹‡à¸™ Secret + Mythic à¸ à¸²à¸¢à¸«à¸¥à¸±à¸‡
    else
        SUMMON_CONFIG = {SUMMON_CONFIG}  -- à¹à¸›à¸¥à¸‡ "Shadow" â†’ {"Shadow"}
    end
end
local MYTHIC_UNITS = {"Cursed Student", "Elf Mage", "Flame Emperor", "Hollow", "Lady Giant", "Puppet", "Salmon Sorcerer", "String Demon"}
local SECRET_UNITS = {"Shadow"}
local hasSummonConfig = _G.Config.SummonUnits and (
    (type(_G.Config.SummonUnits) == "string" and _G.Config.SummonUnits ~= "") or
    (type(_G.Config.SummonUnits) == "table" and #_G.Config.SummonUnits > 0)
)

-- Trait Reroll Config
local TRAIT_REROLL_CONFIG = _G.Config.TraitReroll or {}
-- à¸•à¸±à¸§à¸­à¸¢à¹ˆà¸²à¸‡:
-- _G.Config.TraitReroll = {
--     TargetUnit = "Ice Queen",                          -- à¸•à¸±à¸§à¸—à¸µà¹ˆà¸•à¹‰à¸­à¸‡à¸à¸²à¸£à¸ªà¸¸à¹ˆà¸¡ Trait
--     TargetTrait = {"Enlightenment", "Ultimate"}        -- Trait à¸—à¸µà¹ˆà¸•à¹‰à¸­à¸‡à¸à¸²à¸£ (à¸«à¸¥à¸²à¸¢à¸•à¸±à¸§)
--     à¸«à¸£à¸·à¸­ TargetTrait = "Enlightenment"                 -- Trait à¹€à¸”à¸µà¸¢à¸§
--     à¸«à¸£à¸·à¸­ TargetTrait = nil                             -- à¸­à¸°à¹„à¸£à¸à¹‡à¹„à¸”à¹‰à¸—à¸µà¹ˆà¹„à¸¡à¹ˆà¹ƒà¸Šà¹ˆ None
--     à¸«à¸£à¸·à¸­ TargetTrait = {}                              -- à¹„à¸¡à¹ˆà¸•à¹‰à¸­à¸‡à¸ªà¸¸à¹ˆà¸¡ (à¸‚à¹‰à¸²à¸¡)
-- }

-- Priority List à¸ªà¸³à¸«à¸£à¸±à¸šà¹€à¸¥à¸·à¸­à¸ Unit à¸—à¸µà¹ˆà¸ˆà¸°à¸ªà¸¸à¹ˆà¸¡ Trait (à¸–à¹‰à¸² Config à¸•à¸±à¹‰à¸‡ SummonUnits à¸«à¸¥à¸²à¸¢à¸•à¸±à¸§)
local TRAIT_REROLL_PRIORITY = {
    "Shadow",           -- Priority 1 (Secret)
    "Puppet",           -- Priority 2 (Mythic)
    "Cursed Student",   -- Priority 3 (Mythic)
    "Lady Giant",       -- Priority 4 (Mythic)
    "Elf Mage",         -- Priority 5 (Mythic)
    "Flame Emperor",    -- Priority 6 (Mythic)
    "Hollow",           -- Priority 7 (Mythic)
    "Salmon Sorcerer",  -- Priority 8 (Mythic)
    "String Demon"      -- Priority 9 (Mythic)
}

-- ========================================
-- Description Mode Selection
-- ========================================
local DESCRIPTION_MODE = nil
if GEM_TARGET and not hasSummonConfig then
    DESCRIPTION_MODE = "GEM"
    print("ðŸ“Š Description Mode: GEM (Stats only)")
elseif hasSummonConfig then
    DESCRIPTION_MODE = "SUMMON"
    print("ðŸ“Š Description Mode: SUMMON (Unit tracking)")
end

local function printStep(stepName)
    print(string.format("ðŸ”„ %s", stepName))
end

-- à¸Ÿà¸±à¸‡à¸à¹Œà¸Šà¸±à¸™à¹€à¸Šà¹‡à¸„ Banner à¸“ à¸•à¸­à¸™à¸™à¸µà¹‰ (Global scope)
local function checkCurrentBanner()
    local success, result = pcall(function()
        local Players = game:GetService("Players")
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local Nodes = require(ReplicatedStorage:WaitForChild("Nodes"))

        Nodes.TOGGLE_MENU:FireSelf("Summon", true)
        task.wait(2)

        local summonGui = Players.LocalPlayer.PlayerGui:FindFirstChild("Summon")
        if not summonGui then return {} end

        local foundUnits = {}
        local blacklist = {["Summon"]=true, ["Settings"]=true, ["Rates"]=true, ["Mythic Unit"]=true}

        for _, child in ipairs(summonGui:GetDescendants()) do
            if child:IsA("TextLabel") and child.Visible then
                local text = child.Text or child.ContentText or ""
                if text ~= "" and text:match("^[A-Z]") and #text >= 3 and #text < 30 then
                    if not blacklist[text] then
                        local hasFolder = false
                        local current = child.Parent
                        for i = 1, 5 do
                            if not current then break end
                            if current:IsA("Folder") then hasFolder = true; break end
                            current = current.Parent
                        end
                        if hasFolder and not foundUnits[text] then foundUnits[text] = true end
                    end
                end
            end
        end

        Nodes.TOGGLE_MENU:FireSelf("Summon", false)
        task.wait(0.5)

        local unitList = {}
        for unitName, _ in pairs(foundUnits) do table.insert(unitList, unitName) end
        return unitList
    end)
    return success and result or {}
end

-- ========================================
-- -1. Load Horst API (à¸–à¹‰à¸² Config à¹€à¸›à¸´à¸”)
-- ========================================
if HORST_ENABLED then
    printStep("Loading Horst API...")
    local success, err = pcall(function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/HorstSpaceX/last_update/main/on_loaded.lua"))()
    end)

    if success then
        if GEM_TARGET then
        else
        end
    else
        warn("   âŒ Failed to load Horst API:", err)
        HORST_ENABLED = false
    end
    task.wait(1)
end

-- ========================================
-- 0. StatsGUI (à¹‚à¸«à¸¥à¸”à¸à¹ˆà¸­à¸™à¸­à¸±à¸™à¹à¸£à¸)
-- ========================================
printStep("Loading Stats GUI...")

-- ========================================
-- Global Flag à¸ªà¸³à¸«à¸£à¸±à¸šà¸«à¸¢à¸¸à¸”à¸ªà¸„à¸£à¸´à¸›à¸•à¹Œ
-- ========================================
_G.ScriptShouldStop = false  -- à¹ƒà¸Šà¹‰ _G à¹€à¸žà¸·à¹ˆà¸­à¹ƒà¸«à¹‰à¹€à¸‚à¹‰à¸²à¸–à¸¶à¸‡à¹„à¸”à¹‰à¸—à¸¸à¸à¸—à¸µà¹ˆ

local statsGuiSuccess, statsGuiError = pcall(function()
    local Players = game:GetService("Players")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local RunService = game:GetService("RunService")

    local player = Players.LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui")
    local Nodes = require(ReplicatedStorage:WaitForChild("Nodes"))

    -- à¸ªà¸£à¹‰à¸²à¸‡ ScreenGui
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "StatsDisplay"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.DisplayOrder = 999999
    screenGui.IgnoreGuiInset = true
    screenGui.Parent = playerGui

    -- Frame à¸«à¸¥à¸±à¸
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0.6, 0, 0.6, 0)
    mainFrame.Position = UDim2.new(0.5, 0, 0.65, 0)
    mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    mainFrame.BackgroundColor3 = Color3.fromRGB(245, 235, 220)
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = screenGui

    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UDim.new(0, 12)
    mainCorner.Parent = mainFrame

    -- Padding
    local mainPadding = Instance.new("UIPadding")
    mainPadding.PaddingTop = UDim.new(0.03, 0)
    mainPadding.PaddingBottom = UDim.new(0.03, 0)
    mainPadding.PaddingLeft = UDim.new(0.04, 0)
    mainPadding.PaddingRight = UDim.new(0.04, 0)
    mainPadding.Parent = mainFrame

    local listLayout = Instance.new("UIListLayout")
    listLayout.Padding = UDim.new(0.02, 0)
    listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    listLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Parent = mainFrame

    -- Username Box
    local usernameBox = Instance.new("Frame")
    usernameBox.Name = "UsernameBox"
    usernameBox.Size = UDim2.new(1, 0, 0.15, 0)
    usernameBox.BackgroundColor3 = Color3.fromRGB(139, 90, 43)
    usernameBox.BorderSizePixel = 0
    usernameBox.LayoutOrder = 1
    usernameBox.Parent = mainFrame

    local usernameCorner = Instance.new("UICorner")
    usernameCorner.CornerRadius = UDim.new(0, 10)
    usernameCorner.Parent = usernameBox

    local usernameStroke = Instance.new("UIStroke")
    usernameStroke.Color = Color3.fromRGB(70, 45, 22)
    usernameStroke.Thickness = 3
    usernameStroke.Parent = usernameBox

    local usernameLabel = Instance.new("TextLabel")
    usernameLabel.Size = UDim2.new(1, 0, 1, 0)
    usernameLabel.BackgroundTransparency = 1
    usernameLabel.Text = player.Name
    usernameLabel.TextColor3 = Color3.fromRGB(245, 222, 179)
    usernameLabel.TextSize = 80
    usernameLabel.Font = Enum.Font.GothamBold
    usernameLabel.TextScaled = true
    usernameLabel.Parent = usernameBox

    local usernamePadding = Instance.new("UIPadding")
    usernamePadding.PaddingLeft = UDim.new(0.03, 0)
    usernamePadding.PaddingRight = UDim.new(0.03, 0)
    usernamePadding.PaddingTop = UDim.new(0.15, 0)
    usernamePadding.PaddingBottom = UDim.new(0.15, 0)
    usernamePadding.Parent = usernameLabel

    -- Stats
    local stats = {
        {name = "Gem", key = "Gem", color = Color3.fromRGB(194, 144, 90), order = 2},
        {name = "Gold", key = "Gold", color = Color3.fromRGB(210, 180, 140), order = 3},
        {name = "Trait", key = "TraitReroll", color = Color3.fromRGB(222, 184, 135), order = 4}
    }

    local statsLabels = {}

    for _, stat in ipairs(stats) do
        local statBox = Instance.new("Frame")
        statBox.Name = stat.key .. "Box"
        statBox.Size = UDim2.new(1, 0, 0.18, 0)
        statBox.BackgroundColor3 = stat.color
        statBox.BorderSizePixel = 0
        statBox.LayoutOrder = stat.order
        statBox.Parent = mainFrame

        local statCorner = Instance.new("UICorner")
        statCorner.CornerRadius = UDim.new(0, 10)
        statCorner.Parent = statBox

        local statStroke = Instance.new("UIStroke")
        statStroke.Color = Color3.fromRGB(139, 90, 43)
        statStroke.Thickness = 3
        statStroke.Parent = statBox

        -- Container à¸ªà¸³à¸«à¸£à¸±à¸š name à¹à¸¥à¸° value
        local contentFrame = Instance.new("Frame")
        contentFrame.Size = UDim2.new(1, 0, 1, 0)
        contentFrame.BackgroundTransparency = 1
        contentFrame.Parent = statBox

        local contentPadding = Instance.new("UIPadding")
        contentPadding.PaddingLeft = UDim.new(0.03, 0)
        contentPadding.PaddingRight = UDim.new(0.03, 0)
        contentPadding.PaddingTop = UDim.new(0.1, 0)
        contentPadding.PaddingBottom = UDim.new(0.1, 0)
        contentPadding.Parent = contentFrame

        -- Name (à¸‹à¹‰à¸²à¸¢)
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(0.4, 0, 1, 0)
        nameLabel.Position = UDim2.new(0, 0, 0, 0)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = stat.name
        nameLabel.TextColor3 = Color3.fromRGB(70, 45, 22)
        nameLabel.TextSize = 72
        nameLabel.Font = Enum.Font.GothamBold
        nameLabel.TextScaled = true
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.Parent = contentFrame

        -- Colon (à¸à¸¥à¸²à¸‡)
        local colonLabel = Instance.new("TextLabel")
        colonLabel.Size = UDim2.new(0.1, 0, 1, 0)
        colonLabel.Position = UDim2.new(0.4, 0, 0, 0)
        colonLabel.BackgroundTransparency = 1
        colonLabel.Text = ":"
        colonLabel.TextColor3 = Color3.fromRGB(70, 45, 22)
        colonLabel.TextSize = 72
        colonLabel.Font = Enum.Font.GothamBold
        colonLabel.TextScaled = true
        colonLabel.Parent = contentFrame

        -- Value (à¸‚à¸§à¸²)
        local valueLabel = Instance.new("TextLabel")
        valueLabel.Size = UDim2.new(0.5, 0, 1, 0)
        valueLabel.Position = UDim2.new(0.5, 0, 0, 0)
        valueLabel.BackgroundTransparency = 1
        valueLabel.Text = "..."
        valueLabel.TextColor3 = Color3.fromRGB(70, 45, 22)
        valueLabel.TextSize = 72
        valueLabel.Font = Enum.Font.GothamBold
        valueLabel.TextScaled = true
        valueLabel.TextXAlignment = Enum.TextXAlignment.Right
        valueLabel.Parent = contentFrame

        statsLabels[stat.key] = valueLabel
    end

    -- Sugar Hub Box
    local sugarBox = Instance.new("Frame")
    sugarBox.Name = "SugarBox"
    sugarBox.Size = UDim2.new(1, 0, 0.15, 0)
    sugarBox.BackgroundColor3 = Color3.fromRGB(139, 90, 43)
    sugarBox.BorderSizePixel = 0
    sugarBox.LayoutOrder = 5
    sugarBox.Parent = mainFrame

    local sugarCorner = Instance.new("UICorner")
    sugarCorner.CornerRadius = UDim.new(0, 10)
    sugarCorner.Parent = sugarBox

    local sugarStroke = Instance.new("UIStroke")
    sugarStroke.Color = Color3.fromRGB(70, 45, 22)
    sugarStroke.Thickness = 3
    sugarStroke.Parent = sugarBox

    local sugarLabel = Instance.new("TextLabel")
    sugarLabel.Size = UDim2.new(1, 0, 1, 0)
    sugarLabel.BackgroundTransparency = 1
    sugarLabel.Text = "Sugar Hub"
    sugarLabel.TextColor3 = Color3.fromRGB(245, 222, 179)
    sugarLabel.TextSize = 80
    sugarLabel.Font = Enum.Font.GothamBold
    sugarLabel.TextScaled = true
    sugarLabel.Parent = sugarBox

    local sugarPadding = Instance.new("UIPadding")
    sugarPadding.PaddingLeft = UDim.new(0.03, 0)
    sugarPadding.PaddingRight = UDim.new(0.03, 0)
    sugarPadding.PaddingTop = UDim.new(0.15, 0)
    sugarPadding.PaddingBottom = UDim.new(0.15, 0)
    sugarPadding.Parent = sugarLabel

    -- à¸Ÿà¸±à¸‡à¸à¹Œà¸Šà¸±à¸™à¹ƒà¸ªà¹ˆà¸¥à¸¹à¸à¸™à¹‰à¸³
    local function formatNumber(num)
        local formatted = tostring(num)
        local k
        while true do
            formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
            if k == 0 then
                break
            end
        end
        return formatted
    end

    -- à¸Ÿà¸±à¸‡à¸à¹Œà¸Šà¸±à¸™à¸”à¸¶à¸‡à¸„à¹ˆà¸² Stats
    local function updateStats()
        local success, err = pcall(function()
            local replica = Nodes.GET_PLAYER_REPLICA:InvokeSelf()
            if not replica then
                error("Replica not found")
            end

            local data = replica.Data
            local itemData = data.ItemData
            if not itemData then
                error("ItemData not found")
            end

            -- Gem
            local gem = 0
            if itemData.Gem and type(itemData.Gem) == "table" and itemData.Gem.Amount then
                gem = itemData.Gem.Amount
            end
            statsLabels.Gem.Text = formatNumber(gem)

            -- Gold
            local gold = 0
            if itemData.Gold and type(itemData.Gold) == "table" and itemData.Gold.Amount then
                gold = itemData.Gold.Amount
            end
            statsLabels.Gold.Text = formatNumber(gold)

            -- Trait Reroll
            local traitReroll = 0
            if itemData.TraitReroll and type(itemData.TraitReroll) == "table" and itemData.TraitReroll.Amount then
                traitReroll = itemData.TraitReroll.Amount
            end
            statsLabels.TraitReroll.Text = formatNumber(traitReroll)
        end)

        if not success then
            warn("StatsGUI update error:", err)
        end
    end

    -- Update à¹à¸šà¸š Real-time (à¸•à¸£à¸§à¸ˆà¸ˆà¸±à¸šà¸à¸²à¸£à¹€à¸›à¸¥à¸µà¹ˆà¸¢à¸™à¹à¸›à¸¥à¸‡ + Error Handling)
    task.wait(2)
    updateStats()

    -- à¹€à¸à¹‡à¸šà¸„à¹ˆà¸²à¹€à¸à¹ˆà¸²à¹€à¸žà¸·à¹ˆà¸­à¹€à¸›à¸£à¸µà¸¢à¸šà¹€à¸—à¸µà¸¢à¸š
    local lastGem = 0
    local lastGold = 0
    local lastTrait = 0
    local errorCount = 0
    local maxErrors = 5
    local checkCounter = 0

    -- Initialize à¸„à¹ˆà¸²à¹€à¸£à¸´à¹ˆà¸¡à¸•à¹‰à¸™
    local success = pcall(function()
        local replica = Nodes.GET_PLAYER_REPLICA:InvokeSelf()
        if replica then
            local data = replica.Data
            local itemData = data.ItemData
            if itemData then
                lastGem = itemData.Gem and itemData.Gem.Amount or 0
                lastGold = itemData.Gold and itemData.Gold.Amount or 0
                lastTrait = itemData.TraitReroll and itemData.TraitReroll.Amount or 0
            end
        end
    end)

    -- à¹€à¸Šà¹‡à¸„à¸—à¸¸à¸ 0.5 à¸§à¸´à¸™à¸²à¸—à¸µà¹à¸—à¸™à¸—à¸¸à¸à¹€à¸Ÿà¸£à¸¡ (à¸¥à¸” CPU usage)
    spawn(function()
        while true do
            task.wait(0.5)  -- à¹€à¸Šà¹‡à¸„à¸—à¸¸à¸ 0.5 à¸§à¸´à¸™à¸²à¸—à¸µ (à¸›à¸£à¸°à¸«à¸¢à¸±à¸”à¸ªà¹€à¸›à¸„)

            local success, err = pcall(function()
                local replica = Nodes.GET_PLAYER_REPLICA:InvokeSelf()
                if not replica then
                    error("Replica not found")
                end

                local data = replica.Data
                if not data then
                    error("Data not found")
                end

                local itemData = data.ItemData
                if not itemData then
                    error("ItemData not found")
                end

                -- à¸”à¸¶à¸‡à¸„à¹ˆà¸²à¸›à¸±à¸ˆà¸ˆà¸¸à¸šà¸±à¸™
                local currentGem = itemData.Gem and type(itemData.Gem) == "table" and itemData.Gem.Amount or 0
                local currentGold = itemData.Gold and type(itemData.Gold) == "table" and itemData.Gold.Amount or 0
                local currentTrait = itemData.TraitReroll and type(itemData.TraitReroll) == "table" and itemData.TraitReroll.Amount or 0

                -- à¹€à¸Šà¹‡à¸„à¸§à¹ˆà¸²à¸„à¹ˆà¸²à¹€à¸›à¸¥à¸µà¹ˆà¸¢à¸™à¸«à¸£à¸·à¸­à¹„à¸¡à¹ˆ
                if currentGem ~= lastGem or currentGold ~= lastGold or currentTrait ~= lastTrait then
                    -- à¸­à¸±à¸žà¹€à¸”à¸—à¸—à¸±à¸™à¸—à¸µ
                    if currentGem ~= lastGem then
                        statsLabels.Gem.Text = formatNumber(currentGem)
                        lastGem = currentGem
                    end

                    if currentGold ~= lastGold then
                        statsLabels.Gold.Text = formatNumber(currentGold)
                        lastGold = currentGold
                    end

                    if currentTrait ~= lastTrait then
                        statsLabels.TraitReroll.Text = formatNumber(currentTrait)
                        lastTrait = currentTrait
                    end

                    -- Reset error count à¹€à¸¡à¸·à¹ˆà¸­à¸­à¸±à¸žà¹€à¸”à¸—à¸ªà¸³à¹€à¸£à¹‡à¸ˆ
                    errorCount = 0
                end
            end)

            -- Error Handling - à¸¥à¸­à¸‡ retry
            if not success then
                errorCount = errorCount + 1

                if errorCount <= maxErrors then
                    warn(string.format("âš ï¸ StatsGUI error (%d/%d): %s - Retrying...", errorCount, maxErrors, tostring(err)))

                    -- à¸žà¸¢à¸²à¸¢à¸²à¸¡ force update
                    task.spawn(function()
                        task.wait(0.5)
                        pcall(updateStats)
                    end)
                elseif errorCount == maxErrors + 1 then
                    warn(string.format("âŒ StatsGUI failed after %d attempts - Will keep trying silently", maxErrors))
                end
            end
        end
    end)

    -- ========================================
    -- Toggle GUI with N key (+ Render3D à¸–à¹‰à¸²à¹€à¸›à¸´à¸” Config)
    -- ========================================
    local UserInputService = game:GetService("UserInputService")
    local isGuiVisible = true

    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end

        if input.KeyCode == Enum.KeyCode.N then
            isGuiVisible = not isGuiVisible
            mainFrame.Visible = isGuiVisible

            if TOGGLE_RENDER3D then
                if isGuiVisible then
                    game:GetService("RunService"):Set3dRenderingEnabled(false)
                else
                    game:GetService("RunService"):Set3dRenderingEnabled(true)
                end
            end
        end
    end)

    if TOGGLE_RENDER3D then
        game:GetService("RunService"):Set3dRenderingEnabled(false)
    end

    -- ========================================
    -- Horst Status Reporter (Real-time + Error Handling + à¸ªà¹ˆà¸‡à¸—à¸¸à¸ 30 à¸§à¸´)
    -- ========================================
    if HORST_ENABLED then
        local doneSent = false
        local lastHorstGem = 0
        local lastHorstGold = 0
        local lastHorstTrait = 0
        local lastHorstLevel = 0
        local horstErrorCount = 0
        local maxHorstErrors = 5

        -- à¸Ÿà¸±à¸‡à¸à¹Œà¸Šà¸±à¸™à¸ªà¹ˆà¸‡ Status (à¸žà¸£à¹‰à¸­à¸¡ Error Handling)
        local function sendHorstStatus()
            local success, err = pcall(function()
                local replica = Nodes.GET_PLAYER_REPLICA:InvokeSelf()
                if not replica then
                    error("Replica not found")
                end

                local data = replica.Data
                if not data then
                    error("Data not found")
                end

                local itemData = data.ItemData
                if not itemData then
                    error("ItemData not found")
                end

                -- à¸”à¸¶à¸‡à¸‚à¹‰à¸­à¸¡à¸¹à¸¥ Stats
                local level = data.Level or 0
                local gem = itemData.Gem and type(itemData.Gem) == "table" and itemData.Gem.Amount or 0
                local gold = itemData.Gold and type(itemData.Gold) == "table" and itemData.Gold.Amount or 0
                local trait = itemData.TraitReroll and type(itemData.TraitReroll) == "table" and itemData.TraitReroll.Amount or 0

                -- à¸ªà¸£à¹‰à¸²à¸‡ Status Message
                local HttpService = game:GetService("HttpService")
                local json_data = {
                    Level = level,
                    Gem = gem,
                    Gold = gold,
                    Trait = trait
                }
                local encoded_json = HttpService:JSONEncode(json_data)

                local message = string.format("â­ Level : %d â€¢ ðŸ’Ž Gems : %s â€¢ ðŸª™ Gold : %s â€¢ ðŸŽ² RR : %s",
                    level, formatNumber(gem), formatNumber(gold), formatNumber(trait))

                -- à¸ªà¹ˆà¸‡ Status Update
                if _G.Horst_SetDescription then
                    _G.Horst_SetDescription(message, encoded_json)
                    horstErrorCount = 0  -- Reset error count à¹€à¸¡à¸·à¹ˆà¸­à¸ªà¹ˆà¸‡à¸ªà¸³à¹€à¸£à¹‡à¸ˆ
                end

                -- à¹€à¸Šà¹‡à¸„à¹€à¸›à¹‰à¸²à¸«à¸¡à¸²à¸¢ Gem (à¸–à¹‰à¸²à¸¡à¸µ GEM_TARGET)
                -- âš ï¸ à¸‚à¹‰à¸²à¸¡à¸à¸²à¸£à¹€à¸Šà¹‡à¸„à¸–à¹‰à¸²à¸¡à¸µ SummonUnits Config (à¸•à¹‰à¸­à¸‡à¹ƒà¸«à¹‰à¹„à¸›à¸ªà¸¸à¹ˆà¸¡à¸à¹ˆà¸­à¸™)
                if GEM_TARGET and gem >= GEM_TARGET and not doneSent and not hasSummonConfig then
                    if _G.Horst_AccountChangeDone then
                        -- à¸ªà¹ˆà¸‡ Description à¸à¹ˆà¸­à¸™
                        if _G.Horst_SetDescription then
                            _G.Horst_SetDescription(message, encoded_json)
                        end

                        task.wait(15)  -- à¸£à¸­ 15 à¸§à¸´à¸à¹ˆà¸­à¸™à¸ªà¹ˆà¸‡ DONE

                        local ok, doneErr = pcall(_G.Horst_AccountChangeDone)
                        if ok then
                            doneSent = true
                            _G.ScriptShouldStop = true  -- à¸•à¸±à¹‰à¸‡à¸„à¹ˆà¸² flag à¸«à¸¥à¸±à¸‡à¸ªà¹ˆà¸‡ DONE à¸ªà¸³à¹€à¸£à¹‡à¸ˆ
                            print("âœ… GEM_TARGET reached (no summon config) - Script will stop...")

                            -- Loop à¸ªà¹ˆà¸‡ Description à¸—à¸¸à¸ 5 à¸§à¸´à¸«à¸¥à¸±à¸‡ DONE
                            while true do
                                pcall(function()
                                    local replicaLoop = Nodes.GET_PLAYER_REPLICA:InvokeSelf()
                                    if replicaLoop and replicaLoop.Data and replicaLoop.Data.ItemData then
                                        local dataLoop = replicaLoop.Data
                                        local itemDataLoop = dataLoop.ItemData
                                        local levelLoop = dataLoop.Level or 0
                                        local gemLoop = itemDataLoop.Gem and type(itemDataLoop.Gem) == "table" and itemDataLoop.Gem.Amount or 0
                                        local goldLoop = itemDataLoop.Gold and type(itemDataLoop.Gold) == "table" and itemDataLoop.Gold.Amount or 0
                                        local traitLoop = itemDataLoop.TraitReroll and type(itemDataLoop.TraitReroll) == "table" and itemDataLoop.TraitReroll.Amount or 0

                                        local HttpService = game:GetService("HttpService")
                                        local json_data = {
                                            Level = levelLoop,
                                            Gem = gemLoop,
                                            Gold = goldLoop,
                                            Trait = traitLoop
                                        }
                                        local encoded_json = HttpService:JSONEncode(json_data)

                                        local messageLoop = string.format("â­ Level : %d â€¢ ðŸ’Ž Gems : %s â€¢ ðŸª™ Gold : %s â€¢ ðŸŽ² RR : %s",
                                            levelLoop, formatNumber(gemLoop), formatNumber(goldLoop), formatNumber(traitLoop))

                                        _G.Horst_SetDescription(messageLoop, encoded_json)
                                    end
                                end)
                                task.wait(5)
                            end
                        else
                            warn(string.format("âŒ Failed to send DONE: %s", tostring(doneErr)))
                        end
                    else
                        warn("âŒ Horst_AccountChangeDone function not found")
                    end
                end
            end)

            if not success then
                horstErrorCount = horstErrorCount + 1
                if horstErrorCount <= maxHorstErrors then
                    warn(string.format("âš ï¸ Horst error (%d/%d): %s - Retrying...", horstErrorCount, maxHorstErrors, tostring(err)))
                elseif horstErrorCount == maxHorstErrors + 1 then
                    warn(string.format("âŒ Horst failed after %d attempts - Will keep trying silently", maxHorstErrors))
                end
            end
        end

        -- Initialize à¸„à¹ˆà¸²à¹€à¸£à¸´à¹ˆà¸¡à¸•à¹‰à¸™
        task.wait(1)
        local initSuccess = pcall(function()
            local replica = Nodes.GET_PLAYER_REPLICA:InvokeSelf()
            if replica then
                local data = replica.Data
                local itemData = data.ItemData
                if data and itemData then
                    lastHorstLevel = data.Level or 0
                    lastHorstGem = itemData.Gem and itemData.Gem.Amount or 0
                    lastHorstGold = itemData.Gold and itemData.Gold.Amount or 0
                    lastHorstTrait = itemData.TraitReroll and itemData.TraitReroll.Amount or 0
                end
            end
        end)

        -- à¸ªà¹ˆà¸‡à¸£à¸­à¸šà¹à¸£à¸à¸—à¸±à¸™à¸—à¸µ (à¹€à¸‰à¸žà¸²à¸° GEM mode)
        if DESCRIPTION_MODE == "GEM" then
            sendHorstStatus()
        end

        -- Real-time update (à¹€à¸Šà¹‡à¸„à¸—à¸¸à¸ 1 à¸§à¸´à¸™à¸²à¸—à¸µ à¹à¸—à¸™ 0.3 à¸§à¸´ - à¸›à¸£à¸°à¸«à¸¢à¸±à¸”à¸ªà¹€à¸›à¸„)
        spawn(function()
            while HORST_ENABLED and not _G.ScriptShouldStop and DESCRIPTION_MODE == "GEM" do
                task.wait(1)  -- à¹€à¸Šà¹‡à¸„à¸—à¸¸à¸ 1 à¸§à¸´à¸™à¸²à¸—à¸µ (à¸›à¸£à¸°à¸«à¸¢à¸±à¸”à¸ªà¹€à¸›à¸„)

                local success, err = pcall(function()
                    local replica = Nodes.GET_PLAYER_REPLICA:InvokeSelf()
                    if not replica then
                        error("Replica not found")
                    end

                    local data = replica.Data
                    if not data then
                        error("Data not found")
                    end

                    local itemData = data.ItemData
                    if not itemData then
                        error("ItemData not found")
                    end

                    local currentLevel = data.Level or 0
                    local currentGem = itemData.Gem and type(itemData.Gem) == "table" and itemData.Gem.Amount or 0
                    local currentGold = itemData.Gold and type(itemData.Gold) == "table" and itemData.Gold.Amount or 0
                    local currentTrait = itemData.TraitReroll and type(itemData.TraitReroll) == "table" and itemData.TraitReroll.Amount or 0

                    -- à¹€à¸Šà¹‡à¸„à¸§à¹ˆà¸²à¸„à¹ˆà¸²à¹€à¸›à¸¥à¸µà¹ˆà¸¢à¸™à¸«à¸£à¸·à¸­à¹„à¸¡à¹ˆ
                    if currentLevel ~= lastHorstLevel or currentGem ~= lastHorstGem or
                       currentGold ~= lastHorstGold or currentTrait ~= lastHorstTrait then

                        -- à¸ªà¹ˆà¸‡ update à¸—à¸±à¸™à¸—à¸µ
                        sendHorstStatus()

                        -- à¸šà¸±à¸™à¸—à¸¶à¸à¸„à¹ˆà¸²à¹ƒà¸«à¸¡à¹ˆ
                        lastHorstLevel = currentLevel
                        lastHorstGem = currentGem
                        lastHorstGold = currentGold
                        lastHorstTrait = currentTrait
                    end
                end)

                if not success then
                    -- Silent retry - à¹„à¸¡à¹ˆ warn à¹€à¸žà¸£à¸²à¸°à¸ˆà¸°à¸¥à¸­à¸‡à¹ƒà¸«à¸¡à¹ˆà¹ƒà¸™ 1 à¸§à¸´
                end
            end
        end)

        -- Fallback: à¸ªà¹ˆà¸‡à¸—à¸¸à¸ 30 à¸§à¸´ (à¸à¸£à¸“à¸µ real-time à¸žà¸¥à¸²à¸”)
        spawn(function()
            while HORST_ENABLED and not _G.ScriptShouldStop and DESCRIPTION_MODE == "GEM" do
                task.wait(UPDATE_INTERVAL)
                sendHorstStatus()
            end
        end)
    end
end)

if not statsGuiSuccess then
    warn("âŒ StatsGUI failed to load:", statsGuiError)
end
task.wait(1)

-- Config (à¸ªà¸²à¸¡à¸²à¸£à¸–à¹à¸à¹‰à¹„à¸‚à¹„à¸”à¹‰à¸ˆà¸²à¸ loadstring)
_G.Config = _G.Config or {}

-- ========================================
-- à¸Ÿà¸±à¸‡à¸à¹Œà¸Šà¸±à¸™à¹€à¸Šà¹‡à¸„à¹à¸¡à¸ž - à¸•à¹‰à¸­à¸‡à¹€à¸Šà¹‡à¸„à¸«à¸¥à¸±à¸‡ Stats GUI à¹‚à¸«à¸¥à¸”à¹€à¸ªà¸£à¹‡à¸ˆ
-- ========================================
local function isInTargetMap()
    local success, result = pcall(function()
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local Nodes = require(ReplicatedStorage:WaitForChild("Nodes"))

        -- Method 1: à¹ƒà¸Šà¹‰ Map Replicas (à¹à¸¡à¹ˆà¸™à¸¢à¸³à¸à¸§à¹ˆà¸²)
        local allMaps = Nodes.GET_ALL_MAP_REPLICAS:InvokeSelf()

        if allMaps then
            for mapID, mapReplica in pairs(allMaps) do
                local data = mapReplica.Data
                local parameters = data.Parameters or {}

                -- à¹€à¸Šà¹‡à¸„à¸§à¹ˆà¸²à¹€à¸›à¹‡à¸™ SchoolGrounds Act 1 Story Mode
                if parameters.MapName == "SchoolGrounds" and
                   parameters.ActName == "Act 1" and
                   parameters.Gamemode == "Story" then
                    return true
                end
            end
        end

        return false
    end)
    return success and result
end

-- à¹€à¸Šà¹‡à¸„à¹à¸¥à¸°à¸£à¸­ Wave à¸£à¸µà¹€à¸‹à¹‡à¸•
-- ========================================
-- à¸Ÿà¸±à¸‡à¸à¹Œà¸Šà¸±à¸™ RemoveLobbyMesh (à¹ƒà¸Šà¹‰à¸£à¹ˆà¸§à¸¡à¸à¸±à¸™à¸£à¸°à¸«à¸§à¹ˆà¸²à¸‡ In-Game à¹à¸¥à¸° Lobby)
-- ========================================
local function applyPerformanceOptimizations()
    local g = game
    local w = g.Workspace
    local l = g.Lighting
    local t = w.Terrain

    -- à¹ƒà¸Šà¹‰à¹€à¸‰à¸žà¸²à¸° TOGGLE_RENDER3D (à¹€à¸­à¸² Config.Disable3DRendering à¸­à¸­à¸)
    if TOGGLE_RENDER3D then
        local RunService = game:GetService("RunService")
        RunService:Set3dRenderingEnabled(false)
        print("ðŸ”§ 3D Rendering disabled (TOGGLE_RENDER3D)")
    end

    t.WaterWaveSize = 0
    t.WaterWaveSpeed = 0
    t.WaterReflectance = 0
    t.WaterTransparency = 0

    local Lighting = game:GetService("Lighting")
    Lighting.Brightness = 0
    Lighting.Ambient = Color3.fromRGB(128, 128, 128)
    Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
    Lighting.ColorShift_Bottom = Color3.fromRGB(128, 128, 128)
    Lighting.ColorShift_Top = Color3.fromRGB(128, 128, 128)
    Lighting.GlobalShadows = false
    Lighting.ShadowSoftness = 0
    Lighting.EnvironmentDiffuseScale = 0
    Lighting.EnvironmentSpecularScale = 0
    Lighting.FogEnd = 9e9

    settings().Rendering.QualityLevel = "Level01"

    -- à¹€à¸Šà¹‡à¸„ Map à¸à¹ˆà¸­à¸™ (à¹€à¸žà¸£à¸²à¸°à¹€à¸¡à¸·à¹ˆà¸­à¸­à¸¢à¸¹à¹ˆà¹ƒà¸™à¹€à¸à¸¡à¹ƒà¸«à¹‰à¸¥à¸š Map à¹„à¸¡à¹ˆà¹ƒà¸Šà¹ˆ Lobby)
    local lobbyFolder = workspace:FindFirstChild("Lobby")
    local mapFolder = workspace:FindFirstChild("Map")

    if mapFolder then
        -- à¸¥à¸š children à¸‚à¸­à¸‡ Map (à¹€à¸à¸¡à¸ˆà¸°à¸ªà¸£à¹‰à¸²à¸‡ folder à¹ƒà¸«à¸¡à¹ˆà¸–à¹‰à¸²à¸¥à¸šà¸—à¸±à¹‰à¸‡à¸à¹‰à¸­à¸™)
        for _, obj in pairs(mapFolder:GetChildren()) do
            obj:Destroy()
        end

        -- à¸ªà¸£à¹‰à¸²à¸‡à¸žà¸·à¹‰à¸™à¸¥à¹ˆà¸­à¸‡à¸«à¸™à¹„à¸§à¹‰à¸—à¸µà¹ˆà¹€à¸—à¹‰à¸²à¸œà¸¹à¹‰à¹€à¸¥à¹ˆà¸™
        local player = game:GetService("Players").LocalPlayer
        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local rootPart = player.Character.HumanoidRootPart
            local invisibleFloor = Instance.new("Part")
            invisibleFloor.Name = "InvisibleFloor"
            invisibleFloor.Size = Vector3.new(2000, 1, 2000)
            invisibleFloor.Position = rootPart.Position - Vector3.new(0, 5, 0)
            invisibleFloor.Anchored = true
            invisibleFloor.Transparency = 1
            invisibleFloor.CanCollide = true
            invisibleFloor.Material = Enum.Material.SmoothPlastic
            invisibleFloor.Parent = workspace
        end
    elseif lobbyFolder then
        for _, obj in pairs(lobbyFolder:GetChildren()) do
            obj:Destroy()
        end

        -- à¸ªà¸£à¹‰à¸²à¸‡à¸žà¸·à¹‰à¸™à¸¥à¹ˆà¸­à¸‡à¸«à¸™à¸ªà¸³à¸«à¸£à¸±à¸š Lobby
        local player = game:GetService("Players").LocalPlayer
        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local pos = player.Character.HumanoidRootPart.Position
            local floor = Instance.new("Part")
            floor.Name = "InvisibleFloor"
            floor.Size = Vector3.new(2000, 1, 2000)
            floor.Position = Vector3.new(pos.X, pos.Y - 3, pos.Z)
            floor.Anchored = true
            floor.Transparency = 1
            floor.CanCollide = true
            floor.Material = Enum.Material.SmoothPlastic
            floor.Parent = workspace
        end
    end

    for _, obj in pairs(Lighting:GetChildren()) do
        obj:Destroy()
    end

    local MaterialService = game:GetService("MaterialService")
    for _, obj in pairs(MaterialService:GetChildren()) do
        obj:Destroy()
    end

    for _, obj in pairs(workspace:GetDescendants()) do
        local success, err = pcall(function()
            if obj:IsA("Texture") or obj:IsA("Decal") then
                obj.Transparency = 1
            elseif obj:IsA("SurfaceAppearance") then
                obj:Destroy()
            elseif obj:IsA("Part") or obj:IsA("Union") or obj:IsA("CornerWedgePart") or obj:IsA("TrussPart") or obj:IsA("UnionOperation") then
                obj.Material = "Plastic"
                obj.Color = Color3.fromRGB(128, 128, 128)
                obj.Reflectance = 0
            elseif obj:IsA("MeshPart") then
                obj.Material = "Plastic"
                obj.Color = Color3.fromRGB(128, 128, 128)
                obj.Reflectance = 0
                obj.TextureID = ""
            elseif obj:IsA("ParticleEmitter") or obj:IsA("Trail") then
                obj.Enabled = false
            elseif obj:IsA("Explosion") then
                obj.BlastPressure = 1
                obj.BlastRadius = 1
            elseif obj:IsA("Fire") or obj:IsA("SpotLight") or obj:IsA("Smoke") then
                obj.Enabled = false
            end
        end)
    end

    for _, e in pairs(Lighting:GetChildren()) do
        if e:IsA("BlurEffect") or e:IsA("SunRaysEffect") or e:IsA("ColorCorrectionEffect") or e:IsA("BloomEffect") or e:IsA("DepthOfFieldEffect") then
            e.Enabled = false
        end
    end

    for _, player in pairs(game.Players:GetPlayers()) do
        if player.Character then
            for _, part in pairs(player.Character:GetDescendants()) do
                pcall(function()
                    if part:IsA("Texture") or part:IsA("Decal") then
                        part.Transparency = 1
                    elseif part:IsA("MeshPart") then
                        part.TextureID = ""
                        part.Material = "Plastic"
                        part.Color = Color3.fromRGB(128, 128, 128)
                        part.Reflectance = 0
                    elseif part:IsA("BasePart") then
                        part.Material = "Plastic"
                        part.Color = Color3.fromRGB(128, 128, 128)
                        part.Reflectance = 0
                    elseif part:IsA("ParticleEmitter") or part:IsA("Trail") then
                        part.Enabled = false
                    elseif part:IsA("Fire") or part:IsA("SpotLight") or part:IsA("Smoke") then
                        part.Enabled = false
                    end
                end)
            end
        end
    end
end

-- ========================================
-- à¹€à¸Šà¹‡à¸„à¹à¸¡à¸žà¸«à¸¥à¸±à¸‡à¹‚à¸«à¸¥à¸” Stats GUI à¹€à¸ªà¸£à¹‡à¸ˆà¹à¸¥à¹‰à¸§
-- ========================================
print("ðŸ” Checking current map...")

-- à¸•à¸­à¸™à¸™à¸µà¹‰à¸­à¸¢à¸¹à¹ˆà¹ƒà¸™à¹à¸¡à¸žà¸«à¸£à¸·à¸­à¹„à¸¡à¹ˆ
if isInTargetMap() then
    print("âœ… In Story Mode (School Grounds - Act 1)")
    spawn(function()
        -- à¸›à¸´à¸” Tutorial popup (à¸–à¹‰à¸²à¸¡à¸µ)
        local function closeTutorial()
            local success = pcall(function()
                local playerGui = game:GetService("Players").LocalPlayer.PlayerGui
                local prompt = playerGui:FindFirstChild("Prompt")
                if not prompt then return end

                local tutorialLabel = prompt.Frame.Frame.Folder.Frame.Frame.Frame.TextLabel
                if tutorialLabel then
                    local text = tutorialLabel.ContentText or tutorialLabel.Text
                    if text == "Tutorial" then
                        local closeButton = prompt.Frame.Frame.Folder.Frame:FindFirstChild("PrimaryButton")
                        if closeButton then
                            local GuiService = game:GetService("GuiService")
                            local VirtualInputManager = game:GetService("VirtualInputManager")

                            GuiService.SelectedCoreObject = nil
                            task.wait(0.1)

                            closeButton.Selectable = true
                            GuiService.SelectedCoreObject = closeButton
                            task.wait(0.1)

                            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
                            task.wait(0.05)
                            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Return, false, game)

                            task.wait(0.2)
                            GuiService.SelectedCoreObject = nil

                            return
                        end
                    end
                end
            end)
        end

        closeTutorial()
        task.wait(0.5)

        applyPerformanceOptimizations()


    -- ====================================
    -- à¸£à¸°à¸šà¸šà¸§à¸²à¸‡ + à¸­à¸±à¸žà¹€à¸à¸£à¸” (à¹€à¸«à¸¡à¸·à¸­à¸™ Path B)
    -- ====================================
    local Players = game:GetService("Players")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local Nodes = require(ReplicatedStorage:WaitForChild("Nodes"))
    local Shared = ReplicatedStorage:WaitForChild("Shared")
    local ReplicaClient = require(Shared:WaitForChild("ReplicaClient"))

    -- à¸•à¸±à¸§à¹à¸›à¸£à¸ªà¸³à¸«à¸£à¸±à¸šà¹€à¸à¹‡à¸š Connection à¹à¸¥à¸° State
    local currentConnection = nil
    local allPlacedIDs = {}

    local function getCurrentWave()
        -- Method 1: à¸­à¹ˆà¸²à¸™à¸ˆà¸²à¸ Game Replica (à¸–à¸¹à¸à¸•à¹‰à¸­à¸‡ - à¸¢à¸·à¸™à¸¢à¸±à¸™à¸ˆà¸²à¸ CheckWave.lua)
        local success1, wave1 = pcall(function()
            local gameReplica = Nodes.GET_GAME_REPLICA:InvokeSelf()
            if gameReplica and gameReplica.Data and gameReplica.Data.Wave then
                return tonumber(gameReplica.Data.Wave) or 0
            end
            return nil
        end)

        if success1 and wave1 then
            return wave1
        end

        -- Method 2: Fallback - à¸­à¹ˆà¸²à¸™à¸ˆà¸²à¸ GUI (à¸žà¸£à¹‰à¸­à¸¡ timeout)
        local success2, wave2 = pcall(function()
            local startTime = tick()
            local timeout = 3

            while tick() - startTime < timeout do
                local topHUD = Players.LocalPlayer.PlayerGui:FindFirstChild("TopGameHUD")
                if topHUD then
                    local success, result = pcall(function()
                        local waveLabel = topHUD.Frame:GetChildren()[4].Frame.Frame.Frame.Frame.Frame.TextLabel
                        local text = waveLabel.ContentText or waveLabel.Text
                        return tonumber(string.match(text, "^(%d+)")) or 0
                    end)
                    if success and result then
                        return result
                    end
                end
                task.wait(0.5)
            end
            return nil
        end)

        if success2 and wave2 then
            warn("âš ï¸ Wave detection fallback to GUI (Game Replica failed)")
            return wave2
        end

        warn("âŒ Wave detection failed - both Replica and GUI methods failed")
        return nil  -- âš ï¸ return nil à¹à¸—à¸™ 0 à¹€à¸žà¸·à¹ˆà¸­à¹„à¸¡à¹ˆà¹ƒà¸«à¹‰ trigger false wave reset
    end

    local function resetFarmingState()
        print("ðŸ”„ [resetFarmingState] Resetting state...")
        -- Disconnect connection à¹€à¸à¹ˆà¸² (à¸–à¹‰à¸²à¸¡à¸µ)
        if currentConnection then
            pcall(function()
                currentConnection:Disconnect()
                print("   âœ… [resetFarmingState] Disconnected old connection")
            end)
            currentConnection = nil
        end

        -- à¸¥à¹‰à¸²à¸‡à¸‚à¹‰à¸­à¸¡à¸¹à¸¥ Unit à¹€à¸à¹ˆà¸²
        local oldCount = #allPlacedIDs
        allPlacedIDs = {}
        print(string.format("   ðŸ—‘ï¸ [resetFarmingState] Cleared %d old unit IDs", oldCount))
    end

    local function placeAndUpgrade()
        print("â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•")
        print("ðŸŽ® [placeAndUpgrade] Starting new phase")
        print("â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•")

        local DELAY_AFTER_PLACE = 1
        local AUTO_UPGRADE_PRIORITY = 1

        local function getCurrentMoney()
            -- Method 1: à¸­à¹ˆà¸²à¸™à¸ˆà¸²à¸ Replica (à¹€à¸Šà¸·à¹ˆà¸­à¸–à¸·à¸­à¹„à¸”à¹‰à¸à¸§à¹ˆà¸²)
            local success, money = pcall(function()
                local replica = Nodes.GET_GAME_PLAYER_REPLICA:InvokeSelf()
                if replica and replica.Data and replica.Data.Yen then
                    return replica.Data.Yen
                end
                return nil
            end)

            if success and money then
                return money
            else
                warn("âš ï¸ [getCurrentMoney] Replica method failed, using GUI fallback")
            end

            -- Method 2: Fallback à¸­à¹ˆà¸²à¸™à¸ˆà¸²à¸ GUI
            local success2, money2 = pcall(function()
                local bottomHUD = Players.LocalPlayer.PlayerGui:FindFirstChild("BottomHUD")
                if not bottomHUD then return 0 end
                local moneyLabel = bottomHUD:GetChildren()[2]:GetChildren()[6].Frame.Frame.TextLabel
                local moneyText = moneyLabel.ContentText
                local cleaned = (moneyText:gsub("[^%d]", ""))
                return tonumber(cleaned) or 0
            end)

            if not success2 or not money2 or money2 == 0 then
                warn("âŒ [getCurrentMoney] Both Replica and GUI methods failed")
            end
            return success2 and money2 or 0
        end

        local function getUnitCost(slot)
            local targetSlot = tonumber(slot)
            if not targetSlot then
                warn(string.format("âŒ [getUnitCost] Invalid slot: %s", tostring(slot)))
                return 999999
            end

            local attempts = 0
            while attempts < 10 do  -- à¸ªà¸¹à¸‡à¸ªà¸¸à¸” 10 à¸„à¸£à¸±à¹‰à¸‡ (5 à¸§à¸´à¸™à¸²à¸—à¸µ)
                local success, result, errorMsg = pcall(function()
                    local bottomHUD = Players.LocalPlayer.PlayerGui:FindFirstChild("BottomHUD")
                    if not bottomHUD then return nil, "BottomHUD not found" end

                    -- à¹ƒà¸Šà¹‰ pcall à¸ªà¸³à¸«à¸£à¸±à¸š GetChildren à¹€à¸žà¸·à¹ˆà¸­à¸„à¸§à¸²à¸¡à¸›à¸¥à¸­à¸”à¸ à¸±à¸¢
                    local success1, children2 = pcall(function()
                        return bottomHUD:GetChildren()[2]
                    end)
                    if not success1 or not children2 then return nil, "Cannot access children[2]" end

                    local success2, children5 = pcall(function()
                        return children2:GetChildren()[5]
                    end)
                    if not success2 or not children5 then return nil, "Cannot access children[5]" end

                    local hotbarContainer = children5

                    for _, child in ipairs(hotbarContainer:GetChildren()) do
                        if child:IsA("TextButton") and child.LayoutOrder == targetSlot then
                            -- à¹ƒà¸Šà¹‰ FindFirstChild à¹à¸—à¸™ direct access
                            local frame = child:FindFirstChild("Frame")
                            if not frame then return nil, "No Frame in button" end

                            local children = frame:GetChildren()
                            if children[3] and children[3]:IsA("Frame") then
                                local innerFrame = children[3]:FindFirstChild("Frame")
                                if innerFrame then
                                    local textLabel = innerFrame:FindFirstChild("TextLabel")
                                    if textLabel then
                                        local costText = textLabel.ContentText or textLabel.Text
                                        local cleaned = (costText:gsub("[^%d]", ""))
                                        local parsed = tonumber(cleaned)
                                        if parsed and parsed > 0 then
                                            return parsed, nil
                                        else
                                            return nil, "Failed to parse cost text: " .. costText
                                        end
                                    else
                                        return nil, "No TextLabel in innerFrame"
                                    end
                                else
                                    return nil, "No inner Frame in child[3]"
                                end
                            else
                                return nil, "No Frame at child[3]"
                            end
                        end
                    end
                    return nil, string.format("Slot %d not found in hotbar", targetSlot)
                end)

                if success and result then
                    return result
                elseif success and not result then
                    -- pcall à¸ªà¸³à¹€à¸£à¹‡à¸ˆà¹à¸•à¹ˆà¹„à¸¡à¹ˆà¹€à¸ˆà¸­à¸£à¸²à¸„à¸²
                    if attempts == 0 then
                        warn(string.format("âš ï¸ [getUnitCost] Slot %s error: %s (attempt %d/10)", slot, tostring(errorMsg), attempts + 1))
                    end
                else
                    -- pcall à¸¥à¹‰à¸¡à¹€à¸«à¸¥à¸§
                    if attempts == 0 then
                        warn(string.format("âš ï¸ [getUnitCost] Slot %s pcall failed: %s (attempt %d/10)", slot, tostring(result), attempts + 1))
                    end
                end

                attempts = attempts + 1
                task.wait(0.5)
            end

            warn(string.format("âš ï¸ [getUnitCost] Failed to detect cost for slot %s after 10 attempts", slot))
            return 999999
        end

        print("ðŸ” [placeAndUpgrade] Getting Player Replica...")
        local playerReplica = nil
        for i = 1, 5 do
            playerReplica = Nodes.GET_GAME_PLAYER_REPLICA:InvokeSelf()
            if playerReplica then
                print(string.format("âœ… [placeAndUpgrade] Player Replica found (attempt %d/5)", i))
                break
            end
            warn(string.format("âš ï¸ [placeAndUpgrade] PlayerReplica not found - retry %d/5", i))
            task.wait(1)
        end

        if not playerReplica then
            warn("âŒ [placeAndUpgrade] à¹„à¸¡à¹ˆà¸žà¸š Player Replica - aborting phase")
            return false
        end

        -- à¸£à¸µà¹€à¸‹à¹‡à¸• state à¸à¹ˆà¸­à¸™à¹€à¸£à¸´à¹ˆà¸¡ Phase à¹ƒà¸«à¸¡à¹ˆ
        print("ðŸ”„ [placeAndUpgrade] Resetting farming state...")
        resetFarmingState()

        -- à¸”à¸¶à¸‡ units à¸—à¸µà¹ˆà¸¡à¸µà¸­à¸¢à¸¹à¹ˆà¹à¸¥à¹‰à¸§à¸à¹ˆà¸­à¸™à¸ªà¸£à¹‰à¸²à¸‡ connection
        print("ðŸ“‹ [placeAndUpgrade] Loading existing units...")
        pcall(function()
            local dependenciesModule = ReplicatedStorage:FindFirstChild("Dependencies")
            if dependenciesModule then
                local Dependencies = require(dependenciesModule)
                local GameUnits = Dependencies.GameUnits
                if GameUnits then
                    local existingCount = 0
                    for unitID, _ in pairs(GameUnits:get()) do
                        if not table.find(allPlacedIDs, unitID) then
                            table.insert(allPlacedIDs, unitID)
                            existingCount = existingCount + 1
                        end
                    end
                    print(string.format("   ðŸ“Š [placeAndUpgrade] Loaded %d existing units", existingCount))
                end
            end
        end)

        -- à¸ªà¸£à¹‰à¸²à¸‡ Connection à¹ƒà¸«à¸¡à¹ˆ
        print("ðŸ”— [placeAndUpgrade] Creating unit tracker connection...")
        currentConnection = ReplicaClient.OnNew("GameUnit", function(replica)
            local unitID = replica.Data.ID
            if unitID and not table.find(allPlacedIDs, unitID) then
                table.insert(allPlacedIDs, unitID)
                print(string.format("   ðŸ†• [UnitTracker] New unit detected: %s", tostring(unitID)))
            end
        end)

        -- à¸£à¸­à¹ƒà¸«à¹‰ connection à¸žà¸£à¹‰à¸­à¸¡ (à¹à¸à¹‰ race condition)
        print("â³ [placeAndUpgrade] Waiting for connection to be ready...")
        task.wait(2)

        local function placeUnit(slot, cframe)
            -- Validate slot à¸¡à¸µ unit à¸«à¸£à¸·à¸­à¹„à¸¡à¹ˆ
            local cost = getUnitCost(slot)

            if cost == 0 then
                warn(string.format("âŒ [PlaceUnit] Slot %s is empty or unavailable - skipping", slot))
                return false
            end

            local startCount = #allPlacedIDs

            -- à¹€à¸žà¸´à¹ˆà¸¡ random offset 0.5 studs
            local randomX = (math.random() - 0.5) * 0.5
            local randomZ = (math.random() - 0.5) * 0.5
            local adjustedCFrame = cframe * CFrame.new(randomX, 0, randomZ)

            print(string.format("ðŸ”„ [PlaceUnit] Attempting to place Slot %s (Cost: %d, Money: %d)", slot, cost, getCurrentMoney()))

            local attempts = 0
            while attempts < 60 do
                local money = getCurrentMoney()
                local shouldContinue = false

                -- à¸–à¹‰à¸² cost = 999999 (detect à¹„à¸¡à¹ˆà¹„à¸”à¹‰) â†’ retry getUnitCost() à¸à¹ˆà¸­à¸™
                if cost == 999999 then
                    warn(string.format("âš ï¸ [PlaceUnit] Cannot detect cost for slot %s - retrying detection", slot))
                    local newCost, costErr = getUnitCost(slot)
                    if newCost and newCost ~= 999999 then
                        cost = newCost
                        print(string.format("âœ… [PlaceUnit] Cost detected: %d", cost))
                    else
                        warn(string.format("âš ï¸ [PlaceUnit] Still cannot detect cost - waiting before retry"))
                        attempts = attempts + 1
                        task.wait(1)
                        shouldContinue = true
                    end
                end

                -- à¹€à¸Šà¹‡à¸„à¹€à¸‡à¸´à¸™à¸•à¸²à¸¡à¸›à¸à¸•à¸´
                if not shouldContinue and money >= cost then

                    local success, err = pcall(function()
                        playerReplica:FireServer("PlaceGameUnit", slot, adjustedCFrame)
                    end)

                    if success then
                        task.wait(DELAY_AFTER_PLACE)

                        local waited = 0
                        while #allPlacedIDs <= startCount and waited < 5 do
                            task.wait(0.1)
                            waited = waited + 0.1
                        end

                        if #allPlacedIDs > startCount then
                            local newUnitID = allPlacedIDs[#allPlacedIDs]
                            print(string.format("   âœ… [PlaceUnit] Successfully placed Slot %s (Unit ID: %s)", slot, tostring(newUnitID)))
                            return true
                        else
                            warn(string.format("âš ï¸ [PlaceUnit] Place retry: Slot=%s, Cost=%d, Money=%d, Attempt=%d/60", slot, cost, money, attempts + 1))
                            attempts = attempts + 1
                            task.wait(1)
                        end
                    else
                        warn(string.format("âŒ [PlaceUnit] FireServer failed: Slot=%s, Attempt=%d/60, Error=%s", slot, attempts + 1, tostring(err)))
                        attempts = attempts + 1
                        task.wait(1)
                    end
                elseif not shouldContinue then
                    if attempts % 10 == 0 then
                        print(string.format("â³ [PlaceUnit] Waiting for money: Slot=%s, Need=%d, Have=%d, Attempt=%d/60", slot, cost, money, attempts + 1))
                    end
                    task.wait(1)
                    attempts = attempts + 1
                end
            end

            warn(string.format("âŒ [PlaceUnit] Place timeout after 60 attempts: Slot=%s, Cost=%d", slot, cost))
            return false
        end

        print("ðŸ”„ [Phase] Starting placement sequence...")

        -- à¸Ÿà¸±à¸‡à¸à¹Œà¸Šà¸±à¸™à¹€à¸Šà¹‡à¸„à¸Šà¸·à¹ˆà¸­ Unit à¸ˆà¸²à¸ HotbarData (Replica)
        local function getUnitNameFromSlot(slot)
            local success, unitName = pcall(function()
                local replica = Nodes.GET_PLAYER_REPLICA:InvokeSelf()
                if not replica or not replica.Data or not replica.Data.HotbarData then
                    return nil
                end

                -- à¸­à¹ˆà¸²à¸™ fullKey à¸ˆà¸²à¸ HotbarData
                local fullKey = replica.Data.HotbarData[slot] or replica.Data.HotbarData[tostring(slot)]
                if not fullKey then return nil end

                -- à¹à¸¢à¸ internal name (format: "UnitName#uuid")
                local internalName = fullKey:match("^(.+)#") or fullKey

                -- à¹à¸›à¸¥à¸‡à¹€à¸›à¹‡à¸™ Display Name
                local UnitInfo = require(ReplicatedStorage.Shared.Information.Units)
                local unitInfo = UnitInfo[internalName]

                if unitInfo then
                    return unitInfo.DisplayName or internalName
                end

                return internalName
            end)

            if success and unitName then
                return unitName
            end
            return nil
        end

        -- à¹€à¸Šà¹‡à¸„à¸§à¹ˆà¸² unit à¸—à¸µà¹ˆ equip à¸­à¸¢à¸¹à¹ˆà¹€à¸›à¹‡à¸™à¸•à¸±à¸§à¸—à¸µà¹ˆà¸§à¸²à¸‡à¹„à¸”à¹‰à¹à¸„à¹ˆ 3 à¸•à¸±à¸§à¸«à¸£à¸·à¸­à¹„à¸¡à¹ˆ
        local PLACEMENT_LIMITED_UNITS = {"Greed", "Scissor", "Water Princess"}
        local equippedUnitName = getUnitNameFromSlot("2")  -- slot 2 à¸„à¸·à¸­ unit à¸«à¸¥à¸±à¸
        local isPlacementLimited = false

        if equippedUnitName then
            print(string.format("ðŸ” [Phase] Equipped unit in slot 2: %s", equippedUnitName))
            for _, limitedUnit in ipairs(PLACEMENT_LIMITED_UNITS) do
                if equippedUnitName == limitedUnit then
                    isPlacementLimited = true
                    print(string.format("âš ï¸ [Phase] Unit '%s' is placement-limited (max 3 units) - will skip Unit 4", equippedUnitName))
                    break
                end
            end
        else
            warn("âš ï¸ [Phase] Could not detect equipped unit name - will place all 4 units")
        end

        -- Phase 1-2: à¸§à¸²à¸‡ 4 à¸•à¸±à¸§ (à¸«à¸£à¸·à¸­ 3 à¸•à¸±à¸§à¸–à¹‰à¸²à¹€à¸›à¹‡à¸™ limited unit)
        local unit1ID = nil
        local startCount = #allPlacedIDs
        print("ðŸ“ [Phase 1] Placing Unit 1...")
        local success1 = placeUnit("2", CFrame.new(3077.4265136719, 1798.7340087891, 3330.8972167969))
        if success1 and #allPlacedIDs > startCount then
            unit1ID = allPlacedIDs[#allPlacedIDs]
            print(string.format("âœ… [Phase 1] Unit 1 placed (ID: %s)", tostring(unit1ID)))
        else
            warn("âŒ [Phase 1] Failed to place Unit 1 - aborting phase")
            return false
        end

        local upgradeUnits = {}

        startCount = #allPlacedIDs
        print("ðŸ“ [Phase 1] Placing Unit 2...")
        local success2 = placeUnit("2", CFrame.new(3092.5168457031, 1798.9315185547, 3367.4926757812))
        if success2 and #allPlacedIDs > startCount then
            table.insert(upgradeUnits, allPlacedIDs[#allPlacedIDs])
            print(string.format("âœ… [Phase 1] Unit 2 placed (ID: %s)", tostring(allPlacedIDs[#allPlacedIDs])))
        else
            warn("âŒ [Phase 1] Failed to place Unit 2 - aborting phase")
            return false
        end

        startCount = #allPlacedIDs
        print("ðŸ“ [Phase 2] Placing Unit 3...")
        local success3 = placeUnit("2", CFrame.new(3092.3759765625, 1798.9315185547, 3370.3395996094))
        if success3 and #allPlacedIDs > startCount then
            table.insert(upgradeUnits, allPlacedIDs[#allPlacedIDs])
            print(string.format("âœ… [Phase 2] Unit 3 placed (ID: %s)", tostring(allPlacedIDs[#allPlacedIDs])))
        else
            warn("âŒ [Phase 2] Failed to place Unit 3 - aborting phase")
            return false
        end

        -- Phase 2 Unit 4: à¸‚à¹‰à¸²à¸¡à¸–à¹‰à¸²à¹€à¸›à¹‡à¸™ placement-limited unit
        if isPlacementLimited then
            print("â­ï¸ [Phase 2] Skipping Unit 4 (placement-limited unit equipped)")
        else
            startCount = #allPlacedIDs
            print("ðŸ“ [Phase 2] Placing Unit 4...")
            local success4 = placeUnit("2", CFrame.new(3092.3918457031, 1798.9315185547, 3373.3002929688))
            if success4 and #allPlacedIDs > startCount then
                table.insert(upgradeUnits, allPlacedIDs[#allPlacedIDs])
                print(string.format("âœ… [Phase 2] Unit 4 placed (ID: %s)", tostring(allPlacedIDs[#allPlacedIDs])))
            else
                warn("âŒ [Phase 2] Failed to place Unit 4 - aborting phase")
                return false
            end
        end

        -- Phase 3: à¸£à¸­ 30 à¸§à¸´
        print("â³ [Phase 3] Waiting 30 seconds...")
        task.wait(30)

        -- Phase 4: à¸‚à¸²à¸¢ Unit 1 + à¸§à¸²à¸‡ Unit 5
        print("ðŸ’° [Phase 4] Selling Unit 1...")
        if unit1ID then
            local success, err = pcall(function()
                playerReplica:FireServer("SellGameUnit", unit1ID)
            end)
            if success then
                print(string.format("   âœ… [Phase 4] Sold Unit 1 (ID: %s)", tostring(unit1ID)))
            else
                warn(string.format("   âš ï¸ [Phase 4] Failed to sell Unit 1 (ID=%s): %s", tostring(unit1ID), tostring(err)))
            end
            task.wait(0.5)
        else
            warn("âš ï¸ [Phase 4] unit1ID is nil - cannot sell Unit 1")
        end

        startCount = #allPlacedIDs
        print("ðŸ“ [Phase 4] Placing Unit 5...")
        local success5 = placeUnit("2", CFrame.new(3095.4975585938, 1798.7340087891, 3365.9299316406))
        if success5 and #allPlacedIDs > startCount then
            table.insert(upgradeUnits, allPlacedIDs[#allPlacedIDs])
            print(string.format("âœ… [Phase 4] Unit 5 placed (ID: %s)", tostring(allPlacedIDs[#allPlacedIDs])))
        else
            warn("âš ï¸ [Phase 4] Failed to place Unit 5 - continuing with existing units...")
        end

        -- Phase 5: à¸£à¸­ 2 à¸§à¸´
        print("â³ [Phase 5] Waiting 2 seconds...")
        task.wait(2)

        -- Disconnect connection à¹ƒà¸«à¸¡à¹ˆà¸—à¸µà¹ˆà¸ªà¸£à¹‰à¸²à¸‡à¹ƒà¸™ Phase à¸™à¸µà¹‰
        if currentConnection then
            currentConnection:Disconnect()
            currentConnection = nil
        end

        -- Phase 6: à¸•à¸±à¹‰à¸‡ AutoUpgrade Priority
        print(string.format("ðŸ”§ [Phase 6] Setting AutoUpgrade priority for %d units...", #upgradeUnits))
        for i, unitID in ipairs(upgradeUnits) do
            local success, err = pcall(function()
                playerReplica:FireServer("ChangeGameUnitAutoUpgradePriority", unitID, AUTO_UPGRADE_PRIORITY)
            end)
            if success then
                print(string.format("   âœ… [Phase 6] Priority set for unit %d/%d (ID: %s)", i, #upgradeUnits, tostring(unitID)))
            else
                warn(string.format("   âš ï¸ [Phase 6] Failed to set priority for unit %s: %s", tostring(unitID), tostring(err)))
            end
            task.wait(0.3)
        end

        print("âœ… [Phase] All phases completed successfully")
        return true
    end

    -- Anti-AFK Walk Loop (à¹€à¸”à¸´à¸™à¸§à¸™à¹ƒà¸™à¹à¸¡à¸ž)
    spawn(function()
        local Players = game:GetService("Players")
        local player = Players.LocalPlayer

        task.wait(5)

        local waypoints = {
            Vector3.new(3089, 0, 3271),
            Vector3.new(3089, 0, 3350)
        }

        local currentWaypointIndex = 1

        while true do
            task.wait(0.1)

            if not isInTargetMap() then
                break
            end

            local character = player.Character
            if not character then
                task.wait(1)
                continue
            end

            local humanoid = character:FindFirstChild("Humanoid")
            local hrp = character:FindFirstChild("HumanoidRootPart")

            if not humanoid or not hrp then
                task.wait(1)
                continue
            end

            local targetPos = waypoints[currentWaypointIndex]
            local distance = (Vector3.new(hrp.Position.X, 0, hrp.Position.Z) - Vector3.new(targetPos.X, 0, targetPos.Z)).Magnitude

            if distance > 5 then
                humanoid:MoveTo(Vector3.new(targetPos.X, hrp.Position.Y, targetPos.Z))
                task.wait(0.5)
            else
                currentWaypointIndex = currentWaypointIndex + 1
                if currentWaypointIndex > #waypoints then
                    currentWaypointIndex = 1
                end
                task.wait(0.5)
            end
        end
    end)

    -- Auto Claim Quest/Achievement Loop (à¸—à¸¸à¸ 5 à¸™à¸²à¸—à¸µ)
    spawn(function()
        -- Claim à¸—à¸±à¸™à¸—à¸µ 1 à¸£à¸­à¸šà¸à¹ˆà¸­à¸™
        pcall(function()
            local replica = Nodes.GET_PLAYER_REPLICA:InvokeSelf()
            if replica and replica.Data.QuestData then
                local questData = replica.Data.QuestData
                local claimCount = 0

                for categoryName, _ in pairs(questData) do
                    spawn(function()
                        pcall(function()
                            Nodes.QUEST_CLAIM_ALL_CATEGORY:FireServer(categoryName)
                            claimCount = claimCount + 1
                        end)
                    end)
                    task.wait(0.05)
                end

                task.wait(2)

                local VirtualInputManager = game:GetService("VirtualInputManager")
                for i = 1, 10 do
                    VirtualInputManager:SendMouseButtonEvent(10, 10, 0, true, game, 0)
                    task.wait(0.05)
                    VirtualInputManager:SendMouseButtonEvent(10, 10, 0, false, game, 0)
                    task.wait(0.1)
                end
            end
        end)

        -- à¸§à¸™à¸¥à¸¹à¸›à¸—à¸¸à¸ 5 à¸™à¸²à¸—à¸µ
        while true do
            task.wait(300) -- 5 à¸™à¸²à¸—à¸µ

            pcall(function()
                local replica = Nodes.GET_PLAYER_REPLICA:InvokeSelf()
                if replica and replica.Data.QuestData then
                    local questData = replica.Data.QuestData
                    local claimCount = 0

                    for categoryName, _ in pairs(questData) do
                        spawn(function()
                            pcall(function()
                                Nodes.QUEST_CLAIM_ALL_CATEGORY:FireServer(categoryName)
                                claimCount = claimCount + 1
                            end)
                        end)
                        task.wait(0.05)
                    end

                    task.wait(2)

                    local VirtualInputManager = game:GetService("VirtualInputManager")
                    for i = 1, 10 do
                        VirtualInputManager:SendMouseButtonEvent(10, 10, 0, true, game, 0)
                        task.wait(0.05)
                        VirtualInputManager:SendMouseButtonEvent(10, 10, 0, false, game, 0)
                        task.wait(0.1)
                    end
                else
                    warn("âš ï¸ Quest claim failed: Replica or QuestData not found")
                end
            end)
        end
    end)

    task.wait(5)

        -- à¸Ÿà¸±à¸‡à¸à¹Œà¸Šà¸±à¸™à¸‚à¸²à¸¢ Unit à¸—à¸±à¹‰à¸‡à¸«à¸¡à¸” (à¹€à¸£à¸µà¸¢à¸à¸à¹ˆà¸­à¸™à¹€à¸£à¸´à¹ˆà¸¡ Phase à¹ƒà¸«à¸¡à¹ˆ)
        local function sellAllUnits()
            local soldCount = 0
            local failCount = 0

            print("ðŸ”„ [Wave Reset] Selling all existing units...")

            -- à¸”à¸¶à¸‡ playerReplica à¹ƒà¸«à¸¡à¹ˆ
            local playerReplica = Nodes.GET_GAME_PLAYER_REPLICA:InvokeSelf()
            if not playerReplica then
                warn("âŒ [sellAllUnits] Failed to get playerReplica")
                return false
            end

            -- Method 1: à¹ƒà¸Šà¹‰ Dependencies.GameUnits (à¹€à¸£à¹‡à¸§à¸à¸§à¹ˆà¸²)
            local success1 = pcall(function()
                local dependenciesModule = ReplicatedStorage:FindFirstChild("Dependencies")
                if dependenciesModule then
                    local Dependencies = require(dependenciesModule)
                    local GameUnits = Dependencies.GameUnits
                    if GameUnits then
                        local units = GameUnits:get()
                        for unitID, _ in pairs(units) do
                            local sellSuccess, sellErr = pcall(function()
                                playerReplica:FireServer("SellGameUnit", unitID)
                            end)

                            if sellSuccess then
                                soldCount = soldCount + 1
                                print(string.format("   âœ… Sold unit ID: %s", tostring(unitID)))
                            else
                                failCount = failCount + 1
                                warn(string.format("   âš ï¸ Failed to sell unit ID %s: %s", tostring(unitID), tostring(sellErr)))
                            end

                            task.wait(0.2)  -- à¸«à¸™à¹ˆà¸§à¸‡à¹€à¸¥à¹‡à¸à¸™à¹‰à¸­à¸¢à¸£à¸°à¸«à¸§à¹ˆà¸²à¸‡à¸‚à¸²à¸¢
                        end
                    end
                end
            end)

            if not success1 then
                warn("âš ï¸ Method 1 (Dependencies) failed - trying Method 2 (allPlacedIDs)")

                -- Method 2: Fallback à¹ƒà¸Šà¹‰ allPlacedIDs
                if #allPlacedIDs > 0 then
                    for _, unitID in ipairs(allPlacedIDs) do
                        local sellSuccess, sellErr = pcall(function()
                            playerReplica:FireServer("SellGameUnit", unitID)
                        end)

                        if sellSuccess then
                            soldCount = soldCount + 1
                            print(string.format("   âœ… Sold unit ID: %s", tostring(unitID)))
                        else
                            failCount = failCount + 1
                            warn(string.format("   âš ï¸ Failed to sell unit ID %s: %s", tostring(unitID), tostring(sellErr)))
                        end

                        task.wait(0.2)
                    end
                end
            end

            print(string.format("âœ… [Wave Reset] Sold %d units (Failed: %d)", soldCount, failCount))
            task.wait(1)

            -- Return logic:
            -- - true: à¸–à¹‰à¸²à¸‚à¸²à¸¢à¸ªà¸³à¹€à¸£à¹‡à¸ˆà¸­à¸¢à¹ˆà¸²à¸‡à¸™à¹‰à¸­à¸¢ 1 à¸•à¸±à¸§ à¸«à¸£à¸·à¸­à¹„à¸¡à¹ˆà¸¡à¸µ unit à¹€à¸¥à¸¢ (soldCount=0 à¹à¸¥à¸° failCount=0)
            -- - false: à¸–à¹‰à¸²à¸¡à¸µ unit à¹à¸•à¹ˆà¸‚à¸²à¸¢à¹„à¸¡à¹ˆà¸ªà¸³à¹€à¸£à¹‡à¸ˆà¹€à¸¥à¸¢ (soldCount=0 à¹à¸¥à¸° failCount>0)
            if failCount > 0 and soldCount == 0 then
                warn("âš ï¸ [sellAllUnits] All sell attempts failed")
                return false
            else
                return true  -- à¸ªà¸³à¹€à¸£à¹‡à¸ˆ à¸«à¸£à¸·à¸­à¹„à¸¡à¹ˆà¸¡à¸µ unit
            end
        end

        local isRunningPhase = false
        local lastWaveResetTime = 0
        local WAVE_RESET_COOLDOWN = 5  -- à¸›à¹‰à¸­à¸‡à¸à¸±à¸™ trigger à¸‹à¹‰à¸³à¸ à¸²à¸¢à¹ƒà¸™ 5 à¸§à¸´à¸™à¸²à¸—à¸µ

        print("ðŸ”„ [In-Game] Starting initial phase...")
        placeAndUpgrade()

        while true do
            task.wait(1)

            if isRunningPhase then
                continue
            end

            local currentWave = getCurrentWave()

            -- âš ï¸ à¸–à¹‰à¸² getCurrentWave() fail (return nil) à¹ƒà¸«à¹‰à¸‚à¹‰à¸²à¸¡à¸£à¸­à¸šà¸™à¸µà¹‰
            if currentWave == nil then
                warn("âš ï¸ [Wave Monitor] getCurrentWave() returned nil - skipping this check")
                continue
            end

            local currentTime = tick()

            if (currentWave == 0 or currentWave == 1) and (currentTime - lastWaveResetTime) >= WAVE_RESET_COOLDOWN then
                print(string.format("ðŸ”„ [Wave Reset] Detected at Wave %d - preparing new phase", currentWave))
                isRunningPhase = true
                lastWaveResetTime = currentTime
                task.wait(2)

                -- à¸‚à¸²à¸¢ Unit à¹€à¸à¹ˆà¸²à¸—à¸±à¹‰à¸‡à¸«à¸¡à¸”à¸à¹ˆà¸­à¸™à¹€à¸£à¸´à¹ˆà¸¡ Phase à¹ƒà¸«à¸¡à¹ˆ
                local sellSuccess = sellAllUnits()
                if not sellSuccess then
                    warn("âš ï¸ [Wave Reset] Sell failed but continuing with new phase")
                end

                -- à¹€à¸Šà¹‡à¸„ Banner à¸–à¹‰à¸²à¸¡à¸µ Summon Config à¹à¸¥à¸°à¹€à¸‡à¸´à¸™à¹€à¸à¸´à¸™ 10000
                if hasSummonConfig and #SUMMON_CONFIG > 0 then
                    print("ðŸ” [Wave Reset] Checking banner for target units...")
                    local bannerCheckSuccess, bannerResult = pcall(function()
                        local replica = Nodes.GET_PLAYER_REPLICA:InvokeSelf()
                        if replica and replica.Data then
                            local itemData = replica.Data.ItemData
                            local gems = itemData and itemData.Gem and itemData.Gem.Amount or 0

                            print(string.format("   ðŸ’Ž Current Gems: %d", gems))

                            if gems >= 2500 then
                                print("   âœ… Gems >= 2500 - checking banner...")

                                -- à¹€à¸Šà¹‡à¸„à¸§à¹ˆà¸²à¹€à¸›à¹‡à¸™ Secret unit à¸«à¸£à¸·à¸­à¹„à¸¡à¹ˆ
                                local isSecretUnit = false
                                for _, configUnit in ipairs(SUMMON_CONFIG) do
                                    for _, secretUnit in ipairs(SECRET_UNITS) do
                                        if configUnit == secretUnit then
                                            isSecretUnit = true
                                            print(string.format("   â„¹ï¸ '%s' is a Secret unit - Banner always available", configUnit))
                                            break
                                        end
                                    end
                                    if isSecretUnit then break end
                                end

                                if isSecretUnit then
                                    -- Secret unit: à¸‚à¹‰à¸²à¸¡ Banner check
                                    print(string.format("âœ… [Wave Reset] Secret unit + gems >= 2500 â†’ Rejoining..."))
                                    task.wait(1)

                                    pcall(function()
                                        game:GetService("TeleportService"):Teleport(game.PlaceId, Players.LocalPlayer)
                                    end)
                                else
                                    -- Mythic unit: à¹€à¸Šà¹‡à¸„ Banner à¸•à¸²à¸¡à¸›à¸à¸•à¸´
                                    local bannerUnits = {}
                                    local bannerSuccess = pcall(function()
                                        local startTime = tick()
                                        local timeout = 5

                                        while tick() - startTime < timeout do
                                            local units = checkCurrentBanner()
                                            if #units > 0 then
                                                bannerUnits = units
                                                return
                                            end
                                            task.wait(0.5)
                                        end
                                    end)

                                    if bannerSuccess and #bannerUnits > 0 then
                                        print(string.format("   ðŸ“‹ Banner units found: %s", table.concat(bannerUnits, ", ")))

                                        -- à¹€à¸Šà¹‡à¸„à¸§à¹ˆà¸²à¸¡à¸µà¸•à¸±à¸§à¸—à¸µà¹ˆà¸•à¹‰à¸­à¸‡à¸à¸²à¸£à¸«à¸£à¸·à¸­à¹„à¸¡à¹ˆ
                                        local hasMatch = false
                                        local matchedUnit = nil
                                        for _, configUnit in pairs(SUMMON_CONFIG) do
                                            for _, bannerUnit in pairs(bannerUnits) do
                                                if configUnit == bannerUnit then
                                                    hasMatch = true
                                                    matchedUnit = configUnit
                                                    break
                                                end
                                            end
                                            if hasMatch then break end
                                        end

                                        if hasMatch then
                                            print(string.format("âœ… [Wave Reset] Target unit '%s' found in banner + gems >= 2500 â†’ Rejoining...", matchedUnit))
                                            task.wait(1)

                                            pcall(function()
                                                game:GetService("TeleportService"):Teleport(game.PlaceId, Players.LocalPlayer)
                                            end)
                                            return  -- à¸«à¸¢à¸¸à¸”à¸ªà¸„à¸£à¸´à¸›à¸•à¹Œ
                                        else
                                            warn("âš ï¸ [Wave Reset] No target units found in banner - continuing farming")
                                        end
                                    else
                                        warn("âš ï¸ [Wave Reset] Failed to check banner (timeout or error) - continuing farming")
                                    end
                                end
                            else
                                print(string.format("   â­ï¸ Gems < 2500 - skipping banner check"))
                            end
                        else
                            warn("âš ï¸ [Wave Reset] Failed to get Replica for banner check")
                        end
                    end)

                    if not bannerCheckSuccess then
                        warn(string.format("âš ï¸ [Wave Reset] Banner check error: %s - continuing farming", tostring(bannerResult)))
                    end
                end

                print("ðŸ”„ [Wave Reset] Starting new phase...")
                local success = placeAndUpgrade()
                isRunningPhase = false

                if not success then
                    warn("âš ï¸ [Wave Reset] Phase failed - will retry on next wave reset")
                else
                    print("âœ… [Wave Reset] Phase completed successfully")
                end
            end
        end
    end)

    -- à¸«à¸¢à¸¸à¸”à¸—à¸µà¹ˆà¸™à¸µà¹ˆ - à¹„à¸¡à¹ˆà¸£à¸±à¸™ Lobby scripts
    return
end

-- ========================================
-- LOBBY SCRIPTS (à¸£à¸±à¸™à¹€à¸‰à¸žà¸²à¸°à¸•à¸­à¸™à¹„à¸¡à¹ˆà¹„à¸”à¹‰à¸­à¸¢à¸¹à¹ˆà¹ƒà¸™à¹à¸¡à¸ž)
-- ========================================

-- ========================================
-- 1. RemoveLobbyMesh.lua (Boost FPS)
-- ========================================
printStep("Removing Lobby Mesh...")

-- à¹ƒà¸Šà¹‰à¸Ÿà¸±à¸‡à¸à¹Œà¸Šà¸±à¸™ Performance Optimization
applyPerformanceOptimizations()

task.wait(1)

-- ========================================
-- 2. Settings.lua
-- ========================================
printStep("Applying Settings...")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Nodes = require(ReplicatedStorage:WaitForChild("Nodes"))

local settings = {
    AutoSkipWaves = true,
    AutoVoteStart = true,
    AutoRetry = true,
    LowDetailMode = true,
    FastSummon = true,
    SummonMax = true,
    DisplayPinnedQuests = false,
    PathVisualizerEnabled = false,
    CameraShakeEnabled = false,
    OtherUnitsEnabled = false,
    OtherUnitVFXEnabled = false,
    OwnUnitVFXEnabled = false,
    AbilityVFXEnabled = false,
    UnitAuraEnabled = false,
    TraitAuraEnabled = false,
    BuffIndicatorsEnabled = false,
    DisplayUnitCircles = false,
    DisplayHealthBars = false,
    DisplayEnemyTags = false,
    DisplayEnemyStatusEffects = false,
    DisplayEnemyEffects = false,
    OtherCosmeticEnabled = false,
    OtherEmoteSFXEnabled = false,
    GlobalMessagesEnabled = false,
    DisplayUpdateLog = false,
    DamageIndicatorsEnabled = false,
    AutoPlacePhantoms = false,
    StrictPhantomPlacement = false
}

for settingName, value in pairs(settings) do
    task.spawn(function()
        pcall(function()
            Nodes.CLIENT_CHANGE_SETTING:FireServer(settingName, value)
        end)
    end)
    task.wait(0.5)
end

-- AutoSell Settings
task.wait(1)
local FusionPackage = ReplicatedStorage:WaitForChild("FusionPackage")
local Actions = require(FusionPackage.Actions)

-- à¹€à¸£à¸´à¹ˆà¸¡à¸•à¹‰à¸™: à¸‚à¸²à¸¢ Rare + Epic à¹€à¸—à¹ˆà¸²à¸™à¸±à¹‰à¸™ (à¹„à¸¡à¹ˆà¸‚à¸²à¸¢ Legendary)
for _, rarity in ipairs({"Rare", "Epic"}) do
    pcall(function()
        Actions.ToggleAutoSell("Standard", rarity, false, true)
    end)
    task.wait(0.3)
end

-- à¹€à¸›à¸´à¸”à¸‚à¸²à¸¢ Shiny units à¸—à¸¸à¸ Rarity (Rare, Epic)
print("ðŸ”§ Enabling Shiny AutoSell...")
for _, rarity in ipairs({"Rare", "Epic"}) do
    pcall(function()
        -- Parameter 3 = true à¸«à¸¡à¸²à¸¢à¸–à¸¶à¸‡ Shiny
        Actions.ToggleAutoSell("Standard", rarity, true, true)
    end)
    task.wait(0.3)
end

task.wait(1)

-- ========================================
-- 2.5. Trait Filter Setup
-- ========================================
printStep("Setting Trait Filters...")

do
    local TRAIT_CONFIG = {
        TargetTraits = {"Unbound", "Primordial", "Forsaken", "Draconic", "Investor"},
        ClearBeforeSet = false,
        FilterMode = false,
    }

    -- à¸¥à¹‰à¸²à¸‡ filters (à¸–à¹‰à¸²à¸•à¹‰à¸­à¸‡à¸à¸²à¸£)
    if TRAIT_CONFIG.ClearBeforeSet then
        pcall(function() Nodes.CLIENT_CLEAR_TRAIT_FILTERS:Request() end)
        task.wait(0.3)
    end

    -- à¸•à¸±à¹‰à¸‡ filters
    local success, fail = 0, 0
    for _, trait in ipairs(TRAIT_CONFIG.TargetTraits) do
        if pcall(function() Nodes.CLIENT_TOGGLE_TRAIT_FILTER:Request(trait, TRAIT_CONFIG.FilterMode) end) then
            success = success + 1
        else
            fail = fail + 1
        end
        task.wait(0.1)
    end

    -- à¹à¸ˆà¹‰à¸‡à¸œà¸¥à¸¥à¸±à¸žà¸˜à¹Œ
    if fail == 0 then
        print(string.format("âœ… Trait Filters: %d traits %s", success, TRAIT_CONFIG.FilterMode and "enabled" or "disabled"))
    else
        warn(string.format("âš ï¸ Trait Filters: %d success, %d failed", success, fail))
    end
end

task.wait(1)

-- ========================================
-- 3. AutoClaimStarter.lua
-- ========================================
printStep("Claiming Starter Unit...")

local GuiService = game:GetService("GuiService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local Players = game:GetService("Players")

local TARGET_UNIT = "Carrot"

-- à¸£à¸­à¹ƒà¸«à¹‰ Prompt à¹‚à¸«à¸¥à¸”
task.wait(2)

local playerGui = Players.LocalPlayer.PlayerGui
if playerGui:FindFirstChild("Prompt") then
    local success, folder = pcall(function()
        return playerGui.Prompt.Frame.Frame.Frame.Folder.Frame.Frame
    end)

    if not success or not folder then
        warn("âš ï¸ Starter Unit popup not found or already claimed - skipping")
        task.wait(2)
        return
    end

    -- à¸«à¸²à¸›à¸¸à¹ˆà¸¡à¸—à¸µà¹ˆà¸¡à¸µà¸Šà¸·à¹ˆà¸­ Carrot
    for _, child in pairs(folder:GetChildren()) do
        if child:FindFirstChild("Folder") then
            local textLabel = child.Folder.Frame.Frame:FindFirstChild("TextLabel")
            if textLabel and (textLabel.ContentText == TARGET_UNIT or textLabel.Text == TARGET_UNIT) then
                -- à¸à¸”à¸›à¸¸à¹ˆà¸¡à¹€à¸¥à¸·à¸­à¸à¸•à¸±à¸§à¸¥à¸°à¸„à¸£
                local button = child.Folder.Frame:FindFirstChild("TextButton")
                if button then
                    GuiService.SelectedCoreObject = nil
                    task.wait(0.1)

                    button.Selectable = true
                    GuiService.SelectedCoreObject = button
                    task.wait(0.1)

                    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
                    task.wait(0.05)
                    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Return, false, game)

                    task.wait(0.2)
                    GuiService.SelectedCoreObject = nil

                    task.wait(0.5)

                    -- à¸à¸”à¸›à¸¸à¹ˆà¸¡à¸¢à¸·à¸™à¸¢à¸±à¸™
                    local confirmButton = playerGui.Prompt.Frame.Frame.Frame.Frame:FindFirstChild("PrimaryButton")
                    if confirmButton then
                        GuiService.SelectedCoreObject = nil
                        task.wait(0.1)

                        confirmButton.Selectable = true
                        GuiService.SelectedCoreObject = confirmButton
                        task.wait(0.1)

                        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
                        task.wait(0.05)
                        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Return, false, game)

                        task.wait(0.2)
                        GuiService.SelectedCoreObject = nil

                        task.wait(0.5)

                        -- spam à¸„à¸¥à¸´à¸à¸¡à¸¸à¸¡à¸‹à¹‰à¸²à¸¢à¸šà¸™ 5 à¸£à¸­à¸š
                        for i = 1, 5 do
                            VirtualInputManager:SendMouseButtonEvent(10, 10, 0, true, game, 0)
                            task.wait(0.05)
                            VirtualInputManager:SendMouseButtonEvent(10, 10, 0, false, game, 0)
                            task.wait(0.1)
                        end

                    end
                end
                break
            end
        end
    end
else
end

task.wait(1)

-- ========================================
-- 4. AutoClaimCalendar.lua
-- ========================================
printStep("Claiming Calendar Rewards...")

local START_DAY = 1
local END_DAY = 7

-- Claim ReleaseCalendar à¸—à¸±à¹‰à¸‡à¸«à¸¡à¸”à¸žà¸£à¹‰à¸­à¸¡à¸à¸±à¸™
for day = START_DAY, END_DAY do
    spawn(function()
        pcall(function()
            Nodes.CLAIM_CALENDAR:FireServer("ReleaseCalendar", day)
        end)
    end)
    task.wait(0.05)  -- à¸«à¸™à¹ˆà¸§à¸‡à¹€à¸¥à¹‡à¸à¸™à¹‰à¸­à¸¢
end

task.wait(2)  -- à¸£à¸­à¹ƒà¸«à¹‰ claim à¹€à¸ªà¸£à¹‡à¸ˆ

-- Claim DailyRewards à¸—à¸±à¹‰à¸‡à¸«à¸¡à¸”à¸žà¸£à¹‰à¸­à¸¡à¸à¸±à¸™
for day = START_DAY, END_DAY do
    spawn(function()
        pcall(function()
            Nodes.CLAIM_CALENDAR:FireServer("DailyRewards", day)
        end)
    end)
    task.wait(0.05)  -- à¸«à¸™à¹ˆà¸§à¸‡à¹€à¸¥à¹‡à¸à¸™à¹‰à¸­à¸¢
end

task.wait(2)  -- à¸£à¸­à¹ƒà¸«à¹‰ claim à¹€à¸ªà¸£à¹‡à¸ˆ

-- à¸›à¸´à¸” popup à¸£à¸§à¸¡
local VirtualInputManager = game:GetService("VirtualInputManager")
for i = 1, 10 do
    VirtualInputManager:SendMouseButtonEvent(10, 10, 0, true, game, 0)
    task.wait(0.05)
    VirtualInputManager:SendMouseButtonEvent(10, 10, 0, false, game, 0)
    task.wait(0.1)
end

task.wait(1)

-- ========================================
-- 4.5. Redeem Codes
-- ========================================
printStep("Redeeming Codes...")

do
    local CODES = {
        "250kCCU",
        "300kCCU",
        "200mvisits",
        "VillainInvasion",
        "releasetournamentsorry",
        "sorryforlongmaintenance",
    }

    local successCount = 0
    local failCount = 0

    -- Redeem à¸—à¸µà¸¥à¸°à¹‚à¸„à¹‰à¸” (à¹€à¸žà¸´à¹ˆà¸¡à¹€à¸§à¸¥à¸²à¸£à¸°à¸«à¸§à¹ˆà¸²à¸‡à¹‚à¸„à¹‰à¸”)
    for i, code in ipairs(CODES) do
        local success, result = pcall(function()
            local request = Nodes.CLAIM_CODE:Request(code)
            request:Timeout(5)
            return request:Wait()
        end)

        if success and result and result.Success then
            successCount = successCount + 1
        else
            failCount = failCount + 1
        end

        task.wait(1.1)  -- à¸£à¸­ 5 à¸§à¸´à¸•à¹ˆà¸­à¹‚à¸„à¹‰à¸”
    end

    -- à¸£à¸­à¹€à¸žà¸´à¹ˆà¸¡à¸­à¸µà¸à¸™à¸´à¸”
    task.wait(1)


    -- à¸›à¸´à¸” popup (à¸–à¹‰à¸²à¸¡à¸µ)
    local VirtualInputManager = game:GetService("VirtualInputManager")
    for i = 1, 10 do
        VirtualInputManager:SendMouseButtonEvent(10, 10, 0, true, game, 0)
        task.wait(0.05)
        VirtualInputManager:SendMouseButtonEvent(10, 10, 0, false, game, 0)
        task.wait(0.1)
    end
end

task.wait(1)

-- ========================================
-- 4.6. Claim All Quests, Achievements & BattlePass
-- ========================================
printStep("Claiming All Quests, Achievements & BattlePass...")

do
    -- à¸”à¸¶à¸‡ QuestData
    local replica = Nodes.GET_PLAYER_REPLICA:InvokeSelf()
    if not replica or not replica.Data.QuestData then
        warn("   âš ï¸ QuestData not found!")
    else
        local questData = replica.Data.QuestData
        local categories = {}

        -- à¹€à¸à¹‡à¸š categories à¸—à¸±à¹‰à¸‡à¸«à¸¡à¸”
        for categoryName, _ in pairs(questData) do
            table.insert(categories, categoryName)
        end


        -- Claim à¹à¸•à¹ˆà¸¥à¸° category à¸žà¸£à¹‰à¸­à¸¡à¸à¸±à¸™
        local claimedCount = 0
        for _, categoryName in ipairs(categories) do
            spawn(function()
                pcall(function()
                    Nodes.QUEST_CLAIM_ALL_CATEGORY:FireServer(categoryName)
                    claimedCount = claimedCount + 1
                end)
            end)
            task.wait(0.05)
        end

        task.wait(2)
    end

    task.wait(1)

    -- Claim BattlePass
    local ReplicaClient = require(ReplicatedStorage.Shared.ReplicaClient)
    local battlepassClaimed = 0

    ReplicaClient.OnNew("BattlepassData", function(replica)
        if replica.Data and replica.Data.DataKey then
            local battlepassId = replica.Data.DataKey
            pcall(function()
                Nodes.CLAIM_ALL_BATTLEPASS_REWARDS:FireServer(battlepassId)
                battlepassClaimed = battlepassClaimed + 1
            end)
        end
    end)

    task.wait(2)

    if battlepassClaimed == 0 then
    end

    -- à¸›à¸´à¸” popup à¸—à¸µà¹ˆà¸­à¸²à¸ˆà¸ˆà¸°à¸‚à¸¶à¹‰à¸™à¸¡à¸²
    local VirtualInputManager = game:GetService("VirtualInputManager")
    for i = 1, 20 do
        VirtualInputManager:SendMouseButtonEvent(10, 10, 0, true, game, 0)
        task.wait(0.05)
        VirtualInputManager:SendMouseButtonEvent(10, 10, 0, false, game, 0)
        task.wait(0.1)
    end
end
task.wait(1)

-- ========================================
-- 5. à¹€à¸Šà¹‡à¸„à¸•à¸±à¸§à¸¥à¸°à¸„à¸£à¸—à¸µà¹ˆà¸¡à¸µà¸­à¸¢à¸¹à¹ˆ + Summon System (Mythic/Secret)
-- ========================================

printStep("Checking Inventory...")

-- à¸¥à¸šà¸Ÿà¸±à¸‡à¸à¹Œà¸Šà¸±à¸™ openInventory à¹à¸¥à¸° closeInventory à¹€à¸žà¸£à¸²à¸°à¹„à¸¡à¹ˆà¸ˆà¸³à¹€à¸›à¹‡à¸™à¹à¸¥à¹‰à¸§
-- à¹ƒà¸Šà¹‰ Nodes.GET_DATA_VALUE:InvokeSelf("UnitData") à¹‚à¸”à¸¢à¸•à¸£à¸‡

-- à¸Ÿà¸±à¸‡à¸à¹Œà¸Šà¸±à¸™à¹€à¸Šà¹‡à¸„à¸§à¹ˆà¸²à¸¡à¸µ units à¹ƒà¸™ Inventory (à¸žà¸£à¹‰à¸­à¸¡ Trait)
local function checkInventoryForUnits(targetUnits, returnWithTrait)
    local unitData = Nodes.GET_DATA_VALUE:InvokeSelf("UnitData")
    if not unitData then return {} end

    -- à¸–à¹‰à¸² targetUnits à¹€à¸›à¹‡à¸™ string à¹ƒà¸«à¹‰à¹à¸›à¸¥à¸‡à¹€à¸›à¹‡à¸™ table
    if type(targetUnits) == "string" then
        targetUnits = {targetUnits}
    end

    local UnitInfo = require(ReplicatedStorage.Shared.Information.Units)
    local foundUnits = {}

    for fullKey, data in pairs(unitData) do
        local internalName = fullKey:match("^(.+)#") or fullKey
        local unitInfo = UnitInfo[internalName]
        if unitInfo then
            local displayName = unitInfo.DisplayName or internalName
            for _, targetUnit in ipairs(targetUnits) do
                if displayName == targetUnit then
                    if returnWithTrait then
                        -- return à¸žà¸£à¹‰à¸­à¸¡ Trait à¹à¸¥à¸° Shiny
                        table.insert(foundUnits, {
                            name = displayName,
                            trait = data.Trait or "None",
                            fullKey = fullKey,
                            unitID = data.ID,
                            isShiny = data.Shiny or false
                        })
                    else
                        -- return à¹à¸„à¹ˆà¸Šà¸·à¹ˆà¸­
                        table.insert(foundUnits, displayName)
                    end
                    break
                end
            end
        end
    end
    return foundUnits
end

-- à¸Ÿà¸±à¸‡à¸à¹Œà¸Šà¸±à¸™à¹€à¸¥à¸·à¸­à¸à¸•à¸±à¸§à¸—à¸µà¹ˆà¸ˆà¸°à¸ªà¸¸à¹ˆà¸¡ Trait (Priority: None > Worst Trait)
local function selectBestUnitForReroll(units)
    if #units == 0 then return nil end
    if #units == 1 then return units[1] end

    -- Trait Priority (à¸ˆà¸²à¸à¸à¸²à¸à¸ªà¸¸à¸” â†’ à¸”à¸µà¸ªà¸¸à¸”)
    local TRAIT_PRIORITY = {
        "Strength 1",    -- 1 (à¸à¸²à¸à¸ªà¸¸à¸”)
        "Speed 1",       -- 2
        "Range 1",       -- 3
        "Enlightenment", -- 4
        "Strength 2",    -- 5
        "Speed 2",       -- 6
        "Range 2",       -- 7
        "Limit Breaker", -- 8
        "Precision 1",   -- 9
        "Precision 2",   -- 10
        "Bolt",          -- 11
        "Optics",        -- 12
        "Investor",      -- 13
        "Draconic",      -- 14
        "Forsaken",      -- 15
        "Primordial",    -- 16
        "Unbound"        -- 17 (à¸”à¸µà¸ªà¸¸à¸”)
    }

    -- à¸ªà¸£à¹‰à¸²à¸‡ Trait â†’ Priority Map
    local traitPriorityMap = {}
    for priority, traitName in ipairs(TRAIT_PRIORITY) do
        traitPriorityMap[traitName] = priority
    end

    -- à¹à¸¢à¸ Shiny à¹à¸¥à¸° Non-Shiny
    local shinyUnits = {}
    local normalUnits = {}

    for _, unit in ipairs(units) do
        if unit.isShiny then
            table.insert(shinyUnits, unit)
        else
            table.insert(normalUnits, unit)
        end
    end

    -- à¸Ÿà¸±à¸‡à¸à¹Œà¸Šà¸±à¸™à¹€à¸¥à¸·à¸­à¸à¸•à¸±à¸§à¸—à¸µà¹ˆà¸”à¸µà¸—à¸µà¹ˆà¸ªà¸¸à¸”à¸ˆà¸²à¸ list
    local function selectFromList(list)
        if #list == 0 then return nil end
        if #list == 1 then return list[1] end

        -- à¹à¸¢à¸à¸•à¸±à¸§à¸—à¸µà¹ˆ Trait = None
        local noneUnits = {}
        local withTraitUnits = {}

        for _, unit in ipairs(list) do
            if unit.trait == "None" then
                table.insert(noneUnits, unit)
            else
                table.insert(withTraitUnits, unit)
            end
        end

        -- à¸–à¹‰à¸²à¸¡à¸µà¸•à¸±à¸§à¸—à¸µà¹ˆ Trait = None â†’ à¹€à¸¥à¸·à¸­à¸à¸•à¸±à¸§à¹à¸£à¸
        if #noneUnits > 0 then
            return noneUnits[1]
        end

        -- à¸–à¹‰à¸²à¹„à¸¡à¹ˆà¸¡à¸µ None â†’ à¹€à¸¥à¸·à¸­à¸à¸•à¸±à¸§à¸—à¸µà¹ˆ Trait à¸à¸²à¸à¸ªà¸¸à¸” (priority à¸•à¹ˆà¸³à¸ªà¸¸à¸”)
        if #withTraitUnits > 0 then
            table.sort(withTraitUnits, function(a, b)
                local priorityA = traitPriorityMap[a.trait] or 999
                local priorityB = traitPriorityMap[b.trait] or 999
                return priorityA < priorityB  -- priority à¸•à¹ˆà¸³à¸à¸§à¹ˆà¸² = à¸à¸²à¸à¸à¸§à¹ˆà¸²
            end)
            return withTraitUnits[1]
        end

        return list[1]
    end  -- à¸›à¸´à¸” selectFromList function

    -- à¹€à¸¥à¸·à¸­à¸ Shiny à¸à¹ˆà¸­à¸™ (à¸–à¹‰à¸²à¸¡à¸µ)
    if #shinyUnits > 0 then
        local selected = selectFromList(shinyUnits)
        if selected then return selected end
    end

    -- à¸–à¹‰à¸²à¹„à¸¡à¹ˆà¸¡à¸µ Shiny à¸«à¸£à¸·à¸­à¹€à¸¥à¸·à¸­à¸à¹„à¸¡à¹ˆà¹„à¸”à¹‰ â†’ à¹€à¸¥à¸·à¸­à¸à¸•à¸±à¸§à¸˜à¸£à¸£à¸¡à¸”à¸²
    if #normalUnits > 0 then
        local selected = selectFromList(normalUnits)
        if selected then return selected end
    end

    -- Fallback (à¹„à¸¡à¹ˆà¸™à¹ˆà¸²à¹€à¸à¸´à¸”)
    return units[1]
end  -- à¸›à¸´à¸” selectBestUnitForReroll function

-- à¸Ÿà¸±à¸‡à¸à¹Œà¸Šà¸±à¸™à¸ªà¹ˆà¸‡ Horst Description
local function sendSummonStatus(foundUnits)
    if not HORST_ENABLED or not _G.Horst_SetDescription then return end

    local replica = Nodes.GET_PLAYER_REPLICA:InvokeSelf()
    local gems = replica and replica.Data and replica.Data.ItemData and replica.Data.ItemData.Gem and replica.Data.ItemData.Gem.Amount or 0
    local rr = replica and replica.Data and replica.Data.ItemData and replica.Data.ItemData.TraitReroll and replica.Data.ItemData.TraitReroll.Amount or 0

    local unitNames = {}
    for _, unit in ipairs(foundUnits) do
        table.insert(unitNames, unit)
    end
    local unitText = table.concat(unitNames, ", ")

    local message = string.format("💎 Gems: %d • RR: %d • %s", gems, rr, unitText)

    pcall(function()
        _G.Horst_SetDescription(message)
    end)

    print(string.format("📤 Updated status: %s", message))
end

-- à¹€à¸Šà¹‡à¸„ Summon Config
local shouldSummon = false
local hasTargetUnitConfig = false  -- à¹€à¸›à¸¥à¸µà¹ˆà¸¢à¸™à¸Šà¸·à¹ˆà¸­à¸ˆà¸²à¸ hasTargetUnit
local autoSummonMode = false  -- à¹ƒà¸«à¸¡à¹ˆ: à¹‚à¸«à¸¡à¸” auto summon

if hasSummonConfig then
    -- à¹€à¸Šà¹‡à¸„à¸§à¹ˆà¸²à¹€à¸›à¹‡à¸™ "auto" mode à¸«à¸£à¸·à¸­à¹„à¸¡à¹ˆ
    if type(_G.Config.SummonUnits) == "string" and _G.Config.SummonUnits:lower() == "auto" then
        autoSummonMode = true
        -- Override SUMMON_CONFIG à¹€à¸›à¹‡à¸™ Mythic + Secret à¸—à¸±à¹‰à¸‡à¸«à¸¡à¸”
        local allTargets = {}
        for _, unit in ipairs(SECRET_UNITS) do
            table.insert(allTargets, unit)
        end
        for _, unit in ipairs(MYTHIC_UNITS) do
            table.insert(allTargets, unit)
        end
        SUMMON_CONFIG = allTargets
    end

    -- à¹€à¸Šà¹‡à¸„ Level à¹à¸¥à¸° Gems
    local replica = Nodes.GET_PLAYER_REPLICA:InvokeSelf()
    local level = replica and replica.Data and replica.Data.Level or 0
    local gems = replica and replica.Data and replica.Data.ItemData and replica.Data.ItemData.Gem and replica.Data.ItemData.Gem.Amount or 0

    -- 1. à¹€à¸Šà¹‡à¸„ Inventory à¸à¹ˆà¸­à¸™à¹€à¸ªà¸¡à¸­ (à¹„à¸¡à¹ˆà¸§à¹ˆà¸² Gems à¸ˆà¸°à¸žà¸­à¸«à¸£à¸·à¸­à¹„à¸¡à¹ˆ)
    local foundInInventory = checkInventoryForUnits(SUMMON_CONFIG)

    if autoSummonMode then
        -- à¹‚à¸«à¸¡à¸” auto: à¹„à¸”à¹‰à¸•à¸±à¸§à¹ƒà¸”à¸•à¸±à¸§à¸«à¸™à¸¶à¹ˆà¸‡à¸à¹‡à¸žà¸­
        if #foundInInventory > 0 then
            sendSummonStatus(true)
            hasTargetUnitConfig = true
            print("âœ… Found target unit in inventory - skipping summon")
        end
    else
        -- à¹‚à¸«à¸¡à¸”à¸›à¸à¸•à¸´: à¸•à¹‰à¸­à¸‡à¹„à¸”à¹‰à¸„à¸£à¸šà¸—à¸¸à¸à¸•à¸±à¸§
        if #foundInInventory >= #SUMMON_CONFIG then
            sendSummonStatus(true)
            hasTargetUnitConfig = true
            print("âœ… Found all target units in inventory - skipping summon")
        end
    end

    -- 2. à¸–à¹‰à¸²à¸¢à¸±à¸‡à¹„à¸¡à¹ˆà¸¡à¸µà¸•à¸±à¸§ â†’ à¸žà¸´à¸ˆà¸²à¸£à¸“à¸²à¸§à¹ˆà¸²à¸ˆà¸°à¸ªà¸¸à¹ˆà¸¡à¸«à¸£à¸·à¸­à¹„à¸¡à¹ˆ
    if not hasTargetUnitConfig then
        if level >= 10 and gems >= 2500 then
            -- à¸¡à¸µ Level à¹à¸¥à¸° Gems à¸žà¸­ â†’ à¹„à¸›à¸ªà¸¸à¹ˆà¸¡
            -- à¹€à¸Šà¹‡à¸„à¸§à¹ˆà¸²à¹€à¸›à¹‡à¸™ Secret unit à¸«à¸£à¸·à¸­à¹„à¸¡à¹ˆ
            local isSecretUnit = false
            for _, configUnit in ipairs(SUMMON_CONFIG) do
                for _, secretUnit in ipairs(SECRET_UNITS) do
                    if configUnit == secretUnit then
                        isSecretUnit = true
                        print(string.format("â„¹ï¸ '%s' is a Secret unit - Banner always available", configUnit))
                        break
                    end
                end
                if isSecretUnit then break end
            end

            if isSecretUnit then
                -- Secret unit: à¸‚à¹‰à¸²à¸¡ Banner check (à¸¡à¸µà¹€à¸ªà¸¡à¸­)
                shouldSummon = true
            else
                -- Mythic unit: à¹€à¸Šà¹‡à¸„ Banner à¸•à¸²à¸¡à¸›à¸à¸•à¸´
                local bannerUnits = checkCurrentBanner()

                local hasMatch = false
                for _, configUnit in pairs(SUMMON_CONFIG) do
                    for _, bannerUnit in pairs(bannerUnits) do
                        if configUnit == bannerUnit then
                            hasMatch = true
                            break
                        end
                    end
                    if hasMatch then break end
                end

                if hasMatch then
                    shouldSummon = true
                else
                    if #foundInInventory > 0 then
                        sendSummonStatus(false)
                    end
                end
            end
        else
            -- à¹„à¸¡à¹ˆà¸¡à¸µà¸•à¸±à¸§ + Gems à¹„à¸¡à¹ˆà¸žà¸­ â†’ à¹€à¸Šà¹‡à¸„à¸§à¹ˆà¸²à¸¡à¸µ Mythic Fallback à¸«à¸£à¸·à¸­à¹„à¸¡à¹ˆ
            warn(string.format("âš ï¸ Target unit not found in inventory. Need to farm more gems. Level=%d, Gems=%d (require Level>=10 and Gems>=2500)", level, gems))

            -- à¹€à¸Šà¹‡à¸„à¸§à¹ˆà¸² Config à¹€à¸›à¹‡à¸™ Secret unit à¸«à¸£à¸·à¸­à¹„à¸¡à¹ˆ
            local isSecretSummon = false
            for _, configUnit in ipairs(SUMMON_CONFIG) do
                for _, secretUnit in ipairs(SECRET_UNITS) do
                    if configUnit == secretUnit then
                        isSecretSummon = true
                        break
                    end
                end
                if isSecretSummon then break end
            end

            -- à¸–à¹‰à¸²à¹€à¸›à¹‡à¸™ Secret + Change_Acc_Secrets = true â†’ Fallback à¹„à¸› Mythic
            if isSecretSummon and CHANGE_ACC_SECRETS then
                print("â„¹ï¸ Secret unit not found - checking for Mythic fallback...")

                -- à¹€à¸Šà¹‡à¸„à¸§à¹ˆà¸²à¸¡à¸µ Mythic à¹ƒà¸™ Inventory à¸«à¸£à¸·à¸­à¹„à¸¡à¹ˆ
                local mythicFallback = checkInventoryForUnits(MYTHIC_UNITS)

                if #mythicFallback > 0 then
                    print(string.format("âœ… Found Mythic fallback: %s", table.concat(mythicFallback, ", ")))
                    sendSummonStatus(false)
                    hasTargetUnitConfig = true
                    -- à¹„à¸¡à¹ˆà¸•à¸±à¹‰à¸‡ shouldSummon = true (à¹„à¸¡à¹ˆà¹„à¸›à¸ªà¸¸à¹ˆà¸¡) à¹à¸•à¹ˆà¸¡à¸µ hasTargetUnitConfig = true (à¹„à¸› Trait Reroll)
                else
                    print("âš ï¸ No Mythic fallback found - will proceed to farming")
                    -- à¹„à¸¡à¹ˆà¸•à¸±à¹‰à¸‡ shouldSummon = true (à¹„à¸¡à¹ˆà¹„à¸›à¸ªà¸¸à¹ˆà¸¡) à¹ƒà¸«à¹‰à¹„à¸›à¹€à¸Šà¹‡à¸„ Legendary à¸•à¹ˆà¸­
                end
            else
                print("â„¹ï¸ Script will proceed to farming to collect gems...")
                -- à¹„à¸¡à¹ˆà¸•à¸±à¹‰à¸‡ shouldSummon = true (à¹„à¸¡à¹ˆà¹„à¸›à¸ªà¸¸à¹ˆà¸¡) à¹ƒà¸«à¹‰à¹„à¸›à¹€à¸Šà¹‡à¸„ Legendary à¸•à¹ˆà¸­
            end
        end
    end
end

-- à¹€à¸Šà¹‡à¸„à¸•à¸±à¸§ Legendary (à¸–à¹‰à¸²à¹„à¸¡à¹ˆà¸¡à¸µ Summon Config à¸«à¸£à¸·à¸­à¸‚à¹‰à¸²à¸¡à¸¡à¸²à¹à¸¥à¹‰à¸§)
-- à¹à¸•à¹ˆà¹„à¸¡à¹ˆ override hasTargetUnitConfig à¸–à¹‰à¸²à¸¡à¸µà¸„à¹ˆà¸²à¸­à¸¢à¸¹à¹ˆà¹à¸¥à¹‰à¸§ (à¹€à¸Šà¹ˆà¸™ à¸ˆà¸²à¸ Mythic Fallback)
local hasTargetUnitLegendary = false

if not shouldSummon and not hasTargetUnitConfig then

    local function checkForLegendaryUnits()
        local targetUnits = {
            "The Hero",
            "Scissor",
            "Ice Queen",
            "Water Princess",
            "Forbidden Teacher",
            "Greed"
        }

        -- à¹€à¸Šà¹‡à¸„à¸œà¹ˆà¸²à¸™ UnitData à¹‚à¸”à¸¢à¸•à¸£à¸‡à¹à¸—à¸™à¸à¸²à¸£à¸­à¹ˆà¸²à¸™ GUI
        local unitData = Nodes.GET_DATA_VALUE:InvokeSelf("UnitData")
        if not unitData then
            return false
        end

        local UnitInfo = require(ReplicatedStorage.Shared.Information.Units)

        -- à¹€à¸à¹‡à¸šà¸Šà¸·à¹ˆà¸­à¸—à¸µà¹ˆà¹€à¸ˆà¸­à¹€à¸žà¸·à¹ˆà¸­ debug
        local foundUnits = {}
        local targetFound = false

        for fullKey, data in pairs(unitData) do
            local internalName = fullKey:match("^(.+)#") or fullKey
            local unitInfo = UnitInfo[internalName]

            if unitInfo then
                local displayName = unitInfo.DisplayName or internalName

                -- à¹€à¸à¹‡à¸šà¹€à¸žà¸·à¹ˆà¸­ debug
                if not foundUnits[displayName] then
                    foundUnits[displayName] = true
                end

                -- à¹€à¸Šà¹‡à¸„à¸§à¹ˆà¸²à¸•à¸£à¸‡à¸à¸±à¸š target unit à¸«à¸£à¸·à¸­à¹„à¸¡à¹ˆ
                for _, targetUnit in pairs(targetUnits) do
                    if displayName == targetUnit then
                        targetFound = true
                        break
                    end
                end

                if targetFound then
                    break
                end
            end
        end

        return targetFound
    end

    -- à¹€à¸Šà¹‡à¸„à¸•à¸±à¸§à¸¥à¸°à¸„à¸£à¹‚à¸”à¸¢à¸•à¸£à¸‡ (à¹„à¸¡à¹ˆà¸•à¹‰à¸­à¸‡à¹€à¸›à¸´à¸” Inventory)
    hasTargetUnitLegendary = checkForLegendaryUnits()

    if hasTargetUnitLegendary then
        print("âœ… Found Legendary unit in inventory")
    else
        print("â„¹ï¸ No Legendary units found - will farm with Carrot to collect gems")
    end
end

-- ========================================
-- 6. AutoSummon (à¸ªà¸³à¸«à¸£à¸±à¸š Summon Config à¸«à¸£à¸·à¸­ Legendary)
-- ========================================
if shouldSummon then
    printStep("Auto Summon (Mythic/Secret)...")

    -- ========================================
    -- 6.1 à¹€à¸Šà¹‡à¸„à¹à¸¥à¸°à¸•à¸±à¹‰à¸‡à¸„à¹ˆà¸² AutoSell Legendary à¸à¹ˆà¸­à¸™à¸ªà¸¸à¹ˆà¸¡
    -- ========================================
    print("ðŸ” Checking for Legendary units before summon...")

    local LEGENDARY_UNITS = {
        "The Hero",
        "Scissor",
        "Ice Queen",
        "Water Princess",
        "Forbidden Teacher",
        "Greed"
    }

    local unitData = Nodes.GET_DATA_VALUE:InvokeSelf("UnitData")
    local UnitInfo = require(ReplicatedStorage.Shared.Information.Units)
    local hasLegendary = false

    if unitData then
        for fullKey, data in pairs(unitData) do
            local internalName = fullKey:match("^(.+)#") or fullKey
            local unitInfo = UnitInfo[internalName]

            if unitInfo then
                local displayName = unitInfo.DisplayName or internalName

                for _, legendaryUnit in ipairs(LEGENDARY_UNITS) do
                    if displayName == legendaryUnit then
                        hasLegendary = true
                        print(string.format("   âœ… Found Legendary: %s", displayName))
                        break
                    end
                end

                if hasLegendary then break end
            end
        end
    end

    if hasLegendary then
        print("ðŸ”§ Enabling Legendary AutoSell before summon (Non-Shiny + Shiny)...")

        local FusionPackage = ReplicatedStorage:WaitForChild("FusionPackage")
        local Actions = require(FusionPackage.Actions)

        -- à¹€à¸›à¸´à¸”à¸‚à¸²à¸¢ Legendary (Non-Shiny)
        pcall(function()
            Actions.ToggleAutoSell("Standard", "Legendary", false, true)
        end)
        task.wait(0.3)

        -- à¹€à¸›à¸´à¸”à¸‚à¸²à¸¢ Legendary (Shiny)
        pcall(function()
            Actions.ToggleAutoSell("Standard", "Legendary", true, true)
        end)
        task.wait(0.3)

        print("âœ… Legendary AutoSell enabled before summon (including Shiny)")
    end

    task.wait(1)

    local BANNER_ID = "Standard"
    local AMOUNT_PER_SUMMON = 50  -- à¸ˆà¸³à¸™à¸§à¸™à¸„à¸£à¸±à¹‰à¸‡à¸ªà¸¸à¹ˆà¸¡ (x50 multi)
    local GEMS_PER_SUMMON = 2500  -- Gems à¸—à¸µà¹ˆà¹ƒà¸Šà¹‰à¸•à¹ˆà¸­à¸£à¸­à¸š
    local summonCount = 0

    while true do
        -- à¹€à¸Šà¹‡à¸„à¸§à¹ˆà¸²à¹„à¸”à¹‰à¸•à¸±à¸§à¸—à¸µà¹ˆà¸•à¹‰à¸­à¸‡à¸à¸²à¸£à¸à¹ˆà¸­à¸™à¸ªà¸¸à¹ˆà¸¡ (à¸—à¸¸à¸à¸£à¸­à¸š)
        local foundBeforeSummon = checkInventoryForUnits(SUMMON_CONFIG)

        if autoSummonMode then
            -- à¹‚à¸«à¸¡à¸” auto: à¹„à¸”à¹‰à¸•à¸±à¸§à¹ƒà¸”à¸•à¸±à¸§à¸«à¸™à¸¶à¹ˆà¸‡à¸à¹‡à¸žà¸­
            if #foundBeforeSummon > 0 then
                sendSummonStatus(true)
                hasTargetUnitConfig = true
                print("âœ… Found target unit - stopping summon")
                break
            end
        else
            -- à¹‚à¸«à¸¡à¸”à¸›à¸à¸•à¸´: à¸•à¹‰à¸­à¸‡à¹„à¸”à¹‰à¸„à¸£à¸šà¸—à¸¸à¸à¸•à¸±à¸§
            if #foundBeforeSummon >= #SUMMON_CONFIG then
                sendSummonStatus(true)
                hasTargetUnitConfig = true
                print("âœ… Found all target units - stopping summon")
                break
            end
        end

        -- à¹€à¸Šà¹‡à¸„ Gems à¸à¹ˆà¸­à¸™à¸ªà¸¸à¹ˆà¸¡
        local replica = Nodes.GET_PLAYER_REPLICA:InvokeSelf()
        local gems = replica and replica.Data and replica.Data.ItemData and replica.Data.ItemData.Gem and replica.Data.ItemData.Gem.Amount or 0

        if gems < GEMS_PER_SUMMON then
            warn(string.format("âš ï¸ Not enough gems for summon: %d (require %d) - stopping", gems, GEMS_PER_SUMMON))
            break
        end

        summonCount = summonCount + 1
        print(string.format("ðŸŽ² Summon #%d | Gems: %d", summonCount, gems))

        pcall(function()
            Nodes.BANNER_SUMMON:FireServer(BANNER_ID, AMOUNT_PER_SUMMON)
        end)

        task.wait(0.3)

        -- à¸›à¸´à¸” popup
        for j = 1, 5 do
            VirtualInputManager:SendMouseButtonEvent(10, 10, 0, true, game, 0)
            task.wait(0.01)
            VirtualInputManager:SendMouseButtonEvent(10, 10, 0, false, game, 0)
            task.wait(0.02)
        end

        task.wait(0.2)

        -- à¹€à¸Šà¹‡à¸„à¸§à¹ˆà¸²à¹„à¸”à¹‰à¸•à¸±à¸§à¸—à¸µà¹ˆà¸•à¹‰à¸­à¸‡à¸à¸²à¸£à¸«à¸£à¸·à¸­à¸¢à¸±à¸‡à¸«à¸¥à¸±à¸‡à¸ªà¸¸à¹ˆà¸¡
        local foundInInventory = checkInventoryForUnits(SUMMON_CONFIG)

        if autoSummonMode then
            -- à¹‚à¸«à¸¡à¸” auto: à¹„à¸”à¹‰à¸•à¸±à¸§à¹ƒà¸”à¸•à¸±à¸§à¸«à¸™à¸¶à¹ˆà¸‡à¸à¹‡à¸žà¸­
            if #foundInInventory > 0 then
                sendSummonStatus(true)
                hasTargetUnitConfig = true
                print(string.format("âœ… Found target unit after summon #%d - stopping", summonCount))
                break
            end
        else
            -- à¹‚à¸«à¸¡à¸”à¸›à¸à¸•à¸´: à¸•à¹‰à¸­à¸‡à¹„à¸”à¹‰à¸„à¸£à¸šà¸—à¸¸à¸à¸•à¸±à¸§
            if #foundInInventory >= #SUMMON_CONFIG then
                sendSummonStatus(true)
                hasTargetUnitConfig = true
                print(string.format("âœ… Found all target units after summon #%d - stopping", summonCount))
                break
            else
                -- à¹à¸ªà¸”à¸‡à¸•à¸±à¸§à¸—à¸µà¹ˆà¸¡à¸µà¹à¸¥à¹‰à¸§
                if #foundInInventory > 0 then
                    sendSummonStatus(false)
                end

                -- à¹€à¸Šà¹‡à¸„à¸§à¹ˆà¸²à¹€à¸›à¹‡à¸™ Secret unit à¸«à¸£à¸·à¸­à¹„à¸¡à¹ˆ
                local isSecretUnit = false
                for _, configUnit in ipairs(SUMMON_CONFIG) do
                    for _, secretUnit in ipairs(SECRET_UNITS) do
                        if configUnit == secretUnit then
                            isSecretUnit = true
                            break
                        end
                    end
                    if isSecretUnit then break end
                end

                if isSecretUnit then
                    -- Secret unit: à¸‚à¹‰à¸²à¸¡ Banner check (à¸¡à¸µà¹€à¸ªà¸¡à¸­)
                    -- à¸—à¸³à¸•à¹ˆà¸­ loop
                else
                    -- Mythic unit: à¹€à¸Šà¹‡à¸„ Banner à¸§à¹ˆà¸²à¸¢à¸±à¸‡à¸¡à¸µà¸•à¸±à¸§à¸—à¸µà¹ˆà¸•à¹‰à¸­à¸‡à¸à¸²à¸£à¸­à¸¢à¸¹à¹ˆà¸«à¸£à¸·à¸­à¹„à¸¡à¹ˆ
                    local bannerUnits = checkCurrentBanner()
                    local hasMatch = false
                    for _, configUnit in pairs(SUMMON_CONFIG) do
                        for _, bannerUnit in pairs(bannerUnits) do
                            if configUnit == bannerUnit then
                                hasMatch = true
                                break
                            end
                        end
                        if hasMatch then break end
                    end

                    if not hasMatch then
                        if #foundInInventory > 0 then
                            sendSummonStatus(false)
                        end
                        warn("âš ï¸ Target units no longer in banner - stopping summon")
                        break
                    end
                end
            end
        end
    end

elseif not hasTargetUnitConfig and not hasTargetUnitLegendary then
    printStep("Auto Summon (Legendary)...")

    local BANNER_ID = "Standard"
    local AMOUNT_PER_SUMMON = 50  -- à¸ˆà¸³à¸™à¸§à¸™à¸„à¸£à¸±à¹‰à¸‡à¸ªà¸¸à¹ˆà¸¡ (x50 multi)
    local GEMS_PER_SUMMON = 2500  -- Gems à¸—à¸µà¹ˆà¹ƒà¸Šà¹‰à¸•à¹ˆà¸­à¸£à¸­à¸š
    local DELAY = 2
    local summonCount = 0
    local MAX_SUMMONS = 100  -- à¸ˆà¸³à¸à¸±à¸”à¹„à¸§à¹‰ 100 à¸£à¸­à¸šà¸›à¹‰à¸­à¸‡à¸à¸±à¸™à¸§à¸™à¹„à¸¡à¹ˆà¸£à¸¹à¹‰à¸ˆà¸š

    local function checkForTargetUnits()
        local targetUnits = {
            "The Hero",
            "Scissor",
            "Ice Queen",
            "Water Princess",
            "Forbidden Teacher",
            "Greed"
        }
        return #checkInventoryForUnits(targetUnits) > 0
    end

    while not hasTargetUnitLegendary and summonCount < MAX_SUMMONS do
        -- à¹€à¸Šà¹‡à¸„ Gems à¸à¹ˆà¸­à¸™à¸ªà¸¸à¹ˆà¸¡
        local replica = Nodes.GET_PLAYER_REPLICA:InvokeSelf()
        local gems = replica and replica.Data and replica.Data.ItemData and replica.Data.ItemData.Gem and replica.Data.ItemData.Gem.Amount or 0

        if gems < GEMS_PER_SUMMON then
            warn(string.format("âš ï¸ Not enough gems for Legendary summon: %d (require %d) - stopping", gems, GEMS_PER_SUMMON))
            break
        end

        summonCount = summonCount + 1
        print(string.format("ðŸŽ² Legendary Summon #%d | Gems: %d", summonCount, gems))

        pcall(function()
            Nodes.BANNER_SUMMON:FireServer(BANNER_ID, AMOUNT_PER_SUMMON)
        end)

        task.wait(DELAY)

        -- spam à¸„à¸¥à¸´à¸à¸¡à¸¸à¸¡à¸‹à¹‰à¸²à¸¢à¸šà¸™ 5 à¸£à¸­à¸š
        for j = 1, 5 do
            VirtualInputManager:SendMouseButtonEvent(10, 10, 0, true, game, 0)
            task.wait(0.05)
            VirtualInputManager:SendMouseButtonEvent(10, 10, 0, false, game, 0)
            task.wait(0.1)
        end

        task.wait(2)

        -- à¹€à¸Šà¹‡à¸„à¸§à¹ˆà¸²à¹„à¸”à¹‰ target unit à¸«à¸£à¸·à¸­à¸¢à¸±à¸‡
        hasTargetUnitLegendary = checkForTargetUnits()

        if hasTargetUnitLegendary then
            warn("âœ… Target Legendary unit found!")
        end
    end

    if not hasTargetUnitLegendary then
        warn(string.format("âš ï¸ Reached max summons (%d) without finding target unit", MAX_SUMMONS))
    end
else
end

-- ========================================
-- 6.5 Trait Reroll System (à¸–à¹‰à¸²à¸¡à¸µ Config)
-- ========================================
-- à¹€à¸Šà¹‡à¸„à¸§à¹ˆà¸²à¸„à¸§à¸£à¸—à¸³ Trait Reroll à¸«à¸£à¸·à¸­à¹„à¸¡à¹ˆ
local shouldDoTraitReroll = false
local traitRerollTargetUnit = nil

if TRAIT_REROLL_CONFIG and TRAIT_REROLL_CONFIG.TargetUnit then
    -- Normalize TargetUnit: à¸–à¹‰à¸²à¹€à¸›à¹‡à¸™ table â†’ à¹€à¸­à¸²à¸•à¸±à¸§à¹à¸£à¸, à¸–à¹‰à¸²à¹€à¸›à¹‡à¸™ string â†’ à¹ƒà¸Šà¹‰à¸•à¸£à¸‡à¹†
    local normalizedTargetUnit = TRAIT_REROLL_CONFIG.TargetUnit
    if type(normalizedTargetUnit) == "table" then
        normalizedTargetUnit = normalizedTargetUnit[1]  -- à¹€à¸­à¸²à¸•à¸±à¸§à¹à¸£à¸
    end

    -- à¸à¸£à¸“à¸µà¸—à¸µà¹ˆ 1: TargetUnit = "auto" â†’ à¹ƒà¸Šà¹‰ Fallback logic
    if normalizedTargetUnit == "auto" then
        if hasTargetUnitConfig then
            shouldDoTraitReroll = true
            traitRerollTargetUnit = "auto"  -- à¸ªà¹ˆà¸‡ "auto" à¸•à¹ˆà¸­à¹„à¸›
        elseif not hasTargetUnitConfig and hasSummonConfig then
            -- Fallback: à¹€à¸¥à¸·à¸­à¸ Mythic à¹ƒà¸™ Inventory
            printStep("Checking for fallback Mythic units (auto mode)...")

            local availableMythics = checkInventoryForUnits(MYTHIC_UNITS, true)

            if #availableMythics > 0 then
                -- à¹€à¸£à¸µà¸¢à¸‡à¸•à¸²à¸¡ Priority
                table.sort(availableMythics, function(a, b)
                    local priorityA = 999
                    local priorityB = 999

                    for i, unitName in ipairs(TRAIT_REROLL_PRIORITY) do
                        if a.name == unitName then priorityA = i end
                        if b.name == unitName then priorityB = i end
                    end

                    return priorityA < priorityB
                end)

                local fallbackUnit = availableMythics[1].name
                print(string.format("   Found fallback Mythic: %s", fallbackUnit))

                shouldDoTraitReroll = true
                traitRerollTargetUnit = fallbackUnit
            else
                warn("   âš ï¸ No fallback Mythic units found")
            end
        end
    -- à¸à¸£à¸“à¸µà¸—à¸µà¹ˆ 2: à¸£à¸°à¸šà¸¸à¸Šà¸·à¹ˆà¸­ unit à¹€à¸‰à¸žà¸²à¸° (à¹€à¸Šà¹ˆà¸™ "Shadow")
    else
        shouldDoTraitReroll = true
        traitRerollTargetUnit = normalizedTargetUnit  -- à¹ƒà¸Šà¹‰à¸Šà¸·à¹ˆà¸­à¸—à¸µà¹ˆà¸£à¸°à¸šà¸¸
    end
end

if shouldDoTraitReroll and traitRerollTargetUnit then
    printStep("Checking Trait Reroll Config...")

    local targetUnitName = traitRerollTargetUnit
    local targetTrait = TRAIT_REROLL_CONFIG.TargetTrait

    -- à¹€à¸Šà¹‡à¸„à¸§à¹ˆà¸² SUMMON_CONFIG à¹€à¸›à¹‡à¸™ Secret unit à¸«à¸£à¸·à¸­à¹„à¸¡à¹ˆ
    local isSecretSummon = false
    if hasSummonConfig and CHANGE_ACC_SECRETS then  -- à¸•à¹‰à¸­à¸‡à¹€à¸›à¸´à¸” Config à¸”à¹‰à¸§à¸¢
        for _, configUnit in ipairs(SUMMON_CONFIG) do
            for _, secretUnit in ipairs(SECRET_UNITS) do
                if configUnit == secretUnit then
                    isSecretSummon = true
                    print(string.format("   â„¹ï¸ Config targets Secret unit '%s' + Change_Acc_Secrets enabled - will send DONE after Trait Reroll", configUnit))
                    break
                end
            end
            if isSecretSummon then break end
        end
    end

    -- à¸–à¹‰à¸² TargetUnit à¹€à¸›à¹‡à¸™ "auto" â†’ à¹€à¸¥à¸·à¸­à¸à¸•à¸²à¸¡ Priority
    if targetUnitName == "auto" then
        if hasSummonConfig and hasTargetUnitConfig then
            -- à¹€à¸¥à¸·à¸­à¸à¸ˆà¸²à¸ SummonConfig à¸—à¸µà¹ˆà¹„à¸”à¹‰
            local availableUnits = checkInventoryForUnits(SUMMON_CONFIG, true)

            if #availableUnits > 0 then
                -- à¹€à¸£à¸µà¸¢à¸‡à¸•à¸²à¸¡ Priority
                table.sort(availableUnits, function(a, b)
                    local priorityA = 999
                    local priorityB = 999

                    for i, unitName in ipairs(TRAIT_REROLL_PRIORITY) do
                        if a.name == unitName then priorityA = i end
                        if b.name == unitName then priorityB = i end
                    end

                    return priorityA < priorityB
                end)

                targetUnitName = availableUnits[1].name
                print(string.format("   Auto-selected: %s (Priority)", targetUnitName))
            else
                -- à¹„à¸¡à¹ˆà¹€à¸ˆà¸­ Config units â†’ à¸¥à¸­à¸‡ Fallback à¹„à¸› Mythic
                warn("   âš ï¸ No summon config units found in inventory")

                -- à¸–à¹‰à¸²à¹€à¸›à¹‡à¸™ Secret Summon + Change_Acc_Secrets â†’ à¹ƒà¸Šà¹‰ Mythic Fallback
                if isSecretSummon and CHANGE_ACC_SECRETS then
                    print("   â„¹ï¸ Checking Mythic fallback for Trait Reroll...")
                    local mythicUnits = checkInventoryForUnits(MYTHIC_UNITS, true)

                    if #mythicUnits > 0 then
                        -- à¹€à¸£à¸µà¸¢à¸‡à¸•à¸²à¸¡ Priority
                        table.sort(mythicUnits, function(a, b)
                            local priorityA = 999
                            local priorityB = 999

                            for i, unitName in ipairs(TRAIT_REROLL_PRIORITY) do
                                if a.name == unitName then priorityA = i end
                                if b.name == unitName then priorityB = i end
                            end

                            return priorityA < priorityB
                        end)

                        targetUnitName = mythicUnits[1].name
                        print(string.format("   âœ… Auto-selected Mythic fallback: %s (Priority)", targetUnitName))
                    else
                        targetUnitName = nil
                    end
                else
                    targetUnitName = nil
                end
            end
        else
            warn("   âš ï¸ Cannot use 'auto' without SummonConfig or target unit")
            targetUnitName = nil
        end
    end

    if targetUnitName then
        -- à¹€à¸Šà¹‡à¸„à¸§à¹ˆà¸²à¸¡à¸µà¸•à¸±à¸§à¸—à¸µà¹ˆà¸•à¹‰à¸­à¸‡à¸à¸²à¸£à¸«à¸£à¸·à¸­à¹„à¸¡à¹ˆ
        local unitsWithTrait = checkInventoryForUnits({targetUnitName}, true)

        if #unitsWithTrait > 0 then
            -- à¹€à¸¥à¸·à¸­à¸à¸•à¸±à¸§à¸—à¸µà¹ˆà¸”à¸µà¸—à¸µà¹ˆà¸ªà¸¸à¸”à¸ªà¸³à¸«à¸£à¸±à¸šà¸ªà¸¸à¹ˆà¸¡ Trait (à¹€à¸¥à¸·à¸­à¸ Shiny à¸à¹ˆà¸­à¸™)
            local unitInfo = selectBestUnitForReroll(unitsWithTrait)
            local currentTrait = unitInfo.trait

            print(string.format("   Selected unit: %s (Trait: %s, Shiny: %s, Full Key: %s)",
                unitInfo.name, currentTrait, tostring(unitInfo.isShiny or false), unitInfo.fullKey))

            -- à¹€à¸Šà¹‡à¸„à¸§à¹ˆà¸²à¸¡à¸µ Trait à¸—à¸µà¹ˆà¸•à¹‰à¸­à¸‡à¸à¸²à¸£à¹à¸¥à¹‰à¸§à¸«à¸£à¸·à¸­à¹„à¸¡à¹ˆ
            local hasTargetTrait = false

            if not targetTrait then
                -- nil = à¸ªà¸¸à¹ˆà¸¡à¹à¸šà¸šà¸ªà¸¸à¹ˆà¸¡ (à¹„à¸”à¹‰à¸­à¸°à¹„à¸£à¸à¹‡à¹„à¸”à¹‰à¸—à¸µà¹ˆà¹„à¸¡à¹ˆà¹ƒà¸Šà¹ˆ None)
                hasTargetTrait = (currentTrait ~= "None")
            elseif type(targetTrait) == "table" then
                if #targetTrait == 0 then
                    -- {} = empty table â†’ à¹„à¸¡à¹ˆà¸•à¹‰à¸­à¸‡à¸ªà¸¸à¹ˆà¸¡ Trait
                    hasTargetTrait = true
                else
                    -- à¹€à¸Šà¹‡à¸„à¸§à¹ˆà¸²à¸¡à¸µà¹ƒà¸™ list à¸«à¸£à¸·à¸­à¹„à¸¡à¹ˆ
                    for _, trait in ipairs(targetTrait) do
                        if currentTrait == trait then
                            hasTargetTrait = true
                            break
                        end
                    end
                end
            else
                -- string à¹€à¸”à¸µà¸¢à¸§
                hasTargetTrait = (currentTrait == targetTrait)
            end

            if hasTargetTrait then
                -- à¸¡à¸µ Trait à¸—à¸µà¹ˆà¸•à¹‰à¸­à¸‡à¸à¸²à¸£à¹à¸¥à¹‰à¸§ â†’ à¸‚à¹‰à¸²à¸¡à¸à¸²à¸£à¸ªà¸¸à¹ˆà¸¡
                print(string.format("âœ… %s already has target Trait: %s", targetUnitName, currentTrait))

                -- à¸ªà¹ˆà¸‡ Horst Description + DONE
                if HORST_ENABLED and _G.Horst_SetDescription and _G.Horst_AccountChangeDone then
                    local replica = Nodes.GET_PLAYER_REPLICA:InvokeSelf()
                    local currentGems = replica and replica.Data.ItemData.Gem.Amount or 0
                    local currentRR = replica and replica.Data.ItemData.TraitReroll and replica.Data.ItemData.TraitReroll.Amount or 0

                    _G.Horst_SetDescription(string.format("ðŸ’Ž Gems: %d â€¢ RR: %d â€¢ %s â€¢ Trait: âœ… %s", currentGems, currentRR, targetUnitName, currentTrait))

                    task.wait(15)  -- à¸£à¸­ 15 à¸§à¸´à¸à¹ˆà¸­à¸™à¸ªà¹ˆà¸‡ DONE

                    -- à¸–à¹‰à¸² Config à¹€à¸›à¹‡à¸™ Secret unit â†’ à¸šà¸±à¸‡à¸„à¸±à¸šà¸ªà¹ˆà¸‡ DONE
                    local ok = pcall(_G.Horst_AccountChangeDone)
                        if ok then
                            _G.ScriptShouldStop = true  -- à¸•à¸±à¹‰à¸‡à¸„à¹ˆà¸² flag à¸«à¸¥à¸±à¸‡à¸ªà¹ˆà¸‡ DONE à¸ªà¸³à¹€à¸£à¹‡à¸ˆ
                            print("âœ… Secret unit Trait completed - Script will stop...")

                            -- Loop à¸ªà¹ˆà¸‡ Description à¸—à¸¸à¸ 5 à¸§à¸´à¸«à¸¥à¸±à¸‡ DONE
                            while true do
                                pcall(function()
                                    local replica = Nodes.GET_PLAYER_REPLICA:InvokeSelf()
                                    local gems = replica and replica.Data.ItemData.Gem.Amount or 0
                                    local rr = replica and replica.Data.ItemData.TraitReroll and replica.Data.ItemData.TraitReroll.Amount or 0
                                    _G.Horst_SetDescription(string.format("ðŸ’Ž Gems: %d â€¢ RR: %d â€¢ %s â€¢ Trait: âœ… %s", gems, rr, targetUnitName, currentTrait))
                                end)
                                task.wait(5)
                            end
                        end
                    end

                    if GEM_TARGET then
                        if currentGems >= GEM_TARGET then
                            local ok = pcall(_G.Horst_AccountChangeDone)
                            if ok then
                                _G.ScriptShouldStop = true  -- à¸•à¸±à¹‰à¸‡à¸„à¹ˆà¸² flag à¸«à¸¥à¸±à¸‡à¸ªà¹ˆà¸‡ DONE à¸ªà¸³à¹€à¸£à¹‡à¸ˆ
                                print("âœ… GEM_TARGET reached - Script will stop...")

                                -- Loop à¸ªà¹ˆà¸‡ Description à¸—à¸¸à¸ 5 à¸§à¸´à¸«à¸¥à¸±à¸‡ DONE
                                while true do
                                    pcall(function()
                                        local replica = Nodes.GET_PLAYER_REPLICA:InvokeSelf()
                                        local gems = replica and replica.Data.ItemData.Gem.Amount or 0
                                        local rr = replica and replica.Data.ItemData.TraitReroll and replica.Data.ItemData.TraitReroll.Amount or 0
                                        _G.Horst_SetDescription(string.format("ðŸ’Ž Gems: %d â€¢ RR: %d â€¢ %s â€¢ Trait: âœ… %s", gems, rr, targetUnitName, currentTrait))
                                    end)
                                    task.wait(5)
                                end
                            end
                        end
                    else
                        local ok = pcall(_G.Horst_AccountChangeDone)
                        if ok then
                            _G.ScriptShouldStop = true  -- à¸•à¸±à¹‰à¸‡à¸„à¹ˆà¸² flag à¸«à¸¥à¸±à¸‡à¸ªà¹ˆà¸‡ DONE à¸ªà¸³à¹€à¸£à¹‡à¸ˆ
                            print("âœ… Trait Reroll completed - Script will stop...")

                            -- Loop à¸ªà¹ˆà¸‡ Description à¸—à¸¸à¸ 5 à¸§à¸´à¸«à¸¥à¸±à¸‡ DONE
                            while true do
                                pcall(function()
                                    local replica = Nodes.GET_PLAYER_REPLICA:InvokeSelf()
                                    local gems = replica and replica.Data.ItemData.Gem.Amount or 0
                                    local rr = replica and replica.Data.ItemData.TraitReroll and replica.Data.ItemData.TraitReroll.Amount or 0
                                    _G.Horst_SetDescription(string.format("ðŸ’Ž Gems: %d â€¢ RR: %d â€¢ %s â€¢ Trait: âœ… %s", gems, rr, targetUnitName, currentTrait))
                                end)
                                task.wait(5)
                            end
                        end
                    end
                end
            else
                -- à¸¢à¸±à¸‡à¹„à¸¡à¹ˆà¸¡à¸µ Trait à¸—à¸µà¹ˆà¸•à¹‰à¸­à¸‡à¸à¸²à¸£ â†’ à¹€à¸£à¸´à¹ˆà¸¡à¸ªà¸¸à¹ˆà¸¡
                printStep(string.format("Rerolling Trait for %s...", targetUnitName))

                -- à¹€à¸Šà¹‡à¸„ Trait Reroll à¸ˆà¸³à¸™à¸§à¸™
                local replica = Nodes.GET_PLAYER_REPLICA:InvokeSelf()
                local traitRerolls = 0
                if replica and replica.Data and replica.Data.ItemData and replica.Data.ItemData.TraitReroll then
                    traitRerolls = replica.Data.ItemData.TraitReroll.Amount or 0
                end

                if traitRerolls <= 0 then
                    warn("âŒ No Trait Reroll items available")

                    -- à¸ªà¹ˆà¸‡ Horst Description + DONE (Out of RR)
                    if HORST_ENABLED and _G.Horst_SetDescription and _G.Horst_AccountChangeDone then
                        local currentGems = replica and replica.Data.ItemData.Gem.Amount or 0
                        local currentRR = replica and replica.Data.ItemData.TraitReroll and replica.Data.ItemData.TraitReroll.Amount or 0

                        _G.Horst_SetDescription(string.format("💎 Gems: %d • RR: %d • %s • Trait: ❌ %s (Out of RR)", currentGems, currentRR, targetUnitName, currentTrait))

                        task.wait(15)

                        local ok = pcall(_G.Horst_AccountChangeDone)
                        if ok then
                            _G.ScriptShouldStop = true
                            print("✅ Out of RR - Script will stop...")

                            while true do
                                pcall(function()
                                    local replica = Nodes.GET_PLAYER_REPLICA:InvokeSelf()
                                    local gems = replica and replica.Data.ItemData.Gem.Amount or 0
                                    local rr = replica and replica.Data.ItemData.TraitReroll and replica.Data.ItemData.TraitReroll.Amount or 0
                                    _G.Horst_SetDescription(string.format("💎 Gems: %d • RR: %d • %s • Trait: ❌ %s (Out of RR)", gems, rr, targetUnitName, currentTrait))
                                end)
                                task.wait(5)
                            end
                        end
                    end
                    return
                end
                else
                -- à¸Ÿà¸±à¸‡à¸à¹Œà¸Šà¸±à¸™à¹€à¸Šà¹‡à¸„ Trait à¸›à¸±à¸ˆà¸ˆà¸¸à¸šà¸±à¸™à¸žà¸£à¹‰à¸­à¸¡ retry
                local function getCurrentTrait(fullKey, maxRetries)
                    maxRetries = maxRetries or 10

                    for i = 1, maxRetries do
                        local success, result = pcall(function()
                            local newUnitData = Nodes.GET_DATA_VALUE:InvokeSelf("UnitData")
                            if newUnitData and newUnitData[fullKey] then
                                return newUnitData[fullKey].Trait or "None"
                            end
                            return nil
                        end)

                        if success and result then
                            return result
                        end

                        if i < maxRetries then
                            task.wait(0.1)
                        end
                    end

                    return nil
                end

                -- à¹€à¸£à¸´à¹ˆà¸¡à¸ªà¸¸à¹ˆà¸¡ Trait
                local attempts = 0
                local success = false
                local finalTrait = currentTrait

                while attempts < traitRerolls do
                    -- à¹€à¸Šà¹‡à¸„ RR à¸›à¸±à¸ˆà¸ˆà¸¸à¸šà¸±à¸™à¸à¹ˆà¸­à¸™à¸ªà¸¸à¹ˆà¸¡à¹à¸•à¹ˆà¸¥à¸°à¸£à¸­à¸š
                    local currentReplica = Nodes.GET_PLAYER_REPLICA:InvokeSelf()
                    local currentRR = 0
                    if currentReplica and currentReplica.Data and currentReplica.Data.ItemData and currentReplica.Data.ItemData.TraitReroll then
                        currentRR = currentReplica.Data.ItemData.TraitReroll.Amount or 0
                    end

                    if currentRR <= 0 then
                        print(string.format("âš ï¸ Out of RR during reroll (attempt %d/%d)", attempts, traitRerolls))
                        break
                    end

                    -- à¸à¸³à¸«à¸™à¸” Trait à¸—à¸µà¹ˆà¸ˆà¸°à¸ªà¹ˆà¸‡à¹„à¸›
                    local traitToRoll = nil
                    if type(targetTrait) == "string" then
                        traitToRoll = targetTrait
                    end

                    -- à¸ªà¸¸à¹ˆà¸¡ Trait
                    local rollSuccess, rollError = pcall(function()
                        Nodes.ROLL_UNIT_TRAIT:FireServer(unitInfo.fullKey, traitToRoll)
                    end)

                    if not rollSuccess then
                        task.wait(0.1)
                        continue
                    end

                    -- à¸™à¸±à¸š attempts à¹€à¸‰à¸žà¸²à¸°à¹€à¸¡à¸·à¹ˆà¸­ FireServer à¸ªà¸³à¹€à¸£à¹‡à¸ˆ
                    attempts = attempts + 1

                    task.wait(0.5)

                    -- à¹€à¸Šà¹‡à¸„ Trait à¹ƒà¸«à¸¡à¹ˆ
                    local newTrait = getCurrentTrait(unitInfo.fullKey, 10)

                    if not newTrait then
                        task.wait(0.1)
                        continue
                    end

                    finalTrait = newTrait

                    -- à¸•à¸£à¸§à¸ˆà¸ªà¸­à¸šà¸§à¹ˆà¸²à¹„à¸”à¹‰ Trait à¸—à¸µà¹ˆà¸•à¹‰à¸­à¸‡à¸à¸²à¸£à¸«à¸£à¸·à¸­à¹„à¸¡à¹ˆ
                    local gotTargetTrait = false

                    if not targetTrait then
                        if newTrait ~= "None" then
                            gotTargetTrait = true
                        end
                    elseif type(targetTrait) == "table" then
                        for _, trait in ipairs(targetTrait) do
                            if newTrait == trait then
                                gotTargetTrait = true
                                break
                            end
                        end
                    else
                        if newTrait == targetTrait then
                            gotTargetTrait = true
                        end
                    end

                    if gotTargetTrait then
                        success = true
                        break
                    end

                    task.wait(0.1)
                end

                -- à¹à¸ªà¸”à¸‡à¸œà¸¥à¸¥à¸±à¸žà¸˜à¹Œ
                if success then
                    print(string.format("âœ… %s | Trait: %s | Used: %d | Left: %d",
                        targetUnitName, finalTrait, attempts, traitRerolls - attempts))

                    -- à¸ªà¸³à¹€à¸£à¹‡à¸ˆ
                    if HORST_ENABLED and _G.Horst_SetDescription and _G.Horst_AccountChangeDone then
                        local replicaAfter = Nodes.GET_PLAYER_REPLICA:InvokeSelf()
                        local currentGems = replicaAfter and replicaAfter.Data.ItemData.Gem.Amount or 0
                        local currentRR = replicaAfter and replicaAfter.Data.ItemData.TraitReroll and replicaAfter.Data.ItemData.TraitReroll.Amount or 0

                        _G.Horst_SetDescription(string.format("ðŸ’Ž Gems: %d â€¢ RR: %d â€¢ %s â€¢ Trait: âœ… %s", currentGems, currentRR, targetUnitName, finalTrait))

                        task.wait(15)  -- à¸£à¸­ 15 à¸§à¸´à¸à¹ˆà¸­à¸™à¸ªà¹ˆà¸‡ DONE

                        -- à¸–à¹‰à¸² Config à¹€à¸›à¹‡à¸™ Secret unit â†’ à¸šà¸±à¸‡à¸„à¸±à¸šà¸ªà¹ˆà¸‡ DONE
                        local ok = pcall(_G.Horst_AccountChangeDone)
                            if ok then
                                _G.ScriptShouldStop = true  -- à¸•à¸±à¹‰à¸‡à¸„à¹ˆà¸² flag à¸«à¸¥à¸±à¸‡à¸ªà¹ˆà¸‡ DONE à¸ªà¸³à¹€à¸£à¹‡à¸ˆ
                                print("âœ… Secret unit Trait succeeded - Script will stop...")

                                -- Loop à¸ªà¹ˆà¸‡ Description à¸—à¸¸à¸ 5 à¸§à¸´à¸«à¸¥à¸±à¸‡ DONE
                                while true do
                                    pcall(function()
                                        local replicaAfter = Nodes.GET_PLAYER_REPLICA:InvokeSelf()
                                        local gems = replicaAfter and replicaAfter.Data.ItemData.Gem.Amount or 0
                                        local rr = replicaAfter and replicaAfter.Data.ItemData.TraitReroll and replicaAfter.Data.ItemData.TraitReroll.Amount or 0
                                        _G.Horst_SetDescription(string.format("ðŸ’Ž Gems: %d â€¢ RR: %d â€¢ %s â€¢ Trait: âœ… %s", gems, rr, targetUnitName, finalTrait))
                                    end)
                                    task.wait(5)
                                end
                            end
                        end

                        if GEM_TARGET then
                            if currentGems >= GEM_TARGET then
                                local ok = pcall(_G.Horst_AccountChangeDone)
                                if ok then
                                    _G.ScriptShouldStop = true  -- à¸•à¸±à¹‰à¸‡à¸„à¹ˆà¸² flag à¸«à¸¥à¸±à¸‡à¸ªà¹ˆà¸‡ DONE à¸ªà¸³à¹€à¸£à¹‡à¸ˆ
                                    print("âœ… GEM_TARGET reached - Script will stop...")

                                    -- Loop à¸ªà¹ˆà¸‡ Description à¸—à¸¸à¸ 5 à¸§à¸´à¸«à¸¥à¸±à¸‡ DONE
                                    while true do
                                        pcall(function()
                                            local replicaAfter = Nodes.GET_PLAYER_REPLICA:InvokeSelf()
                                            local gems = replicaAfter and replicaAfter.Data.ItemData.Gem.Amount or 0
                                            local rr = replicaAfter and replicaAfter.Data.ItemData.TraitReroll and replicaAfter.Data.ItemData.TraitReroll.Amount or 0
                                            _G.Horst_SetDescription(string.format("ðŸ’Ž Gems: %d â€¢ RR: %d â€¢ %s â€¢ Trait: âœ… %s", gems, rr, targetUnitName, finalTrait))
                                        end)
                                        task.wait(5)
                                    end
                                end
                            end
                        else
                            local ok = pcall(_G.Horst_AccountChangeDone)
                            if ok then
                                _G.ScriptShouldStop = true  -- à¸•à¸±à¹‰à¸‡à¸„à¹ˆà¸² flag à¸«à¸¥à¸±à¸‡à¸ªà¹ˆà¸‡ DONE à¸ªà¸³à¹€à¸£à¹‡à¸ˆ
                                print("âœ… Trait Reroll succeeded - Script will stop...")

                                -- Loop à¸ªà¹ˆà¸‡ Description à¸—à¸¸à¸ 5 à¸§à¸´à¸«à¸¥à¸±à¸‡ DONE
                                while true do
                                    pcall(function()
                                        local replicaAfter = Nodes.GET_PLAYER_REPLICA:InvokeSelf()
                                        local gems = replicaAfter and replicaAfter.Data.ItemData.Gem.Amount or 0
                                        local rr = replicaAfter and replicaAfter.Data.ItemData.TraitReroll and replicaAfter.Data.ItemData.TraitReroll.Amount or 0
                                        _G.Horst_SetDescription(string.format("ðŸ’Ž Gems: %d â€¢ RR: %d â€¢ %s â€¢ Trait: âœ… %s", gems, rr, targetUnitName, finalTrait))
                                    end)
                                    task.wait(5)
                                end
                            end
                        end
                    end
                else
                    -- à¹ƒà¸Šà¹‰à¸«à¸¡à¸”
                    print(string.format("âš ï¸ %s | Final Trait: %s | Used: %d (all rerolls)", targetUnitName, finalTrait, traitRerolls))

                    if HORST_ENABLED and _G.Horst_SetDescription and _G.Horst_AccountChangeDone then
                        local replicaAfter = Nodes.GET_PLAYER_REPLICA:InvokeSelf()
                        local currentGems = replicaAfter and replicaAfter.Data.ItemData.Gem.Amount or 0
                        local currentRR = replicaAfter and replicaAfter.Data.ItemData.TraitReroll and replicaAfter.Data.ItemData.TraitReroll.Amount or 0

                        _G.Horst_SetDescription(string.format("ðŸ’Ž Gems: %d â€¢ RR: %d â€¢ %s â€¢ Trait: âŒ %s (Out of RR)", currentGems, currentRR, targetUnitName, finalTrait))

                        task.wait(15)  -- à¸£à¸­ 15 à¸§à¸´à¸à¹ˆà¸­à¸™à¸ªà¹ˆà¸‡ DONE

                        -- à¸–à¹‰à¸² Config à¹€à¸›à¹‡à¸™ Secret unit â†’ à¸šà¸±à¸‡à¸„à¸±à¸šà¸ªà¹ˆà¸‡ DONE
                        local ok = pcall(_G.Horst_AccountChangeDone)
                            if ok then
                                _G.ScriptShouldStop = true  -- à¸•à¸±à¹‰à¸‡à¸„à¹ˆà¸² flag à¸«à¸¥à¸±à¸‡à¸ªà¹ˆà¸‡ DONE à¸ªà¸³à¹€à¸£à¹‡à¸ˆ
                                print("âœ… Secret unit (all rerolls used) - Script will stop...")

                                -- Loop à¸ªà¹ˆà¸‡ Description à¸—à¸¸à¸ 5 à¸§à¸´à¸«à¸¥à¸±à¸‡ DONE
                                while true do
                                    pcall(function()
                                        local replicaAfter = Nodes.GET_PLAYER_REPLICA:InvokeSelf()
                                        local gems = replicaAfter and replicaAfter.Data.ItemData.Gem.Amount or 0
                                        local rr = replicaAfter and replicaAfter.Data.ItemData.TraitReroll and replicaAfter.Data.ItemData.TraitReroll.Amount or 0
                                        _G.Horst_SetDescription(string.format("ðŸ’Ž Gems: %d â€¢ RR: %d â€¢ %s â€¢ Trait: âŒ %s (Out of RR)", gems, rr, targetUnitName, finalTrait))
                                    end)
                                    task.wait(5)
                                end
                            end
                        end

                        if GEM_TARGET then
                            if currentGems >= GEM_TARGET then
                                local ok = pcall(_G.Horst_AccountChangeDone)
                                if ok then
                                    _G.ScriptShouldStop = true  -- à¸•à¸±à¹‰à¸‡à¸„à¹ˆà¸² flag à¸«à¸¥à¸±à¸‡à¸ªà¹ˆà¸‡ DONE à¸ªà¸³à¹€à¸£à¹‡à¸ˆ
                                    print("âœ… GEM_TARGET reached - Script will stop...")

                                    -- Loop à¸ªà¹ˆà¸‡ Description à¸—à¸¸à¸ 5 à¸§à¸´à¸«à¸¥à¸±à¸‡ DONE
                                    while true do
                                        pcall(function()
                                            local replicaAfter = Nodes.GET_PLAYER_REPLICA:InvokeSelf()
                                            local gems = replicaAfter and replicaAfter.Data.ItemData.Gem.Amount or 0
                                            local rr = replicaAfter and replicaAfter.Data.ItemData.TraitReroll and replicaAfter.Data.ItemData.TraitReroll.Amount or 0
                                            _G.Horst_SetDescription(string.format("ðŸ’Ž Gems: %d â€¢ RR: %d â€¢ %s â€¢ Trait: âŒ %s (Out of RR)", gems, rr, targetUnitName, finalTrait))
                                        end)
                                        task.wait(5)
                                    end
                                end
                            end
                        else
                            local ok = pcall(_G.Horst_AccountChangeDone)
                            if ok then
                                _G.ScriptShouldStop = true  -- à¸•à¸±à¹‰à¸‡à¸„à¹ˆà¸² flag à¸«à¸¥à¸±à¸‡à¸ªà¹ˆà¸‡ DONE à¸ªà¸³à¹€à¸£à¹‡à¸ˆ
                                print("âœ… All rerolls used - Script will stop...")

                                -- Loop à¸ªà¹ˆà¸‡ Description à¸—à¸¸à¸ 5 à¸§à¸´à¸«à¸¥à¸±à¸‡ DONE
                                while true do
                                    pcall(function()
                                        local replicaAfter = Nodes.GET_PLAYER_REPLICA:InvokeSelf()
                                        local gems = replicaAfter and replicaAfter.Data.ItemData.Gem.Amount or 0
                                        local rr = replicaAfter and replicaAfter.Data.ItemData.TraitReroll and replicaAfter.Data.ItemData.TraitReroll.Amount or 0
                                    _G.Horst_SetDescription(string.format("ðŸ’Ž Gems: %d â€¢ RR: %d â€¢ %s â€¢ Trait: âŒ %s (Out of RR)", gems, rr, targetUnitName, finalTrait))
                                end)
                                task.wait(5)
                                end
                            end
                        end
                    end
                end
                end  -- à¸›à¸´à¸” else à¸‚à¸­à¸‡ if traitRerolls <= 0
            end  -- à¸›à¸´à¸” if hasTargetTrait
        else
            warn(string.format("âš ï¸ Unit '%s' not found in inventory - skipping Trait Reroll", targetUnitName))
        end  -- à¸›à¸´à¸” if #unitsWithTrait > 0
    else
        warn("âš ï¸ No target unit specified - skipping Trait Reroll")
    end  -- à¸›à¸´à¸” if targetUnitName then

    task.wait(1)
end  -- à¸›à¸´à¸” if shouldDoTraitReroll and traitRerollTargetUnit

-- ========================================
-- 7. QuickEquip (à¹€à¸‰à¸žà¸²à¸° Carrot + Legendary à¹€à¸—à¹ˆà¸²à¸™à¸±à¹‰à¸™)
-- ========================================
-- à¹€à¸‚à¹‰à¸²à¹€à¸à¸¡à¹€à¸ªà¸¡à¸­ à¹à¸•à¹ˆ equip Legendary à¹€à¸‰à¸žà¸²à¸°à¸•à¸­à¸™à¸—à¸µà¹ˆà¸¡à¸µ
printStep("Quick Equip...")

-- Get UnitData à¹à¸¥à¸° UnitInfo à¹‚à¸”à¸¢à¸•à¸£à¸‡ (à¹„à¸¡à¹ˆà¸•à¹‰à¸­à¸‡à¸›à¸´à¸” Inventory)
local unitData = Nodes.GET_DATA_VALUE:InvokeSelf("UnitData")
local UnitInfo = require(ReplicatedStorage.Shared.Information.Units)

-- à¸ªà¸£à¹‰à¸²à¸‡ displayNameMap (à¹€à¸¥à¸·à¸­à¸ Shiny à¸à¹ˆà¸­à¸™)
local displayNameMap = {}
for fullKey, data in pairs(unitData) do
    local internalName = fullKey:match("^(.+)#") or fullKey
    local displayName = UnitInfo[internalName] and UnitInfo[internalName].DisplayName or internalName
    local lowerName = displayName:lower()
    local isShiny = data.Shiny or false

    -- à¹€à¸¥à¸·à¸­à¸ Shiny à¸à¹ˆà¸­à¸™ à¸«à¸£à¸·à¸­à¸–à¹‰à¸²à¸¢à¸±à¸‡à¹„à¸¡à¹ˆà¸¡à¸µà¸à¹‡à¹€à¸­à¸²à¸•à¸±à¸§à¸›à¸à¸•à¸´
    if not displayNameMap[lowerName] or isShiny then
        displayNameMap[lowerName] = fullKey
    end
end

-- à¸«à¸² Legendary à¸—à¸µà¹ˆà¸¡à¸µà¸­à¸¢à¸¹à¹ˆ (à¹€à¸¥à¸·à¸­à¸à¸ˆà¸²à¸ Legendary List à¹€à¸—à¹ˆà¸²à¸™à¸±à¹‰à¸™)
local LEGENDARY_UNITS = {
    "Ice Queen",           -- Priority 1 (à¸§à¸²à¸‡à¹„à¸”à¹‰ 4 à¸•à¸±à¸§)
    "Forbidden Teacher",   -- Priority 2 (à¸§à¸²à¸‡à¹„à¸”à¹‰ 4 à¸•à¸±à¸§)
    "The Hero",           -- Priority 3 (à¸§à¸²à¸‡à¹„à¸”à¹‰ 4 à¸•à¸±à¸§)
    "Greed",              -- Priority 4 (à¸§à¸²à¸‡à¹„à¸”à¹‰ 3 à¸•à¸±à¸§)
    "Scissor",            -- Priority 5 (à¸§à¸²à¸‡à¹„à¸”à¹‰ 3 à¸•à¸±à¸§)
    "Water Princess"      -- Priority 6 (à¸§à¸²à¸‡à¹„à¸”à¹‰ 3 à¸•à¸±à¸§)
}

local foundLegendaryUnit = nil

-- à¹€à¸Šà¹‡à¸„à¸•à¸²à¸¡à¸¥à¸³à¸”à¸±à¸š Priority
for _, targetUnit in ipairs(LEGENDARY_UNITS) do
    if displayNameMap[targetUnit:lower()] then
        foundLegendaryUnit = targetUnit
        break
    end
end

-- Unequip All à¸à¹ˆà¸­à¸™
Nodes.UNIT_UNEQUIP_ALL:FireServer("Unit")
task.wait(0.5)

-- Equip Carrot à¸Šà¹ˆà¸­à¸‡ 1 (à¹€à¸ªà¸¡à¸­)
local carrotFullKey = displayNameMap["carrot"]
if carrotFullKey then
    Nodes.UNIT_EQUIP:FireServer(carrotFullKey, "1")
    task.wait(0.3)
    print("âœ… Equipped Carrot in slot 1")
else
    warn("âŒ Carrot not found in inventory")
end

-- Equip Legendary à¸Šà¹ˆà¸­à¸‡ 2 (à¸–à¹‰à¸²à¸¡à¸µ)
if foundLegendaryUnit then
    local legendaryFullKey = displayNameMap[foundLegendaryUnit:lower()]
    if legendaryFullKey then
        Nodes.UNIT_EQUIP:FireServer(legendaryFullKey, "2")
        task.wait(0.3)
        print(string.format("âœ… Equipped %s in slot 2", foundLegendaryUnit))
    end
else
    print("â„¹ï¸ No Legendary unit found - will farm with Carrot only in slot 1")
end

task.wait(1)

-- ========================================
-- 8. auto_start_game.lua
-- ========================================
printStep("Starting Game...")

local CONFIG = {
    MapName = "SchoolGrounds",
    ActName = "Act 1",
    Difficulty = "Hard",
    Gamemode = "Story"
}

local FusionPackage = ReplicatedStorage:WaitForChild("FusionPackage")
local Actions = require(FusionPackage.Actions)
Actions.PartyStartGame(CONFIG)
