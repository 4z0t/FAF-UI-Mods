local Decal = import('/lua/user/userdecal.lua').UserDecal
local rings = {}
local texture = '/mods/TacticalPaint/textures/direct_ring.dds'
local range = 90
local isShown = true
local scaleTable = {math.floor(2.03*range), 0, math.floor(2.03*range)}
local RegisterChatFunc = import('/lua/ui/game/gamemain.lua').RegisterChatFunc
local FindClients = import('/lua/ui/game/chat.lua').FindClients
local Prefs = import('/lua/user/prefs.lua')



function isAllytoMe(nickname)
	for id,player in GetArmiesTable().armiesTable do
		if player.nickname == nickname then
			return IsAlly(GetFocusArmy(),id)
		end
	end
end

function createRingDecal(pos)
    local ring  = Decal(GetFrame(0))
    ring:SetTexture(texture)
    ring:SetScale(scaleTable)
    local ringPos = Vector(pos.x, pos.y, pos.z)
    ring:SetPosition(ringPos)
    return ring
end

function createRing()
    local mousePos = GetMouseWorldPos()
    local ring = nil
    if  isShown then
        ring = createRingDecal(mousePos)
    end
    sendSmdData(0,mousePos)--send info about new ring
    return {decal = ring,
              pos =  mousePos}
end

function DrawRing()
    table.insert(rings,createRing())
end

function DeleteRing()
    --deletes closest one
    local mousePos = GetMouseWorldPos()
    local minRing = nil 
    local ind = nil
    local dist 
    for i,ring in rings do
        dist =  VDist2(ring.pos.x,ring.pos.z,mousePos.x,mousePos.z)
        if minRing then
            if dist < minRing then
                ind = i
                minRing = dist
            end
        else
            minRing = dist
            ind = 1
        end
    end
    if ind then
        rings[ind].decal:Destroy()
        rings[ind]= nil
        sendSmdData(1,ind)--send info about deleting smd ring for all
        table.remove(rings,ind)
    end
    
end

function ChangeShowState()
    if isShown then
        for i,_ in rings do
            rings[i].decal:Destroy()
            rings[i].decal = nil
        end
    else
        for i,_ in rings do
            rings[i].decal = createRingDecal(rings[i].pos)
        end
    end
    isShown = not isShown
end





function sendSmdData(code,data)
    local text 
    if code == 0 then
        text = code..' '..data.x ..' '.. data.y ..' '.. data.z
    elseif code == 1 then
        text = code..' '..data
    end
	local msg = { to = 'allies', Smd = true, text = text}
	SessionSendChatMessage(FindClients(), msg)
end

function processSmdData(player, msg)
	local data = {}
	local me = GetFocusArmy()


	if GetArmiesTable().armiesTable[me].nickname == player or not isAllytoMe(player) then
		return
	end

	for v in string.gfind(msg.text, "%S+") do
		table.insert(data,tonumber(v))
	end

    local code = data[1]
	
	ForkThread(function()
		if code == 0 then
            local pos = {x = data[2],y = data[3],z = data[4]}
            if isShown then
                table.insert(rings,{decal = createRingDecal(pos),
                                     pos = pos})     
            else
                table.insert(rings,{decal = nil,
                                        pos = pos})  
            end
        elseif code == 1 then
            table.remove(rings,data[2])
        end
	end)
end

function init()
	RegisterChatFunc(processSmdData, 'Smd')

end