--- HebrewBalatro - Full Hebrew RTL Translation Mod
--- Requires: Steamodded >= 0.9.8, Lovely Injector
--- Author: Hen Hatuka
---
--- Hebrew rendering relies on LOVE's HarfBuzz text shaping via
--- `use_native_text = true` on the registered font. No runtime BiDi
--- reversal is performed in Lua; HarfBuzz reorders glyphs to visual
--- RTL order inside `love.graphics.newText(font, str)`, which is the
--- exact path Balatro's DynaText uses (see engine/text.lua).

local mod_path = SMODS.current_mod.path

SMODS.Language({
    key = 'he',
    label = 'עברית',
    loc_key = 'en-us',
    font = {
        file = 'BalatroHebrew.ttf',
        render_scale = 200,
        TEXT_HEIGHT_SCALE = 0.83,
        TEXT_OFFSET = {x = 10, y = -20},
        FONTSCALE = 0.1,
        squish = 1,
        DESCSCALE = 1,
        min_filter = 'nearest',
        mag_filter = 'nearest',
        hinting = 'mono',
        use_native_text = true,
    },
})

-- Apply Hebrew-specific language properties after SMODS registration.
-- (SMODS.Language doesn't expose skip_crt / button natively.)
local function patch_he_lang()
    if G and G.LANGUAGES and G.LANGUAGES['he'] then
        local L = G.LANGUAGES['he']
        L.skip_crt = true
        L.button = 'משוב על תרגום'
    end
end

patch_he_lang()

local _orig_love_load = love.load
love.load = function(...)
    local r = {_orig_love_load and _orig_love_load(...)}
    patch_he_lang()
    return table.unpack(r)
end
