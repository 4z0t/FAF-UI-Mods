function Main(isReplay)
    _G.UMT = {
        Info          = import("../mod_info.lua"),
        Version       = import("../mod_info.lua").version,
        Layouter      = import("Layouter.lua"),
        GlobalOptions = import("GlobalOptions.lua"),
        OptionVar     = import("OptionVar.lua"),
        Units         = import("units.lua"),
        Select        = import("select.lua"),
        Views         = {
            EscapeCover = import("Views/EscapeCover.lua").EscapeCover,
            IScrollable = import("Views/IScrollable.lua").IScrollable,
        },
        Containers    = {
            Set = import("Containers/Set.lua").Set,
            Array = import("Containers/Array.lua").Array,
            Dict = import("Containers/Dict.lua").Dict,
        }
    }
end
