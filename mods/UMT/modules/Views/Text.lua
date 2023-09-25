local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local _Text = import("/lua/maui/text.lua").Text


Text = UMT.Class(_Text)
{

    Scale = UMT.Property
    {
        get = function(self)
            return self._scale or LayoutHelpers.GetPixelScaleFactor()
        end,

        set = function(self, value)
            self._scale = value
        end
    },

    Text = UMT.Property
    {
        get = function(self)
            return self:GetText()
        end,

        set = function(self, value)
            self:SetText(value)
        end
    },

    FontFamily = UMT.Property
    {
        get = function(self)
            return self._font._family()
        end,

        set = function(self, value)
            self._font._family:Set(value)
        end
    },

    FontSize = UMT.Property
    {
        get = function(self)
            return self._font._pointsize()
        end,

        set = function(self, value)
            value = math.floor(value * (self._scale or LayoutHelpers.GetPixelScaleFactor()))
            self._font._pointsize:Set(value)
        end
    },

    Color = UMT.Property
    {
        get = function(self)
            return self._color()
        end,

        set = function(self, value)
            self._color:Set(value)
        end
    },

}
