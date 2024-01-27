local Bitmap = import('/lua/maui/bitmap.lua').Bitmap
local LazyVar = import('/lua/lazyvar.lua').Create

---@class UnitOverlay : Bitmap
---@field PosX LazyVar<number>
---@field PosY LazyVar<number>
---@field unit UserUnit
---@field string integer
---@field offsetX number
---@field offsetY number
UnitOverlay = Class(Bitmap)
{
    ---inits a unit overlay
    ---@param self UnitOverlay
    ---@param parent WorldView
    ---@param unit UserUnit
    __init = function(self, parent, unit)
        Bitmap.__init(self, parent)
        self:Hide()
        self:DisableHitTest()
        self.id = unit:GetEntityId()
        self.unit = unit
        self.offsetX = 0
        self.offsetY = 0
        self.PosX = LazyVar()
        self.PosY = LazyVar()
        self.Left:Set(function()
            return parent.Left() + self.PosX() - self.Width() / 2 + self.offsetX
        end)
        self.Top:Set(function()
            return parent.Top() + self.PosY() - self.Height() / 2 + self.offsetY
        end)
        self:SetNeedsFrameUpdate(true)
    end,

    ---@param self UnitOverlay
    GetUnitPosition = function (self)
        return self:GetParent():GetScreenPos(self.unit)
    end,

    ---updates the position of the unit overlay on screen
    ---@param self UnitOverlay
    Update = function(self)
        local pos = self:GetUnitPosition()
        if pos then
            self:Show()
            self.PosX:Set(pos.x)
            self.PosY:Set(pos.y)
        else
            self:Hide()
        end
    end,

    OnDestroy = function(self)
        Bitmap.OnDestroy(self)
        if self.PosX then
            self.PosX:Destroy()
            self.PosX = nil
        end
        if self.PosY then
            self.PosY:Destroy()
            self.PosY = nil
        end
    end
}
