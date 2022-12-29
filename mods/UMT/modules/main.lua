local LuaQ = import("LuaQ.lua")

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
            }
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
    end)
    if not a then return LOG(b) end
end

function TestLuaQ()
    local t = { 1, 2, 3, 4, 5 }
        | LuaQ.foreach(LOG)
        | LuaQ.where(function(_, v) return v > 3 end)
        | LuaQ.foreach(LOG)
        | LuaQ.sum
    LOG(t)


    local m = { 1, 2, 3, 4, 5 }
        | LuaQ.where(function(_, v) return v & 1 == 1 end)
        | LuaQ.reduce(function(val, _, v) return v * val end, 1)
    LOG(m)


end

function Main(isReplay)
    --TestUIClass()
    TestLuaQ()
end

function __moduleinfo.OnReload()
    Main()
end

Main()
