repeat wait() until game:IsLoaded()

if game.PlaceId ~= 79546208627805 and game.PlaceId ~= 126509999114328 then
    return
end

-- Main Script - Auto Farm Manager
-- Sugar Hub - Auto Farm System

print("6.30")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

print("=== Sugar Hub Started ===")

-- ============================================
-- Config (ตั้งได้จากภายนอกผ่าน _G.Config ก่อนรันสคริปต์นี้)
-- ============================================
_G.Config = _G.Config or {}
local Config = _G.Config

-- ค่าพื้นฐาน: ถ้าไม่ได้ตั้งจากภายนอก ให้เป็น false / ไม่ตั้ง
Config.Horst = Config.Horst == true
Config.ToggleRender3D = Config.ToggleRender3D == true
-- Config.Diamonds: ไม่ตั้งค่า default ให้ (ถ้าไม่ตั้งจากภายนอก = nil = ไม่ส่ง DONE เลย)

-- ถ้าเปิด Horst ให้โหลดสคริปต์ Horst
if Config.Horst then
    loadstring(game:HttpGet("https://raw.githubusercontent.com/HorstSpaceX/last_update/main/on_loaded.lua"))()
end

local diamondsGoalReached = false -- เช็คว่าส่ง DONE ไปแล้วหรือยัง (กันส่งซ้ำ)

-- ============================================
-- Anti-AFK (กัน Roblox เตะออกตอนไม่ได้ขยับ)
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

-- ส่ง Description และ DONE ให้ Horst เมื่อ Diamonds ถึงจำนวนที่ตั้งใน Config.Diamonds
-- ถ้าไม่ได้ตั้ง Config.Diamonds (เป็น nil) จะไม่มีการส่ง DONE เลย
local function sendHorstDescription()
    if not Config.Horst then return end
    if not _G.Horst_SetDescription then
        warn("[DEBUG] Horst_SetDescription not found")
        return
    end
    local diamonds = LocalPlayer:GetAttribute("Diamonds") or 0
    local description = string.format(
        "🌲 99 Nights • Diamonds: %d%s",
        diamonds,
        diamondsGoalReached and " ✅" or ""
    )
    _G.Horst_SetDescription(description)
end

local function checkDiamondsGoalAndSendDone()
    if not Config.Horst then return end
    if diamondsGoalReached then return end
    if Config.Diamonds == nil then return end -- ไม่ได้ตั้ง Config.Diamonds = ไม่ส่ง DONE

    local diamonds = LocalPlayer:GetAttribute("Diamonds") or 0
    if diamonds >= Config.Diamonds then
        diamondsGoalReached = true
        sendHorstDescription()

        task.spawn(function()
            task.wait(7) -- รอ Description ส่งเสร็จก่อนส่ง DONE
            if _G.Horst_AccountChangeDone then
                _G.Horst_AccountChangeDone()
            else
                warn("[DEBUG] Horst_AccountChangeDone not found")
            end
        end)
    end
end

LocalPlayer:GetAttributeChangedSignal("Diamonds"):Connect(function()
    updateDiamondsLabel()
    sendHorstDescription()
    checkDiamondsGoalAndSendDone()
end)
updateDiamondsLabel()

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

print("✅ GUI Loaded")

-- ============================================
-- STEP 1: Check Map and Enter Solo if needed
-- ============================================

local function isLobby()
    return workspace:FindFirstChild("Boards") ~= nil
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
    task.wait(0.5)

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
        task.wait(0.4)
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
                    task.wait(0.3)
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

    -- Solo Teleport Logic
    updateStatus("Entering Solo Map...")

    local function hasPlayersInBeam(teleporter)
        local beamPart = teleporter:FindFirstChild("BeamPart")
        if not beamPart then return true end

        local radius = math.max(beamPart.Size.X, beamPart.Size.Z) / 2

        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                local hrp = player.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local distance = math.sqrt(
                        (hrp.Position.X - beamPart.Position.X)^2 +
                        (hrp.Position.Z - beamPart.Position.Z)^2
                    )
                    if distance <= radius then return true end
                end
            end
        end
        return false
    end

    task.wait(3)
    makeInvisible()

    Client.Events.TeleportEvent:FireServer("Remove")
    task.wait(0.5)

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
                if tp.obj and not hasPlayersInBeam(tp.obj) then
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
        task.wait(0.3)
        Client.Events.TeleportEvent:FireServer("Add", selectedTeleporter)
        task.wait(0.3)
        Client.Events.TeleportEvent:FireServer("Chosen", nil, 1, nil)
        print("Entering Solo map...")
        updateStatus("Loading Map...")

        -- รอสูงสุด 20 วิ ถ้ายังอยู่ Lobby อยู่ = teleport ล้มเหลว ให้ลองใหม่
        local waited = 0
        local TELEPORT_TIMEOUT = 20
        while isLobby() and waited < TELEPORT_TIMEOUT do
            waited = waited + 1
            if waited % 5 == 0 then
                print(("Still in Lobby... (%ds)"):format(waited))
            end
            updateStatus(("Loading Map... (%ds)"):format(waited))
            task.wait(1)
        end

        if isLobby() then
            print("Teleport failed or room was taken - retrying...")
            updateStatus("Retrying Teleport...")
            task.wait(2)
        end
    end
    print("Successfully entered Farm map!")
    updateStatus("Map Loaded!")
else
    print("Already in Farm map - continuing...")
    updateStatus("Already in Map")
end

task.wait(1)

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

        local result = Client.Events.RequestConsumeItem:InvokeServer(item)
        if not (result and result.Success) then
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

        task.wait(1)
    end
end)

print("✅ Auto-Eat Running")

-- ============================================
-- DEATH WATCHER: ตายแล้วรอ 5 วิ กดเล่นใหม่
-- ============================================

local suppressPlayAgain = false   -- true = เป็นการ reset ที่เราสั่งเอง ไม่ต้องกดเล่นใหม่

task.spawn(function()
    local AcceptPlayAgain = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("AcceptPlayAgain")
    local handling = false

    local function onDied()
        if suppressPlayAgain or handling then return end
        handling = true
        print("[DEATH] Character died - waiting 5s then respawning")
        pcall(updateStatus, "Died - Play Again in 5s...")
        task.wait(5)
        print("Clicking Play Again...")
        pcall(function() AcceptPlayAgain:FireServer() end)
        handling = false
    end

    local function bindDeath(char)
        local hum = char:FindFirstChildOfClass("Humanoid") or char:WaitForChild("Humanoid", 10)
        if hum then hum.Died:Connect(onDied) end
    end

    if LocalPlayer.Character then bindDeath(LocalPlayer.Character) end
    LocalPlayer.CharacterAdded:Connect(bindDeath)   -- re-bind ทุก respawn
end)

print("✅ Death Watcher Running")

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

local mainFire = retryUntil("find MainFire", function()
    local map = workspace:FindFirstChild("Map")
    local camp = map and map:FindFirstChild("Campground")
    return camp and camp:FindFirstChild("MainFire")
end)

local firePart = retryUntil("find Fire part", function()
    return mainFire:FindFirstChildWhichIsA("BasePart", true)
end)

local firePos = firePart.Position
print("Fire position:", firePos)
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

print("Found trees:", #trees)

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

print("Best axe:", bestAxe.Name, "Damage:", bestAxe:GetAttribute("WeaponResourceDamage"))
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
print("Equipped:", axe.Name)

local Event = ReplicatedStorage.RemoteEvents.ToolDamageObject
local ownerId = tostring(player.UserId) .. "_" .. player.UserId

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

local function warpItemToFire(item)
    if warpedItems[item] then return end

    task.spawn(function()
        pcall(function()
            local StartDrag = ReplicatedStorage.RemoteEvents.RequestStartDraggingItem
            local StopDrag = ReplicatedStorage.RemoteEvents.StopDraggingItem

            StartDrag:FireServer(item)
            task.wait(0.1)

            if item:IsA("Model") then
                item:PivotTo(CFrame.new(firePos + Vector3.new(0, 10, 0)))
            else
                item.CFrame = CFrame.new(firePos + Vector3.new(0, 10, 0))
            end

            task.wait(0.1)
            StopDrag:FireServer(item)
        end)
    end)
    warpedItems[item] = true
end

local platform = Instance.new("Part")
platform.Size = Vector3.new(10, 1, 10)
platform.Anchored = true
platform.CanCollide = true
platform.Transparency = 1
platform.Parent = workspace

local airHeight = 20
local treeIndex = 1

local function flyAndWarpItems()
    updateStatus("Flying & Warping Items...")

    for radius = 20, 500, 40 do
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
                if item:GetAttribute("BurnFuel") and item.Name ~= "Sapling" and not warpedItems[item] then
                    warpItemToFire(item)
                end
            end

            task.wait(duration / steps)
        end
    end

    print("✅ Flight complete")

    -- Warp back to fire after flight
    humanoidRootPart.CFrame = CFrame.new(firePos + Vector3.new(5, 3, 0))
    platform.Position = firePos + Vector3.new(5, 0, 0)
    task.wait(0.5)

    if isTimerExceeded() then
        return true
    end

    return false
end

updateStatus("Initial Flight...")
flyAndWarpItems()

task.wait(1)
local currentLevel = getCurrentLevel()
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
            end

            humanoidRootPart.CFrame = CFrame.new(firePos + Vector3.new(5, 3, 0))
            platform.Position = firePos + Vector3.new(5, 0, 0)

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

    task.wait(1)

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

            print(string.format("[%d/%d] Cutting tree...", treeIndex, #trees))
            humanoidRootPart.CFrame = CFrame.new(treePos + Vector3.new(0, 0, 5))
            platform.Position = humanoidRootPart.Position - Vector3.new(0, 3, 0)
            task.wait(0.1)

            local hitCount = 0
            while tree.Parent do
                if getCurrentLevel() >= maxLevel then
                    print("✅ Max level reached")
                    updateStatus("✅ Fire Complete!")
                    humanoidRootPart.CFrame = CFrame.new(firePos + Vector3.new(5, 3, 0))
                    break
                end

                if isTimerExceeded() then
                    print("⏰ Timer exceeded 20:00! (stopped mid-tree)")
                    updateStatus("✅ Fire Complete!")
                    humanoidRootPart.CFrame = CFrame.new(firePos + Vector3.new(5, 3, 0))
                    break
                end

                pcall(function()
                    Event:InvokeServer(tree, axe, ownerId, humanoidRootPart.CFrame, false)
                end)
                task.wait(0.05)
                hitCount = hitCount + 1
            end

            if getCurrentLevel() >= maxLevel or isTimerExceeded() then
                break
            end

            print(string.format("✅ Tree %d destroyed (%d hits)", treeIndex, hitCount))
            treeIndex = treeIndex + 1
            treesSinceFlight = treesSinceFlight + 1

            task.wait(0.5)
        end
    end
end

print("🎉 Fire reached max level!")
updateStatus("✅ Fire Complete!")
-- platform ต้องอยู่ต่อ เพราะ STEP 3.5/4/5/6 ยังบินและต้องมีแท่นรองใต้เท้า

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
-- STEP 3.5: Warp to Stronghold Floor ทันที (ไม่ต้องรอ Stronghold เปิด)
-- ============================================

print("\n[Step 3.5] Warping to Stronghold Floor immediately...")
updateStatus("Warping to Stronghold Floor...")

retryUntil("find Stronghold Building", function()
    if getStrongholdBuilding() then return true end
    updateStatus("Flying to Find Stronghold...")
    flySearchStronghold()
    return getStrongholdBuilding()
end, 1)

retryUntil("warp to Stronghold Floor", function()
    return warpToStrongholdFloor(2)
end, 1)

-- ============================================
-- STEP 3.6: FPS Boost - ลบของที่ไม่ใช้แล้วทิ้ง หลัง Teleport มา Stronghold
-- ============================================
print("\n[Step 3.6] Boosting FPS (cleaning up map/lighting)...")
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
    local map = workspace:FindFirstChild("Map")
    if map then
        local mapFolderNames = {
            "Biomes", "Blockers", "Boundaries", "Campground", "Caves",
            "ExplodableModels", "FishingSpots", "Foliage", "Ground",
            "Landmarks", "MapLandmarks", "MissingKids", "Snow", "Testing", "Water",
        }
        for _, folderName in ipairs(mapFolderNames) do
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

    -- ลบทุกอย่างใต้ workspace.Characters
    local chars = workspace:FindFirstChild("Characters")
    if chars then
        pcall(function()
            for _, child in ipairs(chars:GetChildren()) do
                pcall(function() child:Destroy() end)
            end
        end)
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
-- STEP 4: Wait for Stronghold to Open (re-warp ที่ 15:00 / 10:00 / 5:00)
-- ============================================

print("\n[Step 4] Waiting for Stronghold to open...")
updateStatus("Waiting for Stronghold...")

local rewarpMarks = {
    {t = 900, label = "15:00", done = false},
    {t = 600, label = "10:00", done = false},
    {t = 300, label = "5:00",  done = false},
}

while true do
    local remaining = getStrongholdTimeRemaining()

    if not remaining then
        print("Stronghold timer not found - waiting...")
        updateStatus("Stronghold Timer Not Found...")
        task.wait(1)
    elseif remaining <= 0 then
        print("✅ Stronghold is OPEN!")
        updateStatus("✅ Stronghold Open!")
        break
    else
        local minutes = math.floor(remaining / 60)
        local seconds = math.floor(remaining % 60)
        --print(string.format("Stronghold opens in: %02d:%02d", minutes, seconds))
        updateStatus(string.format("Stronghold: %02d:%02d", minutes, seconds))

        local crossed = nil
        for _, m in ipairs(rewarpMarks) do
            if not m.done and remaining <= m.t then
                m.done = true
                crossed = m
            end
        end

        if crossed then
            print(string.format("[TIMER] Reached %s - re-warping to Stronghold Floor", crossed.label))
            updateStatus("Re-warp (" .. crossed.label .. ")")
            warpToStrongholdFloor(1)
        end

        task.wait(1)
    end
end

-- ============================================
-- STEP 5: Warp to Wave1 TriggerZone
-- ============================================

print("\n[Step 5] Warping to Wave1 TriggerZone...")
updateStatus("Warping to TriggerZone...")

-- กล่องล่องหน 6 ด้านคลุมตัวเรา กันมอนประชิดและกระสุน Crossbow
local SHIELD_SIZE = 12
local SHIELD_THICK = 1

local shieldParts = {}
local shieldFolder

local function buildShield()
    if shieldFolder then return end

    shieldFolder = Instance.new("Folder")
    shieldFolder.Name = "StrongholdShield"

    local half = SHIELD_SIZE / 2
    local t = SHIELD_THICK
    local faces = {
        {Vector3.new(SHIELD_SIZE, t, SHIELD_SIZE), Vector3.new(0,  half, 0)},  -- บน
        {Vector3.new(SHIELD_SIZE, t, SHIELD_SIZE), Vector3.new(0, -half, 0)},  -- ล่าง
        {Vector3.new(t, SHIELD_SIZE, SHIELD_SIZE), Vector3.new( half, 0, 0)},  -- ขวา
        {Vector3.new(t, SHIELD_SIZE, SHIELD_SIZE), Vector3.new(-half, 0, 0)},  -- ซ้าย
        {Vector3.new(SHIELD_SIZE, SHIELD_SIZE, t), Vector3.new(0, 0,  half)},  -- หน้า
        {Vector3.new(SHIELD_SIZE, SHIELD_SIZE, t), Vector3.new(0, 0, -half)},  -- หลัง
    }

    for i, f in ipairs(faces) do
        local p = Instance.new("Part")
        p.Name = "Face" .. i
        p.Size = f[1]
        p.Anchored = true        -- ขับด้วย CFrame ทุก tick ไม่ให้ physics ลากตัวเรา
        -- บน/ล่าง (offset.Y ~= 0) ไม่ทึบ กันชนพื้น Stronghold จนโดนดีดออกจาก TriggerZone
        -- (กระสุน Crossbow Cultist ยิงแนวนอน ไม่จำเป็นต้องกันบน/ล่างอยู่แล้ว)
        p.CanCollide = (f[2].Y == 0)
        p.CanQuery = true        -- ให้ raycast กระสุนชนกล่องแทนตัวเรา
        p.CanTouch = false       -- ไม่ไป trigger Touched ของอย่างอื่น
        p.Transparency = 1
        p.Massless = true
        p.Material = Enum.Material.SmoothPlastic
        p.Parent = shieldFolder
        table.insert(shieldParts, {part = p, offset = f[2]})
    end

    shieldFolder.Parent = workspace
end

local function updateShield(hrp)
    if not hrp then return end
    local pos = hrp.Position
    for _, entry in ipairs(shieldParts) do
        entry.part.CFrame = CFrame.new(pos + entry.offset)
    end
end

local function destroyShield()
    if shieldFolder then
        shieldFolder:Destroy()
        shieldFolder = nil
    end
    shieldParts = {}
end

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
        updateShield(hrp)
    end
end

warpToTriggerZone()
task.wait(0.3)
print(string.format("✅ Warped to Wave1 TriggerZone: %.1f, %.1f, %.1f", tzPos.X, tzPos.Y, tzPos.Z))

-- Equip Old Sack เพื่อ trigger TriggerZone แล้วกลับไปใช้ axe เดิม
do
    local oldSack = LocalPlayer.Inventory:FindFirstChild("Old Sack")
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
        local building = getStrongholdBuilding()
        local bCF, bSize
        if building then
            bCF, bSize = building:GetBoundingBox()
        end
        for _, c in ipairs(chars:GetChildren()) do
            if c.Name == "Cultist" or c.Name == "Crossbow Cultist" then
                local hum = c:FindFirstChildOfClass("Humanoid")
                local root = c:FindFirstChild("HumanoidRootPart") or c.PrimaryPart or c:FindFirstChildWhichIsA("BasePart")
                if hum and hum.Health > 0 and root then
                    if bCF and bSize then
                        -- เช็คว่าอยู่ใน bounding box ของตึก Stronghold (+ margin 30 stud)
                        local local_ = bCF:PointToObjectSpace(root.Position)
                        local half = bSize / 2 + Vector3.new(30, 30, 30)
                        if math.abs(local_.X) <= half.X
                            and math.abs(local_.Y) <= half.Y
                            and math.abs(local_.Z) <= half.Z
                        then
                            return true
                        end
                    else
                        return true -- หา building ไม่เจอ ให้ผ่านไปก่อน
                    end
                end
            end
        end
        return false
    end

    local waited = 0
    local WAIT_STEP = 0.5
    local SPAWN_TIMEOUT = 8 -- วิ ที่รอมอนเกิดก่อนจะวาร์ปไป Floor แล้ววาร์ปกลับ

    while not anyCultistSpawned() do
        task.wait(WAIT_STEP)
        waited += WAIT_STEP

        if waited >= SPAWN_TIMEOUT then
            print("[Step 5] Cultist ยังไม่เกิด - วาร์ปไป Floor แล้ววาร์ปกลับ TriggerZone")
            updateStatus("Re-warp waiting for spawn...")

            if floorPos then
                local hrp = getLiveParts()
                if hrp then
                    hrp.CFrame = CFrame.new(floorPos)
                    updateShield(hrp)
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
-- STEP 6: Fight loop - ล็อคลอยตลอด, ตี Cultist จากด้านใต้ 15 studs, เช็คซ้ำเรื่อยๆ
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
local HOVER_HEIGHT = 20      -- ลอยใต้ตัวมอน 20 studs แล้วตีขึ้นไป
local ATTACK_INTERVAL = 0.18

-- เช็คว่ามอนอยู่ "ภายในสิ่งก่อสร้างจริง" ของ workspace.Map.Landmarks.Stronghold.Building
-- ตึกเป็นรูปทรงหยักๆ ไม่ใช่สี่เหลี่ยมเป๊ะ ใช้ bounding box กล่องเดียวไม่พอ
-- เช็คแทนโดยดูว่าตำแหน่งมอนอยู่ในกรอบ (OBB) ของ part ใด part หนึ่งของตึกจริงๆ (บวก margin เล็กน้อยกันคลาดเคลื่อน)
local strongholdParts = nil
local PART_MARGIN = 4 -- studs กันคลาดเคลื่อนเล็กน้อยรอบ part แต่ละชิ้น (รัศมีตัวละคร/มอนประมาณนี้)

local function refreshStrongholdParts()
    local building = getStrongholdBuilding()
    if not building then
        strongholdParts = nil
        return
    end

    local floorNames = { "Floor2", "Floor", "Floor3", "Interior" }
    local parts = {}
    for _, floorName in ipairs(floorNames) do
        local floor = building:FindFirstChild(floorName)
        if floor then
            for _, inst in ipairs(floor:GetDescendants()) do
                if inst:IsA("BasePart") then
                    table.insert(parts, inst)
                end
            end
        end
    end

    strongholdParts = parts
end

refreshStrongholdParts()

local function isPointInPart(part, pos)
    local local_ = part.CFrame:PointToObjectSpace(pos)
    local half = part.Size / 2 + Vector3.new(PART_MARGIN, PART_MARGIN, PART_MARGIN)
    return math.abs(local_.X) <= half.X
        and math.abs(local_.Y) <= half.Y
        and math.abs(local_.Z) <= half.Z
end

local function isInsideStronghold(cultistModel, pos)
    local sh = getStrongholdRoot()
    if sh and cultistModel:IsDescendantOf(sh) then
        return true
    end

    if not strongholdParts then
        refreshStrongholdParts()
    end

    if not strongholdParts then
        return false
    end

    for _, part in ipairs(strongholdParts) do
        if part.Parent and isPointInPart(part, pos) then
            return true
        end
    end

    return false
end

-- ชื่อมอนที่ให้ตีใน Stronghold
local CULTIST_NAMES = {
    ["Cultist"] = true,
    ["Crossbow Cultist"] = true,
}

local function findCultists()
    local list = {}
    local chars = workspace:FindFirstChild("Characters")
    if not chars then return list end
    for _, c in ipairs(chars:GetChildren()) do
        if CULTIST_NAMES[c.Name] then
            local root = c:FindFirstChild("HumanoidRootPart") or c.PrimaryPart or c:FindFirstChildWhichIsA("BasePart")
            local hum = c:FindFirstChildOfClass("Humanoid")
            if root and hum and hum.Health > 0 and isInsideStronghold(c, root.Position) then
                table.insert(list, c)
            end
        end
    end
    return list
end

local lockConn
lockConn = RunService.Heartbeat:Connect(function()
    local hrp, hum = getLiveParts()
    if hum and hum.Health > 0 then
        hum.PlatformStand = true
        hum.Sit = false
    end
    if not hrp then return end
    hrp.AssemblyLinearVelocity = Vector3.zero
    hrp.AssemblyAngularVelocity = Vector3.zero
    updateShield(hrp)
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

while true do
    if isStrongholdCleared() then
        print("[OK] FinalGate moved -> Stronghold cleared")
        updateStatus("✅ Stronghold Cleared!")
        break
    end

    local cultists = findCultists()

    if #cultists == 0 then
        -- ไม่มีมอนตอนนี้ ลอยรอเช็คซ้ำ
        local hrp = getLiveParts()
        if hrp then hrp.CFrame = CFrame.new(combatCenter) end
        updateStatus("Waiting for Cultists...")
        task.wait(1)
    else
        for _, cultist in ipairs(cultists) do
            if not cultist or not cultist.Parent then continue end
            if isStrongholdCleared() then break end

            local cultistHum = cultist:FindFirstChildOfClass("Humanoid")
            local root = cultist:FindFirstChild("HumanoidRootPart") or cultist.PrimaryPart or cultist:FindFirstChildWhichIsA("BasePart")
            if not cultistHum or not root then continue end

            updateStatus("Fighting " .. cultist.Name .. "...")

            while cultist.Parent and cultistHum.Health > 0 do
                if isStrongholdCleared() then break end

                local hrp = getLiveParts()
                if not hrp then task.wait(0.2) continue end

                -- ลอยใต้เท้ามอน 15 studs แล้วตีขึ้นไป
                hrp.CFrame = CFrame.new(root.Position - Vector3.new(0, HOVER_HEIGHT, 0))
                    * CFrame.Angles(math.rad(90), 0, 0)

                pcall(function()
                    Event:InvokeServer(cultist, axe, ownerId, hrp.CFrame, false)
                end)

                task.wait(ATTACK_INTERVAL)
            end

            print("Cultist eliminated, checking for more...")
        end

        task.wait(0.3)
    end
end

if lockConn then lockConn:Disconnect() end
destroyShield()
local _, myHum = getLiveParts()
if myHum then myHum.PlatformStand = false end

-- ============================================
-- STEP 7: เปิด Stronghold Diamond Chest
-- ============================================

print("\n[Step 7] Opening Stronghold Diamond Chest...")
updateStatus("Opening Diamond Chest...")

local chest = retryUntil("find Diamond Chest", function()
    local items = workspace:FindFirstChild("Items")
    return (items and items:FindFirstChild("Stronghold Diamond Chest"))
        or workspace:FindFirstChild("Stronghold Diamond Chest", true)
end)

local chestPos = chest:IsA("Model") and chest:GetPivot().Position or chest.Position

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

-- ยิงจนติดอย่างน้อย 1 ครั้ง ไม่มีเพดานรอบ
local fires = 0
retryUntil("fire prompt to open chest", function()
    if not prompt.Parent then return true end          -- prompt หาย = เปิดไปแล้ว
    if not prompt.Enabled then
        if fires > 0 then return true end              -- ยิงติดแล้วค่อยปิด = สำเร็จ
        return nil                                     -- ยังไม่เคยยิงติด รอให้เปิดก่อน
    end
    fireproximityprompt(prompt, 0, true)
    fires = fires + 1
    return true
end, 0.3)

-- ยิงต่ออีกชุดเผื่อ chest ต้อง interact หลายครั้งกว่าจะจ่ายของครบ
for _ = 1, 7 do
    if not (prompt.Parent and prompt.Enabled) then break end
    if pcall(function() fireproximityprompt(prompt, 0, true) end) then
        fires = fires + 1
    end
    task.wait(0.25)
end

print(("✅ Opened Stronghold Diamond Chest (%d interactions)"):format(fires))
updateStatus("✅ Chest Opened!")

-- ============================================
-- STEP 7.5: เก็บเพชรที่ chest drop ออกมา
-- ============================================

print("\n[Step 7.5] Collecting dropped diamonds...")
updateStatus("Collecting Diamonds...")

local COLLECT_RADIUS = 150       -- หาไอเทมรอบ chest ไม่เกิน 150 stud
local COLLECT_EMPTY_STOP = 4     -- ไม่พบของบนพื้นติดกันกี่รอบถึงถือว่าเก็บหมดแล้วจริง
local DIAMOND_ITEM_NAME = "Diamond"  -- เก็บแค่ workspace.Items.Diamond เท่านั้น (ห้ามใช้ substring match เพราะชน Meshes/diamondchest_Cube ของ chest)

local function getItemPart(item)
    local ok, part = pcall(function()
        if item:IsA("BasePart") then return item end
        if item:IsA("Model") then
            return item.PrimaryPart
                or item:FindFirstChild("Main")
                or item:FindFirstChildWhichIsA("BasePart", true)
        end
        return nil
    end)
    if ok then return part end
    return nil
end

local TakeDiamondsEvent = ReplicatedStorage.RemoteEvents.RequestTakeDiamonds

local function firePromptsIn(item)
    -- เพชรไม่มี ProximityPrompt ต้องยิง RequestTakeDiamonds:FireServer(item) ตรงๆ
    local ok = pcall(function()
        TakeDiamondsEvent:FireServer(item)
    end)
    if ok then return 1 end
    return 0
end

local function findDiamonds(origin)
    local found = {}
    local ok = pcall(function()
        local items = workspace:FindFirstChild("Items")
        if not items then return end
        -- เก็บเฉพาะ item ที่ชื่อ "Diamond" ตรงตัวและเป็น direct child ของ Items เท่านั้น
        -- ไม่ใช้ substring/GetDescendants เพราะจะไปชน Meshes/diamondchest_Cube ของ chest
        for _, item in ipairs(items:GetChildren()) do
            if item.Name == DIAMOND_ITEM_NAME then
                local owner = item:GetAttribute("Owner")
                local mine = (owner == nil) or (owner == LocalPlayer.UserId)
                if mine then
                    local part = getItemPart(item)
                    if part then
                        local okDist, dist = pcall(function()
                            return (part.Position - origin).Magnitude
                        end)
                        if okDist and dist <= COLLECT_RADIUS then
                            table.insert(found, {model = item, part = part})
                        end
                    end
                end
            end
        end
    end)
    if not ok then return {} end
    return found
end

local origin = chest:IsA("Model") and chest:GetPivot().Position or chest.Position
local collected = 0
local emptyStreak = 0
local round = 0

while emptyStreak < COLLECT_EMPTY_STOP do
    round = round + 1
    local diamonds = findDiamonds(origin)

    if #diamonds == 0 then
        emptyStreak = emptyStreak + 1
        print(("  round %d: no items found on ground (%d/%d)"):format(round, emptyStreak, COLLECT_EMPTY_STOP))
    else
        emptyStreak = 0

        for _, d in ipairs(diamonds) do
            if d.model and d.model.Parent then
                local name = d.model.Name
                -- chest/diamond node ไม่ถูกทำลายจาก Items ตอนเก็บสำเร็จ (PermanentlyLocalToPlayer)
                -- ต้องเช็คความสำเร็จจาก LocalPlayer.Diamonds attribute เปลี่ยน ไม่ใช่ d.model.Parent == nil
                local startDiamonds = LocalPlayer:GetAttribute("Diamonds")
                local tries = 0
                local gotIt = false

                while not gotIt do
                    tries = tries + 1

                    local hrp = getLiveParts()
                    if hrp and d.part and d.part.Parent then
                        pcall(function()
                            for _ = 1, 5 do
                                hrp.CFrame = CFrame.new(d.part.Position + Vector3.new(0, 2, 0))
                                task.wait(0.05)
                            end
                        end)
                    end

                    firePromptsIn(d.model)
                    task.wait(0.2)

                    local curDiamonds = LocalPlayer:GetAttribute("Diamonds")
                    if curDiamonds ~= startDiamonds then
                        gotIt = true
                    end

                    if not gotIt and tries % 20 == 0 then
                        print(("  ...still couldn't collect %s (attempt %d)"):format(name, tries))
                        updateStatus(("Collecting %s... (%d)"):format(name, tries))
                    end
                end

                collected = collected + 1
                print(("  [OK] collected %s"):format(name))
                task.wait(0.15)
            end
        end
    end

    updateStatus(("Collecting Diamonds... (%d)"):format(collected))
    task.wait(0.5)
end

print(("[OK] Collected %d diamonds"):format(collected))
updateStatus(("✅ Collected %d Diamonds"):format(collected))

print("\n=== Sugar Hub Complete ===")
print("✅ Stronghold sequence finished!")
updateStatus("✅ Done! Resetting...")

-- เก็บเพชรครบแล้ว รีเซ็ตตัวเองเพื่อเริ่มรอบใหม่
task.wait(1)
pcall(function()
    LocalPlayer.Character:BreakJoints()
end)
