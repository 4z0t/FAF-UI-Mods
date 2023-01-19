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
    local c = LuaQ.From{ 1, 2, 3, 4, 5 }
    | LuaQ.where(function(v) return v & 1 == 1 end)

end

function TestOptions()

    local OptionVar = UMT.OptionVar.Create
    local options = {
        strings = OptionVar("TEST", "strings", "First")
    }


    UMT.Options.AddOptions("Test", "Test",
        {
            UMT.Options.Strings("Strings selector", { "First", "Second", "Third", "Fourth", "Fifth", "Sixth", "Seventh" }
                , options.strings)
        })
end

function Main(isReplay)
    TestUIClass()
    TestLuaQ()
    TestOptions()
end

function __moduleinfo.OnReload()
    Main()
end

Main()
