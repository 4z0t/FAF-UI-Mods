
local VDist3 = VDist3
local MATH_Lerp = MATH_Lerp
local function ComputeLen(curve)
    local l = 0
    local prev = nil
    for _, point in curve do
        if prev then
            l = l + VDist3(prev, point)
        end
        prev = point
    end
    return l
end

local lineMoveOrders = {
    ["Move"] = IssueMove,
    ["Attack"] = IssueAttack,
    ["Tactical"] = IssueTactical,
    ["Nuke"] = IssueNuke,
    ["AttackMove"] = IssueAggressiveMove,
}

Callbacks.LineMove = function(data, units)
    if not data.Curve or
        not data.Order or
        not units or
        not OkayToMessWithArmy(data.Army)
    then
        return
    end

    local curve = data.Curve
    local len = ComputeLen(curve)
    if len == 0 then return end
    if data.Clear then
        IssueClearCommands(units)
    end

    local issueOrder = lineMoveOrders[data.Order] or IssueMove

    local unitCount = table.getn(units)
    local pointsCount = table.getn(curve)

    local distBetween = len / (unitCount + 1)
    local currentSegmentLength = distBetween
    local curUnitPosition = 1

    local prevPoint = nil
    local i         = 1
    while i < pointsCount do
        local p1 = prevPoint or curve[i]
        local p2 = curve[i + 1]
        local dist = VDist3(p1, p2)
        if dist > currentSegmentLength then
            local s = currentSegmentLength / dist
            local unitPos = {
                MATH_Lerp(s, p1[1], p2[1]),
                MATH_Lerp(s, p1[2], p2[2]),
                MATH_Lerp(s, p1[3], p2[3]),
            }
            issueOrder({ units[curUnitPosition] }, unitPos)
            prevPoint = unitPos
            curUnitPosition = curUnitPosition + 1
            currentSegmentLength = distBetween
            if curUnitPosition > unitCount then
                break
            end
        else
            currentSegmentLength = currentSegmentLength - dist
            prevPoint = p2
            i = i + 1
        end
    end
end