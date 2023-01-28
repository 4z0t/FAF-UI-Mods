local mods = {}

function Load(isReplay)
    for i, mod in mods do
        local files = DiskFindFiles("/mods/" .. mod .. "/", 'Main.lua')
        for _, file in files do
            LOG("UMT: Loading file " .. file)
            import(file).Main(isReplay)
        end
    end
end

---Adds mod to be loaded during start of the game
---@param name string # mod folder name
function Add(name)
    table.insert(mods, name)
end
