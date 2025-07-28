local StatusBar = import("/lua/maui/statusbar.lua").StatusBar
local UIUtil = import("/lua/ui/uiutil.lua")


---@class ProgressBarExtension
---@field progress StatusBar?
ProgressBarExtension = ReUI.Core.Class()
{
    ---@param self ProgressBarExtension
    ---@param item ReUI.Construction.Grid.Item
    ShowProgressBar = function(self, item)
        local progress = self.progress
        if not progress then
            progress = StatusBar(item, 0, 1, false, false,
                UIUtil.UIFile('/game/unit-over/health-bars-back-1_bmp.dds'),
                UIUtil.UIFile('/game/unit-over/bar01_bmp.dds'),
                true, "Unit RO Health Status Bar")

            item.Layouter(progress)
                :AtBottomCenterIn(item, 4)
                :Width(36)
                :Height(4)
                :Over(item, 4)
                :DisableHitTest()
            self.progress = progress
        end
        progress:Show()
        item:SetNeedsFrameUpdate(true)
    end,

    ---@param self ProgressBarExtension
    ---@param unit UserUnit?
    UpdateProgressBar = function(self, unit)
        if self.progress and unit and not unit:IsDead() then
            self.progress:SetValue(unit:GetWorkProgress())
        end
    end,

    ---@param self ProgressBarExtension
    ---@param item ReUI.Construction.Grid.Item
    HideProgressBar = function(self, item)
        if self.progress then
            self.progress:Hide()
        end
        item:SetNeedsFrameUpdate(false)
    end,

    ---@param self ProgressBarExtension
    DestroyProgressBar = function(self)
        if self.progress then
            self.progress:Destroy()
            self.progress = nil
        end
    end,
}
