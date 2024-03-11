local ipairs = ipairs

local ISelectionHandler = import("/mods/AGP/modules/ISelectionHandler.lua").ISelectionHandler
local IItemComponent = import("/mods/AGP/modules/IItemComponent.lua").IItemComponent
local UIUtil = import("/lua/ui/uiutil.lua")

local LuaQ = UMT.LuaQ
local sessionInfo = SessionGetScenarioInfo()
local isCheatsEnabled = sessionInfo.Options.CheatsEnabled == "true"

---@class AdjustGameSpeed : ISelectionHandler
AdjustGameSpeed = Class(ISelectionHandler)
{
    Name = "Game speed adjust",
    Description = "",
    Enabled = true,
    ---@param self AdjustGameSpeed
    ---@param selection UserUnit[]
    ---@return string[]?
    OnSelectionChanged = function(self, selection)
        if isCheatsEnabled and not SessionIsReplay() then
            return self.Actions
        end
    end,

    Actions =
    {
        { "WLD_DecreaseSimRate", "-" },
        { "WLD_IncreaseSimRate", "+" },
    },

    ---@class GSComponent : IItemComponent
    ---@field data string
    ---@field name UMT.Text
    ComponentClass = Class(IItemComponent)
    {
        ---Called when component is bond to an item
        ---@param self GSComponent
        ---@param item Item
        Create = function(self, item)
            self.name = UMT.Controls.Text(item)
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
        ---@param item Item
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
        ---@param item Item
        Enable = function(self, item)
            self.name:Show()
        end,

        ---@param self DAComponent
        ---@param action FactoryTemplateData
        SetAction = function(self, action)
            self.data = action
            self.name:SetText(self.data[2])
        end,

        ---Called when item is changing event handler
        ---@param self GSComponent
        ---@param item Item
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
