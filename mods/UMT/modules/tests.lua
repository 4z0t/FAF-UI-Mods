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

local A = UIClass
{
    A = function(self)
        LOG("called A")
    end,

    B = Property {
        set = function(self, value)
            LOG("Setting new value " .. value)
        end,
        get = function(self)
            return "Hello"
        end
    }
}



local B = UIClass(A)
{
    C = Property {
        set = function(self, value)
            LOG("called C" .. value)
        end,
        get = function(self)
            return "CCCCCC"
        end
    }
}



function Main()
    local ok, a2 = pcall(function()

        LOG("--------------------------")
        local a = B()
        LOG(a.B)
        a.B = 4
        LOG(a.B)
        a:A()
        LOG(a.C)
        a.C = 4
        LOG(a.C)
        LOG(a.d)
        LOG("--------------------------")
    end)
    if not ok then
        LOG(debug.traceback(a2))
    end
end
