local UIUtil = import("/lua/ui/uiutil.lua")
local Group = ReUI.UI.Controls.Group


---@class OptionsControlPos
---@field [1] number
---@field [2] number
---@field [3] number
---@field [4] number

---@class OptionsControlArgs
---@field option ReUI.Options.ReactiveOption
---@field pos OptionsControlPos

---@class ReUI.Options.OptionsMenu : ReUI.UI.Controls.Group
OptionsMenu = ReUI.Core.Class(Group)
{
    ---@param self ReUI.Options.OptionsMenu
    ---@param parent Control
    __init = function(self, parent)
        Group.__init(self, parent)


    end,

    ---@param self ReUI.Options.OptionsMenu
    ---@param layouter ReUI.UI.Layouter
    InitLayout = function(self, layouter)

    end,

    ---@generic C : ReUI.Options.OptionControl
    ---@param self ReUI.Options.OptionsMenu
    ---@param cls C
    ---@param args OptionsControlArgs
    ---@return ReUI.Options.OptionsMenu
    AddControl = function(self, cls, args)
        return self
    end,
}
