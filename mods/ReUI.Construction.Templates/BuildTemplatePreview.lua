local Bitmap = ReUI.UI.Controls.Bitmap
local Text = ReUI.UI.Controls.Text
local CheckBox = ReUI.UI.Controls.CheckBox
local Group = ReUI.UI.Controls.Group


local UIUtil = import('/lua/ui/uiutil.lua')
local Logic = import('/lua/ui/dialogs/createunit.logic.lua')

local textures = {
    land = '/textures/ui/common/icons/units/land_up.dds',
    sea = '/textures/ui/common/icons/units/sea_up.dds',
    amph = '/textures/ui/common/icons/units/amph_up.dds',
    air = '/textures/ui/common/icons/units/air_up.dds',
}


---@param id string
---@return FileName
local function GetBackgroundImage(id)
    return textures[Logic.GetLayerGroup(id)] or textures.land
end

---@param id string
---@return FileName
local function GetUnitImage(id)
    local icon = UIUtil.UIFile('/icons/units/' .. id .. '_icon.dds', true)
    return icon and DiskGetFileInfo(icon) and icon or
        UIUtil.UIFile('/game/unit_view_icons/unidentified.dds')
end

local function GetUnitSkirtSizes(id)
    local bp = __blueprints[id]
    return bp.Physics.SkirtSizeX or bp.Footprint.SizeX or bp.SizeX or 1,
        bp.Physics.SkirtSizeZ or bp.Footprint.SizeZ or bp.SizeZ or 1
end

local function GetSkirtCentreOffset(id)
    local bp = __blueprints[id]
    local w, h = bp.Footprint.SizeX or bp.SizeX or 1, bp.Footprint.SizeZ or bp.SizeZ or 1
    local sW, sH = GetUnitSkirtSizes(id)
    local XSkirtO, ZSkirtO = bp.Physics.SkirtOffsetX, bp.Physics.SkirtOffsetZ
    return ((XSkirtO + ((sW + XSkirtO) - w))) / 2, ((ZSkirtO + ((sH + ZSkirtO) - h))) / 2
end

---@class BuildTemplatePreview.Icon : ReUI.UI.Controls.Bitmap
---@field icon ReUI.UI.Controls.Bitmap
---@field id string
local Icon = ReUI.Core.Class(Bitmap)
{
    ---@param self BuildTemplatePreview.Icon
    ---@param parent Control
    ---@param id string
    __init = function(self, parent, id)
        Bitmap.__init(self, parent, GetBackgroundImage(id))
        self.icon = Bitmap(self, GetUnitImage(id))
    end,

    ---@param self BuildTemplatePreview.Icon
    ---@param layouter ReUI.UI.Layouter
    InitLayout = function(self, layouter)
        layouter(self.icon)
            :Fill(self)
    end
}

---@class BuildTemplatePreview : ReUI.UI.Controls.Group
---@field _title ReUI.UI.Controls.Text
---@field template any
---@field xOffset number
---@field zOffset number
---@field icons BuildTemplatePreview.Icon[]
BuildTemplatePreview = ReUI.Core.Class(Group)
{
    ---@param self BuildTemplatePreview
    ---@param parent Control
    ---@param template any
    __init = function(self, parent, template)
        Group.__init(self, parent)
        self.template = template

        self._title = Text(self)
        self._title:SetFont("Arial", 16)
        self._title:SetText(template.name)

        local td = template.templateData
        local xOffset, zOffset = { 0, 0 }, { 0, 0 }

        for i = 3, table.getn(td) do
            local id = td[i][1]
            if __blueprints[id] then
                local w, h = GetUnitSkirtSizes(id)
                local posX, posZ = td[i][3], td[i][4]
                local cOffX, cOffZ = GetSkirtCentreOffset(id)
                xOffset[1] = math.min(xOffset[1], (posX - w / 2) + cOffX)
                xOffset[2] = math.max(xOffset[2], (posX + w / 2) + cOffX)
                zOffset[1] = math.min(zOffset[1], (posZ - h / 2) + cOffZ)
                zOffset[2] = math.max(zOffset[2], (posZ + h / 2) + cOffZ)
            end
        end


        self.xOffset, self.zOffset = (xOffset[1] + xOffset[2]) / 2, (zOffset[1] + zOffset[2]) / 2

        self.icons = {}
        for i = 3, table.getn(td) do
            local id = td[i][1]
            self.icons[i] = Icon(self, id)
        end
    end,

    ---@param self BuildTemplatePreview
    ---@param layouter ReUI.UI.Layouter
    InitLayout = function(self, layouter)

        layouter(self._title)
            :Color(UIUtil.factionTextColor)
            :DropShadow(true)
            :AnchorToTop(self, 2)
            :AtHorizontalCenterIn(self)

        local td = self.template.templateData
        local gridscale = 10
        local tXgridSize = td[1]
        local tZgridSize = td[2]
        local tScale = 300 / (math.max(tXgridSize, tZgridSize) * gridscale)
        local scale = gridscale * tScale

        local xOffset, zOffset = self.xOffset, self.zOffset

        for i = 3, table.getn(td) do
            local id = td[i][1]
            local icon = self.icons[i]
            local w, h = GetUnitSkirtSizes(id)
            local xCenOff, zCenOff = GetSkirtCentreOffset(id)

            layouter(icon)
                :Width(w * scale)
                :Height(h * scale)
                :AtCenterIn(self,
                    (td[i][4] - zOffset + zCenOff) * scale,
                    (td[i][3] - xOffset + xCenOff) * scale)
        end

        layouter(self)
            :Width(300)
            :Height(300)
            :Depth(self:GetRootFrame():GetTopmostDepth() + 1)
            :DisableHitTest(true)
    end,
}
