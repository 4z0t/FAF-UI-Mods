local modpath = "/mods/TacticalPaint/"

local Decal = import('/lua/user/userdecal.lua').UserDecal

local RegisterChatFunc = import('/lua/ui/game/gamemain.lua').RegisterChatFunc
local FindClients = import('/lua/ui/game/chat.lua').FindClients
local Prefs = import('/lua/user/prefs.lua')

local PrevMouseWorldPos = nil
local minDist = 3

-- YEAH COOL THING!
local keyMap = {
    ['F1'] = 112,
    ['F2'] = 113,
    ['F3'] = 114,
    ['F4'] = 115,
    ['F5'] = 116,
    ['F6'] = 117,
    ['F7'] = 118,
    ['F8'] = 119,
    ['F9'] = 120,
    ['F10'] = 121,
    ['F11'] = 122,
    ['F12'] = 123,
    ['Num0'] = 96,
    ['Num1'] = 97,
    ['Num2'] = 98,
    ['Num3'] = 99,
    ['Num4'] = 100,
    ['Num5'] = 101,
    ['Num6'] = 102,
    ['Num7'] = 103,
    ['Num8'] = 104,
    ['Num9'] = 105,
    ['A'] = 65,
    ['B'] = 66,
    ['C'] = 67,
    ['D'] = 68,
    ['E'] = 69,
    ['F'] = 70,
    ['G'] = 71,
    ['H'] = 72,
    ['I'] = 73,
    ['J'] = 74,
    ['K'] = 75,
    ['L'] = 76,
    ['M'] = 77,
    ['N'] = 78,
    ['O'] = 79,
    ['P'] = 80,
    ['Q'] = 81,
    ['R'] = 82,
    ['S'] = 83,
    ['T'] = 84,
    ['U'] = 85,
    ['V'] = 86,
    ['W'] = 87,
    ['X'] = 88,
    ['Y'] = 89,
    ['Z'] = 90

}

function isObs(nickname)
    for _, player in GetArmiesTable().armiesTable do
        if player.nickname == nickname then
            return false
        end
    end
    return true
end

function getArmyColor(nickname)
    if nickname then
        for _, player in GetArmiesTable().armiesTable do
            if player.nickname == nickname then
                return player.color
            end
        end
    end
    local me = GetFocusArmy()

    return GetArmiesTable().armiesTable[me].color
end

function isAllytoMe(nickname)
    for id, player in GetArmiesTable().armiesTable do
        if player.nickname == nickname then
            return IsAlly(GetFocusArmy(), id)
        end
    end
end

function getKeyBind()
    for key, value in Prefs.GetFromCurrentProfile('UserKeyMap') do
        if value == 'PaintTool' then
            return keyMap[key]
        end
    end
end

local keybind
local myColor = getArmyColor()
local iskeyChanged = true
local totalDecals = 0

function TacticalPaint()
    local color
    if myColor then
        color = myColor
    else
        color = string.lower(Prefs.GetFromCurrentProfile('options')['TPaintobs_color'] or 'ffffffff')
    end
    if iskeyChanged then
        keybind = getKeyBind()
    end
    iskeyChanged = true

    PrevMouseWorldPos = GetMouseWorldPos()
    DrawPoint(PrevMouseWorldPos, color)
    ForkThread(function()
        while IsKeyDown(keybind) do
            iskeyChanged = false
            local pos = GetMouseWorldPos()
            if VDist2(PrevMouseWorldPos[1], PrevMouseWorldPos[3], pos[1], pos[3]) > 1 then
                --lineDraw(PrevMouseWorldPos, pos, color, true, true)
                lineDraw(PrevMouseWorldPos, pos, color, true, false)
                PrevMouseWorldPos = pos
            end
            coroutine.yield(1)
        end
    end)

end
-- local PrevTime = 0

-- function TacticalPaint()
--     -- LOG(GetGameTime())
--     LOG(CurrentTime())
-- 	local CurTime = CurrentTime()
-- 	if CurTime - PrevTime > 0.5 then
-- 		PrevMouseWorldPos = nil
-- 		PrevTime = CurTime
-- 	end
-- 	local pos = GetMouseWorldPos()
--     if PrevMouseWorldPos and CurTime - PrevTime > 0.05 then
-- 		PrevTime = CurTime
--         if VDist2(PrevMouseWorldPos[1], PrevMouseWorldPos[3], pos[1], pos[3]) > 1 then
--             lineDraw(PrevMouseWorldPos, pos, myColor, true, true)
--         end
--     end
-- 	PrevMouseWorldPos = pos

-- end

function DrawPoint(pos, color)
    -- if not isSent then sendPaintData(pos) end
    if totalDecals >= Prefs.GetFromCurrentProfile('options')['TPaint_maxcount'] then
        return
    end
    totalDecals = totalDecals + 1
    local path = modpath .. 'textures/AnyConv.com__' .. color .. '.dds' -- fuckin ad here
    -- local path = modpath .. 'textures/imfine.dds'
    local newdecal = Decal(GetFrame(0))
    -- LOG(repr(newdecal.__index))
    newdecal:SetTexture(path)
    newdecal:SetScale({1, 1, 1})
    local decalpos = Vector(pos.x, pos.y, pos.z)
    newdecal:SetPosition(decalpos)
    ForkThread(function()
        -- local transferthread = ForkThread(function()
        --     local msg = {
        --         to = 'all',
        --         Overlay = true,
        --         -- text = text,
        --         text = totalDecals .. ' -1 -1 -1 0 ' .. pos.x .. ' ' .. pos.y .. ' ' .. pos.z
        --     }
        --     while true do
        --         SessionSendChatMessage(FindClients(), msg)
        --         coroutine.yield(5)
        --     end
        -- end)
        local lifetime = Prefs.GetFromCurrentProfile('options')['TPaint_lifetime']
        WaitSeconds(lifetime)
       -- KillThread(transferthread)
        newdecal:Destroy()
        totalDecals = totalDecals - 1
    end)
end

function sendPaintData(data)
    -- local text = data[1].x .. ' ' .. data[1].y .. ' ' .. data[1].z .. ' ' .. data[2].x .. ' ' .. data[2].y .. ' ' ..
    -- data[2].z

    local msg = {
        to = 'allies',
        Paint = true,
        -- text = text,
        text = data
    }
    SessionSendChatMessage(FindClients(), msg)
end

function processPaintData(player, msg)
    -- LOG(repr(player))
    -- LOG(repr(msg))
    -- LOG(repr(GetArmiesTable().armiesTable))
    local data = msg.text
    local me = GetFocusArmy()
    -- LOG('PAINT: '..msg.text)

    if GetArmiesTable().armiesTable[me].nickname == player or (not isAllytoMe(player) and not isObs(player)) then
        return
    end
    -- LOG(repr(msg.text))
    -- for v in string.gfind(msg.text, "%S+") do
    --     table.insert(data, tonumber(v))
    -- end
    -- LOG(player)
    -- local color = getArmyColor(player)
    ForkThread(function()
        -- lineDraw(data[1],data[2],color,true)
        lineDraw({
            x = data[1][1],
            y = data[1][2],
            z = data[1][3]
        }, {
            x = data[2][1],
            y = data[2][2],
            z = data[2][3]
        }, data[3], true)
        -- DrawPoint({x = data[1],y = data[2],z = data[3]},color)
    end)
end

function lineDraw(pos1, pos2, color, isNodes, send)
    if send then
        sendPaintData({pos1, pos2, color})
    end
    if isNodes then
        DrawPoint(pos2, color)
        if VDist2(pos1.x, pos1.z, pos2.x, pos2.z) < minDist / 2 then
            return
        end
    end
    local midlePos = Vector((pos1.x + pos2.x) / 2, pos2.y, (pos1.z + pos2.z) / 2)
    if VDist2(pos1.x, pos1.z, pos2.x, pos2.z) < minDist then
        -- if isNodes then return end
        DrawPoint(midlePos, color)
    else
        DrawPoint(midlePos, color)
        lineDraw(pos1, midlePos, color)
        lineDraw(midlePos, pos2, color)
    end
end

function init()
    LOG("PAINT")

    RegisterChatFunc(processPaintData, 'Paint')
    -- ForkThread(function()
    -- 	WaitSeconds(5)
    -- 	local text = "Hello! Im using TacticalPaint mod, that allows you to coordinate game with paint tool."
    -- 	local msg = { to = 'allies', Chat = true, text = text}
    -- 	SessionSendChatMessage(FindClients(), msg)
    -- end)
end

