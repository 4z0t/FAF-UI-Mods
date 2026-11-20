local Group = import('/lua/maui/group.lua').Group
local UIUtil = import('/lua/ui/uiutil.lua')
local Bitmap = import('/lua/maui/bitmap.lua').Bitmap
local LayoutFor = ReUI.UI.FloorLayoutFor
local Tooltip = import('/lua/ui/game/tooltip.lua')

BPITEM_WIDTH = 175
BPITEM_HEIGHT = 52

local factionColors = {
    cybran   = "ffff4040",
    seraphim = "FFffd700",
    aeon     = "6BF32B",
    uef      = "ff4da6ff",
}

local factionTitles = {
    cybran   = "Cybran",
    seraphim = "Seraphim",
    aeon     = "Aeon",
    uef      = "UEF",
}

---@class BlueprintItem : Group
---@field _skin SkinName
---@field _blueprint string|table|false
---@field _icon Bitmap
---@field _bg Bitmap
---@field _name Text
---@field _blueprintText Text
BlueprintItem = Class(Group) {

    ---@param self BlueprintItem
    ---@param parent Control
    ---@param skin SkinName
    ---@param width? number
    ---@param height? number
    __init = function(self, parent, skin, width, height)
        self._skin = skin
        self._blueprint = false
        Group.__init(self, parent)

        width = width or BPITEM_WIDTH
        height = height or BPITEM_HEIGHT

        LayoutFor(self)
            :Width(width)
            :Height(height)

        self._bg = Bitmap(self)
        self._bg._over = '/textures/ui/' .. skin .. '/MODS/double.dds'
        self._bg._rest = '/textures/ui/' .. skin .. '/MODS/single.dds'
        self._bg:SetTexture(self._bg._rest)
        self._bg:SetAlpha(0.45)
        LayoutFor(self._bg)
            :Fill(self)
            :DisableHitTest()

        self._icon = Bitmap(self)
        self._icon:Hide()
        LayoutFor(self._icon)
            :AtLeftIn(self, 4)
            :AtVerticalCenterIn(self)
            :Width(40)
            :Height(40)
            :DisableHitTest()

        self._blueprintText = UIUtil.CreateText(self, '', 10, UIUtil.bodyFont, true)
        self._blueprintText:SetColor(factionColors[skin] or UIUtil.panelColor)
        self._blueprintText:SetClipToWidth(true)
        LayoutFor(self._blueprintText)
            :RightOf(self._icon, 4)
            :AtTopIn(self, 4)
            :AtRightIn(self, 4)
            :DisableHitTest()

        self._name = UIUtil.CreateText(self, '', 11, UIUtil.bodyFont, true)
        self._name:SetClipToWidth(true)
        LayoutFor(self._name)
            :RightOf(self._icon, 4)
            :Below(self._blueprintText, 1)
            :AtRightIn(self, 4)
            :DisableHitTest()

        self:SetBlueprint(false)
    end,

    ---@param self BlueprintItem
    ---@param data string|table|false
    SetBlueprint = function(self, data)
        local skinName = factionTitles[self._skin] or self._skin
        if type(data) == 'string' then
            self._blueprint = data
            self._icon:SetTexture(UIUtil.UIFile('/icons/units/' .. data .. '_icon.dds', true))
            self._icon:Show()

            local bp = __blueprints[data]
            local helpText = bp and bp.Interface and LOC(bp.Interface.HelpText)
            if not helpText or helpText == "" then
                helpText = bp and bp.Description and LOC(bp.Description) or data
            end

            self._blueprintText:SetText(data)
            self._blueprintText:SetColor(UIUtil.highlightColor or "ffffaa00")
            self._name:SetText(helpText)
            self._name:SetColor(UIUtil.bodyColor or "ffffffff")

            Tooltip.AddControlTooltipManual(self, helpText,
                string.format("ID: %s\nFaction: %s\n\nLeft-click: Change unit\nRight-click: Clear slot", data, skinName))
        elseif type(data) == 'table' then
            self._blueprint = data
            local iconId = data.icon or (data.templateData and data.templateData[3] and data.templateData[3][1])
            if iconId then
                self._icon:SetTexture(UIUtil.UIFile('/icons/units/' .. iconId .. '_icon.dds', true))
                self._icon:Show()
            else
                self._icon:Hide()
            end

            self._blueprintText:SetText("Template")
            self._blueprintText:SetColor("ffffff00")
            local tName = data.name or "Build Template"
            self._name:SetText(tName)
            self._name:SetColor(UIUtil.bodyColor or "ffffffff")

            Tooltip.AddControlTooltipManual(self, tName,
                string.format("Build Template (%s)\n\nLeft-click: Change template\nRight-click: Clear slot", skinName))
        else
            self._blueprint = false
            self._icon:Hide()
            self._blueprintText:SetText(skinName)
            self._blueprintText:SetColor(factionColors[self._skin] or "ff888888")
            self._name:SetText("+ Empty")
            self._name:SetColor("ff777777")

            Tooltip.AddControlTooltipManual(self, skinName .. " Slot",
                "Empty slot.\n\nLeft-click: Select blueprint to assign")
        end
    end,

    ---@param self BlueprintItem
    ---@return string|table|false
    GetBlueprint = function(self)
        return self._blueprint
    end,

    ---@param self BlueprintItem
    ---@param event KeyEvent
    ---@return boolean
    HandleEvent = function(self, event)
        if event.Type == 'MouseExit' then
            self._bg:SetTexture(self._bg._rest)
            self._bg:SetAlpha(0.45)
            return true
        elseif event.Type == 'MouseEnter' then
            self._bg:SetTexture(self._bg._over)
            self._bg:SetAlpha(1.0)
            return true
        elseif event.Type == 'ButtonPress' then
            if self.OnClick then
                self:OnClick(event.Modifiers, self._blueprint)
            end
            return true
        end
        return false
    end,

    ---@param self BlueprintItem
    ---@param modifiers KeyModifiers
    ---@param blueprint any
    OnClick = function(self, modifiers, blueprint) end
}
