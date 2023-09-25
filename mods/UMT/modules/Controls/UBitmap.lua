local _Bitmap = import('/lua/maui/bitmap.lua').Bitmap

---@class UMT.Bitmap : Bitmap, ILayoutable
Bitmap = UMT.Class(_Bitmap, UMT.Interfaces.ILayoutable)
{
    ---@param self UMT.Bitmap
    OnInit = function(self)
        self:InitLayouter(self:GetParent())
        _Bitmap.OnInit(self)
    end,

    ---@param self UMT.Bitmap
    ResetLayout = function(self)
        self.Layouter(self)
            :ResetLayout()
            :Width(self.Layouter:ScaleNumber(self.BitmapWidth))
            :Height(self.Layouter:ScaleNumber(self.BitmapHeight))
    end,
}
