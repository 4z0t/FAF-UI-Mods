local VDist3, MATH_Lerp = VDist3, MATH_Lerp

local Prefs = import('/lua/user/prefs.lua')
local Bitmap = import('/lua/maui/bitmap.lua').Bitmap
local LayoutFor = import('/lua/maui/layouthelpers.lua').ReusedLayoutFor
local Dragger = import("/lua/maui/dragger.lua").Dragger
local Group = import('/lua/maui/group.lua').Group
local CommandMode = import("/lua/ui/game/commandmode.lua")
local KeyMapper = import("/lua/keymap/keymapper.lua")

KeyMapper.SetUserKeyAction("Line move", {
    action = "UI_Lua import(\"/mods/LineMove/modules/Main.lua\").Start()",
    category = "order"
})

local KEY_CODES = (function()
    local keyNames = import("ASCIInames.lua").names
    local result = {}
    for k, v in keyNames do
        result[v] = STR_xtoi(k)
    end
    return result
end)()

local function GetKeyBind()
    for key, value in Prefs.GetFromCurrentProfile('UserKeyMap') do
        if value == "Line move" then
            LOG(key)
            return KEY_CODES[key]
        end
    end
end

function Start()
    import("/lua/ui/game/worldview.lua").viewLeft._mouseMonitor:StartLineMove()
end

local toCommandType = {
    ["RULEUCC_Move"] = "Move",
    ["RULEUCC_Attack"] = "Attack",
    ["RULEUCC_Guard"] = "Guard",
    ["RULEUCC_Tactical"] = "Tactical"
}


local function GiveOrders(orders, orderType)

    for id, position in orders do
        SimCallback({
            Func = "GiveOrders",
            Args = {
                unit_orders = { { CommandType = orderType, Position = position } },
                unit_id     = id,
                From        = GetFocusArmy()
            }
        }, false)
    end

end

Point = Class(Bitmap)
{
    __init = function(self, parent, view, position)
        Bitmap.__init(self, parent)
        LayoutFor(self)
            :Color("red")
            :Left(0)
            :Top(0)
            :Width(2)
            :Height(2)
            :DisableHitTest()
            :NeedsFrameUpdate(true)
        self.position = { position[1], position[2], position[3] }
        self.view = view
    end,

    OnFrame = function(self, delta)
        local view = self.view
        local proj = view:Project(self.position)
        self.Left:SetValue(proj.x - 0.5 * self.Width())
        self.Top:SetValue(proj.y - 0.5 * self.Height())
    end
}


---@class MouseMonitor : Group
MouseMonitor = Class(Group)
{

    __init = function(self, parent)
        Group.__init(self, parent)
        self.pressed       = false
        self.points        = TrashBag()
        self.unitPositions = TrashBag()
        self.selection     = false
        self.prevPosition  = false
    end,

    IsStartEvent = function(self, event)
        return event.Type == "ButtonPress" and event.Modifiers.Right
    end,

    IsMoveEvent = function(self, event)
        return event.Type == "MouseMotion" and self.pressed
    end,

    IsEndEvent = function(self, event)
        return event.Type == "ButtonRelease" and self.pressed and not event.Modifiers.Right
    end,

    StartLineMove = function(self)
        self.selection = GetSelectedUnits()
        if not self.selection then
            return
        end
        self.pressed = true
        self:InitPositions(GetMouseWorldPos())
        self:AddPoint(GetMouseWorldPos())
        self:AcquireKeyboardFocus(true)
    end,


    EndLineMove = function(self)
        self.pressed = false
        self.prevPosition = false
        self:GiveOrders()
        self.selection = false
        self:DestroyPoints()
        self:AbandonKeyboardFocus()
    end,


    IsCancelEvent = function(self, event)
        if not self.pressed then return false end

        if event.Type == "ButtonPress" then
            return true
        elseif event.Type == 'KeyUp' then
            local bind = GetKeyBind()
            LOG(bind)
            LOG(event.KeyCode)
            return event.KeyCode == bind
        end
        return false
    end,

    ---@param MouseMonitor WorldView
    ---@param event KeyEvent
    HandleEvent = function(self, event)
        --if not event.Modifiers.Right then return end
        --LOG(event.Type)
        if self:IsMoveEvent(event) then
            self:AddPoint(GetMouseWorldPos())
        elseif self:IsEndEvent(event) then

        elseif self:IsCancelEvent(event) then
            self:EndLineMove()
        end

    end,

    InitPositions = function(self, position)
        for i = 1, table.getn(self.selection) do
            local point = Point(self, self:GetParent(), position)
            LayoutFor(point)
                :Color("white")
            self.unitPositions:Add(point)
        end
    end,

    AddPoint = function(self, position)
        if self.prevPosition and VDist3(self.prevPosition, position) < 1 then
            return
        end

        self.points:Add(Point(self, self:GetParent(), position))
        self.prevPosition = position
        self:UpdatePositions()
    end,


    GetLineLength = function(self)
        local l = 0
        local prev = nil
        for _, point in self.points do
            if prev then
                l = l + VDist3(prev, point.position)
            end
            prev = point.position
        end
        return l
    end,


    DestroyPoints = function(self)
        self.points:Destroy()
        self.unitPositions:Destroy()
    end,

    UpdatePositions = function(self)
        local len = self:GetLineLength()

        if len == 0 then return end

        local unitCount = table.getn(self.unitPositions)
        local distBetween = len / (unitCount + 1)
        local currentSegmentLength = distBetween
        local curUnitPosition = 1

        local pointsCount = table.getn(self.points)
        local prevPoint   = nil
        local i           = 1
        while i < pointsCount do
            local p1 = prevPoint or self.points[i].position
            local p2 = self.points[i + 1].position
            local dist = VDist3(p1, p2)
            if dist > currentSegmentLength then
                local s = currentSegmentLength / dist
                prevPoint = self.unitPositions[curUnitPosition].position

                prevPoint[1] = MATH_Lerp(s, p1[1], p2[1])
                prevPoint[2] = MATH_Lerp(s, p1[2], p2[2])
                prevPoint[3] = MATH_Lerp(s, p1[3], p2[3])

                curUnitPosition = curUnitPosition + 1
                currentSegmentLength = distBetween
                if curUnitPosition > unitCount then
                    break
                end
            else
                currentSegmentLength = currentSegmentLength - dist
                prevPoint = p2
                i = i + 1
            end
        end
    end,


    GiveOrders = function(self)
        if table.getn(self.points) <= 1 then return end

        local orderType = CommandMode.GetCommandMode()[2].name and toCommandType[CommandMode.GetCommandMode()[2].name] or
            'Move'

        local curPos = 1
        local orders = {}
        for _, unit in self.selection do
            if unit:IsDead() then continue end

            orders[unit:GetEntityId()] = self.unitPositions[curPos].position
            curPos                     = curPos + 1
        end

        GiveOrders(orders, orderType)
    end




}
