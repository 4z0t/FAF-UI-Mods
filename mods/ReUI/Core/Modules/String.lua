function Main()
    local type = type
    local StringSub = string.sub
    local StringGSub = string.gsub
    local StringFind = string.find
    local TableInsert = table.insert


    ---@param sep string
    ---@return fun(s:string): (number, string)
    local function SplitIterNext(sep)
        local _end = 0
        ---@param s string
        ---@return number?
        ---@return string?
        return function(s)
            if _end == nil then
                return nil, nil
            end
            local _start
            local pos = _end + 1
            _start, _end = StringFind(s, sep, pos, true)
            return pos, StringSub(s, pos, _start and (_start - 1))
        end
    end

    ---@param s string
    ---@param sep string
    ---@return fun(str:string): (number, string)
    ---@return string
    local function SplitIter(s, sep)
        return SplitIterNext(sep), s
    end

    ---@param s string
    ---@param sep string
    ---@return string[]
    local function Split(s, sep)
        ---@type string[]
        local result = {}

        for _, split in SplitIter(s, sep or " ") do
            TableInsert(result, split)
        end

        return result
    end

    ---@param s string
    ---@return string
    local function TrimStart(s)
        local r = StringGSub(s, "^%s+", "")
        return r
    end

    ---@param s string
    ---@return string
    local function TrimEnd(s)
        local r = StringGSub(s, "%s+$", "")
        return r
    end

    ---@param s string
    ---@return string
    local function Trim(s)
        return TrimEnd(TrimStart(s))
    end

    ---@class ReUI.Core.String : ReUI.Module
    return {
        Trim      = Trim,
        TrimStart = TrimStart,
        TrimEnd   = TrimEnd,

        Split     = Split,
        SplitIter = SplitIter,
    }


end
