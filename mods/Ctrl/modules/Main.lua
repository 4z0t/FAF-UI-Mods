local IsKeyDown = IsKeyDown
local ForkThread = ForkThread

local CM = import("/lua/ui/game/commandmode.lua")

local function ResetMove()
    ConExecute 'StartCommandMode order RULEUCC_Move'
end

---@param command CommandModeData
---@return boolean
local function IsMoveCommand(command)
    return command and command.name == "RULEUCC_Move"
end

local useCtrlMove
local useCtrlCopy

---@param commandMode CommandMode
---@param commandModeData CommandModeData
function OnCommandEnded(commandMode, commandModeData)
    if not useCtrlMove or not IsKeyDown("Control") then return end

    if IsMoveCommand(commandModeData) then
        ForkThread(ResetMove)
        return
    end
end

local CommandMode = import('/lua/ui/game/commandmode.lua')
local prefixes = {
    ["AEON"] = { "uab", "xab", "dab", "zab" },
    ["UEF"] = { "ueb", "xeb", "deb", "zeb" },
    ["CYBRAN"] = { "urb", "xrb", "drb", "zrb" },
    ["SERAPHIM"] = { "xsb", "usb", "dsb", "zsb" }
}

local function CopyBuilding()
    local info = GetRolloverInfo()
    if not info or info.blueprintId == 'unknown' then
        return false
    end

    local selection = GetSelectedUnits()
    if not selection then
        return false
    end

    local bp = info.blueprintId
    local availableOrders, availableToggles, buildableCategories = GetUnitCommandData(selection)

    local buildable = EntityCategoryGetUnitList(buildableCategories)

    if table.empty(buildable) then
        return false
    end

    local currentFaction = string.upper(selection[1]:GetBlueprint().General.FactionName)
    for i, prefix in prefixes[currentFaction] do
        local nbp = string.gsub(bp, "(%a+)(%d+)", prefix .. "%2")
        if table.find(buildable, nbp) then
            ClearBuildTemplates()
            CommandMode.StartCommandMode("build", {
                name = nbp
            })
            return true
        end
    end

    return false
end


function Main(isReplay)
    if isReplay then return end

    UMT.Options.Mods["Ctrl"].enableCtrlMove:Bind(function(opt)
        useCtrlMove = opt()
    end)

    UMT.Options.Mods["Ctrl"].enableCtrlCopy:Bind(function(opt)
        useCtrlCopy = opt()
    end)

    CM.AddEndBehavior(OnCommandEnded)

    local WorldView = import("/lua/ui/controls/worldview.lua").WorldView
    local _WorldViewHandleEvent = WorldView.HandleEvent
    WorldView.ReturnHitTest = false
    WorldView.WasCopying = false
    WorldView.HandleEvent = function(self, event)
        if useCtrlCopy then
            -- return our hit test back, since we dont wanna lose it,
            -- worldview is our primary way of controling units
            if self.ReturnHitTest then
                self.ReturnHitTest = false
                self:EnableHitTest()
            end
            -- this one is called very inconsistenly.
            -- when we hold and drag it is called in the end.
            -- but when we just press it, it is not called at all, so we have no idea wheter we clicked
            -- or dragged, but if we press during command mode again it is called xdddddd
            if event.Type == "ButtonRelease" and self.WasCopying then
                self.WasCopying = false
                return event.Modifiers.Ctrl
            end
            -- Check our primary stuff here.
            if event.Type == "ButtonPress" and event.Modifiers.Ctrl and event.Modifiers.Right then
                if CopyBuilding() then
                    self.WasCopying = true
                    self.ReturnHitTest = true
                    self:DisableHitTest()
                end
            end
        end
        return _WorldViewHandleEvent(self, event)
    end

end
