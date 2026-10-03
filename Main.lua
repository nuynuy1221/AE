--[[
    Slayer 2 — Redeem Codes + Clan Reroll (Horst)

    Config (set _G.Config BEFORE running this script):
        Config.Horst = true|false
        Config.Code  = {"SLAYERS", "WELCOME", ...}           -- codes to redeem, any amount
        Config.Clan  = {"Kamado", "Rengoku", "Soyama", "Uzui"} -- stop when ANY of these is rolled

    Flow: redeem every code -> reroll clan until we hit a wanted clan (or spins run out)
          -> send Description to Horst -> send DONE -> stop.

    ไม่ใช้ require() ของ module ใด ๆ ทั้งสิ้น — ยิง RemoteFunction ตรง ๆ
    เพื่อไม่ให้พังเวลา dependency ของเกมยังโหลดไม่ครบ
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
Config.Code     = Config.Code or {}    -- list of code strings
Config.Clan     = Config.Clan or {}    -- list of clan names, "any of these" = success
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
-- Services
-- ============================================
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer       = Players.LocalPlayer

-- ============================================
-- หา Remote ของ Signal
--   SignalFunction : ...Signals.SignalFunction.Function  (RemoteFunction)
--   SignalEvent    : ...Signals.SignalEvent.Event        (RemoteEvent)
--   ToServer(x, ...) == remote:InvokeServer(x, ...)  หรือ  remote:FireServer(x, ...)
-- ============================================
local function findSignalRemote(signalName, childName)
    local signals = ReplicatedStorage
        :FindFirstChild("Communication")
        and ReplicatedStorage.Communication:FindFirstChild("ServerAndClient")
        and ReplicatedStorage.Communication.ServerAndClient:FindFirstChild("Signals")
    if signals then
        local mod = signals:FindFirstChild(signalName)
        if mod then
            local r = mod:FindFirstChild(childName)
            if r then return r end
        end
    end

    -- fallback: ค้นทั้ง ReplicatedStorage แบบ recursive
    local function scan(node, depth)
        if depth > 6 then return nil end
        for _, child in ipairs(node:GetChildren()) do
            if child:IsA("ModuleScript") and child.Name == signalName then
                local r = child:FindFirstChild(childName)
                if r then return r end
            end
        end
        for _, child in ipairs(node:GetChildren()) do
            if child:IsA("Folder") or child:IsA("Model") then
                local found = scan(child, depth + 1)
                if found then return found end
            end
        end
        return nil
    end
    return scan(ReplicatedStorage, 0)
end

local Remote, EventRemote = nil, nil
-- รอสักพัก เผื่อ Communication / PackageLink โหลดช้า
for _ = 1, 15 do
    Remote      = findSignalRemote("SignalFunction", "Function")
    EventRemote = findSignalRemote("SignalEvent", "Event")
    if Remote then break end
    task.wait(1)
end

if not Remote then
    sendDone()
    return
end

-- wrapper เหมือน SignalFunction.ToServer
local function toServer(...)
    return Remote:InvokeServer(...)
end

-- ต้องยิงหลังสุ่มเสร็จทุกครั้ง ไม่งั้นเซิร์ฟเวอร์จะไม่ยอมให้สุ่มครั้งถัดไป
local function confirmSpin()
    if EventRemote then
        pcall(function() EventRemote:FireServer("ClanSpinComplete") end)
    end
end

-- ============================================
-- ดัก popup ยืนยันการรีดีมที่เซิร์ฟเวอร์ส่งมา
--   เซิร์ฟเวอร์ยิง "InferPopup" -> ServerSignals.InferPopup โชว์ popup -> รอผู้เล่นกด
--   ถ้าไม่มีใครกด ครบ Timeout (5 วิ) PopUpCreator จะยิงค่า default = ปุ่มสุดท้าย (Cancel)
--   ทำให้รีดีมไม่ผ่าน เราจึงตอบแทน โดยอ่านค่าจาก Options[1].Text สดๆ (ไม่เดาค่า "Yes")
-- ============================================
local autoConfirmRedeem = false

-- รอจนกว่า ServerSignals จะเซ็ต OnClientInvoke เสร็จ (Utility.Connect เซ็ตตรงนั้น)
for _ = 1, 30 do
    if type(Remote.OnClientInvoke) == "function" then break end
    task.wait(1)
end

local oldInvoke = Remote.OnClientInvoke
if type(oldInvoke) == "function" then
    Remote.OnClientInvoke = function(player, signalName, popupData, ...)
        if signalName == "InferPopup" and autoConfirmRedeem then
            -- ServerSignals.InferPopup คืนค่า = Text ของปุ่มที่ถูกกด
            -- ปุ่มแรกคือปุ่มยืนยัน (ปุ่มสุดท้ายถูกใช้เป็นค่า default ตอน timeout)
            local content = type(popupData) == "table" and popupData.Content
            local answer
            if type(content) == "table" and type(content.Options) == "table" then
                local first = content.Options[1]
                answer = (type(first) == "table") and first.Text or first
            end
            if type(answer) ~= "string" then answer = "Yes" end
            return answer
        end
        return oldInvoke(player, signalName, popupData, ...)
    end
end

-- ============================================
-- อ่านจำนวน Spin
--   Data root : ReplicatedStorage.Player_Service.Data.<ชื่อ หรือ <ชื่อ>-Studio>
--   event spin: <root>.ClanEvents.<ClanName>.Spins
--   สะสม spin : <root>.slots.Slot<n>.Spinning.FreeClanSpins + .Spins, และ <root>.AccountSpins
-- ============================================
local function dataRoot()
    local data = ReplicatedStorage:FindFirstChild("Player_Service")
    data = data and data:FindFirstChild("Data")
    if not data then return nil end
    return data:FindFirstChild(LocalPlayer.Name)
        or data:FindFirstChild(LocalPlayer.Name .. "-Studio")
end

-- รอให้ data โหลด (โหลดช้าในบางที)
local root
for _ = 1, 30 do
    root = dataRoot()
    if root then break end
    task.wait(1)
end
if not root then
    sendDone()
    return
end

local function numValue(node, name)
    if not node then return nil end
    local v = node:FindFirstChild(name)
    if v and v:IsA("ValueBase") and typeof(v.Value) == "number" then return v end
    return nil
end

local function eventSpinsLeft()
    local folder = root:FindFirstChild("ClanEvents")
    if not folder then return 0 end
    local total = 0
    for _, clan in ipairs(folder:GetChildren()) do
        local spins = numValue(clan, "Spins")
        if spins then total = total + spins.Value end
    end
    return total
end

local function balanceSpinsLeft()
    local total = 0
    local slots = root:FindFirstChild("slots")
    if slots then
        local equipped = numValue(root, "slotEquipped")
        local slot = slots:FindFirstChild("Slot" .. (equipped and equipped.Value or 1))
            or slots:GetChildren()[1]
        if slot then
            local spinning = slot:FindFirstChild("Spinning")
            if spinning then
                local v = numValue(spinning, "FreeClanSpins")
                if v then total = total + v.Value end
                v = numValue(spinning, "Spins")
                if v then total = total + v.Value end
            end
        end
    end
    local account = numValue(root, "AccountSpins")
    if account then total = total + account.Value end
    return total
end

-- สุ่มได้ต่อถ้ายังมี spin อย่างน้อยทาง pool ใด pool หนึ่ง
local function spinsLeft()
    return math.max(eventSpinsLeft(), balanceSpinsLeft())
end

local NOTHING = "$Nothing"

local function isWanted(clanName)
    if type(clanName) ~= "string" or clanName == NOTHING then return false end
    for _, want in ipairs(Config.Clan) do
        if type(want) == "string" and want:lower() == clanName:lower() then
            return true
        end
    end
    return false
end

-- ============================================
-- Step 1 — Redeem codes
--   เปิดดัก popup ยืนยันไว้เฉพาะช่วงนี้ แล้วปิดหลังเสร็จ
--   RedeemedCodes เก็บชื่อโค้ดที่รีดีมแล้ว (NumberValue = เวลาที่รีดีม)
-- ============================================
autoConfirmRedeem = true

for _, code in ipairs(Config.Code) do
    if type(code) == "string" and code ~= "" then
        local clean = code:upper()
        local redeemed = root:FindFirstChild("RedeemedCodes")
        if redeemed and redeemed:FindFirstChild(clean) then
            task.wait(Config.CodeDelay) -- ใช้ไปแล้ว ไม่ต้องยิงซ้ำ
        else
            pcall(toServer, "RedeemCode", clean)
            task.wait(Config.CodeDelay)
        end
    end
end

autoConfirmRedeem = false

-- ให้เซิร์ฟเวอร์อัปเดตค่า Spin หลังได้รางวัลจากโค้ดก่อนเริ่มสุ่ม
task.wait(1.5)

-- ============================================
-- Step 2 — Clan reroll
--   ยิง ClanSpin -> ได้ชื่อ -> ยิง ClanSpinComplete (RemoteEvent) เพื่อปลดล็อกครั้งถัดไป
--   วนจนกว่าจะได้อันที่ต้องการ หรือ spin หมด
-- ============================================
local gotClan  = nil  -- clan ที่สุ่มได้ตรงกับ Config.Clan
local lastClan = nil  -- clan ตัวล่าสุดที่สุ่มได้

local MAX_CONSECUTIVE_FAIL = 8  -- กันค้างถ้าเซิร์ฟเวอร์ปฏิเสธซ้ำ ๆ
local fails = 0

while true do
    if spinsLeft() <= 0 then break end

    local ok, result = pcall(toServer, "ClanSpin")

    if ok and typeof(result) == "string" then
        fails = 0
        lastClan = (result ~= NOTHING) and result or nil
        confirmSpin() -- ปลดล็อกให้สุ่มครั้งต่อไปได้

        if isWanted(result) then
            gotClan = result
            break -- ได้อันที่ต้องการ -> หยุดทันที
        end
    else
        -- สุ่มไม่ได้ (spin ไม่พอ / ยังไม่พร้อม) -> ปลดล็อกแล้วลองใหม่ ไม่หยุดทันที
        fails = fails + 1
        confirmSpin()
        if fails >= MAX_CONSECUTIVE_FAIL or spinsLeft() <= 0 then break end
    end

    task.wait(Config.RollDelay)
end

-- ============================================
-- Step 3 — Report + DONE
-- ============================================
local remaining = spinsLeft()

if gotClan then
    sendDescription(string.format(
        "⚔️ Slayer 2 • Clan: %s ✅ • Spins: %d",
        gotClan, remaining
    ), true)
else
    sendDescription(string.format(
        "⚔️ Slayer 2 • Clan: %s • Spins: %d",
        lastClan or "ไม่มี", remaining
    ), true)
end

sendDone()
