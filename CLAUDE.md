# CLAUDE.md: Historical Time-Travel RPG

A top-down, real-time action RPG (Hades-like combat on the exploration map). The player follows a missing scientist through
history: Persia → an ancient coastal city → Nalanda → wartime India, then an altered present. The game is built in Godot 4 with
GDScript, and almost all art is drawn in code (the first imported PNG is the courtyard statue). The current build is an **Era 1 (Persian) slice at Stage 8e** (the arena's combat ported into the game), plus the combat test arena beside it.
The story runs from the waystation to the cave hideout, the freed rider, the band's chief, the return to the king and the stranger's
trail in the ruins. Stage 7 adds the systems around it, one sub-stage each in the user's order:
- done: 7a inventory (the menu, items, the tuning panel); 7b objectives and quests (quest steps, the journal, the HUD layout, place
  names); 7c squad (Farnaka follows through every door); 7d save (rest spots and the menu; after it, one autosave and four slots, the Journal tab,
  fewer place names, Disband); 7e the hero's bars (HP 100, stamina 100, focus 50 and the strong lasso), the boss bar, Bread / Apple / Coins;
  7f hero level, weapon XP, enemy levels, respawning foes, the Player tab; 7g potions, rare finds, prices, pickups and drops
  (7f and 7g were done together at the user's request); 7h the shop at Scribe Nidu's stall (`shop.gd`); 7i (the user's play-test notes)
  slower stamina, the fight stage, enemies choosing the nearest target, Farnaka's HP / focus / volley / falling and the Reviving Potion,
  focus potions, giving items to companions; 7j (the user's list) journal records in the library and the cave's jail, a second
  scientist log by the ruins, the scorpion and its poison, and the death screen (pick a save to go on from); 7k (the user's list)
  focus only from hits, the journal's Enemies part (instead of "Foes slain" on the HUD), the alarm (nearby foes of the same side join
  a fight), the Antidote, a blank Map tab and the menu keys I / M / Tab / Esc; 7l (the user's play-test notes) enemies stay in a fight
  while engaged, hurt rats walk home and heal, and Datis's sword side quest with the sword (key 1). 7f-7l wait for the user's F5 play-test;
- Stage 8 (the user's request): a **combat test arena** apart from the story, to work out weapons, combos and the feel, then port what
  works into the game. 8a done: `timetravel_godot/arena/` (F6 on `arena.tscn`): the square, the spawner, cheats, weapon picker, readouts;
  8b done: the 8-way aim, Mouse 1 light / Mouse 2 heavy as named strings (fists LLL / LLH / HHH, sword LLL / LHL / HHH), the arena's own
  tuning panel (moves, enemy HP and hit damage); 8c done: the spear, the bow (unlimited arrows; H held draws; the volley earned by two
  hits and focus) and the Space block (every weapon, the bow's the weakest; the slam, the charge and stones pierce it), every combo
  naming itself; 8d done: Q is the weapon's special (a tap, 15 focus, then a 5 s cooldown; sword: a flaming flurry that burns;
  spear: a whirlwind; bow: a piercing arrow; fists: the lasso, held 0.6 s the strong one pulls every non-boss, same cost and
  cooldown) and the parry (not the bow); 8f done: combos that end in Q, named finishers (the special at 1.5 x for 10 focus, with
  its cooldown: fists LLQ / HHQ, sword LLQ / LHQ / HHQ, spear LLQ / HHQ, bow LLQ); the user approved 8b-8f;
  8e done (2026-10-30): all of it ported into the story game "for now" (every move there from the start), the menu's Combos tab
  (before System), the spear (800) and the bow (1200) at Nidu's stall; the user's choices: the strong lasso pulls bandits, the sword's
  flurry bleeds (the blade still shows fire), unlimited arrows. 8e waits for the user's F5 play-test;
- next (not started): teacher-taught moves, timing evaluation and enemy punishment. Details in `IMPROVEMENTS.md` "Next-step ideas" >
  "The next combat plan".

## Where things are
| Path | What it is |
|---|---|
| `Historical_Time_Travel_RPG_Instruction_File.md` | Design document: story, pillars, eras, enemies, combat and non-negotiable rules. It holds **decisions only**. |
| `IMPROVEMENTS.md` | Living backlog: decisions pending, design gaps, bugs, code health, tooling, next-step ideas. |
| `timetravel_godot/` | The Godot project. `README.md` there has the current state, controls, file map, tests and stage history. |
| `timetravel_godot/arena/` | The combat test arena (Stage 8): its own scene `arena.tscn`, wiring `arena.gd`, map, HUD, panel, `arena_combat.gd` (a copy of `scripts/combat.gd`, ported back at 8e), `arena_player.gd` (extends `player.gd`; empty since the 8e port, for arena-only drawings) and `arena_tuning.gd` (extends `tuning.gd`). The story game never loads it. |
| `Code/` | Image pipeline: ComfyUI AnimateDiff workflow, `make_spritesheet.py`, and `prep_prop.py` (one generated prop image -> small game PNG). See `Code/setup.md`. |
| `Sprites/StandStill/` | Generated 8-direction idle sprites (Hero, Bandit, Rat, Scientist, Scorpion). **Not used by the game yet.** |
| `Sprites/Props/` | Full-size source images for PNG props (kept outside the Godot project so they aren't imported). |
| `timetravel_godot/assets/props/` | Game-size prop PNGs made by `prep_prop.py` (currently `statue.png`). |
| `*.png` (root) | Concept art and reference images. |
| `.claude/` | Project settings, plus the Stop hook `hooks/check-docs.ps1` that enforces rule 2. |

## Running
- Godot 4.7.2 is at `C:\Users\Chittranjan\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe` (not on PATH).
- To play, import `timetravel_godot/project.godot` in the editor and press F5. Fight keys (since 8e, the same as the arena's): Mouse 1
  light, Mouse 2 heavy (the bow: held to draw), Space block (a fresh press: parry), Shift dodge, Q the weapon's special (a tap; with
  the fists the lasso, held for the strong one; after a combo's second swing, its finisher), 1 the next weapon carried.
- The combat arena: open `arena/arena.tscn` in the editor and press F6, or `& "<godot console exe>" --path timetravel_godot res://arena/arena.tscn`.
  Its own keys on top of the game's: Tab arena panel, T its tuning panel, C clear the field.
  A headless smoke run: add `--headless --quit-after 300` before the scene path.
- Tests: `powershell -ExecutionPolicy Bypass -File timetravel_godot\tests\run_all.ps1` runs both suites (`world.gd`, `fight.gd`) and prints
  one line each (`-Verbose` lists every FAIL). To run one suite: `& "<godot console exe>" --headless --fixed-fps 60 --path timetravel_godot -s tests/world.gd`.
- After adding a new PNG, import it once before headless tests can load it: `& "<godot console exe>" --headless --path timetravel_godot --import`.
- Python 3.14 (`python`) has Pillow 13 installed per-user (`pip install --user pillow`), for `Code/*.py`. Don't run it with `-I`: that hides user packages.

## Code conventions (match them)
- All tuning numbers are constants at the top of the file that owns them (`combat.gd`: `FIST_MOVES`, `SWORD_MOVES`, `SPEAR_MOVES`,
  `BOW_MOVES`, `WEAPON_KIT`, `BLEED`, `PARRY`, `BOW`, `RETICLE`, `BLOCK`, `PIERCE`, `SPECIAL`, `FINISHER`, `DODGE`, `LASSO`, `STAMINA`, `FOCUS`, `RIDER`,
  `FOE`, `ALARM`, `SIDE`, `ENGAGE`, `RAT`, `BANDIT`, `GIANT`, `CHIEF`, `SLINGER`, `SCORPION`, `POISON`, `FOE_LEVEL`, `WEAPON_XP`, `RESPAWN_CLEAR`, `DROPS`; `player.gd`: `BASE_HP`, `BASE_STAMINA`,
  `BASE_FOCUS`, `GUARD_WALK`, `DRAW_WALK`; `progress.gd`: the XP curve, `PER_LEVEL`, the caps, `WEAPONS`). Move damage and stamina, enemy HP, XP, the focus
  numbers, each weapon's block, the parry, the Q timers and the drop chances are read through `combat.gd tune` (`enemy_hp()`, `hit_dmg()`,
  `arrow_dmg()`, `xp_for()`, `stamina_cost()`, `focus_val()`, `guard()`, `drop_chance()`), which the dev tuning panel (`tuning.gd`, T)
  edits live; read them that way, not from the constants.
- The hero's growth lives in `progress.gd` (`main.progress`): his XP and level, each weapon's XP and level, and the caps, which only a
  teacher raises (`raise_cap()`, `raise_weapon_cap()`). Max HP, stamina and focus are derived (`apply_max()`: the level plus the rare finds
  carried) and never saved. Story XP is a step's or side quest's `"xp"` in `quest.gd`, given by `note()` the first time; kill XP goes
  through `progress.kill_xp()`, so it shrinks against weaker foes.
- Every planned enemy (`enemy_plan()`) comes back on re-entry or a rest (`combat.gd respawn()`), except `BOSSES`; an enemy a map adds
  during play (`spawn_enemy`, `plan_i = -1`) never does, so a scripted fight is never repeated by respawning. A save notes the dead by
  their `enemy_plan()` row, so new rows go at the end of a map's plan (the town's scorpions come after its bandits).
- A fall opens the death screen (`death.gd`), which goes on only by loading a save or a new game; a map has no respawn spot. A section
  of a suite that carries on after a fall stands the hero up with `suite.gd get_up()`.
- Damage over time (poison, since 7j) is a count on the body (`poison` / `poison_t` in `player.gd` and `rider.gd`), started by
  `combat.gd poison_body()` (an enemy table's `"poison": true` makes its lunge poison) and ticked by `_update_poison()`. On an enemy
  (the sword flurry's bleeding, since 8e) it is `combat.gd bleeding` (`_bleed()`, `_update_bleeds()`), not saved.
- HP scale (since 7e): the hero has 100 HP; an ordinary hit on him is 20 and a big boss move 40; enemy HP and the hero's damage are in tens.
  A move that costs stamina goes through `combat.gd _spend()`; a special move costs focus (its own `"focus"` number), never stamina.
- Items are data in `items.gd ITEMS` (with a 12x12 code-drawn icon in `ART`, a `"price"`, and for a rare find its `"bonus"` and `"sell"`);
  `inventory.gd` counts them. Things lying on a map are its `PICKUPS` data const (`[id, item, n, foot, look]`, built by
  `level.gd _make_pickups()`); an enemy's drops come from `combat.gd DROPS` (`level.gd drop()`). `level.gd` saves the pickups taken and
  the drops still lying, so a map never saves them itself.
- Companions are kept per era in `squad.gd` (`MATES` is their data). Their nodes move between maps only through `main.gd`
  (`_carry_squad`, `_place_home`, `squad_order`); a map asks `dialogue.squad` who is in the squad and never hides or frees a companion.
  A companion's HP, focus and `down` (fallen) live on his node (`rider.gd`) and are saved with the squad. Enemies reach companions only
  through `combat.gd targets()` / `hurt_body()`, and a fight is `rat.gd in_fight()` / `combat.gd fighting()` (spotted, or the hero struck
  first), never `after_hero()` alone. Items are applied to the hero or a companion only by `main.gd use_item()` (the Reviving Potion through
  `revive_mate()`), so the menu's tabs and E beside a fallen companion behave the same.
- Menus and panels (`menu.gd`, `tuning.gd`, `shop.gd`) use the **era-neutral style constants at the top of `menu.gd`**, the same in every
  era (the user's decision). Only the dialogue box uses parchment. The menu's keys (I Player, M Map, Tab Squad, Esc System, J Journal)
  are `main.gd _setup_input()` actions mapped to tabs in `menu.gd KEY_TABS`; the `menu` action (Tab and Esc) is what closes any panel.
  The Combos tab (8e, before System) has no key of its own.
- An enemy joining the fight raises the alarm through `rat.gd _enter()` -> `combat.gd alarm()` (`ALARM`, `SIDE`); a new enemy kind needs
  a `SIDE` entry and a `dialogue.gd FOES` entry (its journal name and description).
- An enemy decides to leave a fight only through `rat.gd _give_up()` (the chief and the slingers call it too): the leash and being stuck
  count only while it isn't `engaged()` (`combat.gd ENGAGE`). A new enemy script's `_chase` uses it rather than its own leash test.
- The weapon in hand is `combat.gd weapon`, a `WEAPON_KIT` row (since 8e): its moves (`FIST_MOVES`-style rows; a move's name is its
  tune key, unique across weapons; its `"lv"` is its `progress.gd` level bonus and `WEAPON_XP` key), its named `"strings"` (L / H /
  Q letters; Q strings with a `"fin"` are finishers), its `"block"`, `"special"` and `"hold"`. A new weapon adds a kit row, its drawing
  in `player.gd` (`_draw_swing()` / `_draw_sword_swing()` by `pose`), a `progress.gd WEAPONS` row with its `"per"` keys, and an
  `items.gd` item (how the hero gets it; `combat.has_weapon()` checks the inventory). Its tune keys come from its moves, and the menu's
  Combos tab lists it by itself. Attacks aim with `combat.gd facing()` (the 8-way `player.aim`), never `player.dir`; anything that turns
  the body from outside sets `dir` only, and the aim follows it.
- The combat arena (`arena/`, Stage 8) is the place to try combat changes. `arena/arena_combat.gd` is a **separate copy** of
  `scripts/combat.gd` (the user's choice) with the same API; arena-only code stays in `arena/` and never goes into `scripts/` (a new
  move's drawing goes in `arena_player.gd`, which extends `player.gd`, as an override). A new arena weapon is an `ARENA_WEAPONS` row
  (aliased `WEAPON_KIT` there, which `hud.gd` reads). In the arena the enemy tables are live `var` copies (`foe_table()`), so the arena's
  tuning panel can change enemy damage. Keep the "What the arena changed" list in its header current: since 8e it says what was
  ported; a change made there now is new. Porting into the game is its own step agreed with the user; a fix to `combat.gd` is not
  copied into the arena unless the user asks.
- A side quest with steps uses `quest.gd SIDE`'s `"items"` (carried parts) or `"count"` / `"kinds"` / `"of"` (kills); a person whose
  words change with it gets TALK `"flags"` rows (and `"take"` / `"give"`), never map code.
- A shop is data in `shop.gd SHOPS`, keyed by its keeper (what it sells, which item kinds it buys); prices stay in `items.gd`
  (`"price"`, `"sell"`). A TALK choice opens it with `"then": "shop_<keeper>"`, and the keeper's words go in `dialogue.gd SHOP_LINES`.
  A weapon (an item of kind "tool") is sold only once; the Buy list scrolls, so a shop can sell any number of goods.
- Enemies are `rat.gd`, or a script that extends it for a boss or a special kind (`chief.gd`, `slinger.gd`); `combat.gd _spawn_rat` picks the script by kind.
  A kind that only needs its own numbers and look stays in `rat.gd` with its own table (the scorpion: `combat.gd SCORPION`, `sprites.gd scorpion()`).
- Map layouts, NPCs, enemies, doors, use spots, signs and place names (`PLACES`) are **data consts** at the top of each map script, never
  hard-coded inside the logic.
- Story progress goes through `quest.note(event)`: the objective is driven by the events in `quest.gd STEPS` / `SIDE`. Don't set the stage
  directly from a map.
- Saving (`save.gd`): anything new that must survive a save goes into the owner's state. That means quest flags, the inventory, the
  squad, or a map's `save_state()` / `load_state()` (and its `busy()` while a scripted fight or scene runs). An enemy added during
  play is saved by `level.gd` already. A change to the save's format bumps `save.gd VERSION` and adds a step to `_upgrade()`, so the
  user's old saves still load. The hero's maximums (HP, stamina, focus) follow from the game and are not saved.
  The game autosaves (rest, doors, a new objective; `main.gd autosave()`), so anything that runs `main.tscn` saves. The suites point
  `Save.dir` at a scratch folder in `suite.gd`; a throwaway check must do the same (and delete it), so the user's saves are never touched.
- A companion the story still needs (an escort) goes in `quest.gd NEEDS`, which refuses Disband for that window. Never block it from a map.
- Place names (`PLACES`) are for well-known places only (a town, the ruins, a whole cave). A spot that only notes a quest event goes in the
  map's `NOTES` (`level.gd notes`).
- Each map is one script extending `scripts/level.gd`, registered in `main.gd` `LEVELS`, with doors, spawns and `enemy_plan()` as data.
- Art is drawn by static functions in `sprites.gd` (characters), `props.gd`, `castle_props.gd` and `cave_props.gd` (props) and `terrain.gd`
  (ground painted once; a cave's ground is painted from a floor mask by `cave_ground()`).
  Rules: dark outline, three tones, light from the top-left, y-sorted props via `level.prop()`.
  Dark maps add a `CanvasModulate` and light themselves with `level.gd point_light()` / `flicker_lights()`.
  A PNG prop is drawn from the same kind of static function with `draw_texture`; keep the texture in a static var (a local is freed after the
  one-time draw and shows as a white box), and keep a code-drawn fallback for when the file is missing.
- All spoken and written text lives in `dialogue.gd` (`PEOPLE`, `TALK`, `SCENES`, `LOGS` (the journal: kind `"log"` (the scientist),
  `"clue"` (what the hero noticed) or `"record"` (written by people of the era), an optional `"by"` line; a map's use spot notes a quest
  flag, `add_journal()` and `menu.read_log()`), `BOSSES`, `FOES` (the journal's enemy entries), `SHOP_LINES`, `SHOUTS`, `CHATTER`), and the quest steps, story flags and journal live in `quest.gd`. A TALK conversation can note a quest event (`"note"`), take items (`"take"`), be picked by quest flags (`"flags"` rows),
  hand over items (`"give"`), open a shop (`"then": "shop_<keeper>"`) and have a `"first"` version for the first time only.
- Comments are plain English and explain *why*. Keep header comments current when a file's role changes.
- Work happens in **stages** agreed with the user. Each stage lists "Not in this stage".
- Tests live in two suites only: `tests/world.gd` (maps, doors, NPCs, dialogue, scenes) and `tests/fight.gd` (combat, enemies, boss), both built on
  `tests/suite.gd`. **Don't write new tests unless the user asks.** When a change moves something a test checks (a coordinate, a count),
  update that assert in the suite rather than deleting it.

## Working rules
1. **Suggest improvements as you go.** While working on anything, look for code-health, design-gap, historical-care, UX and tooling
   improvements. Mention the important ones in your reply and add them to `IMPROVEMENTS.md` with a priority.
   Don't implement unrequested improvements without asking.
2. **Always update the .md files after a change, in the same turn.** After any change to code, tests, assets or the pipeline:
   - `timetravel_godot/README.md`: refresh the "Current state" part, and add or extend the entry under "Stage history".
   - `IMPROVEMENTS.md`: tick off what was done (with the date) and add anything new you noticed.
   - `Code/setup.md`: update it when the sprite pipeline changes.
   - `CLAUDE.md`: update it when the layout, commands or rules change.
   A Stop hook (`.claude/hooks/check-docs.ps1`) flags a turn where code is newer than every doc.
3. **The design doc holds decisions only.** Don't edit `Historical_Time_Travel_RPG_Instruction_File.md` for code changes or suggestions.
   When the user makes a design decision, write it into the design doc and remove it from section 12 "Open Decisions" and from
   `IMPROVEMENTS.md` "Decisions pending". Until then, open questions live in `IMPROVEMENTS.md`.
4. Respect the design doc's non-negotiables (section 13) and historical-care rules (pillar 6 and the per-era notes). Flag conflicts
   instead of silently working around them.
5. **Run `tests/run_all.ps1` at the end of each roadmap step** (not after every small edit), and whenever the user asks.
   Report the results honestly, including failures.
