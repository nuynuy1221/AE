repeat wait() until game:IsLoaded()
-- เช็คว่าอยู่ในแมพ Murder Mystery 2 หรือไม่
if game.PlaceId ~= 142823291 then
    return
end

print("Version 1.0.7 (Halloween Event)")
-- Config (ตั้งได้จากภายนอก)
_G.Config = _G.Config or {}
local Config = _G.Config

-- ค่าพื้นฐาน
Config.Horst = Config.Horst == true
Config.HopBagFull = Config.HopBagFull == true
-- Config.Embersickle = true → เปิดกล่อง Halloween จนได้ Embersickle แล้วส่ง DONE
-- ถ้าไม่ตั้งค่า จะไม่ส่ง DONE เลย
Config.Embersickle = Config.Embersickle == true
-- Config.CoinsBox = ชื่อกล่องที่ต้องการเปิดด้วย Coins (เช่น "KnifeBox1", "MysteryBox2")
-- ถ้าไม่ตั้งค่า จะไม่เปิดกล่องด้วย Coins
-- รายการกล่องที่ใช้ได้:
--   MysteryBox1, MysteryBox2
--   KnifeBox1, KnifeBox2, KnifeBox3, KnifeBox4, KnifeBox5
--   MLG Box, GunBox1, GunBox2, GunBox3
Config.CoinsBox = Config.CoinsBox or nil

-- ถ้าเปิด Horst ให้โหลด script
-- ⚠ ต้องกรอง print ก่อนโหลด on_loaded.lua เพราะโค้ดอาจจับค่า print ไปตั้งแต่ตอนโหลด
--   (แบบเดียวกับ horstInstall ใน Fishing Master)
--   on_loaded.lua พิมพ์ "Successfully sent description" ทุกครั้งที่อัปเดต (ทุก ~30 วิ)
--   = สัญญาณว่าส่งถึงปลายทาง ไม่ต้องเห็นทุกครั้ง
if Config.Horst then
    local realPrint = print
    print = function(...)
        local parts = {}
        for i = 1, select("#", ...) do
            parts[#parts + 1] = tostring((select(i, ...)))
        end
        local line = string.lower(table.concat(parts, " "))
        if line:find("sheet", 1, true)
            or line:find("sent description", 1, true)
            or line:find("sent done", 1, true) then
            return
        end
        realPrint(...)
    end

    local ok, err = pcall(function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/HorstSpaceX/last_update/main/on_loaded.lua"))()
    end)
    if not ok then
        print = realPrint
        warn("[Horst] โหลด on_loaded.lua ไม่สำเร็จ: " .. tostring(err))
    end
end

local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local character = player.Character or player.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

-- ตั้งค่า
local SPEED = Config.TweenSpeed or 25
local TWEEN_MAX_TRY = 3        -- จำนวนรอบที่ยิง tween ซ้ำถ้ายังไม่ถึงเป้า
local TWEEN_STUCK_SEC = 5      -- ไม่เข้าใกล้ขึ้นกี่วินาที = ปล่อย
local TWEEN_ARRIVE_XZ = 1.5    -- ต้องแตะจริง (HRP 2 + กล่อง Coin_Server 1.378 → แตะได้ที่ระยะ ≤ 1.69)
local TWEEN_ARRIVE_Y = 1.5     -- หัวต้องอยู่ใกล้ระดับเหรียญจริง (ตัวจมใต้ดิน)
local DEFAULT_HEAD_LIFT = 1.2  -- ระยะ Head สูงกว่า HRP (ค่าเริ่มต้น — วัดจริงตอน respawn)
local DEFAULT_HEAD_HALF = 0.59 -- ครึ่งความสูงหัว (ค่าเริ่มต้น — วัดจริงตอน respawn)
local COIN_TRIGGER_HALF = 0.9395 -- ครึ่งความสูงกล่อง Coin_Server (1.879/2)
local TOUCH_MARGIN = 0.45      -- ให้หัวโผล่พ้นระดับ trigger แค่นิดเดียว (ยิ่งน้อย = ยิ่งซ่อน)
local COLLECT_ACK_WAIT = 0.25  -- รอ CoinCollected ยืนยัน (สูงสุด) — ออกทันทีที่ได้ ack/Collected
local COLLECT_CHAIN_DELAY = 0.05 -- เว้นจังหวะก่อนออกไปเก็บเหรียญชิ้นถัดไป

-- ── สถานะการซ่อนตัว / ล็อคตำแหน่ง ──────────────────────────────────
--   เก็บเหรียญด้วย "หัว": วาง HRP ใต้เหรียญ โดยให้ยอดหัวโผล่พ้น
--   ระดับ trigger แค่ TOUCH_MARGIN → ลำตัว/ขาอยู่ใต้พื้นทั้งหมด
local headLift = DEFAULT_HEAD_LIFT -- Head สูงกว่า HRP กี่ studs (วัดจากตัวจริง)
local headHalf = DEFAULT_HEAD_HALF -- ครึ่งความสูงของหัว (วัดจากตัวจริง)
local sinkHold = nil               -- CFrame ล็อคใต้ดินระหว่างรอเก็บชิ้นถัดไป
local lastGoalCFrame = nil         -- CFrame เป้าของ tween ล่าสุด
local tweenRunning = false         -- กำลัง tween อยู่ → Heartbeat ห้ามเขียนทับ
local lobbyLock = false            -- อยู่ใน Lobby = true → ล็อคตัวไว้ใต้พื้น
local lobbyPin = nil               -- CFrame ที่ล็อคใน Lobby
local lobbyPinChar = nil           -- character ที่ผูกกับ lobbyPin
local MAX_FAILED_COLLECTS = 10 -- ไปถึงแล้วของไม่เข้าติดกันกี่ครั้ง = ถือว่ากระเป๋าเต็ม (fallback)
local DESCRIPTION_INTERVAL = 30 -- ส่ง Description ทุก 30 วิ
local lastDescriptionTime = 0
local doneSent = false -- เช็คว่าส่ง DONE ไปแล้วหรือยัง
local bagWasFull = false -- กัน BreakJoints ซ้ำรัวๆ ตอน Full ค้าง
local lastCharacter = nil -- ใช้รีเซ็ตสถานะเมื่อ respawn
local collectAttempts = 0 -- ไปถึงเหรียญแล้วของไม่เข้าติดกันกี่ครั้ง (รีเซ็ตเมื่อเก็บสำเร็จ)

-- เวลาจริง (ใช้ GetServerTimeNow เหมือน Fishing Master — ไม่นับเวลาเองด้วย os.clock)
local function nowReal()
    local ok, t = pcall(function() return workspace:GetServerTimeNow() end)
    if ok and type(t) == "number" and t > 0 then return t end
    ok, t = pcall(function() return DateTime.now():UnixTimestampMillis() / 1000 end)
    if ok and type(t) == "number" and t > 0 then return t end
    return os.time()
end

-- ── ติดตามกระเป๋าจาก remote ของเกม ───────────────────────────────────
-- CoinCollected(a1, a2 = จำนวนปัจจุบัน, a3 = ความจุกระเป๋า)
--   CoinBagContainerScript.client.lua: if a3 <= a2 then Full.Visible = true
--   → a3 คือความจุจริงของ "ผู้เล่นคนนี้" (ขนาดกระเป๋าแต่ละคนไม่เท่ากัน)
--   → จำ cap ไว้แทนการ hardcode 40
--   → remote ยังเป็นสัญญาณเร็วสุดว่า "เกมรับการเก็บแล้ว" ใช้ต่อการไปชิ้นถัดไป
-- ⚠ เก็บ cap ทั้งแบบต่อชื่อ bag และแบบ lastCap (ไม่รู้แน่ว่า a1 เป็นชื่อ bag หรือ CoinID)
--   ในทางปฏิบัติมี bag เดียวที่ใช้งานต่อรอบ → lastCap คือ cap ของ bag นั้น
--   ตัวนับ ack ใช้แบบ global (ไม่ผูกกับ a1) เพื่อไม่ให้พลาดถ้า a1 ไม่ใช่ชื่อ bag
local bagCaps = {}       -- [bagName] = ความจุจริง (ถ้า a1 เป็นชื่อ bag)
local lastCap = nil      -- ความจุจาก CoinCollected ครั้งล่าสุด (ใช้กับ bag ที่กำลังใช้งาน)
local collectSerial = 0  -- จำนวนครั้งที่ CoinCollected ถูกยิง (สัญญาณว่าเก็บสำเร็จ)

task.spawn(function()
    -- รอ remote แบบวนซ้ำ (ไม่ใช้ WaitForChild timeout ครั้งเดียว เพราะถ้าพลาดจะไม่ได้ hook เลย)
    local gameplay
    while not gameplay do
        pcall(function()
            local remotes = ReplicatedStorage:FindFirstChild("Remotes")
            gameplay = remotes and remotes:FindFirstChild("Gameplay")
        end)
        if not gameplay then task.wait(1) end
    end

    local coinCollected
    while not coinCollected do
        coinCollected = gameplay:FindFirstChild("CoinCollected")
        if not coinCollected then task.wait(1) end
    end

    coinCollected.OnClientEvent:Connect(function(bagName, amount, cap)
        collectSerial = collectSerial + 1
        if type(cap) == "number" and cap > 0 then
            if bagName ~= nil then
                bagCaps[bagName] = cap
            end
            lastCap = cap
        end
        -- มีของเข้ากระเป๋าจริง = ไม่ใช่ "เก็บไม่ได้" → รีเซ็ตตัวนับล้มเหลว
        collectAttempts = 0
    end)

    -- รอบใหม่ = ตัวนับล้มเหลวต้องเริ่มใหม่ (ไม่งั้นกระเป๋าเต็มปลอมข้ามรอบ)
    local coinsStarted
    while not coinsStarted do
        coinsStarted = gameplay:FindFirstChild("CoinsStarted")
        if not coinsStarted then task.wait(1) end
    end
    coinsStarted.OnClientEvent:Connect(function()
        collectAttempts = 0
        -- ล้าง cap เก่า: ความจุอาจต่างกันระหว่างรอบ/เซิร์ฟเวอร์
        --   (cap จะถูกเรียนรู้ใหม่จาก CoinCollected ครั้งแรกของรอบนี้)
        bagCaps = {}
        lastCap = nil
    end)
end)


-- ฟังก์ชันเช็ค Event ปัจจุบัน (ชื่อกล่อง / สกุลเงิน / กุญแจ)
-- ทำแบบ lazy: resolve ครั้งแรกที่ใช้ กันสคริปต์ค้างถ้า EventInfoService ยังไม่พร้อม
local eventContext = nil

local function getEventContext()
    if eventContext then
        return eventContext
    end

    local ctx = {
        boxId = "Halloween2026Box",
        keyName = "HalloweenKey2026",
        currencyName = "Candies2026",
    }

    local initialized = false
    pcall(function()
        local EventInfoService = require(ReplicatedStorage:WaitForChild("SharedServices"):WaitForChild("EventInfoService"))

        -- ยังไม่ init = ใช้ค่า fallback ก่อน แต่ไม่ cache (รอบหน้าค่อยอ่านใหม่)
        if not EventInfoService.Initialized then
            return
        end
        initialized = true

        local mainEvent = EventInfoService:GetMainEvent()
        if not mainEvent or not mainEvent.EventStartInfo then
            return
        end

        local info = mainEvent.EventStartInfo
        if info.KeyName then
            ctx.keyName = info.KeyName
        end
        if info.CurrencyName then
            ctx.currencyName = info.CurrencyName
        end

        local boxes = info.Items and info.Items.MysteryBox
        if boxes then
            for id in pairs(boxes) do
                ctx.boxId = id
                break
            end
        end
    end)

    -- cache เฉพาะตอนที่ EventInfoService พร้อมแล้ว
    if initialized then
        eventContext = ctx
    end

    return ctx
end

-- ══════════════════════════════════════════════════════════════════
-- รายการไอเทมที่ถือครอง (ใช้ร่วมกันทั้ง Horst Description และ Low Mode GUI)
--   - อ่านจาก ProfileData.Weapons.Owned (แหล่งจริง ไม่ใช่ UI)
--   - Chroma: Sync entry มี Chroma = true และ ItemName = ชื่อฐาน
--     → แสดงเป็น "ชื่อฐาน (Chroma)" เพื่อไม่ให้ซ้ำกับไอเทมฐาน
--   - Embersickle (base หรือ chroma) ต่อท้ายด้วย ✅
-- ══════════════════════════════════════════════════════════════════
local EMBERSICKLE_MARK = " ✅"

local function isEmbersickleName(text)
    if type(text) ~= "string" then return false end
    return string.find(string.lower(text), "embersickle", 1, true) ~= nil
end

-- true ถ้า itemKey/ข้อมูลนี้เป็น Embersickle (base หรือ chroma)
local function isEmbersickleEntry(itemKey, info)
    if isEmbersickleName(itemKey) then return true end
    if info then
        local name = info.ItemName or info.Name
        if type(name) == "string" and string.lower(name) == "embersickle" then
            return true
        end
    end
    return false
end

-- ชื่อที่ใช้แสดง: Chroma → "Base (Chroma)"
local function displayItemName(key, info)
    local base = (info and (info.ItemName or info.Name)) or tostring(key)
    if info and info.Chroma == true then
        return base .. " (Chroma)"
    end
    return base
end

-- คืน array ของ { name, rarity, amount, sort, chroma, embersickle }
-- เรียงจากหายาก → ธรรมดา (Sort น้อย = หายากกว่า)
local function collectOwnedItems()
    local items = {}

    pcall(function()
        local ProfileData = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("ProfileData"))
        local Sync = require(ReplicatedStorage:WaitForChild("Database"):WaitForChild("Sync"))

        local owned = ProfileData.Weapons and ProfileData.Weapons.Owned
        if not owned then return end

        local rarities = Sync.Rarities or {}

        for key, amount in pairs(owned) do
            amount = tonumber(amount) or 0
            local info = Sync.Weapons and Sync.Weapons[key]
            local name = displayItemName(key, info)

            if amount > 0 and name ~= "Default Knife" and name ~= "Default Gun" then
                local rarity = (info and info.Rarity) or "Common"
                local sort = (rarities[rarity] and rarities[rarity].Sort) or 999
                local isChroma = (info and info.Chroma == true) or false
                local ember = isEmbersickleEntry(key, info)

                -- ไอเทมฐานกับ chroma มี ItemName เดียวกัน — กันชื่อชนกันด้วย key
                table.insert(items, {
                    key = key,
                    name = name,
                    rarity = rarity,
                    amount = amount,
                    sort = sort,
                    chroma = isChroma,
                    embersickle = ember,
                })
            end
        end
    end)

    table.sort(items, function(a, b)
        if a.sort ~= b.sort then return a.sort < b.sort end
        if a.name ~= b.name then return a.name < b.name end
        return tostring(a.key) < tostring(b.key)
    end)

    return items
end

-- ══════════════════════════════════════════════════════════════════
-- Low Mode GUI (แบบเดียวกับ Fishing Master)
--   เริ่มต้น = ปิดการเรนเดอร์ 3D + หน้าจอดำ · กด N เพื่อสลับ
--   แสดง: Item (ของที่มี) · Coins · Candies
-- ══════════════════════════════════════════════════════════════════
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")

local LowMode = {
	Enabled    = true,          -- เปิดใช้ระบบ Low Mode
	ToggleKey  = Enum.KeyCode.N,
	StartOn    = true,          -- true = เริ่มที่หน้าจอดำ (ปิด 3D)
	BlackCover = true,          -- กรอบดำเต็มจอ
	FogBlack   = true,          -- หมอกดำ กันพื้นหลังหลุดเป็นสีขาว
	-- โลโก้ (ใช้รูป Logo Hub ตัวเดียวกับ Fishing Master)
	LogoAsset  = "rbxassetid://121541221566629",
	Poll       = 2,             -- รีเฟรชข้อมูลทุก N วินาที
	Debug      = false,
}

-- ── ค่าปรับขนาดแผง (สเกลล้วน ไม่คำนวณพิกเซล) ──────────────────────
local LOW_W           = 0.86    -- ความกว้างแผง = กี่ % ของจอ
local LOW_H           = 1.0     -- ความสูงแผง = กี่ % ของจอ
local LOW_FIT         = 0.90    -- ใช้พื้นที่สูงสูงสุดกี่ % (ตาข่ายกันล้นจอ)
local LOW_LINE        = 0.045   -- ความสูงหนึ่งบรรทัด = กี่ % ของสูงจอ
local LOW_GAP_LOGO    = 0.014   -- ช่องไฟ โลโก้ -> บรรทัดแรก
local LOW_GAP_CELL    = 0.010   -- เว้นระหว่างชิ้นในแถว
local LOW_PAD         = 0.010   -- ขอบในของแผง
local LOW_LOGO_H      = 0.155   -- ความสูงโลโก้ = กี่ % ของสูงจอ
local LOW_LOGO_W      = 0.62    -- ความกว้างกรอบโลโก้ (สัดส่วนของ root)
local LOW_LOGO_MIN_PX = 20      -- โลโก้สูงอย่างน้อยกี่พิกเซลจริง
local LOW_TEXT_MIN    = 5       -- ตัวอักษรเล็กสุดบนจอจริง
local LOW_TEXT_MAX    = 120     -- ตัวอักษรใหญ่สุด
local LOW_ITEM_MAX    = 16      -- แสดงชื่อของที่มีสูงสุดกี่ชิ้น

local COIN_COLOR  = Color3.fromRGB(255, 212, 121)  -- ทอง
local CANDY_COLOR = Color3.fromRGB(232, 121, 249)  -- ชมพูอมม่วง (แคนดี้)
local WHITE_COLOR = Color3.fromRGB(238, 238, 245)
local DIM_COLOR   = Color3.fromRGB(150, 150, 168)

local Low = {
	gui = nil, sizeRef = nil, cover = nil, root = nil, scale = nil,
	logo = nil, gapLogo = nil, rowItems = nil, rowCoins = nil, rowCandies = nil,
	rowLays = nil, lastVS = nil, lastLinePx = nil,
	on = false, fixing = false, fog = nil,
	keyConn = nil, sizeConn = nil, camConn = nil, viewConn = nil,
}

-- ── ปิด/เปิดการเรนเดอร์ 3D ระดับเอนจิน ──────────────────────────────
--   hide = true  -> ปิดการวาด 3D (หน้าจอดำ)
--   ต้องเรียกจาก main chunk เท่านั้น (thread ของ task.spawn ไม่มีสิทธิ์)
local function lowSetRender3d(hide)
	hide = (hide == true)
	local want = not hide
	local svc = _ENV.RunService or RunService
	svc:Set3dRenderingEnabled(want)
	Low.render3d = want
	return true
end

-- ── Fallback: ไล่ Workspace ลดกราฟิก (ใช้เมื่อ Set3dRenderingEnabled ไม่มีสิทธิ์) ──
local gfxConn = nil

local function applyLowGraphics(fullSweep)
	fullSweep = (fullSweep ~= false)

	local Terrain = workspace:FindFirstChildWhichIsA("Terrain")
	if Terrain then
		pcall(function()
			Terrain.WaterWaveSize = 0
			Terrain.WaterWaveSpeed = 0
			Terrain.WaterReflectance = 0
			Terrain.WaterTransparency = 1
		end)
	end

	pcall(function()
		Lighting.GlobalShadows = false
		Lighting.FogEnd = 9e9
		Lighting.FogStart = 9e9
	end)

	pcall(function()
		settings().Rendering.QualityLevel = 1
	end)

	if fullSweep then
		for _, v in ipairs(game:GetDescendants()) do
			if v:IsA("BasePart") then
				pcall(function()
					v.CastShadow = false
					v.Material = "Plastic"
					v.Reflectance = 0
				end)
			elseif v:IsA("Decal") then
				pcall(function()
					v.Transparency = 1
					v.Texture = ""
				end)
			elseif v:IsA("ParticleEmitter") or v:IsA("Trail") then
				pcall(function() v.Lifetime = NumberRange.new(0) end)
			end
		end
	end

	for _, v in ipairs(Lighting:GetDescendants()) do
		if v:IsA("PostEffect") then
			pcall(function() v.Enabled = false end)
		end
	end

	if not gfxConn then
		gfxConn = workspace.DescendantAdded:Connect(function(child)
			task.spawn(function()
				if child:IsA("ForceField") or child:IsA("Sparkles")
					or child:IsA("Smoke") or child:IsA("Fire") or child:IsA("Beam") then
					RunService.Heartbeat:Wait()
					pcall(function() child:Destroy() end)
				elseif child:IsA("BasePart") then
					-- ทำครบชุดเหมือนตอน sweep (ไม่ใช่แค่ CastShadow)
					-- ชิ้นที่สตรีมเข้าหลัง sweep (เช่น แมพใหม่) จะได้ถูกลดกราฟิกด้วย
					pcall(function()
						child.CastShadow = false
						child.Material = "Plastic"
						child.Reflectance = 0
					end)
				elseif child:IsA("Decal") then
					pcall(function()
						child.Transparency = 1
						child.Texture = ""
					end)
				end
			end)
		end)
	end
end

-- ── ตัดระบบรอยเท้า (Murderer Perk "Footsteps") ─────────────────────
--   ตอนได้ Role Murder + perk Footsteps เกมจะวาง LocalScript ชื่อ
--   FootstepsClient ไว้ในตัวละคร แล้วสคริปต์นั้นสร้าง Part + SurfaceGui
--   + ImageLabel ทุก 0.25 วิ (อายุ 60 วิ) → รอยเท้าเต็มแมพ = แลคหนัก
--
--   Boost FPS เดิม (applyLowGraphics) ลบแค่เงา/วัสดุ/Decal
--   แต่รอยเท้าเป็น SurfaceGui + ImageLabel → ไม่ถูกแตะ ยังแลคอยู่
--   และถึงปิด 3D ก็ยังเปลือง CPU/แรมเพราะมันยังสร้าง object รัวๆ
--
--   แก้ที่ต้นเหตุ: ปิด LocalScript ตัวสร้างทันทีที่มันโผล่
--   + ลบโฟลเดอร์รอยเท้าที่สร้างค้างไว้ (ทำทุกครั้ง ไม่ขึ้นกับ Low Mode)
local footstepGuardInstalled = false

local function installFootstepGuard()
	if footstepGuardInstalled then return end
	footstepGuardInstalled = true

	local function killGenerator(scriptObj)
		pcall(function()
			scriptObj.Disabled = true
			scriptObj:Destroy()
		end)
	end

	local function killFolder(folder)
		pcall(function() folder:Destroy() end)
	end

	-- 1) ล้างของที่ค้างอยู่ก่อน (รอยเท้าที่สร้างไปแล้ว + ตัวสร้าง)
	local ws = workspace
	for _, v in ipairs(ws:GetDescendants()) do
		if v:IsA("BaseScript") and v.Name == "FootstepsClient" then
			killGenerator(v)
		elseif v:IsA("Folder") and v.Name == "Footsteps" then
			-- โฟลเดอร์รอยเท้า: ทั้งของที่อยู่ในตัวละคร (มีตัวสร้าง)
			-- และของที่สคริปต์สร้างไว้ใน workspace (เก็บ Part ที่วาดรอยเท้า)
			killFolder(v)
		end
	end

	-- 2) จับของใหม่: ทุกครั้งที่ได้ Role Murder / เริ่มรอบใหม่
	ws.DescendantAdded:Connect(function(child)
		if child:IsA("BaseScript") and child.Name == "FootstepsClient" then
			-- ปิดทันทีในเฟรมที่โผล่ (ก่อนมันจะเริ่มลูปสร้างรอยเท้า)
			killGenerator(child)
		elseif child:IsA("Folder") and child.Name == "Footsteps" then
			killFolder(child)
		end
	end)
end

installFootstepGuard()

-- ── หน้าตาป้ายข้อความ ───────────────────────────────────────────────
local function lowLabelSkin(lbl, color)
	lbl.BackgroundTransparency = 1
	lbl.BorderSizePixel = 0
	lbl.Font = Enum.Font.GothamBold
	lbl.TextSize = 21
	lbl.TextColor3 = color or WHITE_COLOR
	pcall(function()
		lbl.TextStrokeColor = Color3.fromRGB(8, 8, 12)
		lbl.TextStrokeTransparency = 0.35
		if Enum.TextStrokeApplyMode then
			lbl.TextStrokeApplyMode = Enum.TextStrokeApplyMode.Boundary
		end
	end)
	lbl.TextXAlignment = Enum.TextXAlignment.Center
	lbl.TextYAlignment = Enum.TextYAlignment.Center
	lbl.TextWrapped = false
	-- สูง = เต็มพ่อ (พ่อถูกบังคับเป็นพิกเซลคงที่ใน lowFillRow)
	lbl.Size = UDim2.new(0, 0, 1, 0)

	-- TextScaled = เอนจิสย่อขยายตัวอักษรเองตามขนาดจอ
	pcall(function()
		lbl.TextScaled = true
		local c = Instance.new("UITextSizeConstraint")
		c.MinTextSize = LOW_TEXT_MIN
		c.MaxTextSize = LOW_TEXT_MAX
		c.Parent = lbl
	end)

	if not pcall(function() lbl.AutomaticSize = Enum.AutomaticSize.X end) then
		lbl.AutomaticSize = Enum.AutomaticSize.None
		lbl.TextXAlignment = Enum.TextXAlignment.Left
	end
	return lbl
end

-- ── ความสูงหนึ่งบรรทัด (วัดจากขนาดแผงจริง) ─────────────────────────
local function lowLinePx()
	if Low.root then
		local ok, a = pcall(function() return Low.root.AbsoluteSize end)
		if ok and a and a.Y >= 16 then
			return math.max(8, math.floor(a.Y * LOW_LINE))
		end
	end
	return 26
end

-- ── แถวที่ห่อชื่อของ (ไหลซ้าย->ขวา แล้วขึ้นบรรทัดใหม่) ─────────────
local function lowMakeRow(parent, order)
	local row = Instance.new("Frame")
	row.Name = "Row" .. tostring(order)
	row.LayoutOrder = order
	row.BackgroundTransparency = 1
	row.BorderSizePixel = 0
	row.Size = UDim2.new(1, 0, LOW_LINE, 0)
	if not pcall(function() row.AutomaticSize = Enum.AutomaticSize.Y end) then
		row.AutomaticSize = Enum.AutomaticSize.None
	end
	row.Parent = parent

	local lay = Instance.new("UIListLayout")
	lay.FillDirection = Enum.FillDirection.Horizontal
	lay.SortOrder = Enum.SortOrder.LayoutOrder
	lay.HorizontalAlignment = Enum.HorizontalAlignment.Center
	lay.VerticalAlignment = Enum.VerticalAlignment.Center
	lay.Padding = UDim.new(0, LOW_GAP_CELL)
	if pcall(function() lay.Wraps = true end) then lay.Wraps = true end
	lay.Parent = row

	Low.rowLays = Low.rowLays or {}
	Low.rowLays[#Low.rowLays + 1] = lay
	return row
end

-- ── เติมข้อความลงแถว ────────────────────────────────────────────────
--   items = { {t=ข้อความ, c=สี, sep=จริง, tail=ต่อท้าย}, ... }
local function lowFillRow(row, items, emptyText)
	if not row then return end

	local linePx = lowLinePx()
	for _, c in ipairs(row:GetChildren()) do
		if c:IsA("TextLabel") or c:IsA("Frame") then c:Destroy() end
	end

	if not items or #items == 0 then
		local l = Instance.new("TextLabel")
		l.LayoutOrder = 1
		lowLabelSkin(l, DIM_COLOR)
		l.Text = emptyText or "-"
		l.Size = UDim2.new(0, 0, 0, linePx)
		l.Parent = row
		return
	end

	local function piece(parent, order, text, color)
		local p = Instance.new("TextLabel")
		p.LayoutOrder = order
		lowLabelSkin(p, color or WHITE_COLOR)
		p.Text = tostring(text)
		p.Parent = parent
	end

	for order, it in ipairs(items) do
		local cell = Instance.new("Frame")
		cell.Name = "Cell"
		cell.LayoutOrder = order
		cell.BackgroundTransparency = 1
		cell.BorderSizePixel = 0
		cell.Size = UDim2.new(0, 0, 0, linePx)
		if not pcall(function() cell.AutomaticSize = Enum.AutomaticSize.X end) then
			cell.AutomaticSize = Enum.AutomaticSize.None
		end
		cell.Parent = row

		local inner = Instance.new("UIListLayout")
		inner.FillDirection = Enum.FillDirection.Horizontal
		inner.SortOrder = Enum.SortOrder.LayoutOrder
		inner.HorizontalAlignment = Enum.HorizontalAlignment.Left
		inner.VerticalAlignment = Enum.VerticalAlignment.Center
		inner.Padding = UDim.new(0, 0)
		inner.Parent = cell

		piece(cell, 1, it.t, it.c)
		if it.tail then piece(cell, 2, it.tail, WHITE_COLOR) end
		-- ", " อยู่ใน Cell เดียวกับชื่อ = ไม่มีวันถูกตัดขึ้นบรรทัดใหม่แยกจากชื่อ
		if it.sep then piece(cell, 3, ", ", WHITE_COLOR) end
	end
end

-- ── คอนเทนเนอร์กลางจอ + UIScale (ตาข่ายกันล้นจอ) ──────────────────
local function lowMakeRoot(gui)
	local root = Instance.new("Frame")
	root.Name = "Root"
	root.AnchorPoint = Vector2.new(0.5, 0.5)
	root.Position = UDim2.fromScale(0.5, 0.5)
	root.Size = UDim2.fromScale(LOW_W, LOW_H)
	pcall(function() root.AutomaticSize = Enum.AutomaticSize.None end)
	root.BackgroundTransparency = 1
	root.BorderSizePixel = 0
	root.ClipsDescendants = false
	root.ZIndex = 2
	root.Parent = gui
	Low.root = root

	local scale = Instance.new("UIScale")
	scale.Scale = 1
	scale.Parent = root
	Low.scale = scale

	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, LOW_PAD)
	pad.PaddingBottom = UDim.new(0, LOW_PAD)
	pad.PaddingLeft = UDim.new(0, LOW_PAD)
	pad.PaddingRight = UDim.new(0, LOW_PAD)
	pad.Parent = root

	local lay = Instance.new("UIListLayout")
	lay.SortOrder = Enum.SortOrder.LayoutOrder
	lay.HorizontalAlignment = Enum.HorizontalAlignment.Center
	lay.VerticalAlignment = Enum.VerticalAlignment.Center
	lay.Padding = UDim.new(0, LOW_GAP_CELL * 0.4)
	lay.Parent = root
	Low.rootLayout = lay
	return root
end

-- ── ขนาดจอจริง (อ่านจากขนาดแผง -> กล้อง -> ค่าล่าสุด) ────────────
local function lowScreenSize()
	local function usable(v)
		if not v then return false end
		return type(v.X) == "number" and type(v.Y) == "number"
			and v.X >= 64 and v.Y >= 64
	end

	if Low.root then
		local good, a = pcall(function() return Low.root.AbsoluteSize end)
		if good and usable(a) and LOW_W > 0 and LOW_H > 0 then
			local w = a.X / LOW_W
			local h = a.Y / LOW_H
			if usable(Vector2.new(w, h)) then
				Low.lastVS = Vector2.new(w, h)
				return Low.lastVS
			end
		end
	end

	local cam = workspace.CurrentCamera
	if cam then
		local good, v = pcall(function() return cam.ViewportSize end)
		if good and usable(v) then
			Low.lastVS = v
			return v
		end
	end

	if usable(Low.lastVS) then return Low.lastVS end
	return Vector2.new(1920, 1080)
end

-- ── ความสูงจริงของเนื้อหาในแผง ─────────────────────────────────────
local function lowContentHeight()
	if not Low.root then return nil end
	local top, bot
	for _, c in ipairs(Low.root:GetChildren()) do
		if c:IsA("GuiObject") then
			local y = c.AbsolutePosition.Y
			local b = y + c.AbsoluteSize.Y
			if not top or y < top then top = y end
			if not bot or b > bot then bot = b end
		end
	end
	if not top or not bot then return nil end
	local h = bot - top
	if h <= 1 then return nil end
	return h
end

-- ── ปรับขนาดแผงให้พอดีจอ ───────────────────────────────────────────
local function lowApplyScale()
	if not (Low.root and Low.scale) then return end

	local vs = lowScreenSize()

	pcall(function()
		if Low.gapLogo then Low.gapLogo.Size = UDim2.new(1, 0, LOW_GAP_LOGO, 0) end
	end)

	if Low.logo then
		local h = LOW_LOGO_H
		if type(vs) == "Vector2" and vs.Y > 0 then
			local minH = LOW_LOGO_MIN_PX / vs.Y
			if minH > h then h = minH end
		end
		pcall(function() Low.logo.Size = UDim2.new(LOW_LOGO_W, 0, h, 0) end)
	end

	-- ตาข่ายนิรภัย: เนื้อหาสูงเกินพื้นที่ = ย่อทั้งแผง
	local cap = vs.Y * LOW_FIT
	local gotH = lowContentHeight()
	if gotH and gotH > cap then
		local s = math.max(0.02, cap / gotH)
		pcall(function() Low.scale.Scale = s end)
		if not Low.fixing then
			Low.fixing = true
			task.delay(0, function()
				Low.fixing = false
				lowApplyScale()
			end)
		end
	elseif (Low.scale.Scale or 1) ~= 1 then
		pcall(function() Low.scale.Scale = 1 end)
	end
end

-- ── สีตาม Rarity (อ่านจาก Sync.Rarity) ─────────────────────────────
local rarityColorCache = nil

local function rarityColor3(rarity)
	if not rarityColorCache then
		local map = {}
		pcall(function()
			local Sync = require(ReplicatedStorage:WaitForChild("Database"):WaitForChild("Sync"))
			if type(Sync.Rarity) == "table" then map = Sync.Rarity end
		end)
		if next(map) then rarityColorCache = map end
	end

	local c = rarityColorCache and rarityColorCache[rarity]
	if typeof(c) == "Color3" then return c end
	return WHITE_COLOR
end

-- ── ดึงข้อมูลสำหรับแผง: Item / Coins / Candies ─────────────────────
local function fetchLowData()
	local data = { items = {}, coins = 0, candies = 0 }

	pcall(function()
		local ProfileData = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("ProfileData"))
		local ctx = getEventContext()

		data.coins = ProfileData.Materials.Owned["Coins"] or 0
		data.candies = ProfileData.Materials.Owned[ctx.currencyName] or 0
	end)

	-- ใช้ตัวรวบรวมเดียวกันกับ Horst Description
	-- (Chroma แสดงเป็น "Base (Chroma)" · Embersickle มี ✅ ต่อท้าย)
	data.items = collectOwnedItems()

	return data
end

-- ── สร้างแถว "Item : ชื่อ1, ชื่อ2, ..." ─────────────────────────────
local function buildItemRow(data)
	local cells = { { t = "Item", c = COIN_COLOR, tail = ":" } }
	local list = data.items
	local n = math.min(#list, LOW_ITEM_MAX)

	for i = 1, n do
		local it = list[i]
		local tail = it.amount > 1 and (" x" .. it.amount) or nil
		if it.embersickle then
			tail = (tail or "") .. EMBERSICKLE_MARK
		end
		cells[#cells + 1] = {
			t = it.name,
			c = rarityColor3(it.rarity),
			tail = tail,
			-- มี ", " ต่อท้ายทุกชิ้นยกเว้นชิ้นสุดท้าย (รวมกรณีมี "+N" ต่อท้าย)
			sep = (i < n) or (#list > n),
		}
	end

	if #list > n then
		cells[#cells + 1] = { t = ("+%d"):format(#list - n), c = DIM_COLOR }
	end

	return cells
end

-- ── สร้าง ScreenGui + กรอบดำ + แผงสถิติ ─────────────────────────────
local function lowBuildUi()
	if Low.gui and Low.gui.Parent and Low.root and Low.root.Parent then return end
	local pg = player:FindFirstChildOfClass("PlayerGui")
	if not pg then return end
	local old = pg:FindFirstChild("MM2LowUi")
	if old then pcall(function() old:Destroy() end) end

	local gui = Instance.new("ScreenGui")
	gui.Name = "MM2LowUi"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 1000
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = pg
	Low.gui = gui

	-- กรอบอ้างอิงขนาดจอ
	local sizeRef = Instance.new("Frame")
	sizeRef.Name = "SizeRef"
	sizeRef.Size = UDim2.fromScale(1, 1)
	sizeRef.BackgroundTransparency = 1
	sizeRef.BorderSizePixel = 0
	sizeRef.ZIndex = 0
	sizeRef.Active = false
	sizeRef.Parent = gui
	Low.sizeRef = sizeRef

	-- กรอบดำเต็มจอ
	if LowMode.BlackCover then
		local cover = Instance.new("Frame")
		cover.Name = "Cover"
		cover.Size = UDim2.fromScale(1, 1)
		cover.BackgroundColor3 = Color3.new(0, 0, 0)
		cover.BorderSizePixel = 0
		cover.ZIndex = 1
		cover.Active = false
		cover.Parent = gui
		Low.cover = cover
	end

	Low.rowLays = {}
	local root = lowMakeRoot(gui)

	-- โลโก้
	local logo = Instance.new("ImageLabel")
	logo.Name = "Logo"
	logo.LayoutOrder = 1
	logo.Size = UDim2.new(LOW_LOGO_W, 0, 0, 130)
	logo.BackgroundTransparency = 1
	logo.Image = LowMode.LogoAsset
	logo.ScaleType = Enum.ScaleType.Fit
	logo.ZIndex = 3
	logo.Parent = root
	Low.logo = logo

	local gap = Instance.new("Frame")
	gap.Name = "LogoGap"
	gap.LayoutOrder = 1.5
	gap.Size = UDim2.new(1, 0, 0, 32)
	gap.BackgroundTransparency = 1
	gap.BorderSizePixel = 0
	gap.Parent = root
	Low.gapLogo = gap

	-- แถวข้อมูล
	Low.rowItems   = lowMakeRow(root, 2)
	Low.rowCoins   = lowMakeRow(root, 3)
	Low.rowCandies = lowMakeRow(root, 4)

	lowApplyScale()

	-- จอเปลี่ยนขนาด -> ปรับทันที
	if Low.sizeRef and not Low.sizeConn then
		pcall(function()
			Low.sizeConn = Low.sizeRef:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
				lowApplyScale()
			end)
		end)
	end

	if not Low.camConn then
		pcall(function()
			local function hookViewport()
				local cam = workspace.CurrentCamera
				if Low.viewConn then pcall(function() Low.viewConn:Disconnect() end) end
				Low.viewConn = nil
				if not cam then return end
				Low.viewConn = cam:GetPropertyChangedSignal("ViewportSize"):Connect(function()
					lowApplyScale()
				end)
			end
			Low.camConn = workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
				hookViewport()
				lowApplyScale()
			end)
			hookViewport()
		end)
	end
end

-- ── รีเฟรชข้อความในแผง (ข้ามถ้าข้อมูลไม่เปลี่ยน) ──────────────────
local lastStatsSig = nil

local function refreshStatsUi(data, force)
	if not (Low.gui and Low.root) then return end
	data = data or fetchLowData()
	lowApplyScale()

	local sig = tostring(data.coins) .. "|" .. tostring(data.candies) .. "|"
	for _, it in ipairs(data.items) do
		sig = sig .. it.name .. ":" .. it.amount .. ","
	end

	local linePx = lowLinePx()
	if (not force) and sig == lastStatsSig and linePx == Low.lastLinePx then return end
	lastStatsSig = sig
	Low.lastLinePx = linePx

	lowFillRow(Low.rowItems, buildItemRow(data), "No item")
	lowFillRow(Low.rowCoins, { { t = "Coins", c = COIN_COLOR, tail = ": " .. tostring(data.coins) } })
	lowFillRow(Low.rowCandies, { { t = "Candies", c = CANDY_COLOR, tail = ": " .. tostring(data.candies) } })

	lowApplyScale()
end

-- ── เปิด/ปิด Low Mode ───────────────────────────────────────────────
local function setLowMode(on)
	on = (on == true)
	if Low.on == on then return end
	Low.on = on

	-- 1) ปิด/เปิดการเรนเดอร์ 3D ก่อนเลย — ต้องไม่ถูกอะไรบล็อก
	--    ถ้าตัวรันไม่มีสิทธิ์ -> fallback ไล่ Workspace (ผลเหมือนกัน)
	if pcall(lowSetRender3d, on) then
		Low.gfxFallback = false
	else
		Low.render3d = not on
		Low.gfxFallback = on   -- true = ต้องไล่ Workspace เอง (ดู matchResweep)
		if on then pcall(applyLowGraphics, true) end
	end

	-- 2) หมอกดำ กันพื้นหลังที่หลุดขึ้นมาเป็นสีขาว
	if on then
		if LowMode.FogBlack then
			if not Low.fog then
				Low.fog = { FogStart = Lighting.FogStart, FogEnd = Lighting.FogEnd, FogColor = Lighting.FogColor }
			end
			pcall(function()
				Lighting.FogStart = 0
				Lighting.FogEnd = 0.5
				Lighting.FogColor = Color3.new(0, 0, 0)
			end)
		end
	else
		if Low.fog then
			pcall(function()
				Lighting.FogStart = Low.fog.FogStart
				Lighting.FogEnd = Low.fog.FogEnd
				Lighting.FogColor = Low.fog.FogColor
			end)
			Low.fog = nil
		end
	end

	-- 3) สร้าง/ซ่อนแผง (ไม่มีการ yield)
	lowBuildUi()
	if Low.gui then Low.gui.Enabled = on end

	-- 4) เติมข้อมูลใน thread แยก — require ProfileData มีการ yield
	--    ถ้าทำตรงนี้จะบล็อก main chunk ก่อนถึง bindLowToggle
	task.spawn(function()
		refreshStatsUi(fetchLowData(), true)
	end)
	return true
end

-- ── ผูกปุ่ม N ───────────────────────────────────────────────────────
local function bindLowToggle()
	if not LowMode.Enabled then
		Low.on = false
		if Low.gui then Low.gui.Enabled = false end
		return
	end

	if not Low.keyConn then
		Low.keyConn = UserInputService.InputBegan:Connect(function(inp, processed)
			if processed then return end
			if inp.KeyCode == LowMode.ToggleKey then
				setLowMode(not Low.on)
			end
		end)
	end

	-- ซิงธงกับภาพจริง
	if Low.gui then Low.on = (Low.gui.Enabled == true) end
end

-- ── เริ่มต้น: ปิด 3D + หน้าจอดำ ─────────────────────────────────────
--   ⚠ เรียก lowSetRender3d ตรงนี้ที่ main chunk (thread ของ task.spawn ไม่มีสิทธิ์)
--   setLowMode ด้านล่างเรียกซ้ำใน pcall เฉย ๆ — ถ้าสิทธิ์มีครั้งแรกผ่านไปแล้ว
--   ครั้งที่สองก็ผ่าน (หรือ fallback ไล่ Workspace ให้)
if LowMode.Enabled and LowMode.StartOn then
	setLowMode(true)
else
	lowBuildUi()
	if Low.gui then Low.gui.Enabled = false end
	task.spawn(function()
		refreshStatsUi(fetchLowData(), true)
	end)
	-- คืนภาพเสมอถ้าไม่เริ่มที่ Low Mode
	pcall(lowSetRender3d, false)
end
bindLowToggle()

-- รีเฟรชข้อมูลเป็นระยะ
task.spawn(function()
	while true do
		task.wait(LowMode.Poll)
		if Low.on then
			refreshStatsUi(fetchLowData())
		end
	end
end)

-- ── Boost FPS ตอนเริ่ม Match ใหม่ ───────────────────────────────────
--   applyLowGraphics(fullSweep=true) = ไล่ game:GetDescendants() ทั้งฉาก
--   จึงไม่ทำทุกวินาที (กินโหลดตัวเอง) — Fishing Master เองก็ทำทุก 60 วิ
--   ที่นี่ผูกกับ "เริ่ม Match" ตามที่ต้องการ: RoundStart + LoadingMap + แมพใหม่
--
--   RoundStart  = เซิร์ฟเวอร์เริ่มรอบ (ยิงทุกครั้งที่เข้าเกมใหม่)
--   LoadingMap  = กำลังโหลดแมพ (มาก่อน RoundStart)
--   Mansion2/Lobby ถูกเพิ่ม/ถูกลบ = แมพใหม่กำลังเข้า
--
--   ⚠ ถ้า Set3dRenderingEnabled ใช้ได้ (ส่วนใหญ่) เอนจินปิดภาพ 3D ไปแล้ว
--     การไล่ Workspace ไม่ช่วยเพิ่มอะไร = ข้าม เพื่อไม่เสียเวลาสแกนทั้งฉาก
--   ⚠ ถ้าใช้ fallback (executor ไม่ให้สิทธิ์) = ต้องไล่ทุกแมตช์จริง ๆ
--     ไม่งั้นแมพใหม่ที่สตรีมเข้าจะยังมีเงา/วัสดุ/particle เต็ม
local MATCH_RESWEEP_DELAY = 1   -- รอให้แมพสตรีมเข้า tree ก่อนไล่
local lastMatchSweep = 0

local function matchResweep(reason)
	-- กันยิงซ้ำรัว ๆ ตอน RoundStart + LoadingMap + แมพใหม่มาพร้อมกัน
	if tick() - lastMatchSweep < 5 then return end
	lastMatchSweep = tick()

	if not Low.on then return end

	task.spawn(function()
		task.wait(MATCH_RESWEEP_DELAY)
		-- ทำทุกแมตช์เสมอ: เกมอาจตั้ง Fog/Lighting กลับตอนเปลี่ยนแมพ
		if LowMode.FogBlack then
			pcall(function()
				Lighting.FogStart = 0
				Lighting.FogEnd = 0.5
				Lighting.FogColor = Color3.new(0, 0, 0)
			end)
		end
		-- ไล่ Workspace เฉพาะตอนที่เอนจินปิดภาพไม่ได้ (ไม่งั้นซ้ำซ้อน)
		if Low.gfxFallback then
			pcall(applyLowGraphics, true)
		end
		if LowMode.Debug then
			print("[Low] resweep:", reason)
		end
	end)
end

pcall(function()
	local Gameplay = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Gameplay")

	-- เริ่มรอบใหม่ = จุดที่ควร Boost FPS ที่สุด (เตรียมเก็บ Candies)
	Gameplay:WaitForChild("RoundStart").OnClientEvent:Connect(function()
		matchResweep("RoundStart")
	end)

	-- กำลังโหลดแมพ (มาถึงตอนแมพใหม่เริ่มเข้า)
	Gameplay:WaitForChild("LoadingMap").OnClientEvent:Connect(function()
		matchResweep("LoadingMap")
	end)

	-- แมพถูกสลับ: Mansion2 (ในเกม) / Lobby (รอ) ถูกเพิ่มหรือถูกลบ
	local watchedMaps = { "Mansion2", "Lobby" }
	local function watchMap(name)
		local map = workspace:FindFirstChild(name)
		if map then
			map.AncestryChanged:Connect(function(_, parent)
				if parent == nil then matchResweep("map removed: " .. name) end
			end)
		end
	end
	for _, name in ipairs(watchedMaps) do watchMap(name) end

	workspace.ChildAdded:Connect(function(child)
		if child.Name == "Mansion2" or child.Name == "Lobby" then
			watchMap(child.Name)
			matchResweep("map added: " .. child.Name)
		end
	end)
end)

-- เรียกจากที่อื่น (hook เดิม) เพื่ออัปเดตทันที
local function updateCurrencyLabels()
	if Low.on then
		refreshStatsUi(fetchLowData(), true)
	end
end

print("✅ MM2 Low Mode GUI Loaded - Press N to toggle")
-- ราคากล่อง (อ่านจาก NewShop ที่ถูก merge จาก EventStartInfo.ShopData ตอนรันไทม์)
--   NewShop[boxId].Price[currencyKey] = ราคาจริงจากเซิร์ฟเวอร์ (แม่นที่สุด)
--   ถ้ายังไม่มี entry (event ยังไม่ init) → ใช้ fallback ที่ส่งเข้ามา
--   Halloween Box '26 = 600 Candies + 1 Halloween Key
--   ⚠ ไม่ scrape จาก UI: ค่าที่ค้างใน TextLabel อาจเป็นค่าเก่า (เช่น 1,000) แล้วทับราคาจริง
local function getBoxPrice(currencyKey, fallback)
    local price = fallback

    pcall(function()
        local Sync = require(ReplicatedStorage:WaitForChild("Database"):WaitForChild("Sync"))
        local boxId = getEventContext().boxId
        local shopItem = Sync.NewShop and Sync.NewShop[boxId]
        local amount = shopItem and shopItem.Price and shopItem.Price[currencyKey]
        if tonumber(amount) then
            price = tonumber(amount)
        end
    end)

    return price
end

-- อัปเดตแผงแบบ real-time เมื่อ inventory เปลี่ยน (สกุลเงิน หรือของในกระเป๋า)
pcall(function()
    local Inventory = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Inventory")
    local inventoryChanged = Inventory:FindFirstChild("InventoryDataChanged")

    if inventoryChanged then
        inventoryChanged.Event:Connect(function(groupName, itemName)
            local ctx = getEventContext()
            if itemName == "Coins"
                or itemName == ctx.currencyName
                or itemName == ctx.keyName
                or groupName == "Weapons" then
                updateCurrencyLabels()
            end
        end)
    end
end)

-- หา key ของ Embersickle (ไอเทมอีเวนท์ถูก inject ตอนรันไทม์)
-- ⚠ ต้องรองรับ Chroma ด้วย: ใน Sync ตัว chroma เป็น "คนละ entry" กับไอเทมฐาน
--   และ ItemName ของ chroma = ชื่อไอเทมฐาน (เช่น DeathshardChroma -> ItemName "Deathshard")
--   key ของ chroma ตั้งได้ 2 แบบในเกม: EmbersickleChroma / ChromaEmbersickle
--   → แมตช์จาก key ที่มีคำว่า embersickle ก่อน แล้วค่อยแมตช์ ItemName ฐาน
local embersickleKeys = nil   -- array ของ key ทุกตัว (base + chroma)
local lastEmbersickleScan = 0
local embersickleMatchedKey = nil  -- key ที่เจอใน inventory จริง (ไว้ log/description)

local function resolveEmbersickleKeys()
    local keys = {}
    local seen = {}

    local function add(key)
        if key and not seen[key] then
            seen[key] = true
            keys[#keys + 1] = key
        end
    end

    pcall(function()
        local Sync = require(ReplicatedStorage:WaitForChild("Database"):WaitForChild("Sync"))
        for _, tableName in ipairs({ "Weapons", "Materials" }) do
            local items = Sync[tableName]
            if items then
                for itemKey, itemInfo in pairs(items) do
                    local name = itemInfo.ItemName or itemInfo.Name
                    -- key มีคำว่า embersickle = ครอบคลุมทั้ง base และ chroma
                    if isEmbersickleName(itemKey) then
                        add(itemKey)
                    -- ItemName ฐานตรงกับ Embersickle (ไอเทมปกติ / chroma ที่ใช้ชื่อฐาน)
                    elseif type(name) == "string" and string.lower(name) == "embersickle" then
                        add(itemKey)
                    end
                end
            end
        end
    end)

    return keys
end

local function getEmbersickleKeys()
    -- สแกนซ้ำทุก 30 วิ เผื่อไอเทมถูก inject หลังจากสคริปต์เริ่มทำงาน
    -- (ถ้าสแกนแล้วยังว่าง ให้ลองใหม่รอบหน้า ไม่ cache ตารางว่าง)
    local now = tick()
    if (not embersickleKeys or #embersickleKeys == 0) and now - lastEmbersickleScan >= 30 then
        lastEmbersickleScan = now
        local found = resolveEmbersickleKeys()
        if #found > 0 then
            embersickleKeys = found
        end
    end
    return embersickleKeys or {}
end

-- เช็คว่ามี Embersickle (หรือ Chroma Embersickle) ใน inventory หรือยัง
-- cache 1 วิ กันสแกนถี่เกิน
local cachedHasEmbersickle = false
local lastEmbersickleCheck = 0

local function checkHasEmbersickle()
    local owned = 0
    local matched = nil
    local groups = { "Weapons", "Materials" }

    pcall(function()
        local ProfileData = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("ProfileData"))

        -- 1) key ที่ resolve ได้จาก Sync (base + chroma)
        for _, key in ipairs(getEmbersickleKeys()) do
            for _, group in ipairs(groups) do
                local data = ProfileData[group]
                local amount = data and data.Owned and data.Owned[key]
                if (tonumber(amount) or 0) > 0 then
                    owned = tonumber(amount)
                    matched = key
                    break
                end
            end
            if owned > 0 then break end
        end

        -- 2) fallback: สแกนชื่อ key ใน Owned ทั้งหมด
        --    (ครอบคลุม Chroma ที่ Sync ยังไม่ inject ตอนสแกน)
        if owned <= 0 then
            for _, group in ipairs(groups) do
                local data = ProfileData[group]
                if data and data.Owned then
                    for itemKey, amount in pairs(data.Owned) do
                        if isEmbersickleName(itemKey) and (tonumber(amount) or 0) > 0 then
                            owned = tonumber(amount) or 1
                            matched = itemKey
                            break
                        end
                    end
                end
                if owned > 0 then break end
            end
        end
    end)

    if owned > 0 and embersickleMatchedKey ~= matched then
        embersickleMatchedKey = matched
        print(("[Embersickle] พบใน inventory: %s"):format(tostring(matched)))
    end

    return owned > 0
end

local function hasEmbersickle()
    if cachedHasEmbersickle then
        return true
    end

    if tick() - lastEmbersickleCheck >= 1 then
        lastEmbersickleCheck = tick()
        cachedHasEmbersickle = checkHasEmbersickle()
    end

    return cachedHasEmbersickle
end

-- บังคับสแกนใหม่ทันที (หลังเปิดกล่อง)
local function refreshEmbersickle()
    lastEmbersickleCheck = tick()
    cachedHasEmbersickle = checkHasEmbersickle()
    return cachedHasEmbersickle
end

-- รวมรายการไอเทมใน inventory สำหรับ Description
-- ใช้ collectOwnedItems() (ProfileData) — ไม่ scrape UI
--   Chroma → "Base (Chroma)" · Embersickle → ต่อท้าย ✅
local function collectInventoryNames()
    local names = {}

    for _, it in ipairs(collectOwnedItems()) do
        local text = it.name
        if it.amount > 1 then
            text = text .. " x" .. it.amount
        end
        if it.embersickle then
            text = text .. EMBERSICKLE_MARK
        end
        names[#names + 1] = text
    end

    return names
end

-- สร้างข้อความ Description (ไม่แสดง Halloween Keys, ไม่มีวันที่)
local function buildDescription()
    local coins = 0
    local candies = 0
    local ctx = getEventContext()

    pcall(function()
        local ProfileData = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("ProfileData"))
        coins = ProfileData.Materials.Owned["Coins"] or 0
        candies = ProfileData.Materials.Owned[ctx.currencyName] or 0
    end)

    local description = string.format(
        "🎮 MM2 • Coins: %d • Candies: %d",
        coins,
        candies
    )

    local itemNames = collectInventoryNames()
    if #itemNames > 0 then
        description = description .. " • Inv : " .. table.concat(itemNames, ", ")
    end

    return description
end

-- ส่ง Description (ไม่ส่ง DONE ที่นี่)
local function sendDescription()
    if not Config.Horst then return end

    if not _G.Horst_SetDescription then
        warn("[DEBUG] Horst_SetDescription not found")
        return
    end

    _G.Horst_SetDescription(buildDescription())
end

-- ส่ง DONE เฉพาะโหมด Embersickle และเฉพาะเมื่อได้ Embersickle จริง
local warnedNoHorst = false
local function maybeSendDone()
    if not Config.Embersickle or doneSent then return end
    if not hasEmbersickle() then return end

    if not (_G.Horst_SetDescription and _G.Horst_AccountChangeDone) then
        if not warnedNoHorst then
            warnedNoHorst = true
            warn("[DEBUG] Horst functions not found; cannot send DONE")
        end
        return
    end

    doneSent = true

    -- แยก thread: task.wait(7) ไม่ให้บล็อกลูปฟาร์มเหรียญ
    task.spawn(function()
        _G.Horst_SetDescription(buildDescription())
        task.wait(7)
        _G.Horst_AccountChangeDone()
        print(("[DONE] Embersickle obtained (%s)"):format(tostring(embersickleMatchedKey or "unknown")))

        -- ส่ง description ต่อทุก 3 วิ
        while true do
            sendDescription()
            task.wait(3)
        end
    end)
end

-- ── Tween ไปยังตำแหน่ง (แบบเดียวกับ Fishing Master) ──────────────────
--   ต่างจากของเดิม 3 จุด:
--     1) เก็บการหมุนเดิมไว้ (CFrame.new(pos) รีเซ็ตการหมุนทุกครั้ง)
--     2) EasingStyle.Linear + เวลาจริง = ความเร็วคงที่ทุก FPS
--     3) มีตัวจับค้าง/ไม่ถึงเป้า แล้วยิงซ้ำจากตำแหน่งจริง (ไม่ค้างรอ tween ที่ล้มเหลว)
-- ── ตำแหน่ง HRP ที่ทำให้ "หัว" แตะเหรียญแค่นิดเดียว ────────────────────
--   ระดับล่างสุดของ trigger = coinY - COIN_TRIGGER_HALF
--   ต้องการให้ยอดหัวอยู่เหนือระดับนั้น TOUCH_MARGIN
--   → HRP = ยอดหัว - ครึ่งหัว - ระยะหัวสูงกว่า HRP
--   ผลลัพธ์: เฉพาะหัวโผล่พ้นพื้น (ไม่เกิน TOUCH_MARGIN) ส่วนตัวอยู่ใต้ดิน
local function headTargetY(coinY)
    return coinY - COIN_TRIGGER_HALF + TOUCH_MARGIN - headHalf - headLift
end

local function arrivedAt(target)
    local hrp = humanoidRootPart
    if not (hrp and hrp.Parent) then return false end
    local p = hrp.Position
    local dxz = Vector3.new(target.X - p.X, 0, target.Z - p.Z).Magnitude
    local dy = math.abs(headTargetY(target.Y) - p.Y)
    return (dxz <= TWEEN_ARRIVE_XZ and dy <= TWEEN_ARRIVE_Y), dxz, dy
end

-- เช็คว่าเหรียญนี้เก็บได้จริงไหม — ใช้ "CoinVisual" เป็นตัวตัดสิน
-- ⚠ ห้าม fallback ไปดู coin.CanTouch ของ Coin_Server เด็ดขาด
--   Coin_Server เป็น Part ถาวร (Anchored=true, CanTouch=true) ที่ไม่เคยถูกลบ
--   ตอนเก็บได้ เกม (CoinVisualizer) จะ Destroy เฉพาะลูก CoinVisual เท่านั้น
--   → ช่องที่เก็บไปแล้วจะไม่มีลูก CoinVisual แต่ CanTouch ยังเป็น true
--   → ของเดิมมองช่องว่างเป็น "เก็บได้" และมักเลือกช่องที่ใกล้ที่สุด
--     (จุดที่เพิ่งยืนอยู่ = ระยะ 0) → tween ระยะ 0 แล้ววนอยู่กับที่
--     = อาการ "แคนดี้เกิดตรงหน้าแต่ไม่ยอมไปเก็บ"
-- ใช้ logic เดียวกับ CoinVisualizer: attribute Collected / Delete = เก็บแล้ว/กำลังจะหาย
local visualSkipUntil = setmetatable({}, { __mode = "k" })

-- ตำแหน่งของ CoinVisual — รองรับทั้ง BasePart และ Model
local function visualPos(visual)
    if not (visual and visual.Parent) then return nil end
    if visual:IsA("BasePart") then
        return visual.Position
    end
    local ok, pivot = pcall(function() return visual:GetPivot().Position end)
    return ok and pivot or nil
end

local function coinIsCollectible(visual)
    if not (visual and visual.Parent) then
        return false
    end
    if visual:GetAttribute("Collected") or visual:GetAttribute("Delete") then
        return false
    end
    local skipUntil = visualSkipUntil[visual]
    if skipUntil and nowReal() < skipUntil then
        return false
    end
    return true
end

-- ระหว่างเดิน: ถ้ามีแคนดี้ใหม่โผล่ใกล้กว่าชิ้นที่กำลังไปมากพอ = เปลี่ยนเป้าทันที
--   กันอาการ "เดินผ่าน/ยืนอยู่ใกล้แคนดี้ที่เพิ่งเกิด แต่ไม่ยอมไปเก็บ"
--   เพราะ tween ที่ตั้งเป้าไว้แล้วจะไม่เปลี่ยนเป้าจนกว่าจะถึงจุดเดิม
local RETARGET_MARGIN = 8      -- ต้องใกล้กว่าอย่างน้อยกี่ studs ถึงจะเปลี่ยนเป้า
local RETARGET_RADIUS = 45     -- สนใจเฉพาะแคนดี้ที่อยู่ในรัศมีนี้
local RETARGET_CHECK = 0.25    -- เช็คทุกกี่วินาที

local function findBetterCoin(currentVisual, currentPos, hrpPos)
    local bestVisual, bestDist = nil, math.huge

    for _, visual in ipairs(CollectionService:GetTagged("CoinVisual")) do
        if visual ~= currentVisual and coinIsCollectible(visual) then
            local pos = visualPos(visual)
            if pos then
                local d = (hrpPos - pos).Magnitude
                if d < bestDist then
                    bestDist = d
                    bestVisual = visual
                end
            end
        end
    end

    if not bestVisual or bestDist > RETARGET_RADIUS then
        return nil
    end

    local currentDist = (hrpPos - currentPos).Magnitude
    if bestDist + RETARGET_MARGIN < currentDist then
        return bestVisual, bestDist
    end

    return nil
end

local function tweenOnce(target, currentVisual)
    local hrp = humanoidRootPart
    if not (hrp and hrp.Parent) then return false end

    local from = hrp.Position

    -- ── เก็บด้วย "หัว" (ตัวละครอยู่ใต้ดิน) ─────────────────────────────
    -- ยอดหัวอยู่พ้นระดับ trigger แค่ TOUCH_MARGIN → เห็นแค่หัวนิดเดียว
    -- ส่วนลำตัว/ขาอยู่ใต้พื้นทั้งหมด
    local goalY = headTargetY(target.Y)
    local goal = Vector3.new(target.X, goalY, target.Z)

    local distance = (goal - from).Magnitude

    -- เก็บทิศหันเดิม ไม่ให้ CFrame.new() รีเซ็ตการหมุน
    local rot = hrp.CFrame - hrp.CFrame.Position
    local goalCFrame = CFrame.new(goal) * rot
    lastGoalCFrame = goalCFrame

    if distance < 1 then
        pcall(function()
            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero
        end)
        return true
    end

    local duration = math.max(distance / SPEED, 0.05)
    local ok, tween = pcall(function()
        return TweenService:Create(
            hrp,
            TweenInfo.new(duration, Enum.EasingStyle.Linear),
            { CFrame = goalCFrame }
        )
    end)
    if not ok or not tween then return false end

    local done = false
    local conn
    conn = tween.Completed:Connect(function() done = true end)
    tween:Play()

    -- ตัวจับค้าง: ถ้าตำแหน่งจริงไม่เข้าใกล้เป้าเลยใน TWEEN_STUCK_SEC = ปล่อย
    --   (เทียบกับ "จุดที่ควรอยู่ ณ เวลานี้" ไม่ใช่ตำแหน่งที่เราเพิ่งเขียนเอง)
    local t0 = nowReal()
    local lastCheck = t0
    local lastRetargetCheck = t0
    local bestGap = math.huge
    local noGainAt = t0

    while not done do
        task.wait(0.05)

        local hrpNow = humanoidRootPart
        if not (hrpNow and hrpNow.Parent) then
            pcall(function() tween:Cancel() end)
            if conn then pcall(function() conn:Disconnect() end) end
            return false
        end

        local now = nowReal()

        -- เป้าหายกลางทาง (ถูกเก็บไปแล้ว/despawn) = ไม่ต้องเดินต่อให้เสียเวลา
        if currentVisual and not coinIsCollectible(currentVisual) then
            pcall(function() tween:Cancel() end)
            if conn then pcall(function() conn:Disconnect() end) end
            return false, nil, true
        end

        -- มีแคนดี้ใหม่ใกล้กว่าเดิมมาก = เปลี่ยนเป้าทันที ไม่ต้องรอถึงจุดเก่า
        if currentVisual and now - lastRetargetCheck >= RETARGET_CHECK then
            lastRetargetCheck = now
            local better, betterDist = findBetterCoin(currentVisual, target, hrpNow.Position)
            if better then
                pcall(function() tween:Cancel() end)
                if conn then pcall(function() conn:Disconnect() end) end
                return false, better
            end
        end

        if now - lastCheck >= 1 then
            lastCheck = now
            local alpha = math.clamp((now - t0) / duration, 0, 1)
            local want = from:Lerp(goal, alpha)
            local gap = (hrpNow.Position - want).Magnitude

            if gap < bestGap - 0.5 then
                bestGap = gap
                noGainAt = now
            elseif now - noGainAt >= TWEEN_STUCK_SEC then
                -- ตัวละครไม่ขยับตามที่ tween สั่ง (ถูกดึงกลับ/ติดอะไร) = เลิก
                pcall(function() tween:Cancel() end)
                if conn then pcall(function() conn:Disconnect() end) end
                return false
            end
        end
    end

    if conn then pcall(function() conn:Disconnect() end) end
    return true
end

local function tweenToPosition(targetPosition, currentVisual)
    local attempts = 0

    while attempts < TWEEN_MAX_TRY do
        attempts = attempts + 1

        local reached = arrivedAt(targetPosition)
        if reached then
            -- อยู่จุดเก็บแล้ว → ล็อคตำแหน่งนี้ไว้
            if humanoidRootPart and humanoidRootPart.Parent then
                sinkHold = humanoidRootPart.CFrame
            end
            return true
        end

        -- ตาย/เกิดใหม่กลางทาง = อ่าน hrp ใหม่ทุกครั้ง (ตัวแปรอัปเดตใน main loop)
        if not (humanoidRootPart and humanoidRootPart.Parent) then return false end

        tweenRunning = true
        local okCall, _, better, lost = pcall(tweenOnce, targetPosition, currentVisual)
        tweenRunning = false
        if not okCall then
            better, lost = nil, nil
        end
        if better or lost then
            -- เปลี่ยนเป้า/เป้าหาย — คืนทันที ให้ลูปหลักเลือกใหม่จากตำแหน่งจริง
            --   ล็อคตำแหน่งปัจจุบันไว้ ไม่ให้เด้งกลับไปจุดเก็บเดิม
            if humanoidRootPart and humanoidRootPart.Parent then
                sinkHold = humanoidRootPart.CFrame
            end
            return false, better
        end

        -- ถึงเป้าจริงหรือยัง (เช็คจากตำแหน่งที่เกมรายงานกลับมา)
        if arrivedAt(targetPosition) then
            -- ล็อคตำแหน่งใต้ดินไว้ระหว่างรอ ack / เลือกชิ้นถัดไป
            --   ไม่งั้นฟิสิกส์จะดันตัวขึ้นจากพื้นทันทีที่ tween จบ
            sinkHold = lastGoalCFrame
            return true
        end

        -- รอบนี้ "ไม่ถึงเป้า" (เส้นทางปกติจะไม่มาถึงตรงนี้) → พักสั้นๆ ก่อนยิงใหม่
        --   ยิง CFrame ซ้ำติดกันทุกเฟรมตอนไปไม่ถึง = ตัวสั่นรัว ไม่มีประโยชน์
        if attempts < TWEEN_MAX_TRY then
            -- ล็อคตำแหน่งปัจจุบันไว้ก่อนพัก (กันเด้งกลับจุดเก็บเดิม/ถูกดันขึ้น)
            if humanoidRootPart and humanoidRootPart.Parent then
                sinkHold = humanoidRootPart.CFrame
            end
            task.wait(0.08)
        end
    end

    -- ถึงหรือไม่ก็หยุด velocity ไม่ให้ไถลต่อ
    pcall(function()
        if humanoidRootPart and humanoidRootPart.Parent then
            humanoidRootPart.AssemblyLinearVelocity = Vector3.zero
            humanoidRootPart.AssemblyAngularVelocity = Vector3.zero
            -- ล็อคตำแหน่งปัจจุบันไว้ (ไม่ให้ฟิสิกส์ดันขึ้น/เด้งกลับ)
            sinkHold = humanoidRootPart.CFrame
        end
    end)

    return false
end

-- ── ล็อคตำแหน่ง (กันฟิสิกส์ดันตัวขึ้น / ซ่อนตัว) ──────────────────────
--   ระหว่าง tween ปล่อยให้ TweenService คุม CFrame
--   พอ tween จบ (ช่วงรอ ack / เลือกชิ้นถัดไป) = เขียน CFrame ทุกเฟรมเอง
--   เพราะตัวถูกวางไว้ใต้พื้น ฟิสิกส์จะดันขึ้นทันทีถ้าไม่ล็อค
--
--   lobbyLock = อยู่ใน Lobby → ล็อคไว้ 10 studs ใต้ตำแหน่งเดิม
--   (ไม่ใช้ Anchored เพราะต้องการให้ตำแหน่งถูก replicate ให้คนอื่นเห็น)
RunService.Heartbeat:Connect(function()
    if tweenRunning then return end

    local char = player.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local targetCFrame = nil
    if lobbyLock then
        if lobbyPinChar ~= char then
            -- ตัวใหม่/respawn ใน Lobby → TP ลงใต้ตัวเอง 10 studs
            lobbyPinChar = char
            lobbyPin = hrp.CFrame - Vector3.new(0, 10, 0)
        end
        targetCFrame = lobbyPin
    elseif sinkHold then
        targetCFrame = sinkHold
    end

    if targetCFrame then
        hrp.CFrame = targetCFrame
        hrp.AssemblyLinearVelocity = Vector3.zero
        hrp.AssemblyAngularVelocity = Vector3.zero
    end
end)

-- ฟังก์ชันค้นหา CoinContainer ใน workspace
local function findCoinContainer()
    for _, parent in ipairs(workspace:GetChildren()) do
        local coinContainer = parent:FindFirstChild("CoinContainer")
        if coinContainer then
            return coinContainer
        end
    end
    return nil
end

-- (visualSkipUntil / coinIsCollectible ประกาศไว้ด้านบนแล้ว ก่อน tweenOnce)

-- ฟังก์ชันหาเหรียญที่ใกล้ที่สุด (คืน CoinVisual ไม่ใช่ Coin_Server)
local function findNearestCoin()
    local hrp = humanoidRootPart
    if not (hrp and hrp.Parent) then
        return nil, math.huge
    end

    -- แหล่งหลัก: tag เดียวกับที่ CoinVisualizer ของเกมใช้
    local candidates = {}
    for _, visual in ipairs(CollectionService:GetTagged("CoinVisual")) do
        candidates[#candidates + 1] = visual
    end

    -- fallback: ถ้า tag ยังไม่มา ให้สแกนจาก CoinContainer
    --   (ต้องมีลูก CoinVisual อยู่จริง — ช่องที่ถูกเก็บแล้วไม่มีลูก = ข้าม)
    if #candidates == 0 then
        local coinContainer = findCoinContainer()
        if coinContainer then
            for _, coin in ipairs(coinContainer:GetChildren()) do
                local visual = coin:FindFirstChild("CoinVisual")
                if visual then
                    candidates[#candidates + 1] = visual
                end
            end
        end
    end

    local nearestVisual = nil
    local shortestDistance = math.huge
    local hrpPos = hrp.Position

    for _, visual in ipairs(candidates) do
        if coinIsCollectible(visual) then
            local pos = visualPos(visual)
            if pos then
                -- ถ่วงระยะแนวตั้ง (x1.5) → เลือกเหรียญระดับเดียวกันก่อน
                --   ลดการวิ่งขึ้น-ลงสลับชั้นรัวๆ ซึ่งทำให้ตัวดูกระตุกขึ้นลง
                local dxz = Vector3.new(pos.X - hrpPos.X, 0, pos.Z - hrpPos.Z).Magnitude
                local dy = (pos.Y - hrpPos.Y) * 1.5
                local distance = math.sqrt(dxz * dxz + dy * dy)
                if distance < shortestDistance then
                    shortestDistance = distance
                    nearestVisual = visual
                end
            end
        end
    end

    return nearestVisual, shortestDistance
end

-- ฟังก์ชันเปิดกล่อง Halloween จนได้ Embersickle
-- ใช้ Halloween Key ก่อน เมื่อ key หมดจึงใช้ Candies
local function openHalloweenBoxes()
    if not Config.Embersickle or doneSent then return end

    local success, err = pcall(function()
        if hasEmbersickle() then return end

        local ProfileData = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("ProfileData"))
        local openCrate = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Shop"):WaitForChild("OpenCrate")
        local ctx = getEventContext()

        local keyPrice = getBoxPrice(ctx.keyName, 1)
        local candyPrice = getBoxPrice(ctx.currencyName, 600)  -- Halloween Box '26 = 600 Candies

        -- จำกัดจำนวนต่อรอบ กันลูปฟาร์มค้างนาน
        local maxPerRun = 30
        local opened = 0

        while opened < maxPerRun do
            local keyCount = ProfileData.Materials.Owned[ctx.keyName] or 0
            local candyCount = ProfileData.Materials.Owned[ctx.currencyName] or 0

            -- ใช้ key ก่อน แล้วค่อยใช้ candies
            local currency = nil
            if keyCount >= keyPrice then
                currency = ctx.keyName
            elseif candyCount >= candyPrice then
                currency = ctx.currencyName
            end

            if not currency then
                break
            end

            local boxSuccess, reward = pcall(function()
                return openCrate:InvokeServer(ctx.boxId, "MysteryBox", currency)
            end)

            if not boxSuccess or not reward then
                break
            end

            -- reward ที่เซิร์ฟเวอร์คืนมาเป็น "array ของ entry" ({ {RewardedItemId=...}, ... })
            -- หรือ string เดี่ยว — รองรับทั้งคู่ และต้องจับ Chroma Embersickle ด้วย
            -- (ชื่อ chroma ใน Sync = ชื่อฐาน + "Chroma" หรือ "Chroma" + ชื่อฐาน)
            local rewardIds = {}
            if type(reward) == "table" then
                if reward.RewardedItemId or reward.ItemId or reward.Name then
                    rewardIds[1] = reward.RewardedItemId or reward.ItemId or reward.Name
                else
                    for _, entry in pairs(reward) do
                        if type(entry) == "table" then
                            rewardIds[#rewardIds + 1] = entry.RewardedItemId or entry.ItemId or entry.Name
                        elseif type(entry) == "string" then
                            rewardIds[#rewardIds + 1] = entry
                        end
                    end
                end
            else
                rewardIds[1] = reward
            end

            local gotEmbersickle = false
            for _, id in ipairs(rewardIds) do
                if isEmbersickleName(tostring(id)) then
                    gotEmbersickle = true
                    print("[Embersickle] ได้รับจากกล่อง: " .. tostring(id))
                    break
                end
            end

            if gotEmbersickle then
                -- รอให้ inventory อัปเดตจริงก่อน (ChangeInventoryItem มาจากเซิร์ฟเวอร์)
                -- แล้วค่อยให้ maybeSendDone เห็นของจริงในลูปถัดไป
                for _ = 1, 20 do
                    if refreshEmbersickle() then break end
                    task.wait(0.1)
                end
                break
            end

            -- เผื่อเซิร์ฟเวอร์คืนค่าเป็น ID/ชื่ออื่น — เช็ค inventory จริงอีกครั้ง
            if refreshEmbersickle() then
                break
            end

            opened = opened + 1

            -- ถ้ายอดเงินไม่ลดเลย แสดงว่าเซิร์ฟเวอร์ปฏิเสธ → หยุด
            local newKeyCount = ProfileData.Materials.Owned[ctx.keyName] or 0
            local newCandyCount = ProfileData.Materials.Owned[ctx.currencyName] or 0
            if newKeyCount >= keyCount and newCandyCount >= candyCount then
                warn("[DEBUG] Box open rejected by server")
                break
            end

            updateCurrencyLabels()
            task.wait(1)
        end
    end)

    if not success then
        warn("[DEBUG] openHalloweenBoxes Error:", tostring(err))
    end
end

-- ฟังก์ชันเปิดกล่องด้วย Coins
local function openCoinsBoxes()
    if not Config.CoinsBox then return end

    local success, err = pcall(function()
        local ProfileData = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("ProfileData"))
        local openCrate = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Shop"):WaitForChild("OpenCrate")

        local boxesOpened = 0

        while true do
            -- เช็คจำนวน Coins ปัจจุบัน
            local coins = ProfileData.Materials.Owned["Coins"] or 0

            -- ถ้าน้อยกว่า 1000 หยุดเปิด
            if coins < 1000 then
                break
            end

            -- เปิดกล่อง 1 รอบ (1000 coins)
            local boxSuccess, boxResult = pcall(function()
                return openCrate:InvokeServer(Config.CoinsBox, "MysteryBox", "Coins")
            end)

            if boxSuccess and boxResult then
                boxesOpened = boxesOpened + 1

                -- อัปเดต GUI ทันที
                updateCurrencyLabels()
            else
                break
            end

            -- รอเล็กน้อยก่อนเปิดรอบถัดไป
            task.wait(1)
        end

        return boxesOpened
    end)

    if not success then
        warn("[DEBUG] openCoinsBoxes Error:", tostring(err))
    end
end

-- ฟังก์ชัน Hop Server
local function hopServer()
    local TeleportService = game:GetService("TeleportService")

    while true do
        local success, result = pcall(function()
            -- ใช้ TeleportService:Teleport() ธรรมดา จะสุ่มหาเซิร์ฟให้เอง
            TeleportService:Teleport(game.PlaceId, player)
        end)

        if success then
            break
        else
            warn("[DEBUG] Teleport failed:", tostring(result))
            -- รอก่อนลองใหม่
            task.wait(3)
        end
    end
end

-- เช็คจำนวนคนในเซิร์ฟเวอร์ตลอดเวลา ถ้าน้อยกว่า 5 คนให้ hop server ทันที (แยก thread)
task.spawn(function()
    while true do
        if #Players:GetPlayers() < 5 then
            hopServer()
            break
        end
        task.wait(1)
    end
end)

-- ส่ง Description ครั้งแรกก่อนเริ่มลูป
sendDescription()
lastDescriptionTime = tick()

-- ลูปหลัก
while true do
    local success, result = pcall(function()
        -- โหมด Embersickle: เปิดกล่อง Halloween จนได้ Embersickle
        -- (ตรวจเฉพาะตอนที่ยังไม่ได้ Embersickle — หลังได้แล้วไม่ต้องสแกนซ้ำทุก loop)
        if Config.Embersickle and not doneSent then
            local openSuccess, openError = pcall(openHalloweenBoxes)

            if not openSuccess then
                warn("[DEBUG] Box Opening Error:", tostring(openError))
            end
        end

        -- เช็คและเปิดกล่องด้วย Coins ถ้า Config.CoinsBox ตั้งค่าไว้
        if Config.CoinsBox then
            local coinBoxSuccess, coinBoxError = pcall(function()
                local ProfileData = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("ProfileData"))
                local currentCoins = ProfileData.Materials.Owned["Coins"] or 0

                if currentCoins >= 1000 then
                    openCoinsBoxes()
                end
            end)

            if not coinBoxSuccess then
                warn("[DEBUG] Coin Box Opening Error:", tostring(coinBoxError))
            end
        end

        -- ส่ง DONE เฉพาะเมื่อได้ Embersickle และ Config.Embersickle = true
        maybeSendDone()

        -- ส่ง Description ทุก 30 วิ (ถ้าส่ง DONE แล้ว thread ทุก 3 วิ รับหน้าที่ต่อ)
        if not doneSent and tick() - lastDescriptionTime >= DESCRIPTION_INTERVAL then
            sendDescription()
            lastDescriptionTime = tick()
        end

        -- อัปเดต character และ humanoidRootPart ใหม่ทุกรอบ
        character = player.Character or player.CharacterAdded:Wait()

        -- respawn แล้วให้เริ่มนับ Full ใหม่ (GUI bag ถูกรีเซ็ต)
        if character ~= lastCharacter then
            lastCharacter = character
            bagWasFull = false
            collectAttempts = 0
            -- ตัวใหม่ = CFrame ล็อคเดิมใช้ไม่ได้แล้ว
            sinkHold = nil
            -- วัดระยะหัวกับ HRP จากตัวจริง (R6/R15 คนละความสูง)
            local newHrp = character:FindFirstChild("HumanoidRootPart")
            local head = character:FindFirstChild("Head")
            if newHrp and head then
                local lift = head.Position.Y - newHrp.Position.Y
                if lift > 0.2 and lift < 3 then
                    headLift = lift
                end
                local half = head.Size.Y * 0.5
                if half > 0.2 and half < 1.5 then
                    headHalf = half
                end
            end
        end

        humanoidRootPart = character:WaitForChild("HumanoidRootPart")

        -- หา MainGUI ใหม่ทุกรอบ (เพราะถูกลบ/สร้างใหม่ตอน teleport)
        local playerGui = player:WaitForChild("PlayerGui")
        local mainGUI = playerGui:WaitForChild("MainGUI", 10)

        if not mainGUI then
            wait(1)
            return
        end

        local gameUI = mainGUI:WaitForChild("Game", 10)
        if not gameUI then
            wait(1)
            return
        end

        -- เช็คว่าอยู่ใน Lobby หรือแมพฟาร์ม
        -- Menu_GUI.client.lua: EarnedXP.Visible = true เฉพาะบทบาท Innocent
        --   บทบาทอื่น (Murderer/Sheriff) ใช้ Timer.Visible = true แทน
        --   → ต้องเช็คทั้งคู่ ไม่งั้นรอบที่ไม่ใช่ Innocent จะไม่ฟาร์มเลย
        -- (ของเดิมอ่าน XPText + task.wait(0.05) ทุกรอบ = บวกดีเลย์ให้ทุกการเก็บ)
        local earnedXP = gameUI:WaitForChild("EarnedXP", 5)
        if not earnedXP then
            wait(1)
            return
        end

        local timerFrame = gameUI:FindFirstChild("Timer")
        local inGame = earnedXP.Visible or (timerFrame ~= nil and timerFrame.Visible)

        if not inGame then
            -- อยู่ใน Lobby → ล็อคตัวไว้ 10 studs ใต้ตำแหน่งเดิม
            --   (Heartbeat จะคอยปัก CFrame ไว้เอง)
            lobbyLock = true
            sinkHold = nil
            character = player.Character or player.CharacterAdded:Wait()
            humanoidRootPart = character:WaitForChild("HumanoidRootPart")
            task.wait(0.5)
            return
        end

        -- เข้าแมพฟาร์มแล้ว = ปลดล็อค Lobby
        lobbyLock = false
        lobbyPinChar = nil
        lobbyPin = nil

        character = player.Character or player.CharacterAdded:Wait()
        humanoidRootPart = character:WaitForChild("HumanoidRootPart")

        local coinBags = gameUI:FindFirstChild("CoinBags")
        if not coinBags then task.wait(0.1) return end

        local container = coinBags:FindFirstChild("Container")
        if not container then task.wait(0.1) return end

        -- หา bag ที่เกมกำลังใช้งาน (Halloween = Candy, ปกติ = Coin)
        -- ใช้ frame ที่ Visible ตัวแรกที่มีช่องตัวเลข (CoinsStarted เปิดเฉพาะ bag ของอีเวนท์)
        local activeBag, bagCountText, bagFullFrame = nil, nil, nil
        for _, frame in ipairs(container:GetChildren()) do
            if frame:IsA("Frame") and frame.Visible then
                local currencyFrame = frame:FindFirstChild("CurrencyFrame")
                local icon = currencyFrame and currencyFrame:FindFirstChild("Icon")
                local coinsText = icon and icon:FindFirstChild("Coins")

                if coinsText then
                    activeBag = frame
                    bagCountText = coinsText
                    bagFullFrame = frame:FindFirstChild("Full")
                    break
                end
            end
        end

        if not activeBag then task.wait(0.1) return end

        -- อ่านสถานะกระเป๋าสดๆ (เรียกซ้ำได้หลังเก็บแต่ละชิ้น)
        --   ความจุจริงของผู้เล่นคนนี้ (จาก CoinCollected: a3) — แต่ละคนขนาดไม่เท่ากัน
        --   bagCaps ผูกตามชื่อ bag; lastCap คือค่าล่าสุดของรอบนี้ (มี bag เดียวที่ใช้งานต่อรอบ)
        --   ถ้ายังไม่เคยได้ค่าจาก remote = nil (ไม่ใช้ตัวเลขเดา)
        local function readBag()
            local amount = tonumber(bagCountText.Text) or 0
            local cap = bagCaps[activeBag.Name] or lastCap
            local full = (bagFullFrame ~= nil and bagFullFrame.Visible)
                or (cap ~= nil and amount >= cap)
            return amount, full
        end

        local _, bagFull = readBag()

        -- กระเป๋าเต็ม: เชื่อสัญญาณเกม (Full.Visible = a3 <= a2) หรือจำนวนถึง cap จริง
        --   + fallback: ไปถึงเหรียญแล้วของไม่เข้าติดกันหลายครั้ง (เช่น กระเป๋าเต็มแต่ UI ยังไม่ขึ้น)
        local isBagFull = bagFull or (collectAttempts >= MAX_FAILED_COLLECTS)

        if isBagFull then
            -- กัน BreakJoints ซ้ำตอน Full ค้างหลัง respawn
            if not bagWasFull then
                bagWasFull = true
                sinkHold = nil -- ปล่อยตัวก่อนตาย (กัน Heartbeat ปักศพเดิม)
                character:BreakJoints()
                task.wait(1)
                if Config.HopBagFull then
                    hopServer()
                end
            else
                task.wait(0.2)
            end
        else
            bagWasFull = false

            -- ยังไม่เต็ม - ฟาร์มตามปกติ
            -- หา CoinVisual ที่ยังเก็บได้ (ไม่ใช่ Coin_Server ที่อยู่ถาวร)
            local targetVisual = findNearestCoin()

            -- เดินตามเป้า; ถ้าระหว่างทางเจอชิ้นที่ใกล้กว่ามากจะเปลี่ยนเป้าให้ทันที
            --   (สูงสุด 8 ครั้ง กันวนไม่จบ)
            --   เก็บได้แล้วเลือกชิ้นถัดไปต่อในลูปเดิมทันที (ไม่กลับไปเริ่มลูปหลัก)
            for _ = 1, 8 do
                if not targetVisual then
                    -- ไม่มีเหรียญให้เก็บแล้ว (รอรอบใหม่) — หน่วงสั้นๆ กัน busy loop
                    task.wait(0.1)
                    break
                end

                local targetPos = visualPos(targetVisual)
                if not targetPos then break end

                local serialBefore = collectSerial
                local reached, retarget = tweenToPosition(targetPos, targetVisual)

                if retarget then
                    targetVisual = retarget
                elseif not coinIsCollectible(targetVisual) then
                    -- เป้าหายกลางทาง (ถูกเก็บไปแล้ว ไม่ว่าใครเก็บ) → เลือกชิ้นถัดไปทันที
                    targetVisual = findNearestCoin()
                else
                    -- ถึงแล้ว: "เก็บปุ๊บ ไปปั๊บ"
                    --   รอ CoinCollected (สัญญาณจากเซิร์ฟเวอร์ว่าเก็บสำเร็จ) แค่สั้นๆ
                    --   ถ้าเกมทำเครื่องหมาย Collected/Delete แล้ว ก็ไปต่อได้ทันทีเช่นกัน
                    local gotIt = false
                    if reached then
                        local deadline = nowReal() + COLLECT_ACK_WAIT
                        while nowReal() < deadline do
                            if collectSerial ~= serialBefore then break end
                            if not coinIsCollectible(targetVisual) then break end
                            task.wait(0.02)
                        end

                        -- สำเร็จเมื่อ: remote ยืนยัน (ของเข้ากระเป๋า) หรือเกมทำเครื่องหมายว่าเก็บแล้ว
                        gotIt = (collectSerial ~= serialBefore)
                            or not coinIsCollectible(targetVisual)
                    end

                    if gotIt then
                        collectAttempts = 0
                        -- กันเลือกชิ้นเดิมซ้ำระหว่างที่ visual ยังไม่ถูกลบ (ลบจริงหลัง 0.5 วิ)
                        if targetVisual.Parent then
                            visualSkipUntil[targetVisual] = nowReal() + 0.5
                        end
                        -- เก็บชิ้นนี้แล้วกระเป๋าเต็มพอดี → หยุดเก็บทันที (ไม่ไปชิ้นถัดไปให้เสียเวลา)
                        local _, nowFull = readBag()
                        if nowFull then break end
                        -- เว้นจังหวะสั้นๆ ก่อนไปชิ้นถัดไป
                        task.wait(COLLECT_CHAIN_DELAY)
                        -- ไปชิ้นถัดไปทันที (ไม่กลับไปเริ่มลูปหลัก)
                        targetVisual = findNearestCoin()
                    else
                        if reached then
                            -- ไปถึงแล้วแต่ของไม่เข้า = เป้านี้เอาไม่ได้ (เช่น กระเป๋าเต็ม)
                            collectAttempts = collectAttempts + 1
                        end
                        -- ถึงหรือไม่ถึง ก็ข้ามชิ้นนี้ชั่วคราวถ้ายังเก็บได้
                        --   กันลูปจมอยู่กับเหรียญที่เอาไม่ได้ (ติดกำแพง/อยู่นอกระยะ)
                        if targetVisual.Parent and coinIsCollectible(targetVisual) then
                            visualSkipUntil[targetVisual] = nowReal() + 0.5
                        end
                        break
                    end
                end
            end
        end
    end)

    if not success then
        warn("Error:", tostring(result))
        task.wait(0.5)
    end

    task.wait(0.01)
end
