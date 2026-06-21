function Main()
    local type = type
    local StringSub = string.sub
    local StringGSub = string.gsub
    local StringFind = string.find
    local TableInsert = table.insert



    ---@param s string
    ---@param sep string
    local function SplitIter(s, sep)
        local _end = 0
        return function(_s, i)
            if _end == nil then
                return nil, nil
            end
            local _start
            i = _end + 1
            _start, _end = StringFind(_s, sep, i, true)
            return i, StringSub(_s, i, _start and (_start - 1))
        end, s, 0
    end

    ---@param s string
    ---@param sep string
    ---@return string[]
    local function Split(s, sep)
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
