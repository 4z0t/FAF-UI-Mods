local LazyVar = import("/lua/lazyvar.lua").Create

---@class ReUI.Options.ReactiveOption
---@field _ref ReUI.Options.OptionRef
---@field _var LazyVar
---@field _prev any
ReactiveOption = ReUI.Core.Class()
{
    OnChanged = ReUI.Core.Events.EventProperty(),

    OnSaved = ReUI.Core.Events.EventProperty(),

    Value = ReUI.Core.Property
    {
        ---@param self ReUI.Options.ReactiveOption
        get = function(self)
            return self:Get()
        end,

        ---@param self ReUI.Options.ReactiveOption
        set = function(self, value)
            self:Set(value)
        end
    } --[[@as any]] ,

    IsChanged = ReUI.Core.Property
    {
        ---@param self ReUI.Options.ReactiveOption
        get = function(self)
            return self._prev ~= nil
        end,
    } --[[@as boolean]] ,

    Name = ReUI.Core.Property
    {
        ---@param self ReUI.Options.ReactiveOption
        get = function(self)
            return self._ref:GetPath(2)
        end,
    } --[[@as string]] ,

    ---@param self ReUI.Options.ReactiveOption
    ---@param ref ReUI.Options.OptionRef
    ---@param default any
    __init = function(self, ref, default)
        self._ref = ref
        local val = self._ref:Get(default)

        self._var = LazyVar(val)
        self._prev = nil
    end,

    ---@param self ReUI.Options.ReactiveOption
    ---@return LazyVar
    Raw = function(self)
        return self._var
    end,

    ---@param self ReUI.Options.ReactiveOption
    ---@return any
    Get = function(self)
        return self._var()
    end,

    ---@param self ReUI.Options.ReactiveOption
    ---@return any
    Prev = function(self)
        return self._prev
    end,

    ---@param self ReUI.Options.ReactiveOption
    ---@param value any
    Set = function(self, value)
        if self._prev == nil then
            self._prev = self:Get()
        end

        self._var:Set(value)
        self.OnChanged:Invoke(self, value)
    end,

    ---@param self ReUI.Options.ReactiveOption
    Restore = function(self)
        if self._prev ~= nil then
            self:Set(self._prev)
            self._prev = nil
        end
    end,

    ---@param self ReUI.Options.ReactiveOption
    Save = function(self)
        local value = self:Get()

        self._ref:Set(value)

        self.OnSaved:Invoke(self, value)
        self._prev = nil
    end,

    ---@param self ReUI.Options.ReactiveOption
    Destroy = function(self)
        self.OnChanged = nil
        self.OnSaved = nil
        self._prev = nil
        self._var:Destroy()
        self._var = nil
        self._ref = nil
    end,
}

---@class DeprecatedOption : ReUI.Options.ReactiveOption
---@field _onChange fun(opt: DeprecatedOption)
DeprecatedOption = ReUI.Core.Class(ReactiveOption)
{
    ---@param self DeprecatedOption
    ---@return any
    __call = function(self)
        WARN(("ReUI.Options: [%s] call operator is deprecated, use '.Value' or ':Get()'"):format(self.Name))
        return self:Get()
    end,

    ---@deprecated use `OnChanged` event to observe when the value of the option changes and get current value with `Value` property
    ---@param self DeprecatedOption
    ---@param f fun(opt: DeprecatedOption)
    Bind = function(self, f)
        WARN(("ReUI.Options: [%s] ':Bind()' is deprecated, use 'OnChanged' event"):format(self.Name))
        self.OnChange = f
        f(self)
    end,

    ---@deprecated use `OnChanged` event to observe when the value of the option changes and get current value with `Value` property
    OnChange = ReUI.Core.Property
    {
        ---@param self DeprecatedOption
        get = function(self)
            WARN(("ReUI.Options: [%s] '.OnChange' is deprecated, use 'OnChanged' event"):format(self.Name))
            return self._onChange
        end,

        ---@param self DeprecatedOption
        set = function(self, value)
            WARN(("ReUI.Options: [%s] '.OnChange' is deprecated, use 'OnChanged' event"):format(self.Name))

            local prevOnChange = self._onChange
            if prevOnChange then
                self.OnChanged:Remove(prevOnChange)
            end
            self.OnChanged:Add(value)
            self._onChange = value
        end
    } --[[@as fun(opt: DeprecatedOption)]] ,
}
