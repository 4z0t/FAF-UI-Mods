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
end
