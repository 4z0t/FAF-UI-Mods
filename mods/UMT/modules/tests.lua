local From = import("linq.lua").from
local Range = import("linq.lua").range

function main()
    local a, b
    a, b = pcall(function()
        local r = Range(1, 10):Foreach(function(k, v)
            print(v)
        end):Dump()
        r:RemoveByValue(4):Dump()
        r.k = 4

    end)
    LOG(a)
    WARN(b)

    a, b = pcall(function()
        local c = require.lua.maui.bitmap()
        local d = require._.modules.linq()
        local e = require.a()

    end)
    LOG(a)
    WARN(b)

end
