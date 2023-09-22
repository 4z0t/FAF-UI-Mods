local Layouter = UMT.Layouter.ReusedLayoutFor

---@alias LayouterFunctor fun(control:ILayoutable|Control):Layouter

---@class ILayoutable
---@field _clearLayout fun(control: ILayoutable, layouter:LayouterFunctor)?
---@field _layout fun(control: ILayoutable, layouter:LayouterFunctor) : fun(control: ILayoutable)?
---@field _layouter fun(control:ILayoutable):Layouter
ILayoutable = ClassSimple
{
    ---@param self ILayoutable
    ---@param parent ILayoutable
    InitLayouter = function(self, parent)
        self.Layouter = parent.Layouter
    end,

    ---@type fun(control:ILayoutable)
    Layout = UMT.Property
    {
        ---@param self ILayoutable
        ---@param value fun(control: ILayoutable, layouter:LayouterFunctor) : fun(control: ILayoutable)?
        set = function(self, value)
            if self._clearLayout then
                self:_clearLayout(self.Layouter)
                self._clearLayout = nil
            end

            self._layout = value

            if self._layout then
                self._clearLayout = self:_layout(self.Layouter)
            else
                self:_Layout(self.Layouter)
            end
        end,
        ---@param self ILayoutable
        ---@return fun(control: ILayoutable)
        get = function(self)
            local layout = self._layout or self._Layout
            ---@param control ILayoutable
            return function (control)
                layout(control, self.Layouter)
            end
        end
    },

    ---@type LayouterFunctor
    Layouter = UMT.Property
    {
        ---@param self ILayoutable
        ---@return LayouterFunctor
        get = function(self)
            return self._layouter or Layouter
        end,

        ---@param self ILayoutable
        ---@param value LayouterFunctor
        set = function(self, value)
            self._layouter = value
        end
    },

    ---@param self ILayoutable
    ---@param layouter LayouterFunctor
    _Layout = function(self, layouter)
        error "Not implemented _Layout method!"
    end
}
