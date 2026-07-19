repeat wait() until game:IsLoaded()
-- ========================================
-- Main Script - รวมทุกฟังก์ชันตามลำดับ
-- ========================================

-- ========================================
-- Anti-AFK (โหลดก่อนอันแรก)
-- ========================================
local Players = game:GetService("Players")
local VirtualUser = game:GetService("VirtualUser")

Players.LocalPlayer.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end)

-- ========================================
-- CONFIG (รองรับ External Config)
-- ========================================
_G.Config = _G.Config or {}
local HORST_ENABLED = _G.Config.Horst == true
local GEM_TARGET = _G.Config.GemTarget  -- nil = ไม่ส่ง DONE
local UPDATE_INTERVAL = 30
local TOGGLE_RENDER3D = _G.Config.ToggleRender3D == true  -- ผูก Render3D กับ GUI toggle

-- ตัวนับ Steps
local TOTAL_STEPS = 9
local currentStep = 0

local function printStep(stepName)
    currentStep = currentStep + 1
    print(string.format("[%d/%d] %s", currentStep, TOTAL_STEPS, stepName))
end

-- ========================================
-- -1. Load Horst API (ถ้า Config เปิด)
-- ========================================
if HORST_ENABLED then
    printStep("Loading Horst API...")
    local success, err = pcall(function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/HorstSpaceX/last_update/main/on_loaded.lua"))()
    end)

    if success then
        if GEM_TARGET then
            print("   🎯 Gem Target:", GEM_TARGET)
        else
            print("   📡 Status Update Only Mode")
        end
    else
        warn("   ❌ Failed to load Horst API:", err)
        HORST_ENABLED = false
    end
    task.wait(1)
end

-- ========================================
-- 0. StatsGUI (โหลดก่อนอันแรก)
-- ========================================
printStep("Loading Stats GUI...")
do
    local Players = game:GetService("Players")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local RunService = game:GetService("RunService")

    local player = Players.LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui")
    local Nodes = require(ReplicatedStorage:WaitForChild("Nodes"))

    -- สร้าง ScreenGui
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "StatsDisplay"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.DisplayOrder = 999999
    screenGui.IgnoreGuiInset = true
    screenGui.Parent = playerGui

    -- Frame หลัก
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

        -- Container สำหรับ name และ value
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

        -- Name (ซ้าย)
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

        -- Colon (กลาง)
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

        -- Value (ขวา)
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

    -- ฟังก์ชันใส่ลูกน้ำ
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

    -- ฟังก์ชันดึงค่า Stats
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

    -- Update ทุก 1 วินาที
    task.wait(2)
    updateStats()

    RunService.Heartbeat:Connect(function()
        if tick() % 1 < 0.016 then
            updateStats()
        end
    end)

    -- ========================================
    -- Toggle GUI with N key (+ Render3D ถ้าเปิด Config)
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
    -- Horst Status Reporter (ส่งข้อมูลทุก 30 วิ)
    -- ========================================
    if HORST_ENABLED then
        local doneSent = false

        -- ฟังก์ชันส่ง Status
        local function sendHorstStatus()
            local success, err = pcall(function()
                local replica = Nodes.GET_PLAYER_REPLICA:InvokeSelf()
                if not replica then return end

                local data = replica.Data
                local itemData = data.ItemData
                if not itemData then return end

                -- ดึงข้อมูล Stats
                local level = data.Level or 0
                local gem = itemData.Gem and itemData.Gem.Amount or 0
                local gold = itemData.Gold and itemData.Gold.Amount or 0
                local trait = itemData.TraitReroll and itemData.TraitReroll.Amount or 0

                -- สร้าง Status Message
                local HttpService = game:GetService("HttpService")
                local json_data = {
                    Level = level,
                    Gem = gem,
                    Gold = gold,
                    Trait = trait
                }
                local encoded_json = HttpService:JSONEncode(json_data)

                local message = string.format("⭐ Level : %d, 💎 Gem : %s, 🪙 Gold : %s, 🎲 Trait : %s",
                    level, formatNumber(gem), formatNumber(gold), formatNumber(trait))

                -- ส่ง Status Update
                if _G.Horst_SetDescription then
                    _G.Horst_SetDescription(message, encoded_json)
                end

                -- เช็คเป้าหมาย Gem (ถ้ามี GEM_TARGET)
                if GEM_TARGET and gem >= GEM_TARGET and not doneSent then
                    if _G.Horst_AccountChangeDone then
                        local ok, doneErr = pcall(_G.Horst_AccountChangeDone)
                        if ok then
                            print(string.format("📡 Sent DONE: %s Gems", formatNumber(GEM_TARGET)))
                            doneSent = true
                        else
                            warn(string.format("❌ Failed to send DONE: %s", tostring(doneErr)))
                        end
                    else
                        warn("❌ Horst_AccountChangeDone function not found")
                    end
                end
            end)
        end

        -- ส่งรอบแรกทันที
        task.wait(1)
        sendHorstStatus()

        -- วนลูปส่งทุก 30 วิ
        spawn(function()
            while true do
                task.wait(UPDATE_INTERVAL)
                sendHorstStatus()
            end
        end)
    end
end
task.wait(1)

-- Config (สามารถแก้ไขได้จาก loadstring)
_G.Config = _G.Config or {
    Disable3DRendering = false
}

-- ========================================
-- เช็คว่าอยู่ในแมพ School Grounds - Act 1 หรือไม่
-- ========================================
local function isInTargetMap()
    local success, result = pcall(function()
        local playerGui = game:GetService("Players").LocalPlayer.PlayerGui
        local rightHUD = playerGui:FindFirstChild("RightGameHUD")
        if not rightHUD then return false end

        -- วน loop หา TextLabel ที่มีชื่อแมพ
        for _, child in pairs(rightHUD:GetDescendants()) do
            if child:IsA("TextLabel") then
                local text = child.ContentText or child.Text
                if text == "School Grounds - Act 1" then
                    return true
                end
            end
        end
        return false
    end)
    return success and result
end

-- ========================================
-- เช็คและรอ Wave รีเซ็ต
-- ========================================
local function waitForWaveReset()
    local playerGui = game:GetService("Players").LocalPlayer.PlayerGui
    local topHUD = playerGui:FindFirstChild("TopGameHUD")
    if not topHUD then
        return
    end

    local function getCurrentWave()
        local success, wave = pcall(function()
            local waveLabel = topHUD.Frame:GetChildren()[4].Frame.Frame.Frame.Frame.Frame.TextLabel
            local text = waveLabel.ContentText or waveLabel.Text
            local currentWave = tonumber(string.match(text, "^(%d+)"))
            return currentWave or 0
        end)
        return success and wave or 0
    end

    local maxWave = 0
    while true do
        local currentWave = getCurrentWave()

        if currentWave > maxWave then
            maxWave = currentWave
        elseif currentWave < maxWave and currentWave == 0 then
            return
        end

        task.wait(1)
    end
end

-- เช็คว่าอยู่ในแมพหรือไม่
if isInTargetMap() then
    
    -- ปิด Tutorial popup (ถ้ามี)
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
        if not success then
        end
    end

    closeTutorial()
    task.wait(0.5)

    -- รัน RemoveLobbyMesh เท่านั้น
    local Config = _G.Config

    local g = game
    local w = g.Workspace
    local l = g.Lighting
    local t = w.Terrain

    if Config.Disable3DRendering then
        local RunService = game:GetService("RunService")
        RunService:Set3dRenderingEnabled(false)
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

    -- เช็ค Map ก่อน (เพราะเมื่ออยู่ในเกมให้ลบ Map ไม่ใช่ Lobby)
    local lobbyFolder = workspace:FindFirstChild("Lobby")
    local mapFolder = workspace:FindFirstChild("Map")

    if mapFolder then
        -- ลบ children ของ Map (เกมจะสร้าง folder ใหม่ถ้าลบทั้งก้อน)
        for _, obj in pairs(mapFolder:GetChildren()) do
            obj:Destroy()
        end

        -- สร้างพื้นล่องหนไว้ที่เท้าผู้เล่น
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
    end

    for _, obj in pairs(Lighting:GetChildren()) do
        obj:Destroy()
    end

    local MaterialService = game:GetService("MaterialService")
    for _, obj in pairs(MaterialService:GetChildren()) do
        obj:Destroy()
    end

    for _, obj in pairs(workspace:GetDescendants()) do
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
            obj.Lifetime = NumberRange.new(0)
        elseif obj:IsA("Explosion") then
            obj.BlastPressure = 1
            obj.BlastRadius = 1
        elseif obj:IsA("Fire") or obj:IsA("SpotLight") or obj:IsA("Smoke") then
            obj.Enabled = false
        end
    end

    for _, e in pairs(Lighting:GetChildren()) do
        if e:IsA("BlurEffect") or e:IsA("SunRaysEffect") or e:IsA("ColorCorrectionEffect") or e:IsA("BloomEffect") or e:IsA("DepthOfFieldEffect") then
            e.Enabled = false
        end
    end

    for _, player in pairs(game.Players:GetPlayers()) do
        if player.Character then
            for _, part in pairs(player.Character:GetDescendants()) do
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
                end
            end
        end
    end


    -- ====================================
    -- ระบบวาง + อัพเกรด (เหมือน Path B)
    -- ====================================
    local Players = game:GetService("Players")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local Nodes = require(ReplicatedStorage:WaitForChild("Nodes"))
    local Shared = ReplicatedStorage:WaitForChild("Shared")
    local ReplicaClient = require(Shared:WaitForChild("ReplicaClient"))
    local FusionPackage = ReplicatedStorage:WaitForChild("FusionPackage")
    local FusionShared = require(FusionPackage.Shared)
    local Fusion = require(FusionPackage:WaitForChild("Fusion"))
    local peek = Fusion.peek

    local function getCurrentWave()
        local success, wave = pcall(function()
            local topHUD = Players.LocalPlayer.PlayerGui:FindFirstChild("TopGameHUD")
            if not topHUD then return 0 end
            local waveLabel = topHUD.Frame:GetChildren()[4].Frame.Frame.Frame.Frame.Frame.TextLabel
            local text = waveLabel.ContentText or waveLabel.Text
            return tonumber(string.match(text, "^(%d+)")) or 0
        end)
        return success and wave or 0
    end

    local function placeAndUpgrade()
        local DELAY_AFTER_PLACE = 1
        local AUTO_UPGRADE_PRIORITY = 1

        local function getCurrentMoney()
            local bottomHUD = Players.LocalPlayer.PlayerGui:FindFirstChild("BottomHUD")
            if not bottomHUD then return 0 end
            local moneyLabel = bottomHUD:GetChildren()[2]:GetChildren()[6].Frame.Frame.TextLabel
            local moneyText = moneyLabel.ContentText
            local cleaned = (moneyText:gsub("[^%d]", ""))
            return tonumber(cleaned) or 0
        end

        local function getUnitCost(slot)
            local targetSlot = tonumber(slot)
            if not targetSlot then return 0 end

            while true do
                local success, cost = pcall(function()
                    local bottomHUD = Players.LocalPlayer.PlayerGui:FindFirstChild("BottomHUD")
                    if not bottomHUD then return 0 end
                    local hotbarContainer = bottomHUD:GetChildren()[2]:GetChildren()[5]

                    for _, child in ipairs(hotbarContainer:GetChildren()) do
                        if child:IsA("TextButton") and child.LayoutOrder == targetSlot then
                            local frame = child.Frame
                            if frame then
                                local children = frame:GetChildren()
                                if children[3] and children[3]:IsA("Frame") then
                                    local innerFrame = children[3].Frame
                                    if innerFrame and innerFrame.TextLabel then
                                        local costText = innerFrame.TextLabel.ContentText
                                        local cleaned = (costText:gsub("[^%d]", ""))
                                        return tonumber(cleaned) or 0
                                    end
                                end
                            end
                        end
                    end
                    return 0
                end)

                if success then
                    return cost
                else
                    task.wait(0.5)
                end
            end
        end

        local playerReplica = Nodes.GET_GAME_PLAYER_REPLICA:InvokeSelf()
        if not playerReplica then
            warn("❌ ไม่พบ Player Replica")
            return
        end

        local allPlacedIDs = {}
        local connection = ReplicaClient.OnNew("GameUnit", function(replica)
            local unitID = replica.Data.ID
            if unitID and not table.find(allPlacedIDs, unitID) then
                table.insert(allPlacedIDs, unitID)
            end
        end)

        local function placeUnit(slot, cframe)
            local cost = getUnitCost(slot)
            local startCount = #allPlacedIDs

            while true do
                local money = getCurrentMoney()
                if money >= cost then
                    local success = pcall(function()
                        playerReplica:FireServer("PlaceGameUnit", slot, cframe)
                    end)
                    if success then
                        task.wait(DELAY_AFTER_PLACE)

                        -- รอให้ unit ถูกเพิ่มเข้า allPlacedIDs
                        local waited = 0
                        while #allPlacedIDs <= startCount and waited < 5 do
                            task.wait(0.1)
                            waited = waited + 0.1
                        end

                        return true
                    else
                        return false
                    end
                else
                    task.wait(1)
                end
            end
        end

        -- Phase 1: วาง 2 ตัวแรก (ไม่อัพเกรด)
        local phase1Units = {}
        placeUnit("2", CFrame.new(3089.634765625, 1798.9315185547, 3303.287109375))
        table.insert(phase1Units, allPlacedIDs[#allPlacedIDs])

        placeUnit("2", CFrame.new(3085.5629882812, 1798.9315185547, 3307.3232421875))
        table.insert(phase1Units, allPlacedIDs[#allPlacedIDs])

        -- Phase 2: วาง 2 ตัวถัดไป (ไม่อัพเกรด)
        local phase2Units = {}
        placeUnit("2", CFrame.new(3076.7241210938, 1798.7340087891, 3331.4426269531))
        table.insert(phase2Units, allPlacedIDs[#allPlacedIDs])

        placeUnit("2", CFrame.new(3073.0454101562, 1798.7340087891, 3335.3151855469))
        table.insert(phase2Units, allPlacedIDs[#allPlacedIDs])

        -- Phase 3: รอ 30 วิ แล้วขาย 2 ตัวแรก
        task.wait(30)

        for _, unitID in ipairs(phase1Units) do
            pcall(function()
                playerReplica:FireServer("SellGameUnit", unitID)
            end)
            task.wait(0.5)
        end

        -- Phase 4: วาง 2 ตัวแทนที่ (ไม่อัพเกรด)
        local phase3Units = {}
        placeUnit("2", CFrame.new(3102.9411621094, 1798.7340087891, 3348.0209960938))
        table.insert(phase3Units, allPlacedIDs[#allPlacedIDs])

        placeUnit("2", CFrame.new(3100.6657714844, 1798.7340087891, 3350.0747070312))
        table.insert(phase3Units, allPlacedIDs[#allPlacedIDs])

        -- Phase 5: รอ 15 วิ แล้วขาย 2 ตัว Phase 2
        task.wait(15)

        for _, unitID in ipairs(phase2Units) do
            pcall(function()
                playerReplica:FireServer("SellGameUnit", unitID)
            end)
            task.wait(0.5)
        end

        -- Phase 6: วาง 2 ตัวสุดท้าย
        local phase4Units = {}
        placeUnit("2", CFrame.new(3091.6513671875, 1798.9315185547, 3367.1286621094))
        table.insert(phase4Units, allPlacedIDs[#allPlacedIDs])

        placeUnit("2", CFrame.new(3093.73828125, 1798.9315185547, 3365.0720214844))
        table.insert(phase4Units, allPlacedIDs[#allPlacedIDs])

        -- Phase 7: รอ 10 วิ แล้วขาย 2 ตัว Phase 3 (จุดที่ 5,6)
        task.wait(10)

        for _, unitID in ipairs(phase3Units) do
            pcall(function()
                playerReplica:FireServer("SellGameUnit", unitID)
            end)
            task.wait(0.5)
        end

        -- Phase 8: วาง 2 ตัวใหม่แทนที่และอัพเกรด
        local phase5Units = {}
        placeUnit("2", CFrame.new(3086.2294921875, 1798.9315185547, 3366.8635253906))
        table.insert(phase5Units, allPlacedIDs[#allPlacedIDs])

        placeUnit("2", CFrame.new(3087.6696777344, 1798.9315185547, 3363.1516113281))
        table.insert(phase5Units, allPlacedIDs[#allPlacedIDs])

        task.wait(2)
        connection:Disconnect()

        -- Phase 9: อัพเกรดเฉพาะ Phase 4 + Phase 5 (4 ตัวสุดท้าย)
        local finalUnits = {}
        for _, id in ipairs(phase4Units) do table.insert(finalUnits, id) end
        for _, id in ipairs(phase5Units) do table.insert(finalUnits, id) end

        for _, unitID in ipairs(finalUnits) do
            pcall(function()
                playerReplica:FireServer("ChangeGameUnitAutoUpgradePriority", unitID, AUTO_UPGRADE_PRIORITY)
            end)
            task.wait(0.3)
        end
    end

    -- Anti-AFK Walk Loop (เดินวนในแมพ)
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

    -- Main Loop
    local lastWave = -1

    while true do
        local currentWave = getCurrentWave()

        if currentWave == 0 or (lastWave > 0 and currentWave < lastWave) then
            while getCurrentWave() == 0 do
                task.wait(0.5)
            end
            placeAndUpgrade()
            lastWave = getCurrentWave()
        elseif currentWave > 0 and lastWave == -1 then
            placeAndUpgrade()
            lastWave = currentWave
        else
            lastWave = currentWave
        end

        task.wait(1)
    end
end

-- ========================================
-- 1. RemoveLobbyMesh.lua (Boost FPS)
-- ========================================
printStep("Removing Lobby Mesh...")

local Config = _G.Config

local g = game
local w = g.Workspace
local l = g.Lighting
local t = w.Terrain

-- Disable 3D Rendering
if Config.Disable3DRendering then
    local RunService = game:GetService("RunService")
    RunService:Set3dRenderingEnabled(false)
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

-- เช็ค Map ก่อน (เพราะเมื่ออยู่ในเกมให้ลบ Map ไม่ใช่ Lobby)
local lobbyFolder = workspace:FindFirstChild("Lobby")
local mapFolder = workspace:FindFirstChild("Map")

if mapFolder then
    -- ลบ children ของ Map (เกมจะสร้าง folder ใหม่ถ้าลบทั้งก้อน)
    for _, obj in pairs(mapFolder:GetChildren()) do
        obj:Destroy()
    end

    -- สร้างพื้นล่องหนไว้ที่เท้าผู้เล่น
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
end

for _, obj in pairs(Lighting:GetChildren()) do
    obj:Destroy()
end

local MaterialService = game:GetService("MaterialService")
for _, obj in pairs(MaterialService:GetChildren()) do
    obj:Destroy()
end

for _, obj in pairs(workspace:GetDescendants()) do
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
        obj.Lifetime = NumberRange.new(0)
    elseif obj:IsA("Explosion") then
        obj.BlastPressure = 1
        obj.BlastRadius = 1
    elseif obj:IsA("Fire") or obj:IsA("SpotLight") or obj:IsA("Smoke") then
        obj.Enabled = false
    end
end

for _, e in pairs(Lighting:GetChildren()) do
    if e:IsA("BlurEffect") or e:IsA("SunRaysEffect") or e:IsA("ColorCorrectionEffect") or e:IsA("BloomEffect") or e:IsA("DepthOfFieldEffect") then
        e.Enabled = false
    end
end

for _, player in pairs(game.Players:GetPlayers()) do
    if player.Character then
        for _, part in pairs(player.Character:GetDescendants()) do
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
                part.Lifetime = NumberRange.new(0)
            elseif part:IsA("Fire") or part:IsA("SpotLight") or part:IsA("Smoke") then
                part.Enabled = false
            end
        end
    end
end

local player = game.Players.LocalPlayer
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
    floor.Parent = workspace.Lobby
end

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

for _, rarity in ipairs({"Rare", "Epic"}) do
    pcall(function()
        Actions.ToggleAutoSell("Standard", rarity, false, true)
    end)
    task.wait(0.3)
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

-- รอให้ Prompt โหลด
task.wait(2)

local playerGui = Players.LocalPlayer.PlayerGui
if playerGui:FindFirstChild("Prompt") then
    local folder = playerGui.Prompt.Frame.Frame.Frame.Folder.Frame.Frame

    -- หาปุ่มที่มีชื่อ Carrot
    for _, child in pairs(folder:GetChildren()) do
        if child:FindFirstChild("Folder") then
            local textLabel = child.Folder.Frame.Frame:FindFirstChild("TextLabel")
            if textLabel and (textLabel.ContentText == TARGET_UNIT or textLabel.Text == TARGET_UNIT) then
                -- กดปุ่มเลือกตัวละคร
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

                    -- กดปุ่มยืนยัน
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

                        -- กดมุมขวาล่างเพื่อปิด popup
                        local camera = workspace.CurrentCamera
                        local screenSize = camera.ViewportSize
                        VirtualInputManager:SendMouseButtonEvent(screenSize.X - 10, screenSize.Y - 10, 0, true, game, 0)
                        task.wait(0.1)
                        VirtualInputManager:SendMouseButtonEvent(screenSize.X - 10, screenSize.Y - 10, 0, false, game, 0)

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
local DELAY_BETWEEN_CLAIMS = 0.5


for day = START_DAY, END_DAY do
    pcall(function()
        Nodes.CLAIM_CALENDAR:FireServer("ReleaseCalendar", day)
    end)
    task.wait(DELAY_BETWEEN_CLAIMS)

    -- กดมุมขวาล่างเพื่อปิด popup (ถ้ารับได้ 1 อัน/วัน)
    local VirtualInputManager = game:GetService("VirtualInputManager")
    local camera = workspace.CurrentCamera
    local screenSize = camera.ViewportSize

    VirtualInputManager:SendMouseButtonEvent(screenSize.X - 10, screenSize.Y - 10, 0, true, game, 0)
    task.wait(0.1)
    VirtualInputManager:SendMouseButtonEvent(screenSize.X - 10, screenSize.Y - 10, 0, false, game, 0)
    task.wait(0.3)
end


for day = START_DAY, END_DAY do
    pcall(function()
        Nodes.CLAIM_CALENDAR:FireServer("DailyRewards", day)
    end)
    task.wait(DELAY_BETWEEN_CLAIMS)

    -- กดมุมซ้ายบนเพื่อปิด popup
    local VirtualInputManager = game:GetService("VirtualInputManager")

    VirtualInputManager:SendMouseButtonEvent(10, 10, 0, true, game, 0)
    task.wait(0.1)
    VirtualInputManager:SendMouseButtonEvent(10, 10, 0, false, game, 0)
    task.wait(0.3)
end

task.wait(1)

-- ========================================
-- 4.5. Redeem Codes
-- ========================================
printStep("Redeeming Codes...")

do
    local CODES = {
        "sorryforguilds",
        "SorryForRestart",
        "200KCCU",
        "100K!",
        "30KLIKES!",
        "EXPEDITIONS",
        "SorryForBugs",
        "AE#1",
        "Release",
    }

    local function redeemCode(code)
        local success, result = pcall(function()
            local request = Nodes.CLAIM_CODE:Request(code)
            request:Timeout(5)
            return request:Wait()
        end)

        if success then
            if result and result.Success then

                -- กดมุมซ้ายบนเพื่อปิด popup
                local VirtualInputManager = game:GetService("VirtualInputManager")
                task.wait(0.2)
                VirtualInputManager:SendMouseButtonEvent(10, 10, 0, true, game, 0)
                task.wait(0.1)
                VirtualInputManager:SendMouseButtonEvent(10, 10, 0, false, game, 0)
                task.wait(0.2)

                return true
            else
                warn(string.format("❌ Failed: %s - %s", code, result and result.Message or "Already claimed or invalid"))
                return false
            end
        else
            warn(string.format("❌ Error: %s - %s", code, tostring(result)))
            return false
        end
    end

    local successCount = 0
    local failCount = 0

    for i, code in ipairs(CODES) do
        if redeemCode(code) then
            successCount = successCount + 1
        else
            failCount = failCount + 1
        end
        task.wait(0.5)
    end

end
task.wait(1)

-- ========================================
-- 5. เช็คตัวละครที่มีอยู่
-- ========================================
printStep("Checking Inventory...")

local function openInventory()
    local GuiService = game:GetService("GuiService")
    local VirtualInputManager = game:GetService("VirtualInputManager")
    local button = game:GetService("Players").LocalPlayer.PlayerGui.LeftHUD.Frame.Frame.Frame:GetChildren()[5]

    button.Selectable = true
    GuiService.SelectedCoreObject = button

    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Return, false, game)

    task.wait(0.1)
    GuiService.SelectedCoreObject = nil
end

local function checkForTargetUnits()
    local targetUnits = {
        "Ice Queen",
        "Greed",
        "Forbidden Teacher",
        "Scissor",
        "Water Princess",
        "The Hero"
    }

    local playerGui = game:GetService("Players").LocalPlayer.PlayerGui

    -- รอให้ Inventory โหลด
    task.wait(2)

    if not playerGui:FindFirstChild("UnitInventory") then
        return false
    end

    -- รอให้ UI โหลดเสร็จและลองหลายครั้ง
    local scrollFrame = nil
    local maxChildren = 0

    for attempt = 1, 5 do
        task.wait(1)

        -- หา ScrollingFrame ที่มี children มากที่สุด (น่าจะเป็น Grid ตัวละคร)
        for _, desc in pairs(playerGui.UnitInventory:GetDescendants()) do
            if desc:IsA("ScrollingFrame") then
                local childCount = #desc:GetChildren()

                -- เลือก ScrollingFrame ที่มี children มากกว่า 10 และมากที่สุด
                if childCount > 10 and childCount > maxChildren then
                    scrollFrame = desc
                    maxChildren = childCount
                end
            end
        end

        if scrollFrame then
            break
        end
    end

    if not scrollFrame then
        return false
    end

    -- วน loop ทุก item ใน ScrollingFrame
    for _, item in pairs(scrollFrame:GetChildren()) do
        -- หาทุก TextLabel ใน item นี้
        for _, desc in pairs(item:GetDescendants()) do
            if desc:IsA("TextLabel") then
                local unitName = desc.ContentText or desc.Text or ""

                -- กรองเฉพาะชื่อตัวละคร (ไม่ใช่ Lvl หรือ ¥)
                if unitName ~= ""
                    and not string.match(unitName, "^Lvl")
                    and not string.match(unitName, "^¥%d+") then

                    -- เช็คว่าตรงกับตัวที่ต้องการไหม
                    for _, targetUnit in pairs(targetUnits) do
                        if string.find(unitName, targetUnit) then
                            return true
                        end
                    end
                end
            end
        end
    end

    return false
end

-- เปิด Inventory
openInventory()

-- เช็คตัวละคร
local hasTargetUnit = checkForTargetUnits()

-- ========================================
-- 6. AutoSummon (ถ้าไม่มีตัวที่ต้องการ)
-- ========================================
if not hasTargetUnit then
    printStep("Auto Summon...")

    local BANNER_ID = "Standard"
    local AMOUNT_PER_SUMMON = 50
    local TOTAL_ROUNDS = 1
    local DELAY = 2

    for i = 1, TOTAL_ROUNDS do

        pcall(function()
            Nodes.BANNER_SUMMON:FireServer(BANNER_ID, AMOUNT_PER_SUMMON)
        end)

        task.wait(DELAY)

        -- กดมุมซ้ายบนเพื่อปิด popup หลัง summon
        VirtualInputManager:SendMouseButtonEvent(10, 10, 0, true, game, 0)
        task.wait(0.1)
        VirtualInputManager:SendMouseButtonEvent(10, 10, 0, false, game, 0)
        task.wait(0.5)
    end

    task.wait(2)

    -- เช็คใหม่อีกครั้ง
    
    openInventory()
    hasTargetUnit = checkForTargetUnits()
else
end

-- ========================================
-- 7. QuickEquip (ถ้ามีตัวที่ต้องการ)
-- ========================================
if hasTargetUnit then
    printStep("Quick Equip...")

    -- ปิด Inventory ก่อน
    local VirtualInputManager = game:GetService("VirtualInputManager")
    VirtualInputManager:SendMouseButtonEvent(10, 10, 0, true, game, 0)
    task.wait(0.1)
    VirtualInputManager:SendMouseButtonEvent(10, 10, 0, false, game, 0)
    task.wait(0.5)

    -- Get UnitData และ UnitInfo
    local unitData = Nodes.GET_DATA_VALUE:InvokeSelf("UnitData")
    local UnitInfo = require(ReplicatedStorage.Shared.Information.Units)

    -- สร้าง displayNameMap
    local displayNameMap = {}
    for fullKey, data in pairs(unitData) do
        local internalName = fullKey:match("^(.+)#") or fullKey
        local displayName = UnitInfo[internalName] and UnitInfo[internalName].DisplayName or internalName
        displayNameMap[displayName:lower()] = fullKey
    end

    -- หา target unit ที่มีอยู่
    local targetUnits = {
        "Ice Queen",
        "Greed",
        "Forbidden Teacher",
        "Scissor",
        "Water Princess",
        "The Hero"
    }

    local foundTargetUnit = nil
    for _, targetUnit in pairs(targetUnits) do
        if displayNameMap[targetUnit:lower()] then
            foundTargetUnit = targetUnit
            break
        end
    end

    -- Unequip All ก่อน
    Nodes.UNIT_UNEQUIP_ALL:FireServer("Unit")
    task.wait(0.5)

    -- Equip Carrot ช่อง 1
    local carrotFullKey = displayNameMap["carrot"]
    if carrotFullKey then
        Nodes.UNIT_EQUIP:FireServer(carrotFullKey, "1")
        task.wait(0.3)
    else
        warn("❌ Carrot not found in inventory")
    end

    -- Equip target unit ช่อง 2
    if foundTargetUnit then
        local targetFullKey = displayNameMap[foundTargetUnit:lower()]
        if targetFullKey then
            Nodes.UNIT_EQUIP:FireServer(targetFullKey, "2")
            task.wait(0.3)
        end
    else
        warn("❌ No target unit to equip in slot 2")
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

else
end

