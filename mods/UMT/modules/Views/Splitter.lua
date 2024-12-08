local Bitmap = import('/lua/maui/bitmap.lua').Bitmap
local LayoutFor = UMT.Layouter.ReusedLayoutFor

Splitter = Class(Bitmap)
{
    __post_init = function(self, parent, color)
        self:InitLayout(parent, color)
    end,

    InitLayout = function(self, parent, color)
        LayoutFor(self)
            :Height(2)
            :Color(color)
            :Left(parent.Left)
            :Right(parent.Right)
    end,

}
