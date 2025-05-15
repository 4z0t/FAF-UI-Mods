local Layouter = import("Layouter.lua").FloorLayoutFor


---@alias ReUILayouter ReUI.UI.Layouter

---@class ReUI.UI.Layoutable
---@field _clearLayout fun(control: ReUI.UI.Layoutable, layouter:ReUILayouter)?
---@field _layout fun(control: ReUI.UI.Layoutable, layouter:ReUILayouter) : fun(control: ReUI.UI.Layoutable)?
---@field _layouter ReUILayouter
Layoutable = ClassSimple
{
    ---@param self ReUI.UI.Layoutable
    ---@param parent ReUI.UI.Layoutable|Control
    InitLayouter = function(self, parent)
        self.Layouter = parent.Layouter
    end,

    ---@type fun(control: ReUI.UI.Layoutable, layouter?:ReUILayouter)
    ---@diagnostic disable:assign-type-mismatch
    Layout = ReUI.Core.Property
    {
        ---@param self ReUI.UI.Layoutable
        ---@param layout fun(control: ReUI.UI.Layoutable, layouter:ReUILayouter) : fun(control: ReUI.UI.Layoutable)?
        set = function(self, layout)
            if self._clearLayout then
                self:_clearLayout(self.Layouter)
                self._clearLayout = nil
            end

            self._layout = layout

            if self._layout then
                self._clearLayout = layout(self, self.Layouter)
            else
                self._clearLayout = self:InitLayout(self.Layouter)
            end
        end,
        ---@param self ReUI.UI.Layoutable
        ---@return fun(control: ReUI.UI.Layoutable, layouter?:ReUILayouter)
        get = function(self)
            local layout = self._layout or self.InitLayout
            ---@param control ReUI.UI.Layoutable
            ---@param layouter? ReUILayouter
            return function(control, layouter)
                return layout(control, layouter or control.Layouter)
            end
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

    ---@param self ReUI.UI.Layoutable
    __post_init = function(self)
        self:Layout()
    end,

    ---@param self ReUI.UI.Layoutable
    ---@param layouter ReUILayouter
    InitLayout = function(self, layouter)
    end
}
