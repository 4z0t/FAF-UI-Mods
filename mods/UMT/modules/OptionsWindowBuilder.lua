local OptionsWindow = import("OptionsWindow.lua").OptionsWindow
local Filter = import("Views/Filter.lua").Filter
local ColorSliders = import("Views/ColorSliders.lua").ColorSliders
local Splitter = import("Views/Splitter.lua").Splitter
local UIUtil = import('/lua/ui/uiutil.lua')


---@class ControlConfig
---@field type  "splitter"|"title"|"color"|"slider"|"filter"|"edit"|"colorslider"
---@field name string
---@field optionVar OptionVar
---@field indent number


local splitterTable = {
    type = "splitter"
}

---comment
---@return ControlConfig
function Splitter()
    return splitterTable
end

---comment
---@return ControlConfig
function Title(name, fontSize, fontFamily, fontColor, indent)
    return {
        type = "title",
        name = name,
        size = fontSize or 16,
        family = fontFamily or UIUtil.titleFont,
        color = fontColor or UIUtil.highlightColor,
        indent = indent or 0
    }
end

---comment
---@return ControlConfig
function Color(name, optionVar, indent)
    return {
        type = "color",
        name = name,
        optionVar = optionVar,
        indent = indent or 0
    }
end

---comment
---@return ControlConfig
function Filter(name, optionVar, indent)
    return {
        type = "filter",
        name = name,
        optionVar = optionVar,
        indent = indent or 0
    }
end

---comment
---@return ControlConfig
function Slider(name, min, max, inc, optionVar, indent)
    return {
        type = "slider",
        name = name,
        optionVar = optionVar,
        min = min,
        max = max,
        inc = inc,
        indent = indent or 0
    }
end

---comment
---@return ControlConfig
function TextEdit(name, optionVar, indent)
    return {
        type = "edit",
        name = name,
        optionVar = optionVar,
        indent = indent or 0
    }
end

---comment
---@return ControlConfig
function ColorSlider(name, optionVar, indent)
    return {
        type = "colorslider",
        name = name,
        optionVar = optionVar,
        indent = indent or 0
    }
end

---@class OptionsWindowBuilder
---@field _control OptionsWindow
OptionsWindowBuilder = ClassSimple
{
    __init = function(self)
        self._control = nil
    end,

    _Started = function(self)
        return self._control ~= nil
    end,

    ---comment
    ---@param self OptionsWindowBuilder
    ---@param title string
    ---@param buildTable ControlConfig[]
    Create = function(self, title, buildTable)

    end,

    ---comment
    ---@param self OptionsWindowBuilder
    ---@param title string
    ---@return OptionsWindowBuilder
    Title = function(self, title)
        if self:_Started() then
            self._control:SetTitle(title)
            return self
        end

        
        return self
    end,

    ---comment
    ---@param self OptionsWindowBuilder
    ---@param controlConfig ControlConfig
    Add = function(self, controlConfig)

    end,

    ---comment
    ---@param self OptionsWindowBuilder
    ---@param colors string[]
    ExtendColors = function(self, colors)

    end,

    ---comment
    ---@param self OptionsWindowBuilder
    ---@return OptionsWindow
    End = function(self)
        local control = self._control
        self._control = nil
        return control
    end
}
