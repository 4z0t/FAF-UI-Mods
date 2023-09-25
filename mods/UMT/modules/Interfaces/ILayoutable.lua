ILayoutable = ClassSimple
{
    Layout = UMT.Property
    {
        set = function(self, value)
            if self._clearLayout then
                self:_clearLayout()
                self._clearLayout = false
            end

            self._layout = value

            if self._layout then
                self._clearLayout = self:_layout()
            else
                self:_Layout()
            end
        end,
        get = function(self)
            return self._layout or self._Layout
        end
    },


    _Layout = function(self)
        error "Not implemented _Layout method!"
    end
}