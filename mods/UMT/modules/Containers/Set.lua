---@type Set
local _Set
---@class Set
---@field _data table<any, boolean>
Set = ClassSimple
{
    ---Creates Set from given table
    ---@param self Set
    ---@param data table
    __init = function(self, data)
        self._data = {}
        if data then
            local d = self._data
            for k, v in data do
                d[v] = true
            end
        end
    end,

    ---Checks whether set contains value
    ---@param self Set
    ---@param value any
    ---@return boolean
    Contains = function(self, value)
        return self._data[value] ~= nil
    end,

    ---Creates array from Set
    ---@param self Set
    ---@return table
    ToArray = function(self)
        local arr = {}
        for v, _ in self._data do
            table.insert(arr, v)
        end
        return arr
    end,


    ---Returns intersections of two sets
    ---@param self Set
    ---@param s Set
    ---@return Set
    Intersect = function(self, s)
        local result = _Set()
        for v, _ in self._data do
            if s:Contains(v) then
                result:Add(v)
            end
        end
        return result
    end,

    ---Adds value to a set
    ---@param self Set
    ---@param value any
    Add = function(self, value)
        self._data[value] = true
    end,

    ---Removes value from a set
    ---@param self Set
    ---@param value any
    Remove = function(self, value)
        self._data[value] = nil
    end,

    ---Returns union of two sets
    ---@param self Set
    ---@param s Set
    ---@return Set
    Union = function(self, s)
        local result = _Set()
        for v, _ in self._data do
            result:Add(v)
        end
        for v, _ in s._data do
            result:Add(v)
        end
        return result
    end,

    ---Checks whether set is subset of given set
    ---@param self Set
    ---@param s Set
    ---@return boolean
    IsSubSetOf = function(self, s)
        for v, _ in self._data do
            if not s:Contains(v) then
                return false
            end
        end
        return true
    end,

    ---Checks equality of two sets
    ---@param self Set
    ---@param s Set
    ---@return boolean
    Equal = function(self, s)
        return self:IsSubSetOf(s) and s:IsSubSetOf(self)
    end,

    Extend = function(self, s)

    end,

    Exclude = function(self, s)

    end,

}
_Set = Set