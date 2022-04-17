local From = import('linq.lua').from
local Range = import('linq.lua').range

function main()
    local a, b = pcall(function()
        local r = Range(1, 10):Foreach(function(k, v)
            print(v)
        end):Dump()
        r:RemoveByValue(4):Dump()
        r.k = 4

    end)
    LOG(a)
    LOG(b)

end
