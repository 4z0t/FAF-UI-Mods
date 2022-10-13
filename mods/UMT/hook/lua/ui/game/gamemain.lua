_G.UMT               = {
    Info       = import("/mods/UMT/mod_info.lua"),
    Version    = import("/mods/UMT/mod_info.lua").version,
    Layouter   = import("/mods/UMT/modules/Layouter.lua"),
    OptionVar  = import("/mods/UMT/modules/OptionVar.lua"),
    Select     = {
        ---Performs hidden unit selection callback
        ---@param callback fun()
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
        EscapeCover = import("/mods/UMT/modules/Views/EscapeCover.lua").EscapeCover,
        StaticScrollable = import("/mods/UMT/modules/Views/StaticScrollable.lua").StaticScrollable,
        DynamicScrollable = import("/mods/UMT/modules/Views/DynamicScrollable.lua").DynamicScrollable,
    },
    WeakMeta   = {
        Key = { __mode = 'k' },
        Value = { __mode = 'v' },
        KeyValue = { __mode = 'kv' },
    },
    Containers = {
        Set = import("/mods/UMT/modules/Containers/Set.lua").Set,
        Array = import("/mods/UMT/modules/Containers/Array.lua").Array,
        Dict = import("/mods/UMT/modules/Containers/Dict.lua").Dict,
    }
}
_G.UMT.Units         = import("/mods/UMT/modules/units.lua")
_G.UMT.GlobalOptions = import("/mods/UMT/modules/GlobalOptions.lua")
