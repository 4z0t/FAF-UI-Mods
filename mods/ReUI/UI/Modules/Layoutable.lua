local Layouter = import("Layouter.lua").FloorLayoutFor

---@overload fun(control:ReUI.UI.Layoutable, layouter?: ReUILayouter)
---@class ReUI.UI.ILayout
---@field Apply fun(layout:ReUI.UI.ILayout, control:ReUI.UI.Layoutable, layouter?: ReUILayouter)
---@field Restore fun(layout:ReUI.UI.ILayout, control:ReUI.UI.Layoutable, layouter?: ReUILayouter)


---@class ReUI.UI.BaseLayout : ReUI.UI.ILayout
BaseLayout = Class()
{
    ---@param self ReUI.UI.BaseLayout
    ---@param control ReUI.UI.Layoutable
    ---@param layouter? ReUILayouter
    __call = function(self, control, layouter)
        self:Apply(control, layouter)
    end,

    ---@param self ReUI.UI.BaseLayout
    ---@param control ReUI.UI.Layoutable
    ---@param layouter? ReUILayouter
    Apply = function(self, control, layouter)
        control:InitLayout(layouter or control.Layouter)
    end,

    ---@param self ReUI.UI.BaseLayout
    ---@param control ReUI.UI.Layoutable
    Restore = function(self, control)
    end
}
local baseLayoutInstance = BaseLayout() --[[@as ReUI.UI.BaseLayout]]

---@class SimpleLayout : ReUI.UI.BaseLayout
---@field _layout ReUILayoutFunction
---@field _clear fun(control: ReUI.UI.Layoutable, layouter:ReUILayouter)?
local SimpleLayout = ReUI.Core.Class(BaseLayout)
{
    ---@param self SimpleLayout
    ---@param layoutF ReUILayoutFunction
    __init = function(self, layoutF)
        self._layout = layoutF
    end,

    ---@param self SimpleLayout
    ---@param control ReUI.UI.Layoutable
    ---@param layouter? ReUILayouter
    Apply = function(self, control, layouter)
        self._clear = self._layout(control, layouter or control.Layouter)
    end,

    ---@param self SimpleLayout
    ---@param control ReUI.UI.Layoutable
    Restore = function(self, control)
        if self._clear then
            self._clear(control, control.Layouter)
        end
    end
}

---@alias ReUILayouter ReUI.UI.Layouter
---@alias ReUILayoutFunction fun(control: ReUI.UI.Layoutable, layouter:ReUILayouter) : fun(control: ReUI.UI.Layoutable, layouter:ReUILayouter)?

---@class ReUI.UI.Layoutable
---@field _layout ReUI.UI.ILayout
---@field _layouter ReUILayouter
Layoutable = ClassSimple
{
    ---@param self ReUI.UI.Layoutable
    ---@param parent ReUI.UI.Layoutable|Control
    InitLayouter = function(self, parent)
        self.Layouter = parent.Layouter
    end,

    ---@type ReUI.UI.ILayout|fun(control: ReUI.UI.Layoutable)
    Layout = ReUI.Core.Property
    {
        ---@param self ReUI.UI.Layoutable
        ---@param layout ReUILayoutFunction|ReUI.UI.ILayout
        set = function(self, layout)
            if type(layout) == "function" then
                layout = SimpleLayout(layout) --[[@as ReUI.UI.ILayout]]
            end

            self.Layout:Restore(self)

            self._layout = layout or baseLayoutInstance

            self._layout:Apply(self)
        end,
        ---@param self ReUI.UI.Layoutable
        ---@return ReUI.UI.ILayout
        get = function(self)
            return self._layout or baseLayoutInstance
        end
    },

    ---@type ReUILayouter
    Layouter = ReUI.Core.Property
    {
        ---@param self ReUI.UI.Layoutable
        ---@return ReUILayouter
        get = function(self)
            return self._layouter or Layouter
        end,

        ---@param self ReUI.UI.Layoutable
        ---@param value ReUILayouter
        set = function(self, value)
            self._layouter = value
        end
    },

    ---Sets whether control will be layouted automatically after it is being created
    AutoLayout = true,

    ---@param self ReUI.UI.Layoutable
    __post_init = function(self)
        if self.AutoLayout then
            self:Layout()
        end
    end,

    ---@param self ReUI.UI.Layoutable
    ---@param layouter ReUILayouter
    InitLayout = function(self, layouter)
    end
}
