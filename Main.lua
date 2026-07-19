repeat wait() until game:IsLoaded()
-- ========================================
-- Main Script - รวมทุกฟังก์ชันตามลำดับ
-- ========================================

-- ========================================
-- CONFIG (รองรับ External Config)
-- ========================================
_G.Config = _G.Config or {}
local HORST_ENABLED = _G.Config.Horst == true
local GEM_TARGET = _G.Config.GemTarget  -- nil = ไม่ส่ง DONE
local UPDATE_INTERVAL = 30

-- ========================================
-- -1. Load Horst API (ถ้า Config เปิด)
-- ========================================
if HORST_ENABLED then
    print("Step -1: Loading Horst API...")
    local success, err = pcall(function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/HorstSpaceX/last_update/main/on_loaded.lua"))()
    end)

    if success then
        print("✅ Step -1 Complete: Horst API loaded!")
        if GEM_TARGET then
            print("🎯 Gem Target:", GEM_TARGET)
        else
            print("📡 Status Update Only Mode (No DONE signal)")
        end
    else
        warn("❌ Failed to load Horst API:", err)
        HORST_ENABLED = false
    end
    task.wait(1)
end

-- ========================================
-- 0. StatsGUI (โหลดก่อนอันแรก)
-- ========================================
print("Step 0: Loading Stats GUI...")
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
    mainFrame.Size = UDim2.new(0.75, 0, 0.6, 0)
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
            if not replica then return end

            local data = replica.Data
            local itemData = data.ItemData
            if not itemData then return end

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
                _G.Horst_SetDescription(message, encoded_json)
                print("📡 Horst Status Update:", message)

                -- เช็คเป้าหมาย Gem (ถ้ามี GEM_TARGET)
                if GEM_TARGET and gem >= GEM_TARGET and not doneSent then
                    print(string.format("🎯 Gem Target Reached! (%s/%s)", formatNumber(gem), formatNumber(GEM_TARGET)))

                    local ok, doneErr = _G.Horst_AccountChangeDone()
                    if ok then
                        print("✅ Horst: Account change DONE sent successfully!")
                        doneSent = true
                    else
                        warn("❌ Horst: Failed to send DONE:", doneErr)
                    end
                end
            end)

            if not success then
                warn("❌ Horst Status Update Error:", err)
            end
        end

        -- ส่งรอบแรกทันที
        task.wait(1)  -- รอให้ข้อมูล replica พร้อม
        sendHorstStatus()

        -- วนลูปส่งทุก 30 วิ
        spawn(function()
            while true do
                task.wait(UPDATE_INTERVAL)
                sendHorstStatus()
            end
        end)

        print("✅ Horst Status Reporter started (Update every", UPDATE_INTERVAL, "seconds)")
    end
end
print("✅ Step 0 Complete: Stats GUI loaded!")
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
    print("Monitoring Wave counter for reset...")
    local playerGui = game:GetService("Players").LocalPlayer.PlayerGui
    local topHUD = playerGui:FindFirstChild("TopGameHUD")
    if not topHUD then
        print("⚠️ TopGameHUD not found")
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
            print(string.format("Wave: %d/%d", currentWave, 15))
        elseif currentWave < maxWave and currentWave == 0 then
            print("✅ Wave reset detected! Starting new cycle...")
            return
        end

        task.wait(1)
    end
end

-- เช็คว่าอยู่ในแมพหรือไม่
if isInTargetMap() then
    print("========================================")
    print("✅ Already in School Grounds - Act 1!")
    print("Skipping setup steps, monitoring Wave...")
    print("========================================")

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

                        print("✅ Tutorial popup closed")
                        return
                    end
                end
            end
        end)
        if not success then
            print("ℹ️ No Tutorial popup found")
        end
    end

    closeTutorial()
    task.wait(0.5)

    -- รัน RemoveLobbyMesh เท่านั้น
    print("Running RemoveLobbyMesh...")
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
        print("  ลบ workspace.Map children...")
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
            print("  ✅ สร้างพื้นล่องหนแล้ว")
        end
    elseif lobbyFolder then
        print("  ลบ workspace.Lobby children...")
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

    print("✅ RemoveLobbyMesh Complete!")

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
        local PLACEMENTS = {
            {slot = "2", cframe = CFrame.new(3102.2963867188, 1798.9315185547, 3265.6330566406)},
            {slot = "2", cframe = CFrame.new(3099.0529785156, 1798.9315185547, 3265.447265625)},
            {slot = "2", cframe = CFrame.new(3102.6994628906, 1798.7340087891, 3269.0915527344)},
            {slot = "2", cframe = CFrame.new(3099.4106445312, 1798.7340087891, 3268.8071289062)},
        }

        local AUTO_UPGRADE_PRIORITY = 1
        local DELAY_AFTER_PLACE = 1
        local DELAY_AFTER_UPGRADE = 0.3

        local function getCurrentMoney()
            local bottomHUD = Players.LocalPlayer.PlayerGui:FindFirstChild("BottomHUD")
            if not bottomHUD then return 0 end
            local moneyLabel = bottomHUD:GetChildren()[2]:GetChildren()[6].Frame.Frame.TextLabel
            local moneyText = moneyLabel.ContentText
            local cleaned = (moneyText:gsub("[^%d]", ""))
            return tonumber(cleaned) or 0
        end

        local function getUnitCost(slot)
            local bottomHUD = Players.LocalPlayer.PlayerGui:FindFirstChild("BottomHUD")
            if not bottomHUD then return 0 end
            local hotbarContainer = bottomHUD:GetChildren()[2]:GetChildren()[5]
            local targetSlot = tonumber(slot)

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
        end

        local playerReplica = Nodes.GET_GAME_PLAYER_REPLICA:InvokeSelf()
        if not playerReplica then
            warn("❌ ไม่พบ Player Replica")
            return
        end

        local placedIDs = {}
        local connection = ReplicaClient.OnNew("GameUnit", function(replica)
            local unitID = replica.Data.ID
            if unitID and not table.find(placedIDs, unitID) then
                table.insert(placedIDs, unitID)
            end
        end)

        print("🎯 เริ่มวาง units...")
        for i, placement in ipairs(PLACEMENTS) do
            local cost = getUnitCost(placement.slot)

            while true do
                local money = getCurrentMoney()
                if money >= cost then
                    local success = pcall(function()
                        playerReplica:FireServer("PlaceGameUnit", placement.slot, placement.cframe)
                    end)
                    if success then
                        task.wait(DELAY_AFTER_PLACE)
                        break
                    else
                        warn("❌ วางไม่สำเร็จ")
                        connection:Disconnect()
                        return
                    end
                else
                    task.wait(1)
                end
            end
        end

        task.wait(2)
        connection:Disconnect()

        if #placedIDs > 0 then
            print("⚡ เปิด Auto Upgrade...")
            for _, unitID in ipairs(placedIDs) do
                pcall(function()
                    playerReplica:FireServer("ChangeGameUnitAutoUpgradePriority", unitID, AUTO_UPGRADE_PRIORITY)
                end)
                task.wait(DELAY_AFTER_UPGRADE)
            end
            print(string.format("✅ วาง + อัพเกรดสำเร็จ %d units", #placedIDs))
        else
            warn("⚠️ ไม่มี units ที่วางสำเร็จ")
        end
    end

    -- Main Loop
    print("🔄 เริ่ม Auto Loop...")
    local lastWave = -1

    while true do
        local currentWave = getCurrentWave()

        if currentWave == 0 or (lastWave > 0 and currentWave < lastWave) then
            print("🔄 Wave reset - รอ Wave > 0...")
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
print("Step 1: Running RemoveLobbyMesh...")

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

print("✅ Step 1 Complete: Boost FPS Success!")
task.wait(1)

-- ========================================
-- 2. Settings.lua
-- ========================================
print("Step 2: Applying Settings...")

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

print("✅ Step 2 Complete: Applied All Settings!")
task.wait(1)

print("✅ Step 2 Complete: Applied All Settings!")
task.wait(1)

-- ========================================
-- 3. AutoClaimStarter.lua
-- ========================================
print("Step 3: Claiming Starter Unit...")

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
                print(string.format("Found %s, selecting...", TARGET_UNIT))

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

                        print(string.format("✅ Successfully claimed %s!", TARGET_UNIT))
                    end
                end
                break
            end
        end
    end
else
    print("⚠️ Prompt not found!")
end

print("✅ Step 3 Complete: Claimed Starter Unit!")
task.wait(1)

-- ========================================
-- 4. AutoClaimCalendar.lua
-- ========================================
print("Step 4: Claiming Calendar Rewards...")

local START_DAY = 1
local END_DAY = 7
local DELAY_BETWEEN_CLAIMS = 0.5

print("Claiming ReleaseCalendar rewards...")
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

print("Claiming DailyRewards...")
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

print("✅ Step 4 Complete: Claimed All Calendar Rewards!")
task.wait(1)

-- ========================================
-- 5. เช็คตัวละครที่มีอยู่
-- ========================================
print("Step 5: Checking Inventory...")

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
        print("⚠️ Inventory not found!")
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
        print("⚠️ ScrollingFrame not found!")
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
                            print(string.format("✅ Found Target Unit: %s", unitName))
                            return true
                        end
                    end
                end
            end
        end
    end

    print("❌ No target units found in inventory")
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
    print("Step 6: No target units found. Starting summon...")

    local BANNER_ID = "Standard"
    local AMOUNT_PER_SUMMON = 50
    local TOTAL_ROUNDS = 1
    local DELAY = 2

    for i = 1, TOTAL_ROUNDS do
        print(string.format("🎲 Summon Round %d/%d", i, TOTAL_ROUNDS))

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

    print("✅ Step 6 Complete: Summon finished!")
    task.wait(2)

    -- เช็คใหม่อีกครั้ง
    print("Checking inventory again...")
    openInventory()
    hasTargetUnit = checkForTargetUnits()
else
    print("✅ Target unit already exists, skipping summon.")
end

-- ========================================
-- 7. QuickEquip (ถ้ามีตัวที่ต้องการ)
-- ========================================
if hasTargetUnit then
    print("Step 7: Equipping units to hotbar...")

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
            print(string.format("✅ Found target unit: %s", foundTargetUnit))
            break
        end
    end

    -- Unequip All ก่อน
    print("\n🔄 Unequipping all units first...")
    Nodes.UNIT_UNEQUIP_ALL:FireServer("Unit")
    task.wait(0.5)
    print("✅ Unequipped all\n")

    -- Equip Carrot ช่อง 1
    local carrotFullKey = displayNameMap["carrot"]
    if carrotFullKey then
        print("Equipping Carrot → Slot 1")
        Nodes.UNIT_EQUIP:FireServer(carrotFullKey, "1")
        print("✅ Done")
        task.wait(0.3)
    else
        warn("❌ Carrot not found in inventory")
    end

    -- Equip target unit ช่อง 2
    if foundTargetUnit then
        local targetFullKey = displayNameMap[foundTargetUnit:lower()]
        if targetFullKey then
            print(string.format("Equipping %s → Slot 2", foundTargetUnit))
            Nodes.UNIT_EQUIP:FireServer(targetFullKey, "2")
            print("✅ Done")
            task.wait(0.3)
        end
    else
        warn("❌ No target unit to equip in slot 2")
    end

    print("\n✨ Equip Complete!")
    task.wait(1)

    -- ========================================
    -- 8. auto_start_game.lua
    -- ========================================
    print("Step 8: Starting game...")

    local CONFIG = {
        MapName = "SchoolGrounds",
        ActName = "Act 1",
        Difficulty = "Hard",
        Gamemode = "Story"
    }

    local FusionPackage = ReplicatedStorage:WaitForChild("FusionPackage")
    local Actions = require(FusionPackage.Actions)
    Actions.PartyStartGame(CONFIG)

    print("✅ Step 8 Complete: Game started!")

else
    print("⚠️ No target unit found after summon. Skipping equip and game start.")
end

print("========================================")
print("✅ All Steps Complete!")
print("========================================")
