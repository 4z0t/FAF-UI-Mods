---@meta


---@class ReUI.Score : ReUI.Module
ReUI.Score = {}

---@class ReUI.Score.ScoreBoard
ReUI.Score.ScoreBoard = ...

---@class ReUI.Score.ReplayScoreBoard
ReUI.Score.ReplayScoreBoard = ...

---@type table<string, (fun(control: ReUI.UI.Layoutable, layouter:ReUI.UI.Layouter) : fun(control: ReUI.UI.Layoutable)?)>
ReUI.Score.Layouts = {}

ReUI.Score.Layouts["minimal"] = ...
ReUI.Score.Layouts["glow border"] = ...
ReUI.Score.Layouts["window border"] = ...

---@type ReUI.Score.ScoreBoard
ReUI.UI.Global["ScoreBoard"] = ...
