local Group = import('/lua/maui/group.lua').Group
local UIUtil = import('/lua/ui/uiutil.lua')
local Combo = import('/lua/ui/controls/combo.lua').Combo
local LayoutFor = UMT.Layouter.ReusedLayoutFor
local LuaQ = UMT.LuaQ

local Edit = import("/lua/maui/edit.lua").Edit


---@class TextEdit : Group
---@field _edit Edit
---@field _option OptionVar
TextEdit = Class(Group)
{
    ---comment
    ---@param self TextEdit
    ---@param parent Control
    ---@param optionVar OptionVar
    ---@param name string
    __init = function(self, parent, optionVar, name, charLimit)
        Group.__init(self, parent)

        self._name = UIUtil.CreateText(self, name, 14, "Arial")

        self._option = optionVar
        self._edit = Edit(self)
        LayoutFor(self._edit)
            :Below(self._name, 2)
            :Height(18)
            :Width(200)
        UIUtil.SetupEditStd(self._edit,
            "ff00ff00",
            'ff000000',
            "ffffffff",
            UIUtil.highlightColor,
            UIUtil.bodyFont,
            16,
            charLimit
        )
        self._edit:SetText(optionVar())
        self._edit.OnEnterPressed = function(edit, text)
            optionVar:Set(text)
            return true
        end



    end,

    __post_init = function(self, parent)
        self:InitLayout(parent)
    end,

    InitLayout = function(self, parent)
        LayoutFor(self._name)
            :AtLeftTopIn(self, 2)
            :DisableHitTest()



        LayoutFor(self)
            :Right(self._edit.Right)
            :Bottom(self._edit.Bottom)
    end,

    OnDestroy = function(self)
        self._option = nil
    end

}
