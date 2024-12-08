do
    local _ReceiveChatFromSim = ReceiveChatFromSim
    function ReceiveChatFromSim(sender, msg)
        local originalNames = GetOriginalNames()
        local armiesTable = GetArmiesTable()
        local i = table.find(originalNames, sender)
        local changedName = armiesTable.armiesTable[i].nickname
        local i = table.find(originalNames, msg.from)
        msg.from = armiesTable.armiesTable[i].nickname or "unknown"


        for i, name in originalNames do
            local _start, _end = string.find(msg.text:lower(), name:lower())
            if _start then
                local replaceName = armiesTable.armiesTable[i].nickname or "unknown"
                msg.text = string.sub(msg.text, 1, _start - 1) .. replaceName .. string.sub(msg.text, _end + 1)
                break
            end
        end
        return _ReceiveChatFromSim(changedName, msg)
    end
end
