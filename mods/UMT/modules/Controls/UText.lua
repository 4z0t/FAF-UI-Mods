local _Text = import("/lua/maui/text.lua").Text

---@class UMT.Text : Text, ILayoutable
Text = UMT.Class(_Text, UMT.Interfaces.ILayoutable)
{
    ---@param self UMT.Text
    OnInit = function(self)
        self:InitLayouter(self:GetParent())
        _Text.OnInit(self)
    end,

    ---@param self UMT.Text
    SetFont = function(self, family, pointsize)
        if self._font then
            self._lockFontChanges = true
            self._font._pointsize:Set(self.Layouter:ScaleNumber(pointsize))
            self._font._family:Set(family)
            self._lockFontChanges = false
            self:_internalSetFont()
        end
    end,
}
