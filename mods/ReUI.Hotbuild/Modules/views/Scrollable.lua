local UIUtil = import('/lua/ui/uiutil.lua')
local StaticScrollable = ReUI.UI.Views.StaticScrollable

---@class Scrollable : ReUI.UI.Views.StaticScrollable
---@field _scroll Scrollbar
Scrollable = Class(StaticScrollable) {
    __init = function(self, parent)
        StaticScrollable.__init(self, parent)
        self._topLine = 1
        self._scroll = UIUtil.CreateVertScrollbarFor(self)
    end,
}
