local function Norm(s)
    if string.len(s) == 1 then
        return "0" .. s
    end
    return s
end

function SetAlpha(color, alpha)
    return Norm(STR_itox(alpha)) .. string.sub(color, 3)
end

function SetRed(color, red)
    return string.sub(color, 1, 2) .. Norm(STR_itox(red)) .. string.sub(color, 5)
end

function SetGreen(color, green)
    return string.sub(color, 1, 4) .. Norm(STR_itox(green)) .. string.sub(color, 7)
end

function SetBlue(color, blue)
    return string.sub(color, 1, 6) .. Norm(STR_itox(blue))
end

function GetAlpha(color)
    return STR_xtoi(string.sub(color, 1, 2))
end

function GetRed(color)
    return STR_xtoi(string.sub(color, 3, 4))
end

function GetGreen(color)
    return STR_xtoi(string.sub(color, 5, 6))
end

function GetBlue(color)
    return STR_xtoi(string.sub(color, 7, 8))
end

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

function UnpackColor(color)
    return GetRed(color), GetGreen(color), GetBlue(color), GetAlpha(color)
end

function ColorMult(color, mult)
    local r, g, b = UnpackColor(color)
    r = math.floor(math.clamp(r * mult, 0, 255))
    g = math.floor(math.clamp(g * mult, 0, 255))
    b = math.floor(math.clamp(b * mult, 0, 255))
    return ColorRGBA(r, g, b)

end
