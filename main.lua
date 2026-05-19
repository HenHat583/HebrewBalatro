--- HebrewBalatro - Full Hebrew RTL Translation Mod
--- Requires: Steamodded >= 0.9.8, Lovely Injector
--- Author: Hen Hatuka

-- ─── UTF-8 utilities (needed for BiDi) ───────────────────────────────────────

local _utf8 = {}
_utf8.pattern = '[\0-\x7F\xC2-\xFD][\x80-\xBF]*'

_utf8.codepoint = function(c)
    local b1, b2, b3, b4 = c:byte(1, 4)
    if not b1 then return nil end
    if b1 < 0x80 then return b1 end
    if b1 < 0xE0 then return (b1 - 0xC0) * 0x40 + (b2 - 0x80) end
    if b1 < 0xF0 then return (b1 - 0xE0) * 0x1000 + (b2 - 0x80) * 0x40 + (b3 - 0x80) end
    return (b1 - 0xF0) * 0x40000 + (b2 - 0x80) * 0x1000 + (b3 - 0x80) * 0x40 + (b4 - 0x80)
end

_utf8.chars = function(s)
    return coroutine.wrap(function()
        for b, c in s:gmatch('()(' .. _utf8.pattern .. ')') do
            coroutine.yield(b, c)
        end
    end)
end

-- ─── BiDi / RTL processing ───────────────────────────────────────────────────

local function _rtl_cp(cp)
    return cp and ((cp >= 0x0590 and cp <= 0x05FF) or (cp >= 0xFB1D and cp <= 0xFB4F))
end

local function _run_kind(char)
    local cp = _utf8.codepoint(char)
    if _rtl_cp(cp) then return 'rtl' end
    if char:match('%s') then return 'neutral' end
    return 'ltr'
end

-- Global function called by Lovely-patched engine/text.lua
function HebrewBalatro_localize_display_text(text, lang)
    if type(text) ~= 'string' or text == '' then return text end
    lang = lang or (G and G.LANG)
    if not (lang and lang.rtl) then return text end

    local runs, cur = {}, nil
    local has_rtl = false

    local function push()
        if cur then runs[#runs + 1] = cur; cur = nil end
    end

    for _, char in _utf8.chars(text) do
        local k = _run_kind(char)
        if k == 'rtl' then has_rtl = true end
        if not cur or cur.kind ~= k then push(); cur = {kind = k, chars = {}} end
        cur.chars[#cur.chars + 1] = char
    end
    push()

    local mirror = {['('] = ')', [')'] = '(', ['['] = ']', [']'] = '['}

    if not has_rtl then
        if text:find('[%(%)%[%]]') then
            local o = select(2, text:gsub('%(', '')) + select(2, text:gsub('%[', ''))
            local c = select(2, text:gsub('%)', '')) + select(2, text:gsub('%]', ''))
            if o ~= c then
                local r = {}
                for _, ch in _utf8.chars(text) do r[#r + 1] = mirror[ch] or ch end
                return table.concat(r)
            end
        end
        return text
    end

    local out = {}
    for i = #runs, 1, -1 do
        local chars = runs[i].chars
        if runs[i].kind == 'rtl' then
            for j = #chars, 1, -1 do out[#out + 1] = mirror[chars[j]] or chars[j] end
        else
            for j = 1, #chars do out[#out + 1] = mirror[chars[j]] or chars[j] end
        end
    end
    return table.concat(out)
end

-- ─── Register Hebrew language ─────────────────────────────────────────────────

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
    },
})

-- Add RTL-specific properties after registration
-- (SMODS.Language doesn't expose rtl/skip_crt/button natively)
local function patch_he_lang()
    if G and G.LANGUAGES and G.LANGUAGES['he'] then
        local L = G.LANGUAGES['he']
        L.skip_crt = true
        L.button = 'משוב על תרגום'
    end
end

-- Try immediately, and also hook into game start in case timing is off
patch_he_lang()

local _orig_love_load = love.load
love.load = function(...)
    local r = {_orig_love_load and _orig_love_load(...)}
    patch_he_lang()
    return table.unpack(r)
end
