function IsIgnoredSelection()
    return ignoreSelection
end

do
    local _OnCommandIssued = OnCommandIssued
    function OnCommandIssued(command)
        _OnCommandIssued(command)

        if not command.Clear then return end

        import('/mods/GS/modules/Main.lua').OnCommandIssued(commandMode, modeData, command)
    end
end


do
    local templateData
    local _SetActiveBuildTemplate = SetActiveBuildTemplate
    local _ClearBuildTemplates = ClearBuildTemplates
    function _G.SetActiveBuildTemplate(template)
        templateData = template
        _SetActiveBuildTemplate(template)
    end

    function _G.GetActiveBuildTemplate()
        return templateData
    end

    function _G.ClearBuildTemplates()
        templateData = nil
        return _ClearBuildTemplates()
    end
end
