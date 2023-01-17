---@module "ColorUtils"

local MathFloor = math.floor
local MathClamp = math.clamp

---returns hex representation of the given int
---@param int integer
---@return string
local function ToHexString(int)
    return string.format("%02X", int)
end

---returns new color with given aplha part
---@param color Color
---@param alpha integer
---@return Color
function SetAlpha(color, alpha)
    return ToHexString(alpha) .. string.sub(color, 3)
end

---returns new color with given red part
---@param color Color
---@param red integer
---@return Color
function SetRed(color, red)
    return string.sub(color, 1, 2) .. ToHexString(red) .. string.sub(color, 5)
end

---returns new color with given green part
---@param color Color
---@param green integer
---@return Color
function SetGreen(color, green)
    return string.sub(color, 1, 4) .. ToHexString(green) .. string.sub(color, 7)
end

---returns new color with given blue part
---@param color Color
---@param blue integer
---@return Color
function SetBlue(color, blue)
    return string.sub(color, 1, 6) .. ToHexString(blue)
end

---returns alpha part of color
---@param color Color
---@return integer
function GetAlpha(color)
    return tonumber(string.sub(color, 1, 2), 16)
end

---returns red part of color
---@param color Color
---@return integer
function GetRed(color)
    return tonumber(string.sub(color, 3, 4), 16)
end

---returns green part of color
---@param color Color
---@return integer
function GetGreen(color)
    return tonumber(string.sub(color, 5, 6), 16)
end

---returns blue part of color
---@param color Color
---@return integer
function GetBlue(color)
    return tonumber(string.sub(color, 7, 8), 16)
end

---returns color as string from RGBA components
---@param r integer
---@param g integer
---@param b integer
---@param a? integer
---@return Color
function ColorRGBA(r, g, b, a)
    if a then
        return string.format("%02x%02x%02x%02x", r, g, b, a)
    else
        return string.format("FF%02x%02x%02x", r, g, b)
    end
end

---retuns RGBA components of the given color as integers
---@param color string
---@return integer
---@return integer
---@return integer
---@return integer
function UnpackColor(color)
    return GetRed(color), GetGreen(color), GetBlue(color), GetAlpha(color)
end

---multiplies color by given value
---@param color Color
---@param mult number
---@return Color
function ColorMult(color, mult)
    local r, g, b = UnpackColor(color)
    r = MathFloor(MathClamp(r * mult, 0, 255))
    g = MathFloor(MathClamp(g * mult, 0, 255))
    b = MathFloor(MathClamp(b * mult, 0, 255))
    return ColorRGBA(r, g, b)
end
