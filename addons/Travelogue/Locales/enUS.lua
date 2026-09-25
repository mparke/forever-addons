-- Every player-facing string Travelogue shows (production rule 4). enUS is the base
-- and the fallback; a string is added here in the same change as the code showing it.

local _, ns = ...

ns.L = ns.Kit.Locale.new(GetLocale(), {})
