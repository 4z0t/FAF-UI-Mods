ReUI.Require
{
    "ReUI.ActionsPanel >= 1.1.0",
}

function Main(isReplay)

    local ASelectionHandler = ReUI.UI.Views.Grid.Abstract.ASelectionHandler
    local AItemComponent = ReUI.UI.Views.Grid.Abstract.AItemComponent
    local UIUtil = import("/lua/ui/uiutil.lua")

    local sessionInfo = SessionGetScenarioInfo()
    local isCheatsEnabled = sessionInfo.Options.CheatsEnabled == "true"

    ---@class ConsoleActions : ASelectionHandler
    local ConsoleActions = Class(ASelectionHandler)
    {
        Name = "Console commands",
        Description = [[Commands for
            * adjusting game speed
            * displaying various stuff
        ]],
        Enabled = true,
        ---@param self ConsoleActions
        ---@param selection UserUnit[]
        ---@return string[]?
        Update = function(self, selection)
            if isCheatsEnabled and not SessionIsReplay() then
                return self.Actions
            end
        end,

        Actions =
        {
            { "WLD_DecreaseSimRate", "-" },
            { "WLD_IncreaseSimRate", "+" },
            { "SallyShears", "☼" },
        },

        ---@class GSComponent : AItemComponent
        ---@field data string[]
        ---@field name ReUI.UI.Controls.Text
        ComponentClass = Class(AItemComponent)
        {
            ---Called when component is bond to an item
            ---@param self GSComponent
            ---@param item BaseGridItem
            Create = function(self, item)
                self.name = ReUI.UI.Controls.Text(item)
                self.name:SetFont("Arial", 32)
                item.Layouter(self.name)
                    :AtCenterIn(item)
                    :Color("C3E600")
                    :DropShadow(true)
                    :DisableHitTest()
                    :Hide()
            end,


            ---Called when grid item receives an event
            ---@param self GSComponent
            ---@param item BaseGridItem
            ---@param event KeyEvent
            HandleEvent = function(self, item, event)
                if event.Type == "ButtonPress" or event.Type == "ButtonDClick" then
                    local action = self.data[1]
                    ConExecute(action)
                    PlaySound(Sound({ Cue = "UI_MFD_Click", Bank = "Interface" }))
                end
            end,

            ---Called when item is activated with this component event handling
            ---@param self GSComponent
            ---@param item BaseGridItem
            ---@param action string[]
            Enable = function(self, item, action)
                self.name:Show()
                self.data = action
                self.name:SetText(self.data[2])
            end,

            ---Called when item is changing event handler
            ---@param self GSComponent
            ---@param item BaseGridItem
            Disable = function(self, item)
                self.name:Hide()
            end,

            ---Called when component is being destroyed
            ---@param self GSComponent
            Destroy = function(self)
                self.name:Destroy()
                self.name = nil
            end,
        },
    }


    ---@class DebugActions : ASelectionHandler
    local DebugActions = Class(ASelectionHandler)
    {
        Name = "Debug Actions",
        Description = "",
        Enabled = true,

        ---@param self DebugActions
        ---@param selection UserUnit[]
        ---@return string[]?
        Update = function(self, selection)
            if isCheatsEnabled and not SessionIsReplay() then
                return self.Actions
            end
        end,

        Actions =
        {
            "xab1401",
            "ual0301_ENGINEER",
            "url0301_ENGINEER",
            "uel0301_ENGINEER",
            "xsl0301_ENGINEER",
        },

        ---@class DAComponent : AItemComponent
        ---@field data string
        ---@field bg ReUI.UI.Controls.Bitmap
        ---@field name ReUI.UI.Controls.Text
        ComponentClass = Class(AItemComponent)
        {
            ---Called when component is bond to an item
            ---@param self DAComponent
            ---@param item BaseGridItem
            Create = function(self, item)
                self.bg = ReUI.UI.Controls.Bitmap(item)
                item.Layouter(self.bg)
                    :Fill(item)
                    :DisableHitTest()
                    :Hide()

                self.name = ReUI.UI.Controls.Text(item)
                self.name:SetFont("Arial", 12)
                self.name:SetText("Debug")
                item.Layouter(self.name)
                    :AtBottomCenterIn(item)
                    :Color("C3E600")
                    :DropShadow(true)
                    :DisableHitTest()
                    :Hide()
            end,


            ---Called when grid item receives an event
            ---@param self DAComponent
            ---@param item BaseGridItem
            ---@param event KeyEvent
            HandleEvent = function(self, item, event)
                if event.Type == "ButtonPress" or event.Type == "ButtonDClick" then
                    local action = self.data
                    local selection = GetSelectedUnits()
                    SelectUnits(nil)
                    local commandModeData = {
                        cheat = true,
                        name = action,
                        unit = action,
                        army = GetFocusArmy(),
                        count = 1,
                        vet = 0,
                        yaw = 0,
                        rand = 0,
                        selection = selection,
                    }
                    import("/lua/ui/game/commandmode.lua").StartCommandMode("build", commandModeData)
                    PlaySound(Sound({ Cue = "UI_MFD_Click", Bank = "Interface" }))
                end
            end,

            ---Called when item is activated with this component event handling
            ---@param self DAComponent
            ---@param item BaseGridItem
            ---@param action string
            Enable = function(self, item, action)
                self.bg:Show()
                self.name:Show()
                self.data = action
                self.bg:SetTexture(UIUtil.UIFile('/icons/units/' .. action .. '_icon.dds'--[[@as FileName]] , true))
            end,

            ---Called when item is changing event handler
            ---@param self DAComponent
            ---@param item BaseGridItem
            Disable = function(self, item)
                self.bg:Hide()
                self.name:Hide()
            end,

            ---Called when component is being destroyed
            ---@param self DAComponent
            Destroy = function(self)
                self.bg:Destroy()
                self.bg = nil
                self.name:Destroy()
                self.name = nil
            end,
        },
    }

    ReUI.ActionsPanel.AddExtension("DebugActions", DebugActions)
    ReUI.ActionsPanel.AddExtension("DebugActions", ConsoleActions)
end
