---@class MenuItem
---@field action string
---@field label string
---@field tooltip string
---@field func fun()

---@param item MenuItem
function AddToMenu(item)
    ---@diagnostic disable-next-line:undefined-global
    for _, t in menus.main do
        table.insert(t, item)
    end
    ---@diagnostic disable-next-line:undefined-global
    actions[item.action] = item.func
end
