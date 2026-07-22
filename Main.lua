repeat wait() until game:IsLoaded()
-- 4.18
-- ========================================
-- Main Script - รวมทุกฟังก์ชันตามลำดับ
-- ========================================

-- ========================================
-- 0. Check PlayerGui (ต้องโหลดก่อนทุกอย่าง)
-- ========================================
do
    local Players = game:GetService("Players")

    local MINIMUM_GUI_COUNT = 50  -- จำนวน GUI ขั้นต่ำที่ต้องมี
    local MAX_WAIT_TIME = 30  -- รอสูงสุด 30 วินาที
    local CHECK_INTERVAL = 1  -- เช็คทุก 1 วินาที

    local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui", 10)

    if not playerGui then
        warn("❌ PlayerGui not found - Kicking...")
        Players.LocalPlayer:Kick("PlayerGui failed to load. Please rejoin.")
        return
    end

    -- รอจนกว่า GUI จะโหลดครบ หรือครบเวลา 30 วิ
    local elapsedTime = 0

    while elapsedTime < MAX_WAIT_TIME do
        local guiCount = #playerGui:GetChildren()

        if guiCount >= MINIMUM_GUI_COUNT then
            break  -- โหลดสำเร็จ ให้รันสคริปต่อได้
        end

        task.wait(CHECK_INTERVAL)
        elapsedTime = elapsedTime + CHECK_INTERVAL
    end

    -- ถ้าครบ 30 วิแล้วยังโหลดไม่ครบ
    local finalCount = #playerGui:GetChildren()
    if finalCount < MINIMUM_GUI_COUNT then
        warn(string.format("❌ PlayerGui incomplete after %ds (%d/%d) - Kicking...", MAX_WAIT_TIME, finalCount, MINIMUM_GUI_COUNT))
        Players.LocalPlayer:Kick(string.format("PlayerGui failed to load properly (%d/%d). Please rejoin.", finalCount, MINIMUM_GUI_COUNT))
        return
    end
end

-- ========================================
-- Anti-AFK (โหลดก่อนอันแรก)
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
        -- รอ random 30-60 วินาที
        task.wait(math.random(30, 60))

        pcall(function()
            local screenSize = camera.ViewportSize

            -- สุ่มมุมจอ
            local edges = {
                {x = 10, y = 10},                              -- มุมซ้ายบน
                {x = screenSize.X - 10, y = 10},              -- มุมขวาบน
                {x = 10, y = screenSize.Y - 10},              -- มุมซ้ายล่าง
                {x = screenSize.X - 10, y = screenSize.Y - 10}, -- มุมขวาล่าง
                {x = screenSize.X / 2, y = 10},               -- กลางบน
                {x = screenSize.X / 2, y = screenSize.Y - 10}, -- กลางล่าง
            }

            -- สุ่มเลือกมุม
            local edge = edges[math.random(1, #edges)]

            -- คลิก
            VirtualInputManager:SendMouseButtonEvent(edge.x, edge.y, 0, true, game, 0)
            task.wait(0.05)
            VirtualInputManager:SendMouseButtonEvent(edge.x, edge.y, 0, false, game, 0)
        end)
    end
end)

-- ========================================
-- CONFIG (รองรับ External Config)
-- ========================================
_G.Config = _G.Config or {}
local HORST_ENABLED = _G.Config.Horst == true
local GEM_TARGET = _G.Config.GemTarget  -- nil = ไม่ส่ง DONE
local UPDATE_INTERVAL = 30
local TOGGLE_RENDER3D = _G.Config.ToggleRender3D == true  -- ผูก Render3D กับ GUI toggle

-- Summon Config
local SUMMON_CONFIG = _G.Config.SummonUnits or {}  -- เช่น {"Elf Mage", "Shadow"}
local MYTHIC_UNITS = {"Cursed Student", "Elf Mage", "Flame Emperor", "Hollow", "Lady Giant", "Puppet", "Salmon Sorcerer", "String Demon"}
local SECRET_UNITS = {"Shadow"}
local hasSummonConfig = SUMMON_CONFIG and #SUMMON_CONFIG > 0

local function printStep(stepName)
    print(string.format("🔄 %s", stepName))
end

-- ฟังก์ชันเช็ค Banner ณ ตอนนี้ (Global scope)
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
-- -1. Load Horst API (ถ้า Config เปิด)
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

    -- Update แบบ Real-time (ตรวจจับการเปลี่ยนแปลง + Error Handling)
    task.wait(2)
    updateStats()

    -- เก็บค่าเก่าเพื่อเปรียบเทียบ
    local lastGem = 0
    local lastGold = 0
    local lastTrait = 0
    local errorCount = 0
    local maxErrors = 5
    local checkCounter = 0

    -- Initialize ค่าเริ่มต้น
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

    -- เช็คทุก 0.5 วินาทีแทนทุกเฟรม (ลด CPU usage)
    spawn(function()
        while true do
            task.wait(0.5)  -- เช็คทุก 0.5 วินาที (ประหยัดสเปค)

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

                -- ดึงค่าปัจจุบัน
                local currentGem = itemData.Gem and type(itemData.Gem) == "table" and itemData.Gem.Amount or 0
                local currentGold = itemData.Gold and type(itemData.Gold) == "table" and itemData.Gold.Amount or 0
                local currentTrait = itemData.TraitReroll and type(itemData.TraitReroll) == "table" and itemData.TraitReroll.Amount or 0

                -- เช็คว่าค่าเปลี่ยนหรือไม่
                if currentGem ~= lastGem or currentGold ~= lastGold or currentTrait ~= lastTrait then
                    -- อัพเดททันที
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

                    -- Reset error count เมื่ออัพเดทสำเร็จ
                    errorCount = 0
                end
            end)

            -- Error Handling - ลอง retry
            if not success then
                errorCount = errorCount + 1

                if errorCount <= maxErrors then
                    warn(string.format("⚠️ StatsGUI error (%d/%d): %s - Retrying...", errorCount, maxErrors, tostring(err)))

                    -- พยายาม force update
                    task.spawn(function()
                        task.wait(0.5)
                        pcall(updateStats)
                    end)
                elseif errorCount == maxErrors + 1 then
                    warn(string.format("❌ StatsGUI failed after %d attempts - Will keep trying silently", maxErrors))
                end
            end
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
    -- Horst Status Reporter (Real-time + Error Handling + ส่งทุก 30 วิ)
    -- ========================================
    if HORST_ENABLED then
        local doneSent = false
        local lastHorstGem = 0
        local lastHorstGold = 0
        local lastHorstTrait = 0
        local lastHorstLevel = 0
        local horstErrorCount = 0
        local maxHorstErrors = 5

        -- ฟังก์ชันส่ง Status (พร้อม Error Handling)
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

                -- ดึงข้อมูล Stats
                local level = data.Level or 0
                local gem = itemData.Gem and type(itemData.Gem) == "table" and itemData.Gem.Amount or 0
                local gold = itemData.Gold and type(itemData.Gold) == "table" and itemData.Gold.Amount or 0
                local trait = itemData.TraitReroll and type(itemData.TraitReroll) == "table" and itemData.TraitReroll.Amount or 0

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
                    horstErrorCount = 0  -- Reset error count เมื่อส่งสำเร็จ
                end

                -- เช็คเป้าหมาย Gem (ถ้ามี GEM_TARGET)
                if GEM_TARGET and gem >= GEM_TARGET and not doneSent then
                    if _G.Horst_AccountChangeDone then
                        local ok, doneErr = pcall(_G.Horst_AccountChangeDone)
                        if ok then
                            doneSent = true
                        else
                            warn(string.format("❌ Failed to send DONE: %s", tostring(doneErr)))
                        end
                    else
                        warn("❌ Horst_AccountChangeDone function not found")
                    end
                end
            end)

            if not success then
                horstErrorCount = horstErrorCount + 1
                if horstErrorCount <= maxHorstErrors then
                    warn(string.format("⚠️ Horst error (%d/%d): %s - Retrying...", horstErrorCount, maxHorstErrors, tostring(err)))
                elseif horstErrorCount == maxHorstErrors + 1 then
                    warn(string.format("❌ Horst failed after %d attempts - Will keep trying silently", maxHorstErrors))
                end
            end
        end

        -- Initialize ค่าเริ่มต้น
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

        -- ส่งรอบแรกทันที
        sendHorstStatus()

        -- Real-time update (เช็คทุก 1 วินาที แทน 0.3 วิ - ประหยัดสเปค)
        spawn(function()
            while HORST_ENABLED do
                task.wait(1)  -- เช็คทุก 1 วินาที (ประหยัดสเปค)

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

                    -- เช็คว่าค่าเปลี่ยนหรือไม่
                    if currentLevel ~= lastHorstLevel or currentGem ~= lastHorstGem or
                       currentGold ~= lastHorstGold or currentTrait ~= lastHorstTrait then

                        -- ส่ง update ทันที
                        sendHorstStatus()

                        -- บันทึกค่าใหม่
                        lastHorstLevel = currentLevel
                        lastHorstGem = currentGem
                        lastHorstGold = currentGold
                        lastHorstTrait = currentTrait
                    end
                end)

                if not success then
                    -- Silent retry - ไม่ warn เพราะจะลองใหม่ใน 1 วิ
                end
            end
        end)

        -- Fallback: ส่งทุก 30 วิ (กรณี real-time พลาด)
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

-- เช็คและรอ Wave รีเซ็ต
-- ========================================
-- ฟังก์ชัน RemoveLobbyMesh (ใช้ร่วมกันระหว่าง In-Game และ Lobby)
-- ========================================
local function applyPerformanceOptimizations()
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

        -- สร้างพื้นล่องหนสำหรับ Lobby
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
            pcall(function()
                obj.Lifetime = NumberRange.new(0, 0)
            end)
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
                    pcall(function()
                        part.Lifetime = NumberRange.new(0, 0)
                    end)
                elseif part:IsA("Fire") or part:IsA("SpotLight") or part:IsA("Smoke") then
                    part.Enabled = false
                end
            end
        end
    end
end

-- ตอนนี้อยู่ในแมพหรือไม่
if isInTargetMap() then
    spawn(function()
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

    -- ใช้ฟังก์ชัน Performance Optimization
    applyPerformanceOptimizations()


    -- ====================================
    -- ระบบวาง + อัพเกรด (เหมือน Path B)
    -- ====================================
    local Players = game:GetService("Players")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local Nodes = require(ReplicatedStorage:WaitForChild("Nodes"))
    local Shared = ReplicatedStorage:WaitForChild("Shared")
    local ReplicaClient = require(Shared:WaitForChild("ReplicaClient"))

    -- ตัวแปรสำหรับเก็บ Connection และ State
    local currentConnection = nil
    local allPlacedIDs = {}

    local function getCurrentWave()
        -- Method 1: อ่านจาก Game Replica (ถูกต้อง - ยืนยันจาก CheckWave.lua)
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

        -- Method 2: Fallback - อ่านจาก GUI (พร้อม timeout)
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
            warn("⚠️ Wave detection fallback to GUI (Game Replica failed)")
            return wave2
        end

        warn("⚠️ Wave detection failed - both Replica and GUI methods failed, returning 0")
        return 0
    end

    local function resetFarmingState()
        print("🔄 [resetFarmingState] Resetting state...")
        -- Disconnect connection เก่า (ถ้ามี)
        if currentConnection then
            pcall(function()
                currentConnection:Disconnect()
                print("   ✅ [resetFarmingState] Disconnected old connection")
            end)
            currentConnection = nil
        end

        -- ล้างข้อมูล Unit เก่า
        local oldCount = #allPlacedIDs
        allPlacedIDs = {}
        print(string.format("   🗑️ [resetFarmingState] Cleared %d old unit IDs", oldCount))
    end

    local function placeAndUpgrade()
        print("═══════════════════════════════════════")
        print("🎮 [placeAndUpgrade] Starting new phase")
        print("═══════════════════════════════════════")

        local DELAY_AFTER_PLACE = 1
        local AUTO_UPGRADE_PRIORITY = 1

        local function getCurrentMoney()
            -- Method 1: อ่านจาก Replica (เชื่อถือได้กว่า)
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
                warn("⚠️ [getCurrentMoney] Replica method failed, using GUI fallback")
            end

            -- Method 2: Fallback อ่านจาก GUI
            local success2, money2 = pcall(function()
                local bottomHUD = Players.LocalPlayer.PlayerGui:FindFirstChild("BottomHUD")
                if not bottomHUD then return 0 end
                local moneyLabel = bottomHUD:GetChildren()[2]:GetChildren()[6].Frame.Frame.TextLabel
                local moneyText = moneyLabel.ContentText
                local cleaned = (moneyText:gsub("[^%d]", ""))
                return tonumber(cleaned) or 0
            end)

            if not success2 or not money2 or money2 == 0 then
                warn("❌ [getCurrentMoney] Both Replica and GUI methods failed")
            end
            return success2 and money2 or 0
        end

        local function getUnitCost(slot)
            local targetSlot = tonumber(slot)
            if not targetSlot then
                warn(string.format("❌ [getUnitCost] Invalid slot: %s", tostring(slot)))
                return 999999
            end

            local attempts = 0
            while attempts < 10 do  -- สูงสุด 10 ครั้ง (5 วินาที)
                local success, result, errorMsg = pcall(function()
                    local bottomHUD = Players.LocalPlayer.PlayerGui:FindFirstChild("BottomHUD")
                    if not bottomHUD then return nil, "BottomHUD not found" end

                    -- ใช้ pcall สำหรับ GetChildren เพื่อความปลอดภัย
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
                            -- ใช้ FindFirstChild แทน direct access
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
                    -- pcall สำเร็จแต่ไม่เจอราคา
                    if attempts == 0 then
                        warn(string.format("⚠️ [getUnitCost] Slot %s error: %s (attempt %d/10)", slot, tostring(errorMsg), attempts + 1))
                    end
                else
                    -- pcall ล้มเหลว
                    if attempts == 0 then
                        warn(string.format("⚠️ [getUnitCost] Slot %s pcall failed: %s (attempt %d/10)", slot, tostring(result), attempts + 1))
                    end
                end

                attempts = attempts + 1
                task.wait(0.5)
            end

            warn(string.format("⚠️ [getUnitCost] Failed to detect cost for slot %s after 10 attempts", slot))
            return 999999
        end

        print("🔍 [placeAndUpgrade] Getting Player Replica...")

        print("🔍 [placeAndUpgrade] Getting Player Replica...")
        local playerReplica = nil
        for i = 1, 5 do
            playerReplica = Nodes.GET_GAME_PLAYER_REPLICA:InvokeSelf()
            if playerReplica then
                print(string.format("✅ [placeAndUpgrade] Player Replica found (attempt %d/5)", i))
                break
            end
            warn(string.format("⚠️ [placeAndUpgrade] PlayerReplica not found - retry %d/5", i))
            task.wait(1)
        end

        if not playerReplica then
            warn("❌ [placeAndUpgrade] ไม่พบ Player Replica - aborting phase")
            return false
        end

        -- รีเซ็ต state ก่อนเริ่ม Phase ใหม่
        print("🔄 [placeAndUpgrade] Resetting farming state...")
        resetFarmingState()

        -- ดึง units ที่มีอยู่แล้วก่อนสร้าง connection
        print("📋 [placeAndUpgrade] Loading existing units...")
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
                    print(string.format("   📊 [placeAndUpgrade] Loaded %d existing units", existingCount))
                end
            end
        end)

        -- สร้าง Connection ใหม่
        print("🔗 [placeAndUpgrade] Creating unit tracker connection...")
        currentConnection = ReplicaClient.OnNew("GameUnit", function(replica)
            local unitID = replica.Data.ID
            if unitID and not table.find(allPlacedIDs, unitID) then
                table.insert(allPlacedIDs, unitID)
                print(string.format("   🆕 [UnitTracker] New unit detected: %s", tostring(unitID)))
            end
        end)

        -- รอให้ connection พร้อม (แก้ race condition)
        print("⏳ [placeAndUpgrade] Waiting for connection to be ready...")
        task.wait(2)

        local function placeUnit(slot, cframe)
            -- Validate slot มี unit หรือไม่
            local cost = getUnitCost(slot)

            if cost == 0 then
                warn(string.format("❌ [PlaceUnit] Slot %s is empty or unavailable - skipping", slot))
                return false
            end

            local startCount = #allPlacedIDs

            -- เพิ่ม random offset 0.5 studs
            local randomX = (math.random() - 0.5) * 0.5
            local randomZ = (math.random() - 0.5) * 0.5
            local adjustedCFrame = cframe * CFrame.new(randomX, 0, randomZ)

            print(string.format("🔄 [PlaceUnit] Attempting to place Slot %s (Cost: %d, Money: %d)", slot, cost, getCurrentMoney()))

            local attempts = 0
            while attempts < 60 do
                local money = getCurrentMoney()

                -- ถ้า cost = 999999 (detect ไม่ได้) → บังคับวางเลย
                local shouldPlace = false
                if cost == 999999 then
                    warn(string.format("⚠️ [PlaceUnit] Cannot detect cost for slot %s - forcing placement", slot))
                    shouldPlace = true
                elseif money >= cost then
                    shouldPlace = true
                end

                if shouldPlace then

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
                            print(string.format("   ✅ [PlaceUnit] Successfully placed Slot %s (Unit ID: %s)", slot, tostring(newUnitID)))
                            return true
                        else
                            warn(string.format("⚠️ [PlaceUnit] Place retry: Slot=%s, Cost=%d, Money=%d, Attempt=%d/60", slot, cost, money, attempts + 1))
                            attempts = attempts + 1
                            task.wait(1)
                        end
                    else
                        warn(string.format("❌ [PlaceUnit] FireServer failed: Slot=%s, Attempt=%d/60, Error=%s", slot, attempts + 1, tostring(err)))
                        attempts = attempts + 1
                        task.wait(1)
                    end
                else
                    if attempts % 10 == 0 then
                        print(string.format("⏳ [PlaceUnit] Waiting for money: Slot=%s, Need=%d, Have=%d, Attempt=%d/60", slot, cost, money, attempts + 1))
                    end
                    task.wait(1)
                    attempts = attempts + 1
                end
            end

            warn(string.format("❌ [PlaceUnit] Place timeout after 60 attempts: Slot=%s, Cost=%d", slot, cost))
            return false
        end

        print("🔄 [Phase] Starting placement sequence...")

        -- ฟังก์ชันเช็คชื่อ Unit จาก HotbarData (Replica)
        local function getUnitNameFromSlot(slot)
            local success, unitName = pcall(function()
                local replica = Nodes.GET_PLAYER_REPLICA:InvokeSelf()
                if not replica or not replica.Data or not replica.Data.HotbarData then
                    return nil
                end

                -- อ่าน fullKey จาก HotbarData
                local fullKey = replica.Data.HotbarData[slot] or replica.Data.HotbarData[tostring(slot)]
                if not fullKey then return nil end

                -- แยก internal name (format: "UnitName#uuid")
                local internalName = fullKey:match("^(.+)#") or fullKey

                -- แปลงเป็น Display Name
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

        -- เช็คว่า unit ที่ equip อยู่เป็นตัวที่วางได้แค่ 3 ตัวหรือไม่
        local PLACEMENT_LIMITED_UNITS = {"Greed", "Scissor", "Water Princess"}
        local equippedUnitName = getUnitNameFromSlot("2")  -- slot 2 คือ unit หลัก
        local isPlacementLimited = false

        if equippedUnitName then
            print(string.format("🔍 [Phase] Equipped unit in slot 2: %s", equippedUnitName))
            for _, limitedUnit in ipairs(PLACEMENT_LIMITED_UNITS) do
                if equippedUnitName == limitedUnit then
                    isPlacementLimited = true
                    print(string.format("⚠️ [Phase] Unit '%s' is placement-limited (max 3 units) - will skip Unit 4", equippedUnitName))
                    break
                end
            end
        else
            warn("⚠️ [Phase] Could not detect equipped unit name - will place all 4 units")
        end

        -- Phase 1-2: วาง 4 ตัว (หรือ 3 ตัวถ้าเป็น limited unit)
        local unit1ID = nil
        local startCount = #allPlacedIDs
        print("📍 [Phase 1] Placing Unit 1...")
        local success1 = placeUnit("2", CFrame.new(3077.4265136719, 1798.7340087891, 3330.8972167969))
        if success1 and #allPlacedIDs > startCount then
            unit1ID = allPlacedIDs[#allPlacedIDs]
            print(string.format("✅ [Phase 1] Unit 1 placed (ID: %s)", tostring(unit1ID)))
        else
            warn("❌ [Phase 1] Failed to place Unit 1 - aborting phase")
            return false
        end

        local upgradeUnits = {}

        startCount = #allPlacedIDs
        print("📍 [Phase 1] Placing Unit 2...")
        local success2 = placeUnit("2", CFrame.new(3092.5168457031, 1798.9315185547, 3367.4926757812))
        if success2 and #allPlacedIDs > startCount then
            table.insert(upgradeUnits, allPlacedIDs[#allPlacedIDs])
            print(string.format("✅ [Phase 1] Unit 2 placed (ID: %s)", tostring(allPlacedIDs[#allPlacedIDs])))
        else
            warn("❌ [Phase 1] Failed to place Unit 2 - aborting phase")
            return false
        end

        startCount = #allPlacedIDs
        print("📍 [Phase 2] Placing Unit 3...")
        local success3 = placeUnit("2", CFrame.new(3092.3759765625, 1798.9315185547, 3370.3395996094))
        if success3 and #allPlacedIDs > startCount then
            table.insert(upgradeUnits, allPlacedIDs[#allPlacedIDs])
            print(string.format("✅ [Phase 2] Unit 3 placed (ID: %s)", tostring(allPlacedIDs[#allPlacedIDs])))
        else
            warn("❌ [Phase 2] Failed to place Unit 3 - aborting phase")
            return false
        end

        -- Phase 2 Unit 4: ข้ามถ้าเป็น placement-limited unit
        if isPlacementLimited then
            print("⏭️ [Phase 2] Skipping Unit 4 (placement-limited unit equipped)")
        else
            startCount = #allPlacedIDs
            print("📍 [Phase 2] Placing Unit 4...")
            local success4 = placeUnit("2", CFrame.new(3092.3918457031, 1798.9315185547, 3373.3002929688))
            if success4 and #allPlacedIDs > startCount then
                table.insert(upgradeUnits, allPlacedIDs[#allPlacedIDs])
                print(string.format("✅ [Phase 2] Unit 4 placed (ID: %s)", tostring(allPlacedIDs[#allPlacedIDs])))
            else
                warn("❌ [Phase 2] Failed to place Unit 4 - aborting phase")
                return false
            end
        end

        -- Phase 3: รอ 30 วิ
        print("⏳ [Phase 3] Waiting 30 seconds...")
        task.wait(30)

        -- Phase 4: ขาย Unit 1 + วาง Unit 5
        print("💰 [Phase 4] Selling Unit 1...")
        if unit1ID then
            local success, err = pcall(function()
                playerReplica:FireServer("SellGameUnit", unit1ID)
            end)
            if success then
                print(string.format("   ✅ [Phase 4] Sold Unit 1 (ID: %s)", tostring(unit1ID)))
            else
                warn(string.format("   ⚠️ [Phase 4] Failed to sell Unit 1 (ID=%s): %s", tostring(unit1ID), tostring(err)))
            end
            task.wait(0.5)
        else
            warn("⚠️ [Phase 4] unit1ID is nil - cannot sell Unit 1")
        end

        startCount = #allPlacedIDs
        print("📍 [Phase 4] Placing Unit 5...")
        local success5 = placeUnit("2", CFrame.new(3095.4975585938, 1798.7340087891, 3365.9299316406))
        if success5 and #allPlacedIDs > startCount then
            table.insert(upgradeUnits, allPlacedIDs[#allPlacedIDs])
            print(string.format("✅ [Phase 4] Unit 5 placed (ID: %s)", tostring(allPlacedIDs[#allPlacedIDs])))
        else
            warn("⚠️ [Phase 4] Failed to place Unit 5 - continuing with existing units...")
        end

        -- Phase 5: รอ 2 วิ
        print("⏳ [Phase 5] Waiting 2 seconds...")
        task.wait(2)

        -- Disconnect connection ใหม่ที่สร้างใน Phase นี้
        if currentConnection then
            currentConnection:Disconnect()
            currentConnection = nil
        end

        -- Phase 6: ตั้ง AutoUpgrade Priority
        print(string.format("🔧 [Phase 6] Setting AutoUpgrade priority for %d units...", #upgradeUnits))
        for i, unitID in ipairs(upgradeUnits) do
            local success, err = pcall(function()
                playerReplica:FireServer("ChangeGameUnitAutoUpgradePriority", unitID, AUTO_UPGRADE_PRIORITY)
            end)
            if success then
                print(string.format("   ✅ [Phase 6] Priority set for unit %d/%d (ID: %s)", i, #upgradeUnits, tostring(unitID)))
            else
                warn(string.format("   ⚠️ [Phase 6] Failed to set priority for unit %s: %s", tostring(unitID), tostring(err)))
            end
            task.wait(0.3)
        end

        print("✅ [Phase] All phases completed successfully")
        return true
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

    -- Auto Claim Quest/Achievement Loop (ทุก 5 นาที)
    spawn(function()
        -- Claim ทันที 1 รอบก่อน
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

        -- วนลูปทุก 5 นาที
        while true do
            task.wait(300) -- 5 นาที

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
                    warn("⚠️ Quest claim failed: Replica or QuestData not found")
                end
            end)
        end
    end)

    task.wait(5)

        -- ฟังก์ชันขาย Unit ทั้งหมด (เรียกก่อนเริ่ม Phase ใหม่)
        local function sellAllUnits()
            local soldCount = 0
            local failCount = 0

            print("🔄 [Wave Reset] Selling all existing units...")

            -- Method 1: ใช้ Dependencies.GameUnits (เร็วกว่า)
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
                                print(string.format("   ✅ Sold unit ID: %s", tostring(unitID)))
                            else
                                failCount = failCount + 1
                                warn(string.format("   ⚠️ Failed to sell unit ID %s: %s", tostring(unitID), tostring(sellErr)))
                            end

                            task.wait(0.2)  -- หน่วงเล็กน้อยระหว่างขาย
                        end
                    end
                end
            end)

            if not success1 then
                warn("⚠️ Method 1 (Dependencies) failed - trying Method 2 (allPlacedIDs)")

                -- Method 2: Fallback ใช้ allPlacedIDs
                if #allPlacedIDs > 0 then
                    for _, unitID in ipairs(allPlacedIDs) do
                        local sellSuccess, sellErr = pcall(function()
                            playerReplica:FireServer("SellGameUnit", unitID)
                        end)

                        if sellSuccess then
                            soldCount = soldCount + 1
                            print(string.format("   ✅ Sold unit ID: %s", tostring(unitID)))
                        else
                            failCount = failCount + 1
                            warn(string.format("   ⚠️ Failed to sell unit ID %s: %s", tostring(unitID), tostring(sellErr)))
                        end

                        task.wait(0.2)
                    end
                end
            end

            print(string.format("✅ [Wave Reset] Sold %d units (Failed: %d)", soldCount, failCount))
            task.wait(1)

            return soldCount > 0 or failCount == 0
        end

        local isRunningPhase = false
        local lastWaveResetTime = 0
        local WAVE_RESET_COOLDOWN = 5  -- ป้องกัน trigger ซ้ำภายใน 5 วินาที

        print("🔄 [In-Game] Starting initial phase...")
        placeAndUpgrade()

        while true do
            task.wait(1)

            if isRunningPhase then
                continue
            end

            local currentWave = getCurrentWave()
            local currentTime = tick()

            if (currentWave == 0 or currentWave == 1) and (currentTime - lastWaveResetTime) >= WAVE_RESET_COOLDOWN then
                print(string.format("🔄 [Wave Reset] Detected at Wave %d - preparing new phase", currentWave))
                isRunningPhase = true
                lastWaveResetTime = currentTime
                task.wait(2)

                -- ขาย Unit เก่าทั้งหมดก่อนเริ่ม Phase ใหม่
                local sellSuccess = sellAllUnits()
                if not sellSuccess then
                    warn("⚠️ [Wave Reset] Sell failed but continuing with new phase")
                end

                -- เช็ค Banner ถ้ามี Summon Config และเงินเกิน 10000
                if hasSummonConfig and #SUMMON_CONFIG > 0 then
                    print("🔍 [Wave Reset] Checking banner for target units...")
                    local bannerCheckSuccess, bannerResult = pcall(function()
                        local replica = Nodes.GET_PLAYER_REPLICA:InvokeSelf()
                        if replica and replica.Data then
                            local itemData = replica.Data.ItemData
                            local gems = itemData and itemData.Gem and itemData.Gem.Amount or 0

                            print(string.format("   💎 Current Gems: %d", gems))

                            if gems >= 10000 then
                                print("   ✅ Gems >= 10000 - checking banner...")

                                -- เช็ค Banner (พร้อม timeout)
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
                                    print(string.format("   📋 Banner units found: %s", table.concat(bannerUnits, ", ")))

                                    -- เช็คว่ามีตัวที่ต้องการหรือไม่
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
                                        print(string.format("✅ [Wave Reset] Target unit '%s' found in banner + gems >= 10000 → Rejoining...", matchedUnit))
                                        task.wait(1)

                                        pcall(function()
                                            game:GetService("TeleportService"):Teleport(game.PlaceId, Players.LocalPlayer)
                                        end)

                                        return  -- หยุดสคริปต์
                                    else
                                        warn("⚠️ [Wave Reset] No target units found in banner - continuing farming")
                                    end
                                else
                                    warn("⚠️ [Wave Reset] Failed to check banner (timeout or error) - continuing farming")
                                end
                            else
                                print(string.format("   ⏭️ Gems < 10000 - skipping banner check"))
                            end
                        else
                            warn("⚠️ [Wave Reset] Failed to get Replica for banner check")
                        end
                    end)

                    if not bannerCheckSuccess then
                        warn(string.format("⚠️ [Wave Reset] Banner check error: %s - continuing farming", tostring(bannerResult)))
                    end
                end

                print("🔄 [Wave Reset] Starting new phase...")
                local success = placeAndUpgrade()
                isRunningPhase = false

                if not success then
                    warn("⚠️ [Wave Reset] Phase failed - will retry on next wave reset")
                else
                    print("✅ [Wave Reset] Phase completed successfully")
                end
            end
        end
    end)

    -- หยุดที่นี่ - ไม่รัน Lobby scripts
    return
end

-- ========================================
-- LOBBY SCRIPTS (รันเฉพาะตอนไม่ได้อยู่ในแมพ)
-- ========================================

-- ========================================
-- 1. RemoveLobbyMesh.lua (Boost FPS)
-- ========================================
printStep("Removing Lobby Mesh...")

-- ใช้ฟังก์ชัน Performance Optimization
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
    local success, folder = pcall(function()
        return playerGui.Prompt.Frame.Frame.Frame.Folder.Frame.Frame
    end)

    if not success or not folder then
        warn("⚠️ Starter Unit popup not found or already claimed - skipping")
        task.wait(2)
        return
    end

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

                        -- spam คลิกมุมซ้ายบน 5 รอบ
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

-- Claim ReleaseCalendar ทั้งหมดพร้อมกัน
for day = START_DAY, END_DAY do
    spawn(function()
        pcall(function()
            Nodes.CLAIM_CALENDAR:FireServer("ReleaseCalendar", day)
        end)
    end)
    task.wait(0.05)  -- หน่วงเล็กน้อย
end

task.wait(2)  -- รอให้ claim เสร็จ

-- Claim DailyRewards ทั้งหมดพร้อมกัน
for day = START_DAY, END_DAY do
    spawn(function()
        pcall(function()
            Nodes.CLAIM_CALENDAR:FireServer("DailyRewards", day)
        end)
    end)
    task.wait(0.05)  -- หน่วงเล็กน้อย
end

task.wait(2)  -- รอให้ claim เสร็จ

print("   ✅ Calendar rewards claimed!")

-- ปิด popup รวม
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
        "1MGROUP!",
        "100mvisits",
        "100K!",
        "30KLIKES!",
        "EXPEDITIONS",
        "AE#1",
        "SorryForBugs",
        "wfade",
        "RELEASE",
    }

    local successCount = 0
    local failCount = 0

    -- Redeem ทุกโค้ดพร้อมกัน
    for i, code in ipairs(CODES) do
        spawn(function()
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
        end)
        task.wait(0.05)  -- หน่วงเล็กน้อย
    end

    -- รอให้ redeem เสร็จ
    task.wait(6)


    -- ปิด popup (ถ้ามี)
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
    -- ดึง QuestData
    local replica = Nodes.GET_PLAYER_REPLICA:InvokeSelf()
    if not replica or not replica.Data.QuestData then
        warn("   ⚠️ QuestData not found!")
    else
        local questData = replica.Data.QuestData
        local categories = {}

        -- เก็บ categories ทั้งหมด
        for categoryName, _ in pairs(questData) do
            table.insert(categories, categoryName)
        end


        -- Claim แต่ละ category พร้อมกัน
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

    -- ปิด popup ที่อาจจะขึ้นมา
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
-- 5. เช็คตัวละครที่มีอยู่ + Summon System (Mythic/Secret)
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

local function closeInventory()
    local VirtualInputManager = game:GetService("VirtualInputManager")
    for i = 1, 5 do
        VirtualInputManager:SendMouseButtonEvent(10, 10, 0, true, game, 0)
        task.wait(0.05)
        VirtualInputManager:SendMouseButtonEvent(10, 10, 0, false, game, 0)
        task.wait(0.1)
    end
end

-- ฟังก์ชันเช็คว่ามี units ใน Inventory
local function checkInventoryForUnits(targetUnits)
    local unitData = Nodes.GET_DATA_VALUE:InvokeSelf("UnitData")
    if not unitData then return {} end

    local UnitInfo = require(ReplicatedStorage.Shared.Information.Units)
    local foundUnits = {}

    for fullKey, data in pairs(unitData) do
        local internalName = fullKey:match("^(.+)#") or fullKey
        local unitInfo = UnitInfo[internalName]
        if unitInfo then
            local displayName = unitInfo.DisplayName or internalName
            for _, targetUnit in pairs(targetUnits) do
                if displayName == targetUnit then
                    table.insert(foundUnits, displayName)
                    break
                end
            end
        end
    end
    return foundUnits
end

-- ฟังก์ชันส่ง Horst Description
local function sendSummonStatus(foundUnits, isComplete)
    if not HORST_ENABLED or not _G.Horst_SetDescription then return end

    local secretUnits = {}
    local mythicUnits = {}
    local otherUnits = {}

    -- เก็บรายชื่อ units ที่ต้องการ (ถ้ามี config)
    local configUnitSet = {}
    if hasSummonConfig then
        for _, unit in ipairs(SUMMON_CONFIG) do
            configUnitSet[unit] = true
        end
    end

    for _, unit in ipairs(foundUnits) do
        local isSecret = false
        for _, secret in ipairs(SECRET_UNITS) do
            if unit == secret then
                table.insert(secretUnits, unit)
                isSecret = true
                break
            end
        end
        if not isSecret then
            for _, mythic in ipairs(MYTHIC_UNITS) do
                if unit == mythic then
                    -- ถ้ามี Config และตัวนี้ไม่ได้อยู่ใน Config → ใส่ Other
                    if hasSummonConfig and not configUnitSet[unit] then
                        table.insert(otherUnits, unit)
                    else
                        table.insert(mythicUnits, unit)
                    end
                    break
                end
            end
        end
    end

    local descParts = {}
    if #secretUnits > 0 then
        table.insert(descParts, "Secret: " .. table.concat(secretUnits, ", "))
    end
    if #mythicUnits > 0 then
        table.insert(descParts, "Mythic: " .. table.concat(mythicUnits, ", "))
    end
    if #otherUnits > 0 then
        table.insert(descParts, "Other: " .. table.concat(otherUnits, ", "))
    end

    if #descParts > 0 then
        local message = table.concat(descParts, " | ")
        pcall(function()
            _G.Horst_SetDescription(message, "")
        end)

        if isComplete and _G.Horst_AccountChangeDone then
            pcall(_G.Horst_AccountChangeDone)
        end
    end
end

-- เช็ค Summon Config
local shouldSummon = false
local hasTargetUnit = false

if hasSummonConfig then

    -- เช็ค Level และ Gems
    local replica = Nodes.GET_PLAYER_REPLICA:InvokeSelf()
    local level = replica and replica.Data and replica.Data.Level or 0
    local gems = replica and replica.Data and replica.Data.ItemData and replica.Data.ItemData.Gem and replica.Data.ItemData.Gem.Amount or 0


    if level > 10 and gems >= 2500 then
        -- เช็คว่ามีตัวที่ต้องการใน Inventory แล้วหรือยัง
        local foundInInventory = checkInventoryForUnits(SUMMON_CONFIG)

        if #foundInInventory >= #SUMMON_CONFIG then
            sendSummonStatus(foundInInventory, true)
            hasTargetUnit = true
        else
            -- เช็ค Banner ว่ามีตัวที่ต้องการหรือไม่
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

                -- ตั้ง AutoSell Legendary
                local FusionPackage = ReplicatedStorage:WaitForChild("FusionPackage")
                local Actions = require(FusionPackage.Actions)
                pcall(function()
                    Actions.ToggleAutoSell("Standard", "Legendary", false, true)
                end)
            else
                if #foundInInventory > 0 then
                    sendSummonStatus(foundInInventory, false)
                end
            end
        end
    else
        warn(string.format("⚠️ Summon check skipped: Level=%d, Gems=%d (require Level>10 and Gems>=2500)", level, gems))
    end
end

-- เช็คตัว Legendary (ถ้าไม่มี Summon Config หรือข้ามมาแล้ว)
if not shouldSummon then

    local function checkForTargetUnits()
        local targetUnits = {
            "The Hero",
            "Scissor",
            "Ice Queen",
            "Water Princess",
            "Forbidden Teacher",
            "Greed"
        }

        -- เช็คผ่าน UnitData โดยตรงแทนการอ่าน GUI
        local unitData = Nodes.GET_DATA_VALUE:InvokeSelf("UnitData")
        if not unitData then
            return false
        end

        local UnitInfo = require(ReplicatedStorage.Shared.Information.Units)

        -- เก็บชื่อที่เจอเพื่อ debug
        local foundUnits = {}
        local targetFound = false

        for fullKey, data in pairs(unitData) do
            local internalName = fullKey:match("^(.+)#") or fullKey
            local unitInfo = UnitInfo[internalName]

            if unitInfo then
                local displayName = unitInfo.DisplayName or internalName

                -- เก็บเพื่อ debug
                if not foundUnits[displayName] then
                    foundUnits[displayName] = true
                end

                -- เช็คว่าตรงกับ target unit หรือไม่
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

        if not targetFound then
            -- แสดงตัวที่เจอทั้งหมด (เพื่อ debug)
            local count = 0
            for unitName, _ in pairs(foundUnits) do
                count = count + 1
                if count >= 10 then
                    break
                end
            end
        end

        return targetFound
    end

    -- เปิด Inventory
    openInventory()
    task.wait(1)

    -- เช็คตัวละคร
    hasTargetUnit = checkForTargetUnits()

    -- ปิด Inventory
    closeInventory()
end

-- ========================================
-- 6. AutoSummon (สำหรับ Summon Config หรือ Legendary)
-- ========================================
if shouldSummon then
    printStep("Auto Summon (Mythic/Secret)...")

    local BANNER_ID = "Standard"
    local AMOUNT_PER_SUMMON = 50  -- 50 ต่อรอบ (x10 summon)
    local DELAY = 2
    local summonCount = 0
    local MAX_SUMMONS = 100

    while summonCount < MAX_SUMMONS do
        -- เช็คเงินก่อนสุ่ม
        local replica = Nodes.GET_PLAYER_REPLICA:InvokeSelf()
        local gems = replica and replica.Data and replica.Data.ItemData and replica.Data.ItemData.Gem and replica.Data.ItemData.Gem.Amount or 0

        if gems < 2500 then
            warn(string.format("⚠️ Not enough gems for summon: %d (require 2500)", gems))
            break
        end

        summonCount = summonCount + 1

        pcall(function()
            Nodes.BANNER_SUMMON:FireServer(BANNER_ID, AMOUNT_PER_SUMMON)
        end)

        task.wait(DELAY)

        -- เช็คเงินหลัง summon
        local replicaAfter = Nodes.GET_PLAYER_REPLICA:InvokeSelf()
        local gemsAfter = replicaAfter and replicaAfter.Data and replicaAfter.Data.ItemData and replicaAfter.Data.ItemData.Gem and replicaAfter.Data.ItemData.Gem.Amount or 0

        if gemsAfter < 2500 then
            warn(string.format("⚠️ Gems depleted after summon: %d (stopping)", gemsAfter))

            -- ปิด popup
            for j = 1, 5 do
                VirtualInputManager:SendMouseButtonEvent(10, 10, 0, true, game, 0)
                task.wait(0.05)
                VirtualInputManager:SendMouseButtonEvent(10, 10, 0, false, game, 0)
                task.wait(0.1)
            end

            break
        end

        -- ปิด popup
        for j = 1, 5 do
            VirtualInputManager:SendMouseButtonEvent(10, 10, 0, true, game, 0)
            task.wait(0.05)
            VirtualInputManager:SendMouseButtonEvent(10, 10, 0, false, game, 0)
            task.wait(0.1)
        end

        task.wait(2)

        -- เช็คว่าได้ครบหรือยัง
        local foundInInventory = checkInventoryForUnits(SUMMON_CONFIG)

        if #foundInInventory >= #SUMMON_CONFIG then
            sendSummonStatus(foundInInventory, true)
            hasTargetUnit = true
            break
        else
            -- แสดงตัวที่มีแล้ว
            if #foundInInventory > 0 then
                sendSummonStatus(foundInInventory, false)
            end

            -- เช็ค Banner ว่ายังมีตัวที่ต้องการอยู่หรือไม่
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
                    sendSummonStatus(foundInInventory, false)
                end
                warn("⚠️ Target units no longer in banner - stopping summon")
                break
            end

        end
    end

    if summonCount >= MAX_SUMMONS then
        local foundInInventory = checkInventoryForUnits(SUMMON_CONFIG)
        if #foundInInventory > 0 then
            sendSummonStatus(foundInInventory, false)
        end
        warn(string.format("⚠️ Reached max summons (%d)", MAX_SUMMONS))
    end

elseif not hasTargetUnit then
    printStep("Auto Summon (Legendary)...")

    local BANNER_ID = "Standard"
    local AMOUNT_PER_SUMMON = 50
    local DELAY = 2
    local summonCount = 0
    local MAX_SUMMONS = 100  -- จำกัดไว้ 100 รอบป้องกันวนไม่รู้จบ

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

    while not hasTargetUnit and summonCount < MAX_SUMMONS do
        summonCount = summonCount + 1

        pcall(function()
            Nodes.BANNER_SUMMON:FireServer(BANNER_ID, AMOUNT_PER_SUMMON)
        end)

        task.wait(DELAY)

        -- spam คลิกมุมซ้ายบน 5 รอบ
        for j = 1, 5 do
            VirtualInputManager:SendMouseButtonEvent(10, 10, 0, true, game, 0)
            task.wait(0.05)
            VirtualInputManager:SendMouseButtonEvent(10, 10, 0, false, game, 0)
            task.wait(0.1)
        end

        task.wait(2)

        -- เช็คว่าได้ target unit หรือยัง
        hasTargetUnit = checkForTargetUnits()

        if hasTargetUnit then
            warn("✅ Target Legendary unit found!")
        end
    end

    if not hasTargetUnit then
        warn(string.format("⚠️ Reached max summons (%d) without finding target unit", MAX_SUMMONS))
    end
else
end

-- ========================================
-- 7. QuickEquip (ถ้ามีตัวที่ต้องการ)
-- ========================================
if hasTargetUnit then
    printStep("Quick Equip...")

    -- ปิด Inventory ก่อน
    local VirtualInputManager = game:GetService("VirtualInputManager")

    -- spam คลิกมุมซ้ายบน 5 รอบ
    for i = 1, 5 do
        VirtualInputManager:SendMouseButtonEvent(10, 10, 0, true, game, 0)
        task.wait(0.05)
        VirtualInputManager:SendMouseButtonEvent(10, 10, 0, false, game, 0)
        task.wait(0.1)
    end

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

    -- หา target unit ที่มีอยู่ (ให้เลือกตัวที่วางได้ 4 ตัวก่อน)
    local targetUnits = {
        "Ice Queen",           -- Priority 1 (วางได้ 4 ตัว)
        "Forbidden Teacher",   -- Priority 2 (วางได้ 4 ตัว)
        "The Hero",           -- Priority 3 (วางได้ 4 ตัว)
        "Greed",              -- Priority 4 (วางได้ 3 ตัว)
        "Scissor",            -- Priority 5 (วางได้ 3 ตัว)
        "Water Princess"      -- Priority 6 (วางได้ 3 ตัว)
    }

    local foundTargetUnit = nil

    -- เช็ค Ice Queen ก่อนเสมอ
    if displayNameMap["ice queen"] then
        foundTargetUnit = "Ice Queen"
    else
        -- ถ้าไม่มี Ice Queen ค้นหาตัวอื่นตามลำดับ
        for _, targetUnit in pairs(targetUnits) do
            if displayNameMap[targetUnit:lower()] then
                foundTargetUnit = targetUnit
                break
            end
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
    warn("⚠️ Skipping equip and game start - no target unit found")
end
