---@meta

---@class ReUI.UI.Color : ReUI.Module
ReUI.UI.Color = {}

---Returns new color with given aplha part
---@param color Color
---@param alpha integer
---@return Color
function ReUI.UI.Color.SetAlpha(color, alpha)
end

---Returns new color with given red part
---@param color Color
---@param red integer
---@return Color
function ReUI.UI.Color.SetRed(color, red)
end

---Returns new color with given green part
---@param color Color
---@param green integer
---@return Color
function ReUI.UI.Color.SetGreen(color, green)
end

---Returns new color with given blue part
---@param color Color
---@param blue integer
---@return Color
function ReUI.UI.Color.SetBlue(color, blue)
end

---Returns alpha part of color
---@param color Color
---@return integer
function ReUI.UI.Color.GetAlpha(color)
end

---Returns red part of color
---@param color Color
---@return integer
function ReUI.UI.Color.GetRed(color)
end

---Returns green part of color
---@param color Color
---@return integer
function ReUI.UI.Color.GetGreen(color)
end

---Returns blue part of color
---@param color Color
---@return integer
function ReUI.UI.Color.GetBlue(color)
end

---Returns color as string from RGBA components
---@param r integer
---@param g integer
---@param b integer
---@param a? integer
---@return Color
function ReUI.UI.Color.ColorRGBA(r, g, b, a)
end

---Retuns RGBA components of the given color as integers
---@param color string
---@return integer @red
---@return integer @green
---@return integer @blue
---@return integer @alpha
function ReUI.UI.Color.UnpackColor(color)
end

---Multiplies color by given value
---@param color Color
---@param mult number
---@return Color
function ReUI.UI.Color.ColorMult(color, mult)
end
