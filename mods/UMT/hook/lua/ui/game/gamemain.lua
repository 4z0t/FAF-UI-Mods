_G.UMT       = {
    Info          = import("/mods/UMT/mod_info.lua"),
    Version       = import("/mods/UMT/mod_info.lua").version,
    Layouter      = import("/mods/UMT/modules/Layouter.lua"),
    GlobalOptions = import("/mods/UMT/modules/GlobalOptions.lua"),
    OptionVar     = import("/mods/UMT/modules/OptionVar.lua"),
    Select        = {
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
    Views         = {
        EscapeCover = import("/mods/UMT/modules/Views/EscapeCover.lua").EscapeCover,
        IScrollable = import("/mods/UMT/modules/Views/IScrollable.lua").IScrollable,
    },
    Containers    = {
        Set = import("/mods/UMT/modules/Containers/Set.lua").Set,
        Array = import("/mods/UMT/modules/Containers/Array.lua").Array,
        Dict = import("/mods/UMT/modules/Containers/Dict.lua").Dict,
    }
}
_G.UMT.Units = import("/mods/UMT/modules/units.lua")
