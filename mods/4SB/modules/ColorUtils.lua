---@module "ColorUtils"


---@alias Color  string
---@alias hexstring string

---comment
---@param s hexstring
---@return hexstring
local function Norm(s)
    if string.len(s) == 1 then
        return "0" .. s
    end
    return s
end

---comment
---@param color Color
---@param alpha integer
---@return Color
function SetAlpha(color, alpha)
    return Norm(STR_itox(alpha)) .. string.sub(color, 3)
end

---comment
---@param color Color
---@param red integer
---@return Color
function SetRed(color, red)
    return string.sub(color, 1, 2) .. Norm(STR_itox(red)) .. string.sub(color, 5)
end

---comment
---@param color Color
---@param green integer
---@return Color
function SetGreen(color, green)
    return string.sub(color, 1, 4) .. Norm(STR_itox(green)) .. string.sub(color, 7)
end

---comment
---@param color Color
---@param blue integer
---@return Color
function SetBlue(color, blue)
    return string.sub(color, 1, 6) .. Norm(STR_itox(blue))
end

---comment
---@param color Color
---@return integer
function GetAlpha(color)
    return STR_xtoi(string.sub(color, 1, 2))
end

---comment
---@param color Color
---@return integer
function GetRed(color)
    return STR_xtoi(string.sub(color, 3, 4))
end

---comment
---@param color Color
---@return integer
function GetGreen(color)
    return STR_xtoi(string.sub(color, 5, 6))
end

---comment
---@param color Color
---@return integer
function GetBlue(color)
    return STR_xtoi(string.sub(color, 7, 8))
end

---comment
---@param r integer
---@param g integer
---@param b integer
---@param a? integer
---@return Color
function ColorRGBA(r, g, b, a)
    if a then
        return Norm(STR_itox(a)) ..
            Norm(STR_itox(r)) ..
            Norm(STR_itox(g)) ..
            Norm(STR_itox(b))
    else
        return "FF" .. Norm(STR_itox(r)) ..
            Norm(STR_itox(g)) ..
            Norm(STR_itox(b))
    end
end

---comment
---@param color string
---@return integer
---@return integer
---@return integer
---@return integer
function UnpackColor(color)
    return GetRed(color), GetGreen(color), GetBlue(color), GetAlpha(color)
end

---comment
---@param color Color
---@param mult number
---@return Color
function ColorMult(color, mult)
    local r, g, b = UnpackColor(color)
    r = math.floor(math.clamp(r * mult, 0, 255))
    g = math.floor(math.clamp(g * mult, 0, 255))
    b = math.floor(math.clamp(b * mult, 0, 255))
    return ColorRGBA(r, g, b)
end
