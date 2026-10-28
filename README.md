# Extraparse

Windower 4 addon for FFXI. Runs alongside Parse in Sortie and tracks what Parse doesn't: buff uptime for your whole party, debuffs on the boss, debuffs the boss puts on players, and every job ability used. Data is kept per boss, keyed by mob name the same way Parse does it, so the two exports line up.

Only you need to run it. It tracks your whole party from your client.

**Author:** Meechie
**Version:** 1.0.2

## Install

1. Copy the `Extraparse` folder into `Windower/addons/`.
2. Load Parse if it isn't already: `//lua load parse`
3. In game: `//lua load extraparse`

To load it every time, add `lua load extraparse` to `Windower/scripts/init.txt`.

## Commands

| Command | What it does |
| --- | --- |
| `//ep export` | Writes the Extraparse file under today's date, like `2026-10-27` |
| `//ep export <name>` | Same, using your own name |
| `//ep reset` | Clears all Extraparse data and runs `parse reset` |
| `//ep status` | Lists fights in progress and finished bosses with fight counts and total time |

- Export Parse separately with `//parse export` as usual. `//ep export` only writes the Extraparse file.
- `//ep` with no command shows the help list. `//extraparse` works in place of `//ep`.
- If a file with that name already exists, the new one gets `<name>_2`, `<name>_3` and so on. Nothing is overwritten.
- In a macro, use `/console ep export` and `/console ep reset`.

## Bosses Tracked

Aita, Degei, Dhartok, Gartell, Ghatjot, Leshonn, Skomora, Triboulex. Every other mob is ignored.

## How It Works

**Fight window**
- A fight starts on the first action anyone takes on the boss, or the boss takes on anyone.
- It ends when the boss dies, from the death message in the action packets. Your engaged status isn't used.
- If nothing involving the boss happens for 90 seconds (a wipe), or you zone, the fight closes as "not killed" at the last action seen.
- A dead boss can't start a new fight for 60 seconds, so late packets on the corpse are ignored.

**Buffs** (everyone in your party)
- Your own buffs come from your buff list. Everyone else's come from the party buff packet (0x076).
- For each buff: uptime %, seconds up, how many times it dropped mid-fight, and the longest gap without it.
- The longest gap counts from the pull to the first time it went up, and from the last drop to the end of the fight.
- Who cast it is filled in whenever the action packet shows it landing, including rolls and self-buff job abilities. Prebuffs show with a negative time.

**Debuffs on the boss**
- Who landed each one, with what spell or ability, when it landed and when it wore off.
- Uptime % and every window it was up.
- Steps show as their daze (Box Step is Sluggish Daze, and so on).
- Dia and Bio overwrite each other, so landing one closes the other.
- If no wear-off message is seen, it counts as up until the fight ends.

**Debuffs on players** (Amnesia, Doom, Paralysis, Silence, Sleep, Stun, Terror, Slow, Weight, and the other ailments in the Player Debuffs list)
- Each instance with when it started, when it ended and how long it lasted.
- Count, total seconds and longest instance per debuff.
- The boss ability that caused it, when the action packet shows it.

**Job abilities**
- Every job ability each party member uses during the fight, with a count and a timestamp for each use, including ones that do no damage.
- Abilities used before the pull aren't counted.

## Export Format

Laid out like Parse's export: boss, then player, then the buff, debuff or ability. Times are seconds from the start of the fight.

```xml
<database>
    <Degei>
        <fight>
            <count>1</count>
            <length>272.4</length>
            <fight_1>
                <start>21:04:33</start>
                <end>21:09:05</end>
                <length>272.4</length>
                <result>killed</result>
            </fight_1>
        </fight>
        <debuffs>
            <Dia>
                <uptime>95.2</uptime>
                <seconds>259.3</seconds>
                <landed>3</landed>
                <window>
                    <on>13.1</on>
                    <off>272.4</off>
                </window>
            </Dia>
        </debuffs>
        <Meechie>
            <buffs>
                <Haste>
                    <uptime>98.1</uptime>
                    <seconds>267.2</seconds>
                    <drops>1</drops>
                    <longest_gap>5.2</longest_gap>
                    <cast>
                        <time>-12.0</time>
                        <by>Healer</by>
                        <via>Haste II</via>
                    </cast>
                </Haste>
            </buffs>
            <debuffs_landed>...</debuffs_landed>
            <debuffs_taken>...</debuffs_taken>
            <abilities>
                <Berserk>
                    <count>3</count>
                    <use>
                        <time>0.0</time>
                    </use>
                </Berserk>
            </abilities>
        </Meechie>
    </Degei>
</database>
```

| Section | Where | What's in it |
| --- | --- | --- |
| `fight` | Under the boss | Fight count, total length, and start, end, length and result for each fight |
| `debuffs` | Under the boss | Uptime %, seconds, times landed and each window, per debuff |
| `buffs` | Under a player | Uptime %, seconds, drops, longest gap and each cast, per buff |
| `debuffs_landed` | Under a player | Each debuff that player landed on the boss: time, spell or ability, and when it wore off |
| `debuffs_taken` | Under a player | Each debuff the player had: count, seconds, longest, and every instance |
| `abilities` | Under a player | Count and time of each use, per job ability |

- `result` is `killed`, `not killed` or `in progress` (exported mid-fight).
- The boss-level sections (`fight`, `debuffs`) are lowercase and player names are capitalized, so they never collide.
- Debuffs use the game's status name. Gravity shows as `Weight` and Distract as `Evasion Down`. The spell that landed it is in `via`.
- Names with spaces use underscores, and characters XML doesn't allow in tag names are dropped (Fighter's Roll becomes `Fighters_Roll`).

## Using It With Parse

The boss names in both files are the same, so DPS for a player is their total damage from Parse divided by `fight/length` from Extraparse.

If you kill the same boss more than once before a reset, both addons merge the kills under one boss. `length` is then the total of all fights, and each timestamped entry gets a `fight` number.

## Settings

Set at the top of `Extraparse.lua`:

- `bosses`: which mob names count as bosses
- `idle_timeout`: seconds without boss actions before a fight closes as not killed (default 90)
- `cast_lead`: seconds a cast can come before the buff or debuff shows up and still be matched to it (default 3)
- `dead_window`: seconds a dead boss can't start a new fight (default 60)
- `parse_delay`: seconds after an Extraparse reset before `parse reset` runs (default 1)
- `player_debuffs`: which statuses go under `debuffs_taken` instead of `buffs`

## Limits

- Your own party only. Alliance members aren't tracked.
- Only what happens in range of your character, since that's all the game sends you.
- After loading mid-session, other players' buffs show up after their next buff change, because that's when the game sends the party buff packet.
- Data is kept in memory until you export. Reloading the addon clears it.
