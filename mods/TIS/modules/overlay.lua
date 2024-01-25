local math = math

local UIUtil = import('/lua/ui/uiutil.lua')
local Group = import('/lua/maui/group.lua').Group
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')

local ScaleNumber = LayoutHelpers.ScaleNumber
local MathFloor = math.floor

local LayoutFor = UMT.Layouter.ReusedLayoutFor

---@param parent Control
---@param label string
---@param pointSize number
---@param offsets { offsetX: OptionVar, offsetY: OptionVar }
---@return Text
local function OffsettableText(parent, label, pointSize, offsets)
    local text   = UIUtil.CreateText(parent, label, pointSize, UIUtil.bodyFont)
    text.offsetX = offsets.offsetX:Raw()
    text.offsetY = offsets.offsetY:Raw()
    return text
end

---@class TIS.Data
---@field id string
---@field eta number
---@field progress number
---@field is_done boolean

---@class TIS.Overlay : Group
---@field worldview WorldView
---@field eta Text
---@field progress Text
Overlay = Class(Group)
{
    ---@param self TIS.Overlay
    ---@param worldview WorldView
    ---@param option any
    __init = function(self, worldview, option)
        Group.__init(self, worldview)
        self.worldview = worldview

        self.eta = OffsettableText(self, '??:??', 10, option.eta)
        self.progress = OffsettableText(self, '0%', 9, option.progress)
    end,

    ---@param self TIS.Overlay
    ---@param worldview WorldView
    __post_init = function(self, worldview)

        LayoutFor(self)
            :AtLeftTopIn(worldview)
            :Width(32)
            :Height(32)
            :DisableHitTest(true)
            :NeedsFrameUpdate(true)

        LayoutFor(self)
            :Color("white")
            :DropShadow(true)
            :DisableHitTest()


        local function AtCenterInOffset(control, parent)
            control.Left:Set(function()
                return MathFloor(parent.Left() + (parent.Width() - control.Width()) * 0.5 +
                    ScaleNumber(control.offsetX()))
            end)
            control.Top:Set(function()
                return MathFloor(parent.Top() + (parent.Height() - control.Height()) * 0.5 +
                    ScaleNumber(control.offsetY()))
            end)
        end

        AtCenterInOffset(self.eta, self)
        AtCenterInOffset(self.progress, self)
    end,

    ---@param self TIS.Overlay
    ---@param eta number
    SetETA = function(self, eta)
        self.eta:SetText(
            eta > 0
            and ("%.2d:%.2d"):format(eta / 60, math.mod(eta, 60))
            or '??:??'
        )
    end,

    ---@param self TIS.Overlay
    ---@param progress number
    SetProgress = function(self, progress)
        self.progress:SetText(("%d%%"):format(math.floor(progress * 100)))
    end,

    ---@param self TIS.Overlay
    ---@param data TIS.Data
    Update = function(self, data)

    end,
}
