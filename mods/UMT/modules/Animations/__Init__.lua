local AnimationFactories = import("AnimationFactory.lua")

Factory = {
    Base = AnimationFactories.GetAnimationFactory(),
    Alpha = AnimationFactories.GetAlphaAnimationFactory(),
    Color = AnimationFactories.GetColorAnimationFactory(),
    Delay = AnimationFactories.GetDelayAnimationFactory(),
}
Sequential = import("SequentialAnimation.lua").SequentialAnimation
Animator = import("Animator.lua").Animator
Animation = import("Animation.lua")