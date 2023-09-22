local Layouter = UMT.Layouter.ReusedLayoutFor

---@class ILayoutable
---@field _clearLayout fun(control: ILayoutable)?
---@field _layout fun(control: ILayoutable) : fun(control: ILayoutable)?
ILayoutable = ClassSimple
{
    Layout = UMT.Property
    {
        ---@param self ILayoutable
        ---@param value any
        set = function(self, value)
            if self._clearLayout then
                self:_clearLayout()
                self._clearLayout = nil
            end

            self._layout = value

            if self._layout then
                self._clearLayout = self:_layout()
            else
                self:_Layout()
            end
        end,
        ---@param self ILayoutable
        ---@return fun(control: ILayoutable)
        get = function(self)
            return self._layout or self._Layout
        end
    },

    Layouter = UMT.Property
    {
        get = function(self)
            return self._layouter or Layouter
        end,

        set = function(self, value)
            self._layouter = value
        end
    },

    ---@param self ILayoutable
    _Layout = function(self)
        error "Not implemented _Layout method!"
    end
}
