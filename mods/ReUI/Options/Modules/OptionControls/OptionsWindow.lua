local UIUtil = import('/lua/ui/uiutil.lua')
local Combo = import('/lua/ui/controls/combo.lua').Combo

local LayoutFor = ReUI.UI.FloorLayoutFor
local Group = ReUI.UI.Controls.Group

local QuickWindow = ReUI.UI.Quick.Window
local QuickContainer = ReUI.UI.Quick.Container
local QuickContext = ReUI.UI.Quick.Context



---@class OptionsContainer : Quick.Container
---@field Context fun(self:OptionsContainer):OptionsContext
OptionsContainer = Class(QuickContainer)
{
    ---@param self OptionsContainer
    ---@param label string
    ---@param option ReUI.Options.ReactiveOption
    OptionCheckbox = function(self, label, option)
        self:Context():TrackOption(option)
        local cb = ReUI.Options.Controls.Checkbox(self._control, option, label)
        self:Builder():AddControl(cb, {
            width = LayoutFor:UnscaleNumber(cb.Width()),
            height = LayoutFor:UnscaleNumber(cb.Height())
        })
    end,

    ---@param self OptionsContainer
    ---@param label string
    ---@param option ReUI.Options.ReactiveOption
    ---@param min number
    ---@param max number
    ---@param inc? number
    OptionSlider = function(self, label, option, min, max, inc)
        self:Context():TrackOption(option)
        local slider = ReUI.Options.Controls.Slider(self._control, option, label, min, max, inc)
        self:Builder():AddControl(slider, {
            width = self:Builder():GetItemWidth(),
            height = 40
        })
    end,

    ---@param self OptionsContainer
    ---@param label string
    ---@param option ReUI.Options.ReactiveOption
    ---@param items ItemData[]
    OptionCombo = function(self, label, option, items)
        self:Context():TrackOption(option)
        local slider = ReUI.Options.Controls.Combo(self._control, option, label, items)
        self:Builder():AddControl(slider, {
            width = self:Builder():GetItemWidth(),
            height = 40
        })
    end,
}

---@class OptionsContext : Quick.Context
---@field _trackedOptions ReUI.Options.ReactiveOption[]
OptionsContext = Class(QuickContext)
{
    ContainerClass = OptionsContainer,

    ---@param self Quick.Context
    ---@param window Quick.Window
    __init = function(self, window)
        QuickContext.__init(self, window)
        self._trackedOptions = {}
    end,

    ---@param self OptionsContext
    ---@param option ReUI.Options.ReactiveOption
    TrackOption = function(self, option)
        table.insert(self._trackedOptions, option)
    end,

    ---@param self OptionsContext
    RestoreOptions = function(self)
        for _, option in ipairs(self._trackedOptions) do
            option:Restore()
        end
    end,

    ---@param self OptionsContext
    ---@return boolean
    SaveOptions = function(self)
        local r = false
        for _, option in ipairs(self._trackedOptions) do
            if option.IsChanged then
                r = true
                option:Save()
            end
        end
        return r
    end,

}


---@class ReUI.Options.Window : Quick.Window
OptionsWindow = ReUI.Core.Class(QuickWindow)
{
    Prefix = "ReUI.Options.Windows",

    ContextClass = OptionsContext,

    ---@param self ReUI.Options.Window
    ---@param title string
    ---@param fn fun(q: OptionsContainer)
    __init = function(self, title, fn)
        QuickWindow.__init(self, title, self:Wrap(fn))
    end,

    ---@param self ReUI.Options.Window
    ---@param fn fun(q: OptionsContainer)
    Wrap = function(self, fn)
        ---@param q OptionsContainer
        return function(q)
            fn(q)
            q:Button("OK", function()
                if q:Context():SaveOptions() then
                    SavePreferences()
                end
            end)
            q:SameLine(20)
            q:Button("Cancel", function()
                q:Context():RestoreOptions()
            end)
        end
    end,

    ---@generic T
    ---@param self ReUI.Options.Window
    ---@param presets T[]
    ---@param onSet fun(preset:T, name: string)
    ---@param initial? integer
    ---@return ReUI.Options.Window
    AddPresets = function(self, presets, onSet, initial)
        local text = UIUtil.CreateText(self._titleBar, "presets", 10, UIUtil.titleFont)
        ---@type Combo
        self._presetsCombo = Combo(self._titleBar, 13, 16)

        LayoutFor(self._presetsCombo)
            :AnchorToLeft(self._closeBtn, 2)
            :AtVerticalCenterIn(self._titleBar)
            :Width(100)

        LayoutFor(text)
            :AnchorToLeft(self._presetsCombo, 4)
            :AtVerticalCenterIn(self._titleBar)
            :DisableHitTest()

        local l = ReUI.LINQ.Enumerate(presets)
            :Select(function(v)
                return v[1] or "invalid entry name"
            end)
            :ToArray()

        self._presetsCombo:AddItems(l, initial or 0)
        self._presetsCombo.OnClick = function(c, i, text)
            onSet(presets[i], presets[i][1])
        end
        return self
    end
}
