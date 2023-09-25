do
    --overwriting existing function with same functionality
    local oldGenerateHotbuildModifiers = GenerateHotbuildModifiers
    function GenerateHotbuildModifiers()
        local modifiers = oldGenerateHotbuildModifiers()
        local keyDetails = GetKeyMappingDetails()

        for key, info in keyDetails do
            local cat = info.action["category"]
            if cat == 'HotBuild Overhaul' then
                if key ~= nil then
                    local shiftModKey = "Shift-" .. key
                    local altModKey = "Alt-" .. key
                    local shiftModBinding = keyDetails[shiftModKey]
                    local altModBinding = keyDetails[altModKey]
                    if not shiftModBinding and not altModBinding then
                        modifiers[shiftModKey] = info.action
                        modifiers[altModKey] = info.action
                    elseif not shiftModBinding then
                        modifiers[shiftModKey] = info.action
                        WARN('Hotbuild key ' ..
                            altModKey ..
                            ' is already bound to action "' ..
                            altModBinding.name .. '" under "' .. altModBinding.category .. '" category')
                    elseif not altModBinding then
                        modifiers[altModKey] = info.action
                        WARN('Hotbuild key ' ..
                            shiftModKey ..
                            ' is already bound to action "' ..
                            shiftModBinding.name .. '" under "' .. shiftModBinding.category .. '" category')
                    else
                        WARN('Hotbuild key ' ..
                            shiftModKey ..
                            ' is already bound to action "' ..
                            shiftModBinding.name .. '" under "' .. shiftModBinding.category .. '" category')
                        WARN('Hotbuild key ' ..
                            altModKey ..
                            ' is already bound to action "' ..
                            altModBinding.name .. '" under "' .. altModBinding.category .. '" category')
                    end
                end
            end
        end
        return modifiers
    end
end
