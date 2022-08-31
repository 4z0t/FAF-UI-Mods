local shadowOrders = import('/lua/spreadattack.lua').ShadowOrders


function Move(units, position)
    for _, unit in units do
        local id = unit:GetEntityId()
        local orders = shadowOrders[id]
        local newOrder = {
            CommandType = "Move",
            Position = position
        }
        table.insert(orders, newOrder)
        SimCallback({
            Func = "GiveOrders",
            Args = {
                unit_orders = orders,
                unit_id     = id,
                From        = GetFocusArmy()
            }
        }, false)
    end

end

function Attack(units, position)

end

function Stop(units)

end

function SetTargetPriority(units)

end
