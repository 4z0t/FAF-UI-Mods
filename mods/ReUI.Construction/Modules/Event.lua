---@class Event
---@field callbacks table
Event = ReUI.Core.Class()
{
    ---@param self Event
    __init = function(self)
        self.callbacks = {}
    end,

    ---@param self Event
    ---@param callback function
    Add = function(self, callback)
        table.insert(self.callbacks, callback)
    end,

    ---@param self Event
    ---@param key any
    ---@param callback function
    AddByKey = function(self, key, callback)
        self.callbacks[key] = callback
    end,

    ---@param self Event
    ---@param callback function
    Remove = function(self, callback)
        for i, v in ipairs(self.callbacks) do
            if v == callback then
                table.remove(self.callbacks, i)
                return
            end
        end
    end,

    ---@param self Event
    ---@param key any
    RemoveByKey = function(self, key)
        self.callbacks[key] = nil
    end,

    ---@param self Event
    ---@param sender any
    ---@param eventArgs any
    Invoke = function(self, sender, eventArgs)
        for i, v in self.callbacks do
            v(sender, eventArgs)
        end
    end,

    ---@param self Event
    Destroy = function(self)
        self.callbacks = nil
    end
}
