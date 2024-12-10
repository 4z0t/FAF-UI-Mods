function TestUIClass()
    local a, b = pcall(function()
        A = UMT.Class
        {
            A = function(self)
                LOG("Normal method")
            end,

            B = UMT.Property {
                get = function(self)
                    LOG("A get method")
                end,
                set = function(self, value)
                    LOG("A set method " .. value)
                end
            },

            E = UMT.Property {
                get = function(self)
                    return self._f
                end,
                set = function(self, value)
                    self._f = value
                end
            }
        }

        C = UMT.Class
        {
            D = UMT.Property {
                get = function(self)
                    LOG("C get method")
                end,
                set = function(self, value)
                    LOG("C set method " .. value)
                end
            }
        }

        B = UMT.Class(A, C)
        {

            A = function(self)
                A.A(self)
                LOG("B second call")
            end,

            C = UMT.Property {
                get = function(self)
                    LOG("B get method")
                end,
                set = function(self, value)
                    LOG("B set method " .. value)
                end
            },
        }
        local aa = A()
        aa:A()
        LOG(aa.B)
        aa.B = 5

        local bb = B()
        bb:A()
        LOG(bb.B)
        bb.B = 5
        LOG(bb.C)
        bb.C = 4
        LOG(bb.D)
        bb.D = 4

        bb.E = function(self)
            LOG("E call with self: " .. tostring(self))
        end
        bb:E()
        bb.E()
    end)
    if not a then return LOG(b) end
end

function TestLuaQ()
    local LuaQ = UMT.LuaQ
    local t = { 1, 2, 3, 4, 5 }
        | LuaQ.foreach(LOG)
        | LuaQ.where(function(v) return v > 3 end)
        | LuaQ.foreach(LOG)
        | LuaQ.sum
    LOG(t)

    local m = { 1, 2, 3, 4, 5 }
        | LuaQ.where(function(v) return v & 1 == 1 end)
        | LuaQ.reduce(function(val, _, v) return v * val end, 1)
    LOG(m)
end

function TestOptions()

    local OptionVar = UMT.OptionVar.Create
    local options = {
        strings = OptionVar("TEST", "strings", "First"),
        edit = OptionVar("TEST", "edit", "default"),
    }

    options.edit.OnChange = function(var)
        LOG(var())
    end
    UMT.Options.AddOptions("Test", "Test",
        {
            UMT.Options.Strings("Strings selector", { "First", "Second", "Third", "Fourth", "Fifth", "Sixth", "Seventh" }
                , options.strings),
            UMT.Options.TextEdit("text edit", options.edit, 20)
        })
end

function TestFunctional()

    local Fun = UMT.Functional.Functors

    local uniqueSelector = Fun.pairs
        | Fun.where(function(v) return v > 3 end)
        | Fun.select(function(v) return v * v end)
        | Fun.distinct
        | Fun.select(function(v) return v / 2 end)

    local t = { 1, 2, 3, 4, 5, 8, 2, 3, 4, 6, 5, 5, }
    local nt = t | uniqueSelector
    reprsl(nt)
    for k, v in uniqueSelector(t) do
        LOG(k, v)
    end

    local numbers = Fun.range(1, 100)
        | Fun.select(function(v) return v * v end)



    reprsl({} | numbers)

    for k, v in numbers() do
        LOG(v)
        if v > 500 then
            break
        end
    end
    local GetGameTimeSeconds = GetSystemTimeSeconds
    local function TimeIt(f, n)
        local start = GetGameTimeSeconds()
        for i = 1, n do
            f()
        end
        return GetGameTimeSeconds() - start
    end

    local MathMod = math.mod
    local function IsPrime(n)
        if (n <= 1) then
            return false
        end
        for i = 2, n - 1 do
            if MathMod(n, i) == 0 then
                return false
            end
        end

        return true
    end

    local sumInFirst100_000OfPrimes = Fun.range(1, 1000)
        | Fun.where(IsPrime)
        | Fun.sum
    local n = 1000
    function sp1000()
        local s = 0
        for i = 1, 1000 do
            if IsPrime(i) then
                s = s + i
            end
        end
        return s
    end
    LOG(TimeIt(sp1000, n))
    LOG(TimeIt(sumInFirst100_000OfPrimes, n))
    LOG(sp1000())
    LOG(sumInFirst100_000OfPrimes())
    -- local sel = Fun.pairsIterator
    --     | Fun.where(function(v) return v > 3 end)
    --     | Fun.select(function(v) return v * v end)

    -- local isel = Fun.ipairsIterator
    --     | Fun.where(function(v) return v > 3 end)
    --     | Fun.select(function(v) return v * v end)
    --     | Fun.toIterator


    -- local irsel = Fun.reversedIpairsIterator
    --     | Fun.where(function(v) return v > 3 end)
    --     | Fun.select(function(v) return v * v end)
    --     | Fun.toIterator

    -- local t = { 1, 2, 3, 4, 5, a = 6, b = 7 }

    -- local minV = sel | Fun.min
    -- local maxV = sel | Fun.max

    -- LOG(t | minV)
    -- LOG(t | maxV)

    -- for k, v in isel(t) do
    --     LOG(k, v)
    -- end

    -- for k, v in irsel(t) do
    --     LOG(k, v)
    -- end




end

function Main(isReplay)
    safecall("UMT.Test error:", function()

        -- TestUIClass()
        -- TestLuaQ()
        -- TestOptions()
        TestFunctional()
    end)
end

function __moduleinfo.OnReload()
    Main()
end
