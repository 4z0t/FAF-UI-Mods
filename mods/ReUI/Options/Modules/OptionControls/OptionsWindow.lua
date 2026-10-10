local UIUtil = import('/lua/ui/uiutil.lua')

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
        QuickWindow.__init(self, title, fn)

        self._bottomBar = Group(self)
        self._okBtn = UIUtil.CreateButtonStd(self._bottomBar, '/widgets02/small', "OK", 14)
        self._cancelBtn = UIUtil.CreateButtonStd(self._bottomBar, '/widgets02/small', "Cancel", 14)

        self._okBtn.OnClick = function(control, modifiers)
            if self._context:SaveOptions() then
                SavePreferences()
            end
        end

        self._cancelBtn.OnClick = function(control, modifiers)
            self._context:RestoreOptions()
        end
    end,

    ---@param self ReUI.Options.Window
    ---@param w number
    ---@param h number
    OnContentResize = function(self, w, h)
        self._minWidth = w + self._padding * 2
        self._minHeight = h + self._padding + 54

        self._width = math.max(self._minWidth, self._width)
        self._height = math.max(self._minHeight, self._height)

        LayoutFor(self._content)
            :Below(self._titleBar)
            :AtLeftIn(self, self._padding)
            :AtRightIn(self, self._padding)
            :AnchorToTop(self._bottomBar)

        LayoutFor(self)
            :Width(self._width)
            :Height(self._height)
    end,


    ---@param self ReUI.Options.Window
    ---@param layouter ReUI.UI.Layouter
    InitLayout = function(self, layouter)
        QuickWindow.InitLayout(self, layouter)

        LayoutFor(self._bottomBar)
            :AtLeftIn(self, self._padding)
            :AtRightIn(self, self._padding)
            :AtBottomIn(self, self._padding)
            :Height(30)

        LayoutFor(self._okBtn)
            :AtHorizontalCenterIn(self._bottomBar, -50)
            :AtVerticalCenterIn(self._bottomBar)
            :Width(80)
            :Height(24)

        LayoutFor(self._cancelBtn)
            :AtHorizontalCenterIn(self._bottomBar, 50)
            :AtVerticalCenterIn(self._bottomBar)
            :Width(80)
            :Height(24)
    end,
}
