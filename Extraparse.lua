--#   ,-.       _,---._ __  / \
--#  /  )    .-'       `./ /   \
--# (  (   ,'            `/    /|
--#  \  `-"             \'\   / |
--#   `.              ,  \ \ /  |
--#    /`.          ,'-`----Y   |
--#   (            ;        |   '
--#   |  ,-.    ,-'         |  /
--#   |  | (   |   Meechie  | /
--#   )  |  \  `.___________|/
--================================================================================
-- Extraparse LUA - v2.0.0 Date: 2026-10-28
--================================================================================

_addon.name     = 'Extraparse'
_addon.author   = 'Meechie'
_addon.version  = '2.0.0'
_addon.commands = {'extraparse', 'ep'}

require('pack')
local packets = require('packets')
local res = require('resources')
local texts = require('texts')
local config = require('config')

-- ==[ Bosses ]================================================
local bosses = {
    ['Aita'] = true,
    ['Degei'] = true,
    ['Dhartok'] = true,
    ['Gartell'] = true,
    ['Ghatjot'] = true,
    ['Leshonn'] = true,
    ['Skomora'] = true,
    ['Triboulex'] = true,
}

local sortie_zones = {
    [133] = true,
    [189] = true,
    [275] = true,
}

-- ==[ Timing ]================================================
local idle_timeout = 90
local cast_lead = 3
local dead_window = 60
local flush_interval = 1
local luopan_grace = 5
local line_delay = 1.5

-- ==[ Output ]================================================
local stamp_buffs = true

-- ==[ HUD ]===================================================
local hud_on = true

local hud_watch = {
    {'Haste', {'Haste', 'Geo Haste'}},
    {'March', {'March'}},
}

local melee_jobs = {
    WAR = true, MNK = true, THF = true, PLD = true, DRK = true,
    BST = true, RNG = true, SAM = true, NIN = true, DRG = true,
    BLU = true, COR = true, PUP = true, DNC = true, RUN = true,
}

local defaults = {
    hud = {
        pos = {x = 100, y = 300},
        bg = {alpha = 170, red = 0, green = 0, blue = 0},
        text = {size = 10, font = 'Consolas', red = 255, green = 255, blue = 255},
        padding = 4,
        flags = {draggable = true},
    },
}

-- ==[ Player Debuffs ]========================================
local player_debuffs = {
    ['Amnesia'] = true,
    ['Doom'] = true,
    ['Paralysis'] = true,
    ['Silence'] = true,
    ['Mute'] = true,
    ['Sleep'] = true,
    ['Stun'] = true,
    ['Terror'] = true,
    ['Charm'] = true,
    ['Petrification'] = true,
    ['Gradual Petrification'] = true,
    ['Poison'] = true,
    ['Blindness'] = true,
    ['Slow'] = true,
    ['Weight'] = true,
    ['Bind'] = true,
    ['Plague'] = true,
    ['Curse'] = true,
    ['Disease'] = true,
    ['Addle'] = true,
    ['Muddle'] = true,
    ['Encumbrance'] = true,
    ['Flash'] = true,
    ['Bio'] = true,
    ['Dia'] = true,
    ['Elegy'] = true,
    ['Requiem'] = true,
    ['Burn'] = true,
    ['Frost'] = true,
    ['Choke'] = true,
    ['Rasp'] = true,
    ['Shock'] = true,
    ['Drown'] = true,
    ['Weakness'] = true,
    ['Inhibit TP'] = true,
    ['Max HP Down'] = true,
    ['Attack Down'] = true,
    ['Defense Down'] = true,
    ['Evasion Down'] = true,
    ['Accuracy Down'] = true,
    ['Magic Atk. Down'] = true,
    ['Magic Def. Down'] = true,
    ['Magic Acc. Down'] = true,
    ['Magic Evasion Down'] = true,
    ['STR Down'] = true,
    ['DEX Down'] = true,
    ['VIT Down'] = true,
    ['AGI Down'] = true,
    ['INT Down'] = true,
    ['MND Down'] = true,
    ['CHR Down'] = true,
}

-- ==[ Geomancy ]==============================================
local geo_status = {[580] = true}
for id = 539, 567 do geo_status[id] = true end

-- ==[ Action Messages ]=======================================
local function set(list)
    local s = {}
    for _, v in ipairs(list) do s[v] = true end
    return s
end

local msg_landed = set{
    82, 127, 141, 160, 164, 186, 194, 203, 205, 230, 236, 237, 242, 243,
    266, 267, 268, 269, 270, 271, 272, 277, 278, 279, 280, 319, 320, 375,
    412, 645, 754, 755, 804,
}

local msg_removed = set{
    64, 83, 123, 159, 168, 204, 206, 321, 322, 341, 342, 343, 344, 350,
    378, 453, 531, 647, 805, 806,
}

local msg_death = set{6, 20, 97, 113, 406, 605, 646}

local msg_ability_status = set{100, 420, 421, 424}

local msg_spell_damage = set{2, 252}

local msg_ja_damage = set{100, 110, 158, 245, 317, 324, 379, 522, 658, 802, 803}

local msg_daze = {
    [519] = 'Lethargic Daze',
    [520] = 'Sluggish Daze',
    [521] = 'Weakened Daze',
    [591] = 'Bewildered Daze',
}

local msg_roll = set{420, 424}

local msg_resist = set{85, 284, 653, 654, 655, 656}

local msg_immunobreak = set{653, 654}

local msg_no_effect = set{75, 156, 189, 283, 323, 659}

local raise_spells = set{'Raise', 'Raise II', 'Raise III', 'Arise'}

local ja_categories = set{6, 14, 15}

-- ==[ Damage Messages ]=======================================
local msg_hit = set{
    1, 2, 67, 77, 110, 157, 185, 187, 197, 227, 252, 264, 265, 274, 317,
    352, 353, 379, 413, 522, 576, 577, 648, 650, 747, 748, 802, 803,
}

local msg_miss = set{15, 30, 31, 32, 63, 70, 158, 188, 245, 282, 324, 354, 658}

local msg_crit = set{67, 353}

local msg_burst = set{252, 265, 274, 379, 650, 747, 748, 803}

local msg_add_damage = set{161, 163, 229}

local msg_spikes = {
    [33] = 'counter',
    [44] = 'spikes',
    [536] = 'retaliation',
}

local taken_results = {
    [14] = 'counter',
    [15] = 'evade',
    [30] = 'anticipate',
    [31] = 'shadow',
    [32] = 'evade',
    [33] = 'counter',
    [63] = 'evade',
    [70] = 'parry',
    [106] = 'intimidate',
    [158] = 'miss',
    [188] = 'miss',
    [245] = 'miss',
    [282] = 'evade',
    [324] = 'miss',
    [354] = 'miss',
    [658] = 'miss',
}

local skillchains = {
    [196] = 'Skillchain',
    [223] = 'Skillchain',
    [288] = 'Light',
    [289] = 'Darkness',
    [290] = 'Gravitation',
    [291] = 'Fragmentation',
    [292] = 'Distortion',
    [293] = 'Fusion',
    [294] = 'Compression',
    [295] = 'Liquefaction',
    [296] = 'Induration',
    [297] = 'Reverberation',
    [298] = 'Transfixion',
    [299] = 'Scission',
    [300] = 'Detonation',
    [301] = 'Impaction',
    [302] = 'Cosmic Elucidation',
    [732] = 'Universal Enlightenment',
    [767] = 'Radiance',
    [768] = 'Umbra',
}

local melee_hands = {
    [0] = 'Main',
    [1] = 'Off-hand',
    [2] = 'Kick',
    [3] = 'Kick',
    [4] = 'Daken',
}

-- ==[ Tables ]================================================
local tables = {
    hits = {'boss', 'fight', 'time', 'attacker', 'pet', 'type', 'action', 'damage', 'crit', 'miss', 'burst', 'tp', 'packet', 'buffs', 'debuffs'},
    taken = {'boss', 'fight', 'time', 'player', 'type', 'source', 'damage', 'result', 'effect', 'buffs'},
    boss_moves = {'boss', 'fight', 'time', 'move', 'type', 'targets', 'players_hit', 'damage', 'effects'},
    enfeebles = {'boss', 'fight', 'time', 'caster', 'action', 'debuff', 'result'},
    deaths = {'boss', 'fight', 'time', 'player', 'event', 'by', 'detail'},
    boss_hp = {'boss', 'fight', 'time', 'hpp'},
    fights = {'boss', 'fight', 'start', 'end', 'length', 'result', 'party_damage', 'party_dps', 'deaths'},
    damage = {
        'boss', 'fight', 'player', 'damage', 'dps', 'share',
        'melee', 'melee_hits', 'melee_misses', 'melee_crits', 'accuracy', 'crit_rate', 'rounds', 'hits_per_round',
        'ranged', 'ranged_hits', 'ranged_misses', 'ranged_crits',
        'ws', 'ws_count', 'ws_misses', 'ws_avg', 'ws_max', 'ws_avg_tp',
        'ja', 'spell', 'spells', 'bursts', 'burst_damage', 'skillchain', 'skillchains',
        'add_effect', 'pet', 'counter', 'other',
    },
    defense = {
        'boss', 'fight', 'player', 'damage_taken', 'melee_taken', 'ability_taken', 'spell_taken',
        'melee_attacks', 'hits', 'crits', 'blocks', 'parries', 'evades', 'shadows', 'anticipates', 'counters',
        'ability_hits', 'resists', 'effects',
    },
    buff_summary = {'boss', 'fight', 'player', 'buff', 'uptime', 'seconds', 'drops', 'longest_gap'},
    buff_windows = {'boss', 'fight', 'player', 'buff', 'on', 'off', 'dropped'},
    buff_casts = {'boss', 'fight', 'time', 'player', 'buff', 'by', 'via', 'value'},
    debuff_summary = {'boss', 'fight', 'debuff', 'uptime', 'seconds', 'landed'},
    debuff_windows = {'boss', 'fight', 'debuff', 'on', 'off', 'by', 'via', 'level'},
    debuffs_taken = {'boss', 'fight', 'player', 'debuff', 'on', 'off', 'length', 'via'},
    abilities = {'boss', 'fight', 'time', 'player', 'ability'},
    run = {'run', 'start', 'end', 'length', 'fights', 'kills', 'deaths'},
}

-- ==[ State ]=================================================
local settings = config.load(defaults)
local db = {}
local fights = {}
local boss_status = {}
local timeline = {}
local casts = {}
local ja_log = {}
local names_by_id = {}
local party = {}
local party_mobs = {}
local pet_owner = {}
local jobs = {}
local tp_hist = {}
local current = {}
local buff_stamps = {}
local boss_stamps = {}
local luopans = {}
local dead = {}
local dead_players = {}
local last_hit_on = {}
local last_view = nil
local self_pending = nil
local last_tick = 0
local last_flush = 0
local last_tp = 0
local packet_seq = 0
local bufs = {}
local made = {}
local run_dir = nil
local run_name = nil
local run_wall = os.time()
local hud = nil
local update_hud

-- ==[ Helpers ]===============================================
local function log(text)
    windower.add_to_chat(207, '[Extraparse] '..text)
end

local function title(s)
    if s:lower() == s then
        s = s:gsub("(%a)([%w']*)", function(a, b) return a:upper()..b end)
    end
    return s
end

local function status_name(id)
    local r = id and res.buffs[id]
    if not r or not r.en then return nil end
    local name = title((r.en:gsub(' %d+$', '')))
    if geo_status[id] then name = 'Geo '..name end
    return name
end

local function is_player_debuff(status)
    return player_debuffs[status] or player_debuffs[(status:gsub('^Geo ', ''))] or false
end

local function boss_key(name)
    return (name:gsub(' ', '_'):gsub("'", ''))
end

local function f1(n)
    return string.format('%.1f', n)
end

local function f2(n)
    return string.format('%.2f', n)
end

local function f0(n)
    return string.format('%.0f', n)
end

local function clock(n)
    local m = math.floor(n / 60)
    return string.format('%d:%02d', m, math.floor(n - m * 60))
end

local function pct(part, total)
    return total > 0 and part / total * 100 or 0
end

local function per(part, total)
    return total > 0 and part / total or 0
end

local function short(n)
    if n >= 1000000 then return string.format('%.2fM', n / 1000000) end
    if n >= 1000 then return string.format('%.1fk', n / 1000) end
    return string.format('%d', math.floor(n))
end

local function sorted(t)
    local keys = {}
    for k in pairs(t) do keys[#keys + 1] = k end
    table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
    return keys
end

-- ==[ Run Files ]=============================================
local function csv(v)
    if v == nil then return '' end
    v = tostring(v)
    if v:find('[,"\r\n]') then v = '"'..(v:gsub('"', '""'))..'"' end
    return v
end

local function put(name, ...)
    local n = select('#', ...)
    local out = {}
    for i = 1, n do out[i] = csv((select(i, ...))) end
    local b = bufs[name]
    if not b then
        b = {}
        bufs[name] = b
    end
    b[#b + 1] = table.concat(out, ',')
end

local function ensure_run()
    if run_dir then return end
    local data_dir = windower.addon_path..'data/'
    local runs_dir = data_dir..'runs/'
    if not windower.dir_exists(data_dir) then windower.create_dir(data_dir) end
    if not windower.dir_exists(runs_dir) then windower.create_dir(runs_dir) end
    local name = os.date('%Y-%m-%d')
    local final, n = name, 1
    while windower.dir_exists(runs_dir..final) do
        n = n + 1
        final = name..'_'..n
    end
    windower.create_dir(runs_dir..final)
    run_dir = runs_dir..final..'/'
    run_name = final
    made = {}
    log('Saving this run to data/runs/'..final)
end

local function flush_all()
    local any = false
    for _, b in pairs(bufs) do
        if #b > 0 then
            any = true
            break
        end
    end
    if not any then return end
    ensure_run()
    for name, b in pairs(bufs) do
        if #b > 0 then
            local file = io.open(run_dir..name..'.csv', 'a')
            if file then
                if not made[name] then
                    file:write(table.concat(tables[name], ','), '\n')
                    made[name] = true
                end
                file:write(table.concat(b, '\n'), '\n')
                file:close()
            elseif not made['!'..name] then
                made['!'..name] = true
                log('Could not write '..name..'.csv')
            end
            bufs[name] = {}
        end
    end
end

-- ==[ Party ]=================================================
local function refresh_party()
    local p = windower.ffxi.get_party()
    party = {}
    party_mobs = {}
    pet_owner = {}
    if not p then return end
    for i = 0, 5 do
        local m = p['p'..i]
        if m and m.name then
            party[m.name] = m
            if m.mob then
                party_mobs[m.name] = m.mob
                if m.mob.id then names_by_id[m.mob.id] = m.name end
                if m.mob.pet_index then pet_owner[m.mob.pet_index] = m.name end
            end
        end
    end
    local me = windower.ffxi.get_player()
    if me and me.name and me.main_job then jobs[me.name] = me.main_job end
end

local function mob_name(id)
    local m = windower.ffxi.get_mob_by_id(id)
    if m and m.name then return m.name, m end
    return names_by_id[id], nil
end

local function is_boss(m)
    return (m and m.is_npc and bosses[m.name]) and true or false
end

local function is_melee(name)
    return jobs[name] and melee_jobs[jobs[name]] or false
end

-- ==[ TP ]====================================================
local function tp_sample(name, tp, now)
    local h = tp_hist[name]
    if not h then
        h = {}
        tp_hist[name] = h
    end
    local last = h[#h]
    if last and last.tp == tp then return end
    h[#h + 1] = {t = now, tp = tp}
    if #h > 8 then table.remove(h, 1) end
end

local function tp_at(name, now)
    local h = tp_hist[name]
    if not h or #h == 0 then return nil end
    local best
    for i = #h, 1, -1 do
        local e = h[i]
        if e.t <= now then
            best = math.max(best or 0, e.tp)
            if e.t < now - 3 then break end
        end
    end
    return best
end

-- ==[ Buff Timeline ]=========================================
local function close_status(rec, now)
    if rec.open then
        rec.intervals[#rec.intervals + 1] = {rec.open, now}
        rec.open = nil
    end
end

local function sync_buffs(name, ids, now)
    local present = {}
    for _, id in ipairs(ids) do
        if id ~= 255 then
            local n = status_name(id)
            if n then present[n] = true end
        end
    end
    current[name] = ids
    buff_stamps[name] = nil
    local tl = timeline[name]
    if not tl then
        tl = {}
        timeline[name] = tl
    end
    for n, rec in pairs(tl) do
        if not present[n] then close_status(rec, now) end
    end
    for n in pairs(present) do
        local rec = tl[n]
        if not rec then
            rec = {intervals = {}}
            tl[n] = rec
        end
        if not rec.open then rec.open = now end
    end
end

local function close_player(name, now)
    current[name] = nil
    buff_stamps[name] = nil
    local tl = timeline[name]
    if not tl then return end
    for _, rec in pairs(tl) do close_status(rec, now) end
end

local function add_cast(target, status, by, via, now, value)
    buff_stamps[target] = nil
    local c = casts[target]
    if not c then
        c = {}
        casts[target] = c
    end
    local list = c[status]
    if not list then
        list = {}
        c[status] = list
    end
    list[#list + 1] = {by = by, via = via, t = now, value = value}
end

local function sync_self(now)
    local me = windower.ffxi.get_player()
    if me and me.name then
        sync_buffs(me.name, me.buffs or {}, now)
    end
end

-- ==[ Boss Debuffs ]==========================================
local function boss_remove(id, status, now)
    local b = boss_status[id]
    local rec = b and b[status]
    if rec then close_status(rec, now) end
    boss_stamps[id] = nil
end

local function boss_land(id, status, by, via, now, spell, level)
    local b = boss_status[id]
    if not b then return end
    boss_stamps[id] = nil
    if spell and spell.overwrites then
        for _, sid in pairs(spell.overwrites) do
            local s = res.spells[sid]
            local other = s and s.status and status_name(s.status)
            if other and other ~= status then boss_remove(id, other, now) end
        end
    end
    local rec = b[status]
    if not rec then
        rec = {intervals = {}, landings = {}}
        b[status] = rec
    end
    if not rec.open then rec.open = now end
    rec.landings[#rec.landings + 1] = {by = by, via = via, t = now, level = level}
end

-- ==[ Stamps ]================================================
local function detail(e, status)
    if e.value then return tostring(e.value) end
    if e.level then return tostring(e.level) end
    if e.via and e.via ~= status then return e.via end
end

local function buff_stamp(name)
    local s = buff_stamps[name]
    if s then return s end
    local count, order = {}, {}
    for _, id in ipairs(current[name] or {}) do
        local n = id ~= 255 and status_name(id)
        if n then
            if not count[n] then
                count[n] = 0
                order[#order + 1] = n
            end
            count[n] = count[n] + 1
        end
    end
    table.sort(order)
    local out = {}
    local pc = casts[name] or {}
    for _, n in ipairs(order) do
        local details, seen = {}, {}
        local list = pc[n] or {}
        for i = #list, 1, -1 do
            if #details >= count[n] then break end
            local e = list[i]
            local key = e.via or ''
            if not seen[key] then
                seen[key] = true
                details[#details + 1] = detail(e, n) or false
            end
        end
        for i = 1, count[n] do
            local d = details[i]
            out[#out + 1] = d and (n..'('..d..')') or n
        end
    end
    s = table.concat(out, ';')
    buff_stamps[name] = s
    return s
end

local function debuff_stamp(id)
    local s = boss_stamps[id]
    if s then return s end
    local b = boss_status[id] or {}
    local out = {}
    for _, status in ipairs(sorted(b)) do
        local rec = b[status]
        if rec.open then
            local l = rec.landings[#rec.landings]
            local d = l and detail(l, status)
            out[#out + 1] = d and (status..'('..d..')') or status
        end
    end
    s = table.concat(out, ';')
    boss_stamps[id] = s
    return s
end

-- ==[ Fight Results ]=========================================
local function clip(rec, a, b)
    local out, first = {}, nil
    local function add(on, off, closed)
        if off > a and on < b then
            out[#out + 1] = {
                on = math.max(on, a),
                off = math.min(off, b),
                raw_on = on,
                dropped = closed and off < b,
            }
            if not first or on < first then first = on end
        end
    end
    for _, iv in ipairs(rec.intervals) do add(iv[1], iv[2], true) end
    if rec.open then add(rec.open, math.huge, false) end
    table.sort(out, function(x, y) return x.on < y.on end)
    return out, first
end

local function coverage(list, a, b)
    local up, gap, cursor = 0, 0, a
    for _, iv in ipairs(list) do
        if iv.on > cursor then gap = math.max(gap, iv.on - cursor) end
        if iv.off > cursor then
            up = up + iv.off - math.max(iv.on, cursor)
            cursor = iv.off
        end
    end
    gap = math.max(gap, b - cursor)
    return up, gap
end

local function build_result(f, finish, outcome)
    local a, b = f.start, finish
    local r = {wall = f.wall_start, length = b - a, outcome = outcome, debuffs = {}, players = {}}

    for status, rec in pairs(boss_status[f.id] or {}) do
        local list = clip(rec, a, b)
        local up = coverage(list, a, b)
        local windows = {}
        for _, iv in ipairs(list) do
            local src
            for _, l in ipairs(rec.landings) do
                if l.t <= iv.raw_on + 0.01 then src = l end
            end
            windows[#windows + 1] = {
                on = iv.on - a,
                off = iv.off - a,
                by = src and src.by,
                via = src and src.via,
                level = src and src.level,
            }
        end
        if up > 0 or #rec.landings > 0 then
            r.debuffs[status] = {seconds = up, landed = #rec.landings, windows = windows}
        end
    end

    for name in pairs(f.roster) do
        local p = {buffs = {}, taken = {}, abilities = {}}
        r.players[name] = p
        local tl = timeline[name] or {}
        local pc = casts[name] or {}
        local statuses = {}
        for s in pairs(tl) do statuses[s] = true end
        for s in pairs(pc) do statuses[s] = true end
        for status in pairs(statuses) do
            local rec = tl[status] or {intervals = {}}
            local list, first = clip(rec, a, b)
            local entries = pc[status] or {}
            if is_player_debuff(status) then
                local inst = {}
                for _, iv in ipairs(list) do
                    local via
                    for _, c in ipairs(entries) do
                        if math.abs(c.t - iv.raw_on) <= cast_lead then
                            via = c.via
                            break
                        end
                    end
                    inst[#inst + 1] = {on = iv.on - a, off = iv.off - a, via = via}
                end
                if #inst > 0 then p.taken[status] = inst end
            else
                local from = math.min(first or a, a) - cast_lead
                local cl = {}
                for _, c in ipairs(entries) do
                    if c.t >= from and c.t <= b then
                        cl[#cl + 1] = {by = c.by, via = c.via, value = c.value, t = c.t - a}
                    end
                end
                local up, gap = coverage(list, a, b)
                if up > 0 or #cl > 0 then
                    local drops, windows = 0, {}
                    for _, iv in ipairs(list) do
                        if iv.dropped then drops = drops + 1 end
                        windows[#windows + 1] = {on = iv.on - a, off = iv.off - a, dropped = iv.dropped}
                    end
                    p.buffs[status] = {seconds = up, drops = drops, gap = gap, casts = cl, windows = windows}
                end
            end
        end
    end

    for _, e in ipairs(ja_log) do
        if e.t >= a and e.t <= b and r.players[e.name] then
            local list = r.players[e.name].abilities
            list[#list + 1] = {t = e.t - a, ability = e.ability}
        end
    end

    return r
end

-- ==[ Fight Files ]===========================================
local function party_total(f)
    local total = 0
    for _, s in pairs(f.stats) do total = total + s.damage end
    return total
end

local function write_damage(f, len, total)
    for _, name in ipairs(sorted(f.stats)) do
        local s = f.stats[name]
        local swings = s.melee_hits + s.melee_misses
        put('damage', f.key, f.index, name, s.damage, f0(per(s.damage, len)), f1(pct(s.damage, total)),
            s.melee, s.melee_hits, s.melee_misses, s.melee_crits, f1(pct(s.melee_hits, swings)), f1(pct(s.melee_crits, s.melee_hits)),
            s.rounds, f2(per(s.swings, s.rounds)),
            s.ranged, s.ranged_hits, s.ranged_misses, s.ranged_crits,
            s.ws, s.ws_count, s.ws_misses, f0(per(s.ws, s.ws_count)), s.ws_max, f0(per(s.ws_tp, s.ws_tp_count)),
            s.ja, s.spell, s.spells, s.bursts, s.burst_damage, s.skillchain, s.skillchains,
            s.add_effect, s.pet, s.counter, s.other)
    end
end

local function write_defense(f)
    for _, name in ipairs(sorted(f.def)) do
        local d = f.def[name]
        put('defense', f.key, f.index, name, d.taken, d.melee_taken, d.ability_taken, d.spell_taken,
            d.melee_attacks, d.hits, d.crits, d.blocks, d.parries, d.evades, d.shadows, d.anticipates, d.counters,
            d.ability_hits, d.resists, d.effects)
    end
end

local function write_debuffs(f, r)
    for _, status in ipairs(sorted(r.debuffs)) do
        local d = r.debuffs[status]
        put('debuff_summary', f.key, f.index, status, f1(pct(d.seconds, r.length)), f1(d.seconds), d.landed)
        for _, w in ipairs(d.windows) do
            put('debuff_windows', f.key, f.index, status, f1(w.on), f1(w.off), w.by, w.via, w.level)
        end
    end
end

local function write_players(f, r)
    for _, name in ipairs(sorted(r.players)) do
        local p = r.players[name]
        for _, status in ipairs(sorted(p.buffs)) do
            local b = p.buffs[status]
            put('buff_summary', f.key, f.index, name, status, f1(pct(b.seconds, r.length)), f1(b.seconds), b.drops, f1(b.gap))
            for _, w in ipairs(b.windows) do
                put('buff_windows', f.key, f.index, name, status, f1(w.on), f1(w.off), w.dropped and 1 or 0)
            end
            for _, c in ipairs(b.casts) do
                put('buff_casts', f.key, f.index, f1(c.t), name, status, c.by, c.via, c.value)
            end
        end
        for _, status in ipairs(sorted(p.taken)) do
            for _, inst in ipairs(p.taken[status]) do
                put('debuffs_taken', f.key, f.index, name, status, f1(inst.on), f1(inst.off), f1(inst.off - inst.on), inst.via)
            end
        end
        for _, u in ipairs(p.abilities) do
            put('abilities', f.key, f.index, f1(u.t), name, u.ability)
        end
    end
end

local function write_fight(f, r)
    local total = party_total(f)
    local len = r.length
    put('fights', f.key, f.index, os.date('%H:%M:%S', r.wall), os.date('%H:%M:%S', r.wall + math.floor(len + 0.5)),
        f1(len), r.outcome, total, f0(per(total, len)), #f.deaths)
    write_damage(f, len, total)
    write_defense(f)
    write_debuffs(f, r)
    write_players(f, r)
end

-- ==[ Fights ]================================================
local function touch_boss(m, now)
    local f = fights[m.id]
    if not f then
        if m.hpp == 0 or (dead[m.id] and now - dead[m.id] < dead_window) then return end
        refresh_party()
        local key = boss_key(m.name)
        local index = db[key] and #db[key].kills or 0
        for _, g in pairs(fights) do
            if g.key == key then index = index + 1 end
        end
        f = {
            id = m.id,
            name = m.name,
            key = key,
            index = index + 1,
            start = now,
            last = now,
            wall_start = os.time(),
            roster = {},
            stats = {},
            def = {},
            deaths = {},
        }
        for n in pairs(party) do f.roster[n] = true end
        fights[m.id] = f
        boss_status[m.id] = {}
        log(m.name..' engaged.')
    end
    f.last = now
end

local function current_fight()
    local best
    for _, f in pairs(fights) do
        if not best or f.last > best.last then best = f end
    end
    return best
end

local function prune()
    if next(fights) then return end
    local now = os.clock()
    for _, tl in pairs(timeline) do
        for status, rec in pairs(tl) do
            rec.intervals = {}
            if not rec.open then tl[status] = nil end
        end
    end
    for name, c in pairs(casts) do
        for status, list in pairs(c) do
            local rec = timeline[name] and timeline[name][status]
            local keep = now - 30
            if rec and rec.open then keep = math.min(rec.open - cast_lead, keep) end
            local kept = {}
            for _, e in ipairs(list) do
                if e.t >= keep then kept[#kept + 1] = e end
            end
            c[status] = #kept > 0 and kept or nil
        end
    end
    ja_log = {}
end

local function end_fight(id, finish, killed)
    local f = fights[id]
    if not f then return end
    for _, rec in pairs(boss_status[id] or {}) do close_status(rec, finish) end
    local r = build_result(f, finish, killed and 'killed' or 'not killed')
    r.deaths = #f.deaths
    write_fight(f, r)
    fights[id] = nil
    boss_status[id] = nil
    boss_stamps[id] = nil
    if killed then dead[id] = finish end
    local entry = db[f.key]
    if not entry then
        entry = {name = f.name, kills = {}}
        db[f.key] = entry
    end
    entry.kills[#entry.kills + 1] = r
    last_view = {f = f, r = r}
    log(string.format('%s %s, %s.', f.name, killed and 'defeated' or 'fight closed', clock(r.length)))
    flush_all()
    prune()
    if update_hud then update_hud() end
end

-- ==[ Damage Dealt ]==========================================
local function stat(f, name)
    local s = f.stats[name]
    if not s then
        s = {
            damage = 0, melee = 0, melee_hits = 0, melee_misses = 0, melee_crits = 0, rounds = 0, swings = 0,
            ranged = 0, ranged_hits = 0, ranged_misses = 0, ranged_crits = 0,
            ws = 0, ws_count = 0, ws_misses = 0, ws_max = 0, ws_tp = 0, ws_tp_count = 0,
            ja = 0, spell = 0, spells = 0, bursts = 0, burst_damage = 0, skillchain = 0, skillchains = 0,
            add_effect = 0, pet = 0, counter = 0, other = 0,
        }
        f.stats[name] = s
    end
    return s
end

local function add_hit(f, now, who, pet, kind, action, damage, crit, miss, burst, tp)
    damage = damage or 0
    put('hits', f.key, f.index, f2(now - f.start), who, pet, kind, action, damage,
        crit and 1 or 0, miss and 1 or 0, burst and 1 or 0, tp, packet_seq,
        (stamp_buffs and not pet) and buff_stamp(who) or nil,
        stamp_buffs and debuff_stamp(f.id) or nil)
    local s = stat(f, who)
    s.damage = s.damage + damage
    if pet then
        s.pet = s.pet + damage
    elseif kind == 'melee' then
        if miss then
            s.melee_misses = s.melee_misses + 1
        else
            s.melee_hits = s.melee_hits + 1
            s.melee = s.melee + damage
            if crit then s.melee_crits = s.melee_crits + 1 end
        end
    elseif kind == 'ranged' then
        if miss then
            s.ranged_misses = s.ranged_misses + 1
        else
            s.ranged_hits = s.ranged_hits + 1
            s.ranged = s.ranged + damage
            if crit then s.ranged_crits = s.ranged_crits + 1 end
        end
    elseif kind == 'ws' then
        if miss then
            s.ws_misses = s.ws_misses + 1
        else
            s.ws_count = s.ws_count + 1
            s.ws = s.ws + damage
            s.ws_max = math.max(s.ws_max, damage)
        end
        if tp then
            s.ws_tp = s.ws_tp + tp
            s.ws_tp_count = s.ws_tp_count + 1
        end
    elseif kind == 'ja' then
        s.ja = s.ja + damage
    elseif kind == 'spell' then
        s.spell = s.spell + damage
        if not miss then s.spells = s.spells + 1 end
        if burst then
            s.bursts = s.bursts + 1
            s.burst_damage = s.burst_damage + damage
        end
    elseif kind == 'skillchain' then
        s.skillchain = s.skillchain + damage
        s.skillchains = s.skillchains + 1
    elseif kind == 'add_effect' then
        s.add_effect = s.add_effect + damage
    elseif kind == 'counter' or kind == 'spikes' or kind == 'retaliation' then
        s.counter = s.counter + damage
    else
        s.other = s.other + damage
    end
end

local function hit_kind(cat, msg)
    if cat == 1 then return 'melee'
    elseif cat == 2 then return 'ranged'
    elseif cat == 3 then return msg_ja_damage[msg] and 'ja' or 'ws'
    elseif cat == 4 then return 'spell'
    elseif cat == 5 then return 'item'
    elseif ja_categories[cat] then return 'ja'
    elseif cat == 11 or cat == 13 then return 'pet_ability'
    end
end

local function log_hits(act, ctx, who, pet)
    local kind = hit_kind(act.category, ctx.msg1)
    local tp = (kind == 'ws' and not pet) and tp_at(who, ctx.now) or nil
    for _, t in ipairs(act.targets) do
        local f = fights[t.id]
        if f then
            local swings = 0
            for _, a in ipairs(t.actions) do
                local msg = a.message
                if kind and (msg_hit[msg] or msg_miss[msg]) then
                    local action = ctx.via
                    if act.category == 1 then
                        action = melee_hands[a.animation] or 'Main'
                        swings = swings + 1
                    elseif msg == 157 then
                        action = 'Barrage'
                    elseif msg == 77 then
                        action = 'Sange'
                    end
                    local miss = msg_miss[msg]
                    add_hit(f, ctx.now, who, pet, kind, action, miss and 0 or a.param, msg_crit[msg], miss, msg_burst[msg], tp)
                end
                if a.has_add_effect and a.add_effect_message ~= 0 then
                    local am = a.add_effect_message
                    if skillchains[am] then
                        add_hit(f, ctx.now, who, pet, 'skillchain', skillchains[am], a.add_effect_param)
                    elseif msg_add_damage[am] and a.add_effect_param > 0 then
                        add_hit(f, ctx.now, who, pet, 'add_effect', 'Additional effect', a.add_effect_param)
                    end
                end
            end
            if swings > 0 and not pet then
                local s = stat(f, who)
                s.rounds = s.rounds + 1
                s.swings = s.swings + swings
            end
        end
    end
end

local function log_spikes(act, ctx, targets, f)
    for i, t in ipairs(act.targets) do
        local name = targets[i].name
        if name and party[name] then
            for _, a in ipairs(t.actions) do
                local kind = a.has_spike_effect and msg_spikes[a.spike_effect_message]
                if kind then
                    add_hit(f, ctx.now, name, nil, kind, (kind:gsub('^%l', string.upper)), a.spike_effect_param)
                elseif a.message == 33 and a.param > 0 then
                    add_hit(f, ctx.now, name, nil, 'counter', 'Counter', a.param)
                end
            end
        end
    end
end

-- ==[ Deaths ]================================================
local function player_died(name, now, killer, cause)
    if dead_players[name] then return end
    local f = current_fight()
    if not f then return end
    local tl = timeline[name]
    if not cause and tl and tl['Doom'] and tl['Doom'].open then cause = 'Doom' end
    local lh = last_hit_on[name]
    if not cause and lh and now - lh.t < 10 then
        cause = lh.source
        killer = killer or lh.boss
    end
    dead_players[name] = {f = f, t = now}
    f.deaths[#f.deaths + 1] = {name = name, cause = cause}
    put('deaths', f.key, f.index, f2(now - f.start), name, 'died', killer or f.name, cause)
end

local function player_up(name, now)
    local d = dead_players[name]
    if not d then return end
    dead_players[name] = nil
    put('deaths', d.f.key, d.f.index, f2(now - d.f.start), name, 'up', nil, f1(now - d.t))
end

local function log_raise(act, ctx, targets)
    if not (ctx.spell and raise_spells[ctx.spell.en]) then return end
    for i in ipairs(act.targets) do
        local name = targets[i].name
        local d = name and dead_players[name]
        if d then
            put('deaths', d.f.key, d.f.index, f2(ctx.now - d.f.start), name, 'raise', ctx.actor, ctx.spell.en)
        end
    end
end

-- ==[ Damage Taken ]==========================================
local function defense(f, name)
    local d = f.def[name]
    if not d then
        d = {
            taken = 0, melee_taken = 0, ability_taken = 0, spell_taken = 0,
            melee_attacks = 0, hits = 0, crits = 0, blocks = 0, parries = 0, evades = 0,
            shadows = 0, anticipates = 0, counters = 0, ability_hits = 0, resists = 0, effects = 0,
        }
        f.def[name] = d
    end
    return d
end

local function boss_kind(cat)
    if cat == 1 then return 'melee'
    elseif cat == 2 then return 'ranged'
    elseif cat == 4 then return 'spell'
    elseif cat == 3 or cat == 11 or cat == 13 or ja_categories[cat] then return 'ability'
    end
end

local function taken_result(kind, a)
    local msg = a.message
    if a.has_spike_effect and (a.spike_effect_message == 33 or a.spike_effect_message == 14) then return 'counter', 0 end
    if kind == 'melee' then
        if a.reaction == 12 and (msg == 1 or msg == 67) then return 'block', a.param end
        if a.reaction == 11 then return 'parry', 0 end
        if msg == 1 then return 'hit', a.param end
        if msg == 67 then return 'crit', a.param end
    end
    if taken_results[msg] then return taken_results[msg], 0 end
    if msg_hit[msg] then return 'hit', a.param end
    if msg_resist[msg] then return 'resist', 0 end
    if msg_no_effect[msg] then return 'no_effect', 0 end
    if msg_landed[msg] then return 'effect', 0, status_name(a.param) end
    if msg_removed[msg] then return 'dispel', 0, status_name(a.param) end
end

local function log_boss_action(act, ctx, targets, f)
    local kind = boss_kind(act.category)
    if not kind then return end
    local source = kind == 'melee' and 'Melee' or kind == 'ranged' and 'Ranged' or ctx.via or ('Ability '..act.param)
    local hit, total, effects = {}, 0, {}
    for i, t in ipairs(act.targets) do
        local name = targets[i].name
        local mine = name and party[name]
        for _, a in ipairs(t.actions) do
            if mine then
                local result, damage, effect = taken_result(kind, a)
                if a.has_add_effect and a.add_effect_message ~= 0 then
                    local am = a.add_effect_message
                    if msg_landed[am] then
                        effect = status_name(a.add_effect_param)
                    elseif msg_add_damage[am] then
                        damage = (damage or 0) + a.add_effect_param
                    end
                end
                if result then
                    put('taken', f.key, f.index, f2(ctx.now - f.start), name, kind, source, damage, result, effect,
                        stamp_buffs and buff_stamp(name) or nil)
                    local d = defense(f, name)
                    d.taken = d.taken + damage
                    if kind == 'melee' then
                        d.melee_taken = d.melee_taken + damage
                        d.melee_attacks = d.melee_attacks + 1
                        if result == 'hit' or result == 'crit' or result == 'block' then d.hits = d.hits + 1 end
                        if result == 'crit' then d.crits = d.crits + 1 end
                        if result == 'block' then d.blocks = d.blocks + 1 end
                        if result == 'parry' then d.parries = d.parries + 1 end
                    elseif kind == 'spell' then
                        d.spell_taken = d.spell_taken + damage
                    else
                        d.ability_taken = d.ability_taken + damage
                    end
                    if kind ~= 'melee' and damage > 0 then d.ability_hits = d.ability_hits + 1 end
                    if result == 'evade' then d.evades = d.evades + 1 end
                    if result == 'shadow' then d.shadows = d.shadows + 1 end
                    if result == 'anticipate' then d.anticipates = d.anticipates + 1 end
                    if result == 'counter' then d.counters = d.counters + 1 end
                    if result == 'resist' then d.resists = d.resists + 1 end
                    if effect then d.effects = d.effects + 1 end
                    if damage > 0 then
                        last_hit_on[name] = {t = ctx.now, source = source, boss = f.name}
                        total = total + damage
                    end
                    if damage > 0 or effect then hit[name] = true end
                end
                if effect then effects[effect] = true end
                if msg_death[a.message] then player_died(name, ctx.now, f.name, source) end
            elseif msg_landed[a.message] then
                local s = status_name(a.param)
                if s then effects[s] = true end
            end
        end
    end
    if kind ~= 'melee' then
        put('boss_moves', f.key, f.index, f2(ctx.now - f.start), source, kind, #act.targets,
            table.concat(sorted(hit), ';'), total, table.concat(sorted(effects), ';'))
    end
    log_spikes(act, ctx, targets, f)
end

-- ==[ Luopans ]===============================================
local function geo_cast(ctx, tid)
    local old = luopans[ctx.actor]
    if old then boss_remove(old.boss, old.status, ctx.now) end
    boss_land(tid, ctx.spell.en, ctx.actor, ctx.spell.en, ctx.now)
    luopans[ctx.actor] = {boss = tid, status = ctx.spell.en, t = ctx.now}
end

local function check_luopans(now)
    for owner, l in pairs(luopans) do
        local m = party_mobs[owner]
        local out = m and m.pet_index
        if out then l.seen = true end
        if not boss_status[l.boss] then
            luopans[owner] = nil
        elseif (l.seen and not out) or (not l.seen and now - l.t > luopan_grace) then
            boss_remove(l.boss, l.status, now)
            luopans[owner] = nil
        end
    end
end

-- ==[ Action Packets ]========================================
local function action_name(cat, param, msg)
    local r
    if cat == 4 then
        r = res.spells[param]
    elseif ja_categories[cat] or cat == 13 then
        r = res.job_abilities[param]
    elseif cat == 3 then
        r = msg_ja_damage[msg] and res.job_abilities[param] or res.weapon_skills[param]
    elseif cat == 11 then
        r = res.monster_abilities[param]
    elseif cat == 5 then
        r = res.items[param]
    elseif cat == 1 then
        return 'Melee'
    elseif cat == 2 then
        return 'Ranged'
    end
    return r and r.en or nil
end

local function enfeeble(ctx, tid, status, result)
    local f = fights[tid]
    if f and party[ctx.actor] then
        put('enfeebles', f.key, f.index, f2(ctx.now - f.start), ctx.actor, ctx.via, status, result)
    end
end

local function handle_status(msg, param, ctx, tid, tname, tboss)
    local status, level, value
    if msg_landed[msg] then
        status = status_name(param)
    elseif msg_daze[msg] then
        status = msg_daze[msg]
        level = param
    elseif msg_ability_status[msg] and ctx.ja and ctx.ja.status and not tboss then
        status = status_name(ctx.ja.status)
        value = ctx.roll
    elseif msg_spell_damage[msg] and ctx.spell and ctx.spell.status and tboss then
        status = status_name(ctx.spell.status)
    end

    if status then
        if tboss then
            if fights[tid] then
                boss_land(tid, status, ctx.actor, ctx.via, ctx.now, ctx.spell, level)
                enfeeble(ctx, tid, level and (status..' '..level) or status, 'landed')
            end
        elseif tname and party[tname] then
            add_cast(tname, status, ctx.actor, ctx.via, ctx.now, value)
        end
    elseif tboss and (msg_resist[msg] or msg_no_effect[msg]) then
        local src = ctx.spell or ctx.ja
        local s = src and src.status and status_name(src.status) or nil
        local result = msg_immunobreak[msg] and 'immunobreak' or msg_resist[msg] and 'resisted' or 'no_effect'
        enfeeble(ctx, tid, s, result)
    elseif msg_removed[msg] then
        if tboss and fights[tid] then
            local s = status_name(param)
            if s then boss_remove(tid, s, ctx.now) end
        end
    elseif msg_death[msg] then
        if tboss and fights[tid] then ctx.deaths[tid] = true end
    end
end

local function on_action(act)
    local now = os.clock()
    local actor, amob = mob_name(act.actor_id)
    if is_boss(amob) then touch_boss(amob, now) end

    local targets = {}
    for i, t in ipairs(act.targets) do
        local tname, tmob = mob_name(t.id)
        local tboss = is_boss(tmob)
        if tboss then touch_boss(tmob, now) end
        targets[i] = {name = tname, boss = tboss}
    end

    if not actor then return end

    local first = act.targets[1] and act.targets[1].actions[1]
    local msg1 = first and first.message or 0
    local cat = act.category
    local is_ja = ja_categories[cat] or (cat == 3 and msg_ja_damage[msg1]) or false
    local ctx = {
        now = now,
        actor = actor,
        msg1 = msg1,
        via = action_name(cat, act.param, msg1),
        ja = is_ja and res.job_abilities[act.param] or nil,
        spell = cat == 4 and res.spells[act.param] or nil,
        roll = msg_roll[msg1] and first.param or nil,
        deaths = {},
    }

    if is_ja and ctx.via and party[actor] and next(fights) then
        ja_log[#ja_log + 1] = {name = actor, ability = ctx.via, t = now}
    end

    if next(fights) then
        packet_seq = packet_seq + 1
        if party[actor] then
            log_hits(act, ctx, actor, nil)
            log_raise(act, ctx, targets)
        elseif amob and amob.index and pet_owner[amob.index] then
            log_hits(act, ctx, pet_owner[amob.index], actor)
        elseif fights[act.actor_id] then
            log_boss_action(act, ctx, targets, fights[act.actor_id])
        end
    end

    local geo = ctx.spell and party[actor] and ctx.spell.type == 'Geomancy' and ctx.spell.en:find('^Geo%-')

    for i, t in ipairs(act.targets) do
        local tm = targets[i]
        if geo and tm.boss and fights[t.id] then geo_cast(ctx, t.id) end
        for _, a in ipairs(t.actions) do
            handle_status(a.message, a.param, ctx, t.id, tm.name, tm.boss)
            if a.has_add_effect and a.add_effect_message ~= 0 then
                handle_status(a.add_effect_message, a.add_effect_param, ctx, t.id, tm.name, tm.boss)
            end
        end
    end

    for id in pairs(ctx.deaths) do end_fight(id, now, true) end
end

-- ==[ Incoming Packets ]======================================
local function on_message(data)
    local p = packets.parse('incoming', data)
    local msg, tid, aid, param = p['Message'], p['Target'], p['Actor'], p['Param 1']
    local now = os.clock()
    if msg_death[msg] then
        local victim = names_by_id[tid]
        if victim and party[victim] then
            local killer = mob_name(aid)
            player_died(victim, now, killer)
            return
        end
    end
    local id = (fights[tid] and tid) or ((tid == 0 or tid == aid) and fights[aid] and aid) or nil
    if not id then return end
    if msg_death[msg] then
        if id == tid then end_fight(id, now, true) end
    elseif msg_removed[msg] then
        local s = status_name(param)
        if s then boss_remove(id, s, now) end
    elseif msg_landed[msg] then
        local s = status_name(param)
        local by = aid ~= id and mob_name(aid) or nil
        if s then boss_land(id, s, by, nil, now) end
    end
end

local function on_party_buffs(data)
    local now = os.clock()
    local seen = {}
    for i = 0, 4 do
        local base = i * 48 + 5
        local id = data:unpack('I', base)
        if id and id ~= 0 then
            local name = names_by_id[id]
            if not name then
                local index = data:unpack('H', base + 4)
                local m = windower.ffxi.get_mob_by_id(id) or windower.ffxi.get_mob_by_index(index)
                name = m and m.name
                if name then names_by_id[id] = name end
            end
            if name then
                local ids = {}
                for n = 1, 32 do
                    local low = data:byte(base + 15 + n)
                    local high = math.floor(data:byte(base + 8 + math.floor((n - 1) / 4)) / 4 ^ ((n - 1) % 4)) % 4
                    local b = low + 256 * high
                    if b ~= 255 and b ~= 0 then ids[#ids + 1] = b end
                end
                sync_buffs(name, ids, now)
                seen[name] = true
            end
        end
    end
    local me = windower.ffxi.get_player()
    local my = me and me.name
    for name in pairs(timeline) do
        if name ~= my and not seen[name] then close_player(name, now) end
    end
end

local function on_party_member(data)
    local p = packets.parse('incoming', data)
    local name = p['Name']
    if not (p['ID'] and name and name ~= '') then return end
    names_by_id[p['ID']] = name
    local job = p['Main job'] and res.jobs[p['Main job']]
    if job and job.ens and job.ens ~= 'NON' then jobs[name] = job.ens end
    local now = os.clock()
    if p['TP'] then tp_sample(name, p['TP'], now) end
    if p['HP'] == 0 and party[name] and party_mobs[name] then player_died(name, now) end
end

-- ==[ Run Control ]===========================================
local function end_run()
    for id, f in pairs(fights) do end_fight(id, f.last, false) end
    local count, kills, deaths = 0, 0, 0
    for _, e in pairs(db) do
        for _, k in ipairs(e.kills) do
            count = count + 1
            deaths = deaths + k.deaths
            if k.outcome == 'killed' then kills = kills + 1 end
        end
    end
    if count > 0 then
        local now = os.time()
        put('run', run_name, os.date('%H:%M:%S', run_wall), os.date('%H:%M:%S', now), clock(now - run_wall), count, kills, deaths)
    end
    flush_all()
    if run_dir then log('Run saved to data/runs/'..run_name) end
    db = {}
    fights = {}
    boss_status = {}
    boss_stamps = {}
    luopans = {}
    dead_players = {}
    last_hit_on = {}
    last_view = nil
    bufs = {}
    made = {}
    run_dir = nil
    run_name = nil
    packet_seq = 0
    run_wall = os.time()
    prune()
    if update_hud then update_hud() end
end

-- ==[ HUD ]===================================================
local function color(r, g, b, s)
    return string.format('\\cs(%d,%d,%d)%s\\cr', r, g, b, s)
end

local function ranked(stats)
    local list = {}
    for name, s in pairs(stats) do list[#list + 1] = {name = name, damage = s.damage} end
    table.sort(list, function(x, y) return x.damage > y.damage end)
    return list
end

local function debuff_line(id)
    local out = {}
    local b = boss_status[id] or {}
    for _, status in ipairs(sorted(b)) do
        local rec = b[status]
        if rec.open then
            local l = rec.landings[#rec.landings]
            if l and l.level then
                out[#out + 1] = status..' '..l.level
            else
                out[#out + 1] = (l and l.via) or status
            end
        end
    end
    return table.concat(out, ', ')
end

local function missing_line()
    local out = {}
    for _, name in ipairs(sorted(party)) do
        if is_melee(name) and current[name] then
            local have = {}
            for _, id in ipairs(current[name]) do
                local n = status_name(id)
                if n then have[n] = true end
            end
            local gone = {}
            for _, w in ipairs(hud_watch) do
                local ok = false
                for _, s in ipairs(w[2]) do
                    if have[s] then ok = true end
                end
                if not ok then gone[#gone + 1] = w[1] end
            end
            if #gone > 0 then out[#out + 1] = name..' '..table.concat(gone, '/') end
        end
    end
    return table.concat(out, ', ')
end

local function player_lines(lines, stats, len)
    local total = 0
    for _, s in pairs(stats) do total = total + s.damage end
    lines[#lines + 1] = string.format('Party %s  %s DPS', short(total), short(per(total, math.max(len, 1))))
    for _, e in ipairs(ranked(stats)) do
        lines[#lines + 1] = string.format(' %-12s %8s %3d%% %7s', e.name, short(e.damage), math.floor(pct(e.damage, total) + 0.5),
            short(per(e.damage, math.max(len, 1))))
    end
end

update_hud = function()
    if not hud then return end
    if not hud_on then
        hud:hide()
        return
    end
    local now = os.clock()
    local lines = {}
    local f = current_fight()
    if f then
        local len = now - f.start
        local m = windower.ffxi.get_mob_by_id(f.id)
        local hp = m and m.hpp and ('  HP '..m.hpp..'%') or ''
        lines[1] = color(255, 200, 80, 'Extraparse')..'  '..f.name..'  '..clock(len)..hp
        player_lines(lines, f.stats, len)
        local d = debuff_line(f.id)
        if d ~= '' then lines[#lines + 1] = 'Boss: '..d end
        local miss = missing_line()
        if miss ~= '' then lines[#lines + 1] = color(255, 110, 110, 'Missing: '..miss) end
        local down = sorted(dead_players)
        if #down > 0 then lines[#lines + 1] = color(255, 110, 110, 'Dead: '..table.concat(down, ', ')) end
    elseif last_view then
        local r = last_view.r
        lines[1] = color(255, 200, 80, 'Extraparse')..'  '..last_view.f.name..'  '..clock(r.length)..'  '..r.outcome
        player_lines(lines, last_view.f.stats, r.length)
    else
        lines[1] = color(255, 200, 80, 'Extraparse')..'  waiting for a boss'
    end
    hud:text(table.concat(lines, '\n'))
    hud:show()
end

local function build_hud()
    if hud then hud:destroy() end
    hud = texts.new('', settings.hud, settings)
    update_hud()
end

-- ==[ Report ]================================================
local function report()
    local f = current_fight()
    local r
    if f then
        r = build_result(f, os.clock(), 'in progress')
    elseif last_view then
        f, r = last_view.f, last_view.r
    else
        log('No boss fight to report yet.')
        return
    end
    local len = r.length
    local total = party_total(f)
    local lines = {}
    lines[1] = string.format('Extraparse | %s %s %s | Party %s, %s DPS', f.name, clock(len), r.outcome, short(total), short(per(total, math.max(len, 1))))

    local row = {}
    for i, e in ipairs(ranked(f.stats)) do
        row[#row + 1] = string.format('%d. %s %s %d%%', i, e.name, short(e.damage), math.floor(pct(e.damage, total) + 0.5))
        if #row == 3 then
            lines[#lines + 1] = table.concat(row, ' | ')
            row = {}
        end
    end
    if #row > 0 then lines[#lines + 1] = table.concat(row, ' | ') end

    local debuffs = {}
    for status, d in pairs(r.debuffs) do debuffs[#debuffs + 1] = {status = status, up = pct(d.seconds, len)} end
    table.sort(debuffs, function(x, y) return x.up > y.up end)
    local parts = {}
    for i = 1, math.min(6, #debuffs) do
        parts[#parts + 1] = string.format('%s %d%%', debuffs[i].status, math.floor(debuffs[i].up + 0.5))
    end
    if #parts > 0 then lines[#lines + 1] = 'Boss: '..table.concat(parts, ' | ') end

    for _, w in ipairs(hud_watch) do
        local parts = {}
        for _, name in ipairs(sorted(r.players)) do
            if is_melee(name) then
                local best = 0
                for _, s in ipairs(w[2]) do
                    local b = r.players[name].buffs[s]
                    if b then best = math.max(best, pct(b.seconds, len)) end
                end
                parts[#parts + 1] = string.format('%s %d%%', name, math.floor(best + 0.5))
            end
        end
        if #parts > 0 then lines[#lines + 1] = w[1]..': '..table.concat(parts, ' | ') end
    end

    if #f.deaths > 0 then
        local parts = {}
        for _, d in ipairs(f.deaths) do
            parts[#parts + 1] = d.cause and (d.name..' ('..d.cause..')') or d.name
        end
        lines[#lines + 1] = 'Deaths: '..table.concat(parts, ', ')
    end

    for i, line in ipairs(lines) do
        coroutine.schedule(function()
            windower.chat.input('/p '..line)
        end, 0.1 + (i - 1) * line_delay)
    end
end

-- ==[ Events ]================================================
windower.register_event('action', on_action)

windower.register_event('incoming chunk', function(id, data)
    if id == 0x029 then
        on_message(data)
    elseif id == 0x076 then
        on_party_buffs(data)
    elseif id == 0x0DD then
        on_party_member(data)
    end
end)

windower.register_event('gain buff', 'lose buff', function()
    self_pending = self_pending or os.clock()
end)

windower.register_event('prerender', function()
    local now = os.clock()
    if self_pending then
        sync_self(self_pending)
        self_pending = nil
    end
    if now - last_tp >= 0.1 then
        last_tp = now
        local me = windower.ffxi.get_player()
        if me and me.name and me.vitals then tp_sample(me.name, me.vitals.tp, now) end
    end
    if now - last_flush >= flush_interval then
        last_flush = now
        flush_all()
    end
    if now - last_tick < 1 then return end
    last_tick = now
    refresh_party()
    check_luopans(now)
    for name, m in pairs(party) do
        if party_mobs[name] then
            if m.hpp == 0 then
                player_died(name, now)
            elseif m.hpp and m.hpp > 0 and dead_players[name] then
                player_up(name, now)
            end
        end
    end
    for id, f in pairs(fights) do
        for n in pairs(party) do f.roster[n] = true end
        local m = windower.ffxi.get_mob_by_id(id)
        if m and m.hpp and m.hpp ~= f.hp_last then
            f.hp_last = m.hpp
            put('boss_hp', f.key, f.index, f2(now - f.start), m.hpp)
        end
        if now - f.last > idle_timeout then end_fight(id, f.last, false) end
    end
    update_hud()
end)

windower.register_event('zone change', function(new_id, old_id)
    local now = os.clock()
    for id, f in pairs(fights) do end_fight(id, f.last, false) end
    for name in pairs(timeline) do close_player(name, now) end
    luopans = {}
    flush_all()
    prune()
    self_pending = now
    if sortie_zones[old_id] and not sortie_zones[new_id] then
        end_run()
    elseif sortie_zones[new_id] and not sortie_zones[old_id] then
        end_run()
        log('Entered Sortie, tracking started.')
    end
end)

windower.register_event('load', 'login', function()
    refresh_party()
    self_pending = os.clock()
    local info = windower.ffxi.get_info()
    if info and info.logged_in then build_hud() end
end)

windower.register_event('logout', function()
    end_run()
    if hud then hud:hide() end
end)

windower.register_event('unload', function()
    end_run()
    if hud then hud:destroy() end
end)

windower.register_event('addon command', function(cmd)
    cmd = cmd and cmd:lower() or 'help'
    if cmd == 'report' then
        report()
    else
        log('report : post the last boss fight to party chat')
    end
end)
