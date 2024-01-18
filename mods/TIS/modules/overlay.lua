local math = math

local UIUtil = import('/lua/ui/uiutil.lua')
local Group = import('/lua/maui/group.lua').Group
local Update = import('update.lua')

local LayoutFor = UMT.Layouter.ReusedLayoutFor

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

        self.eta = UIUtil.CreateText(self, '??:??', 10, UIUtil.bodyFont)
        self.eta.offsetX = option.eta.offsetX:Raw()
        self.eta.offsetY = option.eta.offsetY:Raw()

        self.progress = UIUtil.CreateText(self, '0%', 9, UIUtil.bodyFont)
        self.progress.offsetX = option.progress.offsetX:Raw()
        self.progress.offsetY = option.progress.offsetY:Raw()
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

        Update.AtCenterInOffset(self.eta, self)
        Update.AtCenterInOffset(self.progress, self)
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
