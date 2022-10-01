-- local Decal = import('/lua/user/userdecal.lua').UserDecal
-- local Button = import('/lua/maui/button.lua').Button
-- local UIUtil = import('/lua/ui/uiutil.lua')
-- local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
-- local worldView = import('/lua/ui/game/worldview.lua').viewLeft
-- local Bitmap = import('/lua/maui/bitmap.lua').Bitmap
-- local textures = '/mods/SmdRing/textures/'
-- local Prefs = import('/lua/user/prefs.lua')
-- local Combo = import('/lua/ui/controls/combo.lua').Combo

-- local isShown = true
-- local wasChangedTextures = false
-- local ring_textures = {
--     thin = {'smd', 'tmd', 'air', 'direct', 'nondirect'},
--     bold = {'smdBold', 'tmdBold', 'airBold', 'directBold', 'nondirectBold'}
--     -- custom = {},
-- }

-- local texture_types = {'thin', 'bold'}
-- -- local texture_type_prefixes = {'','Bold'}
-- -- ring_textures[texture_types[ring_textures_prefs[id]]][ring_types[id]]

-- local ring_textures_prefs = Prefs.GetFromCurrentProfile("SmartRings") or {1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1}
-- local ring_types = {1, 2, 2, 4, 3, 4, 3, 3, 5, 4, 3}

-- local ranges = {
-- 90, -- smd
-- 31, -- tmd
-- 12.5, -- aeon tmd
-- 26, -- t1 pds
-- 44, -- t1 aa
-- 50, -- t2 pd
-- 44, -- cyb/sera t2 aa
-- 50, -- uef/aeon t2 aa
-- 128, -- t2 arty
-- 70, -- ravager
-- 60 -- sams
-- }

-- local icons = {'UAB4302_icon', -- smd
-- 'UEB4201_icon', -- tmd
-- 'UAB4201_icon', -- aeon
-- 'UEB2101_icon', -- t1 pds
-- 'UEB2104_icon', -- t1 aa
-- 'UEB2301_icon', -- t2 pd
-- 'URB2204_icon', -- cyb/se
-- 'UEB2204_icon', -- uef/ae
-- 'UEB2303_icon', -- t2 ar
-- 'xeb2306_icon', -- ravager
-- 'UEB2304_icon' -- sams
-- }
-- local item_count = table.getn(icons)
-- local step = 360 / item_count

-- local size = 64
-- local radius = 140

-- local Width = 1920
-- local Height = 1080

-- local SelectionRing = nil
-- local animation = {}
-- local rings = {}
-- local animationRing
-- local isAnimation = false

-- function animateAppear()
--     if SelectionRing then
--         SelectionRing:Destroy()
--         SelectionRing = nil
--         return
--     end
--     if isAnimation then
--         return
--     end
--     isAnimation = true

--     local degree = 0
--     local mouseScreenPos = GetMouseScreenPos()

--     animationRing = Bitmap(GetFrame(0))
--     animationRing.Depth:Set(100)
--     animationRing.Width:Set(radius * 2.5)
--     animationRing.Height:Set(radius * 2.5)
--     -- animationRing:SetAlpha(0.3)
--     animationRing.mousePos = GetMouseWorldPos()
--     LayoutHelpers.AtLeftTopIn(animationRing, GetFrame(0), mouseScreenPos.x - animationRing.Width() / 2,
--         mouseScreenPos.y - animationRing.Height() / 2)

--     animationRing.circle = Bitmap(animationRing, textures .. 'background.dds')
--     animationRing.circle:SetAlpha(0.3)
--     animationRing.circle.Width:Set(0)
--     animationRing.circle.Height:Set(0)
--     LayoutHelpers.AtCenterIn(animationRing.circle, animationRing)
--     for id, _ in icons do
--         local path = textures .. icons[id] .. '.dds'
--         animation[id] = Bitmap(animationRing, path)
--         animation[id].Width:Set(0)
--         animation[id].Height:Set(0)
--         animation[id]:SetAlpha(0)
--         -- LayoutHelpers.AtCenterIn(animation[id], animationRing, 
--         --                         animation[id].Width() / 2, 
--         --                         animation[id].Height() / 2)
--         LayoutHelpers.AtCenterIn(animation[id], animationRing)
--         animation[id].vx = math.cos(math.rad(degree))
--         animation[id].vy = math.sin(math.rad(degree))
--         degree = degree + step

--     end

--     for frame = 1, radius, 20 do
--         animationRing.circle.Width:Set(frame * 2.5)
--         animationRing.circle.Height:Set(frame * 2.5)
--         for id, _ in icons do
--             -- LayoutHelpers.AtCenterIn(animation[id], animationRing, 
--             --         frame * animation[id].vx - animation[id].Width() / 2, 
--             --         frame * animation[id].vy - animation[id].Height() / 2)
--             LayoutHelpers.AtCenterIn(animation[id], animationRing, frame * animation[id].vx, frame * animation[id].vy)
--             animation[id].Width:Set(frame / radius * size)
--             animation[id].Height:Set(frame / radius * size)
--             animation[id]:SetAlpha(frame / radius)
--         end
--         coroutine.yield(1)
--     end
--     animationRing:Destroy()
--     animationRing = nil
--     CallRingSelection(mouseScreenPos)
--     isAnimation = false
-- end

-- function CallRingSelectionAnim()
--     ForkThread(animateAppear)
-- end

-- function CallRingSelection(mouseScreenPos)
--     if SelectionRing then
--         SelectionRing:Destroy()
--         SelectionRing = nil
--         if wasChangedTextures then
--             Prefs.SetToCurrentProfile("SmartRings", ring_textures_prefs)
--         end
--         return
--     end
--     wasChangedTextures = false

--     local degree = 0
--     if mouseScreenPos == nil then
--         mouseScreenPos = GetMouseScreenPos()
--     end

--     SelectionRing = Bitmap(GetFrame(0), textures .. 'background.dds')
--     SelectionRing.Depth:Set(100)
--     SelectionRing.Width:Set(radius * 2.5)
--     SelectionRing.Height:Set(radius * 2.5)
--     SelectionRing:SetAlpha(0.3)
--     SelectionRing.mousePos = GetMouseWorldPos()

--     LayoutHelpers.AtLeftTopIn(SelectionRing, GetFrame(0), mouseScreenPos.x - SelectionRing.Width() / 2,
--         mouseScreenPos.y - SelectionRing.Height() / 2)

--     for id, _ in icons do
--         local path = textures .. icons[id] .. '.dds'
--         local button = Button(SelectionRing, path, path, path, path)

--         button.Width:Set(size)
--         button.Height:Set(size)
--         local pos = {
--             x = radius * math.cos(math.rad(degree)),
--             y = radius * math.sin(math.rad(degree))
--         }
--         -- LayoutHelpers.AtCenterIn(button, SelectionRing, 
--         --                         pos.x - button.Width() / 2, 
--         --                         pos.y - button.Height() / 2)
--         LayoutHelpers.AtCenterIn(button, SelectionRing, pos.x, pos.y)
--         button.id = id
--         button.OnClick = function(self, event)
--             if event.Right then
--                 if self.ringTexSelection then
--                     return
--                 end
--                 wasChangedTextures = true
--                 self.ringTexSelection = Combo(self, 14, 3, nil, nil)
--                 self.ringTexSelection.Width:Set(size)

--                 LayoutHelpers.Below(self.ringTexSelection, self, 0)
--                 LayoutHelpers.AtLeftIn(self.ringTexSelection, self)
--                 LayoutHelpers.ResetRight(self.ringTexSelection)
--                 self.ringTexSelection.id = self.id
--                 self.ringTexSelection.OnClick = function(self, index, text, skipUpdate)
--                     self:SetItem(index)
--                     ring_textures_prefs[self.id] = index
--                 end
--                 self.ringTexSelection:AddItems(texture_types, 1)
--                 self.ringTexSelection:SetItem(ring_textures_prefs[self.id])
--                 self.ringTexSelection.Depth:Set(GetFrame(0):GetTopmostDepth() + 1)

--             else
--                 -- LOG(repr(event))
--                 -- LOG('called '..self.id)
--                 DrawRing(self.id, SelectionRing.mousePos)
--                 SelectionRing:Destroy()
--                 SelectionRing = nil
--                 if wasChangedTextures then
--                     Prefs.SetToCurrentProfile("SmartRings", ring_textures_prefs)
--                 end
--             end
--         end
--         degree = degree + step

--     end
-- end

-- function createRingDecal(pos, range, id)
--     local ring = Decal(GetFrame(0))
--     ring:SetTexture(textures .. ring_textures[texture_types[ring_textures_prefs[id]]][ring_types[id]] .. '.dds')
--     -- ring:SetAlpha(0.6)
--     ring:SetScale({math.floor(2.03 * range), 0, math.floor(2.03 * range)})
--     local ringPos = Vector(pos.x, pos.y, pos.z)
--     ring:SetPosition(ringPos)
--     return ring
-- end

-- function createRing(id, mousePos)
--     -- local mousePos = GetMouseWorldPos()
--     local ring = nil
--     local range = ranges[id]
--     if isShown then
--         ring = createRingDecal(mousePos, range, id)
--     end
--     return {
--         decal = ring,
--         pos = mousePos,
--         range = range,
--         id = id
--     }
-- end

-- function DrawRing(id, mousePos)
--     table.insert(rings, createRing(id, mousePos))
-- end

-- function DeleteRing()
--     -- deletes closest one
--     local mousePos = GetMouseWorldPos()
--     local minRing = nil
--     local ind = nil
--     local dist
--     for i, ring in rings do
--         dist = VDist2(ring.pos[1], ring.pos[3], mousePos[1], mousePos[3])
--         if minRing then
--             if dist < minRing then
--                 ind = i
--                 minRing = dist
--             end
--         else
--             minRing = dist
--             ind = 1
--         end
--     end
--     if ind then
--         rings[ind].decal:Destroy()
--         rings[ind] = nil
--         table.remove(rings, ind)
--     end

-- end

-- function ChangeShowState()
--     if isShown then
--         for i, _ in rings do
--             rings[i].decal:Destroy()
--             rings[i].decal = nil
--         end
--     else
--         for i, _ in rings do
--             rings[i].decal = createRingDecal(rings[i].pos, rings[i].range, rings[i].id)
--         end
--     end
--     isShown = not isShown
-- end
