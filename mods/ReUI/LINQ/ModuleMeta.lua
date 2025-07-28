---@meta


---@class ReUI.LINQ : ReUI.Module
ReUI.LINQ = {}

---@type Enumerator
ReUI.LINQ.PairsEnumerator = ...

---@type Enumerator
ReUI.LINQ.IPairsEnumerator = ...

---@generic K, V, NK, NV
---@param t table<K,V>|V[]
---@param iterator? fun(t:table<NK,NV>, k:NK): NK, NV @defaults to ipairs iterator
---@param transformer? fun(t:table<K,V>):table<NK,NV>
---@return Enumerable
function ReUI.LINQ.Enumerate(t, iterator, transformer)
end

---@class Enumerator
ReUI.LINQ.Enumerator = ...

---@class Enumerable
ReUI.LINQ.Enumerable = ...
