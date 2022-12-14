local function ExistsGlobal(name)
    return rawget(_G, name) ~= nil
end

local LazyImport
if ExistsGlobal "lazyimport" then
    LOG("UMT: using lazyimport")
    LazyImport = lazyimport
else
    local LazyImportMetaTable = {
        __index = function(tbl, key)
            if not tbl.__module then
                tbl.__module = tbl.__import(tbl.__name);
            end
            return tbl.__module[key]
        end,

        __newindex = function(tbl, key, value)
            if not tbl.__module then
                error "Attempt to set new index on not initialized module"
            end
            tbl.__module[key] = value
        end
    }

    ---Creates a new lazy import object
    ---@param name string
    ---@param importFunc (fun(path: string):Module)?
    ---@return Module
    LazyImport = function(name, importFunc)
        local tbl = {
            __name = name,
            __import = importFunc or _G.import,
            __module = false,
        }
        return setmetatable(tbl, LazyImportMetaTable)
    end
end


_G.UMT = {
    Info       = import("/mods/UMT/mod_info.lua"),
    Version    = import("/mods/UMT/mod_info.lua").version,
    Layouter   = import("/mods/UMT/modules/Layouter.lua"),
    OptionVar  = import("/mods/UMT/modules/OptionVar.lua"),
    Select     = LazyImport("/mods/UMT/modules/select.lua"),
    Views      = {
        EscapeCover = import("/mods/UMT/modules/Views/EscapeCover.lua").EscapeCover,
        StaticScrollable = import("/mods/UMT/modules/Views/StaticScrollable.lua").StaticScrollable,
        DynamicScrollable = import("/mods/UMT/modules/Views/DynamicScrollable.lua").DynamicScrollable,
    },
    Weak       = import("/mods/UMT/modules/WeakMeta.lua"),
    Containers = {
        Set = import("/mods/UMT/modules/Containers/Set.lua").Set,
        Array = import("/mods/UMT/modules/Containers/Array.lua").Array,
        Dict = import("/mods/UMT/modules/Containers/Dict.lua").Dict,
    },
    ---@type fa-class
    Class      = import("/mods/UMT/modules/UIClass.lua").UIClass,
    Property   = import("/mods/UMT/modules/UIClass.lua").Property,
    Prevent    = import("/mods/UMT/modules/Prevent.lua"),
    Options    = LazyImport("/mods/UMT/modules/Options.lua"),
    Units      = LazyImport("/mods/UMT/modules/units.lua"),
    LazyImport = LazyImport,
    ExistsGlobal = ExistsGlobal
}

_G.UMT = UMT.Prevent.EditOf(_G.UMT)
