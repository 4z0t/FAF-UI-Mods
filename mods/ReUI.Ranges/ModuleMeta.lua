---@meta

---@class RingPool
---@field ringCount number # total number of rings created by the pool
---@field freeCount number # number of currently available free rings
---@field freeRings Ring[] # pool of idle/recycled Ring objects
---@field Alloc fun(self: RingPool): Ring
---@field Free fun(self: RingPool, ring: Ring)
---@field GetRingCount fun(self: RingPool): number
---@field GetFreeCount fun(self: RingPool): number
---@field GetActiveCount fun(self: RingPool): number
---@field Clear fun(self: RingPool)

---@class RangesWorldViewComponent : ReUI.WorldView.Component, UIShape
---@field _ringPool RingPool
---@field GetRingPool fun(self: RangesWorldViewComponent): RingPool

---@class ReUI.Ranges : ReUI.Module
---@field RingPool RingPool
---@field RangesWorldViewComponent RangesWorldViewComponent
ReUI.Ranges = {}
