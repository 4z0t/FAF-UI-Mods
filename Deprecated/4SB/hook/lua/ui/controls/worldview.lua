local function ExistGlobal(name)
    return rawget(_G, name) ~= nil
end

if ExistGlobal "UMT" and UMT.Version >= 8 then

    ---@class PingData
    ---@field Owner integer
    ---@field Location Vector
    ---@field ArrowColor  'red'|'yellow'| 'blue'
    ---@field Lifetime number
    ---@field Marker boolean
    ---@field Renew boolean

    local Text = UMT.Controls.Text
    local LazyVar = import('/lua/lazyvar.lua').Create
    local Utils = import("/mods/4sb/modules/Utils.lua")
    local LuaQ = UMT.LuaQ

    ---@class TempMarker : UMT.Text
    ---@field PosX LazyVar<number>
    ---@field PosY LazyVar<number>
    ---@field _onFrameTime number
    ---@field _position Vector
    ---@field _worldView WorldView
    local TempMarker = UMT.Class(Text)
    {
        LifeTime = 5,

        __init = function(self, parent, position)
            Text.__init(self, parent)

            self._worldView = parent
            self._position = position
            self._onFrameTime = 0

            self.PosX = LazyVar()
            self.PosY = LazyVar()
            self.Left:Set(UMT.Layouter.Functions.Floor(function() return parent.Left() + self.PosX() - self.Width() * 0.5 end))
            self.Top:Set(UMT.Layouter.Functions.Floor(function() return parent.Top() + self.PosY() - self.Height() * 0.5 end))
            self:DisableHitTest()
            self:SetNeedsFrameUpdate(true)
        end,

        ---@param self TempMarker
        ---@param delta number
        OnFrame = function(self, delta)
            self._onFrameTime = self._onFrameTime + delta
            if self._onFrameTime > self.LifeTime then
                self:Destroy()
                return
            end
            local screenPos = self._worldView:Project(self._position)
            self.PosX:Set(screenPos.x)
            self.PosY:Set(screenPos.y)
        end
    }


    local oldWorldView = WorldView
    WorldView = Class(oldWorldView) {

        __init = function(self, ...)
            oldWorldView.__init(self, unpack(arg))
            self._isMiniMap = arg[4] or false
        end,

        ---@param self WorldView
        ---@param pingData PingData
        DisplayTempMarker = function(self, pingData)
            if pingData.Marker or pingData.Renew or self._isMiniMap then return end

            ---@type TempMarker
            local marker = TempMarker(self, pingData.Location)
            marker.LifeTime = pingData.Lifetime
            local nickname = (
                Utils.GetArmiesFormattedTable() | LuaQ.first(function(v) return v.id == pingData.Owner + 1 end)).nickname
            marker:SetText(nickname)
            marker:Show()
            marker:SetFont("Arial", 13)
        end,

        ---@param self WorldView
        ---@param pingData PingData
        DisplayPing = function(self, pingData)
            import("/lua/ui/game/score.lua").DisplayPing(self, pingData)
            self:DisplayTempMarker(pingData)
            return oldWorldView.DisplayPing(self, pingData)
        end
    }
end
