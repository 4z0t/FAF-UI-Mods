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

    local oldWorldView = WorldView
    WorldView = Class(oldWorldView) {
        -- HandleEvent = function(self, event)
        --     if event.Modifiers.Shift then
        --         --
        --     end
        --     return oldWorldView.HandleEvent(self, event)
        -- end,


        DisplayPing = function(self, pingData)
            import("/lua/ui/game/score.lua").DisplayPing(self, pingData)
            return oldWorldView.DisplayPing(self, pingData)
        end
    }
end
