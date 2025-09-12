local _error = error
local _rawget = rawget
local _pcall = pcall
local _tonumber = tonumber
local StringFormat = string.format
local StringSub = string.sub
local StringGSub = string.gsub
local StringFind = string.find
local TableInsert = table.insert
local setmetatable = setmetatable
local _assert = assert
local import = import

---@class ReUI.Version
---@field major number
---@field minor number
---@field revision number

---@alias LoadStatus
---| "loading"
---| "loaded"
---| "failed"

---@alias LoaderStage
---| "preload"
---| "load"
---| "disposed"

---@class ReUI.Module
---@field Version ReUI.Version
---@field Name string
---@field Status LoadStatus
---@field Dependencies ReUI.Module[]
---@field Path FileName

---@class InternalModuleInfo
---@field path FileName
---@field tag string

---@class InternalModule
---@field path FileName
---@field name string
---@field version ReUI.Version

---@alias CompareOperator
---| ">="
---| "<="
---| ">"
---| "<"
---| "=="
---| "="

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
---@return string
local function GetLastPartOfModuleName(moduleName)
    local splitName = DemangleName(moduleName)
    return splitName[table.getn(splitName)] or ""
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

local VERSION_REGEX = '^(%a[%a%.%d]*)([><=]=?)(%d+%.%d+%.%d+)$'
---@param s string
---@return string? # name
---@return CompareOperator?
---@return ReUI.Version?
local function MatchDependencyString(s)
    s = StringGSub(s, "%s+", "") -- remove spaces
    local start = StringFind(s, VERSION_REGEX)
    if not start then
        return nil, nil, nil
    end

    local moduleName = StringGSub(s, VERSION_REGEX, '%1')

    local op = StringGSub(s, VERSION_REGEX, '%2') --[[@as CompareOperator]]
    local versionS = StringGSub(s, VERSION_REGEX, '%3')

    return moduleName, op, ParseVersion(versionS)
end

local ModuleMeta = {
    ---@param self ReUI.Module
    ---@param key any
    __index = function(self, key)
        _error(("ReUI.Core: attempt to get '%s' from module '%s', which doesn't exist")
            :format(tostring(key), _rawget(self, "Name") or "UNKNOWN"))
    end
}

---@class ReUI.Loader
---@field _isReplay boolean
---@field _stage LoaderStage
---@field _internalData table
---@field _internalModules table<string, InternalModule>
---@field _modules table<string, ReUI.Module>
---@field _loadedModulesInOrder ReUI.Module[]
---@field _modulesInProgress table<string, boolean>
---@field _loadingErrors string[]
---@field _preCreateCallbacks OnCreateUICallback[]
---@field _postCreateCallbacks OnCreateUICallback[]
---@field _preloadStack ReUI.Module[]
Loader = Class()
{
    ---@param self ReUI.Loader
    __init = function(self, internalData, internalModulesList)
        self._isReplay = false
        self._stage = "disposed"

        self._internalData         = internalData
        self._modules              = {}
        self._loadedModulesInOrder = {}
        self._modulesInProgress    = {}
        self._loadingErrors        = {}

        self._preCreateCallbacks = {}
        self._postCreateCallbacks = {}

        self._preloadStack = {}

        self._internalModules = {}
        local ok, result = pcall(function()
            for _, info in ipairs(internalModulesList or {}) do
                local name, version = ParseNameAndVersion(info.tag)
                self._internalModules[name] = {
                    path = info.path,
                    version = version,
                    name = name
                }
                LOG(("ReUI: loaded internal module '%s':%s"):format(name, VersionToString(version)))
            end
        end)
        if not ok then
            WARN("ReUI: failed to load internal modules: " .. result)
        end
    end,

    ---@param self ReUI.Loader
    ---@param func fun(isReplay: boolean)
    ---@return fun(isReplay: boolean)
    Wrap = function(self, func)
        local ___, version = import("/lua/version.lua").GetVersionData()
        if StringSub(version, 1, 1) ~= StringSub(version, 3, 3) then
            return func
        end
        self:PreLoad()
        return function(isReplay)
            self._isReplay = isReplay
            self:Load()
            self:PreCreateUI()
            func(isReplay)
            self:PostCreateUI()
            self:PrintLoadedModules()
            self:Dispose()
        end
    end,

    ---@param self ReUI.Loader
    ---@param message string
    AddError = function(self, message)
        TableInsert(self._loadingErrors, message)
    end,

    ---@param self ReUI.Loader
    ---@return string[]
    GetErrors = function(self)
        return self._loadingErrors
    end,

    ---@param self ReUI.Loader
    PreLoad = function(self)
        self._stage = "preload"

        for _, mod in __active_mods do
            if mod.ReUI and mod.ui_only then
                if mod.selectable then
                    self:PreLoadModule(mod.ReUI)
                else
                    self:AddError((
                        "Do not select mods through client mod list! Use ingame mod manager. Mod '%s' is unselectable.")
                        :format(mod.name))
                end
            end
        end
    end,

    ---@param self ReUI.Loader
    ---@param moduleName string
    ---@return ReUI.Module
    ImportModule = function(self, moduleName)
        if self:IsLoadStage() then
            error("ReUI.Loader: attempt to import module '" .. moduleName .. "' in load stage")
        end

        local moduleVersion, modPath = self:GetModulePathAndInfo(moduleName)
        local mainPath = modPath .. GetLastPartOfModuleName(moduleName) .. ".lua"
        if not exists(mainPath) then
            mainPath = modPath .. "Main.lua"
        end

        ---@type ReUI.Module
        local module = self._modules[moduleName]
        module.Version = moduleVersion
        module.Dependencies = {}
        module.Path = modPath
        module.Main = import(mainPath).Main
        return module
    end,


    ---@param self ReUI.Loader
    ---@param moduleName string
    ---@return ReUI.Module
    TryLoadModule = function(self, moduleName)
        local modulesInProgress = self._modulesInProgress
        if modulesInProgress[moduleName] then
            local msgError = ("Module '%s' is already loading. Is there circular dependency?"):format(moduleName)
            self:AddError(msgError)
            _error(msgError)
        end

        local loadingModule = setmetatable(
            {
                Name = moduleName,
                Status = "loading",
            }, ModuleMeta)

        self._modules[moduleName] = loadingModule

        modulesInProgress[moduleName] = true
        table.insert(self._preloadStack, loadingModule)

        local ok, result = _pcall(self.ImportModule, self, moduleName)

        table.remove(self._preloadStack)
        modulesInProgress[moduleName] = nil

        if not ok then
            loadingModule.Status = "failed"
            self:AddError(("Failed to load module '%s'. See log for more info."):format(moduleName))
            _error(("Failed to load module '%s' due to following error:\n%s"):format(moduleName, result))
        end

        LOG(("ReUI: loaded module '%s':%s"):format(moduleName, VersionToString(result.Version)))

        TableInsert(self._loadedModulesInOrder, loadingModule)
        local demangledName = DemangleName(moduleName)
        self:AssignModule(demangledName, loadingModule)
        return loadingModule
    end,

    ---@param self ReUI.Loader
    ---@param moduleTag string
    TryPreLoad = function(self, moduleTag)
        self:CheckNotDisposed()

        moduleTag = StringGSub(moduleTag, "%s+", "")
        local name = StringGSub(moduleTag, MARKER_VERSION, '%1')
        local module = self._modules[name] or self:TryLoadModule(name)
        if module.Status == "failed" then
            _error(("Module '%s' failed to load previously"):format(name))
        end
        ---@diagnostic disable-next-line:return-type-mismatch
        return module
    end,

    ---@param self ReUI.Loader
    ---@param moduleTag string
    PreLoadModule = function(self, moduleTag)
        local ok, result = _pcall(self.TryPreLoad, self, moduleTag)
        if not ok then
            WARN(result)
        end
    end,

    ---@param self ReUI.Loader
    Load = function(self)
        self._stage = "load"

        for _, module in ipairs(self._loadedModulesInOrder) do
            self:LoadModule(module)
        end
    end,

    ---@param self ReUI.Loader
    ---@return boolean
    IsLoadStage = function(self)
        return self._stage == "load"
    end,

    ---@param self ReUI.Loader
    ---@param module ReUI.Module
    ---@return boolean
    CheckDependencies = function(self, module)
        for _, dep in module.Dependencies do
            if dep.Status == "failed" then
                return false
            end
        end
        return true
    end,

    ---@param self ReUI.Loader
    ---@param module ReUI.Module
    TryCallModuleMain = function(self, module)
        if module.Status == "loaded" then
            return
        end

        if not self:CheckDependencies(module) then
            self:AddError(("Module '%s' failed to load due to failed dependencies."):format(module.Name))
            module.Status = "failed"
            return
        end

        local r = module.Main(self._isReplay)
        module.Main = nil
        if r then
            for k, v in r do
                rawset(module, k, v)
            end
        end
        module.Status = "loaded"
    end,

    ---@param self ReUI.Loader
    ---@param module ReUI.Module
    LoadModule = function(self, module)
        local ok, result = _pcall(self.TryCallModuleMain, self, module)
        if not ok then
            self:AddError(("Failed to load module '%s' due to error in Main. See log for more info."):format(module.Name))
            module.Status = "failed"
            WARN(result)
        end
    end,

    ---@param self ReUI.Loader
    ---@param callback OnCreateUICallback
    AddPreCreateCallback = function(self, callback)
        self:CheckNotDisposed()
        TableInsert(self._preCreateCallbacks, callback)
    end,

    ---@param self ReUI.Loader
    PreCreateUI = function(self)
        for _, callback in self._preCreateCallbacks do
            local ok, result = _pcall(callback, self._isReplay)
            if not ok then
                WARN(result)
            end
        end
    end,

    ---@param self ReUI.Loader
    ---@param callback OnCreateUICallback
    AddPostCreateCallback = function(self, callback)
        self:CheckNotDisposed()
        TableInsert(self._postCreateCallbacks, callback)
    end,

    ---@param self ReUI.Loader
    PostCreateUI = function(self)
        for _, callback in self._postCreateCallbacks do
            local ok, result = _pcall(callback, self._isReplay)
            if not ok then
                WARN(result)
            end
        end

        local errors = self:GetErrors()
        local ok, r = pcall(function()
            local ReceiveChatFromSim = import("/lua/ui/game/chat.lua").ReceiveChatFromSim
            for _, err in errors do
                ReceiveChatFromSim(GetFocusArmy(), {
                    Chat = true,
                    to = 'notify',
                    text = err,
                })
            end
        end)
        if not ok then
            WARN(r)
        end
    end,

    ---@param self ReUI.Loader
    ---@param name string
    ---@return ReUI.Module?
    GetModule = function(self, name)
        return self._modules[name]
    end,

    ---@param self ReUI.Loader
    ---@param tag string
    ---@return ReUI.Module?
    Exists = function(self, tag)
        local name, op, version = MatchDependencyString(tag)
        if not name then
            WARN("ReUI: failed to parse dependency string: " .. tag)
            return nil
        end
        ---@cast op -nil
        ---@cast version -nil

        ---@type ReUI.Module?
        local module = self:GetModule(name)
        if module == nil then
            return nil
        end

        if module.Status == "failed" then
            return nil
        end

        if not CheckVersion(module.Version, op, version) then
            return nil
        end

        if module.Status == "loading" then
            self:LoadModule(module)
        end

        if module.Status == "loaded" then
            return module
        end

        return nil
    end,

    ---@param self ReUI.Loader
    ---@param deps string[]
    Require = function(self, deps)
        self:CheckPreLoadStage()

        local topModule = self._preloadStack[table.getn(self._preloadStack)]
        assert(topModule, "ReUI.Loader: there is no module in preload stack")

        for _, dep in deps do
            local name, op, version = MatchDependencyString(dep)
            if not name then
                _error(("Invalid dependency string '%s'!"):format(dep))
            end
            ---@cast op -nil
            ---@cast version -nil

            ---@type ReUI.Module
            local module = self._modules[name] or self:TryLoadModule(name)

            if module.Status == "failed" then
                _error(("Module '%s' failed to load previously"):format(name))
            end

            TableInsert(topModule.Dependencies, module)

            if self:IsLoadStage() then
                self:LoadModule(module)
            end

            if not CheckVersion(module.Version, op, version) then
                local msg = ("Module '%s' doesn't match required version: current: %s, required: %s%s")
                    :format(
                        name,
                        VersionToString(module.Version),
                        op,
                        VersionToString(version)
                    )
                self:AddError(msg)
                _error(msg)
            end
        end
    end,

    ---@param self ReUI.Loader
    ---@param parts string[]
    ---@param module ReUI.Module
    AssignModule = function(self, parts, module)
        local data = self._internalData
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
    end,

    ---@param self ReUI.Loader
    CheckNotDisposed = function(self)
        _assert(self._stage ~= "disposed",
            "ReUI loader was disposed. Are you trying to require modules outside of creation of UI?")
    end,

    ---@param self ReUI.Loader
    CheckPreLoadStage = function(self)
        _assert(self._stage == "preload",
            "ReUI loader is not in preload stage. Are you trying to require modules within Main function?")
    end,

    ---@param self ReUI.Loader
    ---@param moduleName string
    ---@return ReUI.Version
    ---@return FileName
    GetModulePathAndInfo = function(self, moduleName)
        local moduleInfo = self._internalModules[moduleName]
        if moduleInfo then
            return moduleInfo.version, moduleInfo.path
        end

        local dotPath = StringFormat("/mods/%s/", moduleName) --[[@as FileName]]
        local slashPath = StringFormat("/mods/%s/", StringGSub(moduleName, "%.", "/")) --[[@as FileName]]

        if exists(dotPath .. "mod_info.lua") and exists(slashPath .. "mod_info.lua") then
            local name1, v1 = ParseNameAndVersion(import(dotPath .. "mod_info.lua").ReUI)
            local name2, v2 = ParseNameAndVersion(import(slashPath .. "mod_info.lua").ReUI)

            if VersionGreater(v1, v2) or VersionEqual(v1, v2) then
                return v1, dotPath
            end
            return v2, slashPath
        elseif exists(dotPath .. "mod_info.lua") then
            local name1, v1 = ParseNameAndVersion(import(dotPath .. "mod_info.lua").ReUI)
            return v1, dotPath
        elseif exists(slashPath .. "mod_info.lua") then
            local name2, v2 = ParseNameAndVersion(import(slashPath .. "mod_info.lua").ReUI)
            return v2, slashPath
        end

        error("Unable to find module " .. moduleName)
    end,

    ---@param self ReUI.Loader
    PrintLoadedModules = function(self)
        LOG "ReUI: Loaded modules:"
        for _, module in ipairs(self._loadedModulesInOrder) do
            if module.Status ~= "failed" then
                LOG("\t", module.Name .. ": " .. VersionToString(module.Version))
            end
        end
        LOG "ReUI: Failed to load modules:"
        for _, module in ipairs(self._loadedModulesInOrder) do
            if module.Status == "failed" then
                LOG("\t", module.Name .. ": " .. VersionToString(module.Version))
            end
        end
    end,

    ---@param self ReUI.Loader
    Dispose = function(self)

        if not table.empty(self._preloadStack) then
            WARN("ReUI: Preload stack is not empty.")
        end

        self._stage = "disposed"

        self._loadedModulesInOrder = nil
        self._modulesInProgress = nil
        self._loadingErrors = nil
        self._internalModules = nil

        self._preCreateCallbacks = nil
        self._postCreateCallbacks = nil
    end,
}
