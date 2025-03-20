do
    local countColor = import("/mods/BetterColors/modules/Options.lua").countColor:Raw()
    local OldCommonLogic = CommonLogic
    function CommonLogic()
        OldCommonLogic()
        local CreateElement = controls.choices.CreateElement
        controls.choices.CreateElement = function()
            local btn = CreateElement()
            btn.Count:SetColor(countColor)
            return btn
        end
        local SetControlToType = controls.choices.SetControlToType
        controls.choices.SetControlToType = function(control, type)
            SetControlToType(control, type)
            if type == 'unitstack' and not table.empty(control.Data.units) then
                control.Count:SetColor(countColor)
            end
        end
    end
end
