local OptionsWindow = import("OptionsWindow.lua").OptionsWindow
local Filter = import("Views/Filter.lua").Filter
local ColorSliders = import("Views/ColorSliders.lua").ColorSliders
local Splitter = import("Views/Splitter.lua").Splitter
local UIUtil = import('/lua/ui/uiutil.lua')



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
