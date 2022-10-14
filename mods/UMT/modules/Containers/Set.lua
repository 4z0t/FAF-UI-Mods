---@type fun():Set
local _Set
---Class representing set of unique values
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
            for _, v in data do
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
        result:Extend(self)
        result:Extend(s)
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
    Equals = function(self, s)
        return self:IsSubSetOf(s) and s:IsSubSetOf(self)
    end,

    ---Extends set with elements of given set
    ---@param self Set
    ---@param s Set
    Extend = function(self, s)
        for v, _ in s._data do
            self:Add(v)
        end
    end,


    ---Exclude from set elements of given set
    ---@param self Set
    ---@param s Set
    Exclude = function(self, s)
        for v, _ in s._data do
            self:Remove(v)
        end
    end,

    ---Clears set
    ---@param self Set
    Clear = function(self)
        self._data = {}
    end,

    ---Returns size of set
    ---@param self Set
    ---@return integer
    Size = function(self)
        return table.getsize(self._data)
    end,

    ---Checks whether set is empty set
    ---@param self Set
    ---@return boolean
    IsEmpty = function(self)
        return table.empty(self._data)
    end,

    ---Returns copy of a set
    ---@param self Set
    ---@return Set
    Copy = function(self)
        local result = _Set()
        result:Extend(self)
        return result
    end

}
_Set = Set
