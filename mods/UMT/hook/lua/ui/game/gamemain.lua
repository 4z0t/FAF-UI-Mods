do
    -- local OriginalCreateUI = CreateUI
    -- function CreateUI(isReplay)
    --     OriginalCreateUI(isReplay)
    --     import("/mods/UMT/modules/main.lua").Main(isReplay)
    -- end
    local modPath = '/mods/UMT/'
    local modules = modPath .. "modules/"
    local info    = import(modPath .. "mod_info.lua")
    _G.UMT        = {
        Info          = info,
        Version       = info.version,
        Layouter      = import(modules .. "Layouter.lua"),
        GlobalOptions = import(modules .. "GlobalOptions.lua"),
        OptionVar     = import(modules .. "OptionVar.lua"),

        Select     =
        {
            Hidden = function(callback)
                local CommandMode = import('/lua/ui/game/commandmode.lua')
                local current_command = CommandMode.GetCommandMode()
                local old_selection = GetSelectedUnits() or {}
                SetIgnoreSelection(true)
                callback()
                SelectUnits(old_selection)
                CommandMode.StartCommandMode(current_command[1], current_command[2])
                SetIgnoreSelection(false)
            end
        },
        Views      = {
            EscapeCover = import(modules .. "Views/EscapeCover.lua").EscapeCover,
            IScrollable = import(modules .. "Views/IScrollable.lua").IScrollable,
        },
        Containers = {
            Set = import(modules .. "Containers/Set.lua").Set,
            Array = import(modules .. "Containers/Array.lua").Array,
            Dict = import(modules .. "Containers/Dict.lua").Dict,
        }
    }
    UMT.Units     = import(modules .. "units.lua")

end
