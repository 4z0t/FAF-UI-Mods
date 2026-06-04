ReUI.Require
{
    "ReUI.Core >= 1.6.0",
    "ReUI.Core.Events >= 1.0.0",
}

function Main()
    local Events = ReUI.Core.Events

    ---@class Test.A
    local A = ReUI.Core.Class()
    {
        MyEvent = Events.EventProperty(),
        MySafeEvent = Events.EventProperty(Events.SafeEvent),
    }

    ---@class Test.L
    local Listener = ReUI.Core.Class()
    {
        MyCallbackMethod = function(self, sender, event) end,
        MyCallbackError = function(self, sender, event) error "Hi" end,
    }

    LOG "ReUI.Tests"

    ---@type Test.A
    local a = A()
    local f = function(o, e) end

    ---@type Test.L
    local l = Listener()

    a.MyEvent:Add(f)
    a.MyEvent:Add { l, l.MyCallbackMethod }
    a.MySafeEvent:Add { l, l.MyCallbackError }

    pcall(function()
        LOG "1"
        a.MySafeEvent:Invoke(nil, {})
        a.MyEvent:Invoke(nil, {})
    end)

    a.MyEvent:Remove(f)
    a.MyEvent:Remove { l, l.MyCallbackMethod }
    a.MySafeEvent:Remove { l, l.MyCallbackError }

    pcall(function()
        LOG "2"
        a.MySafeEvent:Invoke(nil, {})
        a.MyEvent:Invoke(nil, {})
    end)


    safecall("Failed remove during invoke 1", function()
        ---@type ReUI.Core.Event
        local e = ReUI.Core.Events.Event('A')
        local function f1()
            e:Remove(f1)
        end

        e:Add(f1)

        local flag = false
        local function f2()
            flag = true
        end

        e:Add(f2)
        e:Invoke(nil, nil)
        assert(flag, "flag must be true")

    end)

    safecall("Failed remove during invoke 2", function()
        ---@type ReUI.Core.Event
        local e = ReUI.Core.Events.Event('A')


        local flag = false
        local function f2()
            flag = true
        end

        local function f1()
            e:Remove(f2)
        end

        e:Add(f1)
        e:Add(f2)

        e:Invoke(nil, nil)
        assert(flag, "flag must be true")

    end)
end
