ReUI.Require
{
    "ReUI.Core >= 1.6.0"
}

function Main()
    local pcall = pcall
    local ipairs = ipairs
    local TableInsert = table.insert
    local TableRemove = table.remove
    local setmetatable = setmetatable
    local getmetatable = getmetatable
    local type = type
    local emptyMetaTable = getmetatable {}

    ---@return boolean
    local function IsSimpleTable(t)
        return getmetatable(t) == emptyMetaTable
    end

    ---@class EventMethodBind:function
    ---@field [1] any
    ---@field [2] fun(object:any, sender:any, event:any)
    local EventMethodBindMeta =
    {
        ---@param self EventMethodBind
        ---@param other EventMethodBind
        ---@return boolean
        __eq = function(self, other)
            return self[1] == other[1] and self[2] == other[2]
        end,

        ---@param self EventMethodBind
        ---@param sender any
        ---@param event any
        __call = function(self, sender, event)
            return self[2](self[1], sender, event)
        end
    }

    ---Binds object and method to be consumed by event
    ---@generic T
    ---@param object T
    ---@param method fun(object:T, sender:any, event:any)
    ---@return EventMethodBind
    local function Bind(object, method)
        if object == nil or method == nil then
            error("ReUI.Core.Events.Bind: expected object and method to be non-nil")
        end

        return setmetatable({ object, method }, EventMethodBindMeta)
    end

    ---@generic T
    ---@param v T
    ---@return T
    local function FilterEvent(v)
        local ty = type(v)
        if ty == "function" then
            return v
        end
        if ty == "table" then
            if not IsSimpleTable(v) then
                return v
            end
            if v[1] == nil or v[2] == nil then
                error("ReUI.Core.Events.Bind: expected object and method to be non-nil")
            end
            return setmetatable(v, EventMethodBindMeta)
        end
        error("Unsupported event type " .. ty)
    end

    ---@param callbacks function[]
    local function CopyCallbacks(callbacks)
        local t = {}
        for i, f in ipairs(callbacks) do
            t[i] = f
        end
        return t
    end

    ---@alias EventCallback fun(sender:any, eventArgs:any)

    ---@class ReUI.Core.Event
    ---@field _name string
    ---@field _needsCopy boolean
    ---@field _callbacks EventCallback[]
    local Event = ReUI.Core.Class()
    {
        ---@param self ReUI.Core.Event
        ---@param name? string
        __init = function(self, name)
            self._name = name or "unnamed"
            self._needsCopy = false
            self._callbacks = nil
        end,

        ---@generic F : function
        ---@param self ReUI.Core.Event
        ---@param callback F
        ---@return F
        Add = function(self, callback)
            callback = FilterEvent(callback)
            if self._callbacks == nil then
                self._callbacks = {}
            elseif self._needsCopy then
                self._callbacks = CopyCallbacks(self._callbacks)
                self._needsCopy = false
            end
            TableInsert(self._callbacks, callback)
            return callback
        end,

        ---@generic F : function
        ---@param self ReUI.Core.Event
        ---@param callback F
        ---@return boolean
        Remove = function(self, callback)
            if self._callbacks ~= nil then
                callback = FilterEvent(callback)
                for i, f in ipairs(self._callbacks) do
                    if f == callback then
                        if self._needsCopy then
                            self._callbacks = CopyCallbacks(self._callbacks)
                            self._needsCopy = false
                        end
                        TableRemove(self._callbacks, i)
                        return true
                    end
                end
            end
            return false
        end,

        ---@param self ReUI.Core.Event
        ---@param sender any
        ---@param eventArgs any
        Invoke = function(self, sender, eventArgs)
            local callbacks = self._callbacks
            if callbacks == nil then
                return
            end

            self._needsCopy = true

            for i, f in ipairs(callbacks) do
                f(sender, eventArgs)
            end

            self._needsCopy = false
        end,

        ---@param self ReUI.Core.Event
        Clear = function(self)
            self._callbacks = nil
        end
    }

    ---@class ReUI.Core.SafeEvent : ReUI.Core.Event
    local SafeEvent = ReUI.Core.Class(Event)
    {
        ---@param self ReUI.Core.SafeEvent
        ---@param sender any
        ---@param eventArgs any
        Invoke = function(self, sender, eventArgs)
            local callbacks = self._callbacks
            if callbacks == nil then
                return
            end

            self._needsCopy = true

            for i, f in ipairs(callbacks) do
                local ok, err = pcall(f, sender, eventArgs)
                if not ok then
                    WARN(("ReUI.Core.Event [%s]: %s"):format(self._name, err))
                end
            end

            self._needsCopy = false
        end,
    }

    ---@param self any
    ---@param value any
    ---@param key any
    local function SetEvent(self, value, key)
        if type(value) ~= "nil" then
            error(("ReUI.Core.Event [%s]: attempt to manually set event property."):format(key))
        end

        local field = "_event" .. key
        local event = self[field]

        if event == nil then
            return
        end

        event:Clear()
        self[field] = nil
    end

    ---Makes event property for ReUI.Core.Class
    ---@overload fun():ReUI.Core.Event
    ---@generic T : ReUI.Core.Event
    ---@param class T
    ---@return T
    local function EventProperty(class)
        class = class or Event
        return ReUI.Core.Property
        {
            get = function(self, key)
                local field = "_event" .. key
                local event = self[field]

                if event == nil then
                    event = class(key)
                    self[field] = event
                end

                return event
            end,

            set = SetEvent
        }
    end

    ---#region Lazy event

    ---@class EventProxy
    ---@field _key any
    ---@field _object any
    ---@field _class fun(name?:string):ReUI.Core.Event
    local EventProxy = ReUI.Core.Class()
    {
        ---@param self EventProxy
        ---@param object table
        ---@param key any
        Proxy = function(self, object, key, class)
            self._object = object
            self._key = key
            self._class = class
            return self
        end,

        ---@param self EventProxy
        ---@param callback function
        ---@return function
        Add = function(self, callback)
            local object = self._object
            local key = self._key
            local class = self._class
            self:Clear()

            if key == nil or object == nil or class == nil then
                error "EventProxy:Add : attempt to proxy after clear."
            end

            local event = class(key)
            object["_event" .. key] = event

            return event:Add(callback)
        end,

        ---@param self EventProxy
        ---@param callback function
        Remove = function(self, callback)
            self:Clear()
        end,

        ---@param self EventProxy
        ---@param sender any
        ---@param eventArgs any
        Invoke = function(self, sender, eventArgs)
            self:Clear()
        end,

        ---@param self EventProxy
        Clear = function(self)
            self._object = nil
            self._key = nil
            self._class = nil
        end,
    }

    ---@type EventProxy
    local eventProxy = EventProxy()

    local function GetEvent(self, key, class)
        local field = "_event" .. key
        local event = self[field]
        if event then
            return event
        end

        return eventProxy:Proxy(self, key, class)
    end

    ---Makes lazy event property for ReUI.Core.Class
    ---Lazy event is instantiated when a listener is added
    ---@param class ReUI.Core.Event?
    ---@return ReUI.Core.Event
    local function LazyEventProperty(class)
        class = class or Event
        return ReUI.Core.Property
        {
            get = function(self, key)
                return GetEvent(self, key, class)
            end,

            set = SetEvent
        }
    end

    ---#endregion

    ---@class ReUI.Core.Events : ReUI.Module
    return {
        Bind = Bind,
        EventProperty = EventProperty,
        -- LazyEventProperty = LazyEventProperty,
        Event = Event,
        SafeEvent = SafeEvent,
    }
end
