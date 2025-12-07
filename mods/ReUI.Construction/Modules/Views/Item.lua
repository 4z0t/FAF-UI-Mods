local Bitmap       = ReUI.UI.Controls.Bitmap
local Text         = ReUI.UI.Controls.Text
local CheckBox     = ReUI.UI.Controls.CheckBox
local Group        = ReUI.UI.Controls.Group
local BaseGridItem = ReUI.UI.Views.Grid.BaseGridItem

local UIUtil = import("/lua/ui/uiutil.lua")
local StrategicIconsFile = import("/lua/ui/game/straticons.lua")
local LazyVar = import('/lua/lazyvar.lua').Create

local validIcons = { land = true, air = true, sea = true, amph = true }
---@param unitID string
---@return FileName
---@return FileName
---@return FileName
---@return FileName
local function GetBackgroundTextures(unitID)
    local bp = __blueprints[unitID]
    local icon = "land"
    if unitID and unitID ~= 'default' then
        local bpIcon = bp.General.Icon
        if not validIcons[bpIcon] then
            if bpIcon then
                WARN(debug.traceback(nil, "Invalid icon" .. bpIcon .. " for unit " .. tostring(unitID)))
            end
            bp.General.Icon = "land"
        else
            icon = bpIcon
        end
    end

    return UIUtil.UIFile('/icons/units/' .. icon .. '_up.dds'--[[@as FileName]] ),
        UIUtil.UIFile('/icons/units/' .. icon .. '_down.dds'--[[@as FileName]] ),
        UIUtil.UIFile('/icons/units/' .. icon .. '_over.dds'--[[@as FileName]] ),
        UIUtil.UIFile('/icons/units/' .. icon .. '_up.dds'--[[@as FileName]] )
end

---@class ReUI.Construction.Grid.Item : BaseGridItem
---@field _grid  ReUI.Construction.Grid
---@field _bg  ReUI.UI.Controls.Bitmap
---@field _icon  ReUI.UI.Controls.Bitmap
---@field _strategicIcon  ReUI.UI.Controls.Bitmap
---@field _text  ReUI.UI.Controls.Text
---@field _textSize number
Item = ReUI.Core.Class(BaseGridItem)
{
    ---@type Lazy<Color>
    TextColor = LazyVar("ffffffff"),

    ---@param self ReUI.Construction.Grid.Item
    ---@param parent ReUI.Construction.Grid
    __init = function(self, parent)
        BaseGridItem.__init(self, parent)
        self._grid = parent

        self._bg = Bitmap(self)
        self._icon = Bitmap(self)
        self._strategicIcon = Bitmap(self)
        self._text = Text(self)

        self._textSize = 0
    end,

    ---@param self ReUI.Construction.Grid.Item
    ---@param layouter ReUI.UI.Layouter
    InitLayout = function(self, layouter)
        BaseGridItem.InitLayout(self, layouter)
        layouter(self._bg)
            :Fill(self)
            :DisableHitTest()
            :Over(self, 1)

        layouter(self._icon)
            :Fill(self)
            :DisableHitTest()
            :Over(self, 2)

        layouter(self._strategicIcon)
            :AtLeftTopIn(self, 4, 4)
            :DisableHitTest()
            :Over(self, 3)

        layouter(self._text)
            :AtRightBottomIn(self, 2)
            :Color(self.TextColor)
            :DropShadow(true)
            :DisableHitTest()
            :Over(self, 10)

        layouter(self)
            :Color "00000000"

        self.TextSize = 20
    end,

    ---@type string
    ---@diagnostic disable-next-line:assign-type-mismatch
    Icon = ReUI.Core.Property
    {
        ---@param self ReUI.Construction.Grid.Item
        set = function(self, value)
            if value == nil then
                self._icon:Hide()
                return
            end

            if DiskGetFileInfo(UIUtil.UIFile('/icons/units/' .. value .. '_icon.dds'--[[@as FileName]] , true)) then
                self._icon:SetTexture(UIUtil.UIFile('/icons/units/' .. value .. '_icon.dds'--[[@as FileName]] , true))
            else
                self._icon:SetTexture(UIUtil.UIFile('/icons/units/default_icon.dds'))
            end
            self._icon:Show()
        end
    },

    ---@type string
    ---@diagnostic disable-next-line:assign-type-mismatch
    IconColor = ReUI.Core.Property
    {
        ---@param self ReUI.Construction.Grid.Item
        set = function(self, value)
            if value == nil then
                self._icon:Hide()
                return
            end
            self._icon:SetSolidColor(value)
            self._icon:Show()
        end
    },

    ---@type string
    ---@diagnostic disable-next-line:assign-type-mismatch
    StrategicIcon = ReUI.Core.Property
    {
        ---@param self ReUI.Construction.Grid.Item
        set = function(self, value)
            if value == nil then
                self._strategicIcon:Hide()
                return
            end

            local iconName = __blueprints[value].StrategicIconName
            if not iconName then
                self._strategicIcon:Hide()
                return
            end

            local path = '/textures/ui/common/game/strategicicons/' .. iconName .. '_rest.dds' --[[@as FileName]]
            if DiskGetFileInfo(path) then
                self._strategicIcon:SetTexture(path)
                self._strategicIcon:Show()
                return
            end

            local icon = StrategicIconsFile.aSpecificStratIcons[value] or
                StrategicIconsFile.aStratIconTranslation[iconName]

            if not icon then
                self._strategicIcon:Hide()
                return
            end

            local path = '/textures/ui/icons_strategic/' .. icon .. '.dds' --[[@as FileName]]
            if not DiskGetFileInfo(path) then
                self._strategicIcon:Hide()
                return
            end

            self._strategicIcon:SetTexture(path)
            self._strategicIcon:Show()
        end
    },

    ---@type string
    ---@diagnostic disable-next-line:assign-type-mismatch
    BackGround = ReUI.Core.Property
    {
        ---@param self ReUI.Construction.Grid.Item
        set = function(self, value)
            if value == nil then
                self._bg:Hide()
                return
            end

            self._bg:SetTexture(value)
            self._bg:Show()
        end
    },

    ---@type string|number
    ---@diagnostic disable-next-line:assign-type-mismatch
    Text = ReUI.Core.Property
    {
        ---@param self ReUI.Construction.Grid.Item
        set = function(self, value)
            if value == nil then
                self._text:Hide()
                return
            end

            self._text:SetText(value)
            self._text:Show()
        end
    },

    TextSize = ReUI.Core.Property
    {
        ---@param self ReUI.Construction.Grid.Item
        set = function(self, value)
            if value == self._textSize then
                return
            end

            self._textSize = value
            self._text:SetFont("Arial", value)
        end,
    } --[[@as number]] ,

    ---@param self ReUI.Construction.Grid.Item
    ---@param id BlueprintId
    ---@param mode? "up"|"down"|"rest"|"disabled"
    DisplayBPID = function(self, id, mode)
        if id == nil then
            return
        end

        mode = mode or "rest"
        self.StrategicIcon = id
        self:SetBackGroundFromId(id, mode)
        self.Icon = id
    end,

    ---@param self ReUI.Construction.Grid.Item
    ClearDisplay = function(self)
        self.StrategicIcon = nil
        self.BackGround = nil
        self.Icon = nil
        self.Text = nil
        self.TextSize = 20
        self._text:SetColor(self.TextColor)
    end,

    ---@param self ReUI.Construction.Grid.Item
    ---@param id string
    ---@param mode? "up"|"down"|"rest"|"disabled"
    SetBackGroundFromId = function(self, id, mode)
        if id == nil then
            self._bg:Hide()
            return
        end

        local up, down, rest, dis = GetBackgroundTextures(id)
        local texture = rest
        if mode == "up" then
            texture = up
        elseif mode == "rest" then
            texture = rest
        elseif mode == "down" then
            texture = down
        elseif mode == "disabled" then
            texture = dis
        end
        self._bg:SetTexture(texture)
        self._bg:Show()
    end,

    ---@param self ReUI.Construction.Grid.Item
    ---@param immediately? boolean
    UpdatePanel = function(self, immediately)
        local panel = self._grid.panel
        if immediately then
            panel:Refresh()
        else
            ForkThread(panel.Refresh, panel)
        end
    end,

    ---@param self ReUI.Construction.Grid.Item
    OnDestroy = function(self)
        self._grid = nil
        self._bg = nil
        self._icon = nil
        self._strategicIcon = nil
        self._text = nil
        BaseGridItem.OnDestroy(self)
    end,
}
