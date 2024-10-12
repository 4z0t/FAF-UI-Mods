---Returns true if given name exists in the global table
---@param name string
---@return boolean
local function ExistsGlobal(name)
    return rawget(_G, name) ~= nil
end

if not ExistsGlobal "ClassSimple" then
    _G.ClassSimple = _G.Class
end

local LazyImport
if ExistsGlobal "lazyimport" then
    LOG "UMT: using lazyimport"
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
    Info         = import("/mods/UMT/mod_info.lua"),
    Version      = import("/mods/UMT/mod_info.lua").version,
    Controls     = LazyImport("/mods/UMT/modules/Controls/__Init__.lua"),
    Layouter     = LazyImport("/mods/UMT/modules/Layouter.lua"),
    OptionVar    = import("/mods/UMT/modules/OptionVar.lua"),
    Interfaces   = LazyImport("/mods/UMT/modules/Interfaces/__Init__.lua"),
    Views        = LazyImport("/mods/UMT/modules/Views/__Init__.lua"),
    Weak         = import("/mods/UMT/modules/WeakMeta.lua"),
    Animation    = LazyImport("/mods/UMT/modules/Animations/__Init__.lua"),
    Class        = import("/mods/UMT/modules/UIClass.lua").UIClass,
    Property     = import("/mods/UMT/modules/UIClass.lua").Property,
    Prevent      = import("/mods/UMT/modules/Prevent.lua"),
    Options      = LazyImport("/mods/UMT/modules/Options.lua"),
    Units        = LazyImport("/mods/UMT/modules/units.lua"),
    LazyImport   = LazyImport,
    ExistsGlobal = ExistsGlobal,
    LuaQ         = import("/mods/UMT/modules/LuaQ.lua"),
    ColorUtils   = import("/mods/UMT/modules/ColorUtils.lua"),
    Mods         = import("/mods/UMT/modules/Mods.lua")
}
