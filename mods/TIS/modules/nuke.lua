local UIUtil = import('/lua/ui/uiutil.lua')
local Group = import('/lua/maui/group.lua').Group
local Update = import('update.lua')
local Data = import('data.lua')
local AddBeatFunction = import('/lua/ui/game/gamemain.lua').AddBeatFunction
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local worldView = import('/lua/ui/game/worldview.lua').viewLeft

local listeners = {}
local overlays = {} -- separiting data from UI
local unit_data = {}
local current_tick = 0
local prev_tick = 0
local MAX_RECORDS = 16

local siloOptions
local showOverlay

local function Remove(id)
    listeners[id] = nil
    unit_data[id] = nil
    if overlays[id] then
        overlays[id]:Destroy()
        overlays[id] = nil
    end
    Update.Remove(id)
    Data.SendData({
        nuke = true,
        remove = true,
        id = id
    })
end

local function UpdateListeners()
    current_tick = GameTick()
    if current_tick ~= prev_tick then
        VerifyWV()
        for id, unit in listeners do
            if unit:IsDead() then
                Remove(id)
            else
                UpdateData(id)
            end
        end
        prev_tick = current_tick
    end
end

function VerifyOverlay(id)
    if showOverlay == 0 then
        return false
    end
    if IsDestroyed(overlays[id]) then
        if listeners[id] then
            overlays[id] = CreateUnitOverlay(listeners[id])
            return true
        elseif unit_data[id] then
            overlays[id] = CreateUnitOverlay(nil, id)
            return true
        else
            return false
        end
    end
    return true
end

function VerifyWV()
    if IsDestroyed(worldView) -- ~= import('/lua/ui/game/worldview.lua').viewLeft 
    then
        worldView = import('/lua/ui/game/worldview.lua').viewLeft
        overlays = {}
    end
end

function UpdateData(id)

    local current_progress = listeners[id]:GetWorkProgress()
    local silo_info = listeners[id]:GetMissileInfo()
    local u_data = unit_data[id]
    local data = {
        nuke = true,
        id = id,
        eta = -1,
        progress = current_progress,
        silo = silo_info.nukeSiloStorageCount + silo_info.tacticalSiloStorageCount
    }
    if (current_progress > u_data.prev_progress) then
        data.eta = math.ceil(((current_tick - prev_tick) / 10) *
                                 ((1 - current_progress) / (current_progress - u_data.prev_progress)))

        -- smoothing filter for eta
        data.eta = smooth_eta(u_data, data.eta)

    end

    UpdateOverlay(data)
    u_data.prev_tick = current_tick
    u_data.prev_eta = data.eta
    u_data.prev_progress = data.progress
    Data.SendData(data)
end

function UpdateOverlay(data)
    if VerifyOverlay(data.id) then
        local overlay = overlays[data.id]
        unit_data[data.id].prev_tick = current_tick

        overlay.progress:SetText(math.floor(data.progress * 100) .. "%")

        overlay.eta:SetText((function(eta)
            if eta > 0 then
                return string.format("%.2d:%.2d", eta / 60, math.mod(eta, 60))
            else
                return '??:??'
            end
        end)(data.eta))
        overlay.count:SetText(data.silo)
    end
end
function smooth_eta(sum_data, input)
    local function sum(tbl)
        local s = 0
        for _, i in tbl do
            s = s + i
        end
        return s
    end
    local raw = sum_data.raw
    -- local filtered = sumData.filtered

    raw[sum_data.current] = input

    if sum_data.current == MAX_RECORDS then
        sum_data.current = 1
    else
        sum_data.current = sum_data.current + 1
    end
    local output = sum(raw) / MAX_RECORDS

    -- local output = -0.25 * filtered[1] + 0.375 * filtered[2] + input + 2 * raw[1] + raw[2]
    -- local output = ((input + raw[1] + raw[2]) / 3 + (filtered[2] + filtered[1]) / 2) / 2
    -- filtered[2], filtered[1] = filtered[1], output
    -- raw[2], raw[1] = raw[1], input
    return output
end

local function format_eta(eta)

end

function init(isReplay, options)
    siloOptions = options
    showOverlay = siloOptions.overlay()
    siloOptions.overlay.OnChange = function(self)
        showOverlay = self()
    end
    AddBeatFunction(UpdateListeners, true)
end

function Add(unit)
    local id = unit:GetEntityId()
    listeners[id] = unit
    local pos = unit:GetPosition()
    local data = {
        id = id,
        init = true,
        nuke = true,
        pos = {pos[1], pos[2], pos[3]}
    }
    unit_data[id] = {
        prev_progress = 0,
        prev_eta = 0,
        raw = {},
        current = 1
    }
    Data.SendData(data)
    overlays[id] = CreateUnitOverlay(unit)
end

function AddExternal(data)
    unit_data[data.id] = {
        pos = Vector(data.pos[1], data.pos[2], data.pos[3]),
        prev_tick = current_tick
    }
    overlays[data.id] = CreateUnitOverlay(nil, data.id)
end

function RemoveExternal(id)
    unit_data[id] = nil
    if overlays[id] then
        overlays[id]:Destroy()
        overlays[id] = nil
    end
end

function CreateUnitOverlay(unit, id)
    local overlay = Group(worldView)
    LayoutHelpers.AtLeftTopIn(overlay, worldView, 0, 0)
    LayoutHelpers.SetDimensions(overlay, 32, 32)
    overlay:DisableHitTest()
    overlay:SetNeedsFrameUpdate(true)
    if id then -- overlay provided by other player
        overlay.id = id
        overlay.OnFrame = function(self, delta)
            if showOverlay == 0 then
                self:Destroy()
            end
            if not SessionIsPaused() and current_tick > unit_data[self.id].prev_tick + 10 then -- no responce for this overlay in 10 ticks- remove it
                RemoveExternal(self.id)
                return
            end
            local pos = worldView:Project(unit_data[self.id].pos)
            self.Left:Set(function ()
                return worldView.Left() + pos.x - self.Width() / 2
            end)
            self.Top:Set(function ()
                return worldView.Top() + pos.y - self.Height() / 2
            end)
        end
    else -- overlay on user side
        overlay.unit = unit
        overlay.OnFrame = function(self, delta)
            if showOverlay == 0 then
                self:Destroy()
            end
            if (not self.unit:IsDead()) then
                local pos = worldView:Project(self.unit:GetPosition())
                self.Left:Set(function ()
                    return worldView.Left() + pos.x - self.Width() / 2
                end)
                self.Top:Set(function ()
                    return worldView.Top() + pos.y - self.Height() / 2
                end)
            end
        end
    end

    overlay.eta = UIUtil.CreateText(overlay, '??:??', 10, UIUtil.bodyFont)
    overlay.eta:DisableHitTest()
    overlay.eta:SetColor('white')
    overlay.eta:SetDropShadow(true)
    overlay.eta.offsetX = siloOptions.eta.offsetX
    overlay.eta.offsetY = siloOptions.eta.offsetY
    Update.AtCenterInOffset(overlay.eta, overlay)

    overlay.progress = UIUtil.CreateText(overlay, '0%', 9, UIUtil.bodyFont)
    overlay.progress:DisableHitTest()
    overlay.progress:SetColor('white')
    overlay.progress:SetDropShadow(true)

    overlay.progress.offsetX = siloOptions.progress.offsetX
    overlay.progress.offsetY = siloOptions.progress.offsetY
    Update.AtCenterInOffset(overlay.progress, overlay)

    overlay.count = UIUtil.CreateText(overlay, '0', 14, "Arial Black")
    overlay.count:DisableHitTest()
    overlay.count:SetColor('white')
    overlay.count:SetDropShadow(true)

    overlay.count.offsetX = siloOptions.count.offsetX
    overlay.count.offsetY = siloOptions.count.offsetY
    Update.AtCenterInOffset(overlay.count, overlay)

    return overlay
end
