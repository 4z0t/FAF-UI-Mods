ReUI.Require
{
    "ReUI.Core >= 1.2.0",
    "ReUI.Options >= 1.0.0",
    "ReUI.UI >= 1.4.0"
}

function Main()
    local Dragger = import("/lua/maui/dragger.lua").Dragger
    local UIUtil = import("/lua/ui/uiutil.lua")
    local Prefs = import("/lua/user/prefs.lua")


    local options = ReUI.Options.Mods["ReUI.QoL"]

    --- Set multifunction collapse arrow to its center
    ReUI.Core.Hook("/lua/ui/game/layouts/multifunction_mini.lua", "SetLayout", function(field, module)
        return function()
            field()
            local controls = import("/lua/ui/game/multifunction.lua").controls
            ReUI.UI.FloorLayoutFor(controls.collapseArrow)
                :AtVerticalCenterIn(controls.bg)
        end
    end)

    if options.multifunctionPanelCollapsed() then
        ReUI.Core.Hook("/lua/ui/game/multifunction.lua", "InitialAnimation", function(field, module)
            return function()
                local controls = module.controls
                local savedParent = module.savedParent

                controls.bg.Left:Set(savedParent.Left() - controls.bg.Width() - 10)
                controls.collapseArrow:SetCheck(true, true)
                controls.bg:Hide()
            end
        end)
    end

    if options.movableMenuPanel() then

        local function SetPos(self, x)
            local f = self:GetRootFrame()
            ReUI.UI.FloorLayoutFor(self)
                :Left(function() return x + f.Left() - self.Width() * 0.5 end)
        end

        local function LoadPosition()
            return Prefs.GetFromCurrentProfile("MenuPanelPos")
        end

        local function SavePosition(x)
            Prefs.SetToCurrentProfile("MenuPanelPos", {
                left = x
            })
        end

        ReUI.Core.Hook("/lua/ui/game/tabs.lua", "CommonLogic", function(field, module)
            return function()
                field()
                module.controls.parent.HandleEvent = function(self, event)
                    if event.Type == "ButtonPress" and event.Modifiers.Middle then
                        local drag = Dragger()
                        local offX = event.MouseX - self.Left() - self.Width() * 0.5
                        drag.OnMove = function(dragself, x, y)
                            SetPos(self, x - offX)
                            GetCursor():SetTexture(UIUtil.GetCursor("W_E"))
                        end
                        drag.OnRelease = function(dragself, x, y)
                            SavePosition(x - offX)
                            GetCursor():Reset()
                            drag:Destroy()
                        end
                        PostDragger(self:GetRootFrame(), event.KeyCode, drag)
                        return true
                    end
                    return false
                end

            end
        end)

        ReUI.Core.Hook("/lua/ui/game/layouts/tabs_mini.lua", "SetLayout", function(field, module)
            return function()
                field()
                local controls = import("/lua/ui/game/tabs.lua").controls
                local panel = controls.parent

                local pos = LoadPosition()
                if pos then
                    SetPos(panel, pos.left)
                end
            end
        end)
    end
end
