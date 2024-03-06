local ipairs = ipairs

local ISelectionHandler = import("/mods/AGP/modules/ISelectionHandler.lua").ISelectionHandler
local IItemComponent = import("/mods/AGP/modules/IItemComponent.lua").IItemComponent
local UIUtil = import("/lua/ui/uiutil.lua")

local LuaQ = UMT.LuaQ
local sessionInfo = SessionGetScenarioInfo()
local isCheatsEnabled = sessionInfo.Options.CheatsEnabled

---@class DebugActions : ISelectionHandler
DebugActions = Class(ISelectionHandler)
{
    Name = "Debug Actions",
    Description = "",
    Enabled = true,
    ---@param self DebugActions
    ---@param selection UserUnit[]
    ---@return any
    OnSelectionChanged = function(self, selection)
        if isCheatsEnabled then
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

    ---@class DAComponent : IItemComponent
    ---@field data FactoryTemplateData
    ---@field bg UMT.Bitmap
    ---@field name UMT.Text
    ComponentClass = Class(IItemComponent)
    {
        ---Called when component is bond to an item
        ---@param self DAComponent
        ---@param item Item
        Create = function(self, item)
            self.bg = UMT.Controls.Bitmap(item)
            item.Layouter(self.bg)
                :Fill(item)
                :DisableHitTest()
                :Hide()

            self.name = UMT.Controls.Text(item)
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
        ---@param item Item
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
        ---@param item Item
        Enable = function(self, item)
            self.bg:Show()
            self.name:Show()
        end,

        ---@param self DAComponent
        ---@param action FactoryTemplateData
        SetAction = function(self, action)
            self.data = action
            self.bg:SetTexture(UIUtil.UIFile('/icons/units/' .. action .. '_icon.dds', true))
        end,

        ---Called when item is changing event handler
        ---@param self DAComponent
        ---@param item Item
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
