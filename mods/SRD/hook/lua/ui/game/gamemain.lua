do
    local originalCreateUI = CreateUI
    function CreateUI(isReplay)
        originalCreateUI(isReplay)
        import("/mods/SRD/modules/main.lua").init(isReplay)
    end
end

local ringPool = {}


---@class Ring
---@field x number
---@field y number
---@field z number
---@field color string
---@field radius number
Ring = ClassSimple
{
    __init = function(self, color, radius)
        self.x = 0
        self.y = 0
        self.z = 0
        self.color = color or "ffffffff"
        self.radius = radius or 0
        ringPool[self] = true
    end,

    ---@param self Ring
    Render = function(self)
        DrawCircle(self.x, self.y, self.z, self.radius, self.color)
    end,

    SetPosition = function(self, pos)
        self.x = pos[1]
        self.y = pos[2]
        self.z = pos[3]
    end,


    SetRadius = function(self, radius)
        self.radius = radius
    end,

    SetColor = function(self, color)
        self.color = color
    end,

    Destroy = function(self)
        ringPool[self] = nil
    end

}



function OnRenderWorld()
    for ring in ringPool do
        ring:Render()
    end
end
