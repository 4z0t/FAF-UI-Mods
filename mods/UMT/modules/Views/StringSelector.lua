local Group = import('/lua/maui/group.lua').Group
local UIUtil = import('/lua/ui/uiutil.lua')
local Combo = import('/lua/ui/controls/combo.lua').Combo
local LayoutFor = UMT.Layouter.ReusedLayoutFor
local LuaQ = UMT.LuaQ




---@class StringSelector : Group
StringSelector = Class(Group)
{
    ---comment
    ---@param self StringSelector
    ---@param parent Control
    ---@param optionVar OptionVar
    ---@param name string
    __init = function(self, parent, optionVar, name, items)
        Group.__init(self, parent)

        self._option = optionVar
        self._name = UIUtil.CreateText(self, name, 14, "Arial")
        self._combo = Combo(self, 13, 16)
        self._combo.OnClick = function(control, index, text)
            control:SetItem(index)
            optionVar:Set(text)
        end


        local currentItem = optionVar()
        
        local id = items | LuaQ.contains(currentItem)
        if not id then
            optionVar:Set(items[1])
            optionVar:Save()
            id = 1
        end
        self._combo:AddItems(items, id)
    end,

    __post_init = function(self, parent)
        self:_Layout(parent)
    end,

    _Layout = function(self, parent)
        LayoutFor(self._name)
            :AtLeftTopIn(self, 2)
            :DisableHitTest()

        LayoutFor(self._combo)
            :Below(self._name, 2)
            :Width(200)

        LayoutFor(self)
            :Right(self._combo.Right)
            :Bottom(self._combo.Bottom)
    end,

    OnDestroy = function(self)
        self._option = nil
    end

}
