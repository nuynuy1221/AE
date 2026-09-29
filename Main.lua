--[[
    Slayer 2 — Redeem Codes + Clan Reroll (Horst)

    Config (set _G.Config BEFORE running this script):
        Config.Horst = true|false
        Config.Code  = {"SLAYERS", "WELCOME", ...}          -- codes to redeem, any amount
        Config.Clan  = {"Kamado", "Rengoku", "Soyama", "Uzui"} -- stop when ANY of these is rolled

    Flow: redeem every code -> reroll clan until we hit a wanted clan (or spins run out)
          -> send Description to Horst -> send DONE -> stop.
]]

repeat task.wait() until game:IsLoaded()

if game.PlaceId ~= 16205713724 then
    return
end

-- ============================================
-- Config
-- ============================================
_G.Config = _G.Config or {}
local Config = _G.Config

Config.Horst    = Config.Horst == true
Config.Code     = Config.Code or {}   -- list of code strings
Config.Clan     = Config.Clan or {}   -- list of clan names, "any of these" = success
Config.RollDelay = Config.RollDelay or 0.6  -- seconds between spins
Config.CodeDelay = Config.CodeDelay or 0.7 -- seconds between code redeems

-- ============================================
-- Horst
-- ============================================
if Config.Horst then
    loadstring(game:HttpGet("https://raw.githubusercontent.com/HorstSpaceX/last_update/main/on_loaded.lua"))()
end

local HORST_MIN_INTERVAL = 30
local horstLastSend = 0

local function sendDescription(text, force)
    if not Config.Horst then return end
    if not _G.Horst_SetDescription then return end
    local now = os.clock()
    if not force and (now - horstLastSend) < HORST_MIN_INTERVAL then return end
    horstLastSend = now
    _G.Horst_SetDescription(text)
end

local function sendDone()
    if not Config.Horst then return end
    if _G.Horst_AccountChangeDone then
        _G.Horst_AccountChangeDone()
    end
end

-- ============================================
-- Services / Module refs
-- ============================================
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer       = Players.LocalPlayer

local function tryRequire(path, ...)
    local node = ReplicatedStorage
    for i = 1, select("#", ...) do
        node = node:FindFirstChild((select(i, ...)))
        if not node then return nil end
    end
    local ok, mod = pcall(require, node)
    if ok then return mod end
    return nil
end

local SignalFunction = tryRequire("Communication", "ServerAndClient", "Signals", "SignalFunction")
local ClanEvents     = tryRequire("CAM", "Global", "ClanEvents")
local SpinBalance    = tryRequire("CAM", "Global", "SpinBalance")

if not SignalFunction then
    print("[Redeem] ERROR: ไม่พบ SignalFunction module")
    return
end

local NOTHING = "$Nothing"

-- ============================================
-- Helpers: read clan spins
-- ============================================
-- ClanEvents.Folder(player) = Player_Service.Data.<Name>.ClanEvents
--   -> <ClanName>.Spins (NumberValue) = spins ที่ event ให้ (การันตีของ event)
local function eventSpinsLeft()
    local folder = ClanEvents and ClanEvents.Folder and ClanEvents.Folder(LocalPlayer) or nil
    if not folder then return 0 end
    local total = 0
    for _, clan in ipairs(folder:GetChildren()) do
        local spins = clan:FindFirstChild("Spins")
        if spins and typeof(spins.Value) == "number" then
            total = total + spins.Value
        end
    end
    return total
end

-- SpinBalance: Spinning.FreeClanSpins + Spinning.Spins + AccountSpins (spin ที่สะสมไว้)
-- ทุกฟังก์ชันของ SpinBalance รับ "slot" (Data.<Name>.slots.Slot<n>) เป็นตัวแรก
local function currentSlot()
    local Utility = tryRequire("CAM", "Global", "Utility")
    if Utility then
        local ok, slot = pcall(Utility.GetData, LocalPlayer)
        if ok and slot then return slot end
    end

    -- fallback: หา slot เอง (Utility ใช้ชื่อผู้เล่น หรือ <ชื่อ>-Studio ในสตูดิโอ)
    local data = ReplicatedStorage:FindFirstChild("Player_Service")
    data = data and data:FindFirstChild("Data")
    if not data then return nil end
    local root = data:FindFirstChild(LocalPlayer.Name) or data:FindFirstChild(LocalPlayer.Name .. "-Studio")
    if not root then return nil end
    local slots = root:FindFirstChild("slots")
    if not slots then return nil end
    local equipped = root:FindFirstChild("slotEquipped")
    local index = (equipped and equipped.Value) or 1
    return slots:FindFirstChild("Slot" .. index) or slots:GetChildren()[1]
end

local function balanceSpinsLeft()
    if not SpinBalance then return 0 end
    local slot = currentSlot()
    if not slot then return 0 end
    local ok, total = pcall(SpinBalance.Total, slot, true) -- true = ใช้ pool ของ Clan
    if ok and typeof(total) == "number" then return total end
    return 0
end

-- สุ่มได้ต่อถ้ายังมี spin อย่างน้อยทาง pool ใด pool หนึ่ง
local function spinsLeft()
    return math.max(eventSpinsLeft(), balanceSpinsLeft())
end

local function isWanted(clanName)
    if type(clanName) ~= "string" then return false end
    if clanName == NOTHING then return false end
    for _, want in ipairs(Config.Clan) do
        if type(want) == "string" and want:lower() == clanName:lower() then
            return true
        end
    end
    return false
end

-- ============================================
-- Step 1 — Redeem codes
-- ============================================
local redeemed, failed = {}, {}

for _, code in ipairs(Config.Code) do
    if type(code) == "string" and code ~= "" then
        local clean = code:upper()
        local ok, result = pcall(SignalFunction.ToServer, "RedeemCode", clean)
        if ok and result == true then
            table.insert(redeemed, clean)
            print("[Redeem] ใช้โค้ดสำเร็จ:", clean)
        else
            table.insert(failed, clean)
            print("[Redeem] ใช้โค้ดไม่ได้:", clean)
        end
        task.wait(Config.CodeDelay)
    end
end

-- ให้เซิร์ฟเวอร์อัปเดตค่า Spin หลังได้รับรางวัลจากโค้ดก่อนเริ่มสุ่ม
task.wait(1.5)

-- ============================================
-- Step 2 — Clan reroll
-- ============================================
local gotClan   = nil  -- clan ที่สุ่มได้ตรงกับ Config.Clan
local lastClan  = nil  -- clan ตัวล่าสุดที่สุ่มได้
local rolls     = 0

while true do
    if spinsLeft() <= 0 then break end

    local ok, result = pcall(SignalFunction.ToServer, "ClanSpin")
    if not ok or typeof(result) ~= "string" then
        break -- เซิร์ฟเวอร์ปฏิเสธ (spin ไม่พอ / ไม่พร้อม) = หยุด
    end

    rolls = rolls + 1
    lastClan = (result ~= NOTHING) and result or nil

    if isWanted(result) then
        gotClan = result
        break -- ได้อันที่ต้องการ -> หยุดทันที
    end

    task.wait(Config.RollDelay)
end

-- ============================================
-- Step 3 — Report + DONE
-- ============================================
local remaining = spinsLeft()

if gotClan then
    sendDescription(string.format(
        "⚔️ Slayer 2 • Clan: %s • Spins: %d",
        gotClan, remaining
    ), true)
    print(string.format("[Redeem] ได้ Clan ที่ต้องการ: %s (เหลือ %d Spin)", gotClan, remaining))
else
    sendDescription(string.format(
        "⚔️ Slayer 2 • ไม่ได้อันที่ต้องการ • ล่าสุด: %s • Spins: %d",
        lastClan or "ไม่มี", remaining
    ), true)
    print(string.format("[Redeem] ไม่ได้อันที่ต้องการ — ล่าสุดได้ %s (เหลือ %d Spin, สุ่ม %d ครั้ง)",
        lastClan or "ไม่มี", remaining, rolls))
end

sendDone()
