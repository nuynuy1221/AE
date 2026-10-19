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
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local character = player.Character or player.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

-- ตั้งค่า
local SPEED = Config.TweenSpeed or 25
local TWEEN_MAX_TRY = 3        -- จำนวนรอบที่ยิง tween ซ้ำถ้ายังไม่ถึงเป้า
local TWEEN_STUCK_SEC = 5      -- ไม่เข้าใกล้ขึ้นกี่วินาที = ปล่อย
local TWEEN_ARRIVE_XZ = 3      -- ถือว่าถึงเป้าเมื่อห่างแนวนอนไม่เกินกี่ studs
local TWEEN_ARRIVE_Y = 6       -- tolerance แนวตั้ง
local DESCRIPTION_INTERVAL = 30 -- ส่ง Description ทุก 30 วิ
local lastDescriptionTime = 0
local doneSent = false -- เช็คว่าส่ง DONE ไปแล้วหรือยัง
local bagWasFull = false -- กัน BreakJoints ซ้ำรัวๆ ตอน Full ค้าง
local lastCharacter = nil -- ใช้รีเซ็ตสถานะเมื่อ respawn

-- เวลาจริง (ใช้ GetServerTimeNow เหมือน Fishing Master — ไม่นับเวลาเองด้วย os.clock)
local function nowReal()
    local ok, t = pcall(function() return workspace:GetServerTimeNow() end)
    if ok and type(t) == "number" and t > 0 then return t end
    ok, t = pcall(function() return DateTime.now():UnixTimestampMillis() / 1000 end)
    if ok and type(t) == "number" and t > 0 then return t end
    return os.time()
end


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
		local Sync = require(ReplicatedStorage:WaitForChild("Database"):WaitForChild("Sync"))
		local ctx = getEventContext()

		data.coins = ProfileData.Materials.Owned["Coins"] or 0
		data.candies = ProfileData.Materials.Owned[ctx.currencyName] or 0

		local owned = ProfileData.Weapons and ProfileData.Weapons.Owned
		if owned then
			local rarities = Sync.Rarities or {}
			for key, amount in pairs(owned) do
				amount = tonumber(amount) or 0
				local info = Sync.Weapons and Sync.Weapons[key]
				local name = info and (info.ItemName or info.Name) or tostring(key)

				if amount > 0 and name ~= "Default Knife" and name ~= "Default Gun" then
					local rarity = (info and info.Rarity) or "Common"
					-- Sort น้อย = หายากกว่า · ไม่รู้จัก = ต่อท้ายสุด
					local sort = (rarities[rarity] and rarities[rarity].Sort) or 999
					table.insert(data.items, {
						name = name,
						rarity = rarity,
						amount = amount,
						sort = sort,
					})
				end
			end
		end

		-- เรียงจากหายาก -> ธรรมดา (Sort น้อย = หายากกว่า)
		table.sort(data.items, function(a, b)
			if a.sort ~= b.sort then return a.sort < b.sort end
			return a.name < b.name
		end)
	end)

	return data
end

-- ── สร้างแถว "Item : ชื่อ1, ชื่อ2, ..." ─────────────────────────────
local function buildItemRow(data)
	local cells = { { t = "Item", c = COIN_COLOR, tail = ":" } }
	local list = data.items
	local n = math.min(#list, LOW_ITEM_MAX)

	for i = 1, n do
		local it = list[i]
		cells[#cells + 1] = {
			t = it.name,
			c = rarityColor3(it.rarity),
			tail = it.amount > 1 and (" x" .. it.amount) or nil,
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
local function getBoxPrice(currencyKey, fallback)
    local price = fallback

    pcall(function()
        local Sync = require(ReplicatedStorage:WaitForChild("Database"):WaitForChild("Sync"))
        local boxId = getEventContext().boxId
        local shopItem = Sync.NewShop and Sync.NewShop[boxId]
        local amount = shopItem and shopItem.Price and shopItem.Price[currencyKey]
        if amount then
            price = amount
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
local embersickleKey = nil
local lastEmbersickleScan = 0

local function resolveEmbersickleKey()
    local found = nil

    pcall(function()
        local Sync = require(ReplicatedStorage:WaitForChild("Database"):WaitForChild("Sync"))
        for _, tableName in ipairs({ "Weapons", "Materials" }) do
            local items = Sync[tableName]
            if items and not found then
                for itemKey, itemInfo in pairs(items) do
                    local name = itemInfo.ItemName or itemInfo.Name
                    if type(name) == "string" and string.lower(name) == "embersickle" then
                        found = itemKey
                        break
                    end
                end
            end
        end
    end)

    return found
end

local function getEmbersickleKey()
    -- สแกนซ้ำทุก 30 วิ เผื่อไอเทมถูก inject หลังจากสคริปต์เริ่มทำงาน
    if not embersickleKey and tick() - lastEmbersickleScan >= 30 then
        lastEmbersickleScan = tick()
        embersickleKey = resolveEmbersickleKey()
    end
    return embersickleKey
end

-- เช็คว่ามี Embersickle ใน inventory หรือยัง (cache 1 วิ กันสแกนถี่เกิน)
local cachedHasEmbersickle = false
local lastEmbersickleCheck = 0

local function checkHasEmbersickle()
    local owned = 0

    pcall(function()
        local ProfileData = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("ProfileData"))
        local key = getEmbersickleKey()

        if key then
            owned = (ProfileData.Weapons.Owned and ProfileData.Weapons.Owned[key])
                or (ProfileData.Materials.Owned and ProfileData.Materials.Owned[key])
                or 0
        end

        -- fallback: ค้นชื่อใน Owned (เผื่อ key ต่างจากที่คาด)
        if owned <= 0 then
            for _, group in ipairs({ "Weapons", "Materials" }) do
                local data = ProfileData[group]
                if data and data.Owned then
                    for itemKey, amount in pairs(data.Owned) do
                        if type(itemKey) == "string"
                            and string.find(string.lower(itemKey), "embersickle")
                            and (tonumber(amount) or 0) > 0 then
                            owned = tonumber(amount) or 1
                            break
                        end
                    end
                end
                if owned > 0 then
                    break
                end
            end
        end
    end)

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

-- รวมรายการไอเทมใน inventory
local function collectInventoryNames()
    local itemNames = {}
    local playerGui = player:FindFirstChild("PlayerGui")

    if not playerGui then return itemNames end

    local mainGUI = playerGui:FindFirstChild("MainGUI")
    local gameUI = mainGUI and mainGUI:FindFirstChild("Game")
    local inventory = gameUI and gameUI:FindFirstChild("Inventory")
    local main = inventory and inventory:FindFirstChild("Main")
    local weapons = main and main:FindFirstChild("Weapons")
    local items = weapons and weapons:FindFirstChild("Items")
    local container = items and items:FindFirstChild("Container")
    local current = container and container:FindFirstChild("Current")
    local currentContainer = current and current:FindFirstChild("Container")

    if not currentContainer then return itemNames end

    for _, item in ipairs(currentContainer:GetChildren()) do
        if item:IsA("Frame") or item:IsA("ImageLabel") then
            local itemName = item:FindFirstChild("ItemName")
            local label = itemName and itemName:FindFirstChild("Label")
            if label and label.Text and label.Text ~= "Default Gun" and label.Text ~= "Default Knife" then
                local name = label.Text
                local amount = 1

                -- วิธีที่ 1: NewItem > Container > Amount
                local newItem = item:FindFirstChild("NewItem")
                local newItemContainer = newItem and newItem:FindFirstChild("Container")
                local amountObj = newItemContainer and newItemContainer:FindFirstChild("Amount")
                if amountObj and amountObj.Text then
                    local numStr = string.match(amountObj.Text, "x?(%d+)")
                    if numStr then
                        amount = tonumber(numStr) or 1
                    end
                end

                -- วิธีที่ 2: สแกน TextLabel ที่มี pattern x2, x3
                if amount == 1 then
                    for _, child in ipairs(item:GetDescendants()) do
                        if child:IsA("TextLabel") or child:IsA("TextButton") then
                            if child.Text and string.match(child.Text, "x%d+") then
                                local numStr = string.match(child.Text, "x(%d+)")
                                if numStr then
                                    amount = tonumber(numStr) or 1
                                    break
                                end
                            end
                        end
                    end
                end

                if amount > 1 then
                    table.insert(itemNames, name .. " x" .. amount)
                else
                    table.insert(itemNames, name)
                end
            end
        end
    end

    return itemNames
end

-- สร้างข้อความ Description (ไม่แสดง Halloween Keys)
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
        "🎮 MM2 • Coins: %d • Candies: %d • %s",
        coins,
        candies,
        os.date("%d/%m/%y")
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
        print("[DONE] Embersickle obtained")

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
local function arrivedAt(target)
    local hrp = humanoidRootPart
    if not (hrp and hrp.Parent) then return false end
    local p = hrp.Position
    local dxz = Vector3.new(target.X - p.X, 0, target.Z - p.Z).Magnitude
    local dy = math.abs(target.Y - p.Y)
    return (dxz <= TWEEN_ARRIVE_XZ and dy <= TWEEN_ARRIVE_Y), dxz, dy
end

local function tweenOnce(target)
    local hrp = humanoidRootPart
    if not (hrp and hrp.Parent) then return false end

    local from = hrp.Position
    local distance = (target - from).Magnitude

    -- เก็บทิศหันเดิม ไม่ให้ CFrame.new() รีเซ็ตการหมุน
    local rot = hrp.CFrame - hrp.CFrame.Position

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
            { CFrame = CFrame.new(target) * rot }
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
        if now - lastCheck >= 1 then
            lastCheck = now
            local alpha = math.clamp((now - t0) / duration, 0, 1)
            local want = from:Lerp(target, alpha)
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

local function tweenToPosition(targetPosition)
    local attempts = 0

    while attempts < TWEEN_MAX_TRY do
        attempts = attempts + 1

        local reached = arrivedAt(targetPosition)
        if reached then return true end

        -- ตาย/เกิดใหม่กลางทาง = อ่าน hrp ใหม่ทุกครั้ง (ตัวแปรอัปเดตใน main loop)
        if not (humanoidRootPart and humanoidRootPart.Parent) then return false end

        tweenOnce(targetPosition)
        task.wait(0.15)

        -- ถึงเป้าจริงหรือยัง (เช็คจากตำแหน่งที่เกมรายงานกลับมา)
        if arrivedAt(targetPosition) then return true end
    end

    -- ถึงหรือไม่ก็หยุด velocity ไม่ให้ไถลต่อ
    pcall(function()
        if humanoidRootPart and humanoidRootPart.Parent then
            humanoidRootPart.AssemblyLinearVelocity = Vector3.zero
            humanoidRootPart.AssemblyAngularVelocity = Vector3.zero
        end
    end)

    return false
end

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

-- เช็คว่าเหรียญยังเก็บได้อยู่ไหม
-- ใช้ logic เดียวกับ CoinVisualizer ของเกม: ดู attribute Collected/Delete
-- (ไม่ใช้ Transparency เพราะ CoinVisual ถูกตั้งเป็น 1 เป็นค่าเริ่มต้น และ attribute ไม่ถูกดัมป์)
local function isCoinAvailable(coin)
    local visual = coin:FindFirstChild("CoinVisual")

    if visual then
        if visual:GetAttribute("Collected") or visual:GetAttribute("Delete") then
            return false
        end
        return true
    end

    if coin:IsA("BasePart") then
        return coin.CanTouch
    end

    return false
end

-- ฟังก์ชันหาเหรียญที่ใกล้ที่สุด
local function findNearestCoin(coins)
    local nearestCoin = nil
    local shortestDistance = math.huge

    for _, coin in ipairs(coins) do
        if coin and coin.Parent and (coin:IsA("BasePart") or coin:IsA("Model")) then
            if isCoinAvailable(coin) then
                local coinPos = coin:IsA("Model")
                    and coin:GetPivot().Position
                    or coin.Position

                local distance = (humanoidRootPart.Position - coinPos).Magnitude

                if distance < shortestDistance then
                    shortestDistance = distance
                    nearestCoin = coin
                end
            end
        end
    end

    return nearestCoin, shortestDistance
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
        local candyPrice = getBoxPrice(ctx.currencyName, 1000)

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

            if string.find(string.lower(tostring(reward)), "embersickle") then
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

        -- เช็คว่าอยู่ใน Lobby หรือแมพฟาร์ม - ดูจาก EarnedXP.Visible
        local earnedXP = gameUI:WaitForChild("EarnedXP", 5)
        if not earnedXP then
            wait(1)
            return
        end

        -- เช็คเพิ่มเติมจาก Timer.XPText ว่าเปลี่ยนแปลงหรือไม่
        local timer = gameUI:FindFirstChild("Timer")
        local xpText = timer and timer:FindFirstChild("XPText")
        local lastXPText = xpText and xpText.Text or ""

        task.wait(0.05)
        local currentXPText = xpText and xpText.Text or ""
        local xpTextChanged = (lastXPText ~= currentXPText)

        local inGame = earnedXP.Visible or xpTextChanged

        if not inGame then
            character = player.Character or player.CharacterAdded:Wait()
            humanoidRootPart = character:WaitForChild("HumanoidRootPart")
            task.wait(0.5)
            return
        end

        character = player.Character or player.CharacterAdded:Wait()
        humanoidRootPart = character:WaitForChild("HumanoidRootPart")

        local coinBags = gameUI:FindFirstChild("CoinBags")
        if not coinBags then task.wait(0.1) return end

        local container = coinBags:FindFirstChild("Container")
        if not container then task.wait(0.1) return end

        -- หา bag ที่เกมกำลังใช้งาน (Halloween = Candy, ปกติ = Coin)
        -- ใช้ frame ที่ Visible ตัวแรกที่มีช่องตัวเลข (CoinsStarted เปิดเฉพาะ bag ของอีเวนท์)
        local activeBag, coinAmount, bagFull = nil, 0, false
        for _, frame in ipairs(container:GetChildren()) do
            if frame:IsA("Frame") and frame.Visible then
                local currencyFrame = frame:FindFirstChild("CurrencyFrame")
                local icon = currencyFrame and currencyFrame:FindFirstChild("Icon")
                local coinsText = icon and icon:FindFirstChild("Coins")
                local fullFrame = frame:FindFirstChild("Full")

                if coinsText then
                    activeBag = frame
                    coinAmount = tonumber(coinsText.Text) or 0
                    bagFull = fullFrame ~= nil and fullFrame.Visible
                    break
                end
            end
        end

        if not activeBag then task.wait(0.1) return end

        -- เต็มเมื่อเกมแจ้ง Full หรือจำนวนถึง cap เดิม (40)
        local isBagFull = bagFull or coinAmount >= 40

        if isBagFull then
            -- กัน BreakJoints ซ้ำตอน Full ค้างหลัง respawn
            if not bagWasFull then
                bagWasFull = true
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

                -- หา CoinContainer
                local coinContainer = findCoinContainer()

                if coinContainer then
                    local coins = coinContainer:GetChildren()

                    if #coins > 0 then
                        local nearestCoin, distance = findNearestCoin(coins)

                        if nearestCoin and nearestCoin.Parent then
                            local coinPos = nearestCoin:IsA("Model")
                                and nearestCoin:GetPivot().Position
                                or nearestCoin.Position

                            tweenToPosition(coinPos)
                        end
                    end
                else
                    task.wait(0.1)
                end
            end
    end)

    if not success then
        warn("Error:", tostring(result))
        task.wait(0.5)
    end

    task.wait(0.01)
end
