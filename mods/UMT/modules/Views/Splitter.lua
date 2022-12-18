local Bitmap = import('/lua/maui/bitmap.lua').Bitmap
local LayoutFor = import('../Layouter.lua').ReusedLayoutFor

Splitter = Class(Bitmap)
{
    __post_init = function(self, parent, color)
        self:_Layout(parent, color)
    end,

    _Layout = function(self, parent, color)
        LayoutFor(self)
            :Height(2)
            :Color(color)
            :Left(parent.Left)
            :Right(parent.Right)
    end,

}
