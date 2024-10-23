do
    local _ReceiveChatFromSim = ReceiveChatFromSim
    function ReceiveChatFromSim(sender, msg)
        local originalNames = GetOriginalNames()
        local armiesTable = GetArmiesTable()
        local i = table.find(originalNames, sender)
        local changedName = armiesTable.armiesTable[i].nickname
        local i = table.find(originalNames, msg.from)
        msg.from = armiesTable.armiesTable[i].nickname


        local found = false
        for _, name in originalNames do

            if string.find(msg.text:lower(), name:lower()) then
                found = true
                break
            end
        end
        if found then
            return
        end
        return _ReceiveChatFromSim(changedName, msg)
    end
end
