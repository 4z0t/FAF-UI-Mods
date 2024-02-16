local Text = UMT.Controls.Text

local colors =
{
    "ffff0000", --red
    "ffFF4500", --OrangeRed
    "ffFFA500", --Orange
    "ffffFf00", --yellow
    "ff00ff00", --lime
    "ff00FA9A", --MediumSpringGreen
    "ff00FFFF", --aqua
    "ff9ACD32", --YellowGreen
    "FFFF00FF", --Magenta
    "FFE6E6FA", --Lavender
    "FF0000FF", --bLUE
    "FF00BFFF", --DeepSkyBlue
    "FF000080", --NAVY


}
-- local colors = {
--     "ffff0000",--red
--     "ffffFf00",--yellow
--     "ff00ff00",--lime
--     "FF0000FF",--bLUE
-- }
local colors_count = table.getn(colors)
TIME_INTERVAL = 0.5
function GetRGB(color)
    if type(color) == 'string' then
        return STR_xtoi(string.sub(color, 3, 4)),
            STR_xtoi(string.sub(color, 5, 6)),
            STR_xtoi(string.sub(color, 7, 8))
    else --TABLES AND NUMEBRS WTF
        return 0, 0, 0
    end
end

function ColorDif(c1, c2)
    local r1, g1, b1 = GetRGB(c1)
    local r2, g2, b2 = GetRGB(c2)
    return r1 - r2, g1 - g2, b1 - b2
end

function GetColor(r, g, b)
    local function norm(s)
        if string.len(s) == 1 then
            return '0' .. s
        end
        return s
    end

    return 'ff' .. norm(STR_itox(r)) .. norm(STR_itox(g)) .. norm(STR_itox(b))
end

---@class RainbowText : Text
RainbowText = UMT.Class(Text) {

    __init = function(self, parent, debugname)
        Text.__init(self, parent, debugname)
        self:SetNeedsFrameUpdate(true)
        self._color_time = TIME_INTERVAL

    end,

    OnFrame = function(self, deltaTime)
        self._color_time = self._color_time + deltaTime
        if self._color_time >= TIME_INTERVAL then
            self._target_color           = colors[math.random(1, colors_count)]
            self._old_color              = self._color()
            self._r, self._g, self._b    = GetRGB(self._old_color)
            self._dr, self._dg, self._db = ColorDif(self._target_color, self._old_color)
            self._color_time             = 0

        end
        local coef = self._color_time / TIME_INTERVAL
        local _r = math.floor(self._r + self._dr * coef)
        local _g = math.floor(self._g + self._dg * coef)
        local _b = math.floor(self._b + self._db * coef)
        self:SetColor(GetColor(_r, _g, _b))
    end,

}
