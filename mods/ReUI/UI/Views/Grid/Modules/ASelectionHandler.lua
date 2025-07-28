---@diagnostic disable-next-line:different-requires
local AItemComponent = import("AItemComponent.lua").AItemComponent

---Abstract class for Selection handler
---@class ASelectionHandler
---@field Name string
---@field Description string
---@field Enabled boolean
ASelectionHandler = Class()
{
    Enabled = false,

    ---@generic T
    ---@param self ASelectionHandler
    ---@param owner T
    __init = function(self, owner)
        self:OnInit(owner)
    end,

    ---@generic T
    ---@param self ASelectionHandler
    ---@param owner T
    OnInit = function(self, owner)
    end,

    ---@param self ASelectionHandler
    ---@param context any
    ---@return string[]? #actions
    ---@return any #context
    Update = function(self, context)
    end,

    ---@param self ASelectionHandler
    Destroy = function(self)
        self:OnDestroy()
    end,

    ---@param self ASelectionHandler
    OnDestroy = function(self)
    end,

    ---@type AItemComponent
    ComponentClass = AItemComponent,
}
