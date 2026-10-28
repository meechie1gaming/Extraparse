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
-- Extraparse LUA - v1.0.2 Date: 2026-10-27
--================================================================================

_addon.name     = 'Extraparse'
_addon.author   = 'Meechie'
_addon.version  = '1.0.2'
_addon.commands = {'extraparse', 'ep'}

require('pack')
local packets = require('packets')
local res = require('resources')

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

-- ==[ Timing ]================================================
local idle_timeout = 90
local cast_lead = 3
local dead_window = 60
local parse_delay = 1

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

local msg_death = set{6, 20, 113, 406, 605, 646}

local msg_ability_status = set{100, 420, 421, 424}

local msg_spell_damage = set{2, 252}

local msg_ja_damage = set{100, 110, 158, 317, 324, 522, 802}

local msg_daze = {
    [519] = 'Lethargic Daze',
    [520] = 'Sluggish Daze',
    [521] = 'Weakened Daze',
    [591] = 'Bewildered Daze',
}

local ja_categories = set{6, 14, 15}

-- ==[ State ]=================================================
local db = {}
local fights = {}
local boss_status = {}
local timeline = {}
local casts = {}
local ja_log = {}
local names_by_id = {}
local party = {}
local dead = {}
local self_pending = nil
local last_tick = 0

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
    return title((r.en:gsub(' %d+$', '')))
end

local function boss_key(name)
    return (name:gsub(' ', '_'):gsub("'", ''))
end

local function fmt(n)
    return string.format('%.1f', n)
end

local function clock(n)
    local m = math.floor(n / 60)
    return string.format('%d:%02d', m, math.floor(n - m * 60))
end

local function pct(part, total)
    return total > 0 and part / total * 100 or 0
end

local function sorted(t)
    local keys = {}
    for k in pairs(t) do keys[#keys + 1] = k end
    table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
    return keys
end

-- ==[ Party ]=================================================
local function refresh_party()
    local p = windower.ffxi.get_party()
    party = {}
    if not p then return end
    for i = 0, 5 do
        local m = p['p'..i]
        if m and m.name then
            party[m.name] = true
            if m.mob and m.mob.id then names_by_id[m.mob.id] = m.name end
        end
    end
end

local function mob_name(id)
    local m = windower.ffxi.get_mob_by_id(id)
    if m and m.name then return m.name, m end
    return names_by_id[id], nil
end

local function is_boss(m)
    return (m and m.is_npc and bosses[m.name]) and true or false
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
    local tl = timeline[name]
    if not tl then return end
    for _, rec in pairs(tl) do close_status(rec, now) end
end

local function add_cast(target, status, by, via, now)
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
    list[#list + 1] = {by = by, via = via, t = now}
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
end

local function boss_land(id, status, by, via, now, spell)
    local b = boss_status[id]
    if not b then return end
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
    rec.landings[#rec.landings + 1] = {by = by, via = via, t = now}
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

local function player_entry(r, name)
    local p = r.players[name]
    if not p then
        p = {buffs = {}, taken = {}, landed = {}, abilities = {}}
        r.players[name] = p
    end
    return p
end

local function build_result(f, finish, outcome)
    local a, b = f.start, finish
    local r = {wall = f.wall_start, length = b - a, outcome = outcome, debuffs = {}, players = {}}

    for name in pairs(f.roster) do player_entry(r, name) end

    for status, rec in pairs(boss_status[f.id] or {}) do
        local list = clip(rec, a, b)
        local up = coverage(list, a, b)
        local windows = {}
        for _, iv in ipairs(list) do
            windows[#windows + 1] = {on = iv.on - a, off = iv.off - a}
        end
        if up > 0 or #rec.landings > 0 then
            r.debuffs[status] = {seconds = up, landed = #rec.landings, windows = windows}
        end
        for _, l in ipairs(rec.landings) do
            if l.by and f.roster[l.by] then
                local off = b
                for _, iv in ipairs(list) do
                    if l.t >= iv.on - 0.01 and l.t <= iv.off then
                        off = iv.off
                        break
                    end
                end
                local p = player_entry(r, l.by)
                local entries = p.landed[status]
                if not entries then
                    entries = {}
                    p.landed[status] = entries
                end
                entries[#entries + 1] = {t = l.t - a, via = l.via, off = off - a}
            end
        end
    end

    for name in pairs(f.roster) do
        local p = player_entry(r, name)
        local tl = timeline[name] or {}
        local pc = casts[name] or {}
        local statuses = {}
        for s in pairs(tl) do statuses[s] = true end
        for s in pairs(pc) do statuses[s] = true end
        for status in pairs(statuses) do
            local rec = tl[status] or {intervals = {}}
            local list, first = clip(rec, a, b)
            local entries = pc[status] or {}
            if player_debuffs[status] then
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
                        cl[#cl + 1] = {by = c.by, via = c.via, t = c.t - a}
                    end
                end
                local up, gap = coverage(list, a, b)
                if up > 0 or #cl > 0 then
                    local drops = 0
                    for _, iv in ipairs(list) do
                        if iv.dropped then drops = drops + 1 end
                    end
                    p.buffs[status] = {seconds = up, drops = drops, gap = gap, casts = cl}
                end
            end
        end
    end

    for _, e in ipairs(ja_log) do
        if e.t >= a and e.t <= b and f.roster[e.name] then
            local p = player_entry(r, e.name)
            local list = p.abilities[e.ability]
            if not list then
                list = {}
                p.abilities[e.ability] = list
            end
            list[#list + 1] = e.t - a
        end
    end

    return r
end

-- ==[ Fights ]================================================
local function touch_boss(m, now)
    local f = fights[m.id]
    if not f then
        if m.hpp == 0 or (dead[m.id] and now - dead[m.id] < dead_window) then return end
        refresh_party()
        f = {
            id = m.id,
            name = m.name,
            key = boss_key(m.name),
            start = now,
            last = now,
            wall_start = os.time(),
            roster = {},
        }
        for n in pairs(party) do f.roster[n] = true end
        fights[m.id] = f
        boss_status[m.id] = {}
        log(m.name..' engaged.')
    end
    f.last = now
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
    fights[id] = nil
    boss_status[id] = nil
    if killed then dead[id] = finish end
    local entry = db[f.key]
    if not entry then
        entry = {name = f.name, kills = {}}
        db[f.key] = entry
    end
    entry.kills[#entry.kills + 1] = r
    log(string.format('%s %s, %s.', f.name, killed and 'defeated' or 'fight closed', clock(r.length)))
    prune()
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

local function handle_status(msg, param, ctx, tid, tname, tboss)
    local status
    if msg_landed[msg] then
        status = status_name(param)
    elseif msg_daze[msg] then
        status = msg_daze[msg]
    elseif msg_ability_status[msg] and ctx.ja and ctx.ja.status and not tboss then
        status = status_name(ctx.ja.status)
    elseif msg_spell_damage[msg] and ctx.spell and ctx.spell.status and tboss then
        status = status_name(ctx.spell.status)
    end

    if status then
        if tboss then
            if fights[tid] then boss_land(tid, status, ctx.actor, ctx.via, ctx.now, ctx.spell) end
        elseif tname and party[tname] then
            add_cast(tname, status, ctx.actor, ctx.via, ctx.now)
        end
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
        via = action_name(cat, act.param, msg1),
        ja = is_ja and res.job_abilities[act.param] or nil,
        spell = cat == 4 and res.spells[act.param] or nil,
        deaths = {},
    }

    if is_ja and ctx.via and party[actor] and next(fights) then
        ja_log[#ja_log + 1] = {name = actor, ability = ctx.via, t = now}
    end

    for i, t in ipairs(act.targets) do
        local tm = targets[i]
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
    local id = (fights[tid] and tid) or ((tid == 0 or tid == aid) and fights[aid] and aid) or nil
    if not id then return end
    local now = os.clock()
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
    if p['ID'] and p['Name'] and p['Name'] ~= '' then
        names_by_id[p['ID']] = p['Name']
    end
end

-- ==[ XML ]===================================================
local function xml_tag(s)
    s = tostring(s):gsub(' ', '_'):gsub('[^%w_%.%-]', '')
    if s == '' or s:find('^[%d%.%-]') then s = '_'..s end
    return s
end

local function xml_text(s)
    return (tostring(s):gsub('&', '&amp;'):gsub('<', '&lt;'):gsub('>', '&gt;'))
end

local function writer()
    local lines = {}
    local w = {}
    function w.open(d, tag)
        lines[#lines + 1] = string.rep('    ', d)..'<'..tag..'>'
    end
    function w.close(d, tag)
        lines[#lines + 1] = string.rep('    ', d)..'</'..tag..'>'
    end
    function w.leaf(d, tag, v)
        if v ~= nil then
            lines[#lines + 1] = string.rep('    ', d)..'<'..tag..'>'..xml_text(v)..'</'..tag..'>'
        end
    end
    function w.text()
        return table.concat(lines, '\n')
    end
    return w
end

-- ==[ XML Fight ]=============================================
local function write_fight(w, kills, total)
    w.open(2, 'fight')
    w.leaf(3, 'count', #kills)
    w.leaf(3, 'length', fmt(total))
    for i, k in ipairs(kills) do
        local tag = 'fight_'..i
        w.open(3, tag)
        w.leaf(4, 'start', os.date('%H:%M:%S', k.wall))
        w.leaf(4, 'end', os.date('%H:%M:%S', k.wall + math.floor(k.length + 0.5)))
        w.leaf(4, 'length', fmt(k.length))
        w.leaf(4, 'result', k.outcome)
        w.close(3, tag)
    end
    w.close(2, 'fight')
end

-- ==[ XML Boss Debuffs ]======================================
local function write_boss_debuffs(w, kills, total, multi)
    local agg = {}
    for fi, k in ipairs(kills) do
        for status, d in pairs(k.debuffs) do
            local a = agg[status]
            if not a then
                a = {seconds = 0, landed = 0, windows = {}}
                agg[status] = a
            end
            a.seconds = a.seconds + d.seconds
            a.landed = a.landed + d.landed
            for _, win in ipairs(d.windows) do
                a.windows[#a.windows + 1] = {fight = fi, on = win.on, off = win.off}
            end
        end
    end
    if not next(agg) then return end
    w.open(2, 'debuffs')
    for _, status in ipairs(sorted(agg)) do
        local a = agg[status]
        local tag = xml_tag(status)
        w.open(3, tag)
        w.leaf(4, 'uptime', fmt(pct(a.seconds, total)))
        w.leaf(4, 'seconds', fmt(a.seconds))
        w.leaf(4, 'landed', a.landed)
        for _, win in ipairs(a.windows) do
            w.open(4, 'window')
            if multi then w.leaf(5, 'fight', win.fight) end
            w.leaf(5, 'on', fmt(win.on))
            w.leaf(5, 'off', fmt(win.off))
            w.close(4, 'window')
        end
        w.close(3, tag)
    end
    w.close(2, 'debuffs')
end

-- ==[ XML Player Buffs ]======================================
local function write_buffs(w, per, kills, present, multi)
    local agg = {}
    for fi = 1, #kills do
        local p = per[fi]
        if p then
            for status, b in pairs(p.buffs) do
                local a = agg[status]
                if not a then
                    a = {seconds = 0, drops = 0, gap = 0, casts = {}, seen = {}}
                    agg[status] = a
                end
                a.seconds = a.seconds + b.seconds
                a.drops = a.drops + b.drops
                a.gap = math.max(a.gap, b.gap)
                a.seen[fi] = true
                for _, c in ipairs(b.casts) do
                    a.casts[#a.casts + 1] = {fight = fi, by = c.by, via = c.via, t = c.t}
                end
            end
        end
    end
    if not next(agg) then return end
    w.open(3, 'buffs')
    for _, status in ipairs(sorted(agg)) do
        local a = agg[status]
        for fi in pairs(per) do
            if not a.seen[fi] then a.gap = math.max(a.gap, kills[fi].length) end
        end
        local tag = xml_tag(status)
        w.open(4, tag)
        w.leaf(5, 'uptime', fmt(pct(a.seconds, present)))
        w.leaf(5, 'seconds', fmt(a.seconds))
        w.leaf(5, 'drops', a.drops)
        w.leaf(5, 'longest_gap', fmt(a.gap))
        for _, c in ipairs(a.casts) do
            w.open(5, 'cast')
            if multi then w.leaf(6, 'fight', c.fight) end
            w.leaf(6, 'time', fmt(c.t))
            w.leaf(6, 'by', c.by)
            w.leaf(6, 'via', c.via)
            w.close(5, 'cast')
        end
        w.close(4, tag)
    end
    w.close(3, 'buffs')
end

-- ==[ XML Debuffs Landed ]====================================
local function write_landed(w, per, kills, multi)
    local agg = {}
    for fi = 1, #kills do
        local p = per[fi]
        if p then
            for status, list in pairs(p.landed) do
                agg[status] = agg[status] or {}
                for _, l in ipairs(list) do
                    agg[status][#agg[status] + 1] = {fight = fi, t = l.t, via = l.via, off = l.off}
                end
            end
        end
    end
    if not next(agg) then return end
    w.open(3, 'debuffs_landed')
    for _, status in ipairs(sorted(agg)) do
        local list = agg[status]
        local tag = xml_tag(status)
        w.open(4, tag)
        w.leaf(5, 'count', #list)
        for _, l in ipairs(list) do
            w.open(5, 'landing')
            if multi then w.leaf(6, 'fight', l.fight) end
            w.leaf(6, 'time', fmt(l.t))
            w.leaf(6, 'via', l.via)
            w.leaf(6, 'wore_off', fmt(l.off))
            w.close(5, 'landing')
        end
        w.close(4, tag)
    end
    w.close(3, 'debuffs_landed')
end

-- ==[ XML Debuffs Taken ]=====================================
local function write_taken(w, per, kills, multi)
    local agg = {}
    for fi = 1, #kills do
        local p = per[fi]
        if p then
            for status, list in pairs(p.taken) do
                local a = agg[status]
                if not a then
                    a = {seconds = 0, longest = 0, list = {}}
                    agg[status] = a
                end
                for _, inst in ipairs(list) do
                    local len = inst.off - inst.on
                    a.seconds = a.seconds + len
                    a.longest = math.max(a.longest, len)
                    a.list[#a.list + 1] = {fight = fi, on = inst.on, off = inst.off, len = len, via = inst.via}
                end
            end
        end
    end
    if not next(agg) then return end
    w.open(3, 'debuffs_taken')
    for _, status in ipairs(sorted(agg)) do
        local a = agg[status]
        local tag = xml_tag(status)
        w.open(4, tag)
        w.leaf(5, 'count', #a.list)
        w.leaf(5, 'seconds', fmt(a.seconds))
        w.leaf(5, 'longest', fmt(a.longest))
        for _, inst in ipairs(a.list) do
            w.open(5, 'instance')
            if multi then w.leaf(6, 'fight', inst.fight) end
            w.leaf(6, 'on', fmt(inst.on))
            w.leaf(6, 'off', fmt(inst.off))
            w.leaf(6, 'length', fmt(inst.len))
            w.leaf(6, 'via', inst.via)
            w.close(5, 'instance')
        end
        w.close(4, tag)
    end
    w.close(3, 'debuffs_taken')
end

-- ==[ XML Job Abilities ]=====================================
local function write_abilities(w, per, kills, multi)
    local agg = {}
    for fi = 1, #kills do
        local p = per[fi]
        if p then
            for ability, times in pairs(p.abilities) do
                agg[ability] = agg[ability] or {}
                for _, t in ipairs(times) do
                    agg[ability][#agg[ability] + 1] = {fight = fi, t = t}
                end
            end
        end
    end
    if not next(agg) then return end
    w.open(3, 'abilities')
    for _, ability in ipairs(sorted(agg)) do
        local list = agg[ability]
        local tag = xml_tag(ability)
        w.open(4, tag)
        w.leaf(5, 'count', #list)
        for _, u in ipairs(list) do
            w.open(5, 'use')
            if multi then w.leaf(6, 'fight', u.fight) end
            w.leaf(6, 'time', fmt(u.t))
            w.close(5, 'use')
        end
        w.close(4, tag)
    end
    w.close(3, 'abilities')
end

-- ==[ XML Boss ]==============================================
local function write_boss(w, key, kills)
    local multi = #kills > 1
    local total = 0
    for _, k in ipairs(kills) do total = total + k.length end

    local boss_tag = xml_tag(key)
    w.open(1, boss_tag)
    write_fight(w, kills, total)
    write_boss_debuffs(w, kills, total, multi)

    local players = {}
    for fi, k in ipairs(kills) do
        for name, p in pairs(k.players) do
            players[name] = players[name] or {}
            players[name][fi] = p
        end
    end
    for _, name in ipairs(sorted(players)) do
        local per = players[name]
        local present = 0
        for fi in pairs(per) do present = present + kills[fi].length end
        local tag = xml_tag(name)
        w.open(2, tag)
        write_buffs(w, per, kills, present, multi)
        write_landed(w, per, kills, multi)
        write_taken(w, per, kills, multi)
        write_abilities(w, per, kills, multi)
        w.close(2, tag)
    end
    w.close(1, boss_tag)
end

-- ==[ Commands ]==============================================
local function export(name)
    name = name and (name:gsub('[\\/:%*%?"<>|]', '_')) or os.date('%Y-%m-%d')

    local data_dir = windower.addon_path..'data/'
    local base = data_dir..'export/'
    if not windower.dir_exists(data_dir) then windower.create_dir(data_dir) end
    if not windower.dir_exists(base) then windower.create_dir(base) end

    local final, n = name, 1
    while windower.file_exists(base..final..'.xml') do
        n = n + 1
        final = name..'_'..n
    end

    local now = os.clock()
    local keys = {}
    for k in pairs(db) do keys[k] = true end
    for _, f in pairs(fights) do keys[f.key] = true end

    local w = writer()
    w.open(0, 'database')
    for _, key in ipairs(sorted(keys)) do
        local kills = {}
        if db[key] then
            for _, k in ipairs(db[key].kills) do kills[#kills + 1] = k end
        end
        for _, f in pairs(fights) do
            if f.key == key then kills[#kills + 1] = build_result(f, now, 'in progress') end
        end
        write_boss(w, key, kills)
    end
    w.close(0, 'database')

    local file = io.open(base..final..'.xml', 'w+')
    if not file then
        log('Could not write '..final..'.xml')
        return
    end
    file:write(w.text())
    file:close()

    log('Exported '..final..'.xml')
end

local function reset()
    db = {}
    fights = {}
    boss_status = {}
    prune()
    log('Reset.')
    coroutine.schedule(function()
        windower.send_command('parse reset')
    end, parse_delay)
end

local function show_status()
    local any = false
    for _, f in pairs(fights) do
        any = true
        log(f.name..': in progress, '..clock(os.clock() - f.start))
    end
    for _, key in ipairs(sorted(db)) do
        any = true
        local e = db[key]
        local total = 0
        for _, k in ipairs(e.kills) do total = total + k.length end
        log(string.format('%s: %d fight%s, %s', e.name, #e.kills, #e.kills == 1 and '' or 's', clock(total)))
    end
    if not any then log('No boss data.') end
end

local function help()
    log('export [name] : write XML, named by date if no name is given')
    log('reset : clear data and run parse reset')
    log('status : list tracked boss fights')
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
    if now - last_tick < 1 then return end
    last_tick = now
    refresh_party()
    for id, f in pairs(fights) do
        for n in pairs(party) do f.roster[n] = true end
        if now - f.last > idle_timeout then end_fight(id, f.last, false) end
    end
end)

windower.register_event('zone change', function()
    local now = os.clock()
    for id, f in pairs(fights) do end_fight(id, f.last, false) end
    for name in pairs(timeline) do close_player(name, now) end
    prune()
    self_pending = now
end)

windower.register_event('load', 'login', function()
    refresh_party()
    self_pending = os.clock()
end)

windower.register_event('addon command', function(cmd, ...)
    cmd = cmd and cmd:lower() or 'help'
    local args = {...}
    if cmd == 'export' then
        export(args[1])
    elseif cmd == 'reset' then
        reset()
    elseif cmd == 'status' then
        show_status()
    else
        help()
    end
end)
