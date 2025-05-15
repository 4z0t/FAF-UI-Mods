ReUI.Require
{
    "ReUI.Core >= 1.0.0",
    "ReUI.GamemainFix >= 1.0.0"
}

function Main(isReplay)

    local _tonumber = tonumber
    local MathFloor = math.floor
    local MathClamp = math.clamp
    local StringFormat = string.format
    local StringSub = string.sub

    ---returns hex representation of the given int
    ---@param int integer
    ---@return string
    local function ToHexString(int)
        return StringFormat("%02X", int)
    end

    ---returns new color with given aplha part
    ---@param color Color
    ---@param alpha integer
    ---@return Color
    local function SetAlpha(color, alpha)
        return ToHexString(alpha) .. StringSub(color, 3)
    end

    ---returns new color with given red part
    ---@param color Color
    ---@param red integer
    ---@return Color
    local function SetRed(color, red)
        return StringSub(color, 1, 2) .. ToHexString(red) .. StringSub(color, 5)
    end

    ---returns new color with given green part
    ---@param color Color
    ---@param green integer
    ---@return Color
    local function SetGreen(color, green)
        return StringSub(color, 1, 4) .. ToHexString(green) .. StringSub(color, 7)
    end

    ---returns new color with given blue part
    ---@param color Color
    ---@param blue integer
    ---@return Color
    local function SetBlue(color, blue)
        return StringSub(color, 1, 6) .. ToHexString(blue)
    end

    ---returns alpha part of color
    ---@param color Color
    ---@return integer
    local function GetAlpha(color)
        return _tonumber(StringSub(color, 1, 2), 16)
    end

    ---returns red part of color
    ---@param color Color
    ---@return integer
    local function GetRed(color)
        return _tonumber(StringSub(color, 3, 4), 16)
    end

    ---returns green part of color
    ---@param color Color
    ---@return integer
    local function GetGreen(color)
        return _tonumber(StringSub(color, 5, 6), 16)
    end

    ---returns blue part of color
    ---@param color Color
    ---@return integer
    local function GetBlue(color)
        return _tonumber(StringSub(color, 7, 8), 16)
    end

    ---returns color as string from RGBA components
    ---@param r integer
    ---@param g integer
    ---@param b integer
    ---@param a? integer
    ---@return Color
    local function ColorRGBA(r, g, b, a)
        return StringFormat("%02x%02x%02x%02x", a or 255, r, g, b)
    end

    ---retuns RGBA components of the given color as integers
    ---@param color string
    ---@return integer @red
    ---@return integer @green
    ---@return integer @blue
    ---@return integer @alpha
    local function UnpackColor(color)
        return GetRed(color), GetGreen(color), GetBlue(color), GetAlpha(color)
    end

    ---multiplies color by given value
    ---@param color Color
    ---@param mult number
    ---@return Color
    local function ColorMult(color, mult)
        local r, g, b = UnpackColor(color)
        r = MathFloor(MathClamp(r * mult, 0, 255))
        g = MathFloor(MathClamp(g * mult, 0, 255))
        b = MathFloor(MathClamp(b * mult, 0, 255))
        return ColorRGBA(r, g, b)
    end

    return {
        SetAlpha = SetAlpha,
        SetRed = SetRed,
        SetGreen = SetGreen,
        SetBlue = SetBlue,

        GetAlpha = GetAlpha,
        GetRed = GetRed,
        GetGreen = GetGreen,
        GetBlue = GetBlue,

        ColorMult = ColorMult,
        ColorRGBA = ColorRGBA,
        UnpackColor = UnpackColor,
    }
end
