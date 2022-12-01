function Main(isReplay)
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
    end)
    if not a then return LOG(b) end
end
