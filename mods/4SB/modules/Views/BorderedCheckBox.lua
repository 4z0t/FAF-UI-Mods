local Bitmap = import('/lua/maui/bitmap.lua').Bitmap
local Group = import('/lua/maui/group.lua').Group
local BorderedText = import("BorderedText.lua").BorderedText
local LazyVar = import('/lua/lazyvar.lua').Create
local LayoutFor = import("/lua/maui/layouthelpers.lua").ReusedLayoutFor
local Text = import("/lua/maui/text.lua").Text
local Dragger = import("/lua/maui/dragger.lua").Dragger

local colorAnimationFactory = import("../Animations/AnimationFactory.lua").GetColorAnimationFactory()


BorderedCheckBox = Class(BorderedText)
{
    __init = function(self, parent, normalUnchecked, normalChecked, overUnchecked, overChecked, disabledUnchecked,
                      disabledChecked, clickCue, rolloverCue, borderWidth)
        BorderedText.__init(self, parent, normalUnchecked, borderWidth)

        self._states = {
            normal = {
                checked = normalChecked,
                unchecked = normalUnchecked
            },
            over = {
                checked = overChecked or normalChecked,
                unchecked = overUnchecked or normalUnchecked
            },
            disabled = {
                checked = disabledChecked or normalChecked,
                unchecked = disabledUnchecked or normalUnchecked
            }
        }

        self._rolloverCue = rolloverCue
        self._clickCue = clickCue

        self._checkState = "unchecked"
        self._controlState = "normal"
    end,

    SetNewColors = function(self, normalUnchecked, normalChecked, overUnchecked, overChecked, disabledUnchecked,
                            disabledChecked)
        self._states.normal.checked = normalChecked
        self._states.normal.unchecked = normalUnchecked
        self._states.over.checked = overChecked or normalChecked
        self._states.over.unchecked = overUnchecked or normalUnchecked
        self._states.disabled.checked = disabledChecked or normalChecked
        self._states.disabled.unchecked = disabledUnchecked or normalUnchecked
        -- update current color

        self:SetColor(self._states[self._controlState][self._checkState])
    end,

    SetCheck = function(self, isChecked, skipEvent)
        if isChecked == true then
            self._checkState = "checked"
        else
            self._checkState = "unchecked"
        end
        self:SetState(self._controlState, self._checkState)
        if not skipEvent then
            self:OnCheck(isChecked)
        end
    end,

    ToggleCheck = function(self)
        self:SetCheck(self._checkState ~= "checked")
    end,

    IsChecked = function(self)
        return (self._checkState == "checked")
    end,

    OnDisable = function(self)
        if self._controlState ~= "disabled" then
            self._controlState = "disabled"
            self:SetState(self._controlState, self._checkState)
        end
    end,

    OnEnable = function(self)
        if self._controlState ~= "enabled" then
            self._controlState = "normal"
            self:SetState(self._controlState, self._checkState)
        end
    end,

    HandleEvent = function(self, event)
        if event.Type == 'MouseEnter' then
            if self._controlState ~= "disabled" then
                self._controlState = "over"
                self:SetState(self._controlState, self._checkState)
                if self._rolloverCue ~= "NO_SOUND" then
                    if self._rolloverCue then
                        PlaySound(Sound { Cue = self._rolloverCue, Bank = "Interface", })
                    end
                end
                return true
            end
        elseif event.Type == 'MouseExit' then
            if self._controlState ~= "disabled" then
                self._controlState = "normal"
                self:SetState(self._controlState, self._checkState)
                return true
            end
        elseif event.Type == 'ButtonPress' or event.Type == 'ButtonDClick' then
            self:OnClick(event.Modifiers)
            if self._clickCue ~= "NO_SOUND" then
                if self._clickCue then
                    PlaySound(Sound { Cue = self._clickCue, Bank = "Interface", })
                end
            end
            return true
        end

        return false
    end,

    SetState = function(self, state, check)
        self:SetColor(self._states[state][check])
    end,

    -- override this method to handle checks
    OnCheck = function(self, checked) end,

    -- override this method to handle clicks differently than default (which is ToggleCheck)
    OnClick = function(self, modifiers)
        self:ToggleCheck()
    end,
}

---@type Animator
local colorAnimator = import("../Animations/Animator.lua").Animator(GetFrame(0))
local colorAnimation = colorAnimationFactory
    :For(0.5)
    :Create(colorAnimator)


AnimatedBorderedCheckBox = Class(BorderedCheckBox)
{
    SetState = function(self, state, check)
        colorAnimation:Apply(self, self._states[state][check])
    end,
}
