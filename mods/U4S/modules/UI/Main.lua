---@class SimToUIData
---@field fileName FileName
---@field functionName string
---@field args table?


---callbacks sim request to specified function string link
---@param name string
---@param simData SimToUIData
local function Callback(name, simData)
    import(simData.fileName)[simData.functionName](simData.args, name)
end

---Processes sim passed data
---@param syncData table<string, SimToUIData>
function Process(syncData)
    for name, simData in syncData do
        Callback(name, simData)
    end
end