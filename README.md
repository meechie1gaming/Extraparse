# Extraparse

Windower 4 addon for FFXI. An all-in-one parser for Sortie bosses: damage, defense, buff and debuff uptime, boss moves, deaths and more, for your whole party, saved as a folder of CSV tables after every run.

There's nothing to set up or remember. Load it, run Sortie, and the run is saved when you leave.

**Author:** Meechie
**Version:** 2.0.0

## Install

1. Copy the `Extraparse` folder into `Windower/addons/`.
2. In game: `//lua load extraparse`

To load it every time, add `lua load extraparse` to `Windower/scripts/init.txt`.

Parse isn't needed for Sortie bosses. Keep it loaded if you parse other content.

## How a Run Works

1. Load the addon. The HUD shows up and tracking starts.
2. Zone into Sortie. You'll see "Entered Sortie, tracking started."
3. Fight bosses as usual. Each fight starts on the first action on the boss and ends when it dies. After a 90 second lull (a wipe), the fight closes as "not killed".
4. Leave Sortie. Everything is saved to `data/runs/<date>/` and you'll see "Run saved to data/runs/2026-10-28".

- Moving between Sortie floors doesn't end the run.
- A second run the same day goes in `2026-10-28_2`, and so on. Nothing is overwritten.
- Hits, damage taken, boss moves, deaths and boss HP are written as they happen, every second. A boss's summary tables are written the moment it dies. A crash loses at most the last second, plus the summary for a fight still in progress.
- Logging out or unloading the addon also saves the run.

## HUD

During a fight:

```
Extraparse  Aita  2:31  HP 63%
Party 4.12M  27.3k DPS
 Meechie         1.42M  34%    9.4k
 Romulis         1.10M  27%    7.3k
 Kekia          812.0k  20%    5.4k
Boss: Dia III, Distract III, Geo-Frailty, Sluggish Daze 5
Missing: Romulis Haste
Dead: Bard
```

- **Boss** lists the debuffs up on the boss right now, by the spell that landed them.
- **Missing** lists melee party members without Haste or a March.
- **Dead** lists who's down.
- Between fights it shows the last fight's result.
- Drag it to move it. The position is saved.

## Command

| Command | What it does |
| --- | --- |
| `//ep report` | Posts the current or last boss fight to party chat |

In a macro: `/console ep report`. There are no other commands.

The report looks like this:

```
Extraparse | Aita 4:32 killed | Party 6.21M, 22.9k DPS
1. Meechie 2.10M 34% | 2. Romulis 1.80M 29% | 3. Kekia 1.21M 19%
Boss: Dia 97% | Geo-Frailty 95% | Evasion Down 88% | Elegy 92%
Haste: Meechie 100% | Romulis 92%
March: Meechie 98% | Romulis 95%
Deaths: Bard (Mangle)
```

## Bosses Tracked

Aita, Degei, Dhartok, Gartell, Ghatjot, Leshonn, Skomora, Triboulex. Every other mob is ignored.

## Run Folder

Every table has `boss` and `fight` columns. `fight` counts fights against that boss within the run, so a second Aita pull is fight 2. Times are seconds from the start of that fight. One folder is one run, ready to hand to a dashboard.

### Written as they happen

| File | One row per | Columns |
| --- | --- | --- |
| `hits.csv` | Damage event on a boss | time, attacker, pet, type, action, damage, crit, miss, burst, tp, packet, buffs, debuffs |
| `taken.csv` | Boss attack on a party member | time, player, type, source, damage, result, effect, buffs |
| `boss_moves.csv` | Boss TP move or spell | time, move, type, targets, players_hit, damage, effects |
| `enfeebles.csv` | Debuff attempt on a boss | time, caster, action, debuff, result |
| `deaths.csv` | Death, raise cast or get-up | time, player, event, by, detail |
| `boss_hp.csv` | Change in boss HP % | time, hpp |

### Written when a fight ends

| File | One row per | Columns |
| --- | --- | --- |
| `fights.csv` | Fight | start, end, length, result, party_damage, party_dps, deaths |
| `damage.csv` | Player per fight | damage, dps, share, then melee, ranged, WS, JA, spell, burst, skillchain, additional effect, pet and counter breakdowns (see below) |
| `defense.csv` | Player per fight | damage_taken, melee_taken, ability_taken, spell_taken, melee_attacks, hits, crits, blocks, parries, evades, shadows, anticipates, counters, ability_hits, resists, effects |
| `buff_summary.csv` | Buff per player per fight | uptime, seconds, drops, longest_gap |
| `buff_windows.csv` | Stretch a buff was up | player, buff, on, off, dropped |
| `buff_casts.csv` | Buff landing seen | time, player, buff, by, via, value |
| `debuff_summary.csv` | Boss debuff per fight | uptime, seconds, landed |
| `debuff_windows.csv` | Stretch a boss debuff was up | debuff, on, off, by, via, level |
| `debuffs_taken.csv` | Debuff on a player | player, debuff, on, off, length, via |
| `abilities.csv` | Job ability use | time, player, ability |
| `run.csv` | Run | run, start, end, length, fights, kills, deaths |

### Column notes

**hits.csv**
- `attacker` is the party member. For pets it's the owner, and `pet` has the pet's name.
- `type` is `melee`, `ranged`, `ws`, `ja`, `spell`, `skillchain`, `add_effect`, `pet_ability`, `item`, `counter`, `spikes` or `retaliation`.
- `action` is `Main`, `Off-hand`, `Kick` or `Daken` for melee. Otherwise it's the weapon skill, spell, ability or skillchain name.
- `damage` is 0 on a miss. HP drained counts as damage.
- `crit`, `miss` and `burst` are 1 or 0.
- `tp` is the TP the weapon skill went off at. It's only filled for weapon skills.
- `packet` is shared by rows from the same action: one melee round, or a weapon skill and the skillchain it closed.

**taken.csv**
- `result` is one of `hit`, `crit`, `block`, `parry`, `evade`, `shadow`, `anticipate`, `counter`, `intimidate`, `miss`, `resist`, `no_effect`, `effect` or `dispel`.
- `effect` is the debuff it put on the player.

**deaths.csv**
- `event` is `died`, `raise` or `up`.
- For `died`, `by` is the boss and `detail` is what killed them: the last thing that hit them within 10 seconds, or Doom.
- For `raise`, `by` is the caster and `detail` is the spell.
- For `up`, `detail` is the seconds they were dead.

**enfeebles.csv**
- `result` is `landed`, `resisted`, `immunobreak` or `no_effect`.
- Steps show as their daze with the level, like `Sluggish Daze 3`.

**damage.csv**
- Melee: hits, misses, crits, accuracy, crit_rate, rounds and hits_per_round.
- Ranged: hits, misses and crits.
- WS: count, misses, average, max and average TP.
- Spells: damage and casts. Bursts: count and damage.
- Skillchains: damage and count.
- Pet damage is counted in the owner's total and also shown on its own.

### Buff and Debuff Stamps

The `buffs` and `debuffs` columns in `hits.csv` and `taken.csv` show what was active at that moment, separated by `;`:

```
Chaos Roll(11);Geo Attack Boost;Haste(Haste II);March(Honor March);March(Victory March)
Dia(Dia III);Evasion Down(Distract III);Geo-Frailty;Sluggish Daze(5)
```

- The bracket shows the song or spell that gave it, the roll total, or the daze level, when it's known.
- A status with no bracket was seen, but not who or what gave it.
- Stacked copies each get their own entry, so two Marches show twice.
- Stamps show the state before the hit lands.
- Pet hits have no buffs, since pets aren't in the party buff packet.
- The stamp shows the buff is up, not how strong it is. Potency from gear and merits isn't in the packets.

### Names

- Debuffs use the game's status name. Gravity shows as `Weight` and Distract as `Evasion Down`. The `via` column has the spell.
- Geomancy bubble effects have their own status in game, so they show as `Geo Attack Boost`, `Geo Haste` and so on, separate from regular spell buffs.
- Geo bubble debuffs on the boss send no message, so they're tracked from the Geo- cast until the luopan despawns.

### Size

With stamps on, a full 8-boss run is about 10 MB. With `stamp_buffs` off it's about 1 MB.

## Settings

Set at the top of `Extraparse.lua`:

- `bosses`: which mob names count as bosses
- `sortie_zones`: zone IDs that count as Sortie (133, 189, 275)
- `idle_timeout`: seconds without boss actions before a fight closes as not killed (default 90)
- `cast_lead`: seconds a cast can come before the buff or debuff shows up and still be matched to it (default 3)
- `dead_window`: seconds a dead boss can't start a new fight (default 60)
- `flush_interval`: seconds between writes to the run folder (default 1)
- `luopan_grace`: seconds to wait for a luopan after a Geo- cast before dropping the Geo debuff (default 5)
- `line_delay`: seconds between report lines in party chat (default 1.5)
- `stamp_buffs`: fill the buffs and debuffs columns (default true)
- `hud_on`: show the HUD (default true)
- `hud_watch`: what the HUD's Missing line checks for. Each entry is a label and the statuses that count
- `melee_jobs`: which jobs the Missing line and the report's Haste and March lines cover
- `player_debuffs`: which statuses count as debuffs on players instead of buffs

The HUD position and look are saved in `data/settings.xml`.

## Limits

- Your own party only. Alliance members aren't tracked.
- Only what happens in range of your character, since that's all the game sends you.
- Other players' buffs come from the party buff packet, which can trail a change by a moment. After loading mid-run, their buffs show up after their next buff change.
- Jobs come from the party update packet, so the Missing line fills in once each member's job has been seen.
- TP at weapon skill is the highest TP seen for that player in the 3 seconds before it. Your own is exact. Other players' depends on how recently the game sent their TP.
- Geo bubble debuffs on the boss assume the boss stays inside the luopan's area. Indi- debuffs on the boss can't be seen.
