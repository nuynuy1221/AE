repeat wait() until game:IsLoaded()

if game.PlaceId ~= 79546208627805 and game.PlaceId ~= 126509999114328 then
    return
end

-- Main Script - Auto Farm Manager
-- Sugar Hub - Auto Farm System

print("Version 1.2.4 / 5.16")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

print("=== Sugar Hub Started ===")

-- ============================================
-- Config (can be set externally via _G.Config before running this script)
-- ============================================
_G.Config = _G.Config or {}
local Config = _G.Config

-- Defaults: if not set externally, use false / leave unset
Config.Horst = Config.Horst == true
Config.ToggleRender3D = Config.ToggleRender3D == true
Config.BuyClass = Config.BuyClass or {}  -- Table of class names to buy, e.g. {"Camper", "Medic"}
-- UpgradeClass: class หลักที่จะใช้ฟาร์ม (ตอนนี้รอบรับ Cyborg — ใช้ Laser Cannon ยิงแทนตี)
-- ตอนอยู่ lobby: equip class นี้ทันที + อัปเกรดถ้า CanLevelUp
-- ตอนเข้า Stronghold: equip Laser Cannon + ยิงแทนตี
-- ถ้าไม่ตั้ง = ฟาร์มปกติ (ตีต้นไม้ด้วยขวาน)
Config.UpgradeClass = Config.UpgradeClass or {}  -- Table เช่น {"Cyborg"} - ตอนนี้ใช้แค่ตัวแรก
-- RerollShop: สุ่มหน้าร้าน class จนเจอตัวที่อยู่ใน BuyClass (เปิดได้เมื่อมี BuyClass เท่านั้น)
Config.RerollShop = Config.RerollShop == true
-- MaxRerollPrice: ราคาสุ่มสูงสุดที่ยอมรับ เช่น 50 (ราคา 51+ = เลิกสุ่ม) - มีผลเมื่อ RerollShop = true เท่านั้น
Config.MaxRerollPrice = tonumber(Config.MaxRerollPrice)
-- Config.Diamonds: no default (if not set externally = nil = never send DONE)

-- If Horst is enabled, load the Horst script
if Config.Horst then
    loadstring(game:HttpGet("https://raw.githubusercontent.com/HorstSpaceX/last_update/main/on_loaded.lua"))()
end

-- ============================================
-- Check if goals are met (check real-time values from game)
-- ============================================
local function CheckGoals()
    if not Config.Horst then return false end

    local diamondsGoal = Config.Diamonds ~= nil
    local classesGoal = Config.BuyClass and #Config.BuyClass > 0
    local upgradeGoal = Config.UpgradeClass and #Config.UpgradeClass > 0
    local isLobby = game.PlaceId == 79546208627805

    -- Check real-time diamonds from game
    local diamondsMet = true
    if diamondsGoal then
        local currentDiamonds = LocalPlayer:GetAttribute("Diamonds") or 0
        diamondsMet = currentDiamonds >= Config.Diamonds
    end

    -- Check real-time classes from game (only in Lobby)
    local classesMet = true
    if (classesGoal or upgradeGoal) and isLobby then
        local ClassProgress = LocalPlayer:FindFirstChild("ClassProgress")
        if ClassProgress then
            -- Check BuyClass: ต้อง owned ครบทุกตัว
            if classesGoal then
                for _, className in ipairs(Config.BuyClass) do
                    if not ClassProgress:FindFirstChild(className) then
                        classesMet = false
                        break
                    end
                end
            end
            -- Check UpgradeClass: ทุก class ใน list ต้องถึง Lv.3
            -- (ถ้าไม่มี class ไหน Lv.3 สักตัว = ยังไม่达成 - เรียงตาม priority)
            if upgradeGoal and classesMet then
                local allAtMax = true
                local anyValid = false
                for _, clsName in ipairs(Config.UpgradeClass) do
                    if type(clsName) == "string" then
                        anyValid = true
                        local folder = ClassProgress:FindFirstChild(clsName)
                        if not folder then
                            allAtMax = false
                            break
                        else
                            local lvl = folder:GetAttribute("Level") or 1
                            if lvl < 3 then
                                allAtMax = false
                                break
                            end
                        end
                    end
                end
                if not anyValid or not allAtMax then
                    classesMet = false
                end
            end
        end
    end

    -- In farm map: ignore classes goal
    if not isLobby and (classesGoal or upgradeGoal) then
        return false
    end

    -- Send DONE only if all goals met
    if diamondsMet and classesMet then
        if _G.Horst_AccountChangeDone then
            _G.Horst_AccountChangeDone()
        end
        return true  -- Goals met
    end

    return false  -- Goals not met
end


-- ============================================
-- Anti-AFK (prevent Roblox from kicking for inactivity)
-- ============================================
local VirtualUser = game:GetService("VirtualUser")
LocalPlayer.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
    print("[AntiAFK] Idled -> sent virtual input")
end)

-- ============================================
-- GUI Setup
-- ============================================

local playerGui = LocalPlayer:WaitForChild("PlayerGui")

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "SugarHubGUI"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.DisplayOrder = 999999
screenGui.IgnoreGuiInset = true
screenGui.Parent = playerGui

-- Main Frame (ขนาด/ตำแหน่งเป็น scale ทั้งหมด เพื่อปรับตามขนาดจอ - เหมือน Anime Expeditions)
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

-- ฟังก์ชันใส่ลูกน้ำ (เหมือน Anime Expeditions)
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

-- Username Box (LayoutOrder 1 - เหมือน Anime Expeditions)
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
usernameLabel.Text = LocalPlayer.Name
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

-- ฟังก์ชันสร้างกล่อง Stat แบบ name/colon/value (เหมือน Anime Expeditions)
local function createStatBox(name, key, color, layoutOrder)
    local statBox = Instance.new("Frame")
    statBox.Name = key .. "Box"
    statBox.Size = UDim2.new(1, 0, 0.18, 0)
    statBox.BackgroundColor3 = color
    statBox.BorderSizePixel = 0
    statBox.LayoutOrder = layoutOrder
    statBox.Parent = mainFrame

    local statCorner = Instance.new("UICorner")
    statCorner.CornerRadius = UDim.new(0, 10)
    statCorner.Parent = statBox

    local statStroke = Instance.new("UIStroke")
    statStroke.Color = Color3.fromRGB(139, 90, 43)
    statStroke.Thickness = 3
    statStroke.Parent = statBox

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

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(0.4, 0, 1, 0)
    nameLabel.Position = UDim2.new(0, 0, 0, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = name
    nameLabel.TextColor3 = Color3.fromRGB(70, 45, 22)
    nameLabel.TextSize = 72
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextScaled = true
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.Parent = contentFrame

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

    return valueLabel
end

-- Status Box (LayoutOrder 2)
local diamondsValueLabel
local statusValueLabel = createStatBox("Status", "Status", Color3.fromRGB(194, 144, 90), 2)
statusValueLabel.Text = "Initializing..."

-- Diamonds Box (LayoutOrder 3) - อ่านค่าจาก LocalPlayer.Diamonds attribute (ดูตาม diamond_checker_print.lua)
diamondsValueLabel = createStatBox("Diamonds", "Diamonds", Color3.fromRGB(210, 180, 140), 3)

local function updateDiamondsLabel()
    local diamonds = LocalPlayer:GetAttribute("Diamonds")
    diamondsValueLabel.Text = diamonds and formatNumber(diamonds) or "..."
end

-- ส่ง Description ให้ Horst
-- CLASS_QUESTS ต้อง declare ก่อน (hoist) เพราะ function bodies ในบาง executor scope leak
local CLASS_QUESTS = {
    Cyborg = {
        [2] = { AlienTechKills = 200, MultiDamageShots = 50 },
        [3] = { AlienTechKills = 350, MultiDamageShots = 100 },
    },
    -- ... (จะ merge เพิ่มด้านล่าง)
}

local function sendHorstDescription()
    if not Config.Horst then return end
    if not _G.Horst_SetDescription then return end

    local diamonds = LocalPlayer:GetAttribute("Diamonds") or 0

    local isLobby = game.PlaceId == 79546208627805
    local hasConfig = (Config.BuyClass and #Config.BuyClass > 0) or
                     (Config.UpgradeClass and #Config.UpgradeClass > 0)

    -- ถ้าไม่มี config เลย → ไม่ต้องแสดง Class
    if not hasConfig then
        _G.Horst_SetDescription(string.format("🌲 99 Nights • Diamonds: %d", diamonds))
        return
    end

    local classText
    if isLobby then
        local lines = {}
        local ClassProgress = LocalPlayer:FindFirstChild("ClassProgress")
        if ClassProgress then
            local seen = {}
            local classesToShow = {}
            if Config.BuyClass then
                for _, c in ipairs(Config.BuyClass) do classesToShow[#classesToShow + 1] = c end
            end
            if Config.UpgradeClass then
                for _, c in ipairs(Config.UpgradeClass) do classesToShow[#classesToShow + 1] = c end
            end
            for _, className in ipairs(classesToShow) do
                if not seen[className] then
                    seen[className] = true
                    local folder = ClassProgress:FindFirstChild(className)
                    if folder then
                        local lvl = folder:GetAttribute("Level") or 1
                        local classStr = className .. " Lv" .. lvl
                        -- คำนวณ % quest progress (Lv < 3)
                        if lvl < 3 then
                            local targetLevel = lvl + 1
                            local reqs = CLASS_QUESTS[className] and CLASS_QUESTS[className][targetLevel]
                            if reqs then
                                local totalPct = 0
                                local count = 0
                                for statKey, goal in pairs(reqs) do
                                    local have = folder:GetAttribute(statKey) or 0
                                    if type(have) == "number" and goal > 0 then
                                        totalPct = totalPct + math.min(have / goal, 1) * 100
                                        count = count + 1
                                    end
                                end
                                if count > 0 then
                                    local avgPct = math.floor(totalPct / count)
                                    classStr = classStr .. " (" .. avgPct .. "%)"
                                    -- Dev Logs: แสดงแต่ละ stat แยก
                                    print(string.format("[Quest] %s -> Lv.%d: %d%% (avg)",
                                        className, targetLevel, avgPct))
                                    for statKey, goal in pairs(reqs) do
                                        local have = folder:GetAttribute(statKey) or 0
                                        if type(have) == "number" and goal > 0 then
                                            print(string.format("  - %s: %d / %d",
                                                statKey, have, goal))
                                        end
                                    end
                                end
                            end
                        else
                            classStr = classStr .. " (MAX)"
                        end
                        table.insert(lines, classStr)
                    else
                        table.insert(lines, className .. " (not owned)")
                    end
                end
            end
        end
        classText = #lines > 0 and table.concat(lines, ", ") or "None"
    else
        -- แมพฟาร์ม: เช็คเฉพาะ class ที่กำลัง equip + คำนวณ % quest progress
        local equipped = LocalPlayer:GetAttribute("Class")
        if equipped then
            local lvl = LocalPlayer:GetAttribute("ClassLevel") or 1
            local classTextPart = equipped .. " Lv" .. lvl
            -- คำนวณ % ของ quest ถัดไป (ใช้ CLASS_QUESTS ที่ฝังไว้)
            local targetLevel = math.min(lvl + 1, 3)
            local reqs = CLASS_QUESTS[equipped] and CLASS_QUESTS[equipped][targetLevel]
            if reqs and lvl < 3 then
                local cp = LocalPlayer:FindFirstChild("ClassProgress")
                local folder = cp and cp:FindFirstChild(equipped)
                if folder then
                    local totalPct = 0
                    local count = 0
                    for statKey, goal in pairs(reqs) do
                        local have = folder:GetAttribute(statKey) or 0
                        if type(have) == "number" and goal > 0 then
                            totalPct = totalPct + math.min(have / goal, 1) * 100
                            count = count + 1
                        end
                    end
                    if count > 0 then
                        local avgPct = math.floor(totalPct / count)
                        classTextPart = classTextPart .. " (" .. avgPct .. "%)"
                    end
                end
                classText = classTextPart .. " [Can't check classes during farming]"
            else
                classText = classTextPart .. " (MAX) [Can't check classes during farming]"
            end
        else
            classText = "None [Can't check classes during farming]"
        end
    end

    _G.Horst_SetDescription(string.format(
        "🌲 99 Nights • Diamonds: %d • Class: %s", diamonds, classText))
end

local function checkDiamondsGoalAndSendDone()
    sendHorstDescription()
    CheckGoals()
end

LocalPlayer:GetAttributeChangedSignal("Diamonds"):Connect(function()
    updateDiamondsLabel()
    checkDiamondsGoalAndSendDone()
end)
updateDiamondsLabel()

-- ClassStatUpdated Remote watcher: ดัก event จาก server → อัปเดต quest % real-time
-- signature: ClassStatUpdated:FireClient(player, className, statKey, value, delta)
local classStatCache = {}  -- [className] = { [statKey] = value }
local lastFarmReport = 0    -- cooldown log

pcall(function()
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    -- รอ remote แบบ indefinite ใน background task (กัน hook ก่อน remote พร้อม)
    task.spawn(function()
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local Remotes = ReplicatedStorage:WaitForChild("RemoteEvents", 300)  -- รอ 5 นาที
        if not Remotes then
            warn("[ClassStat] RemoteEvents not found after 5 min")
            return
        end
        -- ตอนนี้รอ ClassStatUpdated แบบ indefinite (กัน hook ก่อน remote replicate)
        local ClassStatUpdated = Remotes:WaitForChild("ClassStatUpdated", math.huge)
        if not ClassStatUpdated or not ClassStatUpdated.OnClientEvent then return end
        ClassStatUpdated.OnClientEvent:Connect(function(className, statKey, value, delta)
            if not className or not statKey then return end
            classStatCache[className] = classStatCache[className] or {}
            classStatCache[className][statKey] = value

            -- ถ้าอยู่แมพฟาร์ม → คำนวณ % + print + ส่ง Horst update
            -- ใช้กับ "currently equipped class" (LocalPlayer.ClassLevel) — ไม่ใช่ [1] เสมอ
            local isLobby = game.PlaceId == 79546208627805
            if not isLobby and Config.Horst then
                -- ตรวจว่า className นี้อยู่ใน UpgradeClass list ไหม
                local isTracked = false
                for _, clsName in ipairs(Config.UpgradeClass or {}) do
                    if clsName == className then isTracked = true break end
                end
                if isTracked then
                    local mainClass = className
                    local lvl = LocalPlayer:GetAttribute("ClassLevel") or 1
                    if lvl < 3 then
                        local reqs = CLASS_QUESTS[mainClass] and CLASS_QUESTS[mainClass][lvl + 1]
                        if reqs then
                            local totalPct, count = 0, 0
                            for sk, goal in pairs(reqs) do
                                local have = classStatCache[mainClass][sk]
                                    or (LocalPlayer.ClassProgress
                                        and LocalPlayer.ClassProgress:FindFirstChild(mainClass)
                                        and LocalPlayer.ClassProgress:FindFirstChild(mainClass):GetAttribute(sk))
                                    or 0
                                if type(have) == "number" and goal > 0 then
                                    totalPct = totalPct + math.min(have / goal, 1) * 100
                                    count = count + 1
                                end
                            end
                            if count > 0 then
                                local avgPct = math.floor(totalPct / count)
                                if os.clock() - lastFarmReport >= 1 then
                                    lastFarmReport = os.clock()
                                    print(string.format("[Quest] %s -> Lv.%d: %d%% (via ClassStatUpdated)",
                                        mainClass, lvl + 1, avgPct))
                                    -- Dev Logs: แสดง stat แต่ละอัน
                                    for sk, goal in pairs(reqs) do
                                        local have = classStatCache[mainClass][sk]
                                            or (LocalPlayer.ClassProgress
                                                and LocalPlayer.ClassProgress:FindFirstChild(mainClass)
                                                and LocalPlayer.ClassProgress:FindFirstChild(mainClass):GetAttribute(sk))
                                            or 0
                                        if type(have) == "number" and goal > 0 then
                                            print(string.format("  - %s: %d / %d", sk, have, goal))
                                        end
                                    end
                                end
                                local equipped = LocalPlayer:GetAttribute("Class")
                                local equippedLvl = LocalPlayer:GetAttribute("ClassLevel") or 1
                                local classTextPart = equipped and (equipped .. " Lv" .. equippedLvl .. " (" .. avgPct .. "%)")
                                    or mainClass .. " Lv" .. lvl .. " (" .. avgPct .. "%)"
                                if Config.Horst and _G.Horst_SetDescription then
                                    local diamonds = LocalPlayer:GetAttribute("Diamonds") or 0
                                    _G.Horst_SetDescription(string.format(
                                        "🌲 99 Nights • Diamonds: %d • Class: %s [Can't check classes during farming]",
                                        diamonds, classTextPart))
                                end
                            end
                        end
                    end
                end
            end
        end)
        print("[ClassStat] watching ClassStatUpdated")
    end)
end)

-- รอให้ attribute Diamonds sync มาจาก server ก่อน (อาจยังเป็น nil ตอนสคริปต์เริ่ม)
-- ป้องกันการส่ง "Diamonds: 0" ไปที่ Horst ทั้งที่ยังโหลดค่าจริงไม่เสร็จ
task.spawn(function()
    local waited = 0
    while LocalPlayer:GetAttribute("Diamonds") == nil and waited < 15 do
        task.wait(0.2)
        waited = waited + 0.2
    end
    updateDiamondsLabel()
    sendHorstDescription()
    checkDiamondsGoalAndSendDone()
end)

-- ============================================
-- Toggle GUI/Render3D ด้วยปุ่ม N
-- ============================================
local UserInputService = game:GetService("UserInputService")
local isGuiVisible = true

-- ถ้าเปิด ToggleRender3D ให้ปิด Render3D ตอนเริ่มต้น (เพราะ GUI เปิดอยู่)
if Config.ToggleRender3D then
    RunService:Set3dRenderingEnabled(false)
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end

    if input.KeyCode == Enum.KeyCode.N then
        isGuiVisible = not isGuiVisible
        mainFrame.Visible = isGuiVisible

        -- ถ้าเปิด ToggleRender3D ให้เปิด/ปิด 3D Rendering ตาม GUI (กลับกัน)
        if Config.ToggleRender3D then
            RunService:Set3dRenderingEnabled(not isGuiVisible)
        end
    end
end)

-- Hub Name Box (LayoutOrder 4 - อยู่ล่างสุด เหมือน Sugar Hub ใน Anime Expeditions)
local hubBox = Instance.new("Frame")
hubBox.Name = "HubBox"
hubBox.Size = UDim2.new(1, 0, 0.15, 0)
hubBox.BackgroundColor3 = Color3.fromRGB(139, 90, 43)
hubBox.BorderSizePixel = 0
hubBox.LayoutOrder = 4
hubBox.Parent = mainFrame

local hubCorner = Instance.new("UICorner")
hubCorner.CornerRadius = UDim.new(0, 10)
hubCorner.Parent = hubBox

local hubStroke = Instance.new("UIStroke")
hubStroke.Color = Color3.fromRGB(70, 45, 22)
hubStroke.Thickness = 3
hubStroke.Parent = hubBox

local hubLabel = Instance.new("TextLabel")
hubLabel.Size = UDim2.new(1, 0, 1, 0)
hubLabel.BackgroundTransparency = 1
hubLabel.Text = "Sugar Hub"
hubLabel.TextColor3 = Color3.fromRGB(245, 222, 179)
hubLabel.TextSize = 80
hubLabel.Font = Enum.Font.GothamBold
hubLabel.TextScaled = true
hubLabel.Parent = hubBox

local hubPadding = Instance.new("UIPadding")
hubPadding.PaddingLeft = UDim.new(0.03, 0)
hubPadding.PaddingRight = UDim.new(0.03, 0)
hubPadding.PaddingTop = UDim.new(0.15, 0)
hubPadding.PaddingBottom = UDim.new(0.15, 0)
hubPadding.Parent = hubLabel

-- Update Status Function (pcall กันพัง ถ้า label ถูก Destroy ไปแล้วจะไม่ทำให้ script ทั้งเส้นตายไปด้วย)
local function updateStatus(text)
    pcall(function()
        statusValueLabel.Text = text
    end)
end

-- ============================================
-- Retry helper: วนจนสำเร็จ ไม่มีเพดานรอบ ไม่มี timeout
-- ============================================
local function retryUntil(label, fn, interval)
    interval = interval or 0.5
    local attempt = 0
    while true do
        attempt = attempt + 1
        local ok, result = pcall(fn)
        if ok and result then
            if attempt > 1 then
                print(("  [OK] %s succeeded on attempt %d"):format(label, attempt))
            end
            return result
        end
        if not ok then
            warn(("  [WARN] %s error on attempt %d: %s"):format(label, attempt, tostring(result)))
        end
        if attempt % 20 == 0 then
            print(("  ...%s not yet (attempt %d)"):format(label, attempt))
        end
        pcall(updateStatus, ("%s... (%d)"):format(label, attempt))
        task.wait(interval)
    end
end

-- ============================================
-- GLOBAL SHIELD: กล่องล่องหน 6 ด้านคลุมตัวเรา "ตลอดเวลา" (ตั้งแต่เริ่มฟาร์มจนจบ)
-- หุ้ม 4 ด้านข้าง + บน + ล่าง กันมอนประชิดและกระสุน
-- สร้างแบบ WELD ติดกับ HumanoidRootPart => ขยับตาม "ทันที" ในระดับ physics
-- (แม้ FPS เหลือ 5 ก็ตามสนิท เพราะเป็นชิ้นส่วนเดียวกันกับตัวละคร ไม่ต้องรอ loop ขยับ)
-- ============================================
local SHIELD_SIZE = 8     -- ครึ่งรัศมี 4 รอบ HRP = พอดีคลุมหัวถึงเท้า
local SHIELD_THICK = 1
-- shieldSolid = true เปิดกายภาพ 4 ด้านข้าง = "กันมอนเดินเข้ามาหาเรา" (ดันมอนออกนอกโล่)
-- ใช้ตอนอยู่นอก Stronghold (แมพฟาร์ม/แถวกองไฟ) - พอเข้า Stronghold (Step 3.6)
-- สคริปต์จะเรียก setShieldSolid(false) สลับเป็นโหมดโปร่งเอง = ไม่ชนมอน/พื้นห้อง/แท่น
-- กันโล่ไปติดพื้นตอนรอมอนเกิดที่ TriggerZone
-- ทุกโหมด: ด้านบน/ล่างโปร่งเสมอ + ดัก raycast กระสุนได้ (CanQuery = true เสมอ)
local shieldSolid = true

local shieldFolder = nil

local function destroyShield()
    if shieldFolder then
        pcall(function() shieldFolder:Destroy() end)
        shieldFolder = nil
    end
end

local function buildShield()
    destroyShield()

    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not (char and hrp) then return end

    shieldFolder = Instance.new("Folder")
    shieldFolder.Name = "SugarHubShield"

    local half = SHIELD_SIZE / 2
    local t = SHIELD_THICK
    -- กล่องสมมาตรครบ 6 ด้านรอบ HRP: คลุม -4..+4 = หัวจดเท้า (HRP อยู่กลางตัวละคร)
    local faces = {
        {Vector3.new(SHIELD_SIZE, t, SHIELD_SIZE), Vector3.new(0,  half, 0), false}, -- บน
        {Vector3.new(SHIELD_SIZE, t, SHIELD_SIZE), Vector3.new(0, -half, 0), false}, -- ล่าง
        {Vector3.new(t, SHIELD_SIZE, SHIELD_SIZE), Vector3.new( half, 0, 0), true},  -- ขวา
        {Vector3.new(t, SHIELD_SIZE, SHIELD_SIZE), Vector3.new(-half, 0, 0), true},  -- ซ้าย
        {Vector3.new(SHIELD_SIZE, SHIELD_SIZE, t), Vector3.new(0, 0,  half), true},  -- หน้า
        {Vector3.new(SHIELD_SIZE, SHIELD_SIZE, t), Vector3.new(0, 0, -half), true},  -- หลัง
    }

    for i, f in ipairs(faces) do
        local p = Instance.new("Part")
        p.Name = "ShieldFace" .. i
        p.Size = f[1]
        p.Anchored = false       -- ห้าม anchor - weld กับ HRP เพื่อให้ตามทันทีทุกเฟรม
        p.CanCollide = shieldSolid and f[3]
        p.CanQuery = true        -- ให้ raycast กระสุนชนกล่องแทนตัวเรา
        p.CanTouch = false       -- ไม่ไป trigger Touched ของอย่างอื่น
        p.Transparency = 1
        p.Massless = true        -- ไม่เพิ่มน้ำหนัก/แรงกระทบต่อตัวละคร
        p.Material = Enum.Material.SmoothPlastic
        p.CFrame = hrp.CFrame * CFrame.new(f[2])
        p.Parent = shieldFolder

        local weld = Instance.new("WeldConstraint")
        weld.Part0 = hrp
        weld.Part1 = p
        weld.Parent = p
    end

    -- เก็บไว้ในตัวละคร: ตาย/เกิดใหม่ถูกลบไปด้วย ไม่ค้างใน workspace
    shieldFolder.Parent = char
end

-- สลับโหมดโล่: true = ชนมอนได้ (กันมอนเดินเข้ามา), false = โปร่ง (ไม่ชนอะไรเลย แค่ดักกระสุน)
-- เรียกแล้ว rebuild โล่ทันทีถ้ากำลังสร้างอยู่ (ตายเกิดใหม่ก็จะได้โหมดล่าสุดเสมอ)
local function setShieldSolid(enabled)
    if shieldSolid == enabled then return end
    shieldSolid = enabled
    if shieldFolder then
        print("[Shield] Switch mode -> " .. (enabled and "SOLID (block monsters)" or "PHASE (no collision)"))
        buildShield()
    end
end

-- ตายเกิดใหม่ = สร้างโล่ใหม่ให้อัตโนมัติ
LocalPlayer.CharacterAdded:Connect(function(char)
    local hrp = char:WaitForChild("HumanoidRootPart", 10)
    if hrp then
        task.wait(0.2) -- รอ character ตั้งค่าเสร็จก่อน
        buildShield()
    end
end)

print("✅ GUI Loaded")

-- ============================================
-- STEP 1: Check Map and Enter Solo if needed
-- ============================================

local function isLobby()
    return workspace:FindFirstChild("Boards") ~= nil
end

----------------------------------------------------------------
-- Auto-level-up + equip class (Lobby)
-- 1. ถ้ามี UpgradeClass ใน Config → equip class นั้นก่อน (ถ้ามีอยู่แล้ว)
-- 2. เช็ค class ทุกตัวที่ owned → ถ้า CanLevelUp=true → ยิง RequestLevelUpClass
-- 3. ตอนนี้รอบรับแค่ตัวแรกของ UpgradeClass เป็น "main" class
----------------------------------------------------------------
local function lobbyAutoLevelUp()
    local Client = require(LocalPlayer.PlayerScripts.Client)
    local ClassProgress = LocalPlayer:FindFirstChild("ClassProgress")
    if not ClassProgress then
        return
    end

    -- Validate Config.UpgradeClass: ต้องเป็น table ของ string เท่านั้น
    local validClasses = {}
    if Config.UpgradeClass == nil then
        -- ไม่ได้ตั้ง → silent skip
    elseif type(Config.UpgradeClass) ~= "table" then
        warn(string.format("[ClassUpgrade] Config.UpgradeClass is %s (expected table) - skip",
            type(Config.UpgradeClass)))
    else
        for i, v in ipairs(Config.UpgradeClass) do
            if type(v) ~= "string" then
                warn(string.format("[ClassUpgrade] UpgradeClass[%d] is %s (expected string) - skip",
                    i, type(v)))
            else
                table.insert(validClasses, v)
            end
        end
    end

    if #validClasses == 0 then
        -- ไม่มี class ที่ valid → skip ทั้งหมด
        return
    end

    -- 1) Equip class ตามลำดับ UpgradeClass - ข้าม class ที่ Lv.3 แล้ว
    for _, mainClass in ipairs(validClasses) do
        local folder = ClassProgress:FindFirstChild(mainClass)
        if not folder then
            warn("[ClassUpgrade] " .. mainClass .. " not owned")
        else
            local curLvl = folder:GetAttribute("Level") or 1
            if curLvl >= 3 then
                -- skip, ลอง class ถัดไป
            else
                if folder:GetAttribute("Equipped") ~= true then
                    Client.Events.UpdateEquipped:FireServer(mainClass)
                    local t = 0
                    while folder:GetAttribute("Equipped") ~= true and t < 3 do
                        task.wait(0.1); t += 0.1
                    end
                    if folder:GetAttribute("Equipped") ~= true then
                        warn("[ClassUpgrade] equip " .. mainClass .. " timed out (server may not have responded)")
                    end
                end
                break  -- เจอ class ที่ยังไม่ Lv.3 → หยุด
            end
        end
    end

    -- 2) อัปเกรดทุก class ที่ CanLevelUp → รวมเป็นบรรทัดเดียว
    local upgrades = {}
    for _, folder in ipairs(ClassProgress:GetChildren()) do
        if folder:GetAttribute("CanLevelUp") == true and (folder:GetAttribute("Level") or 1) < 3 then
            local cn = folder:GetAttribute("ClassName") or folder.Name
            local fromLv = folder:GetAttribute("Level") or 1
            local ok = pcall(function()
                Client.Events.RequestLevelUpClass:FireServer(cn)
            end)
            if not ok then
                warn("[ClassUpgrade] FireServer(" .. cn .. ") failed")
            end
            task.wait(0.5)
            local toLv = folder:GetAttribute("Level") or 1
            if toLv > fromLv then
                table.insert(upgrades, cn .. " Lv" .. fromLv .. "->Lv" .. toLv)
            else
                warn("[ClassUpgrade] " .. cn .. " still Lv." .. toLv .. " after request (server may not have processed)")
            end
        end
    end

    if #upgrades > 0 then
        local msg = "[ClassUpgrade] " .. table.concat(upgrades, ", ")
        print(msg)
        updateStatus(msg)
    end
end


print("\n[Step 1] Checking current map...")
updateStatus("Checking Map...")

if isLobby() then
    print("Currently in Lobby - Entering Solo map...")
    updateStatus("Entering Solo Map...")

    local Client = require(LocalPlayer.PlayerScripts.Client)

    -- ============================================
    -- Daily Quests & Badges (before entering map)
    -- ============================================

    local function makeInvisible()
        local character = LocalPlayer.Character
        if not character then return end

        for _, part in pairs(character:GetDescendants()) do
            if part:IsA("BasePart") or part:IsA("Decal") then
                part.Transparency = 1
            elseif part:IsA("Accessory") then
                local handle = part:FindFirstChild("Handle")
                if handle then handle.Transparency = 1 end
            end
        end

        local humanoid = character:FindFirstChild("Humanoid")
        if humanoid then
            humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
            humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
        end
    end

    -- Make invisible first
    updateStatus("Preparing...")
    makeInvisible()
    task.wait(0.1)

    local LEVER_PATH = {
        "Boards", "DailyQuest", "MainBoard", "Functional", "Lever",
        "Meshes/dailyquestmachine_Cube.007 (1)",
    }

    local function resolvePath(root, path)
        local node = root
        for _, name in ipairs(path) do
            if not node then return nil end
            node = node:FindFirstChild(name)
        end
        return node
    end

    local function needsRoll()
        -- เทียบ DailyQuests.QuestDay กับ workspace.DailyQuestDay
        local day = workspace:GetAttribute("DailyQuestDay")
        local quests = LocalPlayer:FindFirstChild("DailyQuests")
        if not day or not quests then return false end
        return quests:GetAttribute("QuestDay") ~= day
    end

    local function getRollPrompt()
        local folder = workspace:FindFirstChild("DailyQuests")
        local promptPart = folder and folder:FindFirstChild("PromptPart")
        local attachment = promptPart and promptPart:FindFirstChild("PromptAttachment")
        return attachment and attachment:FindFirstChildWhichIsA("ProximityPrompt"), promptPart
    end

    local function firePrompt(prompt)
        if not prompt or not prompt.Enabled then return false end
        if typeof(fireproximityprompt) == "function" then
            return (pcall(fireproximityprompt, prompt))
        end
        -- fallback สำหรับ executor ที่ไม่มี fireproximityprompt
        pcall(function() prompt.HoldDuration = 0 end)
        prompt:InputHoldBegin()
        task.wait(0.1)
        prompt:InputHoldEnd()
        return true
    end

    local function teleportToLever()
        local hrp = retryUntil("find HumanoidRootPart", function()
            local char = LocalPlayer.Character
            return char and char:FindFirstChild("HumanoidRootPart")
        end, 0.2)

        local pivot = retryUntil("find DailyQuest Lever", function()
            local lever = resolvePath(workspace, LEVER_PATH)
            if not lever then return nil end
            if lever:IsA("BasePart") then return lever.CFrame end
            if lever:IsA("Model") then return lever:GetPivot() end
            return nil
        end, 0.3)

        -- ยืนหน้า lever เยื้องขึ้นกันจมพื้น แล้วหันหน้าเข้าหา
        local standPos = pivot.Position + Vector3.new(0, 3, 5)
        hrp.CFrame = CFrame.lookAt(standPos, pivot.Position)
        task.wait(0.1)
        print("Teleported to lever")
    end

    local function rollDailyQuest()
        if not needsRoll() then
            print("Daily quests already rolled for today")
            return
        end

        print("Rolling daily quests...")
        teleportToLever()

        -- lever กับ prompt อยู่คนละ path เตือนถ้าหลุดระยะกด
        local prompt, promptPart = getRollPrompt()
        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if prompt and hrp and promptPart and promptPart:IsA("BasePart") then
            local dist = (promptPart.Position - hrp.Position).Magnitude
            if dist > prompt.MaxActivationDistance then
                warn(("Prompt out of range after teleport: %.1f > %d"):format(dist, prompt.MaxActivationDistance))
            end
        end

        -- ยิงซ้ำจน QuestDay ตรงกับวันปัจจุบัน ไม่มีเพดาน
        retryUntil("roll daily quest", function()
            if not needsRoll() then return true end
            local p = getRollPrompt()
            if p then firePrompt(p) end
            return not needsRoll()
        end, 0.25)

        print("Roll complete")
    end

    local function claimAllDailyQuestRewards()
        print("Claiming Daily Quest rewards...")
        local DailyQuests = LocalPlayer:FindFirstChild("DailyQuests")
        if not DailyQuests then return end
        for _, quest in ipairs(DailyQuests:GetChildren()) do
            if quest:GetAttribute("Completed") and not quest:GetAttribute("Rewarded") then
                local slot = quest:GetAttribute("QuestNumber")
                if slot then
                    Client.Events.RequestClaimDailyRequestReward:InvokeServer(slot)
                    task.wait(0.1)
                end
            end
        end
    end

    local function claimAllBadges()
        print("Claiming Badges...")
        local Unclaimed = LocalPlayer:FindFirstChild("UnclaimedBadges")
        if not Unclaimed then return end
        local BadgeDB = Client.Databases and Client.Databases.BadgeDatabase
        if not BadgeDB then return end
        for _, badge in pairs(BadgeDB.Badges or {}) do
            if Unclaimed:GetAttribute(tostring(badge.ID)) == true then
                Client.Events.RequestClaimBadgeDiamonds:FireServer(badge.ID)
                task.wait(0.2)
            end
        end
    end

    updateStatus("Rolling Daily Quest...")
    rollDailyQuest()

    updateStatus("Claiming Quest Rewards...")
    claimAllDailyQuestRewards()

    updateStatus("Claiming Badges...")
    claimAllBadges()

    print("Daily Quests & Badges done")

    -- ============================================
    -- Auto-Upgrade + Equip Class (Lobby only - ก่อน Auto-Buy)
    -- 1) Equip main class จาก UpgradeClass[1]
    -- 2) อัปเกรดทุก class ที่ CanLevelUp
    -- ============================================
    updateStatus("Upgrading Classes...")
    lobbyAutoLevelUp()

    -- ============================================
    -- Auto-Buy Class (ก่อนสร้างห้อง)
    -- ============================================
    if Config.BuyClass and #Config.BuyClass > 0 then
        local ClassProgress = LocalPlayer:FindFirstChild("ClassProgress")
        if ClassProgress then
            local ReplicatedStorage = game:GetService("ReplicatedStorage")
            local Shop = ReplicatedStorage:FindFirstChild("Shop")

            if Shop then
                local Classes = Shop:FindFirstChild("Classes")

                if Classes then
                    local Client = require(LocalPlayer.PlayerScripts.Client)

                    -- เช็ค stock แบบเดียวกับ UI (decompile ClassesClient): InStock<UserId> ทับ InStock
                    local function isInStock(clsFolder)
                        local s = clsFolder:GetAttribute("InStock")
                        local mine = clsFolder:GetAttribute("InStock" .. LocalPlayer.UserId)
                        if mine ~= nil then s = mine end
                        return s == true
                    end

                    -- คืนรายชื่อ class ที่ยังขาด = ไม่ owned และไม่อยู่ใน stock
                    local function wantedStillNeeded()
                        local need = {}
                        for _, className in ipairs(Config.BuyClass) do
                            if not ClassProgress:FindFirstChild(className) then
                                local folder = Classes:FindFirstChild(className)
                                if not (folder and isInStock(folder)) then
                                    table.insert(need, className)
                                end
                            end
                        end
                        return need
                    end

                    -- ============================================
                    -- Auto-Reroll Shop (Config.RerollShop + Config.MaxRerollPrice)
                    -- เปิดได้เมื่อ: RerollShop = true "และ" มี BuyClass เท่านั้น
                    -- - เช็คราคา class ที่ต้องการจาก ClassesDatabase ก่อน (เช่น Cyborg=600, Vampire=500)
                    -- - ถ้าของครบแล้ว (owned/อยู่ใน stock) = ไม่สุ่มเลย
                    -- - สุ่มแล้วเจอตัวที่ต้องการ = ซื้อทันที แล้วค่อยสุ่มหาตัวที่เหลือต่อ
                    -- - หยุดสุ่มเมื่อ: ราคาสุ่ม > MaxRerollPrice หรือ
                    --   หักราคาสุ่มแล้วเพชรไม่พอซื้อตัวถูกสุดที่ยังขาด
                    --   (= สุ่มไปก็ซื้อไม่ได้ ให้ไปฟาร์มต่อ)
                    -- ============================================
                    if Config.RerollShop then
                        -- ราคา class ที่ต้องการจาก ClassesDatabase (ClassList[ชื่อ].Price)
                        local classPrices = {}
                        do
                            local db = Client.Databases and Client.Databases.ClassesDatabase
                            local list = db and db.ClassList
                            if list then
                                for _, className in ipairs(Config.BuyClass) do
                                    local entry = list[className]
                                    local p = entry and tonumber(entry.Price)
                                    if p then
                                        classPrices[className] = p
                                    else
                                        print("[Reroll] No price for " .. className .. " in ClassesDatabase")
                                    end
                                end
                            else
                                warn("[Reroll] ClassesDatabase not found - skipping reroll")
                            end
                        end

                        -- ราคาหลังส่วนลด (attribute Discount บน folder class - ตาม decompile AttemptPurchase)
                        local function effectivePrice(className)
                            local base = classPrices[className]
                            if not base then return nil end
                            local folder = Classes:FindFirstChild(className)
                            local disc = (folder and folder:GetAttribute("Discount")) or 0
                            if disc > 0 then
                                return math.max(math.round(base - base * (disc / 100)), 1)
                            end
                            return base
                        end

                        -- ซื้อทันทีทุกตัวที่อยู่ใน stock และมีเพชรพอ
                        -- (เตือน "เพชรไม่พอ" แค่ครั้งเดียวต่อ class กันสแปมทุกรอบ)
                        local lowDiamondWarned = {}

                        local function buyInStockNow()
                            for _, className in ipairs(Config.BuyClass) do
                                if not ClassProgress:FindFirstChild(className) then
                                    local folder = Classes:FindFirstChild(className)
                                    if folder and isInStock(folder) then
                                        local p = effectivePrice(className)
                                        local diamonds = LocalPlayer:GetAttribute("Diamonds") or 0
                                        if p == nil or diamonds >= p then
                                            print(string.format("[Reroll] %s in stock (%s) - buying",
                                                className, tostring(p)))
                                            updateStatus("Buying: " .. className)
                                            Client.Events.RequestPurchaseClass:FireServer(className)
                                            -- รอยืนยันว่า owned จริง (กันยิงซ้ำเสียเพชร)
                                            local vt = 0
                                            while vt < 2 and not ClassProgress:FindFirstChild(className) do
                                                task.wait(0.1)
                                                vt += 0.1
                                            end
                                        elseif not lowDiamondWarned[className] then
                                            lowDiamondWarned[className] = true
                                            print(string.format("[Reroll] %s in stock but low diamonds (%d/%s)",
                                                className, diamonds, tostring(p)))
                                        end
                                    end
                                end
                            end
                        end

                        -- ราคาถูกสุดของตัวที่ยังขาด (ไม่ owned ไม่ใน stock) - nil ถ้าไม่รู้ราคาตัวไหนเลย
                        local function minMissingPrice()
                            local minP
                            for _, className in ipairs(Config.BuyClass) do
                                if not ClassProgress:FindFirstChild(className) then
                                    local folder = Classes:FindFirstChild(className)
                                    if not (folder and isInStock(folder)) then
                                        local p = effectivePrice(className)
                                        if p and (not minP or p < minP) then
                                            minP = p
                                        end
                                    end
                                end
                            end
                            return minP
                        end

                        local need = wantedStillNeeded()
                        if #need == 0 then
                            print("[Reroll] All wanted classes owned/in stock - no rolls needed")
                        elseif next(classPrices) == nil then
                            print("[Reroll] No prices known for wanted classes - skipping reroll")
                        else
                            -- สรุปราคา + ตัวที่ยังขาดในบรรทัดเดียว
                            local pricesStr = {}
                            for _, className in ipairs(Config.BuyClass) do
                                table.insert(pricesStr, className .. "=" .. tostring(classPrices[className] or "?"))
                            end
                            print("[Reroll] Starting | missing: " .. table.concat(need, ", ")
                                .. " | prices: " .. table.concat(pricesStr, ", "))
                            updateStatus("Rerolling Shop...")
                            if not Config.MaxRerollPrice then
                                print("[Reroll] WARN: MaxRerollPrice not set - limited only by diamonds")
                            end

                            local rerollRemote = ReplicatedStorage.RemoteEvents
                                and ReplicatedStorage.RemoteEvents:FindFirstChild("RerollShop")

                            if not rerollRemote then
                                warn("[Reroll] RerollShop remote not found - skipping")
                            else
                                -- จับ event ที่ server ปฏิเสธ (สุ่มใกล้รอบ rotate)
                                local cantReroll = false
                                pcall(function()
                                    Client.Events.CantRerollNow:Connect(function()
                                        cantReroll = true
                                    end)
                                end)

                                local function snapEqual(a, b)
                                    for k, v in pairs(a) do if b[k] ~= v then return false end end
                                    for k in pairs(b) do if a[k] == nil then return false end end
                                    return true
                                end

                                -- นับ roll ติดกันที่ stock ไม่เปลี่ยน (3 ครั้ง = เลิกสุ่ม)
                                local timeoutStreak = 0
                                -- นับครั้งที่โดน server block ติดกัน (6 ครั้ง = เลิกสุ่ม)
                                local blockStreak = 0

                                while true do
                                    -- 1) ซื้อทันทีทุกตัวที่อยู่ใน stock และเพชรพอ (เช่นสุ่มได้ Vampire ก็ซื้อ Vampire ก่อน)
                                    buyInStockNow()

                                    -- 2) ยังขาดอยู่ไหม
                                    local stillNeed = wantedStillNeeded()
                                    if #stillNeed == 0 then
                                        print("[Reroll] ✅ All wanted classes obtained - done")
                                        updateStatus("✅ Reroll Success!")
                                        break
                                    end

                                    -- 3) ราคาสุ่มรอบนี้
                                    local price = LocalPlayer:GetAttribute("RerollPrice")
                                    if type(price) ~= "number" then
                                        task.wait(0.5)
                                        price = LocalPlayer:GetAttribute("RerollPrice")
                                    end
                                    if type(price) ~= "number" then
                                        warn("[Reroll] Cannot read RerollPrice - stopping")
                                        break
                                    end

                                    -- 4) ลิมิตราคาสุ่มจาก Config
                                    if type(Config.MaxRerollPrice) == "number" and price > Config.MaxRerollPrice then
                                        print(string.format("[Reroll] Roll price %d > limit %d - stopping",
                                            price, Config.MaxRerollPrice))
                                        updateStatus(string.format("Reroll %d > %d - Stop",
                                            price, Config.MaxRerollPrice))
                                        break
                                    end

                                    -- 5) เช็คว่าสุ่มแล้วคุ้มไหม: เพชร - ค่าสุ่ม ต้อง >= ราคาตัวถูกสุดที่ยังขาด
                                    --    (เช่น มี 510 ค่าสุ่ม 15 => เหลือ 495 < ราคา Vampire 500 = สุ่มไปก็ซื้อไม่ได้ ไปฟาร์มต่อ)
                                    local diamonds = LocalPlayer:GetAttribute("Diamonds") or 0
                                    if diamonds < price then
                                        print(string.format("[Reroll] Diamonds %d < roll cost %d - farming instead",
                                            diamonds, price))
                                        updateStatus("No diamonds for reroll - farming...")
                                        break
                                    end
                                    local minNeed = minMissingPrice()
                                    if minNeed and (diamonds - price) < minNeed then
                                        print(string.format(
                                            "[Reroll] After roll cost: %d left < cheapest needed (%d) - farming instead",
                                            diamonds - price, minNeed))
                                        updateStatus("Can't afford after roll - farming...")
                                        break
                                    end

                                    -- 6) snapshot stock ก่อนยิง
                                    local before = {}
                                    for _, cls in ipairs(Classes:GetChildren()) do
                                        before[cls.Name] = tostring(isInStock(cls))
                                    end

                                    cantReroll = false
                                    local ok = pcall(function() rerollRemote:FireServer() end)
                                    if not ok then
                                        warn("[Reroll] FireServer failed - stopping")
                                        break
                                    end

                                    -- 7) รอผล: stock เปลี่ยน / โดน block / timeout 6 วิ
                                    local settled = false
                                    local waited = 0
                                    while waited < 6 do
                                        task.wait(0.25)
                                        waited += 0.25
                                        local after = {}
                                        for _, cls in ipairs(Classes:GetChildren()) do
                                            after[cls.Name] = tostring(isInStock(cls))
                                        end
                                        if not snapEqual(before, after) then
                                            settled = true
                                            break
                                        end
                                        if cantReroll then
                                            blockStreak += 1
                                            if blockStreak >= 6 then
                                                print("[Reroll] Still blocked after 6 tries - stopping")
                                                updateStatus("Can't Reroll Now - stopping")
                                                settled = true
                                                break
                                            end
                                            print("[Reroll] Blocked near rotate - waiting 5s")
                                            updateStatus("Can't Reroll Now - waiting...")
                                            task.wait(5)
                                            settled = true
                                            break
                                        end
                                    end
                                    if not settled then
                                        timeoutStreak += 1
                                        if timeoutStreak >= 3 then
                                            print("[Reroll] Stock not changing after 3 rolls - stopping")
                                            break
                                        end
                                    else
                                        timeoutStreak = 0
                                        blockStreak = 0
                                        updateStatus("Rerolling...")
                                    end
                                    task.wait(0.3)
                                end
                            end
                        end
                    end

                    updateStatus("Buying Classes...")

                    local totalClasses = #Config.BuyClass
                    local ownedCount = 0
                    local outOfStock = {}

                    for _, className in ipairs(Config.BuyClass) do
                        if not ClassProgress:FindFirstChild(className) then
                            local classFolder = Classes:FindFirstChild(className)
                            if classFolder then
                                local inStock = isInStock(classFolder)
                                if inStock then
                                    print(string.format("[Auto-Buy] Buying: %s", className))
                                    updateStatus(string.format("Buying: %s", className))
                                    Client.Events.RequestPurchaseClass:FireServer(className)
                                    task.wait(0.5)
                                    if ClassProgress:FindFirstChild(className) then
                                        print(string.format("[Auto-Buy] Bought: %s", className))
                                    else
                                        warn(string.format("[Auto-Buy] Buy %s failed (server may not have processed)", className))
                                    end
                                else
                                    print(string.format("[Auto-Buy] %s out of stock", className))
                                    table.insert(outOfStock, className)
                                end
                            else
                                warn(string.format("[Auto-Buy] Class folder not found: %s", className))
                            end
                        else
                            ownedCount = ownedCount + 1
                        end
                    end

                    task.wait(2)

                    -- Count owned classes after purchase
                    ownedCount = 0
                    for _, className in ipairs(Config.BuyClass) do
                        if ClassProgress:FindFirstChild(className) then
                            ownedCount = ownedCount + 1
                        end
                    end

                    updateStatus(string.format("Classes: %d/%d", ownedCount, totalClasses))

                    local allOwned = ownedCount == totalClasses

                    if allOwned then
                        updateStatus("All Classes Owned")
                        if CheckGoals() then
                            updateStatus("Goals Complete - DONE Sent")
                            return  -- หยุดทันที ไม่สร้างห้อง
                        end
                    elseif #outOfStock > 0 then
                        updateStatus("Out of Stock")
                        task.wait(2)
                    end
                else
                    warn("Auto-Buy: Classes folder not found")
                end
            else
                warn("Auto-Buy: Shop not found")
            end
        else
            warn("Auto-Buy: ClassProgress not found")
        end
    end

    -- Check if goals are already met before entering farm map
    if CheckGoals() then
        updateStatus("Goals Complete - DONE Sent")
        return  -- หยุดทันที ไม่สร้างห้อง
    end

    -- Solo Teleport Logic
    updateStatus("Entering Solo Map...")

    -- นับผู้เล่น "อื่น" ที่ยืนอยู่ในวง BeamPart ของ Teleporter หมายเลข num
    -- คืน math.huge ถ้าหา BeamPart ไม่เจอ = ถือว่าไม่ปลอดภัย (ไม่ใช้วงนั้น)
    local function countPlayersInBeam(num)
        local tp = workspace:FindFirstChild("Teleporter" .. num)
        local beamPart = tp and tp:FindFirstChild("BeamPart")
        if not beamPart then return math.huge end

        -- รัศมีวงจากขนาด part (เทียบเฉพาะแกน X, Z - ไม่สนความสูง)
        local radius = math.max(beamPart.Size.X, beamPart.Size.Z) / 2

        local count = 0
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                local hrp = player.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local distance = math.sqrt(
                        (hrp.Position.X - beamPart.Position.X)^2 +
                        (hrp.Position.Z - beamPart.Position.Z)^2
                    )
                    if distance <= radius then count += 1 end
                end
            end
        end
        return count
    end

    task.wait(1)
    makeInvisible()

    Client.Events.TeleportEvent:FireServer("Remove")
    task.wait(0.1)

    local teleporters = {
        {num = 1, obj = workspace:FindFirstChild("Teleporter1")},
        {num = 2, obj = workspace:FindFirstChild("Teleporter2")},
        {num = 3, obj = workspace:FindFirstChild("Teleporter3")},
    }

    -- วนลองหาห้องจนกว่าจะเข้าได้จริง (กันเคสมีคนเข้าพร้อมกันแล้ว teleport ล้มเหลว)
    while isLobby() do
        local selectedTeleporter = nil
        while not selectedTeleporter do
            for _, tp in ipairs(teleporters) do
                if tp.obj and countPlayersInBeam(tp.num) == 0 then
                    selectedTeleporter = tp.num
                    print("Found empty Teleporter:", selectedTeleporter)
                    break
                end
            end
            if not selectedTeleporter then
                print("All teleporters busy - waiting...")
                updateStatus("Waiting for Empty Teleporter...")
                task.wait(1)
            end
        end

        Client.Events.TeleportEvent:FireServer("Remove")
        task.wait(0.1)
        Client.Events.TeleportEvent:FireServer("Add", selectedTeleporter)
        task.wait(0.1)
        Client.Events.TeleportEvent:FireServer("Chosen", nil, 1, nil)
        print("Entering Solo map...")
        updateStatus("Loading Map...")

        -- รอสูงสุด 20 วิ - เฝ้าตลอดว่ามีคนอื่นเดินเข้าวง Teleporter ที่เราจองไหม
        -- ถ้ามี = Remove ทิ้งทันทีแล้วไปเลือกวงใหม่ (กันถูกรวมห้องกับคนอื่น)
        local waited = 0
        local TELEPORT_TIMEOUT = 20
        local someoneJoined = false
        while isLobby() and waited < TELEPORT_TIMEOUT do
            waited = waited + 0.1
            if countPlayersInBeam(selectedTeleporter) > 0 then
                someoneJoined = true
                break
            end
            if math.floor(waited) % 5 == 0 and math.abs(waited - math.floor(waited)) < 0.05 then
                print(("Still in Lobby... (%ds)"):format(math.floor(waited)))
            end
            updateStatus(("Loading Map... (%.0fs)"):format(waited))
            task.wait(0.1)
        end

        if someoneJoined and isLobby() then
            print(string.format("Someone entered OUR Teleporter%d (%d player) - re-picking",
                selectedTeleporter, countPlayersInBeam(selectedTeleporter)))
            updateStatus("Teleporter Occupied - Re-picking...")
            Client.Events.TeleportEvent:FireServer("Remove")
            task.wait(1)
        elseif isLobby() then
            warn("Teleport failed or room was taken - retrying...")
            updateStatus("Retrying Teleport...")
            task.wait(0.5)
        end
    end
    print("Successfully entered Farm map!")
    updateStatus("Map Loaded!")
else
    print("Already in Farm map - continuing...")
    updateStatus("Already in Map")
end

task.wait(0.3)

-- ============================================
-- Anti-Share: เช็คผู้เล่นอื่นในแมพฟาร์มตลอดเวลา
-- ถ้ามีคนอื่นอยู่แมพเดียวกับเรา = Teleport กลับ Lobby ทันที
-- (สคริปต์จะถูกรันใหม่ที่ Lobby แล้วสร้างห้องโซโล่ขึ้นมาเอง)
-- ============================================
if game.PlaceId ~= 79546208627805 then
    task.spawn(function()
        local TeleportService = game:GetService("TeleportService")
        task.wait(5) -- ให้แมพโหลดนิ่งๆ ก่อนเช็คครั้งแรก

        while true do
            local others = 0
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= LocalPlayer and plr.Character and plr.Character.Parent then
                    others += 1
                end
            end

            if others > 0 then
                print("[Anti-Share] " .. others .. " other player(s) in farm map - hopping back to lobby")
                updateStatus("Player Detected - Hopping...")
                pcall(function()
                    TeleportService:Teleport(79546208627805, LocalPlayer)
                end)
                task.wait(10) -- กันยิง teleport ซ้ำรัวๆ ตอนยังไม่ย้ายเซิร์ฟ
            end

            task.wait(3)
        end
    end)
end

-- ============================================
-- STEP 2: Start Auto-Eat Food (Continuous Background)
-- ============================================

print("\n[Step 2] Starting continuous auto-eat food...")

task.spawn(function()
    local Client = require(LocalPlayer.PlayerScripts.Client)
    local MAX_HUNGER = 200
    local MIN_HUNGER = 150

    local function getHunger()
        return LocalPlayer:GetAttribute("Hunger") or 100
    end

    local function getHRP()
        local char = LocalPlayer.Character
        return char and char:FindFirstChild("HumanoidRootPart")
    end

    local function getItemPos(item)
        if item:IsA("Model") then
            if item.PrimaryPart then return item.PrimaryPart.Position end
            local part = item:FindFirstChildWhichIsA("BasePart", true)
            return part and part.Position
        elseif item:IsA("BasePart") then
            return item.Position
        end
        return nil
    end

    local function findClosestFood()
        local hrp = getHRP()
        if not hrp then return nil end

        local closest, closestDist = nil, math.huge

        for _, item in ipairs(workspace.Items:GetChildren()) do
            local restore = item:GetAttribute("RestoreHunger")
            if restore and restore > 0 then
                local owner = item:GetAttribute("Owner")
                local interaction = item:GetAttribute("Interaction")
                local skip = false

                if owner and owner ~= LocalPlayer.UserId then skip = true end
                if interaction and interaction ~= "Item" and interaction ~= "Tool" then skip = true end
                if LocalPlayer:GetAttribute("Class") == "Bunny" and item:GetAttribute("HasMeat") then skip = true end

                if not skip then
                    local pos = getItemPos(item)
                    if pos then
                        local dist = (pos - hrp.Position).Magnitude
                        if dist < closestDist then
                            closestDist = dist
                            closest = item
                        end
                    end
                end
            end
        end
        return closest, closestDist
    end

    local function pullItem(item)
        local hrp = getHRP()
        if not hrp then return false end

        local success = pcall(function()
            local StartDrag = ReplicatedStorage.RemoteEvents.RequestStartDraggingItem
            local StopDrag = ReplicatedStorage.RemoteEvents.StopDraggingItem

            StartDrag:FireServer(item)
            task.wait(0.1)

            if item:IsA("Model") then
                item:PivotTo(CFrame.new(hrp.Position))
            else
                item.CFrame = CFrame.new(hrp.Position)
            end

            task.wait(0.1)
            StopDrag:FireServer(item)
        end)
        return success
    end

    local function consumeItem(item)
        if not Client.PlayerHandler.Alive then return false end

        local parent = item.Parent
        item.Parent = ReplicatedStorage.TempStorage

        -- pcall กัน invoke throw (ไอเทมหาย/ย้ายระหว่าง pull): เดิม error ฆ่า coroutine ของ auto-eat ถาวร
        -- และไอเทมค้างใน TempStorage - คืนกลับทุกกรณี
        local ok, result = pcall(function()
            return Client.Events.RequestConsumeItem:InvokeServer(item)
        end)
        if not ok or not (result and result.Success) then
            item.Parent = parent
            return false
        end

        return true
    end

    -- Continuous loop
    while true do
        local currentHunger = getHunger()

        if currentHunger < MIN_HUNGER then
            local food = findClosestFood()
            if food then
                pullItem(food)
                consumeItem(food)
            end
        end

        task.wait(0.2)
    end
end)

print("✅ Auto-Eat Running")

-- ============================================
-- DEATH WATCHER: ตายแล้วรอ 5 วิ กดเล่นใหม่
-- เดิมฟังแค่ Humanoid.Died ซึ่งตอนตาย "ระหว่าง Stronghold" ไม่ยอมฟิง
-- (เกมใช้ระบบเลือด custom - เหมือนมอนที่อ่านเลือดจาก attribute "Health")
-- จึงเช็คหลายสัญญาณพร้อมกันแบบ poll ตลอด:
--   1) Humanoid.Health <= 0          (ตายแบบปกติ)
--   2) attribute "Health" <= 0       บนโมเดลตัวละคร (ระบบเลือด custom)
--   3) attribute "Dead" == true      flag ตายของเกม
--   4) อยู่แมพฟาร์มแต่ Character หายค้าง > 2 วิ (ค้างหน้าจอเลือกเล่นใหม่)
-- ============================================

task.spawn(function()
    local AcceptPlayAgain = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("AcceptPlayAgain")
    local handling = false

    -- รอ character แรกก่อน กัน false positive ตอนสคริปต์เพิ่งเริ่ม/เพิ่งเข้าแมพ
    if not (LocalPlayer.Character and LocalPlayer.Character.Parent) then
        LocalPlayer.CharacterAdded:Wait()
    end

    -- เช็คว่า "ตาย" จากหลายสัญญาณ (สัญญาณไหนเจอก่อนก็ถือว่าตาย)
    local function isDeadNow()
        local char = LocalPlayer.Character
        if not (char and char.Parent) then return false end -- เคสนี้จับใน loop หลักด้วย timer

        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum and hum.Health <= 0 then return true end

        local attrHP = char:GetAttribute("Health")
        if type(attrHP) == "number" and attrHP <= 0 then return true end

        if char:GetAttribute("Dead") == true then return true end

        return false
    end

    local function clickPlayAgain()
        if handling then return end
        handling = true
        print("[DEATH] Character died - waiting 5s then respawning")
        pcall(updateStatus, "Died - Play Again in 5s...")
        task.wait(5)

        -- กดซ้ำจนกว่าจะเกิดใหม่จริง (กันกดครั้งเดียวแล้วหลุด)
        print("Clicking Play Again...")
        for _ = 1, 15 do
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if char and char.Parent and hum and hum.Health > 0 then
                print("[DEATH] Respawned!")
                break
            end
            pcall(updateStatus, "Died - Clicking Play Again...")
            pcall(function() AcceptPlayAgain:FireServer() end)
            task.wait(1)
        end
        handling = false
    end

    -- poll เร็วๆ ตลอดเวลา - จับตายทุกรูปแบบ รวมตอนอยู่ Stronghold
    local missingSince = nil
    while true do
        local char = LocalPlayer.Character
        if char and char.Parent then
            missingSince = nil
            if not handling and isDeadNow() then
                clickPlayAgain()
            end
        elseif game.PlaceId ~= 79546208627805 then
            -- อยู่แมพฟาร์มแต่ Character หายไป = ตายค้างหน้าจอเล่นใหม่
            missingSince = missingSince or os.clock()
            if not handling and os.clock() - missingSince >= 2 then
                missingSince = nil
                print("[DEATH] Character missing in farm map - treating as death")
                clickPlayAgain()
            end
        end
        task.wait(0.25)
    end
end)

print("✅ Death Watcher Running")

-- ============================================
-- HP ZERO WATCHER: เซ็ตเลือดเป็น 0 เฉพาะ "มอน StrongholdEnemy" ตลอดเวลา
-- เช็คจาก attribute "StrongholdEnemy" บนตัวโมเดลใน workspace.Characters
-- (ไม่กรองด้วยชื่อ/ระยะแล้ว - Juggernaut Cultist ฯลฯ มี flag นี้ = true)
-- สำคัญ: บางตัวระบบอ่านเลือดจาก attribute "Health" บนโมเดลหลักเอง ไม่ใช่ Humanoid
-- เลือด 0 = ตายปลอม fight loop จะตีต่อ 1 รอบให้ตายจริง
-- ============================================

-- เช็คว่าโมเดลนี้เป็นมอน Stronghold หรือไม่ (จาก attribute บนโมเดลโดยตรง)
local function isStrongholdEnemy(model)
    if typeof(model) ~= "Instance" or not model.Parent then return false end
    if model:GetAttribute("StrongholdEnemy") ~= true then return false end
    if Players:GetPlayerFromCharacter(model) then return false end
    return true
end

-- เคลียร์เลือดมอน 1 ตัว: เซ็ตทั้ง attribute "Health" บนโมเดลหลัก + Humanoid.Health
-- (Humanoid บางตัวอาจอยู่ลึกในโมเดล ใช้ recursive fallback) - คืน true ถ้าช่องทางไหนเป็น 0
-- ข้อยกเว้น: Deer = ห้ามลดเลือดเด็ดขาด (จัดการด้วย Deer Watcher แทน)
local function zeroEnemyHealth(model)
    if model.Name == "Deer" then return false end
    pcall(function() model:SetAttribute("Health", 0) end)

    local zeroed = model:GetAttribute("Health") == 0
    local hum = model:FindFirstChildOfClass("Humanoid")
        or model:FindFirstChildWhichIsA("Humanoid", true)
    if hum then
        pcall(function() hum.Health = 0 end)
        if hum.Health == 0 then zeroed = true end
    end
    return zeroed
end

task.spawn(function()
    while true do
        local chars = workspace:FindFirstChild("Characters")
        if chars then
            for _, model in ipairs(chars:GetChildren()) do
                if isStrongholdEnemy(model) then
                    local hum = model:FindFirstChildOfClass("Humanoid")
                    local attrHealth = model:GetAttribute("Health")
                    local needsZero = (hum ~= nil and hum.Health > 0)
                        or (attrHealth ~= nil and attrHealth > 0)
                    if needsZero then
                        zeroEnemyHealth(model)
                    end
                end
            end
        end
        task.wait(0.2)
    end
end)

print("✅ HP Zero Watcher Running")

-- ============================================
-- DEER WATCHER: เจอ workspace.Characters.Deer = วาร์ปมันไปไกลๆ แล้วลบโมเดลทิ้งทันที
-- ไม่ลดเลือด Deer (zeroEnemyHealth + findCultists ดักชื่อไว้แล้ว)
-- ถ้า server ส่งมันกลับมาใหม่ = เจอซ้ำ วาร์ป + ลบใหม่ วนแบบนี้ไปเรื่อยๆ
-- ============================================
task.spawn(function()
    while true do
        local chars = workspace:FindFirstChild("Characters")
        local deer = chars and chars:FindFirstChild("Deer")
        if deer then
            pcall(function()
                -- วาร์ปไปไกลๆ ก่อน (สุดยอดขึ้นไป 5000 studs จากตำแหน่งเดิม)
                local farPos
                if deer:IsA("Model") then
                    farPos = deer:GetPivot().Position + Vector3.new(0, 5000, 0)
                    deer:PivotTo(CFrame.new(farPos))
                else
                    local root = deer:FindFirstChild("HumanoidRootPart") or deer.PrimaryPart
                        or deer:FindFirstChildWhichIsA("BasePart")
                    if root then
                        farPos = root.Position + Vector3.new(0, 5000, 0)
                        root.CFrame = CFrame.new(farPos)
                    end
                end
            end)
            task.wait(0.1)
            pcall(function() deer:Destroy() end)
            print("[Deer] Found Deer - warped far away & destroyed")
        end
        task.wait(0.2)
    end
end)

print("✅ Deer Watcher Running")

-- ============================================
-- STEP 3: Farm Trees and Upgrade Fire
-- ============================================

print("\n[Step 3] Starting tree farming and fire upgrade...")
updateStatus("Finding Fire...")

local player = LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
local humanoid = character:WaitForChild("Humanoid")

-- respawn แล้วอัปเดตตัวแปรที่ warp ใช้ ให้เป็นของสดตลอด
player.CharacterAdded:Connect(function(char)
    character = char
    humanoidRootPart = char:WaitForChild("HumanoidRootPart", 10)
    humanoid = char:WaitForChild("Humanoid", 10)
end)

-- เปิดโล่รอบตัวตั้งแต่เริ่มฟาร์ม (weld ติดตัว ตามเราทันทีจนจบเกม)
buildShield()

local mainFire = retryUntil("find MainFire", function()
    local map = workspace:FindFirstChild("Map")
    local camp = map and map:FindFirstChild("Campground")
    return camp and camp:FindFirstChild("MainFire")
end)

local firePart = retryUntil("find Fire part", function()
    return mainFire:FindFirstChildWhichIsA("BasePart", true)
end)

local firePos = firePart.Position
updateStatus("Finding Trees...")

local trees = retryUntil("find Small Tree", function()
    local found = {}
    for _, item in ipairs(workspace:GetDescendants()) do
        if item:GetAttribute("Health") and item.Name == "Small Tree" then
            table.insert(found, item)
        end
    end
    if #found > 0 then return found end
    return nil
end, 1)

updateStatus("Sorting Trees...")

table.sort(trees, function(a, b)
    local posA = a:IsA("Model") and a:GetPivot().Position or a.Position
    local posB = b:IsA("Model") and b:GetPivot().Position or b.Position
    local distA = (posA - firePos).Magnitude
    local distB = (posB - firePos).Magnitude
    return distA < distB
end)

updateStatus("Finding Best Axe...")

local bestAxe = retryUntil("find Axe in Inventory", function()
    local inv = player:FindFirstChild("Inventory")
    if not inv then return nil end

    local best, bestDmg = nil, 0
    for _, tool in ipairs(inv:GetChildren()) do
        local damage = tool:GetAttribute("WeaponResourceDamage")
        if damage and damage > bestDmg then
            bestDmg = damage
            best = tool
        end
    end
    return best
end, 1)

updateStatus("Equipping Axe...")

local Client = require(player.PlayerScripts.Client)

local toolHandle = retryUntil("equip axe", function()
    Client.InventoryHandler.RequestEquipItem(bestAxe)
    for _ = 1, 10 do
        local char = LocalPlayer.Character
        local th = char and char:FindFirstChild("ToolHandle")
        if th and th:FindFirstChild("OriginalItem") then return th end
        task.wait(0.1)
    end
    return nil
end, 0.5)

local axe = toolHandle.OriginalItem.Value

local Event = ReplicatedStorage.RemoteEvents.ToolDamageObject
local ownerId = tostring(player.UserId) .. "_" .. player.UserId

-- ============================================
-- VAMPIRE CLASS HELPERS
-- ============================================
local vampireScythe = LocalPlayer.Inventory
    and LocalPlayer.Inventory:FindFirstChild("Vampire Scythe")
local isVampire = LocalPlayer:GetAttribute("Class") == "Vampire"
local myChar = workspace:WaitForChild(LocalPlayer.Name)

-- ลด HP ตัวเองเหลือ 1 (เรียกก่อนตี ถ้า Quest Lifesteal ยังไม่เสร็จ)
local function keepHPOne()
    local hum = myChar and myChar:FindFirstChildOfClass("Humanoid")
    if hum and hum.Health > 1 then
        pcall(function() hum.Health = 1 end)
    end
end

-- เซ็ต HP กลับ 100 (เรียกเมื่อ Lifesteal Quest เสร็จ)
local function restoreHP()
    local hum = myChar and myChar:FindFirstChildOfClass("Humanoid")
    if hum and hum.Health < 100 then
        pcall(function() hum.Health = 100 end)
    end
end

-- เช็ค Quest LifestealHealing ครบไหม (เฉพาะ stat เดียว - ใช้สำหรับ NightLoop)
-- เช็ค Quest LifestealHealing ครบไหม (เฉพาะ stat เดียว - ใช้สำหรับ NightLoop)
-- ใช้ classStatCache (อัปเดตจาก ClassStatUpdated event) เพราะ ClassProgress มีแค่ใน Lobby
local function isVampireLifestealDone()
    local lvl = LocalPlayer:GetAttribute("ClassLevel") or 1
    local reqs = CLASS_QUESTS["Vampire"] and CLASS_QUESTS["Vampire"][lvl + 1]
    if not reqs or not reqs.LifestealHealing then return true end
    local have = classStatCache["Vampire"]
        and classStatCache["Vampire"]["LifestealHealing"] or 0
    return have >= reqs.LifestealHealing
end

-- หา Monster ที่ตีได้ (ใช้สำหรับ NightLoop)
-- ข้าม: Deer, Owl, Friendly tag, Pet tag, StrongholdEnemy (Cultist)
local SKIP_NAMES = {
    ["Deer"] = true,
    ["Owl"] = true,
}

local function findNightMonsters()
    local list = {}
    local chars = workspace:FindFirstChild("Characters")
    if not chars then return list end

    for _, model in ipairs(chars:GetChildren()) do
        -- ข้ามชื่อที่ห้ามตี
        if not SKIP_NAMES[model.Name] then
            -- ข้าม Cultist (StrongholdEnemy)
            if model:GetAttribute("StrongholdEnemy") ~= true then
                -- ข้าม Friendly/Pet tag
                local hasFactionTag = model:HasTag("Friendly")
                    or model:HasTag("Pet")
                    or model:HasTag("Ally")
                if not hasFactionTag then
                    local hum = model:FindFirstChildOfClass("Humanoid")
                        or model:FindFirstChildWhichIsA("Humanoid", true)
                    if hum and hum.Parent and hum.Health > 0 then
                        table.insert(list, model)
                    end
                end
            end
        end
    end
    return list
end

-- Inline check: มี Cultist เกิดใน Characters ไหม (แทน anyCultistSpawned ที่อยู่ใน local scope)
local function checkAnyCultistSpawned()
    local chars = workspace:FindFirstChild("Characters")
    if not chars then return false end
    for _, c in ipairs(chars:GetChildren()) do
        if isStrongholdEnemy(c) and c:FindFirstChildOfClass("Humanoid") then
            return true
        end
    end
    return false
end

local fireFrame = retryUntil("find MainFire BillboardGui", function()
    local center = mainFire:FindFirstChild("Center")
    local gui = center and center:FindFirstChild("BillboardGui")
    local frame = gui and gui:FindFirstChild("Frame")
    if frame and frame:FindFirstChild("TextLabel") and frame:FindFirstChild("RealTimer") then
        return frame
    end
    return nil
end, 0.3)

local textLabel = fireFrame.TextLabel
local timerLabel = fireFrame.RealTimer

local maxLevel = 7

local function getCurrentLevel()
    local fireText = textLabel.Text

    if fireText:find("FIRE FULLY UPGRADED") or fireText:find("MAP FULLY REVEALED") then
        return maxLevel
    end

    if fireText == "" or fireText:match("^%s*$") then
        return maxLevel
    end

    local levelMatch = string.match(fireText, "level (%d+)")
    return tonumber(levelMatch) or 1
end

local function isTimerExceeded()
    local timerText = timerLabel.Text
    local minutes, seconds = string.match(timerText, "(%d+):(%d+)")

    if minutes and seconds then
        local totalMinutes = tonumber(minutes)
        return totalMinutes >= 20
    end

    return false
end

local warpedItems = {}
local collectedChildren = {}

local CRAFTING_BENCH_ITEMS = {
    ["Bolt"] = true,
    ["Broken Fan"] = true,
    ["Broken Microwave"] = true,
    ["Old Radio"] = true,
    ["Sheet Metal"] = true,
    ["Chair"] = true,
}
local CRAFTING_BENCH_SKIP_FIRE = {}

local function getCraftingTouchZone()
    local bench = workspace:FindFirstChild("Map")
        and workspace.Map:FindFirstChild("Campground")
        and workspace.Map.Campground:FindFirstChild("CraftingBench")
    return bench and bench:FindFirstChild("TouchZone")
end

local function warpItemToTarget(item, targetPos)
    if warpedItems[item] then return end

    task.spawn(function()
        pcall(function()
            local StartDrag = ReplicatedStorage.RemoteEvents.RequestStartDraggingItem
            local StopDrag = ReplicatedStorage.RemoteEvents.StopDraggingItem

            StartDrag:FireServer(item)
            task.wait(0.1)

            if item:IsA("Model") then
                item:PivotTo(CFrame.new(targetPos))
            else
                item.CFrame = CFrame.new(targetPos)
            end

            task.wait(0.1)
            StopDrag:FireServer(item)
        end)
    end)
    warpedItems[item] = true
end

local function warpItemToFire(item)
    warpItemToTarget(item, firePos + Vector3.new(0, 10, 0))
end

local LOST_CHILD_NAMES = {
    "Lost Child",
    "Lost Child2",
    "Lost Child3",
    "Lost Child4",
}
local LOST_CHILD_TOTAL = #LOST_CHILD_NAMES

-- เช็คสถานะเด็กจาก attribute (อ้างอิงจาก decompile ของเกม: KidClueClient/_DinoKidQuestClient/GiveKidItemClient)
-- ยังไม่ช่วย = Lost=true + Interaction="CanBeBagged" / ช่วยแล้ว = Lost=false, Interaction="Befriend"..KidId (+Rescued/Friending)
-- สำคัญ: เด็กที่ช่วยแล้ว "โมเดลไม่หายไปไหน" แค่พลิก attribute - ยิง prompt ใส่ = กด "Ask for Clue" แล้วเกมเด้ง pop-up รัวๆ
local function kidAlreadyRescued(c)
    if c:GetAttribute("Lost") == false then return true end
    local interaction = c:GetAttribute("Interaction")
    if type(interaction) == "string" and string.sub(interaction, 1, 8) == "Befriend" then return true end
    return c:GetAttribute("Rescued") == true or c:GetAttribute("Friending") == true
end

local function kidStillLost(c)
    return c:GetAttribute("Lost") == true and c:GetAttribute("Interaction") == "CanBeBagged"
end

local function collectLostChildren()
    local chars = workspace:FindFirstChild("Characters")
    if not chars then return end

    for _, name in ipairs(LOST_CHILD_NAMES) do
        if not collectedChildren[name] then
            local c = chars:FindFirstChild(name)
            if c then
                if kidAlreadyRescued(c) then
                    -- mark ว่าจบแล้ว (ปลอดภัย: ตัวที่ช่วยแล้วไม่มีวันอยู่ใน ItemBag) - ห้ามยิง prompt
                    collectedChildren[name] = true
                    local count = 0
                    for _ in pairs(collectedChildren) do count += 1 end
                    print(string.format("[LostChild] %s already rescued - skipped (%d/%d)", name, count, LOST_CHILD_TOTAL))
                elseif kidStillLost(c) then
                    local head = c:FindFirstChild("Head")
                    local attachment = head and head:FindFirstChild("ProximityAttachment")
                    local prompt = attachment and attachment:FindFirstChild("ProximityInteraction")
                    if prompt then
                        -- วาร์ปเราไปหาเด็ก แล้วยิง prompt ซ้ำจนกว่าเด็กจะหาย หรือสถานะเปลี่ยน (ถูกช่วยแล้ว)
                        local attempts = 0
                        while chars:FindFirstChild(name) and kidStillLost(c) and attempts < 10 do
                            -- ดึง hrp ใหม่ทุก iteration กันตาย/เกิดใหม่กลางลูป (part เก่าถูกทำลาย = วาร์ปเงียบ)
                            local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                            local root2 = c:FindFirstChild("HumanoidRootPart") or c.PrimaryPart
                            if hrp and root2 then
                                hrp.CFrame = CFrame.new(root2.Position + Vector3.new(0, 2, 0))
                                task.wait(0.1)
                                if prompt.Enabled then
                                    pcall(function()
                                        if typeof(fireproximityprompt) == "function" then
                                            fireproximityprompt(prompt, 0, true)
                                        else
                                            prompt.HoldDuration = 0
                                            prompt:InputHoldBegin()
                                            task.wait(0.05)
                                            prompt:InputHoldEnd()
                                        end
                                    end)
                                end
                            end
                            attempts += 1
                            task.wait(0.2)
                        end
                        if not chars:FindFirstChild(name) then
                            collectedChildren[name] = true
                            local count = 0
                            for _ in pairs(collectedChildren) do count += 1 end
                            print(string.format("[LostChild] Collected %d/%d (%s)", count, LOST_CHILD_TOTAL, name))
                            updateStatus(string.format("Lost Children: %d/%d", count, LOST_CHILD_TOTAL))
                        end
                    end
                end
                -- attribute ยังไม่ยืนยันทั้งสองทาง (ยังไม่ sync) = ข้ามรอบนี้ ไม่ mark ไม่กด
            end
        end
    end
end

local function allChildrenCollected()
    for _, name in ipairs(LOST_CHILD_NAMES) do
        if not collectedChildren[name] then return false end
    end
    return true
end

local function dropAllLostChildren(retryDepth)
    retryDepth = retryDepth or 0 -- เพดานความลึกของ retry: เดิมเรียกซ้ำไม่จำกัด (ลิมิต 5 รอบใน for ไม่มีวันทำงานจริง)
    local inv = LocalPlayer:FindFirstChild("Inventory")
    local oldSack = inv and inv:FindFirstChild("Old Sack")
    if not oldSack then
        warn("Cannot drop children: Old Sack not found in inventory")
        return
    end

    -- วาร์ปไปยืน "ด้านหน้ากองไฟ" (+5 stud = จุดยืนมาตรฐานเดียวกับที่ใช้ทั่วสคริปต์)
    -- แล้วค่อยปล่อยเด็ก (เดิมไปยืนทับกองไฟ +0)
    local targetPos = firePos + Vector3.new(5, 3, 0)
    local warpSuccess, warpErr = pcall(function()
        humanoidRootPart.CFrame = CFrame.new(targetPos)
    end)

    if not warpSuccess then
        warn("Failed to warp to campfire:", warpErr)
        return
    end

    task.wait(0.1)

    -- ตรวจสอบว่าวาร์ปสำเร็จจริง
    local currentPos = humanoidRootPart.Position
    local distance = (currentPos - targetPos).Magnitude
    if distance > 10 then
        warn("Warp to campfire failed! Distance from target:", distance)
        return
    end

    -- เพิ่มเวลารอให้เซิร์ฟเวอร์อัพเดทตำแหน่ง
    task.wait(1.5)

    -- equip sack ก่อนปล่อย
    Client.InventoryHandler.RequestEquipItem(oldSack)
    task.wait(0.3)
    inv = LocalPlayer:FindFirstChild("Inventory")
    oldSack = inv and inv:FindFirstChild("Old Sack")
    if not oldSack then
        warn("Old Sack disappeared after equip attempt")
        return
    end

    local BagDrop = ReplicatedStorage.RemoteEvents.RequestBagDropItem
    local droppedCount = 0
    local droppedNames = {}
    for name in pairs(collectedChildren) do
        table.insert(droppedNames, name)
    end

    -- ปล่อยเด็กทีละตัวด้วยดีเลย์
    for name in pairs(collectedChildren) do
        local bag = LocalPlayer:FindFirstChild("ItemBag")
        local bagChild = bag and bag:FindFirstChild(name)
        if bagChild then
            pcall(function()
                BagDrop:FireServer(oldSack, bagChild, false)
            end)
            droppedCount = droppedCount + 1
            task.wait(0.2) -- ดีเลย์ป้องกัน rate-limiting
        end
    end

    -- รอให้เซิร์ฟเวอร์ประมวลผลการปล่อย
    task.wait(1)

    -- ตรวจสอบว่ากระเป๋าว่างจริงก่อนล้างตาราง
    local bag = LocalPlayer:FindFirstChild("ItemBag")
    local remainingChildren = 0
    if bag then
        for _, child in pairs(bag:GetChildren()) do
            if child:IsA("Model") and table.find(LOST_CHILD_NAMES, child.Name) then
                remainingChildren = remainingChildren + 1
            end
        end
    end

    if remainingChildren == 0 then
        collectedChildren = {}
        print("Successfully dropped all", droppedCount, "children at campfire")
    else
        warn("Some children failed to drop! Remaining:", remainingChildren, "/ Attempted:", droppedCount)
    end

    -- เช็คสถานะ Lost หลังปล่อย: รอ 5 วิ ถ้าเด็กตัวไหนยังขึ้น Lost = เกมไม่ยอมรับการปล่อย
    -- ให้ไปเก็บใหม่แล้วปล่อยรอบใหม่ที่กองไฟ (สูงสุด 5 รอบ กันวนไม่รู้จบ)
    if droppedCount > 0 and #droppedNames > 0 then
        for attempt = 1, 5 do
            task.wait(5)

            local charsNow = workspace:FindFirstChild("Characters")
            local stillLost = {}
            if charsNow then
                for _, name in ipairs(droppedNames) do
                    local c = charsNow:FindFirstChild(name)
                    if c and c:GetAttribute("Lost") == true then
                        table.insert(stillLost, name)
                    end
                end
            end

            if #stillLost == 0 then
                if attempt > 1 then
                    print("[LostChild] All dropped children saved (Lost cleared)")
                end
                break
            end

            warn("[LostChild] Still Lost after 5s: " .. table.concat(stillLost, ", ")
                .. " - recollecting & re-dropping (attempt " .. attempt .. "/5)")
            updateStatus("Lost Child still Lost - recollecting...")

            -- เคลียร์รายชื่อที่ยัง Lost ออกจากตาราง เพื่อให้ collectLostChildren เก็บใหม่ได้
            for _, name in ipairs(stillLost) do
                collectedChildren[name] = nil
            end

            -- เดิมเรียก dropAllLostChildren() แล้ว return ทันที = for attempt ไม่มีวันได้รอบสอง
            -- ส่ง retryDepth ต่อเพื่อให้เพดาน 5 ชั้นมีผลจริง
            if retryDepth >= 5 then
                warn("[LostChild] Retry depth limit (5) reached - giving up for this round")
                break
            end

            collectLostChildren()
            return dropAllLostChildren(retryDepth + 1)
        end
    end

    -- re-equip axe หลังปล่อย
    Client.InventoryHandler.RequestEquipItem(bestAxe)
end

local platform = Instance.new("Part")
platform.Size = Vector3.new(10, 1, 10)
platform.Anchored = true
platform.CanCollide = true
platform.Transparency = 1
platform.Parent = workspace

-- (กำแพงป้องกันเดิมถูกแทนด้วย GLOBAL SHIELD แบบ weld ติดตัวด้านบนแล้ว)
local airHeight = 20
local treeIndex = 1

local function flyAndWarpItems()
    updateStatus("Flying & Warping Items...")

    for radius = 20, 1000, 40 do
        local steps = 50 + math.floor(radius / 40) * 5
        local circumference = 2 * math.pi * radius
        local speed = 1000
        local duration = circumference / speed

        for i = 0, steps do
            local alpha = i / steps
            local angle = alpha * math.pi * 2
            local offsetX = math.cos(angle) * radius
            local offsetZ = math.sin(angle) * radius
            local circlePos = firePos + Vector3.new(offsetX, airHeight, offsetZ)

            humanoidRootPart.CFrame = CFrame.new(circlePos)
            platform.Position = circlePos - Vector3.new(0, 3, 0)

            for _, item in ipairs(workspace.Items:GetChildren()) do
                if not warpedItems[item] and item.Name ~= "Sapling" then
                    if CRAFTING_BENCH_ITEMS[item.Name] or item.Name == "Log" then
                        local tz = getCraftingTouchZone()
                        local tzPos = tz and tz:IsA("BasePart") and tz.Position
                            or (tz and tz:IsA("Model") and tz:GetPivot().Position)
                        if tzPos then
                            warpItemToTarget(item, tzPos + Vector3.new(0, 2, 0))
                        end
                    elseif not CRAFTING_BENCH_SKIP_FIRE[item.Name] and item:GetAttribute("BurnFuel") then
                        warpItemToFire(item)
                    end
                end
            end

            collectLostChildren()

            task.wait(duration / steps)
        end
    end

    print("✅ Flight complete")

    -- Warp back to fire after flight
    humanoidRootPart.CFrame = CFrame.new(firePos + Vector3.new(5, 3, 0))
    platform.Position = firePos + Vector3.new(5, 0, 0)
    task.wait(0.1)

    -- ถ้าเก็บเด็กไม่ครบ ให้บินวนหาใหม่อีกรอบก่อน drop
    if not allChildrenCollected() then
        print("[LostChild] Not all found (" .. LOST_CHILD_TOTAL .. " needed) - searching again with extended range...")
        updateStatus("Searching Lost Children (extended)...")
        for radius = 20, 1500, 40 do
            -- ต้องบินครบรอบก่อน ไม่หยุดกลางคัน
            local steps = 60
            local circumference = 2 * math.pi * radius
            local speed = 1000
            local duration = circumference / speed
            for i = 0, steps do
                local angle = (i / steps) * math.pi * 2
                local circlePos = firePos + Vector3.new(math.cos(angle) * radius, airHeight, math.sin(angle) * radius)
                humanoidRootPart.CFrame = CFrame.new(circlePos)
                platform.Position = circlePos - Vector3.new(0, 3, 0)
                collectLostChildren()
                task.wait(duration / steps)
            end
            -- เช็คหลังครบรอบเท่านั้น
            if allChildrenCollected() then break end
        end
    end

    dropAllLostChildren()

    if isTimerExceeded() then
        return true
    end

    return false
end

updateStatus("Initial Flight...")
flyAndWarpItems()

local currentLevel = getCurrentLevel()
task.wait(0.3)
print(string.format("📊 Current Level: %d", currentLevel))
updateStatus("Upgrading Fire...")

local levelChanged = false
task.spawn(function()
    while currentLevel < maxLevel and not isTimerExceeded() do
        task.wait(0.1)
        local newLevel = getCurrentLevel()
        if newLevel ~= currentLevel then
            currentLevel = newLevel
            levelChanged = true

            if currentLevel >= maxLevel then
                print("🎉 Max level reached!")
                updateStatus("🎉 Fire Complete!")
            else
                print(string.format("🎉 Level changed to %d!", currentLevel))
                updateStatus("Upgrading Fire...")
                humanoidRootPart.CFrame = CFrame.new(firePos + Vector3.new(5, 3, 0))
                platform.Position = firePos + Vector3.new(5, 0, 0)
            end

            if currentLevel >= maxLevel then
                break
            end
        end

        if isTimerExceeded() then
            print("⏰ Timer exceeded 20:00!")
            updateStatus("✅ Fire Complete!")
            break
        end
    end

    if isTimerExceeded() then
        updateStatus("✅ Fire Complete!")
    end
end)

print("🔄 Starting main loop...")
local treesSinceFlight = 0

while currentLevel < maxLevel and not isTimerExceeded() do
    currentLevel = getCurrentLevel()
    if currentLevel >= maxLevel or isTimerExceeded() then
        print("✅ Max level reached")
        updateStatus("✅ Fire Complete!")
        humanoidRootPart.CFrame = CFrame.new(firePos + Vector3.new(5, 3, 0))
        break
    end

    task.wait(0.2)

    if levelChanged then
        levelChanged = false
        treesSinceFlight = 0

        currentLevel = getCurrentLevel()
        if currentLevel >= maxLevel then
            print("✅ Max level reached")
            updateStatus("✅ Fire Complete!")
            humanoidRootPart.CFrame = CFrame.new(firePos + Vector3.new(5, 3, 0))
            break
        end

        print(string.format("🎉 Level increased to %d!", currentLevel))
        updateStatus("Upgrading Fire...")

        local timerExceeded = flyAndWarpItems()

        if timerExceeded or getCurrentLevel() >= maxLevel or isTimerExceeded() then
            print("✅ Max level reached or timer exceeded")
            updateStatus("✅ Fire Complete!")
            humanoidRootPart.CFrame = CFrame.new(firePos + Vector3.new(5, 3, 0))
            break
        end
    else
        if treesSinceFlight >= 3 then
            print(string.format("🔄 Cut 3 trees but level still %d, flying...", currentLevel))
            updateStatus("Flying for Items...")
            treesSinceFlight = 0

            local timerExceeded = flyAndWarpItems()

            if timerExceeded or getCurrentLevel() >= maxLevel or isTimerExceeded() then
                print("✅ Max level reached or timer exceeded")
                updateStatus("✅ Fire Complete!")
                humanoidRootPart.CFrame = CFrame.new(firePos + Vector3.new(5, 3, 0))
                break
            end

            continue
        end

        updateStatus("Cutting Trees...")

        if treeIndex > #trees then
            print("⚠️ No more trees, flying...")
            updateStatus("Finding Trees...")
            flyAndWarpItems()

            if getCurrentLevel() >= maxLevel then
                print("✅ Max level reached")
                updateStatus("✅ Fire Complete!")
                humanoidRootPart.CFrame = CFrame.new(firePos + Vector3.new(5, 3, 0))
                break
            end
        else
            if getCurrentLevel() >= maxLevel then
                print("✅ Max level reached")
                updateStatus("✅ Fire Complete!")
                humanoidRootPart.CFrame = CFrame.new(firePos + Vector3.new(5, 3, 0))
                break
            end

            local tree = trees[treeIndex]
            local treePos = tree:IsA("Model") and tree:GetPivot().Position or tree.Position

            -- วาร์ปไปข้างต้นไม้ 5 studs และหันหน้าเข้าหาต้นไม้
            local cutPos = treePos + Vector3.new(5, 0, 0)
            humanoidRootPart.CFrame = CFrame.lookAt(cutPos, treePos)
            platform.Position = cutPos - Vector3.new(0, 3, 0)

            task.wait(0.1)

            local hitCount = 0
            local failStreak = 0
            -- backstop 500 ตี: กันต้นที่เซิร์ฟปัด damage เงียบๆ จนลูปฟาร์มหลักค้าง
            while tree.Parent and hitCount < 500 do
                if getCurrentLevel() >= maxLevel then
                    print("✅ Max level reached")
                    pcall(updateStatus, "✅ Fire Complete!")
                    humanoidRootPart.CFrame = CFrame.new(firePos + Vector3.new(5, 3, 0))
                    break
                end

                if isTimerExceeded() then
                    print("⏰ Timer exceeded 20:00! (stopped mid-tree)")
                    pcall(updateStatus, "✅ Fire Complete!")
                    humanoidRootPart.CFrame = CFrame.new(firePos + Vector3.new(5, 3, 0))
                    break
                end

                -- อัพเดท axe ทุกครั้งก่อนตี
                local char = LocalPlayer.Character
                local th = char and char:FindFirstChild("ToolHandle")
                local currentAxe = th and th:FindFirstChild("OriginalItem") and th.OriginalItem.Value

                if not currentAxe then
                    warn("Axe lost, re-equipping...")
                    Client.InventoryHandler.RequestEquipItem(bestAxe)
                    task.wait(0.3)
                    char = LocalPlayer.Character
                    th = char and char:FindFirstChild("ToolHandle")
                    currentAxe = th and th:FindFirstChild("OriginalItem") and th.OriginalItem.Value
                    if not currentAxe then
                        warn("Cannot equip axe")
                        break
                    end
                end

                -- ใช้ remote event อย่างเดียว
                local success, err = pcall(function()
                    Event:InvokeServer(tree, currentAxe, ownerId, humanoidRootPart.CFrame, false)
                end)

                if success then
                    failStreak = 0
                else
                    -- เงื่อนไขเดิม (hitCount > 5 and not tree.Parent) ขัดกับเงื่อนไขลูป = เงื่อนไขตาย
                    -- เปลี่ยนเป็นนับ invoke error ติดกัน 5 ครั้งแล้วข้ามต้นนี้
                    failStreak += 1
                    if hitCount == 0 then
                        warn("First hit failed:", err)
                    end
                    if failStreak >= 5 then
                        warn("Tree not taking damage after 5 consecutive failed hits - skipping")
                        break
                    end
                end

                task.wait(0.18)
                hitCount = hitCount + 1
            end

            if tree.Parent and hitCount >= 500 then
                warn("Hit cap (500) reached on one tree - skipping")
            end

            if getCurrentLevel() >= maxLevel or isTimerExceeded() then
                break
            end

            print(string.format("✅ Tree %d destroyed (%d hits)", treeIndex, hitCount))
            treeIndex = treeIndex + 1
            treesSinceFlight = treesSinceFlight + 1

            task.wait(0.1)
        end
    end
end

print("🎉 Fire reached max level!")
updateStatus("✅ Fire Complete!")

-- ปล่อยเด็กทั้งหมดก่อนไป Stronghold (กรณีบินรอบสุดท้ายไม่ได้ drop)
dropAllLostChildren()

-- ============================================
-- STEP 3.5: Check Wood/Scrap, craft bench upgrade + beds
-- ============================================

print("\n[Step 3.5] Checking resources for crafting...")

local CraftEvent = ReplicatedStorage.RemoteEvents.CraftItem
local campground = workspace.Map.Campground

local function getTotalScrap() return campground:GetAttribute("TotalScrap") or 0 end
local function getTotalWood()  return campground:GetAttribute("TotalWood")  or 0 end

local NEED_WOOD  = 50
local NEED_SCRAP = 26

-- หา Wood ที่ขาด: ตัดต้นไม้แล้วดึงไม้ไปโต๊ะคราฟ
if getTotalWood() < NEED_WOOD then
    print("[Step 3.5] Wood insufficient - chopping trees...")
    updateStatus("Chopping trees for Wood...")
    Client.InventoryHandler.RequestEquipItem(bestAxe)
    task.wait(0.3)
    local craftTZ = getCraftingTouchZone()
    local craftPos = craftTZ and (craftTZ:IsA("BasePart") and craftTZ.Position or craftTZ:GetPivot().Position)
    local tIdx = 1
    while getTotalWood() < NEED_WOOD do
        local tree = trees[tIdx]
        if not tree or not tree.Parent then tIdx += 1 continue end
        local treePos = tree:IsA("Model") and tree:GetPivot().Position or tree.Position

        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then
            warn("[Step 3.5] HumanoidRootPart not found - waiting...")
            task.wait(1)
            continue
        end

        Client.InventoryHandler.RequestEquipItem(bestAxe)
        task.wait(0.3)

        -- วาร์ปไปข้างต้นไม้ 5 studs และหันหน้าเข้าหาต้นไม้
        local cutPos = treePos + Vector3.new(5, 0, 0)
        hrp.CFrame = CFrame.lookAt(cutPos, treePos)
        platform.Position = cutPos - Vector3.new(0, 3, 0)

        task.wait(0.1)

        local treeDestroyed = false
        while tree.Parent do
            local char = LocalPlayer.Character
            local th = char and char:FindFirstChild("ToolHandle")
            local currentAxe = th and th:FindFirstChild("OriginalItem") and th.OriginalItem.Value
            if not currentAxe then
                print("[Step 3.5] Axe lost - re-equipping...")
                Client.InventoryHandler.RequestEquipItem(bestAxe)
                task.wait(0.3)
                char = LocalPlayer.Character
                th = char and char:FindFirstChild("ToolHandle")
                currentAxe = th and th:FindFirstChild("OriginalItem") and th.OriginalItem.Value
                if not currentAxe then break end
            end

            hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if not hrp then break end

            local success = pcall(function()
                Event:InvokeServer(tree, currentAxe, ownerId, hrp.CFrame, false)
            end)

            if not success then
                warn("[Step 3.5] Hit failed - tree may be invalid")
            end

            pcall(updateStatus, string.format("Chopping Wood: %d/%d", getTotalWood(), NEED_WOOD))
            task.wait(0.2)

            if not tree.Parent then
                treeDestroyed = true
                break
            end
        end

        hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        -- ดึงไม้ทั้งหมดใน workspace.Items ไปโต๊ะคราฟ
        if craftPos then
            for _, item in ipairs(workspace.Items:GetChildren()) do
                if item.Name == "Log" and not warpedItems[item] then
                    warpItemToTarget(item, craftPos + Vector3.new(0, 2, 0))
                end
            end
        end
        updateStatus(string.format("Chopping Wood: %d/%d", getTotalWood(), NEED_WOOD))
        tIdx += 1
        if tIdx > #trees then break end
    end
    Client.InventoryHandler.RequestEquipItem(bestAxe)
    task.wait(0.3)

    -- วาร์ปกลับไปยืนที่กองไฟ (จุดยืนมาตรฐานข้างกองไฟ) หลังตัดไม้เสร็จ
    local backHrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if backHrp then
        backHrp.CFrame = CFrame.new(firePos + Vector3.new(5, 3, 0))
        platform.Position = firePos + Vector3.new(5, 0, 0)
    end
end

-- หา Scrap ที่ขาด: บินวนหา items แล้วดึงไปโต๊ะคราฟ
if getTotalScrap() < NEED_SCRAP then
    print("[Step 3.5] Scrap insufficient - searching items...")
    updateStatus("Searching Scrap items...")
    local craftTZ2 = getCraftingTouchZone()
    local craftPos2 = craftTZ2 and (craftTZ2:IsA("BasePart") and craftTZ2.Position or craftTZ2:GetPivot().Position)
    for radius = 20, 400, 40 do
        if getTotalScrap() >= NEED_SCRAP then break end
        local steps = 20
        for i = 0, steps do
            if getTotalScrap() >= NEED_SCRAP then break end
            local angle = (i / steps) * math.pi * 2
            local pos = firePos + Vector3.new(math.cos(angle)*radius, airHeight, math.sin(angle)*radius)
            humanoidRootPart.CFrame = CFrame.new(pos)
            if craftPos2 then
                for _, item in ipairs(workspace.Items:GetChildren()) do
                    if not warpedItems[item] and item:GetAttribute("Scrappable") then
                        warpItemToTarget(item, craftPos2 + Vector3.new(0, 2, 0))
                    end
                end
            end
            task.wait(0.1)
        end
    end

    -- วาร์ปกลับไปยืนที่กองไฟหลังค้นหา Scrap เสร็จ (จุดยืนมาตรฐานเหมือนตอนตัดไม้)
    local backHrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if backHrp then
        backHrp.CFrame = CFrame.new(firePos + Vector3.new(5, 3, 0))
        platform.Position = firePos + Vector3.new(5, 0, 0)
    end
end

-- รอจนครบ
local waitCraft = 0
while (getTotalWood() < NEED_WOOD or getTotalScrap() < NEED_SCRAP) and waitCraft < 30 do
    updateStatus(string.format("Waiting resources... Wood:%d/%d Scrap:%d/%d",
        getTotalWood(), NEED_WOOD, getTotalScrap(), NEED_SCRAP))
    task.wait(1)
    waitCraft += 1
end
print(string.format("[Step 3.5] Resources ready: Wood=%d Scrap=%d", getTotalWood(), getTotalScrap()))

-- อัพโต๊ะคราฟ 2 และ 3
updateStatus("Upgrading Crafting Bench 2...")
pcall(function() CraftEvent:InvokeServer("Crafting Bench 2") end)
task.wait(0.5)
updateStatus("Upgrading Crafting Bench 3...")
pcall(function() CraftEvent:InvokeServer("Crafting Bench 3") end)
task.wait(0.5)

-- วางเตียง: หา blueprint nil แล้ว InvokeServer RequestPlaceStructure
local PlaceEvent = ReplicatedStorage.RemoteEvents.RequestPlaceStructure
local alecCircle = workspace.Map.Campground:FindFirstChild("alecCircle")

local function getCirclePositions()
    return {
        Vector3.new(-20, 4, 10),
        Vector3.new(-20, 4, 5),
        Vector3.new(-20, 4, 0),
    }
end

local function findBlueprint(name)
    local inv = LocalPlayer:FindFirstChild("Inventory")
    local bpInv = inv and inv:FindFirstChild(name .. " Blueprint")
    if bpInv then return bpInv end
    if typeof(getnilinstances) ~= "function" then return nil end
    for _, obj in ipairs(getnilinstances()) do
        if obj.Name == name .. " Blueprint" then return obj end
    end
end

local BED_ITEMS = {"Old Bed", "Regular Bed", "Good Bed"}
local usedPositions = {}

for _, bedName in ipairs(BED_ITEMS) do
    updateStatus("Crafting " .. bedName .. "...")
    pcall(function() CraftEvent:InvokeServer(bedName) end)
    task.wait(0.5)

    local bp = nil
    local waited = 0
    while not bp and waited < 5 do
        bp = findBlueprint(bedName)
        task.wait(0.2)
        waited += 0.2
    end

    if bp then
        local placed = false
        local attempts = 0
        -- เพดาน 10 ครั้ง: เดิม while not placed ไม่มีเพดาน = วางไม่สำเร็จถาวรแล้วสคริปต์ค้างที่ Step 3.5 ตลอด
        while not placed and attempts < 10 do
            attempts += 1
            -- re-equip ทุกรอบเผื่อหลุด
            Client.InventoryHandler.RequestEquipItem(bp)
            task.wait(0.3)

            -- เช็คว่า BP หายจาก Inventory = วางสำเร็จแล้ว
            local inv2 = LocalPlayer:FindFirstChild("Inventory")
            if not (inv2 and inv2:FindFirstChild(bedName .. " Blueprint")) then
                placed = true
                print("[Step 3.5] Placed " .. bedName .. " (BP gone)")
                break
            end

            local positions = getCirclePositions()
            for _, pos in ipairs(positions) do
                local alreadyUsed = false
                for _, used in ipairs(usedPositions) do
                    if (pos - used).Magnitude < 3 then alreadyUsed = true break end
                end
                if not alreadyUsed then
                    -- ไม่ต้องวาร์ปตัวเองไปหน้ากองไฟก่อนวางแล้ว - PlaceEvent ส่งพิกัด CFrame ไปเอง
                    pcall(function()
                        local center = alecCircle and select(1, alecCircle:GetBoundingBox()).Position or pos
                        -- ถ้า center อยู่ตรง pos (ระยะแบนระนาบ ~ 0) CFrame.lookAt จะได้ NaN = เซิร์ฟปัดทุกครั้ง วางไม่เคยสำเร็จ
                        local placeCF
                        if (center.X - pos.X) ^ 2 + (center.Z - pos.Z) ^ 2 < 0.05 ^ 2 then
                            placeCF = CFrame.new(pos)
                        else
                            placeCF = CFrame.lookAt(pos, Vector3.new(center.X, pos.Y, center.Z))
                        end
                        PlaceEvent:InvokeServer(bp, {
                            Valid = true,
                            CFrame = placeCF,
                            Position = pos,
                        }, placeCF, nil)
                    end)
                    task.wait(0.3)
                    -- เช็ค BP หายไหม
                    inv2 = LocalPlayer:FindFirstChild("Inventory")
                    if not (inv2 and inv2:FindFirstChild(bedName .. " Blueprint")) then
                        table.insert(usedPositions, pos)
                        placed = true
                        print("[Step 3.5] Placed " .. bedName .. " (BP gone)")
                        break
                    end
                end
            end

            if not placed then
                print(string.format("[Step 3.5] Attempt %d failed for %s - retrying...", attempts, bedName))
                task.wait(0.2)
            end
        end

        if not placed then
            warn("[Step 3.5] Could not place " .. bedName .. " after " .. attempts .. " attempts - skipping")
        end
    else
        warn("[Step 3.5] Blueprint not found for " .. bedName)
    end
    task.wait(0.3)
end

print("[Step 3.5] Crafting complete!")
updateStatus("Crafting done!")

-- platform ต้องอยู่ต่อ เพราะ STEP 3.6/4/5/6 ยังบินและต้องมีแท่นรองใต้เท้า

-- ============================================
-- Shared: Stronghold helpers
-- ============================================

local function getStrongholdRoot()
    local map = workspace:FindFirstChild("Map")
    local landmarks = map and map:FindFirstChild("Landmarks")
    return landmarks and landmarks:FindFirstChild("Stronghold")
end

local function getStrongholdBuilding()
    local sh = getStrongholdRoot()
    return sh and sh:FindFirstChild("Building")
end

local function getStrongholdFunctional()
    local sh = getStrongholdRoot()
    return sh and sh:FindFirstChild("Functional")
end

-- คืน center + size ของ Floor (ใช้ GetBoundingBox เพราะ pivot อาจไม่อยู่กลางจริง)
local function getFloorInfo()
    local building = getStrongholdBuilding()
    if not building then return nil end

    local floor = building:FindFirstChild("Floor") or building:FindFirstChild("Floor", true)
    if not floor then return nil end

    if floor:IsA("Model") then
        local cf, size = floor:GetBoundingBox()
        return cf.Position, size
    elseif floor:IsA("BasePart") then
        return floor.Position, floor.Size
    end
    return nil
end

-- บินวนหา Stronghold ถ้ายังไม่ stream เข้ามา
local function flySearchStronghold()
    local searchRadius = 800
    local searchSteps = 100
    local searchDuration = (2 * math.pi * searchRadius) / 1000

    for i = 0, searchSteps do
        local angle = (i / searchSteps) * math.pi * 2
        local searchPos = firePos + Vector3.new(
            math.cos(angle) * searchRadius,
            airHeight,
            math.sin(angle) * searchRadius
        )
        humanoidRootPart.CFrame = CFrame.new(searchPos)
        platform.Position = searchPos - Vector3.new(0, 3, 0)

        if getStrongholdBuilding() then return true end
        task.wait(searchDuration / searchSteps)
    end
    return getStrongholdBuilding() ~= nil
end

local strongholdFloorPos = nil

local function warpToStrongholdFloor(holdSeconds)
    local center, size = getFloorInfo()

    if not center then
        local building = getStrongholdBuilding()
        if not building then
            warn("[WARN] Stronghold Building not found - skipping warp")
            return false
        end
        warn("⚠️ Floor not found. Children of Building:")
        for _, child in ipairs(building:GetChildren()) do
            print("   -", child.Name, "(" .. child.ClassName .. ")")
        end
        center, size = building:GetPivot().Position, Vector3.new(0, 0, 0)
    end

    local target = center + Vector3.new(0, size.Y / 2 + 5, 0)
    strongholdFloorPos = target

    if platform and platform.Parent then
        platform.Size = Vector3.new(16, 1, 16)
        platform.Position = target - Vector3.new(0, 4, 0)
    end

    local reps = math.max(1, math.floor((holdSeconds or 1) / 0.1))
    for _ = 1, reps do
        humanoidRootPart.CFrame = CFrame.new(target)
        task.wait(0.1)
    end

    print(string.format("✅ Warped to Stronghold Floor: %.1f, %.1f, %.1f", target.X, target.Y, target.Z))
    return true
end

local function getStrongholdTimeRemaining()
    for _, sh in ipairs(CollectionService:GetTagged("Stronghold")) do
        if sh.Name ~= "AlienMothership" then
            local f = sh:FindFirstChild("Functional")
            if f and f:GetAttribute("OpenTime") then
                return f:GetAttribute("OpenTime") - workspace:GetServerTimeNow()
            end
        end
    end
    return nil
end

-- ============================================
-- STEP 3.6: Warp to Stronghold Floor ทันที (ไม่ต้องรอ Stronghold เปิด)
-- ============================================

print("\n[Step 3.6] Warping to Stronghold Floor...")
updateStatus("Warping to Stronghold Floor...")

-- เข้า Stronghold แล้ว = สลับโล่เป็นโหมดโปร่ง (ไม่ชนมอน/พื้น) กันโล่ติดพื้นห้อง/ขวาง TriggerZone
setShieldSolid(false)

retryUntil("find Stronghold Building", function()
    if getStrongholdBuilding() then return true end
    updateStatus("Flying to Find Stronghold...")
    flySearchStronghold()
    return getStrongholdBuilding()
end, 1)

retryUntil("warp to Stronghold Floor", function()
    return warpToStrongholdFloor(2)
end, 1)

----------------------------------------------------------------
-- STEP 3.6b: Equip Laser Cannon + ยิงแทนตี
-- ทำเฉพาะเมื่อ equipped class ตรงกับ Config.UpgradeClass[1]
-- (ตอนนี้ Cyborg ใช้ Laser Cannon, ฆ่า Stronghold enemy ด้วยกระสุน Energy)
-- ตรวจ Energy เต็ม 100 ก่อนยิง, ยิงหลายตัวพร้อมกัน (multi-target ใน 1 นัด)
-- ถ้าไม่มี class ตาม UpgradeClass → ฟาร์มปกติ (ไม่ทำอะไร)
----------------------------------------------------------------
-- Quest table (ฝังในไฟล์ - ไม่เรียก database) ใช้เช็คว่า quest เสร็จหรือยัง
-- Format: [className] = { [level] = { statKey = goal, ... } }
-- (merge เข้ากับ CLASS_QUESTS ที่ hoist ไว้ข้างบน)
do
local _questKeys = {
    Ranger = {
        [2] = { EnemyKills = 80, KidRescues = 10 },
        [3] = { EnemyKills = 200, KidRescues = 35 },
    },
    Medic = {
        [2] = { RevivePlayers = 25, FindMeds = 30 },
        [3] = { RevivePlayers = 40, FindMeds = 50 },
    },
    Assassin = {
        [2] = { TravelStuds = 2500, PerfectKills = 100 },
        [3] = { TravelStuds = 10000, PerfectKills = 250 },
    },
    Camper = {
        [2] = { FoodCooked = 75, LogsBurned = 200 },
        [3] = { FoodCooked = 150, LogsBurned = 350 },
    },
    Scavenger = {
        [2] = { ScrapScrap = 450, TravelStuds = 2500 },
        [3] = { ScrapScrap = 1000, TravelStuds = 10000 },
    },
    Cook = {
        [2] = { CookMeat = 200, CookStew = 50 },
        [3] = { CookMeat = 400, CookStew = 200 },
    },
    Lumberjack = {
        [2] = { CutTree = 200, PlantSapling = 70 },
        [3] = { CutTree = 500, PlantSapling = 200 },
    },
    Brawler = {
        [2] = { MeleeHit = 350, TakeMeleeHit = 200 },
        [3] = { MeleeHit = 600, Regenerate = 5000 },
    },
    Hunter = {
        [2] = { WolfKills = 120, BunnyKills = 120 },
        [3] = { WolfKills = 250, AlphaWolfKills = 120 },
    },
    Alien = {
        [2] = { AlienTechKills = 150 },
        [3] = { AlienTechKills = 300 },
    },
    Farmer = {
        [2] = { WaterFarmPlots = 40, PickCrops = 200 },
        [3] = { WaterFarmPlots = 80, PickCrops = 500 },
    },
    Blacksmith = {
        [2] = { BuildStructures = 80, UpgradeCraftingBench = 20 },
        [3] = { BuildStructures = 250, UpgradeCraftingBench = 40 },
    },
    ["Base Defender"] = {
        [2] = { BuildDefense = 60, DefenseKills = 80 },
        [3] = { BuildDefense = 150, DefenseKills = 200 },
    },
    Berserker = {
        [2] = { EnemyKillsWhileLow = 50 },
        [3] = { EnemyKillsWhileLow = 150 },
    },
    Fisherman = {
        [2] = { CatchFish = 350, CatchSharks = 5 },
        [3] = { CatchFish = 500, CatchSharks = 15 },
    },
    Pyromaniac = {
        [2] = { EnemyKillsWithFire = 150 },
        [3] = { EnemyKillsWithFire = 400 },
    },
    ["Poison Master"] = {
        [2] = { EnemyKillsWithPoison = 100 },
        [3] = { EnemyKillsWithPoison = 250 },
    },
    ["Big Game Hunter"] = {
        [2] = { ConsumePelt = 50, WolfKills = 70 },
        [3] = { ConsumePelt = 100, WolfKills = 150 },
    },
    Chef = {
        [2] = { FoodCooked = 200, CookSpecialDish = 50 },
        [3] = { FoodCooked = 400, CookSpecialDish = 100 },
    },
    Gambler = {
        [2] = { ChestOpened = 70 },
        [3] = { ChestOpened = 150, RubyChestOpened = 10 },
    },
    Support = {
        [2] = { SupportDamageAbsorbed = 500, SupportBonusDamageDealt = 200 },
        [3] = { SupportDamageAbsorbed = 1500, SupportBonusDamageDealt = 500 },
    },
    ["Fire Bandit"] = {
        [2] = { EnemyKillsWithFire = 100, SetEnemiesOnFire = 200 },
        [3] = { EnemyKillsWithFire = 250, SetEnemiesOnFire = 500 },
    },
    Zookeeper = {
        [2] = { PetsTamed = 30 },
        [3] = { PetsTamed = 60 },
    },
    Beastmaster = {
        [2] = { WolvesSummoned = 50, PetDamageDealt = 5000 },
        [3] = { WolvesSummoned = 100, PetDamageDealt = 15000 },
    },
    Undead = {
        [2] = { Revived = 30 },
        [3] = { Revived = 60 },
    },
    Necromancer = {
        [2] = { CultistsResurrected = 100, PetDamageDealt = 5000 },
        [3] = { CultistsResurrected = 200, PetDamageDealt = 5000 },
    },
    Witch = {
        [2] = { HitPotion = 100 },
        [3] = { HitPotion = 300 },
    },
    Vampire = {
        [2] = { LifestealHealing = 450, DealDamage = 5000 },
        [3] = { LifestealHealing = 1000, DealDamage = 15000 },
    },
    Brute = {
        [2] = { Taunts = 100, DamageBlocked = 800 },
        [3] = { Taunts = 250, DamageBlocked = 2000 },
    },
    Explorer = {
        [2] = { TravelStuds = 2500, ChestOpened = 80 },
        [3] = { TravelStuds = 10000, ChestOpened = 200 },
    },
    ["Gifting Elf"] = {
        [2] = { GivePresent = 40 },
        [3] = { GivePresent = 90 },
    },
    Snowman = {
        [2] = { HitSnowball = 500 },
        [3] = { HitSnowball = 1000 },
    },
    Engineer = {
        [2] = { BuildTurret = 15, TurretKill = 300 },
        [3] = { BuildTurret = 40, TurretKill = 600 },
    },
    Feaster = {
        [2] = { EatStew = 50, TimeOverfed = 1000 },
        [3] = { EatStew = 150, TimeOverfed = 3000 },
    },
    Nightcrawler = {
        [2] = { EnemiesDefeatedInDark = 50 },
        [3] = { EnemiesDefeatedInDark = 150 },
    },
    Grenadier = {
        [2] = { ExplosiveKills = 50 },
        [3] = { ExplosiveKills = 150 },
    },
    Gunslinger = {
        [2] = { TrustyRevolverKills = 250 },
        [3] = { TrustyRevolverKills = 500 },
    },
    Bunny = {
        [2] = { EatCarrots = 200 },
        [3] = { EatCarrots = 400 },
    },
    ["Alien Scientist"] = {
        [2] = { Dissolves = 50 },
        [3] = { Dissolves = 150 },
    },
}
for k, v in pairs(_questKeys) do
    CLASS_QUESTS[k] = v
end
end  -- end of do block (CLASS_QUESTS merge)

local useCannon = false
local cannonTool = nil
local cannonEnergyCost = 75  -- EnergyCost ต่อนัด (จาก CheckEnergy.lua)
-- เกมเก็บ Energy คงเหลือที่ LocalPlayer:GetAttribute("EnergyAmmo")
-- Logic ยิง: 1 นัดใช้ 75 Energy → ต้องมี Energy > 75 ก่อนยิง (เช็ค >= 76)

if type(Config.UpgradeClass) == "table" and type(Config.UpgradeClass[1]) == "string" then
    local equippedClass = LocalPlayer:GetAttribute("Class")
    -- Cannon ใช้ได้เฉพาะ Cyborg (Energy weapon → AlienTechKills quest)
    if equippedClass == "Cyborg" then
        -- เช็ค level: ถ้า Lv.3 แล้ว = เควสครบแล้ว → ฟาร์มปกติด้วยขวาน (no cannon)
        local equippedLevel = LocalPlayer:GetAttribute("ClassLevel") or 1
        if equippedLevel >= 3 then
            print(string.format("[Cannon] %s Lv.%d done, using axe", equippedClass, equippedLevel))
        else
            local inv = LocalPlayer:FindFirstChild("Inventory")
            if inv then
                cannonTool = inv:FindFirstChild("Laser Cannon")
                if cannonTool then
                    useCannon = true
                    updateStatus("Equipping Laser Cannon...")
                    pcall(function()
                        Client.InventoryHandler.RequestEquipItem(cannonTool)
                    end)
                    task.wait(1.0)
                    local char = LocalPlayer.Character
                    local th = char and char:FindFirstChild("ToolHandle")
                    local origItem = th and th:FindFirstChild("OriginalItem") and th.OriginalItem.Value
                    if origItem and origItem.Name == "Laser Cannon" then
                        print("[Cannon] equipped")
                        cannonTool = origItem
                    else
                        warn("[Cannon] equip failed (got " .. tostring(origItem and origItem.Name) .. ")")
                        useCannon = false
                    end
                else
                    warn("[Cannon] Laser Cannon not in Inventory, fallback to axe")
                end
            end
        end
    end
end

-- ฟังก์ชันยิงเฉพาะเมื่อ useCannon=true
-- คืน true ถ้ายิงสำเร็จ (Energy เต็ม + มีเป้า)
local function cannonTryShoot(energyThreshold)
    energyThreshold = energyThreshold or 100
    if not useCannon or not cannonTool then return false end

    local char = LocalPlayer.Character
    if not char then return false end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    local head = char:FindFirstChild("Head")
    if not head then return false end

    -- เช็ค EnergyAmmo คงเหลือ (เกมเก็บที่ LocalPlayer)
    local energy = LocalPlayer:GetAttribute("EnergyAmmo")
    if type(energy) == "number" and energy <= cannonEnergyCost then
        return false  -- Energy ไม่พอ → รอ refill
    end

    -- หา enemy ในรัศมี 200 studs (เฉพาะ Stronghold enemy ที่ยังไม่ตาย)
    local enemies = {}
    local chars = workspace:FindFirstChild("Characters")
    if not chars then return false end
    for _, m in ipairs(chars:GetChildren()) do
        if m:IsA("Model")
            and not Players:GetPlayerFromCharacter(m)
            and m:GetAttribute("Dead") ~= true
            and m:GetAttribute("StrongholdEnemy") == true
            and m:GetAttribute("Tamed") ~= true then
            local pos = m:GetPivot().Position
            if (pos - hrp.Position).Magnitude <= 200 then
                table.insert(enemies, m)
            end
        end
    end

    if #enemies == 0 then return false end

    -- Cluster enemies: จัดกลุ่มตัวที่อยู่ใกล้กัน (<= ExplosionRadius * 1.2)
    -- ถ้ากลุ่มใหญ่เกินไปจนกระจายเกิน AOE → แยกยิงทีละ cluster
    local cannonExplosionRadius = cannonTool:GetAttribute("ExplosionRadius") or 16
    local clusterRadius = cannonExplosionRadius * 1.2
    local clusters = {}

    local function getPos(inst)
        if inst:IsA("Model") then return inst:GetPivot().Position end
        if inst:IsA("BasePart") then return inst.Position end
        return nil
    end

    for _, e in ipairs(enemies) do
        local pos = getPos(e)
        if pos then
            local placed = false
            for _, cluster in ipairs(clusters) do
                if (cluster.center - pos).Magnitude <= clusterRadius then
                    table.insert(cluster.members, e)
                    -- อัปเดต center เป็นค่าเฉลี่ย
                    local sum = cluster.center * cluster.count
                    sum = sum + pos
                    cluster.count = cluster.count + 1
                    cluster.center = sum / cluster.count
                    placed = true
                    break
                end
            end
            if not placed then
                table.insert(clusters, { center = pos, members = { e }, count = 1 })
            end
        end
    end

    -- เอา cluster แรก (ใกล้สุด) — เพื่อให้ยิงทีละกลุ่ม ไม่ใช่ยิงหมดใน 1 นัด
    table.sort(clusters, function(a, b)
        return (a.center - head.Position).Magnitude < (b.center - head.Position).Magnitude
    end)
    local targetCluster = clusters[1]
    local targetEnemies = targetCluster.members

    -- avgPos + dir จาก cluster นี้
    local avgPos = targetCluster.center
    local dir = (avgPos - head.Position).Unit
    -- ป้องกัน NaN + zero vector: ถ้า dir = 0 หรือ NaN ใช้ LookVector แทน
    if dir ~= dir or dir == Vector3.zero then
        dir = head.CFrame.LookVector
        if dir == Vector3.zero then dir = Vector3.new(0, 0, -1) end
    end

    local target = enemies[1]
    local targetPart = target:FindFirstChild("HumanoidRootPart")
        or target:FindFirstChild("Head")
        or target.PrimaryPart
    if not targetPart then return false end

    local pcallOk, pcallErr, serverResult = pcall(function()
        -- ยิง 3 remotes ตรงๆ (ตาม Cobalt log - ไม่ผ่าน ProjectileClass)
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local Remotes = ReplicatedStorage:FindFirstChild("RemoteEvents")
        local RegisterProjectile = Remotes and Remotes:FindFirstChild("RegisterProjectile")
        local ReplicateBullet = Remotes and Remotes:FindFirstChild("ReplicateBullet")
        local ExplosiveDamage = Remotes and Remotes:FindFirstChild("ExplosiveProjectileDamageEnemy")

        if not (RegisterProjectile and ReplicateBullet and ExplosiveDamage) then
            warn("[Cannon] missing remote(s)")
            return
        end

        local speed = cannonTool:GetAttribute("ProjectileSpeed") or 700
        local gravity = cannonTool:GetAttribute("ProjectileGravity") or 0
        local velocity = dir * speed
        local pid = math.floor((tick() * 1000) % 1000000)

        -- 1) RegisterProjectile
        RegisterProjectile:InvokeServer(cannonTool, pid, false)

        -- 2) ReplicateBullet
        ReplicateBullet:FireServer("FireAllClients", pid, {
            ProjectileGravity = gravity,
            HeadPos = head.Position,
            Origin = head.Position,
            Velocity = velocity,
            ProjectileName = "LaserMissile",
        })

        -- 3) ExplosiveProjectileDamageEnemy (AOE) - ใช้ avgPos เป็นจุดระเบิด
        local hitList = {}
        for _, e in ipairs(targetEnemies) do
            if e:IsA("Model") then
                local d = (e:GetPivot().Position - avgPos).Magnitude
                table.insert(hitList, { Model = e, Distance = d })
            elseif e:IsA("BasePart") then
                local d = (e.Position - avgPos).Magnitude
                table.insert(hitList, { Model = e, Distance = d })
            end
        end
        local ownerId = tostring(pid) .. "_" .. tostring(LocalPlayer.UserId)
        local result = ExplosiveDamage:InvokeServer(hitList, pid, ownerId, avgPos)
        return result
    end)
    if not pcallOk then
        warn("[Cannon] shoot failed: " .. tostring(pcallErr))
        return false
    end

    -- เช็คผล: server คืน table {Success=true,...} ถ้าสำเร็จ
    local result = serverResult
    if type(result) == "table" then
        if result.Success == false then
            warn("[Cannon] server refused damage")
            return false
        end
        -- สำเร็จ → นับ enemy ที่ตาย (HP <= 0 หรือ Destroyed)
        local killed = 0
        for _, e in ipairs(targetEnemies) do
            if not e or not e.Parent then
                killed += 1
            elseif e:IsA("Model") then
                local hum = e:FindFirstChildOfClass("Humanoid")
                    or e:FindFirstChildWhichIsA("Humanoid", true)
                if hum and hum.Health <= 0 then
                    killed += 1
                end
            end
        end
        if killed > 0 then
            print(string.format("[Cannon] killed %d/%d", killed, #enemies))
        end
        return true
    end
    return true
end

-- Background: ยิง cannon ตลอดเวลาตอนอยู่ Stronghold (ทำงานขนานกับ main loop)
-- EnergyCost = 75 ต่อนัด (จาก CheckEnergy.lua) - server จะ validate Energy คงเหลือ
if useCannon then
    task.spawn(function()
        while useCannon do
            local shot = cannonTryShoot()
            if not shot then
                task.wait(0.5)  -- ไม่มีเป้า / Energy ไม่พอ → รอ
            else
                task.wait(0.2)  -- ยิงสำเร็จ → cooldown
            end
        end
    end)
end

-- ============================================
-- STEP 3.7: FPS Boost - ลบของที่ไม่ใช้แล้วทิ้ง หลัง Teleport มา Stronghold
-- ============================================
print("\n[Step 3.7] Boosting FPS (cleaning up map/lighting)...")
updateStatus("Boosting FPS...")

do
    -- ลบทุกอย่างใต้ Lighting และ MaterialService ให้เหลือแค่ตัว service เอง
    local lightingTargets = {
        game:GetService("Lighting"),
        game:GetService("MaterialService"),
    }
    for _, parent in ipairs(lightingTargets) do
        pcall(function()
            for _, child in ipairs(parent:GetChildren()) do
                pcall(function() child:Destroy() end)
            end
        end)
    end

    -- ลบของในโฟลเดอร์แมพที่ไม่จำเป็นแล้ว (ยกเว้น Landmarks.Stronghold)
    -- ถ้าเป็น Vampire + Quest LifestealHealing ยังไม่เสร็จ → ไม่ลบ "Ground" + "Characters" (ต้องวาร์ปตีมอนตอนกลางคืน)
    local keepMap = isVampire and not isVampireLifestealDone()
    local map = workspace:FindFirstChild("Map")
    if map then
        local mapFolderNames = {
            "Biomes", "Blockers", "Boundaries", "Campground", "Caves",
            "ExplodableModels", "FishingSpots", "Foliage", "Ground",
            "Landmarks", "MapLandmarks", "MissingKids", "Snow", "Testing", "Water",
        }
        for _, folderName in ipairs(mapFolderNames) do
            -- ข้าม "Ground" ถ้า Vampire ยังทำ Quest อยู่
            if keepMap and folderName == "Ground" then
                continue
            end
            local folder = map:FindFirstChild(folderName)
            if folder then
                pcall(function()
                    for _, child in ipairs(folder:GetChildren()) do
                        -- ห้ามลบ workspace.Map.Landmarks.Stronghold
                        if not (folderName == "Landmarks" and child.Name == "Stronghold") then
                            pcall(function() child:Destroy() end)
                        end
                    end
                end)
            end
        end
    end

    -- ลบทุกอย่างใต้ workspace.Characters (ยกเว้นถ้า Vampire ยังทำ Quest อยู่)
    if not keepMap then
        local chars = workspace:FindFirstChild("Characters")
        if chars then
            pcall(function()
                for _, child in ipairs(chars:GetChildren()) do
                    pcall(function() child:Destroy() end)
                end
            end)
        end
    end

    print("[OK] FPS boost cleanup done")
end

-- จับตำแหน่ง FinalGate ตอนเข้า Stronghold ครั้งแรก ถ้าค่าเปลี่ยน = เคลียร์แล้ว
local function getFinalGatePos()
    local map = workspace:FindFirstChild("Map")
    local landmarks = map and map:FindFirstChild("Landmarks")
    local sh = landmarks and landmarks:FindFirstChild("Stronghold")
    local func = sh and sh:FindFirstChild("Functional")
    local gate = func and func:FindFirstChild("FinalGate")
    if not gate then return nil end

    if gate:IsA("BasePart") then
        return gate.Position
    elseif gate:IsA("Model") then
        return gate:GetPivot().Position
    end

    local part = gate:FindFirstChildWhichIsA("BasePart", true)
    return part and part.Position or nil
end

local finalGateBasePos = retryUntil("find FinalGate", getFinalGatePos, 0.2)

print(string.format("📌 FinalGate base pos: %.2f, %.2f, %.2f",
    finalGateBasePos.X, finalGateBasePos.Y, finalGateBasePos.Z))

-- ============================================
-- STEP 4: Wait for Stronghold to Open
-- ============================================

-- ============================================
-- VAMPIRE NIGHT LOOP (เฉพาะ Class Vampire)
-- ทำ Quest LifestealHealing ตอนกลางคืน
-- ตีด้วย Vampire Scythe + ลด HP ตัวเองเหลือ 1
-- หยุดเมื่อ: Quest ครบ / Stronghold เปิด / ไม่ใช่กลางคืน
-- ============================================
local function vampireNightLoop()
    if not isVampire then return end
    print("[Vampire] Night loop started")
    while isVampire do
        -- Pre-check 1: Quest LifestealHealing ครบ?
        if isVampireLifestealDone() then
            print("[Vampire] Lifesteal quest done, returning to Stronghold")
            restoreHP()
            break
        end

        -- Pre-check 2: Stronghold เปิด?
        if checkAnyCultistSpawned() then
            print("[Vampire] Stronghold opened, returning to Stronghold")
            break
        end

        -- Pre-check 3: State == "Night"?
        if workspace:GetAttribute("State") ~= "Night" then
            task.wait(1)
            continue
        end

        -- หา Monster ที่ไม่ใช่ Cultist
        local monsters = findNightMonsters()
        if #monsters == 0 then
            task.wait(1)
            continue
        end

        -- ตีทีละตัว: ตีซ้ำตัวเดียวจนกว่าจะตาย หรือครบ 100 ที → เปลี่ยนตัว
        local MAX_HITS_PER_TARGET = 100
        for _, monster in ipairs(monsters) do
            if not (monster and monster.Parent) then continue end
            local hrp = LocalPlayer.Character
                and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if not hrp then break end

            local root = monster:FindFirstChild("HumanoidRootPart")
                or monster.PrimaryPart
            if not root then continue end

            -- วาร์ปไปเหนือ
            hrp.CFrame = CFrame.new(root.Position + Vector3.new(0, 10, 0))
                * CFrame.Angles(math.rad(-90), 0, 0)
            task.wait(0.2)

            -- ตีซ้ำตัวเดิมจนกว่าจะตาย หรือครบ 100 ที
            local hitCount = 0
            while monster and monster.Parent and hitCount < MAX_HITS_PER_TARGET do
                -- ลด HP ตัวเองเหลือ 1 (ทุกตี — ต้องทำ Lifesteal)
                keepHPOne()

                -- ตีด้วย Vampire Scythe (ไม่ลดเลือดมอน)
                if vampireScythe then
                    pcall(function()
                        Event:InvokeServer(monster, vampireScythe, ownerId, hrp.CFrame, false)
                    end)
                end
                hitCount = hitCount + 1

                -- เช็ค Quest LifestealHealing ทันที (อาจครบจากการตีตัวนี้)
                if isVampireLifestealDone() then
                    print("[Vampire] Lifesteal quest done, returning to Stronghold")
                    restoreHP()
                    return  -- ออกจาก vampireNightLoop ทันที
                end

                -- เช็คว่ามอนตายหรือยัง (Dead attribute หรือ Humanoid.Health <= 0)
                local npc = monster:FindFirstChild("NPC")
                local isDead = false
                if npc then
                    if npc:GetAttribute("Dead") == true then isDead = true end
                    if npc:IsA("Humanoid") and npc.Health <= 0 then isDead = true end
                end

                if isDead then
                    print("[Vampire] Killed " .. monster.Name .. " after " .. hitCount .. " hits")
                    break  -- ตายแล้ว → ตัวถัดไป
                end

                if hitCount >= MAX_HITS_PER_TARGET then
                    print("[Vampire] " .. monster.Name .. " survived " .. MAX_HITS_PER_TARGET .. " hits, skipping")
                    break  -- ครบ 100 → เปลี่ยนตัว
                end

                task.wait(0.2)
            end
        end

        task.wait(1)
    end

    -- วาร์ปกลับ combatCenter
    local hrp = LocalPlayer.Character
        and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if hrp then
        hrp.CFrame = CFrame.new(combatCenter + Vector3.new(0, HOVER_HEIGHT, 0))
            * CFrame.Angles(math.rad(-90), 0, 0)
    end
    print("[Vampire] Night loop ended, at Stronghold")
end

-- ============================================
-- VAMPIRE HP WATCHER: ลด HP ตัวเองเหลือ 1 ตลอดเวลา
-- ตราบเท่าที่ Quest LifestealHealing ยังไม่เสร็จ
-- เมื่อครบแล้ว → เซ็ต HP กลับ 100 (ครั้งเดียว)
-- ============================================
if isVampire then
    task.spawn(function()
        local hpRestored = false
        while isVampire do
            if isVampireLifestealDone() then
                if not hpRestored then
                    restoreHP()
                    hpRestored = true
                    print("[Vampire] Lifesteal quest done - HP restored to 100")
                end
            else
                hpRestored = false
                keepHPOne()
            end
            task.wait(0.5)
        end
    end)
end

print("\n[Step 4] Waiting for Stronghold to open...")
updateStatus("Waiting for Stronghold...")

while true do
    local remaining = getStrongholdTimeRemaining()

    if not remaining then
        updateStatus("Stronghold Timer Not Found...")
        task.wait(1)
    elseif remaining <= 0 then
        print("✅ Stronghold is OPEN!")
        updateStatus("✅ Stronghold Open!")
        break
    else
        local minutes = math.floor(remaining / 60)
        local seconds = math.floor(remaining % 60)
        updateStatus(string.format("Stronghold: %02d:%02d", minutes, seconds))
        task.wait(1)
    end
end

-- ============================================
-- VAMPIRE: ถ้าเป็น Class Vampire และ LifestealHealing ยังไม่เสร็จ
-- ตี Monster ตอนกลางคืนก่อนเข้า Stronghold (Step 5+)
-- ============================================
if isVampire then
    vampireNightLoop()
end

-- ============================================
-- STEP 5: Warp to Wave1 TriggerZone
-- ============================================

print("\n[Step 5] Warping to Wave1 TriggerZone...")
updateStatus("Warping to TriggerZone...")

-- (โล่ Stronghold แบบเดิมถูกยกเลิก - ใช้ GLOBAL SHIELD แบบ weld ติดตัว
--  ที่สร้างไว้ตอนต้นสคริปต์แทน ซึ่งเปิดตลอดและตามตัวทันทีทุก FPS)

-- ล็อคตัวไม่ให้ตกตลอดเวลา (ดึง character สดทุก tick กัน respawn)
local function getLiveParts()
    local char = LocalPlayer.Character
    if not char or not char.Parent then return nil, nil end
    return char:FindFirstChild("HumanoidRootPart"), char:FindFirstChildOfClass("Humanoid")
end

local triggerZone = retryUntil("find Wave1 TriggerZone", function()
    local functional = getStrongholdFunctional()
    local tz = functional
        and functional:FindFirstChild("EnemyWaves12")
        and functional.EnemyWaves12:FindFirstChild("Wave1")
        and functional.EnemyWaves12.Wave1:FindFirstChild("TriggerZone")
    if tz and tz:IsA("BasePart") then return tz end
    return nil
end, 0.5)

local tzPos = triggerZone.Position - Vector3.new(0, 3, 0)
strongholdFloorPos = tzPos

if platform and platform.Parent then
    platform.Size = Vector3.new(16, 1, 16)
    platform.Position = tzPos - Vector3.new(0, 4, 0)
end

local tzWaitPos = tzPos + Vector3.new(0, 3, 0) -- วาร์ปสูงกว่า TriggerZone 3 studs ตอนรอมอนเกิด ให้ตกลงมาโดน TriggerZone จริงๆ

local function warpToTriggerZone()
    local hrp = getLiveParts()
    if hrp then
        hrp.CFrame = CFrame.new(tzWaitPos)
    end
end

warpToTriggerZone()
task.wait(0.3)
print(string.format("✅ Warped to Wave1 TriggerZone: %.1f, %.1f, %.1f", tzPos.X, tzPos.Y, tzPos.Z))

-- Equip Old Sack เพื่อ trigger TriggerZone แล้วกลับไปใช้ axe เดิม
do
    local inv = LocalPlayer:FindFirstChild("Inventory")
    local oldSack = inv and inv:FindFirstChild("Old Sack")
    if oldSack then
        Client.InventoryHandler.RequestEquipItem(oldSack)
        task.wait(0.5)
    end
    Client.InventoryHandler.RequestEquipItem(bestAxe)
end


-- รอมอนเกิด: ถ้าไม่เกิดภายในเวลาที่กำหนด ให้วาร์ปไป Floor แล้ววาร์ปกลับ TriggerZone ใหม่ วนจนกว่ามอนจะเกิด
do
    local floorCenter = getFloorInfo()
    local floorPos = floorCenter and (floorCenter + Vector3.new(0, 10, 0))

    local function anyCultistSpawned()
        local chars = workspace:FindFirstChild("Characters")
        if not chars then return false end
        for _, c in ipairs(chars:GetChildren()) do
            -- เช็คจาก attribute StrongholdEnemy บนโมเดล (ไม่ใช้ชื่อ/ตำแหน่งแล้ว)
            if isStrongholdEnemy(c) and c:FindFirstChildOfClass("Humanoid") then
                return true
            end
        end
        return false
    end

    local waited = 0
    local WAIT_STEP = 0.2
    local SPAWN_TIMEOUT = 8 -- วิ ที่รอมอนเกิดก่อนจะวาร์ปไป Floor แล้ววาร์ปกลับ

    while not anyCultistSpawned() do
        task.wait(WAIT_STEP)
        waited += WAIT_STEP

        if waited >= SPAWN_TIMEOUT then
            print("[Step 5] Cultist not spawned - warping to Floor then back to TriggerZone")
            updateStatus("Re-warp waiting for spawn...")

            if floorPos then
                local hrp = getLiveParts()
                if hrp then
                    hrp.CFrame = CFrame.new(floorPos)
                end
                task.wait(0.3)
            end

            warpToTriggerZone()
            waited = 0
        end
    end

    print("✅ Cultist spawned!")
end


-- ============================================
-- STEP 6: Fight loop - วาร์ปเข้าไปหา Cultist "ทุกตัว" ทีละตัว ปรับเลือดแล้วตีตัวนั้นจากจุดใกล้
-- ทำครบรอบแล้วตัวไหนยังไม่ตาย = วนทำใหม่อีกรอบ ครบ 2 รอบเต็มยังไม่ตาย
-- = โหมดเก็บตาย: วาร์ป + ปรับเลือดเร็วก่อน "ทุกตี" (ไม่ต้องรอ) ตีซ้ำจนตาย
-- ============================================

print("\n[Step 6] Fighting Cultists in Stronghold...")
updateStatus("Fighting Cultists...")

-- Re-equip axe ก่อนเริ่ม fight เผื่อถูก unequip ระหว่างรอ
do
    Client.InventoryHandler.RequestEquipItem(bestAxe)
    local waited = 0
    while waited < 3 do
        local char = LocalPlayer.Character
        local th = char and char:FindFirstChild("ToolHandle")
        if th and th:FindFirstChild("OriginalItem") then
            axe = th.OriginalItem.Value
            break
        end
        task.wait(0.1)
        waited += 0.1
    end
end

local combatCenter = strongholdFloorPos or humanoidRootPart.Position
local HOVER_HEIGHT = 10       -- ระยะมาตรฐาน: ลอย/วาร์ป "ด้านบน" ของมอน 10 studs (หันหน้าลง)
local ATTACK_INTERVAL = 0.18

-- นับว่า Cultist ตัวไหน "รอด" จาก [วาร์ปเข้าใกล้ + ปรับเลือด + รอ + ตี] ไปแล้วกี่รอบ (weak key กัน memory leak)
-- ครบ FINISH_MODE_AFTER รอบแล้วยังไม่ตาย = เข้าโหมดเก็บตาย: วาร์ป + ปรับเลือดเร็ว (ไม่รอ) + ตี ซ้ำจนตาย
local surviveCounts = setmetatable({}, {__mode = "k"})
local FINISH_MODE_AFTER = 2

-- เช็คมอนที่จะตี: ดูจาก attribute "StrongholdEnemy" บนโมเดลใน workspace.Characters โดยตรง
-- (ยกเลิกการเช็คชื่อ/ระยะ/Floor เดิมทั้งหมด - เชื่อ flag ที่เกม stamp ไว้บนตัวโมเดลเอง)
local function findCultists()
    local list = {}
    local chars = workspace:FindFirstChild("Characters")
    if not chars then return list end
    for _, c in ipairs(chars:GetChildren()) do
        if c.Name == "Deer" then continue end -- Deer ไม่ตี/ไม่ลดเลือด (จัดการโดย Deer Watcher)
        if isStrongholdEnemy(c) then
            local root = c:FindFirstChild("HumanoidRootPart") or c.PrimaryPart or c:FindFirstChildWhichIsA("BasePart")
            local hum = c:FindFirstChildOfClass("Humanoid")
                or c:FindFirstChildWhichIsA("Humanoid", true)
            -- ไม่กรอง Health > 0: เลือด 0 = ตายปลอม ต้องตีต่ออีก 1 รอบถึงตายจริง
            if root and hum then
                table.insert(list, c)
            end
        end
    end
    return list
end

-- ลอยแบบ IY Fly (ไม่ hard-lock): ติด BodyVelocity บน HRP คนเดียวพอ
-- ตัวละครยังเป็น "ปกติ" - มี animation ฟิสิกส์ทำงาน แค่ลอยนิ่งไม่ตก
-- (เดิมใช้ PlatformStand + เคลียร์ velocity ทุกเฟรม = แข็งค้างเป็นหุ่น)
local flyBodyVelocity

local function ensureFlyBody(hrp)
    if not hrp then return end
    -- HRP เปลี่ยนไหม (ตายเกิดใหม่) ถ้าเปลี่ยนสร้างติดใหม่อัตโนมัติ
    if not flyBodyVelocity or not flyBodyVelocity.Parent then
        flyBodyVelocity = Instance.new("BodyVelocity")
        flyBodyVelocity.Name = "SugarHubHover"
        flyBodyVelocity.MaxForce = Vector3.new(9e9, 9e9, 9e9)
        flyBodyVelocity.Velocity = Vector3.zero -- ลอยนิ่ง - แรงนี้สู้แรงโน้มถ่วงเอง
        flyBodyVelocity.Parent = hrp
    end
end

local function destroyFlyBody()
    if flyBodyVelocity then
        flyBodyVelocity:Destroy()
        flyBodyVelocity = nil
    end
end

local lockConn
lockConn = RunService.Heartbeat:Connect(function()
    local hrp = getLiveParts()
    ensureFlyBody(hrp)
end)

-- Stronghold เคลียร์แล้ว = ตำแหน่ง FinalGate เปลี่ยนจากที่จับไว้ตอนแรก
local GATE_MOVE_THRESHOLD = 1     -- ขยับเกิน 1 stud ถือว่าเปลี่ยนจริง
local CLEAR_CONFIRM_COUNT = 3     -- อ่านติดกัน 3 ครั้ง กันค่ากระพริบ
local FIGHT_MIN_SECONDS = 10      -- 10 วิแรกไม่ตรวจ กันประตูขยับตอนเปิดด่าน

local function getFinalGatePart()
    local gate = workspace:FindFirstChild("FinalGate", true)
    if not gate then return nil end
    if gate:IsA("BasePart") then return gate end
    if gate:IsA("Model") then
        return gate.PrimaryPart or gate:FindFirstChildWhichIsA("BasePart", true)
    end
    return nil
end

local fightStart = os.clock()
local clearHits = 0
local gateOrigin = nil

do
    local part = getFinalGatePart()
    if part then gateOrigin = part.Position end
end

local function isStrongholdCleared()
    if os.clock() - fightStart < FIGHT_MIN_SECONDS then
        return false
    end

    local part = getFinalGatePart()
    if not part then
        clearHits = 0
        return false
    end

    -- ถ้าจับตำแหน่งแรกไม่ทัน (ประตู stream มาช้า) จับตอนนี้แล้วเริ่มนับใหม่
    if not gateOrigin then
        gateOrigin = part.Position
        clearHits = 0
        return false
    end

    if (part.Position - gateOrigin).Magnitude > GATE_MOVE_THRESHOLD then
        clearHits = clearHits + 1
    else
        clearHits = 0
    end

    return clearHits >= CLEAR_CONFIRM_COUNT
end

local TOTAL_ROUNDS = 3
local completedRounds = 0

local function doOneRound()
    fightStart = os.clock()
    clearHits = 0
    -- ใช้ตำแหน่ง gate ตอน Stronghold ยังปิด (จับไว้แล้วตอน Step 3.6)
    gateOrigin = finalGateBasePos

    -- รอ Cultist เกิด
    do
        local floorCenter2 = getFloorInfo()
        local floorPos2 = floorCenter2 and (floorCenter2 + Vector3.new(0, 10, 0))

        local function anyCultistSpawned()
            local chars = workspace:FindFirstChild("Characters")
            if not chars then return false end
            for _, c in ipairs(chars:GetChildren()) do
                -- เช็คจาก attribute StrongholdEnemy บนโมเดล (ไม่ใช้ชื่อ/ตำแหน่งแล้ว)
                if isStrongholdEnemy(c) and c:FindFirstChildOfClass("Humanoid") then
                    return true
                end
            end
            return false
        end

        local waited = 0
        local WAIT_STEP = 0.2
        local SPAWN_TIMEOUT = 8
        while not anyCultistSpawned() do
            task.wait(WAIT_STEP)
            waited += WAIT_STEP
            if waited >= SPAWN_TIMEOUT then
                print("[Round " .. completedRounds+1 .. "] Cultist not spawned - warping to Floor then back to TriggerZone")
                updateStatus("Re-warp waiting for spawn...")
                if floorPos2 then
                    local hrp = getLiveParts()
                    if hrp then hrp.CFrame = CFrame.new(floorPos2) end
                    task.wait(0.3)
                end
                warpToTriggerZone()
                waited = 0
            end
        end
        print("✅ Cultist spawned! (round " .. completedRounds+1 .. ")")
    end

    -- Fight loop
    while true do
        if isStrongholdCleared() then
            print("[OK] FinalGate moved -> round " .. completedRounds+1 .. " cleared")
            updateStatus("✅ Round " .. completedRounds+1 .. "/" .. TOTAL_ROUNDS .. " Cleared!")
            break
        end

        local cultists = findCultists()

        if #cultists == 0 then
            local hrp = getLiveParts()
            if hrp then hrp.CFrame = CFrame.new(combatCenter) end
            updateStatus("Waiting for Cultists... (round " .. completedRounds+1 .. ")")
            task.wait(1)
        else
            local hrp = getLiveParts()
            if not hrp then task.wait(0.2) continue end

            -- re-equip axe ก่อนตีทุก tick (เฉพาะตอนไม่ใช้ cannon)
            if not useCannon then
                local char = LocalPlayer.Character
                local th = char and char:FindFirstChild("ToolHandle")
                if not (th and th:FindFirstChild("OriginalItem")) then
                    Client.InventoryHandler.RequestEquipItem(bestAxe)
                    task.wait(0.1)
                    char = LocalPlayer.Character
                    th = char and char:FindFirstChild("ToolHandle")
                    if th and th:FindFirstChild("OriginalItem") then
                        axe = th.OriginalItem.Value
                    end
                end
            end

            -- Phase 1: คำนวณ centroid ของทุก cultist + ความสูงสูงสุด -> วาร์ปจุดเดียว
            -- แล้วลดเลือดทุกตัวพร้อมกัน -> รอ 1 วิ -> ตีทุกตัวพร้อมกัน
            -- (ลดเวลาจาก N iteration เหลือ 1 batch - เร็วขึ้นมาก)
            local validCultists = {}
            local centroid = Vector3.zero
            local maxY = -math.huge
            for _, cultist in ipairs(cultists) do
                if not cultist or not cultist.Parent then continue end
                local root = cultist:FindFirstChild("HumanoidRootPart") or cultist.PrimaryPart
                if not root then continue end
                table.insert(validCultists, cultist)
                centroid = centroid + root.Position
                if root.Position.Y > maxY then maxY = root.Position.Y end
            end

            if #validCultists > 0 then
                centroid = centroid / #validCultists
                -- วาร์ปไปเหนือ centroid ให้สูงกว่าตัวที่สูงที่สุด HOVER_HEIGHT studs
                local warpPos = Vector3.new(centroid.X, maxY + HOVER_HEIGHT, centroid.Z)
                hrp.CFrame = CFrame.new(warpPos) * CFrame.Angles(math.rad(-90), 0, 0)

                updateStatus("Fighting " .. #validCultists .. " Cultists... (round " .. completedRounds+1 .. ")")

                -- รอ 0.2 วิ ก่อนลดเลือด (ให้เซิร์ฟทันเห็น CFrame ใหม่ก่อน)
                task.wait(0.2)

                -- ลดเลือดทุกตัวพร้อมกัน (1 ครั้งต่อตัว) - เร็วกว่าทีละตัวมาก
                -- ทำเสมอ (ทั้ง cannon class และ axe class) - ให้ Cultist ตายเร็ว
                for _, cultist in ipairs(validCultists) do
                    pcall(function() zeroEnemyHealth(cultist) end)
                end

                -- รอ 1 วิ ก่อนโจมตี (ให้เซิร์ฟทันเห็น CFrame ใหม่ + Health=0 replicate)
                task.wait(1)

                -- ตีทุกตัวพร้อมกันจากจุด centroid เดียวกัน
                -- (ถ้า useCannon → skip - background loop ยิงให้แล้ว)
                -- (Vampire: ใช้ Scythe แทน axe + keepHPOne ถ้า Lifesteal ยังไม่เสร็จ)
                if not useCannon then
                    -- เลือก weapon: Scythe ถ้า Vampire, axe ถ้า class อื่น
                    local weapon = (isVampire and vampireScythe) or axe
                    -- keepHPOne ก่อนตี (เฉพาะ Vampire + Lifesteal ยังไม่เสร็จ)
                    if isVampire and weapon and not isVampireLifestealDone() then
                        keepHPOne()
                    end
                    for _, cultist in ipairs(validCultists) do
                        if cultist and cultist.Parent then
                            pcall(function()
                                Event:InvokeServer(cultist, weapon, ownerId, hrp.CFrame, false)
                            end)
                        end
                    end
                end

                -- นับรอบที่ตัวนี้ยังไม่ตาย: ปรับเลือดติด = +1, ปรับเลือดไม่ติด = +2 (ไม่ทำงาน = นับหนัก)
                for _, cultist in ipairs(validCultists) do
                    local attrZero = cultist:GetAttribute("Health") == 0
                    local hum = cultist:FindFirstChildOfClass("Humanoid")
                        or cultist:FindFirstChildWhichIsA("Humanoid", true)
                    local humZero = hum and hum.Parent ~= nil and hum.Health == 0
                    local zeroed = attrZero or humZero
                    surviveCounts[cultist] = (surviveCounts[cultist] or 0) + (zeroed and 1 or 2)
                end
            end

            -- Phase 2: ตัวไหนทำครบ FINISH_MODE_AFTER รอบแล้วยังไม่ตาย
            -- = โหมดเก็บตาย: วาร์ปตามตัวมัน + ปรับเลือดเร็วก่อน "ทุกตี" (ไม่ต้องรอ) ตีซ้ำจนตาย
            for _, cultist in ipairs(cultists) do
                if cultist and cultist.Parent and (surviveCounts[cultist] or 0) >= FINISH_MODE_AFTER then
                    print("[Fight] Cultist survived " .. FINISH_MODE_AFTER
                        .. " full rounds - finish mode: quick zero + hit until dead")
                    while cultist.Parent and not isStrongholdCleared() do
                        local hrp2 = getLiveParts()
                        if not hrp2 then task.wait(0.2) continue end
                        local root2 = cultist:FindFirstChild("HumanoidRootPart") or cultist.PrimaryPart
                        if not root2 then break end

                        -- วาร์ปไปเหนือตัวมัน 10 studs (หันหน้าลง) - มันเดินหนีก็ตามไปตี
                        hrp2.CFrame = CFrame.new(root2.Position + Vector3.new(0, HOVER_HEIGHT, 0))
                            * CFrame.Angles(math.rad(-90), 0, 0)
                        task.wait()

                        -- re-equip axe ถ้าหลุดระหว่างตี
                        local char2 = LocalPlayer.Character
                        local th2 = char2 and char2:FindFirstChild("ToolHandle")
                        if not (th2 and th2:FindFirstChild("OriginalItem")) then
                            Client.InventoryHandler.RequestEquipItem(bestAxe)
                            task.wait(0.1)
                            char2 = LocalPlayer.Character
                            th2 = char2 and char2:FindFirstChild("ToolHandle")
                            if th2 and th2:FindFirstChild("OriginalItem") then
                                axe = th2.OriginalItem.Value
                            end
                        end

                        -- ปรับเลือดก่อนทุกตี (แบบเร็ว ไม่รอ settle) แล้วค่อยตีทันที
                        pcall(function() zeroEnemyHealth(cultist) end)
                        -- เลือก weapon: Scythe ถ้า Vampire
                        local weapon2 = (isVampire and vampireScythe) or axe
                        -- keepHPOne ก่อนตี (Vampire + Lifesteal ยังไม่เสร็จ)
                        if isVampire and weapon2 and not isVampireLifestealDone() then
                            keepHPOne()
                        end
                        pcall(function()
                            Event:InvokeServer(cultist, weapon2, ownerId, hrp2.CFrame, false)
                        end)
                        task.wait(ATTACK_INTERVAL)
                    end
                    surviveCounts[cultist] = nil -- ตายแล้ว (หรือรอบเคลียร์) - เคลียร์ตัวนับ
                end
            end

            -- กลับไปลอยจุดเดิม (เหนือจุดกลาง 10 studs) รอ tick ถัดไป
            hrp.CFrame = CFrame.new(combatCenter + Vector3.new(0, HOVER_HEIGHT, 0))
                * CFrame.Angles(math.rad(-90), 0, 0)

            task.wait(ATTACK_INTERVAL)
        end
    end
end

-- ============================================
-- STEP 6-7: วน 3 รอบ fight + เปิด chest + เก็บเพชร
-- ============================================

-- Flag: ติดเมื่อ quest ของ main class เสร็จแล้ว รอให้ round ปัจจุบันจบ + เก็บเพชรก่อน teleport
local questReadyToLeave = false

-- Quest progress watcher: แสดง % ทุกครั้งที่ quest stat อัปเดต (ทุกที่ - Lobby/Stronghold/ฟาร์ม)
if type(Config.UpgradeClass) == "table" and type(Config.UpgradeClass[1]) == "string" then
    local mainClass = Config.UpgradeClass[1]
    local cp = LocalPlayer:FindFirstChild("ClassProgress")
    local folder = cp and cp:FindFirstChild(mainClass)
    if folder then
        local lastReport = 0
        local function reportQuestProgress()
            -- cooldown 1 วิ กัน spam
            if os.clock() - lastReport < 1 then return end
            lastReport = os.clock()
            local lvl = folder:GetAttribute("Level") or 1
            if lvl >= 3 then return end
            local reqs = CLASS_QUESTS[mainClass] and CLASS_QUESTS[mainClass][lvl + 1]
            if not reqs then return end
            local totalPct, count = 0, 0
            for statKey, goal in pairs(reqs) do
                local have = folder:GetAttribute(statKey) or 0
                if type(have) == "number" and goal > 0 then
                    totalPct = totalPct + math.min(have / goal, 1) * 100
                    count = count + 1
                end
            end
            if count > 0 then
                local avgPct = math.floor(totalPct / count)
                print(string.format("[Quest] %s -> Lv.%d: %d%%", mainClass, lvl + 1, avgPct))
            end
        end
        for statKey, _ in pairs(CLASS_QUESTS[mainClass] and CLASS_QUESTS[mainClass][2] or {}) do
            folder:GetAttributeChangedSignal(statKey):Connect(reportQuestProgress)
        end
        for statKey, _ in pairs(CLASS_QUESTS[mainClass] and CLASS_QUESTS[mainClass][3] or {}) do
            folder:GetAttributeChangedSignal(statKey):Connect(reportQuestProgress)
        end
        reportQuestProgress()  -- แสดงค่าเริ่มต้น
    end
end

while completedRounds < TOTAL_ROUNDS do
    print(string.format("\n[Step 6] Round %d/%d", completedRounds+1, TOTAL_ROUNDS))
    updateStatus(string.format("Round %d/%d - Fighting...", completedRounds+1, TOTAL_ROUNDS))

    -- Re-equip ทุกรอบ: ถ้า useCannon → Laser Cannon, ไม่งั้น axe
    if useCannon and cannonTool then
        pcall(function() Client.InventoryHandler.RequestEquipItem(cannonTool) end)
    else
        Client.InventoryHandler.RequestEquipItem(bestAxe)
    end
    do
        local waited = 0
        while waited < 3 do
            local char = LocalPlayer.Character
            local th = char and char:FindFirstChild("ToolHandle")
            if th and th:FindFirstChild("OriginalItem") then
                local currentTool = th.OriginalItem.Value
                if useCannon and cannonTool and currentTool.Name == "Laser Cannon" then
                    axe = currentTool  -- ใช้ตัวแปร axe ร่วม (เพื่อ compat กับ doOneRound)
                    break
                elseif not useCannon and currentTool == bestAxe then
                    axe = currentTool
                    break
                end
            end
            task.wait(0.1)
            waited += 0.1
        end
    end

    doOneRound()
    completedRounds += 1

    -- เช็ค quest ของ class ที่ equip อยู่ ถ้าครบตาม level → ตั้ง flag (รอจบ loop + เก็บเพชรก่อน)
    if Config.UpgradeClass and Config.UpgradeClass[1] and not questReadyToLeave then
        local mainClass = Config.UpgradeClass[1]
        local isLobby = game.PlaceId == 79546208627805

        -- ใน Lobby: ใช้ ClassProgress folder (อ่านจาก attribute ของ folder - แม่นยำ)
        -- ในแมพฟาร์ม: ใช้ LocalPlayer attribute (folder อาจหาย)
        local level = 1
        local statSource = nil  -- table ที่ใช้อ่าน stat
        if isLobby then
            local cp = LocalPlayer:FindFirstChild("ClassProgress")
            local folder = cp and cp:FindFirstChild(mainClass)
            if folder then
                level = folder:GetAttribute("Level") or 1
                statSource = folder
            end
        else
            level = LocalPlayer:GetAttribute("ClassLevel") or 1
            statSource = classStatCache[mainClass]  -- ดักจาก ClassStatUpdated event
        end

        if statSource then
            local goalLevel = level + 1
            if goalLevel <= 3 then
                local reqs = CLASS_QUESTS[mainClass] and CLASS_QUESTS[mainClass][goalLevel]
                if reqs then
                    local allMet = true
                    for statKey, goal in pairs(reqs) do
                        local have = statSource[statKey] or 0
                        if type(have) ~= "number" or have < goal then
                            allMet = false
                        end
                    end
                    if allMet then
                        questReadyToLeave = true
                        print(string.format("[Quest] %s ready -> Lv.%d, leaving after this round",
                            mainClass, goalLevel))
                        updateStatus("Quest done - finishing round")
                    end
                end
            end
        end
    end

    -- เปิด chest
    print(string.format("\n[Step 7] Opening Diamond Chest (round %d)...", completedRounds))
    updateStatus("Opening Diamond Chest...")

    local chest = retryUntil("find Diamond Chest", function()
        local items = workspace:FindFirstChild("Items")
        return (items and items:FindFirstChild("Stronghold Diamond Chest"))
            or workspace:FindFirstChild("Stronghold Diamond Chest", true)
    end)

    -- chest อาจเป็นชนิดอื่นตอน stream ไม่เสร็จ (ไม่ใช่ Model/BasePart) - index .Position ตรงๆ พัง = สคริปต์หยุดกลาง Step 7
    local chestPos
    for _ = 1, 10 do
        if chest:IsA("Model") then
            chestPos = chest:GetPivot().Position
        elseif chest:IsA("BasePart") then
            chestPos = chest.Position
        else
            local part = chest:FindFirstChildWhichIsA("BasePart", true)
            chestPos = part and part.Position
        end
        if chestPos then break end
        task.wait(0.5)
    end
    if not chestPos then
        -- สรุปตำแหน่งไม่ได้จริง = ใช้จุดกองไฟแทน (รอบนี้หาเพชรไม่เจอ แต่ flow เดินต่อได้ ไม่ error ตาย)
        warn("[Step 7] Cannot resolve Diamond Chest position - falling back to fire position")
        chestPos = firePos
    end
    if platform and platform.Parent then
        platform.Size = Vector3.new(10, 1, 10)
        platform.Position = chestPos - Vector3.new(0, 3, 0)
    end
    for _ = 1, 15 do
        local hrp = getLiveParts()
        if hrp then hrp.CFrame = CFrame.new(chestPos + Vector3.new(0, 3, 0)) end
        task.wait(0.1)
    end

    local prompt = retryUntil("find chest ProximityPrompt", function()
        local main = chest:FindFirstChild("Main")
        local attachment = main and main:FindFirstChild("ProximityAttachment")
        local p = attachment and attachment:FindFirstChild("ProximityInteraction")
        if p and p:IsA("ProximityPrompt") then return p end
        return chest:FindFirstChildWhichIsA("ProximityPrompt", true)
    end, 0.3)

    local fires = 0
    retryUntil("fire prompt to open chest", function()
        if not prompt.Parent then return true end
        if not prompt.Enabled then
            if fires > 0 then return true end
            return nil
        end
        if typeof(fireproximityprompt) == "function" then
            fireproximityprompt(prompt, 0, true)
        else
            pcall(function() prompt.HoldDuration = 0 end)
            prompt:InputHoldBegin() task.wait(0.1) prompt:InputHoldEnd()
        end
        fires += 1
        return true
    end, 0.3)
    for _ = 1, 7 do
        if not (prompt.Parent and prompt.Enabled) then break end
        if typeof(fireproximityprompt) == "function" then
            if pcall(function() fireproximityprompt(prompt, 0, true) end) then fires += 1 end
        else
            pcall(function() prompt.HoldDuration = 0 end)
            prompt:InputHoldBegin() task.wait(0.1) prompt:InputHoldEnd()
            fires += 1
        end
        task.wait(0.25)
    end
    print(("✅ Opened chest (%d interactions)"):format(fires))
    updateStatus("✅ Chest Opened!")

    -- เก็บเพชร
    print(string.format("\n[Step 7.5] Collecting diamonds (round %d)...", completedRounds))
    updateStatus("Collecting Diamonds...")
    local COLLECT_RADIUS = 150
    local COLLECT_EMPTY_STOP = 4
    local DIAMOND_ITEM_NAME = "Diamond"
    local TakeDiamondsEvent = ReplicatedStorage.RemoteEvents.RequestTakeDiamonds

    local function getItemPart(item)
        local ok, part = pcall(function()
            if item:IsA("BasePart") then return item end
            if item:IsA("Model") then
                return item.PrimaryPart or item:FindFirstChild("Main") or item:FindFirstChildWhichIsA("BasePart", true)
            end
        end)
        if ok then return part end
    end

    local function findDiamonds(origin)
        local found = {}
        pcall(function()
            local items = workspace:FindFirstChild("Items")
            if not items then return end
            for _, item in ipairs(items:GetChildren()) do
                if item.Name == DIAMOND_ITEM_NAME then
                    local owner = item:GetAttribute("Owner")
                    if owner == nil or owner == LocalPlayer.UserId then
                        local part = getItemPart(item)
                        if part then
                            local ok2, dist = pcall(function() return (part.Position - origin).Magnitude end)
                            if ok2 and dist <= COLLECT_RADIUS then
                                table.insert(found, {model = item, part = part})
                            end
                        end
                    end
                end
            end
        end)
        return found
    end

    local origin = chestPos
    local collected = 0
    local emptyStreak = 0
    local collectRound = 0
    while emptyStreak < COLLECT_EMPTY_STOP do
        collectRound += 1
        local diamonds = findDiamonds(origin)
        if #diamonds == 0 then
            emptyStreak += 1
            print(("  round %d: no items (%d/%d)"):format(collectRound, emptyStreak, COLLECT_EMPTY_STOP))
        else
            emptyStreak = 0
            for _, d in ipairs(diamonds) do
                if d.model and d.model.Parent then
                    local startDiamonds = LocalPlayer:GetAttribute("Diamonds")
                    local tries = 0
                    local gotIt = false
                    -- เดิม while not gotIt ไม่มีเพดาน: โมเดลถูกลบ/เซิร์ฟปัด = ยิง FireServer ใส่ instance ศพไม่รู้จบ
                    while not gotIt and tries < 25 do
                        if not (d.model and d.model.Parent) then break end
                        tries += 1
                        local hrp = getLiveParts()
                        if hrp and d.part and d.part.Parent then
                            pcall(function()
                                for _ = 1, 5 do hrp.CFrame = CFrame.new(d.part.Position + Vector3.new(0,2,0)) task.wait(0.05) end
                            end)
                        end
                        pcall(function() TakeDiamondsEvent:FireServer(d.model) end)
                        task.wait(0.2)
                        if LocalPlayer:GetAttribute("Diamonds") ~= startDiamonds then gotIt = true end
                        if not gotIt and tries % 20 == 0 then
                            updateStatus(("Collecting Diamond... (%d)"):format(tries))
                        end
                    end
                    if gotIt then
                        collected += 1
                        task.wait(0.15)
                    elseif d.model and d.model.Parent then
                        warn("Diamond not collected after 25 tries - skipping")
                    end
                end
            end
        end
        updateStatus(("Collecting Diamonds... (%d)"):format(collected))
        task.wait(0.2)
    end
    print(("[OK] Collected %d diamonds (round %d)"):format(collected, completedRounds))
    updateStatus(("✅ Collected %d Diamonds"):format(collected))

    -- ถ้า quest พร้อมอัปแล้ว → ออกจาก Stronghold กลับ lobby (หลังเก็บเพชรเสร็จ)
    if questReadyToLeave then
        local mainClass = Config.UpgradeClass and Config.UpgradeClass[1] or "?"
        print(string.format("[Quest] %s quest complete - leaving for lobby", mainClass))
        updateStatus("Teleporting to lobby...")
        task.wait(2)
        local LOBBY_PLACE_ID = 79546208627805
        pcall(function()
            local TS = game:GetService("TeleportService")
            TS:Teleport(LOBBY_PLACE_ID, LocalPlayer)
        end)
        task.wait(5)
        useCannon = false
        return
    end

    -- ถ้ายังไม่ครบ 3 รอบ รอ Stronghold เปิดใหม่แล้ววาร์ปกลับ
    if completedRounds < TOTAL_ROUNDS then
        print(string.format("[Round %d done] Waiting 20min for Stronghold to reopen...", completedRounds))
        warpToStrongholdFloor(1)
        -- นับ 20 นาทีเองแทนการอ่าน timer
        local WAIT_SECONDS = 20 * 60
        for i = WAIT_SECONDS, 1, -1 do
            local mins = math.floor(i / 60)
            local secs = i % 60
            updateStatus(string.format("Round %d done - Next: %02d:%02d", completedRounds, mins, secs))
            task.wait(1)
        end
        -- หลังนับครบ เช็คว่าเปิดจริงไหม ถ้าไม่ให้รอต่อ
        while true do
            local remaining = getStrongholdTimeRemaining()
            if not remaining or remaining <= 0 then
                print("✅ Stronghold reopened!")
                break
            end
            local mins = math.floor(remaining / 60)
            local secs = math.floor(remaining % 60)
            updateStatus(string.format("Waiting... %02d:%02d", mins, secs))
            task.wait(1)
        end
        warpToTriggerZone()
        task.wait(1)
    end
end

if lockConn then lockConn:Disconnect() end
destroyShield()
destroyFlyBody() -- ถอน BodyVelocity คืนการควบคุมตัวละครปกติ (ไม่มี PlatformStand ให้ปลดแล้ว)

print("\n=== Sugar Hub Complete ===")
print("✅ Stronghold sequence finished! (3 rounds)")
sendHorstDescription()
checkDiamondsGoalAndSendDone()

-- รอจนครบ 100 วัน ก่อนรีเซ็ต
-- อ่านวันจาก workspace.StoryDayCounter (แบบเดียวกับ NextDayUI ที่ decompile ได้)
local function getCurrentDay()
    local storyDay = workspace:GetAttribute("StoryDayCounter")
    if storyDay then return storyDay end
    -- สำรอง: ถ้าแมพไม่มี StoryDayCounter ค่อยใช้ attribute ของผู้เล่น
    return LocalPlayer:GetAttribute("Day") or 0
end

local MIN_DAY = 100
updateStatus(string.format("Waiting Day %d+ (now: %d)...", MIN_DAY, getCurrentDay()))
while getCurrentDay() < MIN_DAY do
    updateStatus(string.format("Day %d/%d - waiting...", getCurrentDay(), MIN_DAY))
    task.wait(5)
end

print(string.format("✅ Day %d reached - resetting!", getCurrentDay()))
updateStatus("✅ Done! Resetting...")
task.wait(0.3)
pcall(function()
    -- ฆ่าตัวเองจบรอบ - ปล่อยให้ Death Watcher จับแล้วกดเล่นใหม่ต่อได้เลย (จบรอบ = เริ่มรอบใหม่)
    LocalPlayer.Character:BreakJoints()
end)
