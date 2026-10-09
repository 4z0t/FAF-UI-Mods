local UIUtil = import('/lua/ui/uiutil.lua')

local Combo = import('/lua/ui/controls/combo.lua').Combo

local OptionControl = import("OptionControl.lua").OptionControl

local LINQ = ReUI.LINQ

local Contains = LINQ.IPairsEnumerator
    :Select "value"
    :Contains()

---@class ItemData
---@field value string
---@field text string

---@class ReUI.Options.OptionCombo : ReUI.Options.OptionControl
---@field _combo Combo
---@field _text ReUI.UI.Controls.Text
---@field _items ItemData[]
OptionCombo = ReUI.Core.Class(OptionControl) {

    ---@param self ReUI.Options.OptionCombo
    ---@param parent Control
    ---@param option ReUI.Options.ReactiveOption
    ---@param label string
    ---@param items ItemData[]
    __init = function(self, parent, option, label, items)
        OptionControl.__init(self, parent, option)

        self._items = items

        self._text = ReUI.UI.Controls.Text.Create(self, UIUtil.bodyFont, 14)
        self._text:SetText(label)

        self._combo = Combo(self, 13, 16)

        self._combo.OnClick = function(c, i, text)
            option:Set(self._items[i].value)
        end

        self._combo:AddItems(
            LINQ.Enumerate(self._items):Select "text":ToArray(),
            Contains(self._items, option:Get()) or 1)
    end,

    ---@param self ReUI.Options.OptionCombo
    ---@param layouter ReUI.UI.Layouter
    InitLayout = function(self, layouter)
        layouter(self._text)
            :AtLeftTopIn(self, 2)
            :DisableHitTest()

        layouter(self._combo)
            :Below(self._text, 2)
            :AtLeftIn(self, 2)
            :AtRightIn(self, 2)
    end,

    ---@param self ReUI.Options.OptionCombo
    ---@param option ReUI.Options.ReactiveOption
    ---@param newValue string
    ValueChanged = function(self, option, newValue)
        local i = Contains(self._items, newValue)
        self._combo:SetItem(i or 1)
    end
}
