local Group = UMT.Controls.Group
local Bitmap = UMT.Controls.Bitmap
local Text = UMT.Controls.Text
local UIUtil = import('/lua/ui/uiutil.lua')
local Tooltip = import('/lua/ui/game/tooltip.lua')
local ExpandableSelectionGroup = import("Views/ExpandableSelectionGroup.lua").ExpandableSelectionGroup
local ExpandableGroup = import("Views/ExpandableGroup.lua").ExpandableGroup
local AnimatedBorderedCheckBox = import("Views/BorderedCheckBox.lua").AnimatedBorderedCheckBox
local LazyVar = import('/lua/lazyvar.lua').Create

local Functions = UMT.Layouter.Functions

local Options = import("Options.lua")

local textSize = 12

local panelWidth = 300
local panelHeight = 20
local checkboxWidth = 18
local checkboxHeight = 18

local bgColor = Options.player.color.bg:Raw()
local textFont = Options.player.font.data:Raw()

local checkboxes = import("DataPanelConfig.lua").checkboxes
local Chechbox = UMT.Class(AnimatedBorderedCheckBox)
{
    HandleEvent = function(self, event)
        if event.Type == 'WheelRotation' then
            local dropdown = self:GetParent()
            local dataPanel = dropdown:GetParent()
            local GetData = checkboxes[dropdown._id][self._id + 1].GetData
            dataPanel:Sort(dropdown._id, GetData, event.WheelRotation)
            return true
        end
        return AnimatedBorderedCheckBox.HandleEvent(self, event)
    end
}

local CheckboxDropDown = UMT.Class(ExpandableSelectionGroup)
{
    __init = function(self, parent, width, height)
        ExpandableSelectionGroup.__init(self, parent, width, height)
        self._bg = Bitmap(self)

        self._direction = false
        self._sortId = false

        self._arrow = Text(self)
        self._arrow:SetText("")
        self._arrow:SetFont(textFont, 14)

        self.Layouter(self._bg)
            :Color(bgColor)
            :Fill(self._expand)
            :Top(self.Bottom)

        self.Layouter(self._arrow)
            :AtVerticalCenterIn(self)
            :AnchorToRight(self)
            :DisableHitTest()
    end,

    AddControls = function(self, controls)
        ExpandableGroup.AddControls(self, controls)


        local function CheckBoxOnClick(control, modifiers)
            local dropdown = control:GetParent()
            local dataPanel = dropdown:GetParent()
            if modifiers.Left then
                if dropdown._isExpanded then
                    dropdown:SetActiveControl(control._id)
                    dataPanel:UpdateDataSetup(dropdown._id, control._id + 1)
                    dropdown:Contract()
                else
                    dropdown:Expand()
                end
            elseif modifiers.Right and control == dropdown._active then
                control:ToggleCheck()
                if control._checkState == "checked" then
                    dataPanel._sb:Expand(dropdown._id)
                else
                    dataPanel._sb:Contract(dropdown._id)
                end
            end
        end

        self._active._id = 0
        self._active.OnClick = CheckBoxOnClick
        self._active:SetAlpha(1)

        for i, control in self._controls do
            control._id = i
            control.OnClick = CheckBoxOnClick
            control:SetAlpha(0)
        end
    end,

    SetDirection = function(self, direction)

        if not direction then
            self._sortId = false
            self._arrow:SetText("")
            return
        end
        if direction > 0 then
            self._arrow:SetText("↑")
            self._direction = 1
        else
            self._arrow:SetText("↓")
            self._direction = -1
        end
        self._sortId = self._active._id
        self._arrow:SetColor(self._active._color)
    end,

    SetActiveControl = function(self, control)
        local new, old = ExpandableSelectionGroup.SetActiveControl(self, control)
        if self._active._id == self._sortId then
            self:SetDirection(self._direction)
        else
            self._arrow:SetText("")
        end
        return new, old
    end
}


---@class DataPanel : UMT.Group
---@field _bg Bitmap
DataPanel = UMT.Class(Group)
{
    __init = function(self, parent)
        Group.__init(self, parent)
        self._sb = parent
        self._bg = Bitmap(self)
        self._setup = {}
        self._dropdowns = {}
        for i, category in checkboxes do
            local dropdown = CheckboxDropDown(self, panelHeight, panelHeight)
            dropdown._id = i
            table.insert(self._dropdowns, dropdown)
            table.insert(self._setup, 1)
        end

        self._replayId = Text(self)
    end,

    __post_init = function(self)
        self:Layout()
        self:_SetupCheckBoxes()
        self._sb:SetDataSetup(self._setup)
        self._replayId:SetText(tostring(UIUtil.GetReplayId() or ""))
    end,

    ---@param self DataPanel
    ---@param layouter UMT.Layouter
    _Layout = function(self, layouter)


        local dropdownsCount = table.getn(self._dropdowns)

        local first = self._dropdowns[1]

        local spacing = LazyVar()

        spacing:Set(
            layouter:Min(
                20,
                Functions.Div(
                    layouter:Diff(self.Width, dropdownsCount * checkboxWidth),
                    dropdownsCount + 1
                )
            )
        )

        layouter(self._bg)
            :Fill(self)
            :Color(bgColor)
            :DisableHitTest()


        layouter(self)
            :Width(panelWidth)
            :Height(panelHeight)

        for i, dropdown in self._dropdowns do
            if i == dropdownsCount then

                layouter(dropdown)
                    :AtVerticalCenterIn(self)
                    :Right(Functions.Diff(self.Right, spacing))
            elseif i == 1 then
                local nextDD = self._dropdowns[i + 1]
                local dd = dropdown
                layouter(dropdown)
                    :AtVerticalCenterIn(self)
                    :Left(function()
                        local left = dd.Right() - dd.Width()
                        if left < self._replayId.Right() then
                            self._replayId:Hide()
                        else
                            self._replayId:Show()
                        end
                        return left
                    end)
                    :Right(Functions.Diff(nextDD.Left, spacing))
            else
                local nextDD = self._dropdowns[i + 1]
                layouter(dropdown)
                    :AtVerticalCenterIn(self)
                    :Right(Functions.Diff(nextDD.Left, spacing))
            end

        end

        layouter(self._replayId)
            :AtVerticalCenterIn(self)
            :Color("ffaaaaaa")
            :DisableHitTest()
            :AtLeftIn(self, 4)
        self._replayId:SetFont(textFont, textSize)
    end,

    _SetupCheckBoxes = function(self)
        local layouter = self.Layouter
        for i, dropdown in self._dropdowns do
            local cbs = {}
            for j, checkboxData in checkboxes[i] do
                local checkbox = Chechbox(
                    dropdown,
                    checkboxData.nu,
                    checkboxData.nc,
                    checkboxData.ou,
                    checkboxData.oc,
                    checkboxData.du,
                    checkboxData.dc
                )
                layouter(checkbox)
                    :Width(checkboxWidth)
                    :Height(checkboxHeight)
                checkbox:SetText(checkboxData.text)
                checkbox:SetFont(textFont, textSize)
                checkbox:SetCheck(true)
                Tooltip.AddControlTooltip(checkbox, checkboxData.tooltip, 0.5)
                cbs[j] = checkbox
            end
            dropdown:AddControls(cbs)
        end
    end,

    UpdateDataSetup = function(self, category, id)
        self._setup[category] = id
        self._sb:SetDataSetup(self._setup)
    end,

    ResetDirection = function(self)
        for i, dropdown in self._dropdowns do
            dropdown:SetDirection()
        end
    end,

    HandleEvent = function(self, event)
        if event.Type == 'WheelRotation' then
            self:ResetDirection()
            self._sb:SortArmies(nil, 0)
        end
    end,

    Sort = function(self, index, sortFun, direction)
        self:ResetDirection()
        self._dropdowns[index]:SetDirection(direction)
        self._sb:SortArmies(sortFun, direction > 0 and 1 or -1)
    end
}
