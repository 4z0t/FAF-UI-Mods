local _error = error
local _rawget = rawget
local _pcall = pcall
local _tonumber = tonumber
local StringSub = string.sub
local StringGSub = string.gsub
local StringFind = string.find
local TableInsert = table.insert
local setmetatable = setmetatable
local _assert = assert

---@class ReUI.Version
---@field major number
---@field minor number
---@field revision number


---@class ReUI.Module
---@field Version ReUI.Version
---@field Name string

---@alias CompareOperator
---| ">="
---| "<="
---| ">"
---| "<"
---| "=="
---| "="

local isReplay = false
local disposed = true
---@type table<string, ReUI.Module|"failed">
local loadedModules = nil
---@type ReUI.Module[]
local loadedModulesInOrder = nil
---@type table<string, boolean>
local modulesInProgress = nil


local VERSION_NUMBER_REGEX = '^(%d+)%.(%d+)%.(%d+)$'
---@param vs string
---@return ReUI.Version
local function ParseVersion(vs)
    local major = StringGSub(vs, VERSION_NUMBER_REGEX, '%1')
    local minor = StringGSub(vs, VERSION_NUMBER_REGEX, '%2')
    local revision = StringGSub(vs, VERSION_NUMBER_REGEX, '%3')
    return { major = _tonumber(major), minor = _tonumber(minor), revision = _tonumber(revision) }
end

local MARKER_VERSION = '^(%a[%a%.%d]*)=(%d+%.%d+%.%d+)$'
---@param s string
---@return string, ReUI.Version
local function ParseNameAndVersion(s)
    local name = StringGSub(s, MARKER_VERSION, '%1')
    local version = StringGSub(s, MARKER_VERSION, '%2')
    return name, ParseVersion(version)
end

---@param s string
---@return string[]
local function SplitName(s)
    local strings = {}
    local prev = 1
    while true do
        local _start, _end = StringFind(s, ".", prev, true)
        if _start then
            TableInsert(strings, StringSub(s, prev, _start - 1))
        else
            break
        end
        prev = _end + 1
    end
    TableInsert(strings, StringSub(s, prev))
    return strings
end

---@param moduleName string
---@return string[]
local function DemangleName(moduleName)
    local splitName = SplitName(moduleName)
    if table.empty(splitName) then
        _error("Name can't have 0 parts")
    end

    if splitName[1] == "ReUI" then
        table.remove(splitName, 1)
    end

    return splitName
end

---@param moduleName string
---@return FileName
---@return FileName
local function GetModulePath(moduleName)
    ---@type FileName
    ---@diagnostic disable-next-line:assign-type-mismatch
    local modulePath = ("/mods/ReUI.%s/"):format(moduleName)
    if not exists(modulePath .. "mod_info.lua") then
        ---@diagnostic disable-next-line:cast-local-type
        modulePath = ("/mods/%s/"):format(moduleName)
    end

    return modulePath .. "mod_info.lua", modulePath .. "Main.lua"
end

local ModuleMeta = {
    ---@param self ReUI.Module
    ---@param key any
    __index = function(self, key)
        _error(("ReUI.Core: attempt to get '%s' from module '%s', which doesn't exist")
            :format(tostring(key), _rawget(self, "Name") or "UNKNOWN"))
    end
}


---@param moduleName string
---@return ReUI.Module
local function LoadModule(moduleName)
    local modInfoPath, modMainPath = GetModulePath(moduleName)
    local moduleInfo = import(modInfoPath)
    local m = import(modMainPath)
    ---@type ReUI.Module
    local module = setmetatable(m.Main(isReplay) or {}, ModuleMeta)
    m.Main = nil

    module.Name = moduleName
    _, module.Version = ParseNameAndVersion(moduleInfo.ReUI)
    return module
end

---Returns whether v1 is equal to v2
---@param v1 ReUI.Version
---@param v2 ReUI.Version
---@return boolean
local function VersionEqual(v1, v2)
    return v1.major == v2.major
        and v1.minor == v2.minor
        and v1.revision == v2.revision
end

---Returns whether v1 is greater than v2
---@param v1 ReUI.Version
---@param v2 ReUI.Version
---@return boolean
local function VersionGreater(v1, v2)
    return v1.major > v2.major
        or v1.major == v2.major and v1.minor > v2.minor
        or v1.major == v2.major and v1.minor == v2.minor and v1.revision > v2.revision
end

---@param v1 ReUI.Version
---@param operator CompareOperator
---@param v2 ReUI.Version
---@return boolean
local function CheckVersion(v1, operator, v2)
    if operator == ">=" then
        return VersionEqual(v1, v2) or VersionGreater(v1, v2)
    elseif operator == "<=" then
        return VersionEqual(v1, v2) or VersionGreater(v2, v1)
    elseif operator == ">" then
        return VersionGreater(v1, v2)
    elseif operator == "<" then
        return VersionGreater(v2, v1)
    elseif operator == "==" or operator == "=" then
        return VersionEqual(v1, v2)
    else
        _error("Invalid operator " .. operator)
    end
end

---@param version ReUI.Version
---@return string
local function VersionToString(version)
    return ("%d.%d.%d"):format(version.major, version.minor, version.revision)
end

---@param parts string[]
---@param module ReUI.Module
local function AssignModule(parts, module)
    ---@diagnostic disable-next-line:undefined-field
    local data = ReUI.__data
    ---@diagnostic disable-next-line:deprecated
    local n = table.getn(parts)
    for i = 1, n do
        local part = parts[i]
        local t = _rawget(data, part)
        if i == n then
            if t then
                if t.Name then
                    _error("Attempt to override module " .. t.Name)
                end

                for k, v in t do
                    module[k] = v
                end
            end
            data[part] = module
        else
            data[part] = t or {}
            data = data[part]
        end
    end
end

---@param moduleName string
---@return ReUI.Module
local function TryLoadModule(moduleName)
    if modulesInProgress[moduleName] then
        _error(("Module '%s' is already loading. Is there circular dependency?"):format(moduleName))
    end

    modulesInProgress[moduleName] = true

    local ok, result = _pcall(LoadModule, moduleName)

    modulesInProgress[moduleName] = nil

    if not ok then
        loadedModules[moduleName] = "failed"
        _error(("Failed to load module '%s' due to following error:\n%s"):format(moduleName, result))
    end

    LOG(("ReUI: loaded module '%s':%s"):format(moduleName, VersionToString(result.Version)))

    loadedModules[moduleName] = result
    TableInsert(loadedModulesInOrder, result)
    local demangledName = DemangleName(moduleName)
    AssignModule(demangledName, result)
    return result
end

local VERSION_REGEX = '^(%a[%a%.%d]*)([><=]=?)(%d+%.%d+%.%d+)$'
---@param s string
---@return string # name
---@return CompareOperator
---@return ReUI.Version
local function MatchDependencyString(s)
    s = StringGSub(s, "%s+", "") -- remove spaces
    local start = string.find(s, VERSION_REGEX)
    _assert(start, ("Invalid dependency string '%s'!"):format(s))

    local moduleName = StringGSub(s, VERSION_REGEX, '%1')
    ---@type CompareOperator
    ---@diagnostic disable-next-line:assign-type-mismatch
    local op = StringGSub(s, VERSION_REGEX, '%2')
    local versionS = StringGSub(s, VERSION_REGEX, '%3')

    return moduleName, op, ParseVersion(versionS)
end

---@param deps string[]
function Require(deps)
    _assert(not disposed, "ReUI loader was disposed. Are you trying to require modules outside of creation of UI?")

    for _, dep in deps do
        local name, op, version = MatchDependencyString(dep)
        ---@type (ReUI.Module | "failed")?
        local module = loadedModules[name]
        if module == "failed" then
            _error(("Module '%s' failed to load previously"):format(name))
        end

        if not module then
            module = TryLoadModule(name)
        end

        if not module then
            _error(("Required module '%s' does not exist!"):format(name))
        end

        if not CheckVersion(module.Version, op, version) then
            _error(("Module '%s' doesn't match required version: current: %s, required: %s%s")
                :format(
                    name,
                    VersionToString(module.Version),
                    op,
                    VersionToString(version)
                )
            )
        end
    end
end

---@param marker string
---@return ReUI.Module
local function TryLoad(marker)
    _assert(not disposed, "ReUI loader was disposed. Are you trying to require modules outside of creation of UI?")

    marker = StringGSub(marker, "%s+", "")
    local name = StringGSub(marker, MARKER_VERSION, '%1')
    local module = loadedModules[name] or TryLoadModule(name)
    if module == "failed" then
        _error(("Module '%s' failed to load previously"):format(name))
    end
    ---@diagnostic disable-next-line:return-type-mismatch
    return module
end

function Load(marker)
    local ok, result = _pcall(TryLoad, marker)
    if not ok then
        WARN(result)
    end
end

function Init(_isReplay)
    isReplay = _isReplay
    disposed = false
    loadedModules = {}
    loadedModulesInOrder = {}
    modulesInProgress = {}
end

function Dispose()
    LOG "ReUI: Loaded modules:"
    for _, module in ipairs(loadedModulesInOrder) do
        LOG("\t", module.Name)
    end
    ---@diagnostic disable-next-line:cast-local-type
    loadedModules = nil
    ---@diagnostic disable-next-line:cast-local-type
    loadedModulesInOrder = nil
    ---@diagnostic disable-next-line:cast-local-type
    modulesInProgress = nil
    disposed = true
end
