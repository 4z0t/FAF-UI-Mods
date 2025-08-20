ReUI.Require
{
    "ReUI.Core >= 1.2.0",
    "ReUI.Options >= 1.0.0"
}


function Main()
    -- local options = ReUI.Options.Mods["ReUI"]

    -- local mods = {
    --     { options.construction, "ReUI.Construction >= 1.0.0" },
    --     { options.economy, "ReUI.Economy >= 1.0.0" },
    --     { options.score, "ReUI.Score >= 1.0.0" },
    --     -- { options.reclaim, "ReUI.Reclaim >= 1.0.0" },
    -- }

    -- for _, mod in mods do
    --     if mod[1]() then
    --         local ok, err = pcall(ReUI.Require, { mod[2] })
    --         if not ok then
    --             WARN(err)
    --         end
    --     end
    -- end
end
