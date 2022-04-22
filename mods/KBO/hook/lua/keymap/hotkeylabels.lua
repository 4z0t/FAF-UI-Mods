function ResetIdRelations()
    local idRelations, upgradeKey, orderKeys = getKeyTables()
    construction.setIdRelations(idRelations, upgradeKey)
end