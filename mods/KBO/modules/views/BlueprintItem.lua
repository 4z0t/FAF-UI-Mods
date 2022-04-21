local Group = import('/lua/maui/group.lua').Group
local UIUtil = import('/lua/ui/uiutil.lua')
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local Bitmap = import('/lua/maui/bitmap.lua').Bitmap

BPITEM_WIDTH = 192
BPITEM_HEIGHT = 64

BlueprintItem = Class(Group) {
    __init = function(self, parent, skin)
        Group.__init(self, parent)
        LayoutHelpers.SetDimensions(self, BPITEM_WIDTH, BPITEM_HEIGHT)

        self._icon = Bitmap(self)
        self._icon:Hide()
        LayoutHelpers.AtLeftIn(self._icon, self, 2)
        LayoutHelpers.AtVerticalCenterIn(self._icon, self)

        self._name = UIUtil.CreateText(self, '', 10, UIUtil.bodyFont, true)
        LayoutHelpers.AtRightBottomIn(self._name, self, 4, 3)

        self._blueprint = false

        self._blueprintText = UIUtil.CreateText(self, '', 10, UIUtil.bodyFont, true)
        self._blueprintText:SetColor(UIUtil.panelColor)
        LayoutHelpers.AtRightTopIn(self._blueprintText, self, 4, 3)

        self._bg = Bitmap(self)
        self._bg._over = '/textures/ui/' .. skin .. '/MODS/double.dds'
        self._bg._rest = '/textures/ui/' .. skin .. '/MODS/single.dds'
        self._bg:SetTexture(self._bg._rest)
        self._bg:SetAlpha(0.5)
        LayoutHelpers.FillParent(self._bg, self)
        

        self._icon:DisableHitTest()
        self._bg:DisableHitTest()
        self._blueprintText:DisableHitTest()
        self._name:DisableHitTest()

    end,

    SetBlueprint = function(self, blueprint)
        if blueprint then
            local icon = UIUtil.UIFile('/icons/units/' .. blueprint .. '_icon.dds', true)
            self._blueprint = blueprint
            self._icon:SetTexture(icon)

            self._icon:Show()
            self._blueprintText:SetText(blueprint)
            self._name:SetText(LOC(__blueprints[blueprint].Interface.HelpText))
        else
            self._icon:Hide()
            self._blueprint = false
            self._blueprintText:SetText('')
            self._name:SetText('')
        end
    end,
    GetBlueprint = function(self)
        return self._blueprint
    end,

    HandleEvent = function(self, event)
        if event.Type == 'MouseExit' then
            self._bg:SetTexture(self._bg._rest)
            self._bg:SetAlpha(0.5)
            return true
        elseif event.Type == 'MouseEnter' then
            self._bg:SetTexture(self._bg._over)
            self._bg:SetAlpha(1)
            return true
        elseif event.Type == 'ButtonPress' then
            self:OnClick(event.Modifiers, self._blueprint)
            return true
        end
        return false
    end,

    -- overloadable
    OnClick = function(self, modifiers, blueprint)

    end

}