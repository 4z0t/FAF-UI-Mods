local Group = ReUI.UI.Controls.Group
local Bitmap = ReUI.UI.Controls.Bitmap
local Text = ReUI.UI.Controls.Text

local LazyVar = import('/lua/lazyvar.lua').Create

---@class ReUI.Units.Overlay : ReUI.UI.Controls.Bitmap
---@field _worldView WorldView
---@field PosX LazyVar<number>
---@field PosY LazyVar<number>
---@field unit UserUnit
---@field id UnitId
---@field string integer
---@field offsetX number
---@field offsetY number
Overlay = ReUI.Core.Class(Bitmap)
{
    ---inits a unit overlay
    ---@param self ReUI.Units.Overlay
    ---@param parent WorldView
    ---@param unit UserUnit
    ---@param worldView WorldView
    __init = function(self, parent, unit, worldView)
        Bitmap.__init(self, parent)

        self._worldView = worldView
        self.id = unit:GetEntityId()
        self.unit = unit
        self.offsetX = 0
        self.offsetY = 0
        self.PosX = LazyVar()
        self.PosY = LazyVar()
    end,

    ---@param self ReUI.Units.Overlay
    ---@param layouter ReUI.UI.Layouter
    InitLayout = function(self, layouter)

        local worldView = self._worldView
        self.Left:Set(function()
            return worldView.Left() + self.PosX() - self.Width() / 2 + self.offsetX
        end)
        self.Top:Set(function()
            return worldView.Top() + self.PosY() - self.Height() / 2 + self.offsetY
        end)

        self:Hide()
        self:DisableHitTest()
        self:SetNeedsFrameUpdate(true)
    end,

    ---@param self ReUI.Units.Overlay
    ---@return Vector2?
    GetUnitPosition = function(self)
        return self._worldView:GetScreenPos(self.unit)
    end,

    ---updates the position of the unit overlay on screen
    ---@param self ReUI.Units.Overlay
    Update = function(self)
        local pos = self:GetUnitPosition()
        if pos then
            self.PosX:Set(pos.x)
            self.PosY:Set(pos.y)
            self:Show()
        else
            self:Hide()
        end
    end,

    ---@param self ReUI.Units.Overlay
    OnDestroy = function(self)
        if self.PosX then
            self.PosX:Destroy()
            self.PosX = nil
        end
        if self.PosY then
            self.PosY:Destroy()
            self.PosY = nil
        end
        self.id = nil
        self.unit = nil
        self.offsetX = nil
        self.offsetY = nil
        self._worldView = nil
        Bitmap.OnDestroy(self)
    end
}
