# Time-Travel RPG (Godot 4)

A top-down, real-time action RPG slice for Era 1 (Achaemenid Persia) of the *Historical Time-Travel RPG*.
Design: [`../Historical_Time_Travel_RPG_Instruction_File.md`](../Historical_Time_Travel_RPG_Instruction_File.md) ·
Backlog and open questions: [`../IMPROVEMENTS.md`](../IMPROVEMENTS.md) · Working rules: [`../CLAUDE.md`](../CLAUDE.md)

**Current stage: 8e, the arena's combat in the story game (F5).** The user approved every combo change from the arena (8b-8f), so it is
now in the game too, "for now" with every move there from the start (teachers will unlock them later):
- **Keys changed:** Mouse 1 light attack, Mouse 2 heavy (the bow: hold to draw), **Space blocks** (a fresh press parries; it no longer
  attacks), Shift dodge, Q the weapon's special (with the fists the lasso; after a string's second swing, its finisher), 1 the next
  weapon carried. Attacks aim 8 ways.
- **Named strings for every weapon**, and their names float up: a finished string by its name in pale gold (L, L, H shows "Shoulder
  charge"; the letters are only in the Combos tab), a special by its name in orange ("Flaming flurry").
- **Block and parry** exactly as in the arena: part of a front hit gets through and it costs stamina; the guard breaks at 0 stamina;
  the giant's slam, the chief's charge and stones pierce it (violet warnings); a parry costs nothing, gives 8 focus and staggers the
  attacker. Bosses can't be staggered, and the bow can't parry.
- **The spear and the bow are sold at Scribe Nidu's stall** (800 and 1200 coins: costly on purpose, the user's prices). A weapon is
  carried once; key 1 cycles fists, sword, spear and bow among those you have. Each has its own weapon XP and levels (Player tab).
- **The sword's special bleeds** (the user's choice for historical care): the flurry's thrusts leave foes bleeding (4 every 0.5 s,
  6 times; red drops), while the blade still flickers with fire so the special reads apart from plain swings.
- **The strong lasso pulls bandits and slingers** too (the user's choice; the plain lasso still can't). Bosses still shrug it off.
- **A Combos tab** in the menu, before System: each weapon you have, its strings (letters in colour, name, moves), what Q and the
  finishers do, and its guard and parry, with the current numbers.
- New moves earn weapon XP by their kind (a shoulder charge like a punch, an overhead like a thrust); the hero's arrows teach the bow.
- No save change: old saves load as they are (the spear and the bow start at 0 weapon XP).

**The combat test arena** (Stages 8a-8f) stays as the place to try combat. A separate scene in the same project
(`arena/arena.tscn`; open it and press F6): a walled square with four columns and the training dummy, where any enemy or boss can be
spawned to try weapons, combos and the feel of a fight. It keeps its own copy of the combat code (`arena/arena_combat.gd`; its flurry
still burns); its hero and HUD are now the game's `player.gd` and `hud.gd` as they are. What it added (8b-8f):
- **Mouse 1 is a light attack and Mouse 2 a heavy one** (8b). Presses make named strings: the fists' LLL (punch, punch, kick), LLH
  (shoulder charge) and HHH (knee, knee, hammer fist); the sword's LLL (slash, slash, thrust), LHL (rising cut, which stuns a light
  foe) and HHH (three overheads).
- **Attacks go 8 ways**, wherever the move keys last pointed, diagonals too, as the dodge already did (8b).
- **Two new weapons (8c); key 1 cycles fists, sword, spear, bow:**
  - the **spear** has the longest reach: LLL jab, jab, long thrust; LLH sweeping arc; HHH drive, drive, charging lunge;
  - the **bow** has unlimited arrows: Mouse 1 is a quick arrow (the third of a chain is a volley of three, only if the first two
    hit something and there are 10 focus to spend); hold Mouse 2 to draw and aim (stamina drains), and let go to shoot: the further
    drawn, the harder and faster.
- **Space blocks (8c),** with every weapon (the bow's guard is the weakest). A hit from the front lets part of its damage through and costs stamina; with
  no stamina left the guard breaks. He walks slowly behind it, and stamina refills at half speed. The giant's slam, the chief's
  charge and a slinger's stone go through the guard; their warnings are drawn again in violet.
- **Every combo names itself** when its last move starts: its letters and name float over the hero ("LLH  Shoulder charge").
- **Q is the weapon's own move (8d).** With the fists it is still the lasso: hold Q 0.6 s for the strong lasso, which now pulls
  bandits too. With the other weapons a tap of Q is a special: the sword's **flaming flurry** (four thrusts that set foes burning),
  the spear's **whirlwind** (a strike all round), the bow's **piercing arrow** (goes through every foe in its line). Each special,
  and the strong lasso, costs 15 focus and is followed by a 5 s cooldown.
- **Finishers (8f):** press Q after the second swing of a combo (in the chain window, or during the swing) and the weapon's special
  ends it as a named finisher: 1.5 x damage, 10 focus, the same 5 s cooldown. Fists LLQ Lasso yank, HHQ Bull catch; sword LLQ
  Blazing flurry, LHQ Rising blaze, HHQ Inferno; spear LLQ Wide whirl, HHQ Vaulting whirl; bow LLQ Piercing volley.
- **Parry (8d):** press Space just before a hit lands (within 0.15 s) for no damage, +8 focus, and a staggered attacker. Every
  weapon but the bow; the giant's slam, the chief's charge and stones can't be parried.
- **T opens the arena's own tuning panel** (8b): every move's damage and stamina, the weapon's block, each enemy's HP and how hard it
  hits the hero.

Tab opens the arena panel (the spawner, the cheats and the hero's levels, the weapon picker with its strings and moves, the readouts).
See "The combat arena" below.
Stage 7l (the user's play-test notes), with a follow-up from the next play-test:
- **Round buttons.** The weapon in hand is a round gold-ringed badge at the bottom right (like the user's reference picture): a fist
  while unarmed, the sword after key 1, one at a time, with no name. A small round "1" is notched into its lower-right (a dark gap
  cuts the badge's ring round it, the user's mock-up); it always shows, in the same gold as the badge. Q and
  Shift at the bottom left are round too, the cooldown sweeping round inside; "Sh" now reads "Shift".
- **Same-size bars.** HP, stamina and focus are always the same length; a level-up raises the numbers, not the bars.
- **Things on the ground** pulse with a soft halo, bob a little and glint more often. Quest parts (Datis's blade and hilt) are drawn
  twice the size with a brighter halo, carry a small light on a dark map, and show their name when you come close.
- **The alarm** now calls every awake member of the enemy's group, however far (the storeroom's side-room rats used to sit out behind
  the fence), and the storeroom's fence rails no longer block sight.
**Fights.** Enemies no longer walk off in the middle of a fight. Before, a bandit pushed a little past its leash, or caught on a tent in
the cave, gave up while you stood next to it. Now the leash and getting stuck count only while an enemy isn't engaged: you are more
than 80 px from it and haven't hit it in the last 3 s. Running away still ends a chase, and 1.75x its leash from home ends any.
**Rats.** A hurt rat that ran off and hid now walks home once you have been away for 4 s, and walking home always heals, so no rat
keeps a part-empty bar.
**Datis's sword** (a side quest):
- After you have met the king, Datis asks you to find his broken sword in the storeroom. The blade is in the side room's rat nest, the
  hilt beside the giant's pile. The objective counts them (n/2).
- Bring both back. He puts the sword together and gives it to you, then asks you to cut down ten of the band (bandits, slingers, the
  chief). The objective counts them (n/10).
- Come back for 80 coins (plus the quest XP: 60 for the sword, 100 for the bounty).
- **Key 1** draws the sword or puts it away. Space then swings slash, slash, thrust: 20 / 20 / 35 damage, 15 / 15 / 25 stamina, a little
  more reach than fists. The full combo's thrust feeds focus like the kick. The Sword has its own weapon XP and levels in the Player tab.
- At the bottom right of the HUD a badge shows the weapon in hand (a box at first; round since the follow-up). The toasts sit above it.
- With the fists out, the sword hangs at his hip.
Saves go to version 6 (the weapon in hand); old saves load with the fists.
Stage 7k (the user's list). **Focus** no longer refills by itself: every hit that lands gives 3, and the kick that ends a
full punch-punch-kick gives 6 more (a rest still fills it). **"Foes slain" left the HUD**; the Journal tab now has two parts, Writings
(the logs, clues and records) and **Enemies**: each kind you have cut down, with "Slain N", and E opens its description. **The alarm**:
when an enemy joins the fight (it spots you, or you hit it first), every enemy of its side (rats, the band, the scorpions) within
150 px that can see it stops patrolling and joins too; they don't pass it on, sleeping groups and bosses keep their own wake-ups, and
a foe killed before it noticed you raises none. **The Antidote** (20 coins at Nidu's) ends a poison at once, on you or Farnaka.
**Menu keys**: I opens the Player tab, M the new **Map** tab (blank for now), Tab the Squad tab, Esc the System tab, J the journal.
With the menu open, another tab's key goes to that tab and the same key closes it; Esc always closes (after backing out of a choice).
Saves go to version 5 (the kills by kind); old saves load, with the Enemies list starting empty.
Stage 7j added new journal entries, the scorpion and the death screen. **The journal** has three new entries,
each read with E where it lies (+20 XP each). A clay tablet on Scholar Utana's desk in the hall's library, *The King's Road*: a short
record of the empire (Cyrus's conquests, Darius's satrapies and road stations, Hindush and its gold dust); it glints until read. A rider's
last note in the empty east pen of the cave's jail, *A note in the jail*: how the chief broke the riders' camp and killed them one by
one. And a second torn page from the scientist's notebook, lying by the scorpions' den in the ruins (there after the return to the king,
like the first; optional). Entries now have a third kind, **Record** (written by people of the era), beside Log and Clue.
**Scorpions**: three guard a den under a fallen slab in the west of the ruins. They are slow and short-sighted and stay near the den.
Their sting has a long wind-up (the tail arches over the back and a red line shows) and a short reach. A sting does 10 and
**poisons**: 4 HP a second for 5 s (30 in all), shown by a purple HP bar, the word "Poisoned" and a purple pulse on the hero. A new sting
starts the count again, poison never takes the last HP, and a rest cures it. Farnaka can be poisoned too. 40 HP, level 2, 15 XP; the
lasso pulls them. **The death screen** (the user's choice): when the hero falls, the screen goes black, "YOU FELL" and where come up,
and you pick the save to go on from, the autosave (picked first) or a filled slot, or New game. There is no getting up on the map any
more, so a fall costs whatever happened since that save (the autosave is written at every door, rest and new objective). Saves
are unchanged (version 4).
Stage 7i added the squad in the fight, slower stamina, and new potions (the user's play-test notes). **Stamina** now refills at 15 a
second, starting 1.2 s after your last move, so an empty bar takes about 8 s to fill. **The fight starts** only when an enemy has spotted you
(its "?" is full) or you strike first, so Farnaka no longer shoots a bandit whose "?" is still rising. **Farnaka can be hurt**: an enemy in
the fight goes after whoever is nearer, you or him (you win a close call). He has 80 HP and 50 focus, with both bars over his head
in a fight and a line under the XP on the HUD. On **Follow** he stays with you out of a fight. In a fight he moves on his own: he
backs away from enemies that close in, comes back toward you when he has no shot, never strays far, and walks back to you when it's over.
On **Wait** he holds his spot, even while he is being hit. His arrows that land fill his focus, and a full bar makes his next shot a
**volley** of three arrows. At 0 HP he **falls** and lies there, through doors too, until you use a **Reviving Potion** on him (200 coins
at Nidu's: he gets up with 10 % of his HP) or rest. To use one, press E beside him ("E Revive"), or use the menu. You can never be revived:
you fall as before. "You fell" gets him up at full HP. **Focus potions** (the game's "mana"): Small (+25, 30 coins) and Large (+50,
50 coins). **Giving items**: with a companion here, E on bread or a potion in the Player tab asks "Use on: You / Farnaka / Back". The
Squad tab has a new **Give item** command that lists your food and potions, or only the Reviving Potion while he is down. His orders are
locked while he is down. Old saves load: he comes back at full HP.
Stage 7h added the shop. Scribe Nidu, at the red-and-white stall by the training yard, now shows a coin in the bubble overhead
instead of "...". Talk to Nidu and pick "Show me your goods." to open the stall, a panel in the menu's look with two tabs. **Buy**: Bread 10,
Apple 25, Small Potion 50, Large Potion 80 coins, one per E, as many as you can pay for (prices you can't pay are dimmed). **Sell**:
the rare finds you carry, for 120 (the necklace) or 250 (the armlet); the first E asks, because the find's bonus goes with it, and the
second sells. A/D switch tabs, W/S select, Tab or Esc leaves. The first talk with Nidu still has the ledger lines; after that the talk
goes straight to the question. Also: the placeholder portraits now scale to their box, so the Squad tab's small ones no longer spill below
their frame.
With 7h the agreed roadmap (bug fixes, the cave, inventory / quests / squad / save / items / shop) is done. The next step is the user's choice.
Stage 7g added potions, rare finds, pickups and drops. Things lie on the maps and are taken by walking over them (they glint
now and then): a small potion and 15 coins in the ruins, two bread and a small potion in the storeroom, the riders' own supplies in the
cave's raided camp, and the chief's four coin bags (25 coins each). Enemies leave drops where they fall: now and then bread from a rat,
coins, bread or a small potion from a bandit or a slinger. The giant always leaves its carnelian necklace (+10 max stamina while you
carry it) and a small potion; the chief his ibex armlet (+10 max HP), a large potion and 50 coins. New items: the Small Potion (75 HP)
and the Large Potion (150 HP), drunk from the Player tab. Every item has a price for the shop, and the rare finds a price they sell
for. The king's reward is now 100 coins. Taken pickups and drops still lying on the ground are saved.
Stage 7f added the hero's level and weapon XP. XP comes from kills (less from a foe below your level: a level-3 hero gets 5 XP from a
rat), and from each story step, the side quest and each new journal entry (shown as "+40 XP"). Each level adds 10 max HP, 10 stamina
and 5 focus, and fills all three; the level stops at 10 until a teacher (none yet) raises it. Landing punches and kicks trains the
Unarmed weapon (more damage per level), catches train the Lasso (longer reach, shorter cooldown); weapons stop at level 5. The HUD
shows "Lv N" with a thin XP bar, and the boss bar the boss's level. The menu's first tab is now **Player**: your level, XP and bars on
top, your weapons with their levels, then your items. Ordinary foes come back when you walk back into their map or rest there (never
right next to you); the giant, the chief and the foes of scripted fights (the ambush, the summons, the slingers) never do. Old saves
are upgraded: the XP of the story steps and journal entries you already have is added.
Stage 7e added HP, stamina and focus. The hearts are gone: the hero has three bars at the top left. HP is 100, shown with its
number. An ordinary hit on him costs 20 and a big boss move 40. Enemy HP and the hero's damage are ten times what they were, so every fight
takes the same number of hits. Stamina is 100: a punch costs 10, the kick 20, a dodge 25 and a lasso throw 20. It refills half a second
after the last spend; at 0 a move does nothing and the bar flashes. Focus is 50 and is spent only on special moves: the first is the
**strong lasso** (hold Q, then let go; 25 focus). It reaches 1.5x as far, stuns a rat or a slinger twice as long, and binds a bandit where he
stands for 1.5 s; bosses still shrug it off. Focus fills by 3 for every hit that lands and slowly by itself. In a boss fight the giant's or
the chief's name and health show in a wide bar at the bottom of the screen. Food is now Bread (10 HP) and an Apple (30 HP), and the money is
Coins (yellow). Resting and getting up after "You fell" fill all three bars. Old saves still load: hearts become HP and the items are renamed.
Also: once you have cut the captain down and gone back to the king, his stake in the cave is empty (he is with the king's healers).)
Stage 7d (with follow-ups) added saving. There is one autosave and four save slots. The autosave is written when you rest at a
rest spot, when you go through a door, and when the main objective moves on. It waits until saving is allowed. There are two rest spots:
the town well, and the band's fire in the cave (the last stop before the chief; you can rest from any side of it). Resting fills HP,
stamina and focus. The prompt reads "E Rest"; while an enemy is still hunting you it is dimmed and says "Enemies nearby" (a wounded enemy
that runs off or cowers doesn't count). A save keeps the HP you had, so loading (also after dying) starts with that.
The Squad tab shows a card per companion on the left, and on the right his details (role, status, arrow damage, how often he shoots,
his bow) and a Commands box with icons (Follow / Wait here / Disband / Back). E opens the commands. While a slot's actions or the
commands are open, A/D move inside them instead of switching tabs, and Esc backs out first. The menu's System tab lists Autosave, Slot 1-4
(each with its place and time, or "Empty"), New game and Quit game. E on a slot opens Save here / Load / Back; the autosave can only be loaded.
Overwriting, loading and New game ask for a second E. You can't save while enemies are after you or during the ambush, the chief's fight
or a scene. Loading puts back the map and spot, HP, stamina, focus, XP, the quest and journal, the inventory, the squad, and each map as you left it.
Dead enemies stay dead, the living come back at home at full health, and the cave's cage, ambush, seal and captain stay as they were.
The follow-ups also gave the journal its own menu tab (J opens it). Only well-known places are named on the HUD now: the cave is just
"The Hill Cave". The squad order "Stop following" is now called Disband, and it is refused while the story still needs the companion:
Farnaka can't be disbanded between his rescue and the return to the king).
Stage 7c added the squad. Once freed, Farnaka stays with you for the rest of Era 1 and follows you through every door, out
of the cave, into the town, the storeroom, the courtyard and the hall. The menu's Squad tab gives him three orders: Follow; Wait here
(he holds his spot and still shoots; a door brings him along again); Disband (he goes back to his spot by the throne in the hall,
where you can talk to him to have him follow again). Talking to him while he waits or is at home gives the same choices).
Stage 7b added objectives and quests. The objective now runs the whole slice, from "Find King Rostam" through the cave to
"Search the ancient ruins north of the town", with "Free the caged rider" as an optional objective once you have seen the jail. The HUD
stacks the objective, the hero's bars and XP at the top left, and the name of each place you walk into shows at the top right. After the return to
the king, Farnaka (or the king, passing on the captain's account) points you to a stranger seen heading for the ruins. There you find boot
prints, a strange brass box and a torn page: the first scientist log. The menu's new Quests tab (J) shows the steps, the optional
objectives and the journal).
Stage 7a added the inventory (Tab, Esc or I; E eats food), Arshan's gift of food, the king's 20 coins, item toasts and the dev tuning
panel (T).
The Era 1 slice so far: the waystation town, the storeroom with its giant rat, the castle courtyard and the great hall with King Rostam, and
the cave hideout in the north-east cliff (lookouts, the raided camp, the jail with the caged rider Farnaka, who joins you as an archer and
sets off an ambush, the band's camp, and the chief's sealed boss room). When the chief falls you cut the captain Vahauka down from his stake
and go back to the king, with the rider or without him.
Next: not set yet; the agreed roadmap is finished. Candidates are in `../IMPROVEMENTS.md` (teachers, maps for sale, a quick-heal key...).

## Current state

### Run it
- **Editor:** open Godot 4 (4.7.2 is installed here; the project was started on 4.2) -> Import -> pick `project.godot` -> press F5.
- Almost everything is drawn in code. The one imported image is the courtyard statue, `assets/props/statue.png` (68x116), made from
  `../Sprites/Props/statue_src.webp` with `../Code/prep_prop.py` (see `../Code/setup.md`). If the PNG is missing, the older code-drawn statue is used.
  The viewport is 480x270, integer-scaled to a 1440x810 window, with pixel snapping on.

### Controls
| Key | Action |
|---|---|
| WASD / arrows | move |
| Mouse 1 / Mouse 2 | light / heavy attack (8e). Presses make the weapon's named strings (the Combos tab lists them; the fists' LLL is punch, punch, kick at 10 / 10 / 20 stamina). With the bow, hold Mouse 2 to draw and aim (walking turns the aim; stamina drains), let go to shoot |
| Space | block, held (8e): a front hit lets part through and costs stamina; at 0 stamina the guard breaks. A fresh press just before a hit parries it (+8 focus; not the bow). The slam, the charge and stones pierce it |
| 1 | the next weapon you carry: fists, the sword (Datis's quest), the spear and the bow (Nidu's stall) |
| Shift | dodge roll (brief invulnerability; 25 stamina) |
| Q | with a weapon: its special (sword flurry, spear whirlwind, bow piercing arrow; 15 focus, then a 5 s recharge). With the fists: tap, the lasso (pull and stun small foes; heavy ones resist; 20 stamina); hold 0.6 s, then let go: the strong lasso (15 focus; 1.5x reach, a longer stun, pulls a bandit too; shares the recharge). After a string's second swing: its finisher (10 focus, 1.5x) |
| E | talk / read a sign / rest and autosave at a rest spot (the town well, the cave's band fire; only while no enemy is after you) / use (the cave's cage door, the ruins' clues, the tablet on Utana's desk, the note in the jail) / go through a door. Talking to Nidu (the coin in the bubble) opens the shop. Beside a fallen companion ("E Revive"): use a Reviving Potion on him |
| (after you fall) | the death screen: W/S choose a save (the autosave first) or New game, E resume (pauses the game) |
| (in the shop) | A/D switch Buy / Sell, W/S select, E buy one (or sell: a second E confirms), Tab or Esc leave (pauses the game) |
| I / M / Tab / Esc / J | open the menu (pauses the game) on the Player tab (level and bars, weapons, items) / the Map tab (blank for now) / the Squad tab / the System tab / the Journal (E reads an entry or an enemy). The Combos tab (8e, before System) is reached with A/D: W/S picks a weapon. Open: another tab's key goes there, the same key closes, Esc closes. Inside: W/S select, E use (eat or drink; with a companion here, "Use on: You / Farnaka / Back"), A/D switch tabs. With a choice open (a save slot's actions, a companion's commands or Give item list, Use on): A/D or W/S choose, E confirm, Esc back |
| (walk over it) | take something lying on the ground (a pickup or a drop) |
| T | dev: the tuning panel (enemy HP and XP, punch / kick / arrow damage, the sword's slash / thrust, stamina costs and refill, focus numbers, the ordinary foes' drop chances; W/S select, A/D change, X reset, E print; the new moves, block and parry are only on the arena's panel) |
| B | debug: collision boxes (orange = see-through for enemy sight), doors, vision cones, sleeping-group circles |
| G | sprite gallery |
| R | restart (dev: a full reset to a new game; the save files are kept; Load is in the menu's System tab) |

### Maps and how they connect
Each map is one script extending `level.gd`, registered in `main.gd` `LEVELS`. The map you leave stays frozen exactly as it was.
```
town (world_waystation.gd, 1200x1340): rat nests, road bandits, the ruins (the scorpions' den in the west, the stranger's trail)
 ├─ storeroom door, press E  ⇄  storeroom (storeroom.gd, 640x928): rats, giant-rat boss barn
 ├─ cave mouth in the north-east cliff, auto  ⇄  cave (cave.gd, 1100x1500): lookouts, raided camp (tent and tunnel rats), jail (the rider, the ambush), the band's camp, boss room (the chief)
 │                                              └─ the chief falls, E at the captain's stake -> hall, spawn "king_return" (the return scene)
 └─ east end of the bridge, auto  ⇄  courtyard (courtyard.gd, 960x640)
                                       └─ open north gate, auto  ⇄  hall (hall.gd, 720x800): King Rostam stair scene, servant, Scholar Utana
```
The main thread (`quest.gd STEPS`; each step ends on a quest event, and the objective is the step after the furthest one done, so going
out of order still reads right):

| Stage | Objective | Done when (`quest.note`) |
|---|---|---|
| 0 | (none: Datis wears a "?") | you talk to Veteran Datis (`met_datis`) |
| 1 | Find King Rostam | the king's stair scene or the return scene ends (`met_king`) |
| 2 | Find the band's hideout in the north-east hills | you walk into the cave (`cave_entered`) |
| 3 | Defeat the band's chief | he falls (`chief_down`) |
| 4 | Cut the captain down | E at his stake, and his scene ends (`captain_found`) |
| 5 | Return to King Rostam | the return scene ends (`return_done`) |
| 6 | Search the ancient ruins north of the town | you have taken both the brass box and the torn page (`ruins_searched`) |
| 7 | The trail goes on... | (the end of the slice so far) |

Optional (`quest.gd SIDE`): "Free the caged rider" shows once you have walked into the jail (`saw_cage`). It is ticked when the cage
opens (`rider_freed`) and missed if the captain is found first. Other flags: `rider_joined`, `saw_prints`, `found_object`,
`found_log`, `found_log_2` (the second page, 7j), `read_tablet` (the library's tablet, 7j), `found_note` (the jail's note, 7j),
`talked_<id>_<stage>`. The journal (`quest.journal`, words in `dialogue.gd LOGS`) holds the boot prints, the brass box and the two torn
pages from the ruins, the tablet's *The King's Road* and the jail's note. A LOGS entry is a "log" (the scientist's words), a "clue"
(what the hero noticed) or a "record" (written by people of the era), with an optional `"by"` line for the reader.

### File map (`scripts/`)
| File | Role |
|---|---|
| `main.gd` | Wires everything (maps, hero, his progress, quest, inventory, squad, dialogue, combat, HUD, menu, shop, tuning panel, death screen); `LEVELS`; items on the hero or a companion (`use_item()`, `revive_mate()`, `revive_by_hand()` for E, `fallen_mates()`, `mate_name()`; 7i); `travel()` (fade, swap map, spawn, carry the squad, then the new map's `arrived()`; walking back into a map brings its ordinary foes back, `combat.respawn()`); "Level N!" over the hero; the hero's maximums worked out again whenever the inventory changes (a rare find); pickups taken each frame (`check_pickups()`); squad orders (`squad_order()`: follow / wait / home, with the fade-out and the home spot); saving (`save_block()`, `save_game()`, `rest()` (also brings the map's ordinary foes back and cures poison), `load_game()` (the menu's Load and the death screen; reloads the scene; `_ready` then builds the game from the save, and each map gets its saved state when first built: `saved_maps`, `_apply_saved()`), `new_game()`); frees the frozen maps on exit; auto-door check; input bindings |
| `death.gd` | The death screen (Stage 7j): opens by itself 1.6 s after the hero falls (`combat.gd over_t`; `hud.gd` fades to black first), pauses the game, says "YOU FELL" and where (`level.gd place_at()`), and lists the saves to go on from (`save.gd SLOTS` that hold a readable save, the autosave first and picked) and New game; W/S choose, E `resume()` (`main.gd load_game()` / `new_game()`). Uses the menu's style constants |
| `level.gd` | Base of every map (since 7j no respawn spot: a fall opens the death screen): place names (`place_name`, `places` from each map's `PLACES`, `place_at()`, `check_places()` notes a place's quest event), `era`, rest spots (`rests` from `RESTS`, `near_rest()`, their E boxes), saving (`busy()`, `save_state()` / `load_state()`: `dead_plan`, the living enemies added during play, the pickups taken and the drops still lying), pickups (`pickup_plan` from each map's `PICKUPS`, `_make_pickups()`, `drop()`, `check_pickups()` within `PICKUP_R`, `draw_look()` for a map's own look), collision grid, `solid()` (optionally low = see-through) / `unsolid()` / `prop()`, line of sight and `sight_blocked()`, doors, use spots (`uses`, `usable()`, `use_spot()`), `talk_done()` after a conversation with a "then", `arrived(spawn)` after a door's fade, spawns, sleeping enemy groups, `hittables` (the training dummy), light helpers for dark maps (`point_light()`, `flicker_lights()`) |
| `world_waystation.gd` | Town exterior: roads, walled town, ruins, the cave mouth (auto door to the cave), river and bridge, nests, bandits, signs; `PLACES`; `PICKUPS` (a small potion and coins in the ruins); the scorpions' den in the west of the ruins (7j: `DEN`, `DEN_SCORPIONS`, added to `enemy_plan()` after the bandits); the stranger's trail after the return (`PRINTS`, the brass box and the torn page as use spots, and since 7j the second page by the den, `CLUE_PAGE_2` / `PAGE2_USE`) |
| `storeroom.gd` | Storeroom dungeon from `FLOORS` tiles; enemy groups `WAKE`; boss barn (pile, pens, summon points); `PICKUPS` (bread by the sacks, a small potion at the barn's gate, and since 7l Datis's broken blade in the side room and the hilt by the giant's pile); dark lighting |
| `cave.gd` | The band's cave hideout: floor from `ROOMS` + `TUNNELS` (a noise-wobbled mask), props / torches / rugs / blood (`STAINS` pools, `DRAGS`, `SPATTER`) / enemies as data, the camp rats from the tents and both tunnels (`CAMP_TRIGGER`, `CAMP_RATS`), one cage builder (`_cage()`: the rider's cage, the jail's pens, the boss room's empty cage), the rider's cage (E opens its door) with the captured rider, the rescue ambush (`WAVE` with per-entry `delay`, a barricade at `BARRICADE`, then `WAIT`), the chief's fight (`WAKE["boss"]`, the seal at `SEAL`, `SLINGER_SPOTS` at the tents' doors), a rider's note in the jail's empty east pen (7j: `NOTE`, `NOTE_USE`), the staked captain (`CAPTAIN`, E at `CAPTAIN_USE` once the seal lifts) and the return to the king; `PICKUPS` (the riders' supplies in the raided camp, the chief's four coin bags, drawn as bags by `draw_look()`); one barricade helper (`_barricade_at()` / `_lift()`); daylight at the mouth, dark lighting |
| `rider.gd` | Farnaka: caged -> steps out -> after the talk joins the squad and follows the hero through every door: on his trail out of a fight, on his own in one (`_skirmish()`: keeps `keep_min` from enemies, within `leash` of the hero; `_walk_back()` afterwards), shooting the nearest enemy in the fight (`rat.in_fight()`) every 0.5 s, a 3-arrow volley when his focus is full; or holds a spot ("wait", still shooting, never moved by a hit), goes home ("leaving", "home"), is walked by a scene ("walk"), or stays caged after a lesser return ("behind"). Since 7i: `hp` / `focus`, `hurt()`, `fall()` (the `down` flag: lies there, through doors, until `revive(pct)` or `rest()`), `heal()` / `add_focus()` for items given, `arrow_landed()`, bars over his head, "E Revive" tag. Since 7j `poison` / `poison_t` (a scorpion's sting; falling or a rest cures it). Extends `npc.gd`; numbers in `combat.gd RIDER` |
| `save.gd` | The save slots `SLOTS` (`auto`, `1`-`4`), each a file in `Save.dir` (default `user://`, on Windows `%APPDATA%\Godot\app_userdata\Time-Travel RPG\`): `save_auto.json`, `save_1.json` .. `save_4.json`. `write(main, slot)` (a `snapshot()` of the hero (HP, stamina, focus, and `progress.state()`: XP, level cap, weapon XP and caps; the level and the maximums are not saved), quest, inventory, squad per era and every map's `save_state()`), `read(slot)` (an older `VERSION` is brought up to date by `_upgrade()`: version 1 had hearts and the old item names; version 2 had kill XP only, so the XP of the story steps, side quests and journal entries already done is added; version 3 had no companion HP, focus or fall; version 4 had no kills by kind; version 5 no weapon in hand), `info(slot)`, `migrate()` (the old one-slot `save.json` becomes slot 1), and the helpers that put a save back (`apply_hero`, `apply_progress`, `squad_list`, `map_state`) |
| `squad.gd` | The squad, kept per era: `MATES` (who can join, role, era, home spot, the Squad tab's stats), members with their orders (`follow` / `wait` / `home`), `join`, `find`, `current(era)`, `leave_era`. `main.gd` moves the companions' nodes (`_carry_squad`, `_place_home`, `squad_order`) |
| `chief.gd` | The band's chief (extends `rat.gd`): sleeps on his seat, charge (with a locking red line; dazed by anything tall: rock, a tent, the strongbox; it hurts a companion in the way too), axe sweep (red arc; everyone inside), enrage at half health, armour during his moves, heals and can enrage again once he is home; draws his telegraphs on the fx layer. Numbers: `combat.gd CHIEF` |
| `slinger.gd` | The chief's slingers (extends `rat.gd`): keep their distance, spin the sling with a thin aim line, throw stones (`combat.shoot`) at their `foe` (the hero, or a nearer companion). Numbers: `combat.gd SLINGER` |
| `courtyard.gd` | Castle courtyard on a river island: statue in a raised planter on a ring road, wall fountain, supply colonnade, armoury stall, patrolling guards, gate tunnel |
| `hall.gd` | Great hall and throne room; steps up to the dais (side walls, stepped carpet); dining side with a servant, library alcove with Scholar Utana and, on his desk, the clay tablet that E reads (7j: `TABLET`, `TABLET_USE`, `usable()` / `use_spot()`); the one-time king scene and the return scene from the cave (`arrived("king_return")`, the rider by the throne), sharing one scripted walk (`_walk_hero_to()`); lighting |
| `combat.gd` | All combat tuning. Since 8e (ported from the arena): the weapons, `FIST_MOVES` / `SWORD_MOVES` / `SPEAR_MOVES` / `BOW_MOVES` (one row a move: timing, damage, stamina, reach / `side`, `pose`, `lv` (its level bonus and weapon-XP key), effects `dash` / `stun` / `bleed`; a bow move's `shot`, `speed`, `arrows`, `spread`, `stagger`; a special's `special`, `name`, `focus`, `after`), `WEAPON_KIT` / `WEAPON_LIST` (each weapon's name, moves, `block`, `parry`, `hold`, `special` and named `strings`, Q strings with a `"fin"`; `has_weapon()`, `switch_weapon()`, `equip()`, `_moves()`, `_row()`), `LETTER_COL` (the Combos tab's letters), the strings (`chain`, `_next_chain()`, `_move_of()`, `_is_last()`, `_try_swing(key)`, `_name_string()`), the specials and finishers (`SPECIAL` charge and cooldown `special_cd`, `FINISHER`, `_try_special()`, `_q_fits()`, `_try_finisher()`, `q_cost()`), `BLEED` (the flurry: `bleeding`, `_bleed()`, `_update_bleeds()`, red drops), the bow (`BOW`, `RETICLE`, `_start_draw()`, `_update_draw()`, `_loose()`, `_fire()`, the earned volley, the hero's arrows in `shots`), the guard (`BLOCK`, `guard()`, `_in_front()`, `_blocked()`, `PIERCE` / `_piercing()` / `_draw_pierce_warnings()`, `PARRY` / `parry_t` / `_parried()`, `_draw_guard()`), `_pull_heavy()` (the strong lasso pulls a bandit), `facing()` = the hero's 8-way aim; `ENGAGE` (7l: staying in a fight), `DODGE`, `LASSO` (the strong lasso's `focus` / `strong_range`), `STAMINA`, `FOCUS`, `BOSSES`, `RIDER` (since 7i also his HP, focus, volley, revive share and how he moves in a fight), `FOE` (who an enemy goes after), `ALARM` and `SIDE` (7k: who joins when one enemy joins the fight, `alarm()`), `RAT`, `BANDIT`, `GIANT`, `CHIEF`, `SLINGER`, `SCORPION` and `POISON` (7j), `DUMMY`, XP, `FOE_LEVEL`, `WEAPON_XP`, `RESPAWN_CLEAR`, `DROPS`); poison (`poison_body()`, `_update_poison()`: ticks on the hero and the companions with him, never the last HP); `over_t`, the time since the hero fell (no respawn since 7j: `death.gd` takes it from there); `tune` (the live copy of every move's damage and stamina, enemy HP, XP, the focus numbers, each weapon's block, the parry, the Q timers and the drop chances that the tuning panel edits, read through `enemy_hp()`, `hit_dmg()` (plus the weapon level's bonus for the move's `lv`), `arrow_dmg()`, `xp_for()`, `stamina_cost()`, `focus_val()`, `drop_chance()`); hero attacks, dodge, lasso and the strong lasso (hold Q; `lasso_range()` / `lasso_cool()` with the Lasso level's bonus), the stamina and focus they spend (`_spend()`, `_refill()`: stamina only; focus comes from hits, `_gain_focus()`), the weapon XP they earn; `kills` and `kills_by` (7k: per kind, for the journal); kill XP (cut by the foe's level), drops (`rng`, `_roll_drops()`); `respawn()` (the ordinary planned foes come back; a group with nobody left goes back to sleep), damage, the squad in the fight (`fighting()`, `mates()`, `targets()`, `hurt_body()`), arrows and stones in flight (`shots`, `shoot()` with who shot it and a spread; stones hit a companion too), `boss()` (the boss the hero is fighting, for the boss bar), `spawn_enemy()` for enemies a map adds during play (picks `chief.gd` / `slinger.gd` / `rat.gd` by kind), enemies' ground telegraphs, the dummy's wobble, effects |
| `items.gd` | Every item as data (`ITEMS`: name, kind tool / food / valuable / rare / story, description, `heal` in HP, `focus`, `cure` (7k: ends a poison), `revive`, `use` eat / drink, `key`, `price`, a rare find's `bonus` and `sell`) and its code-drawn 12x12 icon (`ART`, `icon()`; also the Unarmed fist): the lasso, Bread, Apple, the Small and Large Potions, the Small and Large Focus Potions, the Antidote (7k), the Reviving Potion, Coins, the Sword and its broken blade and hilt (7l), the Spear and the Bow (8e, sold at Nidu's), the carnelian necklace, the ibex armlet, the brass box; `BADGE_ART` / `badge()`: the 20x20 fist, sword, spear and bow of the HUD's weapon badge; `pickup()` draws an item lying on the ground (a pulsing halo, shadow, the icon bobbing, a glint; a story item twice the size, `PULSE_*`, `STORY_PULSE_*`) |
| `inventory.gd` | What the hero carries (item id -> count), `add` / `remove` / `count`, the order the menu lists them in, recent gains for the HUD's toasts |
| `menu.gd` | The game menu (pauses the game; since 7k each key opens its own tab, `KEY_TABS`: I Player, J Journal, M Map, Tab Squad, Esc System): the era-neutral style constants shared by every panel (and the bar colours the HUD uses), the tab bar, the Player tab (a top strip with the level, the XP bar and HP / stamina / focus; the list: the weapons with their levels, then the items by kind; the details: a weapon's level, XP, bonus now and next and its costs, or an item's (E eats or drinks; with a companion here the "Use on" choice, `_use_targets()` / `_use_on()`; a rare find's bonus and sale price); the coins total), the Quests tab (steps, optional objectives), the Journal tab (logs, clues and, since 7j, records: `KIND_LABELS`; since 7k an Enemies part, `_journal_rows()`: each kind slain with its count) and the reader (an enemy shows its `dialogue.gd FOES` description), the Map tab (7k: blank, `_draw_map()`) (`read_log()`, also opened by a map; an entry's `"by"` line under its title), the Squad tab (member cards, details from `squad.gd MATES` "stats" (two to a row) / "gear", a Commands box with `ICONS`; Disband locked with the reason while `quest.needed()`, every order while he is down; Give item, `_give_list()`), the Combos tab (8e: `_combo_weapons()`, `_draw_combos()`: each weapon carried and, for the one picked, its strings from `combat.gd WEAPON_KIT` with their letters in `LETTER_COL`, the Q line, the finisher rule, the guard and parry; `_combo_line()`), `_inner_open()` (A/D stay inside an open choice), the System tab (Autosave, Slot 1-4 with Save here / Load / Back, New game); the tab bar shrinks its `TAB_GAP` if the names would run into "Esc close"; a weapon's cost line comes from its moves (`_first_move()`) |
| `shop.gd` | A keeper's stall (Stage 7h): `SHOPS` (keyed by the keeper: the shop's name, the item ids it sells, the item kinds it buys; Nidu's sells Bread, Apple, both healing potions, both focus potions, the Antidote, the Reviving Potion and since 8e the Spear and the Bow, and buys rare finds), opened by a conversation's `"then": "shop_<keeper>"` (`open_on()`); a Buy tab (`buy()`: one at the item's `"price"`; a weapon only once, `_owned_tool()`; the list scrolls) and a Sell tab (`sell()`: a second E, then the item's `"sell"` in coins and `progress.apply_max()` at once); the keeper's strip (portrait, name, a line from `dialogue.gd SHOP_LINES`); `keeps()` for the coin mark. Uses the menu's style constants, panel size and `detail_head()`; pauses the game |
| `tuning.gd` | Dev tuning panel (T): edits `combat.gd tune` live (damage, enemy HP and XP (the scorpion's row since 7j), a STAMINA row, a FOCUS row and two DROPS rows for the ordinary foes' drop chances) and shows punches / combos / seconds to kill per enemy; E prints the values |
| `rat.gd` | One enemy's brain and drawing: rat, bandit, giant and (7j) scorpion, whose lunge is a tail sting that poisons (`_tail()` for its drawing; the overhead marks sit at `top`) (patrol, alert, chase, wind-up, lunge, flee, return, summon, slam, pulled, stun, bound); steering round obstacles and giving up when stuck; `hit(..., interrupt = false)` for arrows (hurts, never staggers); `pull(strong)` and `bind(secs)` for the lasso; `after_hero()`; `in_fight()` (after the hero and past "alert": the fight has started); joining the fight raises the alarm (7k: `_enter()` calls `combat.alarm()`; `join_fight()` for those it calls); `foe` (7i: the hero, or in the fight the nearer companion, `_pick_foe()`; the slam hurts everyone in the circle); the base of `chief.gd` and `slinger.gd` (`_state_more()`, `person`); every enemy heals to full once it walks home; a boss hides its small bar while the boss bar shows it; `level` (`combat.gd FOE_LEVEL`) |
| `player.gd` | Hero movement, camera, hurt/dodge feedback; since 8e (from the arena's `arena_player.gd`) the 8-way `aim` (`facing_vec()`; it follows the body when a door, a load or a cutscene turns him, `aim_from_dir()`), `_turn()` / `_face_aim()`, the slow walk behind the guard (`GUARD_WALK`) and while drawing the bow (`DRAW_WALK`), and every attack drawing by `pose` (punch / kick, slash / thrust, shoulder, knee, hammer, rise, overhead, the flurry's fire-lit blade, the spear held / thrusting / sweeping / whirling, the bow at rest / drawn / shooting, the guard held across); the sword at the hip (`has_sword`), scripted walking for cutscenes; the three bars (`BASE_HP`, `BASE_STAMINA`, `BASE_FOCUS` at level 1; `max_*` set by `progress.gd`; `refill()`), `aiming` (turning on the spot while holding Q), `poison` / `poison_t` (7j; a purple pulse while poisoned) |
| `progress.gd` | How the hero grows (Stage 7f): his XP and level (`STEP_BASE` / `STEP_GROW` curve, `PER_LEVEL`, `START_CAP`, `raise_cap()`), `kill_xp()` (less from a weaker foe), each weapon's XP and level (`WEAPONS`: Unarmed, Sword, Spear, Bow, Lasso; `"per"` keyed by a move's `lv`; `WEAPON_START_CAP`, `raise_weapon_cap()`, `bonus()`, `bonus_text()`), `apply_max()` (the maximums from the level and the rare finds carried), the toasts (`news`), `state()` / `load_state()` for the save |
| `npc.gd` / `npc_data.gd` | One NPC (routes, idle animations, chatter bubbles, the marks over a talkable one ("?", a coin for a shopkeeper, "..."), E tag, `shout()`, `talk_id` to use another TALK entry) / the town's NPC data |
| `dialogue.gd` | All spoken and written text (`PEOPLE`, `TALK` (a conversation may have a `"then"` for the map (or `squad_*` / `shop_<keeper>`), a `"note"` (quest event), a `"give"` and (7l) a `"take"` of items; a person may have `"flags"` rows that win over the stage table, `_pick()`: Datis's sword quest; and a `"first"` version used only the first time), `SCENES` (scripted scenes; a line may name its speaker with `"who"`), `LOGS` (the journal: logs, clues and records, each with an optional `"by"`), `BOSSES` (names on the boss bar), `FOES` (7k: the journal's enemy names and descriptions), `SHOP_LINES` (a shopkeeper's greeting and replies), `SHOUTS`, `CHATTER`), parchment box, choices, sign panel, quest marks (`mark_for()`: "quest", "shop", "chat"), `draw_portrait()` (a PNG, or a placeholder silhouette drawn at 56 px and scaled to its box); E also uses a map's use spots |
| `quest.gd` | The story's progress: `STEPS` (the main thread as data, each with its `"xp"`), `SIDE` (optional objectives, with `"xp"`; since 7l `"items"` to carry (`check_items()`) or a kill `"count"` (`count_kill()`), shown by `side_label()`: Datis's `"sword"` and `"bounty"`), `note(event)` (gives a step's or side quest's XP the first time), `flags`, the journal (ids, in the order found; `LOG_XP` for each new entry) |
| `hud.gd` | Top left, stacked: the objective box (plus open optional objectives), the HP bar with its number, the stamina bar and the focus bar (all `BAR_W` long whatever the maximum; a notch at what Q costs now, `combat.q_cost()`; a bar flashes when a move was refused), "Lv N" with a thin XP bar ("MAX" at the cap) and a line per companion with the hero (HP and focus, or FALLEN); top right: the place name; bottom right: a round badge with the weapon in hand and a small round "1" notched into its lower-right (`_draw_weapon()`, `_disc()`, `_key()`; it swells on a switch, `POP_TIME`); bottom centre in a boss fight: the boss bar (name, level, health, a half-health notch); round Q and Shift buttons with a cooldown sweep (`_skill()`; since 8e Q fills toward a weapon's special: its focus or its recharge, whichever is further behind), hint line (`HINT`), toasts (items, journal entries, "+N XP", level-ups and weapon level-ups, bottom right), hurt flash, the fade to black when the hero falls (`death.gd` draws over it), the HP bar purple with "Poisoned" (and "poisoned" on a companion's line) while poison runs (7j), sprite gallery (with the scorpion) |
| `sprites.gd` | Code-drawn characters (`person`, `rat`, `scorpion` (7j: side-on, its tail blended between `TAIL_REST`, `TAIL_UP` and `TAIL_STRIKE`), `camel`, `lizard`, `sleeper`) and NPC palettes. This is the swap point for PNG sprites later |
| `props.gd` / `castle_props.gd` | Code-drawn props for the town/storeroom (incl. `house()` with detail sets, the `storehouse()`, the barn, the training yard's fence, dummy and weapon rack, the `scorpion_den()` (7j)) / for the castle maps (the statue draws its PNG; `stair_cheek` flanks a flight of steps; `clay_tablet()` on Utana's desk, 7j) |
| `cave_props.gd` | Code-drawn props for the cave: tents (bloodied when torn), fire rings, camp tables (`bloody`, `"irons"`), bedrolls, stake palisades, the wooden cage (door width, height and pole `gap` set per use: the jail's pens) and what lies in a pen (`pen_inside`: the dead, or a bowl and a cuff), the chief's seat, his `hoard` and `war_table`, a `chest`, the band's banner, a fire bowl, a barricade (the ambush and the boss room's seal), dropped gear, a broken spear, arrows in the ground, a torn tunic, the jail's chain frames / strap bench / straw mat / branding irons, the boss room's loot (coin bags, spilled coins, a strongbox, an ibex skull), staked captives (silhouettes), the captain's stake and ropes, daylight shafts, the rider's `leather_note()` (7j) |
| `terrain.gd` | Ground painted once into an image (sand, roads, river, cliffs, bridge, flagstones, rugs, flights of `steps()`, cave ground from a floor mask (`cave_ground()`, `cave_path()`), blood (`stain()` pools, `spatter()`, `drag()` smears)…) |
| `atmosphere.gd` | Torch glow, water sparkle, vignette, drifting dust |
| `drawn.gd` | A node that draws itself through a callable (used by every prop and character) |

### Where to tune (combat balance)
The design doc's "Combat balance" section (section 8) explains what each number does to a fight. The tuning panel (T) changes the marked ones
live for one session; E on the panel prints them so they can be copied here.
To make values you found on the panel the game's own: press E, then copy the printed lines into the constants at the top of `combat.gd`
(`COMBO` damage and stamina, `DODGE` / `LASSO` stamina, `STAMINA`, `FOCUS`, `LASSO "focus"`, `RIDER "dmg"`, each enemy table's `"hp"`,
the `XP_*` constants). `combat.gd default_tune()` builds the panel's values from those constants, so they become the defaults (and what X
resets to). Update any `fight.gd` assert that checks one of those numbers.

| What | Where (current value) | On the panel |
|---|---|---|
| Hero HP / stamina / focus | `player.gd BASE_HP` / `BASE_STAMINA` / `BASE_FOCUS` (100 / 100 / 50) | |
| Every move (8e) | `combat.gd FIST_MOVES` / `SWORD_MOVES` / `SPEAR_MOVES` / `BOW_MOVES` (`"dmg"`, `"stamina"`, `"dur"`, `"reach"`, `"side"`, `"kb"`; punch 10, kick 20, slash 20, thrust 35 as before; the rest are the arena's first guesses) | punch, kick, slash, thrust only (all of them on the arena's panel) |
| The strings and their pauses | `combat.gd WEAPON_KIT[w]["strings"]` (letters -> moves, name, `"pause"`); `CHAIN_WINDOW` (0.35 s) | |
| The specials and finishers | each special's row (`"focus"` 15, its damage), `SPECIAL` (charge 600 ms, cooldown 5000 ms), `FINISHER` (10 focus, 1.5x), a Q string's `"fin"` | focus costs only |
| The sword's bleeding | `combat.gd BLEED` (4 every 0.5 s, 6 ticks; Inferno's `"bleed_ticks"` 10) | |
| Block and parry | `combat.gd BLOCK` (arc, safety, push, 0.6 s broken, half refill), each weapon's `"block"` (% through / stamina: fists 50 / 15, sword 30 / 12, spear 35 / 12, bow 55 / 15), `PARRY` (150 ms, +8 focus), `PIERCE` | |
| The bow | `combat.gd BOW` (0.8 s full draw, 35 % at once), the volley's `"earn"` (2 hits) and `"focus"` (10) | |
| Spear and bow prices | `items.gd ITEMS "spear"` / `"bow"` `"price"` (800 / 1200) | |
| Staying in a fight (7l) | `combat.gd ENGAGE` (`"near"` 80 px, `"hit_time"` 3 s, `"hard"` 1.75x the leash, `"stuck_max"` 4 s) | |
| A hurt rat going home | `combat.gd RAT "calm_time"` (4 s with the hero away) | |
| Datis's quest | `quest.gd SIDE "sword"` / `"bounty"` (XP 60 / 100, `"of"` 10, `"kinds"`); the coins in `dialogue.gd TALK "datis"` (80); the parts in `storeroom.gd PICKUPS` | |
| Stamina per move | each move's `"stamina"` (punch 10, kick 20), `DODGE` / `LASSO` `"stamina"` (25 / 20); refill `STAMINA` (15 per s, after 1.2 s; was 60 after 0.5 s before 7i; half behind the guard) | yes (not the delay) |
| Focus | `FOCUS` (`"per_hit"` 3, `"combo"` 6 more when a string's last swing lands; no refill by itself since 7k; a special's own hits give none); the strong lasso `LASSO` `"focus"` (15 since 8e), `"strong_range"` (1.5x), its hold `SPECIAL "charge"` (0.6 s) | gains and cost |
| Safety after a hit | `combat.gd HERO_INVULN` (1 s) | |
| Enemy HP | `combat.gd RAT` / `BANDIT` / `SLINGER` / `SCORPION` / `GIANT` / `CHIEF` `"hp"` (30 / 60 / 20 / 40 / 120 / 200) | yes |
| Enemy damage | `"dmg"` in those tables (20; the scorpion's sting 10); the giant's `"dmg"` and `"slam_dmg"` (40), the chief's `"charge_dmg"` (40) and `"sweep_dmg"` (20), a slinger's stone `"dmg"` (20) | |
| Poison (7j) | `combat.gd POISON` (`"dmg"` 4 every `"every"` 1 s, `"ticks"` 5: 20 more after a sting's 10; never the last HP); an enemy table's `"poison": true` makes its lunge poison | |
| The scorpion (7j) | `combat.gd SCORPION` (the sting's wind-up `"wind_time"` 0.8 s, reach `"wind_range"` 30 px, `"vision"` 80, `"leash"` 130); the den's spots `world_waystation.gd DEN_SCORPIONS` | HP and XP |
| XP per kill | `combat.gd XP_RAT` / `XP_BANDIT` / `XP_SLINGER` / `XP_SCORPION` / `XP_GIANT` / `XP_CHIEF` (10 / 25 / 15 / 15 / 100 / 150) | yes |
| The rider's arrows | `combat.gd RIDER` `"dmg"` (10), `"shot_every"` (0.5 s) | damage |
| The rider in a fight (7i) | `combat.gd RIDER` `"hp"` (80), `"invuln"` (0.6 s), `"revive"` (10 % HP from a Reviving Potion), `"focus"` (50), `"focus_per_hit"` (5), `"volley"` (3 arrows), `"volley_spread"` (0.2 rad), `"keep_min"` (60 px from an enemy), `"leash"` (120 px from the hero), `"stuck_snap"` (1 s) | |
| Who an enemy goes after | `combat.gd FOE` (`"recheck"` 0.4 s, `"tie"` 24 px in the hero's favour) | |
| The alarm (7k) | `combat.gd ALARM` (`"radius"` 150 px, in sight; the enemy's plan group always joins) and `SIDE` (rats with the giant, the band, the scorpions) | |
| Food and potion healing, prices | `items.gd ITEMS` `"heal"` / `"focus"` / `"price"` (Bread 10 / 10, Apple 30 / 25, Small Potion 75 / 50, Large Potion 150 / 80; Small Focus Potion +25 focus / 30, Large Focus Potion +50 / 50; Antidote 20; Reviving Potion 200) | |
| What a shop sells and buys | `shop.gd SHOPS` (Nidu: the four healing items, the two focus potions, the Antidote, the Reviving Potion, the Spear and the Bow; buys `"rare"`) | |
| Rare finds | `items.gd ITEMS` `"bonus"` / `"sell"` (necklace +10 max stamina / 120, armlet +10 max HP / 250) | |
| XP to the next level | `progress.gd STEP_BASE` + `STEP_GROW` x (level - 1) (100, 50: totals 100, 250, 450 ... 2700 for Lv 10) | |
| What a level adds | `progress.gd PER_LEVEL` (+10 HP, +10 stamina, +5 focus) | |
| Level caps | `progress.gd START_CAP` (10), `WEAPON_START_CAP` (5); raised only by `raise_cap()` / `raise_weapon_cap()` (a teacher, later) | |
| Weapon levels | `progress.gd WEAPONS` `"xp"` (Unarmed 30 / 80 / 150 / 250, Sword, Spear and Bow 40 / 100 / 180 / 300, Lasso 15 / 40 / 80 / 130) and `"per"` (Unarmed +1 punch, +2 kick; Sword +2 slash, +3 thrust; Spear +1 jab, +2 thrust; Bow +1 arrow, +3 aimed; Lasso +8 px reach, -0.15 s cooldown per level), keyed by a move's `"lv"` | |
| Weapon XP per use | `combat.gd WEAPON_XP`, by a move's `"lv"` (punch 1, kick 2, slash 1, thrust 2, jab 1, arrow 1, aimed 2, lasso catch 3, strong catch 5; a special none) | |
| Enemy levels, kill XP cut | `combat.gd FOE_LEVEL` (rat 1, bandit 2, slinger 2, scorpion 2, giant 3, chief 4); `progress.gd KILL_CUT` (0.25 per level), `KILL_MIN` (0.1) | |
| Story XP | `quest.gd STEPS` `"xp"` (20, 30, 40, 100, 40, 100, 80), `SIDE` `"xp"` (free the rider 60), `LOG_XP` (20 per journal entry; six entries in Era 1 since 7j) | |
| The death screen (7j) | `death.gd OPEN_AT` (1.6 s after the fall), `WORDS_AT` (0.6 s) | |
| Respawning | `combat.gd RESPAWN_CLEAR` (160 px: no foe comes back nearer the hero than this) | |
| Drops | `combat.gd DROPS` (rows of chance %, item, min, max; the bosses' rows are 100) | the ordinary foes' chances |
| Picking up | `level.gd PICKUP_R` (10 px), `PICKUP_TAG_R` (56 px: a story item's name shows), `PICKUP_LIGHT` (its light on a dark map); each map's `PICKUPS` | |
| How a pickup shows | `items.gd GLINT_EVERY` (1.4 s), `PULSE_TIME` (1.2 s), `PULSE_ALPHA` / `PULSE_R` (0.22 / 9 px), `STORY_PULSE_ALPHA` / `STORY_PULSE_R` (0.38 / 16 px), `BOB` (1.5 px) | |
| The king's reward | `hall.gd RETURN_COINS` (100) | |

### The combat arena (Stages 8a-8f, `arena/`)
A testing ground for combat, apart from the story: spawn any enemy or boss, try weapons and combos, watch the numbers, and change them
until the fighting feels smooth. Later, what works is ported into the game.
- **Run it:** in the editor open `arena/arena.tscn` and press **F6** (Run Current Scene). From a terminal:
  `& "<godot console exe>" --path timetravel_godot res://arena/arena.tscn`. F5 still runs the story game (`main.tscn`).
- **Nothing is saved** and the user's saves are never read. The hero starts at level 1 with every weapon (fists, sword, spear, bow)
  and the lasso.
- **Keys:**
  - **WASD** moves and aims: 8 ways, diagonals too;
  - **Mouse 1** light attack, **Mouse 2** heavy attack (with the bow: hold to draw, let go to shoot; while drawing he walks at 50 %,
    walking turns the aim; with the bow in hand a short dotted reticle (4 dots) shows where the arrow will go: faint for the quick
    arrows, brighter while drawing, white at a full draw);
  - **Space** (held) block, with any weapon; pressed just before a hit, a parry (not the bow);
  - **Shift** dodge;
  - **Q**: with the fists the lasso (hold Q 0.6 s: the strong lasso); with any other weapon a tap is its special (15 focus, then a
    5 s cooldown);
  - **1** next weapon (fists, sword, spear, bow);
  - **Tab** the arena panel (Tab or Esc closes it), **T** the tuning panel;
  - **C** clear the field, **B** collision and vision boxes, **R** restart the arena.
- **Strings (8b):** each press continues a string of the weapon in hand if one starts that way (`arena_combat.gd ARENA_WEAPONS`
  `"strings"`); otherwise it starts a new one.
  - Fists: LLL punch, punch, kick; **LLH** punch, punch, **shoulder charge** (a short dash and a big push, little damage);
    **HHH** knee, knee, **hammer fist** (slow and costly, hard last hit, long pause).
  - Sword: LLL slash, slash, thrust; **LHL** slash, **rising cut** (a light foe it staggers is stunned), slash; **HHH** three
    **overhead** cuts (the most damage and stamina, the longest pause).
  - Spear (8c): LLL jab, jab, long thrust (the longest reach, a narrow line); **LLH** jab, jab, **sweeping arc** (wide, a big push);
    **HHH** drive, drive, **charging lunge** (a dash forward with the longest thrust).
  - Bow (8c): **LLL** quick, quick, **volley** (three arrows fanned). The volley must be earned (the play-test: it was easy to
    spam). Both earlier arrows of the string must have hit something (a foe or the dummy) by the time it leaves, and it costs 10
    focus. Otherwise the third shot is one plain arrow and the hero says why ("No volley: 1 of 2 hit", "No volley: focus"). The
    pause after a volley string is 0.5 s. **H held** draws: stamina drains while it is held, and letting
    go shoots the aimed arrow. A full draw (0.8 s) does its full damage, flies fastest and staggers; an early one does less, down to
    35 %. With no stamina left the arrow goes at once. Arrows are unlimited, hit the dummy too, and feed focus like any hit.
- **The block (8c, Space held):** every weapon. The bow was left out at first, then given a guard after the user's play-test
  (without one it was too hard); he holds the stave up across his front.
  - **What it covers:** only hits from the front (a pale arc shows the guard), within about 70 degrees either side of the aim.
  - **A blocked hit:** lets part of the damage through (bow 55 %, fists 50 %, spear 35 %, sword 30 %) and costs stamina
    (15 / 15 / 12 / 12).
  - **The guard breaking:** at 0 stamina the next hit on the guard breaks it. That hit lands in full, and there is no block, attack
    or lasso for 0.6 s.
  - **Behind the guard:** stamina refills at half speed and he walks at 40 % speed. A sting caught on the guard doesn't poison.
  - **Piercing attacks:** the giant's slam, the chief's charge and a slinger's stone go through the guard in full ("Pierced!").
    Their warnings are drawn again in violet (`PIERCE_COL`): a ring round the slam's landing spot, edges on the charge line, a
    slinger's aim line, and stones in flight glow violet. Switch any off in `arena_combat.gd PIERCE`.
  - **Where to change it:** the numbers are `arena_combat.gd BLOCK` and each weapon's `"block"`; the tuning panel edits both values.
- **The specials (8d, Q).**
  - **Cost and timing:** a tap of Q, 15 focus, never stamina, then a 5 s cooldown before the next (the play-test: cheaper, but
    with a recharge).
  - **Limits:** it can't start mid-swing, and its own hits don't feed focus.
  - **Sword, flaming flurry:** four fast thrusts, each stepping forward along the aim with the blade alight. Each does 10, and every
    foe hit burns: 4 damage every 0.5 s, 6 times, with flames on the foe and orange numbers (`BURN`). A burn can finish a foe off.
  - **Spear, whirlwind:** the spear swung right round him. It hits every foe within 42 px for 30 and pushes each outward.
  - **Bow, piercing arrow:** a heavy arrow drawn and loosed at once. It does 50, goes through every foe in its line, hitting each
    once, and staggers them.
  - **Fists:** Q stays the lasso. The strong lasso (hold Q 0.6 s while the ring closes, 15 focus, the same 5 s cooldown) now
    **pulls bandits and slingers too** (the game does the same since 8e). The giant rat and the chief can't be pulled. Let go
    early, or while it is cooling ("Strong lasso in N s"), and it is the plain throw.
  - **The Q button** (bottom left) fills with whichever is further behind, the focus toward the special's cost or its cooldown, and
    lights when both are ready. Too little focus: "Needs 15 focus". Still cooling: "Ready in N s". The special's name floats up when
    it starts.
- **Finishers (8f).** A combo can end in Q.
  - **When:** press Q after its second swing, in the chain window, or during that swing, when it is buffered like any press.
  - **What it does:** the weapon's special plays as the combo's finisher, named with its letters.
  - **Cost:** 1.5 x the special's damage, 10 focus (a plain special: 15), and the special's 5 s cooldown (needed and restarted).
  - **Where else:** Q anywhere else is the plain special (or, with the fists, the lasso). The pips under the hero show a Q in
    violet.

  | Weapon | Finisher | What it adds |
  |---|---|---|
  | Fists | LLQ Lasso yank | the strong lasso at once, no hold |
  | Fists | HHQ Bull catch | the same, 1.3 x the reach |
  | Sword | LLQ Blazing flurry | the flurry at 1.5 x |
  | Sword | LHQ Rising blaze | its thrusts stun a light foe |
  | Sword | HHQ Inferno | 5 thrusts, a 10-tick burn |
  | Spear | LLQ Wide whirl | 54 px round him (42 plain) |
  | Spear | HHQ Vaulting whirl | a dash forward first |
  | Bow | LLQ Piercing volley | 3 piercing arrows |

  The finishers are strings ending in Q with a `"fin"` (the changes to the special's row) in `arena_combat.gd ARENA_WEAPONS`;
  `FINISHER` holds the 1.5 x and the 10 focus (on the tuning panel as "finisher").
- **The parry (8d).** A fresh press of Space opens a 0.15 s window, shown as a gold guard arc. A hit from the front in that window
  is parried: no damage and no stamina, +8 focus, and the attacker staggers back (bosses are armoured and don't). After the window
  it is an ordinary block. The bow can't parry, and nor can anyone parry the attacks that pierce the block. The window and the focus
  are on the tuning panel (`PARRY`).
  - Every string has a name (the plain ones too: "Punch, punch, kick"). When its last move starts, even in the air, its letters
    and name float over the hero, so each can be told apart while testing (a bow's last shot is named when it leaves). The last
    swing of any string gives the full combo's focus.
  - Every new move's numbers are first guesses, to be tuned by play.
- **The tuning panel** (T; pauses the fight; changes last until R restarts the arena):
  - **Keys:** W/S picks a number, A/D changes it, X puts it back, E prints every value to the Godot console in `arena_combat.gd`
    form (so a value you like can be copied into the constants), T or Esc closes it.
  - **WEAPON IN HAND:** each move's damage and stamina, and its block (% let through, stamina a blocked hit). For
    the bow's "aimed" arrow, the damage is a full draw's and the stamina is per second of drawing. Press 1 before opening the panel to
    list another weapon.
  - **HERO** (two columns): dodge and lasso stamina, the refill per second, the focus numbers (the volley's cost too), the parry
    window (ms) and the focus a parry gives, the strong lasso's charge (ms), the Q cooldown (ms) and a finisher's focus. A special shows in the weapon's list as "name (Q, focus)", its second number being its
    focus cost.
  - **ENEMIES:** each kind's HP and how hard each of its attacks hits the hero: a rat's bite, a bandit's hit, a slinger's stone, a
    scorpion's sting, the giant's lunge and slam, the chief's sweep and charge. Enemies already standing feel a change at once.
  - **Read-outs beside each enemy, for the weapon in hand:** light hits to kill it, plain strings to kill it, seconds of non-stop
    plain strings, and how many of its first attack you last from full HP.
- **The arena panel** (pauses the fight; W/S select, A/D change, E flips a yes / no or does an action):
  SPAWN (enemy kind including the giant and the chief, how many 1-8, their level 1-10 (each kind starts at its own), awake: they come at
  once, or they patrol and must spot you; Spawn puts them in a ring round the hero and closes the panel; Clear field);
  HERO (can't die: HP stops at 1; endless stamina; endless focus; no Q cooldown: specials, finishers and both lassos never wait; hero level 1-10; Unarmed, Sword and Lasso levels; full heal);
  WEAPON IN HAND (the picker, with the weapon's strings (their letters, moves and names) and its moves: each move's damage, stamina,
  length, reach and knock-back);
  SHOW (damage numbers, the DPS readout, the combo timeline, hit boxes; reset the DPS counters).
- **Readouts:** top right, DPS over the last 5 s and since the last reset, damage and hits, the last hit (move, damage, on what), the
  enemies standing, the cheats on. Hits on the dummy count too (it takes no damage), so a weapon's own DPS can be measured on it.
  Under the hero, the **combo timeline**: the swing on now with its hit window in red and a white line for how far it has got, the
  chain window (blue) running down after a swing, the grey pause after a string's last swing, a dot while the next swing is buffered
  (pale gold for L, orange for H), and a pip per place in the string showing the letters pressed so far. **Hit boxes** show where an
  enemy's feet must be for the swing to land (red while it can). They turn with the 8-way aim.
- **A fall** shows "DOWN" and the hero gets up at full after 1.2 s; the enemies stay. No kill XP, weapon XP or drops: the levels are what
  the panel sets.

| File | Role |
|---|---|
| `arena.tscn` / `arena.gd` | The scene and its light wiring (a stand-in for `main.gd`): the map, the hero (`arena_player.gd`), `progress.gd` and `inventory.gd`, the arena's combat, HUD, the tuning panel (`arena_tuning.gd`; `arena.gd` has `combat`, `world`, `player`, `levels`, `travelling` as `main.gd` does) and the arena panel; `spawn()` (a ring `SPAWN_RING` / `BOSS_RING` round the hero, inside the floor), `set_hero_level()`, `set_weapon_level()`; its own key bindings (`_bind()`, `_bind_mouse()`: `light` Mouse 1, `heavy` Mouse 2) |
| `arena_player.gd` | Extends `scripts/player.gd` and, since 8e, adds nothing: the 8-way aim, the guard, the slow walks and every drawing it had moved into `player.gd` with the port. A new arena-only move's drawing goes here as an override until it is ported |
| `arena_tuning.gd` | Extends `scripts/tuning.gd` (same keys): the weapon in hand's moves (a special's second number is its focus, `_second()`), its block, the hero's costs, focus and parry (`HERO_CELLS` in two columns of `HERO_ROWS`), each enemy's HP and hit damage (`FOE_HITS`, cells `["foe", kind, key]` read and written through `arena_combat.gd foe_table()`), the read-outs for the weapon in hand, `_print_values()` in `arena_combat.gd` form |
| `arena_map.gd` | The map (extends `scripts/level.gd`), 640x480: walls, `PILLARS` (four tall columns: they block sight and shots and daze the chief's charge), the dummy at `DUMMY_AT`, `SPAWN`; no enemies of its own |
| `arena_combat.gd` | **A copy of `scripts/combat.gd` taken at Stage 7l**, changed freely (its header lists what changed: the porting checklist). `FIST_MOVES` / `SWORD_MOVES` / `SPEAR_MOVES` / `BOW_MOVES` (one row a move: timing, damage, stamina, reach, `side`, `pose`, `lv`, effects `dash` / `stun`; a bow move's `shot`, `speed`, `arrows`, `spread`, `stagger`), `BOW` (the draw), `BLOCK` (the guard; `guard()`, `_in_front()`, `_blocked()`, `_draw_guard()`), `PIERCE` (`_piercing()`, `_draw_pierce_warnings()`), the specials (8d: `_try_special()`, `BURN` / `_burn()` / `_update_burns()`, `_in_area()`, the piercer's `"pierce"` shots, `_pull_heavy()`), `PARRY` (`parry_t`, `_parried()`), `SPECIAL` (the strong lasso's charge, the Q cooldown `special_cd`), the finishers (8f: Q strings with `"fin"`, `FINISHER`, `_q_fits()`, `_try_finisher()`, the move's row `_cur`), the bow's `_start_draw()` / `_update_draw()` / `_loose()` / `_fire()`, `ARENA_WEAPONS` / `WEAPON_LIST` (each weapon's name, moves, `block`, `hold` and `strings`; `_moves()`, `move_name()`, `switch_weapon()`, `equip()`), the strings (`chain`, `_next_chain()`, `_move_of()`, `_is_last()`, `_try_swing(key)`, `_name_string()`), `facing()` = the 8-way aim, the enemy tables as live `var` copies of `_RAT` ... (`foe_table()`, `reset_foe()`), the cheats (`god`, `endless_stamina`, `endless_focus`), `GET_UP`, `clear_field()`, the hit log (`hits`, `total_dmg`, `total_hits`, `dps_recent()` over `DPS_WINDOW`, `dps_total()`, `reset_readout()`), `view` (what is shown) and the timeline and hit box on the fx layer. Same API as `combat.gd`, so `rat.gd`, `chief.gd`, `slinger.gd` and `tuning.gd` work with it as they are; since 8e `WEAPON_KIT` names its `ARENA_WEAPONS` for `hud.gd`. Ported to the game at 8e (its header says what stayed arena-only); its flurry still burns |
| `arena_hud.gd` | Extends `scripts/hud.gd`: the bars, level, Q / Shift buttons and weapon badge (`hud.gd`'s own since 8e), boss bar (names from `dialogue.gd BOSSES`), the readout box, "DOWN" |
| `arena_panel.gd` | The arena panel (Tab): rows `LEFT` / `RIGHT`, `_change()` (A/D), `_act()` (E), the weapon's strings, Q move, block and moves table (`_combo_table()`). Menu style constants |

### Tests (`tests/`)
Two suites, both built on `suite.gd`. Every section starts from a fresh game, and the run ends with `---- passed: N  failures: N` and `OK` / `FAILED`.
They are run at the end of each roadmap step (not after every edit), and new tests are only written when asked.
- **All (Windows):** `powershell -ExecutionPolicy Bypass -File timetravel_godot\tests\run_all.ps1` (one line per suite; `-Verbose` lists every FAIL)
- **One suite:** `& "C:\Users\Chittranjan\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe" --headless --fixed-fps 60 --path timetravel_godot -s tests/world.gd`
  (Linux: `godot --headless --fixed-fps 60 --path . -s tests/world.gd`)

The suites point `Save.dir` at a scratch folder (`user://test_saves/`, emptied at the end), because the game autosaves on doors and new
objectives. A test run never touches your saves. They also seed `combat.rng` (the drop rolls), so every run is the same.

| Suite | Sections | Last run (2026-10-30, Stage 8e, Godot 4.7.2) |
|---|---|---|
| `world.gd` | town reachability; town people + talking + quest stage; dialogue choices; maps (storeroom door, fade, frozen town, sleeping groups, the death screen in the storeroom and in town, killed foes back on re-entry); courtyard (bridge door, guards, ring road, fountain, stores, planter); hall (gate, collisions, king scene once) | 210 pass, 0 fail |
| `fight.gd` | rat fight (telegraph, the light LLL string, lasso, kill, fall + the death screen); dodge and escape; bandits (and the town map's count: 6 rats, 3 bandits, 3 scorpions); giant rat (sleep, armour, summon once, XP); jump + ground slam | 82 pass, 0 fail |

The suites press `light` (Mouse 1) since 8e; `suite.gd ACTIONS` lists `light`, `heavy` and `block` in place of the old `attack`.

Since 7j a fall opens the death screen, which only goes on by loading a save (a scene reload the suites can't do), so a section that
carries on after a fall puts the hero back up by hand with `suite.gd get_up()`.

There are no screenshot scripts any more. Check visuals by playing the game.

---

## Stage history (newest first)
The notes below are kept as written at each stage. The "Files" and "Where to tune" blocks inside older stages describe the code at that time;
the up-to-date list is the file map above.

### Stage 8e follow-up: only the string's name over the hero (2026-10-30)
The user's request: drop the letters from the name that floats up ("LLH  Shoulder charge" is now "Shoulder charge"). `combat.gd
_name_string()` shows `_string()["name"]` alone; the Combos tab still shows each string's letters. Specials were already named
alone. The arena keeps its letters (its copy wasn't changed). Checked headless: "Hammer fist", "Lasso yank", "Blazing flurry",
"Wide whirl" and "Piercing volley" floated up with no letters; both suites pass (210 + 82).

### Stage 8e: the arena's combat in the story game, the Combos tab, the spear and the bow at Nidu's (2026-10-30)
The user's request: every combo change looked good, so put it in the game for now; a Combos tab before System; a special's name in
orange and a finished string's letters and name over the hero; block and parry as in the arena; the spear and the bow in the shop,
costly. Plan: `~/.claude/plans/all-combo-changes-looks-squishy-valiant.md`. The user's decisions on the open questions:
- the strong lasso **pulls** bandits (the arena rule), not the game's old bind (design doc section 7 updated);
- the sword's flurry makes foes **bleed** instead of burn (historical care), but the blade still flickers with fire while it runs,
  so the special looks different from plain swings; the names stay;
- **unlimited arrows** (design doc section 7 updated);
- the spear costs **800** and the bow **1200**.

What changed:
- **`combat.gd`** is rebuilt from `arena/arena_combat.gd`: `WEAPON_KIT` (was `ARENA_WEAPONS`) with the four weapons' moves and named
  strings, light / heavy input (`light` / `heavy` actions on the mouse), the specials and finishers, the bow's draw and earned volley,
  the block, the parry and the piercing attacks, `_pull_heavy()`, the floating names. `BLEED` replaces the arena's `BURN` (red drops
  instead of flames, no damage numbers). Kept from the game: constant enemy tables, kill XP, drops, quest kills, the death screen.
  Weapon XP now comes from a move's `"lv"` (`WEAPON_XP`), so the new moves teach their weapon; the spear's and bow's moves got level
  keys (jab / thrust, arrow / aimed), and the hero's arrows teach the bow when they land. Gone: `COMBO`, `SWORD_COMBO`,
  `COMBO_END_PAUSE`, `last_n`, the `attack` action and the old left-click poll, `LASSO "charge"` / `"bind"` (the hold is `SPECIAL
  "charge"`; the strong lasso costs 15, as in the arena).
- **`player.gd`** took in everything `arena/arena_player.gd` had: the 8-way aim, the guard and the slow walks, every drawing. The aim
  follows the body whenever something else turns him (a door's spawn, a load, a cutscene, the tests set `dir`): `facing_vec()` only
  trusts an aim that agrees with `dir`, and the next physics frame resets it. On a diagonal the body now always faces sideways (the
  arena could leave him facing left while aiming up-right).
- **`main.gd`**: `light` Mouse 1, `heavy` Mouse 2, `block` Space (`_bind_mouse()`); key 1 shows the weapon's name.
- **`hud.gd`**: the hint line (`HINT`, 390 of 480 px), the Q button as the arena's (focus or recharge toward the special), the focus
  notch at `q_cost()`. The spear and the bow badges are pixel art in `items.gd BADGE_ART`.
- **`menu.gd`**: the **Combos** tab (between Squad and System), and the Player tab's cost line read from the weapon's moves. The
  seven tab names still fit with their 16 px gap (228 px of names in 338).
- **`items.gd`** (the Spear and the Bow, tools at 800 / 1200, their icons and badges; the lasso's words), **`progress.gd`** (Spear and
  Bow weapon rows, `WEAPON_ORDER`), **`shop.gd`** (Nidu sells both, a weapon only once, the Buy list scrolls: 10 goods, 8 rows),
  **`tuning.gd`** (its swing-time column reads the fists' plain string).
- **The arena** stays the user's separate copy. `arena_combat.gd` gained `WEAPON_KIT` (a name for its `ARENA_WEAPONS`, which
  `hud.gd` reads) and a header line on what was ported; `arena_player.gd` is now empty (all in `player.gd`); `arena_hud.gd` dropped
  its Q button and badge (now `hud.gd`'s).
- **Tests:** `fight.gd` presses `light`, and sets `chain = "LL"` where it set `last_n = 1`; `suite.gd ACTIONS` updated. Both suites
  pass (210 + 82). A throwaway headless run (saves in a scratch folder) bought both weapons (a second spear refused), cycled key 1,
  played each weapon's LLL, LLQ, special, HHH and block (fists LLQ "Lasso yank" with "Pulled!", the sword's bleeding, a "Parry!"),
  drew the Combos and Player tabs and the shop, saved with the bow in hand and walked through a door with the aim following.
- No save change: an old save's missing spear and bow weapon XP start at 0.

Not in this stage: teacher-taught moves (everything is there at once, for now), the timing evaluation, the enemy punishment, the
game's tuning panel rows for the new moves, a key for the Combos tab, new tests.

### Stage 8f follow-up: walking while drawing the bow, an aim reticle (2026-10-29)
The user's play-test notes:
- **Moving while drawing.** He used to stand still while H drew the bow (`player.aiming`). Now he walks at 60 % speed
  (`arena_player.gd DRAW_WALK`, the user's number), in the same way as behind the guard (a scripted slow walk, so `scripts/player.gd`
  is untouched), and walking turns the aim.
- **Aim reticle.** While drawing, a short dotted line runs from the hand along the aim: 5 small dots, 6 px apart, starting 10 px out
  (`arena_combat.gd RETICLE`, `_draw_reticle()`). It is pale while drawing and white once the draw is full. It always shows while
  drawing, whatever the Show switches.
- **The red block in the meter under the hero** is the swing's hit window: the part of the swing where it can land. The white line is
  how far the swing has got, and blue is the time left to press the next attack. The user chose to keep it as it is.
Checked headless: with the bow drawn and right held for 0.5 s he moved 21 px (60 % of 70 px/s), the aim turned right, and he was
still drawing; letting go shot the arrow.
After the user's next try, 60 % was too fast: `DRAW_WALK` is now 0.5 (50 %). The reticle now shows whenever the bow is in hand,
for the quick (L) arrows too (faint). The dots were made 1 px, then put back to 2 px with one dot fewer (4) at the user's next look.
### Stage 8f follow-up: a "No Q cooldown" cheat (2026-10-29)
The user's request: a test switch to drop Q's cooldown. The arena panel's HERO part has a new row, **No Q cooldown**
(`arena_combat.gd no_q_cooldown`). While it is on, the special cooldown and the lasso's throw cooldown are held at 0 every frame, so
specials, finishers and both lassos can follow one another at once. Focus is still spent, so pair it with Endless focus to spam them.
The readout's Cheats line shows "no Q cd". Checked headless: on, both cooldowns stay at 0; off, a 5 s cooldown runs as before.

### Stage 8f: combos that end in a special (2026-10-29)
The user's choices:
- the special as a combo's finisher, with **named** finishers;
- a finisher uses the special's cooldown;
- 8e (the Combos tab) waits for the port, so 8f came first.

All in `arena/`; nothing in `scripts/` changed.
- **The finishers:**
  - `arena_combat.gd`: each weapon's Q strings (LLQ, LHQ, HHQ ...) come after its others, each with a `"fin"` (changes to the
    special's row) and a pause;
  - `FINISHER` sets 1.5 x the damage (`"mul"`) and the cost, 10 focus, through `tune["focus"]["finisher"]`;
  - `_q_fits()` / `_try_finisher()` handle a Q in the chain window, and a buffered `"Q"` during the swing;
  - the finisher needs and restarts `special_cd`.
- **How the finisher row is applied:**
  - a move's row is now `_cur`: its own row with a finisher's changes, set in `_start_swing(m, over)`;
  - `_resolve_hits()` / `_fire()` apply `"mul"`, and `_burn()` takes a tick count (`"burn_ticks"`);
  - the fists' finishers throw the strong lasso at once, with `_throw_lasso()`'s new `reach_mul`.
- **On screen:** the timeline shows a Q pip in violet. The flurry's drawing follows its thrust count (`arena_player.gd pose_hits`;
  Inferno has 5).
- **Panels:** the arena panel lists a weapon's finishers on one line ("Finish LLQ HHQ (10 focus)"); the tuning panel has a
  "finisher" focus row (HERO in two columns of 7).

Checks:
- A throwaway headless script (not a suite):
  - sword: LL then Q is Blazing flurry (10 focus, the cooldown, its name, 4 hits of 15); it is refused during the cooldown; HHQ
    Inferno is 5 hits and a 10-tick burn; LHQ Rising blaze stuns a slinger;
  - a Q during the second swing is buffered and the finisher follows; Q after one swing is the plain special;
  - spear: LLQ reaches 50 px, and HHQ dashes about 48 px;
  - bow: LLQ fires 3 piercing arrows of 75;
  - fists: LLQ pulls a bandit at once, and HHQ reaches 205 px.

  All 24 passed. The 8b (26), 8c (47) and 8d (30) checks still pass.
- Screenshots of both panels were checked.
- Both suites still pass (210 / 82).

Not in this stage: the Combos tab (8e, with the port), teacher-taught moves, the timing evaluation, the enemy punishment, any
change to the story game, new tests.

### Stage 8d follow-up: cheaper specials with a cooldown (2026-10-29)
The user's play-test note: the specials should cost less but need a charge time, the lasso too. A first try made every special a
hold-to-charge; the user corrected it:
- a tap of Q for the specials, then a cooldown;
- the lasso keeps its hold-to-charge for the strong pull, plus a cooldown;
- the giant rat and the chief are never pulled.

What changed (all in `arena/`):
- **`arena_combat.gd`:**
  - `SPECIAL` holds `"charge"` (600 ms, the strong lasso's hold; `LASSO`'s own `"charge"` is gone) and `"cooldown"` (5000 ms),
    both in `tune["special"]`; `q_charge()`, `special_cd_max()`;
  - `special_cd` is set by a special (`_try_special()`: "Ready in N s" while cooling) and by a strong lasso (`_release_lasso()`: a
    plain throw while cooling, "Strong lasso in N s");
  - the specials and the strong lasso cost 15 focus (was 25);
  - the charge ring glows only when the cooldown is over too.
- **`arena_hud.gd`:** the Q button fills with the slower of focus and cooldown.
- **Arena panel:** the Q line gives the cost and the cooldown.
- **Tuning panel:** "lasso charge" and "Q cooldown" rows; the HERO cells are in two columns of 6.

Checks: the throwaway 8d script, rewritten for taps:
- specials fire on a tap and start the 5 s cooldown;
- a tap during it is refused with the reason, and it runs out;
- the strong lasso still needs the hold, pulls a bandit and starts the cooldown; held again while cooling, it is a plain throw;
- the giant rat can't be pulled.

All 30 passed on two runs. The 8b (26) and 8c (47) checks and both suites (210 / 82) still pass. Screenshots of both panels were
checked.

### Stage 8d: the Q specials and the parry (2026-10-29)
Step C of the user's order. The user's rules, from the 8b planning:
- Q is the weapon's own move: the lasso with the fists, a special costing focus with the others;
- the fists' special: the strong lasso works on all enemies except bosses;
- the sword's: a flame sword, like fencing;
- the spear's: a 360-degree strike;
- the bow's: a big piercing arrow;
- the parry: a perfect block, for every weapon but the bow.

All in `arena/`; nothing in `scripts/` changed.
- **Specials** (`arena_combat.gd`):
  - a weapon row's `"special"` names a move row with `"special"`, `"name"`, `"focus"` (through tune) and `"after"`;
  - `_try_special()` starts it on Q. A move outside the strings ends with its own pause, and its hits don't feed focus;
  - flurry: `"hits"` thrusts (`_seg`: each one steps forward and hits afresh) and `"burn"` (`BURN`, `burning`, `_burn()`,
    `_update_burns()`, `_draw_burns()`);
  - whirl: `"radius"` (`_in_area()`: a circle; pushes outward);
  - piercer: a shot with `"pierce"`; it goes on through, `"hit"` keeping each target once, and its trail is drawn heavier.
- **The strong lasso:** `_pull_heavy()` pulls a heavy non-boss itself, since `rat.gd pull()` refuses them; it no longer calls `bind()`.
- **Parry:** `PARRY`, `tune["parry"]`. `parry_t` opens on a fresh Space press while the guard is up, and closes with the guard.
  `_parried()` is judged in `hurt_player()` after the piercing check and before the block: the attacker found at the hit's origin
  takes a 0-damage interrupting hit. A weapon row's `"parry": false` is set on the bow.
- **On screen** (`arena_player.gd`): the flurry's burning blade, the whirl, the piercer's draw; the gold parry arc; the heavy
  arrow. `arena_hud.gd _draw_skills()` fills the Q button with focus.
- **Panels:** the arena panel shows the Q move and "parry / no parry", and "Enemies standing" moved under the left column. The
  tuning panel lists a special's focus cost, the parry window and its focus, and the HERO cells are in two columns.
- **Fixes found by the checks:** a special's damage asked `progress.gd` for a bonus key it doesn't have (`hit_dmg()` now skips an
  empty `"lv"`); the parry window outlived the guard and carried over to the next weapon (it now closes with the guard).

Checks:
- A throwaway headless script (not a suite):
  - Q without focus does nothing and says so; the flurry spent 25 focus, all four thrusts hit, gave no focus, and the burn ticked
    6 times then went out;
  - the whirl hit foes in front, behind and to the side and pushed them outward; the piercing arrow hit two bandits in a line for
    50 each;
  - Q with the fists still gathers the lasso, and the strong one pulled a bandit in;
  - a hit in the parry window did nothing, gave 8 focus and staggered the bandit; after the window it was a block; the giant's slam
    couldn't be parried; the bow blocks but opens no window;
  - the tuning panel lists the new numbers.

  All 23 passed. The 8b (26) and 8c (47) checks still pass; the 8c one now lets the parry window pass before testing the block.
- Screenshots of the specials, the burn, the gold arc and both panels were checked, and the panel fixed after them.
- Both suites still pass (210 / 82).

Not in this stage: combos that end in a special (8f), the Combos tab (8e), teacher-taught moves, any change to the story game, new
tests.

### Stage 8c second follow-up: the bow blocks (2026-10-29)
The user's play-test: with no guard, the bow was too hard. The bow now blocks like the other weapons, with the weakest guard: 55 % of a
hit gets through and it costs 15 stamina (`ARENA_WEAPONS["bow"]["block"]`, on the tuning panel). He holds the stave up across his
front (`arena_player.gd _draw_guard()`). The parry (8d) still leaves the bow out.

Checks: the throwaway 8c script now expects the bow to block (55 % through, 15 stamina) and its block rows on the tuning panel. All 47
checks passed, and both suites still pass (210 / 82).

### Stage 8c follow-up: names for every combo, an earned volley, piercing attacks (2026-10-29)
The user's notes on 8c:
- the combo names didn't show (they only floated up when the last hit landed, and the plain strings had none);
- the bow's volley was easy to spam;
- some attacks should go through the block;
- stamina should refill behind the guard.

All in `arena/`:
- **Names:** every string has a name, and `"plain"` marks the basic one. `_name_string()` runs when the last move starts
  (`_start_swing()`; a bow's when it leaves, `_fire()`). It shows the letters and the name ("LLH  Shoulder charge"), with
  `text()`'s new width.
- **Volley:** the volley row has `"earn": 2` (earlier arrows of its string that must have hit, counted through `string_id`,
  `landed` and `_arrow_landed()`), `"focus": 10` (`tune["focus"]["volley"]`, on the tuning panel) and `"fallback": "quick"`.
  The hero says why it didn't fly, and the volley string's pause is now 0.5 s.
- **Piercing attacks:** `PIERCE` covers the giant's slam, the chief's charge and a slinger's stone. `_piercing()` finds the slam
  and the charge from the attacker's own state and position; a stone sets `_pierce_shot`. Neither `rat.gd` nor `chief.gd`
  changed. `_draw_pierce_warnings()` draws their warnings again in `PIERCE_COL` (violet), and stones glow violet.
- **Guard:** behind it, stamina refills at `BLOCK.regen` (half the usual rate).

Checks:
- The throwaway 8c script, extended: no hits means a plain arrow and the reason; two hits and the focus make a volley that spends
  10; two hits but no focus means a plain arrow and the reason; the refill behind the guard is half rate; the slam, the charge and a
  stone pierce while the chief's sweep is blocked; LLL, LLH and the spear's HHH name themselves in the air.
- All 46 checks passed, and the 8b check still passed.
- Screenshots of the name and the violet warnings were checked.
- Both suites still pass (210 / 82).

### Stage 8c: the spear, the bow, the block (2026-10-29)
Step B of the user's order. The user's rules, from the 8b planning:
- unlimited arrows;
- Mouse 1 shoots quick arrows; Mouse 2 held aims, draining stamina;
- Space blocks, with every weapon but the bow;
- the bow has no parry either (the parry comes in 8d).

All in `arena/`; nothing in `scripts/` changed.
- **Spear** (`SPEAR_MOVES`): LLL jab, jab, long thrust; LLH sweeping arc; HHH drive, drive, charging lunge. A move row's new
  `"side"` sets how wide its box is (the jabs narrow, the sweep wide). It is drawn in `arena_player.gd` (held upright, thrusts,
  sweep).
- **Bow** (`BOW_MOVES`, `BOW`):
  - **Shot moves:** a move with `"shot"` fires arrows at its hit time (`_fire()`) instead of a hit box.
  - **Volley:** LLL ends in three arrows fanned out.
  - **Drawing:** the weapon's `"hold"` move is H held (`_start_draw()` / `_update_draw()` / `_loose()`). Stamina drains while
    drawing, the timeline shows the draw, and the damage and speed grow with it. Only a half draw or more staggers.
  - **The hero's arrows:** they are shots with `"hero"`, `"kb"` and `"stagger"`; they log hits, feed focus and rock the dummy.
  - **Drawing on screen:** `arena_player.gd` (held at his side, drawn, loosed).
- **Block** (`BLOCK`, each weapon's `"block"`, `tune["block"]`):
  - it is judged first in `hurt_player()`: `_in_front()` within `arc` of the aim, then `_blocked()` (the weapon's cut of the damage,
    its stamina, a small push, 0.25 s of safety);
  - with no stamina left the guard breaks (the full hit, and no block, swing or lasso for 0.6 s);
  - no stamina refill behind the guard;
  - a sting caught on the guard doesn't poison;
  - a pale arc shows the guard (bright on a blocked hit, red and broken while broken);
  - the hero walks at `GUARD_WALK` and holds the weapon across, through player.gd's scripted walk, so `player.gd` is unchanged.
- **HUD, panels:**
  - the spear's and the bow's badges are drawn in `arena_hud.gd`;
  - the arena panel shows the bow's held H and each weapon's block;
  - the tuning panel edits the weapon's block (% through, stamina a hit).

Claude's defaults, not yet the user's choice (in IMPROVEMENTS "Decisions pending"): every number above; that every enemy attack can
be blocked from the front (none pierce yet); no stamina refill behind the guard.

Checks:
- A throwaway headless script (not a suite):
  - every spear string played its moves; a jab reached 42 px where a slash doesn't;
  - a quick arrow hit for 10; the third quick shot was a volley of 3;
  - H drew the bow and drained stamina; a full draw hit for 40, and an early release less; at 0 stamina the arrow went by itself;
  - an arrow rocked the dummy;
  - the bow couldn't block; the sword's guard let 30 % through and cost 12 stamina; a sting on the guard didn't poison; a hit from
    behind came through in full;
  - at 0 stamina the guard broke and came back; walking behind the guard was 40 % as fast;
  - the tuning panel listed the sword's block and none for the bow.

  All 31 passed, and the 8b check still passed.
- Screenshots of the new drawings and both panels were checked.
- Both suites still pass (210 / 82).

Not in this stage: the Q specials and the parry (8d), attacks that pierce the block, any change to the story game, new tests.

### Stage 8b: light / heavy strings, the 8-way aim, the arena's tuning panel (2026-10-29)
The user's request: attacks only went 4 ways while the dodge went 8; add light and heavy attacks and a special, in the arena only.
The user's decisions:
- **Keys:** Mouse 1 light, Mouse 2 heavy, Space block, Shift dash, Q = the lasso with the fists and the weapon's special otherwise.
- **New weapons:** a spear and a bow (unlimited arrows; the light shot is quick, and holding heavy aims while it drains stamina).
- **Block and parry:** for every weapon but the bow, which has neither.
- **Specials:** the fists' strong lasso pulls every non-boss; the sword makes a flaming lunge flurry that sets foes burning; the
  spear a 360-degree strike; the bow a big piercing arrow.
- **Light and heavy** make named strings (the 8b idea).
- **Order of work:** A (8b) the aim, keys and strings; B (8c) the spear, the bow and the block; C (8d) the specials, then the parry.
  Later: E (8e) a Combos tab in the inventory menu as weapons and combos come in; F (8f) combos that end in a special.
- **Tuning panel:** asked mid-plan, it now edits every move's numbers and how hard each enemy hits.

What changed (all in `arena/`; nothing in `scripts/` changed):
- **8-way aim:** `arena_player.gd` (new) extends `player.gd` with `aim`, set from the move keys under the same rules as `dir` (no
  turning mid-swing, in a dodge or while throwing). `facing_vec()` returns it, so the swing drawings, the hit test, the swing's
  shove, the lasso and the hit box all follow it. The body still faces 4 ways.
- **Light / heavy strings:**
  - `arena_combat.gd`: `COMBO` and `SWORD_COMBO` became `FIST_MOVES` / `SWORD_MOVES` (one row a move, with `pose`, `lv` and the
    effects `dash` / `stun`), and each `ARENA_WEAPONS` row has `"strings"`.
  - A press makes `chain + key` if a string starts that way (`_next_chain()`), else starts a new string.
  - Each string has its own `"pause"` after its last swing.
  - The timeline's pips show the letters.
  - A named string's name floats up when its last swing lands.
  - Every move has its own tune keys, built from the tables.
  - The new moves are drawn in `arena_player.gd`: shoulder, knee, hammer, rise, overhead.
- **Mouse keys:** `arena.gd _bind_mouse()`; the `attack` action and the old left-click poll are gone.
- **Tuning panel:** `arena_tuning.gd` (new) extends `tuning.gd`, with the weapon in hand's moves, the hero's costs, each enemy's HP
  and hit damage, and the read-outs for the weapon in hand.
  - So enemy damage can change live, the enemy tables in `arena_combat.gd` are `var` copies of `_RAT` ... consts. `rat.gd` reads
    them by name, as before.
  - `foe_table()` and `reset_foe()` give access to them.
- **Arena panel:** it lists the strings and the moves. The HUD hint names the mouse keys.
- **One change from the plan:** the 8b note's "guard break" on the hammer fist was dropped. Any hit already staggers a bandit in his
  wind-up, and the bosses' armour is a design rule.

Checks:
- A throwaway headless script (not a suite): every string of both weapons played its moves, a press fitting no string started anew,
  the chain cleared after its window, the aim followed held diagonal keys, and a diagonal slash hit a diagonal bandit. On the tuning
  panel, a bandit's hit damage changed live and reset, and a move's damage changed live. All 25 passed.
- Screenshots of the panels and the new poses were checked, and the panel layouts fixed after them.
- Both suites still pass (210 / 82).

Not in this stage: the spear, the bow and the block (8c); the specials and the parry (8d); any change to the story game; new tests.

### Stage 8a: the combat test arena (2026-10-28)
The user's request: a test stage, a square where any enemy or boss can be fought, to work out weapons and combos until the combat is
smooth, then port that into the game. The user's choices: the same project folder with a different file to run, kept light, with the
existing tuning panel; a **separate copy** of the combat code; the first step has a weapon picker, the spawner, the cheats and hero
setup, and the readouts.
- New folder `arena/`: `arena.tscn` + `arena.gd` (the wiring), `arena_map.gd`, `arena_combat.gd` (the copy of `combat.gd`), `arena_hud.gd`
  (extends `hud.gd`), `arena_panel.gd`. Details under "The combat arena" above.
- Reused unchanged: `player.gd`, `rat.gd`, `chief.gd`, `slinger.gd`, `progress.gd`, `inventory.gd`, `items.gd`, `tuning.gd`, `level.gd`,
  `hud.gd`, the props and terrain painters. Nothing in `scripts/` changed, so the story game is as it was.
- One change from the plan: the arena panel is one page in two columns (walked with W/S) instead of four tabs, so A/D only ever
  change a value.
- Checked with a throwaway headless script (not a suite): it spawned every kind at a set level, swung at the dummy and the
  enemies, switched weapons, used the cheats, fell and got up, cleared the field, set the hero's and a weapon's level, and used the panel
  and the tuning panel. All passed. Both suites still pass (210 / 82).
Not in this stage: the feel pass (hit-stop, knock-back, input buffer, cancel windows), new weapons, enemy changes, any change to the story
game, new tests.

### Stage 7l follow-up: round buttons, same-size bars, pickups that show, the group alarm (2026-10-28)
The user's play-test notes with three screenshots (a reference picture of round weapon icons, the storeroom, the HUD at Lv 2).
- **Weapon badge** (`hud.gd _draw_weapon()`): the box became a round badge (a dark disc, a gold ring lit from the top-left, `_disc()`)
  with only the weapon in hand, drawn from new 20x20 art (`items.gd BADGE_ART`, `badge()`; a weapon without it falls back to its 12px
  icon at 1.5x). No name (the user's note). It swells for `POP_TIME` on a switch. The toasts start 14 px higher.
- **The "1" chip** (`_key()`, `KEY_R`, `KEY_GAP`; after the user's mock-up): first a small "1" under the badge, shown only with the
  sword; then moved to the badge's lower-right, overlapping it, with a dark circle drawn first so the badge's ring looks cut round
  it. It always shows so the player knows the key, and stays still while the badge swells. It was dim until the sword was carried at
  first; the user asked for the badge's gold always (one style). After the next look the dark gap was thinned (`KEY_GAP` 0.5, was
  1.5), the chip grew to `KEY_R` 8, and every round button's letter ("Q", "Shift", "1") is bold with a thin outline and centred
  properly (`_label()`, a `FontVariation` with `variation_embolden`).
- **Q and Shift** are round buttons in the same style; the cooldown is a pie sweep; "Sh" became "Shift".
- **Bars**: HP, stamina and focus are all `BAR_W` (90 px) whatever their maximum (the user's rule: same size, only the value differs).
  Before, each grew with its own maximum, and stamina (+10 a level against 100) passed the HP bar's end into its number.
  `BAR_MAX` and `_bar_w()` are gone.
- **Pickups** (`items.gd pickup()`): every one has a pulsing halo, bobs and glints every 1.4 s (was 2.2); a `"story"` item is drawn
  at 2x with a brighter, wider halo. `level.gd`: on a dark map (it has a `CanvasModulate`) a story item gets a small light of its own
  (`_light_pickup()`, deferred because a map adds its dark after its pickups; freed by `_remove_pickup()`), and shows its name while
  the hero is within `PICKUP_TAG_R`.
- **Alarm bug**: in the storeroom's side room the left rat joined and the two right ones didn't. Two causes: `storeroom.gd _fence()`
  rails blocked sight (now `low`: they stop feet, not eyes), and the right rats were 162 and 241 px from the left one, past
  `ALARM "radius"`. Now every awake member of the joining enemy's plan group joins, however far (`combat.gd alarm()`); the radius
  and sight rule stays for everyone else.
- Tests: world 210 / 0, fight 82 / 0. The HUD and the pickups are not covered by the suites: check them with F5.

### Stage 7l: enemies stay in a fight, hurt rats heal, Datis's sword (2026-10-28)
The user's play-test notes and screenshot, and their answers on the quest: Datis gives it; the parts are collected; then 10 bandits;
key 1 and a weapon box at the bottom right; a plain "Sword"; skills later.
- **Staying in a fight.** Before, `_chase` ended on the leash whoever was next to the enemy, and stuck / no headway ended it too (the
  cave's tents). The alarm (7k) made it worse, since a bandit it calls from 150 px may start near its leash.
  - New: `rat.gd engaged(pd)` (the foe within `ENGAGE "near"`, or `hit_t` from a hit in the last `"hit_time"` s) and `_give_up(pd)`,
    used by `rat.gd`, `chief.gd` and `slinger.gd` `_chase`.
  - Engaged, the leash and being stuck don't count, `_watch_progress` doesn't fire, and a stuck enemy tries the other side every 1.5 s.
  - It gives up after `"stuck_max"` s stuck, or beyond `"hard"` x the leash.
- **Hurt rats heal.** `_cower(dt, pd)` walks home after `RAT "calm_time"` s with the hero beyond `flee_wake` (`calm_t`). `_return`
  always heals at home (the old `hp > flee_hp` guard broke the design rule). A hurt rat walking home doesn't turn back to chase.
- **Datis's quest.**
  - `dialogue.gd TALK "datis"`: a stage-2 ask (`note` "sword_asked").
  - New TALK `"flags"` rows (`_pick()`; from `"flags_from"`; the furthest flag first) and a new `"take"` (items taken before the
    `"give"`, then the `"note"`).
  - `mark_for()`: a "?" whenever the conversation would note something new (it replaces Datis's stage-0 rule).
  - `quest.gd SIDE "sword"` (items: `check_items()` from `main.gd` on an inventory change notes "sword_parts") and `"bounty"`
    (`count_kill()` from `combat.gd rat_killed`; the count in `flags["bounty_kills"]`).
  - `side_label()` gives "(n/2)", "(n/10)" and the next words; it is used by the HUD and the Quests tab.
  - Items `sword_blade` and `sword_hilt` (story) as `storeroom.gd PICKUPS`; `sword` (tool, key 1). Each has a 12x12 icon.
- **The sword.**
  - `combat.gd SWORD_COMBO`, `weapon`, `_combo()`, `move_name()`, `hit_dmg()` by weapon (tune `"slash"` / `"thrust"`), stamina by move,
    `_weapon_xp(weapon, ...)` (`WEAPON_XP` slash 1, thrust 2), and the reach per swing.
  - `switch_weapon()` on the new `switch_weapon` action (key 1, `main.gd`).
  - `progress.gd WEAPONS "sword"` (between Unarmed and the Lasso).
  - `player.gd` draws it held, swinging (an arc with a trail, or a thrust) and sheathed (`_draw_sword_held()` / `_draw_sword_swing()` /
    `_draw_sheath()`).
  - `hud.gd _draw_weapon()` (bottom right; the toasts moved up 22 px).
  - `menu.gd _draw_weapon()`: the sword's stamina line.
  - `tuning.gd` has a SWORD row; its notes are one line now.
- **Save version 6:** `"weapon"` in the hero block (`main.gd` restores it only if the sword is carried); `_upgrade()` 5 -> 6.
- Design doc: the sword decision (section 7).
- **Tests:** `world.gd` 210 / 0 and `fight.gd` 82 / 0, no script errors. A throwaway check (deleted) passed 24 / 24:
  - a bandit 260 px from home with the hero 40 px away stays in the fight, and walks home once the hero backs off;
  - a hiding rat at 8 HP heals at home;
  - Datis's conversations, marks, the parts noted, take / give, the bounty's count (rats don't count, a slinger does) and the 80 coins;
  - key 1 refused, then the sword drawn (20 / 35 damage, 15 stamina, a slash landing and training the Sword) and put away;
  - the save's weapon and count, and the v5 upgrade;
  - both parts' spots reachable from the storeroom entry.
  - Not checked: a cave case (an engaged bandit caught on a tent).
- Not in this stage: sword skills from Datis; a separate key per weapon; the bandits' weapons; sword sound.

### Stage 7k: focus from hits, the Enemies journal, the alarm, the Antidote, the Map tab and menu keys (2026-10-28)
The user's list of six (the first was "check the improvement file": read, and its antidote entry is now done).
- **Focus** (`combat.gd FOCUS`): no refill by itself any more (`_refill()` is stamina only). `_gain_focus(finisher)`: +3 a hit that
  lands, +6 more when the kick of a full punch-punch-kick lands (once per kick, however many it hits). `tune["focus"]` has `"combo"`
  instead of `"regen"`; the tuning panel's FOCUS row shows "full combo".
- **Enemies in the journal**: `combat.gd kills_by` (kind -> count) beside `kills`; saved (`save.gd VERSION` 5, `_upgrade()` gives an
  old save an empty list). `dialogue.gd FOES` holds each kind's name and description (placeholder words). The Journal tab
  (`menu.gd _journal_rows()`, `_draw_journal()`) shows WRITINGS, then ENEMIES (a kind once one is slain, "Slain N" on the right); E
  opens either in the reader ("Enemy - slain: N", then the description). "Foes slain" is gone from the HUD; the companion lines
  moved up.
- **The alarm** (`combat.gd ALARM`, `SIDE`, `alarm()`): `rat.gd _enter()` calls it when an enemy goes from out of the fight to in it
  (spotted the hero, or hit / pulled / bound by him). Everyone of the same side within 150 px, in sight of it, not asleep, not a boss
  and not already fighting, joins (`join_fight()`: from patrol, alert or walking home). Those called don't call others (`_called`).
- **The Antidote** (`items.gd`, a slim green flask, 20 coins, `"cure": true`): `main.gd use_item()` ends a poison on the hero or a
  companion and is used up only if there was one. On Nidu's Buy list (now eight goods, which fills it).
- **The Map tab** (`menu.gd`, between Journal and Squad): a frame and "You have no map of this land yet."
- **Keys** (`main.gd _setup_input()`: `map` M, `squad_menu` Tab, `system_menu` Esc; `menu.gd KEY_TABS`): each opens the menu on its
  tab; open, another tab's key goes there and the same key closes; Esc always closes (backing out of an open choice first, as before).
  The `menu` action (Tab and Esc) still closes the shop and the tuning panel. The hint line says "I M Tab Esc menu"; the menu's corner
  and footer say "Esc close".
- Design doc: the user's decisions are written in (focus from hits only, the alarm, the HUD without foes slain, the menu keys, the
  Antidote).
- **Tests:** `world.gd` 210 / 0 and `fight.gd` 82 / 0, no script errors. A throwaway check (deleted) passed 26 / 26: focus stays put
  for 3 s and gains 3 / 9; kills by kind, the journal's rows and their order, the save and the v4 upgrade, E opening an enemy;
  the alarm brings a rat 60 px away but not a scorpion beside it; the antidote refused without poison, then cures and is used up;
  M, Tab, Tab, Esc, I, Esc, Tab, Esc through real key events.
- Not in this stage: a map to show in the Map tab; scouts as their own role and faction territories; enemy portraits in the journal;
  a scrolling shop list.

### Stage 7j: journal records and a second log, the scorpion and its poison, the death screen (2026-10-28)
The user's list. The one open question (what the death screen offers) was asked, and the user chose "resume from a save" (now in the
design doc, section 11). The idea of a new area about the scientist's intentions is in `../IMPROVEMENTS.md` for later.
- **Journal entries** (`dialogue.gd LOGS`; each is a use spot that notes a quest flag, adds the entry (+20 XP) and opens the reader).
  Placeholder words, with the history behind them in the comments.
  - A third kind, **"record"**: written by people of the era. An entry may have a `"by"` line, which the reader shows under the title
    instead of the kind's default. The Journal tab labels the kinds Log / Clue / Record (`menu.gd KIND_LABELS`).
  - **The King's Road** (`tablet_road`, record): a clay tablet on Utana's desk in the library (`hall.gd TABLET`, `TABLET_USE`;
    `castle_props.gd clay_tablet()`, which glints until it has been read; flag `read_tablet`). The text covers Cyrus taking Media,
    Lydia and Babylon, Darius fixing each satrapy's tribute and running the King's Road (stations, relays, rations on a sealed order),
    and Hindush paying in gold dust. Naming Darius sets the slice in his reign or later.
  - **A note in the jail** (`jail_note`, record): a scrap of leather in the jail's empty east pen (`cave.gd NOTE`, `NOTE_USE`;
    `cave_props.gd leather_note()`; flag `found_note`). It is a rider's charcoal note in Aramaic: they held the fire until the arrows ran
    out, the chief came down off the rocks with his axe, and the rest are taken up the steps one a night. It agrees with the captain's
    account. The hero takes it, and the pens with the dead stay untouchable, as the design doc says.
  - **A second torn page** (`page_2`, log): by the scorpions' den, there once the king has heard about the stranger, like the first
    (`world_waystation.gd CLUE_PAGE_2`, `PAGE2_USE`; flag `found_log_2`). It is optional: the box and the first page still finish the
    search. Day 4: Herodotus's 360 talents of gold dust from "India" (he means the Indus satrapy), the scribes counting barley but no
    counts from the east, and a sting under the stones the night before.
- **The scorpion** (`rat.gd` kind `"scorpion"`, `combat.gd SCORPION`; `sprites.gd scorpion()`; the den `props.gd scorpion_den()`).
  - Three guard a den under a fallen slab in the west of the ruins (`DEN`, `DEN_SCORPIONS`). The slab is low, so it gives no cover.
  - They are added to the town's `enemy_plan()` after the bandits, so an older save's dead rows still mean the same enemies.
  - The rat's brain with its own numbers: 40 HP, slow (44 chase), short-sighted (80 vision, a narrow cone, a 34 px "feel"), a 130 px
    leash, never flees, light (the lasso pulls it), no drops, level 2, 15 XP. It respawns like other ordinary foes.
  - Its lunge is a sting: a 0.8 s wind-up in which the tail arches over its head (`rat.gd _tail()`) and the usual red line shows, then a
    short strike.
  - The overhead marks (?, !, stun stars, health) now sit at the enemy's `top`, so the scorpion's clear its tail; a rat's are where they
    were.
- **Poison** (`combat.gd POISON`, `poison_body()`, `_update_poison()`).
  - A sting that lands does its 10 and poisons the one it hit, the hero or Farnaka: 4 HP every second, 5 times.
  - A new sting starts the count again, and a poison never takes the last HP (Claude's default, in `../IMPROVEMENTS.md`).
  - A rest cures it (`main.gd rest()`, `rider.gd rest()`), and so does a companion's fall.
  - The count lives on the body (`player.gd` / `rider.gd` `poison`, `poison_t`) and is not saved.
  - On screen: the HUD's HP bar and heart turn purple with "Poisoned" beside the numbers (`menu.gd POISON_COL`), a companion's line says
    "poisoned", the body pulses purple, and each tick floats "-4".
- **The death screen** (`death.gd`, new).
  - When the hero falls, the HUD fades to black as before. At 0.6 s "YOU FELL" and "in <place>" fade in; at 1.6 s the choices open and
    the game pauses.
  - The choices are the saves that can be read (the autosave, then slots 1-4, each with its place and time) and New game. The autosave
    is first and picked. With nothing saved the line reads "Nothing is saved yet. Start the trail again:" and only New game is
    offered.
  - W/S choose, E resumes (`main.gd load_game()` / `new_game()`), and every other key is swallowed.
  - The old respawn is gone: `combat.gd _game_over()`, `RESPAWN_AFTER`, `back_t`, `rat.gd calm()`, `level.gd respawn_pos` /
    `respawn_face`, the town's `gate_pos`, and the cave's `ENTRY_RESPAWN`, `WAVE_RESPAWN` and `BOSS_RESPAWN`. A fall in the ambush or the
    chief's fight goes back to the last save, which is always from before it (`busy()` holds saving).
  - This also fixes the old "Back to the waystation gate..." line that was shown on every map.
  - E no longer reaches a conversation, sign or door while the hero is down (`dialogue.gd`).
- **Tuning panel**: a Scorpion row (HP, XP). The enemy and the stamina / focus / drop rows are 12 px apart now (were 13) so it all fits.
- **Gallery** (G): the scorpion, stinging in a loop.
- Saves: no format change (`save.gd VERSION` stays 4). New flags go in the quest's flags; the scorpions are new rows at the end of the
  town's plan.
- Tests: world 210/0, fight 82/0, no script errors. Asserts moved, none deleted:
  - `fight.gd`: "the hero gets up with full HP / back at the gate / XP kept" became "the death screen is up and paused / it lists the
    saves on disk then New game / nothing changes until a save is picked"; "3 bandits and 6 rats" now also counts the 3 scorpions.
  - `world.gd`: the storeroom's respawn spot became its entry spot, and the two falls (storeroom, town) check the death screen, the place
    it names and the saves it lists, then carry on with the new `suite.gd get_up()`.
  - A throwaway headless check (not kept; the suites' scratch save folder) passed 51/51. It covered these things:
    - the scorpions' homes free and not nudged, and the den, page 2, the tablet and the note all reachable;
    - the new texts fitting the reader;
    - a real sting (wind-up first, 10 HP, 5 ticks, 30 in all);
    - the 1 HP floor, a rest curing it, and Farnaka poisoned, ticked and cured by a fall or a rest;
    - all three journal spots (entry, reader, XP, can't take twice; page 2 doesn't finish the search);
    - the death screen with no saves (New game only), then with the autosave and slot 2, S moving the choice, no menu behind it.
  - Not checked: how the scorpion, its sting, the den, the tablet, the note, the purple poison and the death screen look on screen,
    and whether the scorpions feel fair (play it). Loading from the death screen is the menu's own `load_game()`, which the suites can't
    run, so it was not exercised here either.
- Not in this stage: an antidote item, poison on the tuning panel, saving a running poison, poison on other enemies, a confirm before
  New game on the death screen, the scientist-intentions area (an idea for later), the camp's soldiers' logs (the jail note is the one
  record of the raid so far).

### Stage 7i: the squad in the fight, slower stamina, revive and focus potions, giving items (2026-10-28)
The user's play-test notes, planned and decided with them (the decisions are now in the design doc, sections 7 and 8).
- **Stamina** (`combat.gd STAMINA`): it now refills at 15 a second, starting 1.2 s after the last spend (it was 60 after 0.5 s), so an
  empty bar takes about 8 s to fill.
- **The fight stage** (`rat.gd in_fight()`, `combat.gd fighting()`): an enemy is in the fight once it has spotted the hero, or once he
  struck first. That is `after_hero()` minus `"alert"`.
  - The bug: Farnaka sometimes shot before a fight began. He picked his targets with `after_hero()`, which is already true while an
    enemy's "?" meter is rising. `rider.gd _pick_target` now uses `in_fight()`.
  - Rest spots and the boss bar still use `after_hero()`.
- **Enemies choose a target** (`rat.gd foe`, `_pick_foe()`, `combat.gd FOE`).
  - While it chases, every 0.4 s an enemy in the fight goes after the nearest of the hero and the companions standing with him. The
    hero counts as 24 px nearer, so he wins a close call.
  - It never switches during a wind-up or an attack. On patrol, return, flee or cower it minds the hero again, and it turns back to the
    hero when the companion it was after falls.
  - Enemies still only notice the hero, so a companion never starts a fight.
  - Attacks aimed at one body (a lunge, the chief's charge contact) hurt that `foe`. The giant's slam, the chief's sweep arc and his
    charge path hurt everyone they reach. The slingers aim at their `foe`, and their stones hit a companion standing in the way.
  - New helpers in `combat.gd`: `mates()`, `targets()` and `hurt_body()`.
- **Farnaka can be hurt** (`rider.gd`; numbers in `combat.gd RIDER`).
  - He has 80 HP, with 0.6 s after each hit before the next can land, and no knock-back.
  - At 0 HP he falls (`down`, a flag on top of his state, so an order given meanwhile keeps him down). He lies on his side, greyed. He
    is carried through doors still down, and he cannot be talked to; Disband is refused, and the Squad tab locks his orders.
  - **A Reviving Potion** gets him up with 10 % of his HP (8). Use it with E beside him (an "E Revive" tag, dimmed without a potion;
    `dialogue.gd _nearest_fallen()` -> `main.revive_by_hand()`), or from the menu.
  - A rest gets him up at full HP, and so does "You fell" (the game's full reset). He does not heal by himself, the same as the hero.
  - A scene that walks him (the hall's return) gets him up first.
  - The hero is never revived: he falls as before.
- **His focus and the volley**: each arrow of his that lands adds 5 (`combat.gd shoot()` now records who shot, and `_update_shots`
  calls `arrow_landed()`). With a full bar of 50, his next shot is a volley of 3 arrows fanned 0.2 rad apart, which empties it, with a
  "Volley!" text.
- **Moving in a fight** (`rider.gd _skirmish()`, `_walk_back()`, `_go()`).
  - On Follow, out of a fight he walks the trail as before. In a fight he moves on his own: he backs away from an enemy nearer than
    60 px, comes back toward the hero when he is more than 120 px away or has no shot, stands still while drawing, and steers round
    props.
  - When he is stuck for 1 s, he joins the hero at once. When the fight ends he walks back to the hero, then takes up the trail.
  - On Wait he holds his spot, in a fight or not, even while hit.
- **His bars**: while a fight is on, his HP (green) and focus (blue) bars are over his head; his HP bar also shows whenever he is hurt.
  The HUD has a line per companion under "Foes slain": his name with thin HP and focus bars, or "FALLEN" blinking red
  (`hud.gd _draw_mates()`). The colour is `menu.gd MATE_HP_COL`.
- **New items** (`items.gd`, all sold at Nidu's; the descriptions are grounded, with no magic):
  - the Small Focus Potion (+25 focus, 30 coins) and the Large Focus Potion (+50, 50), which are bitter herb tea, the game's "mana";
  - the Reviving Potion (200 coins), a healer's cordial of wine, myrrh and herbs, with linen to bind a wound.
- **Giving items** (one function for both menus, `main.gd use_item(id, target)`):
  - In the Player tab, E on food or a potion with a companion here opens "Use on: You / Farnaka / Back". Each name shows the bar
    the item fills. The Reviving Potion lists only the fallen, and a fallen companion is greyed for anything else.
  - In the Squad tab, a new **Give item** command turns the Commands box into the list of food and potions carried (only the Reviving
    Potion while he is down).
  - The Squad tab's details now show his HP and focus, with the stats two to a row so the box still fits.
- **Saves** (`save.gd VERSION` 4): each squad member keeps his HP, focus and whether he has fallen. A version 3 save loads with him at
  full HP, standing.
- Tests: no assert moved; world 210/0, fight 82/0, no script errors.
  - A throwaway headless check (not kept; the suites' scratch save folder) passed 41/41. It covered these things:
    - stamina: no refill before 1.2 s, 60 after 4 s, and full after 7 s;
    - an alert rat that is after the hero but not in the fight is not shot, and a chasing one starts the fight;
    - the rat switches to a waiting Farnaka who is nearer, bites him, and he does not move;
    - he falls at 0 HP, is no longer a target, and the rat turns back to the hero;
    - an order keeps him down, and Disband is refused;
    - a door carries him along, still down;
    - E without a potion does nothing, and E with one gets him up at 8 HP;
    - revives from the Player tab and from the Squad tab's Give item;
    - bread and a focus potion given to him, and a focus potion for the hero;
    - the 3-arrow volley, and an arrow landing that feeds his focus;
    - a rest and "You fell" get him up at full HP;
    - a save and load keep his fall and focus, and a version 3 save is upgraded;
    - in a fight he backs away and stays near the hero, and afterwards he walks back to him.
  - Not checked: how the bars, the fallen pose, the volley and the menu boxes look on screen, and how the fights feel (play it).
- Not in this stage: slow healing out of a fight, more companions or their gear, other companion specials, enemies that notice
  companions, a quick-use potion key, focus or reviving potions as drops, and the companion's numbers or enemy damage on the tuning panel.

### Stage 7h: the shop at Scribe Nidu's stall (2026-10-28)
The last stage of the agreed roadmap's step 3 (the roadmap set by the user on 2026-10-26 is now done).
- **`shop.gd`** (new, `main.shop`): a panel in the menu's era-neutral style (its colours, panel size and the shared `detail_head()`, now
  static in `menu.gd`), pausing the game like the menu. `SHOPS` is the data, keyed by the keeper: Nidu's stall sells Bread, Apple, the
  Small and the Large Potion and buys rare finds.
  - **Buy:** the goods with their `items.gd "price"` (dimmed when the coins don't reach); E buys one, with a status line ("Bought: Bread.
    -10 coins") instead of a HUD toast, so a run of buys doesn't pile up toasts. Not enough coins: "Not enough coins." Stock never runs out.
  - **Sell:** the rare finds carried, at their `"sell"`; the details say what the find adds while carried and that selling gives it up.
    The first E asks ("Press E again to sell it.  You lose its +10 max HP."), the second sells, and `progress.apply_max()` runs at once.
    Food, story items and the lasso can't be sold. Nothing sold can be bought back.
  - **The keeper's strip** at the top: a 28 px portrait, the name, and a line from `dialogue.gd SHOP_LINES` (a greeting, then a reply
    after each buy, sale or a sale that the coins don't cover; placeholder words).
  - Keys: A/D switch Buy / Sell, W/S select, E buy / sell, Tab or Esc leave.
- **Nidu's conversation** (`dialogue.gd TALK "nidu"`): the first time, the two ledger lines (the second now mentions supplies for sale)
  and then the question; later, the question alone. "Show me your goods." opens the shop (a new `"then"` form, `"shop_<keeper>"`, handled in
  `dialogue._close()` like `squad_*`); "Nothing for now." gets "Safe road, then.". Historical note in the comment: road stations of this
  period issued rations to travellers and scribes recorded each one, so a scribe selling supplies and writing them down fits.
- **The coin mark:** `dialogue.mark_for()` returns `"shop"` for a keeper (`shop.keeps()`), and `npc.gd` draws the yellow coin icon in the
  white oval instead of "...".
- **Portraits** (`dialogue.gd draw_portrait()`): the placeholder silhouette is drawn in a 56 px square and scaled to its box. It used to
  keep its 56 px sizes, so in the Squad tab's 31 px cards the head spilled about 8 px below the frame. The dialogue box (56 px) looks the same.
- Saves: nothing new to save (coins and items are in the inventory already); `save.gd VERSION` stays 3.
- Tests: no assert moved; world 210/0, fight 82/0, no script errors. A throwaway headless check (not kept; the suites' scratch save folder)
  passed 33/33: Nidu's coin mark; the first and later conversations; the choice opening the shop and pausing; no buying at 0 coins; Bread
  and Large Potions bought down to 30 coins and a third refused; nothing to sell, then only the armlet listed (not bread); the confirm, the
  sale for 250 and max HP back from 110 to 100 at once; A/D, S and E through real input events; Tab leaving without opening the menu;
  "Nothing for now." keeping the shop shut; the dialogue box and the shop panel drawing without errors.
  Not checked: how the panel and the coin mark look on screen (play it).
- Not in this stage: buying back, limited or restocking stock, selling food or other items, maps for sale, focus-refill items, a quick-heal
  key, other shops or prices per era, showing the goods on Nidu's stall (it still shows pots).

### Stage 7g: potions, rare finds, prices, pickups and drops (2026-10-28)
The third stage from the items-and-XP discussion, done straight after 7f at the user's request (one F5 play-test for both).
- **Items** (`items.gd`): every item has a `"price"` for the shop (7h): Bread 10, Apple 25, Small Potion 50, Large Potion 80, so a
  higher tier gives more HP per coin (1.0, 1.2, 1.5, 1.9). New: the **Small Potion** (75 HP) and the **Large Potion** (150 HP), healing
  items with `"use": "drink"` (the menu says "E drink", "You're not hurt."), drawn as a waxed clay flask and a glazed one. New kind
  **"rare"** ("Rare finds"): a boss's keepsake that adds to the hero's maximums while carried (`"bonus"`, counted by
  `progress.gd apply_max()`, worked out again by `main.gd` whenever the inventory changes) and that a shop will buy (`"sell"`): the
  giant's **carnelian necklace** (+10 max stamina, sells for 120) and the chief's **ibex armlet** (+10 max HP, 250); placeholder words.
- **Drops** (`combat.gd DROPS`, chances through `tune` and on the T panel's two DROPS rows): rat 10% bread; bandit 45% 5-12 coins, 15%
  bread, 8% small potion; slinger 35% 3-8 coins, 10% small potion; the giant always its necklace and a small potion; the chief always
  his armlet, a large potion and 50 coins. Each row rolls on its own (`combat.rng`, seeded by the suites). A drop lies where the enemy
  fell (`level.gd drop()`, nudged aside from other drops) and never vanishes; a respawned foe rolls again.
- **Pickups** (`level.gd`, every map): a map's `PICKUPS` rows `[id, item, n, foot, look]` become y-sorted props that draw the item with a
  shadow and a glint every 2.2 s (`items.gd pickup()`); walking within `PICKUP_R` (10 px) takes it, with the usual "+N" toast. A map can
  draw one its own way (`draw_look()`): the cave's coin bags. Placed: the ruins (a small potion among the broken pillars, 15 coins by the
  north pillar); the storeroom (2 bread by the sacks, a small potion at the barn's gate); the cave's raided camp (the riders' 2 bread,
  an apple, a small potion); the chief's room (the four coin bags, 25 coins each; they were scenery before). None at the stalls.
- **Saves:** each map saves the ids taken (`"taken"`) and the drops still lying (`"drops"`); an older save has neither, so it needs no
  upgrade step.
- **The king's reward** (`hall.gd RETURN_COINS`): 20 -> 100 coins, so it buys something at these prices.
- Tests: no assert moved; the suites now seed the drop rolls. world 210/0, fight 82/0. A throwaway headless check (not kept) passed
  46/46: every pickup stands on free ground reachable from the map's entrance; the giant's drops; taking the necklace raises max stamina;
  a taken pickup and a lying drop survive a save and a load; the Player tab (weapons, potions, rare finds) and the T panel draw.
- Not in this stage: the shop (7h, at Nidu's); equipment slots and armour; focus-refill items; a quick-heal key; story items as rewards
  (a jailer's key, the seal ring); XP for avoiding fights.

### Stage 7f: hero level, weapon XP, enemy levels, respawning, the Player tab (2026-10-28)
The second stage from the items-and-XP discussion (the user's decisions are in the design doc, section 9 "Levels and weapon XP").
- **`progress.gd`** (new, `main.progress`): the hero's XP and level. The next level needs `100 + 50 x (level - 1)` XP; each adds +10 max
  HP, +10 stamina, +5 focus and fills the bars ("Level 3!" over the hero, a toast with the new maximums). The level stops at
  `START_CAP` 10 and only a teacher can raise it (`raise_cap()`, no caller yet); at the cap XP stops and the bar says MAX. The maximums
  follow from the level (`apply_max()`), so they are never saved.
- **XP sources:** kills, cut when the hero is above the foe (`kill_xp()`: x (1 - 0.25 per level between), never under 10%); every enemy
  has a level (`combat.gd FOE_LEVEL`: rat 1, bandit and slinger 2, giant 3, chief 4; a plan row can set its own), shown on the boss bar.
  Each main-story step and the side quest give XP the first time (`quest.gd STEPS` / `SIDE` `"xp"`, 410 + 60 in Era 1) and each new
  journal entry 20 (`LOG_XP`), never cut, with a "+N XP" toast.
- **Weapon XP** (`progress.gd WEAPONS`): Unarmed (1 per punch and 2 per kick that land on an enemy, not the dummy) and the Lasso (3 per
  catch, 5 per strong catch or bind; `combat.gd WEAPON_XP`). Each Unarmed level adds +1 punch and +2 kick damage (`hit_dmg()`); each Lasso
  level +8 px of reach and 0.15 s off its cooldowns. Weapons stop at level 5 (`WEAPON_START_CAP`). A weapon level never unlocks a move.
- **Respawning** (`combat.gd respawn()`): walking back into a map (`main._switch_level`, not the first time) or resting there brings back
  every ordinary planned enemy that died, at home, unless its home is within `RESPAWN_CLEAR` (160 px) of the hero (it comes next time).
  A group with nobody left alive goes back to sleep first. The giant and the chief never come back, nor do enemies added during play
  (the ambush, the camp rats, the summons, the boss-room slingers). The cave refills fully, bandits included.
- **HUD:** "XP N" became "Lv N" with a thin XP bar; the boss bar shows "Lv N"; toasts for XP, level-ups and weapon level-ups.
- **Menu:** the Inventory tab became the **Player** tab (I opens it): a top strip (level, XP bar and numbers, HP / stamina / focus), then
  the list with **Weapons** first (Unarmed and the Lasso, each with its level and a small XP bar; the lasso item is not listed twice),
  then the items by kind; a weapon's details give its level and cap, XP to the next level ("A teacher can take you further" at the top),
  its bonus now and next, and its stamina / focus costs. The bar colours moved to `menu.gd`'s style constants (the HUD uses them).
- **Saves:** `save.gd VERSION` 3. The hero block holds `xp`, `cap`, `wxp`, `wcap` (`progress.state()`). A version-2 save is upgraded as it
  is read: the XP of the story steps, side quest and journal entries already done is added to its kill XP. `main.gd` now puts back the
  inventory before the hero, since a rare find changes his maximums.
- Tests: the XP asserts read `main.progress.xp`; `world.gd`'s frozen-town and storeroom checks now expect the killed rat back on
  re-entry (one more alive). world 210/0, fight 82/0. The throwaway check above also covered this stage: level 3 at 250 XP (120 / 120 /
  60), 5 XP from a rat at level 3, Unarmed level 2 (punch 11, kick 22), the Lasso's reach and cooldown, the weapon cap, story XP given
  once, the giant never respawning while the entrance rat does, and v1 and v2 saves upgraded and loaded.
- Not in this stage: moves or chains from weapon levels; a teacher who raises a cap; skill points; XP for avoiding fights; armour;
  enemy stats that scale with their level.

### Stage 7e: HP, stamina, focus, the boss bar, Bread / Apple / Coins (2026-10-28)
The first of three stages from the items-and-XP discussion with the user (7e bars, 7f levels and weapon XP, 7g pickups and drops; the
shop moves to 7h). The user's decisions: HP 100, stamina 100 (costs depend on the weapon), focus 50 for special moves (the "MP" bar,
named Focus), a boss bar at the bottom, Bread / Apple / small and large potions, plain yellow Coins.
- **Rescale:** damage to the hero x20 (an ordinary hit 20, the giant's lunge and slam and the chief's charge 40); enemy HP and the hero's
  damage x10 (rat 30 (runs at 10), bandit 60, slinger 20, giant 120, chief 200; punch 10, kick 20, the rider's arrow 10). Every fight takes
  the same number of hits as before.
- **Stamina** (`player.gd BASE_STAMINA`, `combat.gd STAMINA`, each `COMBO` swing's `"stamina"`, `DODGE` / `LASSO` `"stamina"`): punch 10,
  kick 20 (a full combo 40), dodge 25, lasso 20. A move starts while any stamina is left and spends down to 0; at 0 the press does
  nothing and the bar flashes (`combat._spend()`). It refills at 60 per second, 0.5 s after the last spend (`_refill()`).
- **Focus** (`player.gd BASE_FOCUS`, `combat.gd FOCUS`): +3 per hit that lands on an enemy (not the dummy), +1 per second. Its first use is
  the **strong lasso**: hold Q (the hero can turn but not walk, `player.aiming`; a ring closes round him and glows blue when ready, after
  `LASSO "charge"` 0.5 s), let go to throw it for 25 focus and no stamina. 1.5x reach; a light foe is pulled and stunned twice as long
  (`rat.gd pull(strong)`); a heavy one (a bandit) is bound where he stands for 1.5 s (`bind()`, the new "bound" state, rope coils drawn
  round his arms, "Bound!"); bosses refuse it ("Too heavy!"). Not enough focus: the ordinary throw, and the focus bar flashes.
  A tap of Q is the ordinary throw, now thrown when Q is let go.
- **HUD** (`hud.gd _draw_bars()`): the hearts became a heart icon, the HP bar and "72 / 100", the stamina bar and the focus bar (a white
  notch at the strong lasso's cost). Each bar is 90 px at its base maximum and grows with it later (up to 170 px).
  **Boss bar** (`_draw_boss()`, `combat.boss()`, names in `dialogue.gd BOSSES`, placeholder "The Giant Rat" / "Chief of the Band"):
  bottom centre while the giant or the chief is after the hero, with a notch at half health; their small over-head bars hide meanwhile.
- **Items:** flatbread -> Bread (10 HP), pomegranate -> Apple (30 HP, new icon), silver -> Coins (yellow coin icon). Arshan gives 2 bread
  and an apple; the king's lines say coins (`hall.gd RETURN_COINS`, still 20). The menu says "Coins N" and "E eat (+N HP)".
- **Tuning panel:** a STAMINA row (punch, kick, dodge, lasso, refill/s) and a FOCUS row (per hit, refill/s, strong lasso); HP steps of 10,
  damage steps of 5; E prints them in combat.gd form.
- **Saves:** `save.gd VERSION` 2. The hero's HP, stamina and focus are saved, not the maximums. A version-1 save is upgraded as it is read
  (`_upgrade()`: hearts x20, the three items renamed), so the old slots still load.
- **The captain leaves the cave (bug fix, the user's report):** once the hero has cut Vahauka down and gone back to the king, the cave
  shows his stake empty with its ropes cut (`cave.gd _captain_gone()`, on arriving in the cave or loading a save); the king says he is with
  the healers. It is not done at the moment of leaving, so he doesn't vanish during the fade.
- Tests: the asserts moved to the new numbers (HP 100, rat 30, bandit 60, giant 120, slam and lunge 40). world 208/0, fight 82/0.
  A throwaway headless check (not kept) also passed 21/21 with no script errors: the tuning panel and the inventory draw; stamina costs,
  refusal at 0 and refill; the strong lasso binding a bandit out of the ordinary lasso's reach for 25 focus and no stamina; the boss bar for
  the waking giant; a version-1 save upgraded and loaded.
- Not in this stage: levels, weapon XP, enemy levels, respawning (7f); potions, rare finds, pickups, drops, prices (7g); the shop (7h);
  armour; focus moves other than the strong lasso; a teacher for the strong lasso.

### Stage 7d follow-ups 4: short rest notices, Quit game (2026-10-27)
- Resting says just "Game saved." (was "You rest at the band's fire. Game saved."). When an enemy is hunting you, the rest notice
  and the menu's Save both say "Enemies nearby." (`main.gd save_block()`).
- The System tab has a Quit game row under New game. It asks for a second E ("Anything not saved is lost."), then `get_tree().quit()`.
- The System tab's autosave hint is shorter, so it no longer runs off the panel.
- Tests: world 208/0, fight 82/0.

### Stage 7d follow-ups 3: resting fixed, rest prompt, Squad tab, A/D in choices (2026-10-27)
The user's play-test notes:
- **Couldn't rest at the band's fire after clearing the camp.** There were two causes:
  - The rest rect covered only the strip south of the fire, so a hero standing north of it had no E. It is now a ring all round the fire,
    `Rect2(660, 552, 60, 50)`, with the prompt to the east of it.
  - `rest_open()` counted a fleeing or cowering enemy (`after_hero()` is true for those), so one wounded rat hiding anywhere blocked
    resting for good. New `rat.gd hunting()` (after the hero, not fleeing or cowering) is used by `rest_open()` and so by
    `save_block()`. `after_hero()` is unchanged, so the rider still shoots fleeing ones.
- **The rest prompt says what it does:** `level.gd _draw_e_box(n, at, label, dim)` can draw a small tag beside the E. A rest spot shows
  "E Rest", "E Enemies nearby" (dimmed) or "E Not now" (dimmed, while `busy()`).
  - `near_rest()` again returns the spot either way, so E reaches `main.rest()`, which says why not.
- **Squad tab rebuilt** after the user's reference picture, in the era-neutral style, with real data only:
  - left: a card per companion (portrait, name, role, status);
  - right: DETAILS (role, status, then `squad.gd MATES "stats"`: arrow damage read through tune, how often he shoots; the Equipment
    slot from `"gear"`, his bow) and a COMMANDS box (Follow / Wait here / Disband / Back) with 10x10 pixel icons (`menu.gd ICONS`).
  - Locked orders show "(locked)", and the reason is wrapped under the box when one is selected (it was cut off before).
  - E opens the commands, E gives the order, and the commands close again.
- **A/D in choices:** `menu.gd _inner_open()` (a slot's actions or a companion's commands). While a choice is open, A/D move inside it
  and never switch tabs. Tab/Esc backs out of it first (`_close_inner()`), and the next press closes the menu. The footer reads
  "A/D or W/S choose   E confirm   Esc back".
- **Tests:** world 208/0, fight 82/0, no assert changed. A throwaway check (deleted; scratch saves) confirmed:
  - `rest_open()` for chase / alert (closed) and flee / cower / patrol (open);
  - four points round the fire inside the ring;
  - the Squad commands: D D moved to Disband without leaving the tab, Disband was refused with the reason, Esc backed out, then D
    switched tabs and Esc closed the menu.
  - Not checked: how the new Squad tab and the rest tag look on screen (play it).
- Not in this stage: companion hearts, levels and other stats, Heal, skills, a big character figure.

### Stage 7d follow-ups 2: fewer rest spots (2026-10-27)
The user's notes:
- **Rest spots:**
  - Kept: the town well, and in the cave the band's fire (the last fire before the steps up to the chief).
  - Removed: the cook's fire under the red canopy and the raided camp's fire (the riders' fire). Both fires are still drawn; only their
    `RESTS` rows went.
- **Only while no enemy is after you:**
  - `level.gd rest_open()` is false while any living enemy on the map is after the hero (`rat.after_hero()`).
  - `near_rest()` returns nothing and `_draw_rest_prompt` hides the E box until then.
  - `main.gd save_block()` uses the same `rest_open()` for its "Not while enemies are after you." (since follow-ups 4: "Enemies nearby.")
- **Low-heart autosave (the user's decision):** no change. A save keeps the hearts the hero had, and loading (also after dying) starts
  with them. The HP system will be reworked later.
- **Tests:** world 208/0, fight 82/0; no assert needed changing. A throwaway check (deleted; scratch save folder) confirmed: one rest
  spot per map, and the well's rest spot closes while an enemy chases and opens again when it stops.

### Stage 7d follow-ups: journal tab, fewer place names, Disband, save slots (2026-10-27)
The user's notes after playing 7d.
- **Journal tab:** the menu's tabs are now Inventory / Quests / Journal / Squad / System.
  - Quests shows the thread's steps and the optional objectives across the whole panel.
  - Journal lists the logs and clues (W/S, E reads).
  - J and a map's `read_log()` open the Journal tab.
- **Only well-known places are named** (the user's rule):
  - the cave's PLACES are gone, so it shows only "The Hill Cave". Kept: Waystation Road, Waystation Town, The Ancient Ruins, The King's
    Courtyard, The Great Hall, The Storeroom.
  - The jail's `saw_cage` note moved to a new unnamed-spot list: `level.gd notes` (`[Rect2, quest event]`, from a map's `NOTES` const,
    walked by `check_places()`).
- **Disband:** the squad order "Stop following" is renamed Disband. It behaves the same (he goes to his spot in the hall and stays in the
  squad).
  - New rule: a companion the story still needs can't be disbanded. `quest.gd NEEDS` holds the rows (`mate`, `from` flag, `until` flag,
    `why`) and `quest.needed(mate)` gives the reason.
  - Farnaka is needed from `rider_freed` until `return_done` ("escort him safely to the king first").
  - `main.gd squad_order("home")` refuses with a HUD notice, which covers every caller. The Squad tab greys Disband with the reason, and
    `dialogue.gd _drop_locked_orders()` leaves his "Go back to the hall." choice out.
  - `squad.leave_era()` ignores the lock, since that is the story's own move.
- **Save slots:** one autosave and four slots (`save.gd SLOTS`, files `save_auto.json`, `save_1.json`..`save_4.json` in `Save.dir`).
  - An old `save.json` becomes slot 1 (`Save.migrate()`, run at start).
  - `main.gd autosave()` writes the autosave and shows "Autosaved.". It is asked for (`autosave_due`) after every door and whenever
    `quest.stage` changes (checked in `main._process`, so maps never save), and is written as soon as `save_block()` allows.
  - Resting writes the autosave at once.
  - The System tab lists Autosave, Slot 1-4 (place and time, or Empty) and New game. E on a slot opens Save here / Load / Back (the
    autosave: Load / Back). Overwriting a used slot, loading and New game each ask for a second E.
  - `load_game(slot)` puts the slot on the root mark and `main._ready` reads it.
- **Tests:** `suite.gd` points `Save.dir` at `user://test_saves/` and empties it at the end. No assert needed changing. world 208/0,
  fight 82/0.
  - A throwaway check (not kept; it wrote only to a scratch folder, deleted afterwards) confirmed: the `needed()` window, the five tabs,
    an autosave after a stage change, a save to slot 2, and the cave's 0 places / 1 note.
  - Not checked yet: the menu's new layout on screen (play it).
- Not in this stage: tuning values written to a file, more than four slots, naming or deleting slots, a picture per slot, Disband removing
  him from the squad.

### Stage 7d: saving (2026-10-27)
The fourth of the six stages. The user's decision (design doc, section 11): save at rest spots (a well, a fireplace) and from the menu.
- **`save.gd`** (new): one slot, `user://save.json`, JSON with a `version`.
  - Saved: the map, spot and facing, hearts and XP, foes slain, the quest (stage, flags, journal), the inventory, the squad per era (id
    and order only, never a map or spot), and every built map's `save_state()`.
  - Maps not visited since a load carry their saved state forward (`main.saved_maps`).
  - JSON turns numbers into floats, so the `apply_*` helpers convert them back.
- **Map state** (`level.gd`):
  - `dead_plan`: the `enemy_plan()` indices of the planned enemies killed (`rat.gd plan_i`, noted by `combat.rat_killed`; `combat.attach`
    skips them);
  - `spawned`: the living enemies a map added during play (camp rats, the band waiting after the ambush, slingers), which come back at
    home;
  - living enemies come back at home at full health, and sleeping groups sleep again (the healing rule);
  - the cave adds `cage_opened`, `bow_taken`, `camp_sprung`, `wave_done`, `seal_lifted`, `captain_cut`, `boss_done`. On load, the rider
    is in the squad, out of the cage waiting, or left behind, as he was;
  - the hall adds `intro_done` (the king talkable, no scene).
- **Loading:**
  - The menu's Load sets a mark on the scene tree's root and reloads the scene. `main._ready` sees the mark and builds the saved map
    instead of the town.
  - It puts the hero, quest and inventory back, and rebuilds the squad's nodes (`_rebuild_squad`: following ones beside the hero, ones at
    home on their home map or off the maps until it is built).
  - The start map gets its state at once; every other map gets it when first built (`_apply_saved`).
  - The suites build `main.tscn` without the mark, so a save on disk never changes a test. There is no title screen; R still starts a
    new game.
- **When you can save** (`main.save_block()`): not while fallen or travelling, not while any enemy is after you, and not while the map
  is `busy()` (the cave's ambush, the chief's fight and the 1.5 s before his room opens; the hall's scenes).
- **Rest spots** (`RESTS` data, `level.rests`, E boxes): the town well, the cook's fire, the raided camp's fire and the band's fire.
  - E rests: hearts back to full, then the game is saved, and a notice says so in the middle of the screen (`hud.notice()`).
  - If a save isn't allowed, the notice says why.
- **The menu's System tab:** Save (greyed with the reason when not allowed); Load the last save and New game (each asks for a second E,
  "Anything not saved is lost."); the last save's place and time. Status lines in the menu now span the panel (one was cut off).
- **Fix:** `main._exit_tree()` frees the maps you left (out of the scene tree), so a restart or a load no longer leaks them (the
  roadmap's confirmed bug).
- Tests: `world.gd` 208 and `fight.gd` 82 pass, 0 fail, no script errors or leaks (no asserts changed). A throwaway headless check
  (not kept; it wrote only to a scratch save file, deleted afterwards) passed 42 of 42:
  - the town round trip: spot, stats, inventory without a second lasso, quest, a dead rat staying dead;
  - the cave round trip with the squad: Farnaka beside the hero, the cage open, the bow taken, the ambush over, the band members added
    during play back, a dead lookout staying dead, then out through the door;
  - saving blocked by a chasing rat and by the ambush; every rest spot reachable; resting at the well;
  - a companion at home before the hall exists, loaded off the maps, then at his spot in the hall; the hall's king already met;
  - the real reload path from the System tab (second E), leaving the game unpaused.
  Windowed screenshots of the System tab and the rest notice were checked.
- Not in this stage: more than one slot, a title screen, autosave on doors, saving the giant rat's "already summoned" (it can summon
  again after a load), saving which sleeping groups were awake.

### Stage 7c: the squad (2026-10-27)
The third of the six stages. The user's rules (design doc, section 7 "Companions (squad)"):
- companions stay in their own era, and the squad is kept per era, not per map;
- three orders: Follow; Wait; Stop following (he goes to a home spot and stays in the squad);
- leaving an era sends everyone home.
- **`squad.gd`** (new): `MATES` (Farnaka: archer, Era 1, home by the throne in the great hall) and the members per era with their order.
  `level.gd` gained `era` (1 everywhere for now). `leave_era()` exists but has no caller until there is time travel.
- **Through doors** (`main.gd _carry_squad`): on every map change each Follow or Wait member of the era is moved to the new map (off
  whichever map or holder had him), set to Follow and snapped behind the hero at the spawn (`rider.arrive()`). One told to Follow from
  the Squad tab while at home on another map catches up this way at the next door.
- **Stop following** (`main.gd squad_order("home")`):
  - he stops, fades out over 0.5 s and is placed at his home spot (`rider.at_home()`): talkable, "Come with me." / "Stay here for now.";
  - if the hall hasn't been built yet he waits off the maps (under `main`, hidden) and `_place_home()` puts him there when the hero
    first arrives;
  - calling him back mid-fade stops the fade.
- **Wait** (`rider.hold()`): he stands, still shoots enemies already after the hero, and is talkable with "Come with me." / "Go back
  to the hall." / "Keep watch here."
  - Dialogue choices can have their own `"then"`, and up to 3 choices (W/S).
  - A "then" starting with `squad_` is a squad order for the person spoken to (`dialogue.squad_order` -> `main.squad_order`).
  - `npc.gd talk_id` picks his `rider_wait` / `rider_home` conversations.
- **The cave:**
  - the talk that frees him now also puts him in the squad (`squad.join`);
  - his shouts play only when he is here with the hero (`_rider_with_us()`);
  - `_go_to_king` calls him to Follow (from wherever he is) instead of hiding him;
  - the cave builds a caged rider only if he isn't in the squad yet (for 7d's loading).
- **The hall:** the return scene no longer builds a second rider (`RIDER_HALL` and the `rider_hall` person and talk are gone). The
  squad's own rider, carried in through the door, is placed at `RIDER_FROM` and walked up to `RIDER_STOP` (`rider.walk_to()`). After the
  scene he goes on following.
- **The menu's Squad tab** shows each companion of this era:
  - portrait (`dialogue.draw_portrait()`, now shared), name, role and what he is doing ("Following you" / "Catching up with you" /
    "Holding his position" / "At The Great Hall");
  - the three orders. W/S selects one and E gives it; Wait only works while he is with you.
- His "?" mark only shows before he has joined (`dialogue.mark_for`).
- Tests: `world.gd` 208 and `fight.gd` 82 pass, 0 fail, no script errors (no asserts changed). A throwaway headless check (not kept)
  passed 22 of 22:
  - the join; out of the cave with the hero; Wait from the tab;
  - a waiting rider staying put, then brought through a door;
  - Stop following before the hall exists (off the maps), then at his spot in the hall;
  - "Come with me." at home; home and Follow on the same map; a call back mid-fade;
  - the return scene with the squad's rider walking up and speaking, then following.
  Windowed screenshots of the Squad tab and the three-choice talk were checked.
- Not in this stage: companion health, healing or equipment; more members (the captain, hired guards); companion pathfinding (he still
  walks your trail, through props); time travel and the all-eras gathering; saving the squad (7d).

### Stage 7b: objectives and quests, the HUD layout, place names, the stranger's trail (2026-10-27)
The second of the six stages. The user's decisions behind it (design doc): the scientist's trail runs through a stranger the rider saw
heading for the ancient ruins, where the hero finds prints, a log and a dropped object; the HUD is stacked at the top left, with place
names at the top right.
- **`quest.gd` rewritten:**
  - `STEPS` is the main thread as data (the table under "Maps and how they connect"). Maps and conversations report events with
    `note(event)`; the objective is the step after the furthest one done, so it never goes back and sequence breaks still read right.
  - `stage` and `set_stage()` stay, so the tests' "stage 1" and "Find King Rostam" still hold.
  - `SIDE` holds optional objectives (shown / done / missed by events): "Free the caged rider".
  - A journal (`journal`, `add_journal()`).
- **Events wired:**
  - Datis's talk: a new TALK key `"note": "met_datis"` replaces `"set_stage": 1`.
  - The hall: `_intro_finished` notes `met_king`; the return notes `return_done`.
  - The cave: `arrived()` notes `cave_entered`; the cage `rider_freed`; the chief's fall `chief_down` (at once, not only at the return);
    `_go_to_king` notes `captain_found` (`rider_joined` is still set directly).
- **HUD (the user's layout):**
  - Top left: the objective box, with "Optional: ..." lines for open optional objectives and the "NEW OBJECTIVE" flash; under it the
    hearts, then XP and foes slain. With no objective the hearts sit at the top.
  - The box uses the menu's era-neutral colours.
  - New toasts: "Journal: <title>" (accent border) beside the item toasts.
- **Place names:** `level.gd place_name` / `places` (from each map's `PLACES` const: `[name, Rect2, quest note]`) and `place_at()`.
  - The HUD shows the name of the place the hero walks into at the top right: fade in, about 2.5 s, fade out. It must hold 0.3 s first,
    and the same name doesn't show again within 20 s.
  - Names: Waystation Road (the town map outside the walls), Waystation Town, The Ancient Ruins, The Storeroom, The King's Courtyard,
    The Great Hall, The Hill Cave, and in the cave The Raided Camp, The Band's Jail (walking in notes `saw_cage`), The Band's Camp and
    The Chief's Hall.
  - `main.gd _process` calls `world.check_places()` for the notes.
- **The stranger's trail:**
  - Both return scenes gained lines (placeholder words). With the rider, Farnaka tells the king about a stranger in odd clothes and
    boots who passed the camp the evening before the raid, going north toward the old ruins. Without him, the king passes on what
    Vahauka saw.
  - After the return the ruins hold three things (`world_waystation.gd`, data consts; nothing shows before `return_done`):
    - boot prints from the road by the east gate, up past the town's east wall and west into the ruins (`PRINTS`, a walkable path
      found with a flood fill; `Props.boot_print`, a ridged sole and a heel). Walking along them writes "Boot prints in the ruins" in
      the journal.
    - the stranger's dropped brass box (a compass the hero has no word for; `Props.brass_box`, glints every 2 s). E takes it: a story
      item `brass_box` with its own icon, plus a journal entry.
    - a torn notebook page under a stone (`Props.torn_page`). E opens it in the reader, and it joins the journal as the first log.
  - Both taken = `ruins_searched`, and the objective becomes "The trail goes on...". The log ends pointing to "the coast", a
    placeholder hint at Era 2.
- **The menu's Quests tab** (J, or A/D from the inventory):
  - the main thread's steps so far (pixel ticks for done ones, a marker on the current one) and the optional objectives (open, ticked
    or "missed");
  - on the right, the journal (title and Log / Clue). E opens an entry in the reader (title, whose words, the text; E closes it).
  - A map can open the reader directly (`menu.read_log()`, through `dialogue.menu`); closing it then closes the menu.
- Tests: `world.gd` 208 and `fight.gd` 82 pass, 0 fail, no script errors (no asserts changed). A throwaway headless check (not kept)
  passed 41 of 41:
  - steps in and out of order, never back; the optional objective shown, done and missed;
  - the town's three place names and the banner at the start, on walking in, and not again within 20 s;
  - entering the cave, the jail's name and its note, the cage ticking the optional objective;
  - the return scene leading to the ruins and counting as meeting the king;
  - the ruins: nothing before the return; the box, the page and every print free and reachable; prints into the journal, E on the box
    and the page, the reader, journal order, `ruins_searched`;
  - J, W/S, E to read, E back, A to the inventory, Tab.
  Windowed screenshots of the HUD, the ruins, the reader and the Quests tab were checked (the first ticks, drawn with `draw_line`, didn't
  show; they are pixel rects now).
- Not in this stage: map markers or an objective arrow, more logs or side quests, the captain in the hall, the per-map game-over text,
  saving the journal (7d).

### Stage 7a: inventory, the menu and the tuning panel (2026-10-27)
The first of six stages the user asked for on 2026-10-27, in this order: inventory, objectives and quests, squad, save, item pickups, shop
(plan in `../IMPROVEMENTS.md` "Agreed roadmap"). Their decisions from the same day are in the design doc: the scientist's trail, the squad
rules, saving, the HUD layout, era-neutral menus, and a new "Combat balance" section (section 8).
- **The menu** (`menu.gd`): Tab or Esc opens it, I opens it on the inventory; it pauses the game like a conversation and won't open over one,
  over a sign, a door's fade, a scene or "You fell". One plain, era-neutral look (dark see-through panel, thin grey border, white text, a
  blue accent); the colours are constants at the top of `menu.gd`, shared by the tuning panel and the HUD's toasts. The dialogue box keeps
  its parchment. Only the Inventory tab exists so far; Quests, Squad and System come in 7b-7d.
- **The inventory** (`inventory.gd`, items in `items.gd`): a list grouped by kind (Tools, Supplies, Valuables, Story items) with a code-drawn
  12x12 icon per item, and on the right the selected item's big icon, name, kind, count, what E does and its description. **E eats food**
  (restores its `heal` hearts; at full health "You're not hungry."). Silver has its own line at the bottom. The lasso is listed as a tool
  with its key (Q).
- **The items are a provisional starter set:** lasso, flatbread (1 heart), pomegranate (2 hearts), silver. Which items exist and where they
  can be found will be settled with the user before 7e. They come from:
  - the start: the lasso;
  - Keeper Arshan's first conversation: 2 flatbread and a pomegranate (new TALK keys: `"first"`, a version used only the first time, noted
    in `quest.flags` as `talked_<id>_<stage>`; `"give"`, items handed over when it ends);
  - the king's return scene: 20 silver (`hall.gd RETURN_SILVER`; both return scenes gained a line about it).
- **Toasts:** "+2 Flatbread" with its icon at the bottom right for 2.5 s, fading out.
- **The tuning panel** (`tuning.gd`, T, pauses): punch, kick and arrow damage, and HP and XP for rats, bandits, slingers, the giant rat and the
  chief, with live columns (punches and combos to kill, seconds of non-stop swinging, seconds for the rider alone).
  - A change of HP applies at once to every living enemy of that kind on every map built so far (each keeps its share of health).
  - The values are `combat.gd tune`, filled from the constants at start and read through `enemy_hp()`, `hit_dmg()`, `arrow_dmg()` and
    `xp_for()` (`rat.gd`, `chief.gd`, `slinger.gd`, `rider.gd`, `combat.gd`). Without the panel nothing differs.
  - They last one session; E prints them in `combat.gd` form.
- **Combat balance:** the design doc gained a section on how HP, damage and XP fit together and what changing each does; "Where to tune"
  above lists the constants.
- The hint line now reads "... E talk   Tab menu   R restart" (B and G, both dev keys, were dropped to make room).
- Tests: `world.gd` 208 and `fight.gd` 82 pass, 0 fail, no script errors (no asserts changed). A throwaway headless check (not kept) passed
  39 of 39:
  - the lasso at start with no toast; Arshan's gift once, with two toasts; eating at full and part health, the list and selection after the
    last one;
  - I, W/S, E and Tab through real input events; no menu over a conversation or after "You fell";
  - T, changing bandit HP and XP, every bandit rescaled, a kill paying the new XP, punch damage for both punches, the computed columns;
  - the return scene's 20 silver.
  Windowed screenshots of the menu, the toasts and the panel were checked.
- Not in this stage: item pickups, drops, the shop, equipment slots, a quick-eat key (eating from the paused menu works even mid-fight),
  enemy-damage tuning, the Quests / Squad / System tabs.

### Stage 6e: the camp, the jail and the boss room from the user's pictures (2026-10-27)
From three touched-up screenshots of the cave sent by the user (the raided camp, the boss room, the jail) and their answers: one camp rat from
each tent plus one from each tunnel; no stalagmites in the boss room, loot instead; an ibex skull, not a person's; the jail's pens hold the dead
(now in the design doc, section 4 and Era 1).
- **Blood** (`terrain.gd`): `stain()` is a pool now (wider than tall, a dark rim, a red middle with a wet shine, splashes and droplets), in a
  red that still reads under the cave's dark light and glows by a fire (`BLOOD_D` / `BLOOD` / `BLOOD_L`). New `drag()` (a broad smear along a
  curve: a dark band, a redder middle, streaks that thin out and break up, a few clots) and `spatter()` (droplets over a flattened ellipse).
  In `cave.gd` the data are `STAINS`, `DRAGS` (`[width, points]`, replacing `SMEARS`) and `SPATTER`.
- **Abandoned camp**: big pools at both tent doors and round the fire, a broad smear from the left tent past the fire toward the south tunnel and
  three more, spatter everywhere; the torn tents are sprayed with blood and dark on the threshold, both tables are bloodied
  (`camp_table(..., bloody)`), two broken spears lie crossed by the fire and the right table.
- **Camp rats** (`CAMP_RATS`, was `TENT_RATS`): the trigger is unchanged, but the four rats now come from four places: one out of each tent's
  doorway, one up the tunnel from the entrance (behind you, just off screen) and one down the tunnel from the fork, each with a puff of dust.
- **Jail** (room a little larger, `ROOMS` `[230, 262, 165, 108]`): the rider's cage, its torches moved in beside it (178 / 282); four small pens of
  lashed poles in the corners (`cage()` with a narrow door and wider pole `gap`, fully solid), two holding a dark, featureless figure slumped
  against the back poles (`pen_inside`), seen through the gaps; three chain frames with open cuffs; a strap bench and a tool table
  (`"irons"`); a brazier of coals by the bench and another by the tunnel mouth; the jailer's table with the rider's bow and its stool on the west
  side, a spear rack, a straw mat, pots, a barrel and a crate; a broad smear from the cage door across the room. The foot stocks, the
  whipping post and the fetter post are gone (`stocks()`, `whip_post()`, `fetter_post()` deleted). `WAVE_RESPAWN` moved to (236, 318).
- **Boss room** (same room, steps, seal and respawn):
  - north: the chief's seat in front of his `hoard` (two gold piles either side of the seat, a low heap, chests, gold bowls, a glint),
    banners and fire bowls either side;
  - north-west: his `war_table` (a painted hide map with red roads, an akinakes, scrolls, a clay oil lamp with its own small light), stools,
    a barrel, pots, a banner;
  - north-east: two staked silhouettes, then the captain on the last stake under a torch (`CAPTAIN` (962, 190), `CAPTAIN_USE` moved with him),
    pools and a smear below them, and an empty cage with its door hanging open;
  - three tan tents with red rugs (two west, one east) and banners; the bedding corner on a rug to the south-east; more palisades along the
    south walls, a fire bowl each side of the steps' top, a spear rack;
  - the open floor: no stalagmites (`stalagmite()` deleted). Instead coin bags, spilled coins, a stool and an ibex skull (low or walkable), and a
    `strongbox` (an open chest on two crates) and a crate stack, which are tall: a charge into them still dazes the chief, and they stop stones.
  - `SLINGER_SPOTS` are the three tents' doorways, so the slingers burst out of the tents.
- `_jail()` now calls one `_cage()` builder, shared with the pens and the empty cage.
- Tests: `world.gd` 208 and `fight.gd` 82 pass, 0 fail (no asserts changed). A throwaway headless check (not kept) passed 36 of 37: every new
  prop and torch stands on floor, the rat spots, the tent doors, the cage door, the jail's middle, the respawns and the captain's spot are reachable;
  the trigger brings exactly four rats, one at each spot; the boss room seals, three slingers appear at the tent doors, a charge into the
  strongbox dazes the chief, and when he falls the seal lifts and the captain can be cut down. The one miss is 6a's camp crate at (212, 1062),
  whose left corner touches the rock rim (unchanged). Windowed screenshots of the three rooms were compared with the pictures.
- Not in this stage: picking up the hoard or the coin bags; looking into or freeing the pens; new tests; enemy numbers; the soldiers' logs.

### Stage 6d: the cave tells what the band did (2026-10-27)
From the user's playtest notes and answers: the camp and the jail show traces only; the boss room may show distant silhouettes of captives on
upright stakes (never crosses: the Achaemenids staked rebels, as at Behistun); the hero goes back to the king only after cutting the riders'
captain down; the ambush is 2 bandits rushing, 2 slingers later, and 1-2 waiting on the way out.
- **Abandoned camp** (`cave.gd`): its fire is lit. The three munching rats and the `"camp"` wake group are gone; instead four rats burst out of the
  two tents' doorways (`TENT_RATS`, aggro, a puff of dust) the first time the hero's feet are in `CAMP_TRIGGER`, the ground between the tents and
  the fire. More stains, blood dragged along the ground (`SMEARS`: a run of `terrain.stain()` calls, shrinking), spent arrows standing in the
  ground, a bloodied strip of tunic on a broken stake.
- **Jail**: foot stocks, a whipping post with cut ropes, a post with open fetters on a chain, a bowl of coals with two branding irons (lit by a small
  flickering light); stains and a drag mark from the cage door to the whipping post. Nobody in any of them.
- **Ambush**: the barricade now shuts the tunnel lower down (`BARRICADE` (270, 624)) so the band can come up it in turn. `WAVE` entries have a
  `"delay"`: 2 bandits at once from different tunnel points, 2 slingers at 4.0 / 4.6 s (the rider shouts "Slingers in the tunnel!"). The barricade
  lifts once all four have come and fallen; then two bandits (`WAIT`) are placed lower in the tunnel and at the fork, awake on an ordinary beat.
  The rider's "clear" shout now warns that more may be waiting.
- **Boss room**: three staked captives along the north and east walls (`cave_props.stake_captive`: a tall stake, a near-black featureless body,
  pale ropes, a dark pool). On the west side, under a torch, the riders' captain **Vahauka** (`npc.gd`, palette `"captain"`) bound alive to his own
  stake (`bare_stake` behind him, `captive_ropes` in front), muttering. The west-side crate stack and barrel were removed to make room; one
  slinger spot moved to (720, 200).
- **The return**: when the chief falls the seal still lifts after 1.5 s (`_lift_seal()`), but nothing teleports. The rider (if with you) shouts
  that the captain is alive. E in front of him (`CAPTAIN_USE`, only once the seal has lifted) cuts the ropes (he slumps forward, the stake is
  redrawn with cut ends) and plays `SCENES["captain"]` (how the band came at night, how the ones who ran were cut down, how the chief staked the
  rest one each night); when it closes `_go_to_king()` sets the flags (new: `captain_found`) and travels to the hall. Until then the cage can
  still be opened (a late rescue is now possible).
- **Dialogue**: the rider no longer says he is the last; both king return scenes mention the captain (`king_return_rider`, `king_return_alone`).
- Tests: both suites pass (208 / 82). A throwaway headless check (not kept) walked the whole cave flow: no rats before the trigger, 4 after;
  2 then 4 in the ambush, barricade up then lifted, 2 waiting; boss sealed, seal lifted with no teleport, the captain's spot usable, his scene,
  then the hall (19 / 19).
- Not in this stage: the soldiers' logs (later, they will spring the tent rats); the captain in the hall; new tests; rat/slinger numbers.

### Stage 6c: the chief, the slingers and the return to the king (2026-10-27)
As planned in `../stage6c_plan.md`, with the user's three answers: the rider shoots only enemies already after the hero; the chief has 20 HP
(tune later); you can't escape the chief (his room is sealed until he falls). This finishes the cave.
- **The chief** (`chief.gd`, extends `rat.gd`; numbers in `combat.gd CHIEF`): a bandit drawn 1.3x in dark wool, with a sheepskin over one shoulder and
  a *sagaris* (a long-handled axe). He sits asleep in front of his seat until you reach the middle of his room (`WAKE["boss"]`, radius 70, aggro).
  - **Charge** (70-200 px away, every 3.5 s): a red line on the ground follows you for 0.8 s and freezes (brighter) for the last 0.25 s; then he rushes
    190 px along it. If he touches you: 2 hearts. Roll **sideways** through him (rolling back along the line doesn't outrun him). Running into
    anything tall (rock, a stalagmite) stops him **dazed** for 1.2 s (stars; he takes hits).
  - **Sweep** (closer than 40 px): a red arc of 120 degrees and 44 px in front of him, fixed when the 0.6 s wind-up starts; 1 heart only if you are
    inside it when it lands. Step behind him or roll.
  - **Enrage** once at 10/20 HP: a roar (red, sparks, a shake, "He's enraged!"), then speeds x1.3 and wind-ups and recovery / 1.3.
  - **Armour:** hits hurt but never interrupt his wind-ups, charge, sweep or roar. He is too heavy to lasso. He keeps his damage after "You fell".
  - His charge line and sweep arc are drawn on combat's fx layer (`draw_telegraph()`, called for any enemy that has it).
- **The slingers** (`slinger.gd`; `combat.gd SLINGER`): 3 lean bandits with slings that appear at `SLINGER_SPOTS` (with a puff of dust) when the chief
  wakes, never before. 2 HP, 15 XP. They back off if you come closer than 70 px and close in beyond 130 px; with the sling ready (first throw after
  0.6-1.6 s, then every 1.6 s) and you in sight, they spin it overhead for 0.7 s (a thin aim line) and throw a stone (1 heart; tall things stop it,
  a dodge lets it fly past). A hit interrupts the spin; the lasso pulls them.
- **The sealed room:** when he wakes, a spiked barricade shuts the top of the steps (`SEAL`), the rider shouts "The chief himself! Watch his axe!",
  and "You fell" puts you back in the room's south end (`BOSS_RESPAWN`); the chief and the slingers go home and come again. The ambush (6b) and the seal
  share one helper: `cave.gd _barricade_at(point)` spans the run of floor on that row from rock to rock, and `_lift()` takes it away.
- **The rider** (`rider.gd _pick_target`) now shoots only enemies for which `rat.gd after_hero()` is true (awake, not patrolling, not walking home):
  he never wakes a sleeping group or the chief, and never starts a fight with a patrol that hasn't seen you.
- **The return:** 1.5 s after the chief falls the seal lifts, `quest.gd flags` get `chief_down` and `rider_joined`, and the hero is taken to the hall
  (spawn `king_return`, 90 px south of the steps). `main.travel()` now calls the new map's `arrived(spawn)` after the fade. In the hall the king calls
  "Let them through!", the camera looks up, and the hero walks to the throne (the stair-scene walk, now `hall.gd _walk_hero_to()`), then the return
  dialogue plays (`dialogue.gd SCENES`):
  - **with the rider:** he walks up beside you (a plain NPC, `RIDER_HALL`) and speaks his own lines in the same box (a line with `"who": "rider"` shows
    his name and portrait); afterwards he stays by the throne, talkable (`TALK["rider_hall"]`). In the cave he is gone.
  - **without him** (the lesser return): the king asks after his riders and gets no answer. In the cave the rider stays where he was, muttering; the cage
    has no E any more (no late rescue in this build).
  Either way the return counts as meeting the king: `intro_done`, the king is talkable, and the stair scene never plays. You can walk back to the cave.
- **Spoken text moved:** the hall's call line and first king conversation are now `dialogue.gd SHOUTS["king_call"]` and `SCENES["king_intro"]`.
- **Shared code:** `rat.gd` gained `person` (drawn as a person: faces four ways, topples when it dies), `heals` (healed when back home; the chief isn't),
  `_state_more()` (extra states for scripts built on it), `after_hero()`, and `_person_marks()` (the bandit's markers and bar, shared with the slingers).
- Tests: `world.gd` 208 and `fight.gd` 82 pass, 0 fail (no asserts changed). A throwaway check (not kept) passed 73 checks: he sleeps until the room's
  middle, then the room seals (the steps can't be reached) and 3 slingers come in; the line follows then locks, stepping out of it is safe, a charge
  hurts 2, a sideways roll passes through him, a stalagmite dazes him; the sweep hurts inside the arc and not behind him; one enrage at 10/20 (x1.3);
  stones hurt, a dodge and a stalagmite stop them; a fall respawns you inside the sealed room and he keeps his damage; the rider ignores sleeping and
  patrolling enemies; both returns (walk, the right lines, the speakers, flags, the king talkable, the cave afterwards: seal gone, no E at the cage).
  Screenshots of the fight and the throne room were checked in a windowed run.
- Not in this stage: a late rescue after the lesser return; the rider leaving the cave before the chief falls; keys and inventory; quest-tracker text;
  loot or a scientist clue from the chief; camp alarms and pathfinding.
- **After 6c (same day), the user's decision on healing:** every enemy that walks back home heals to full (after a fall or a given-up chase), bosses
  included (design doc, section 8). So the chief no longer keeps his damage: after "You fell" he walks back to his seat, heals to 20/20 and can enrage
  again (`chief.gd _return` clears `enraged`). The `rat.gd heals` switch from 6c was removed; the notes above that say he keeps his damage are superseded.
  Tests: both suites pass; the throwaway 6c check's fall section now expects him back at 20/20, not enraged.

### Stage 6b: the rescue, the rider and the ambush (2026-10-27)
As planned with the user (design doc, Era 1 "the king's lost riders").
- **The cage:** stand in front of its door and press **E** (an E box shows there; `CAGE_USE`). The door swings open and only its own solid goes
  (`_door_rect`, `level.unsolid()`). There is no key yet: keys wait for an inventory.
- **The rider, Farnaka** (`rider.gd`, extends `npc.gd`, so the dialogue box treats him as an NPC): he steps out to `RIDER_OUT` and waits with a "?" mark.
  Talk to him (placeholder lines, `dialogue.gd TALK["rider"]`). When the box closes (`"then": "rider_join"` -> `cave.talk_done()`), he takes his bow and
  bow case from the jail table and follows you:
  - he walks your own trail about 22 px behind, so he never needs pathfinding, and jumps back next to you if you are suddenly over 220 px away (a respawn);
  - every 0.5 s, if an enemy is within 170 px and in sight, he steps 9 px out to the side (away from you), draws for 0.16 s and shoots it;
  - an arrow does 1 damage with a small knock-back but never staggers (`rat.gd hit(..., interrupt = false)`), so it can't pin an enemy in place;
    it wakes a sleeping enemy and sends it after you. Kills by arrow count for your XP;
  - nothing hurts him, enemies ignore him, and E never lands on him again. If you leave the cave he stays where he stood and goes on following when you return.
  Numbers: `combat.gd RIDER`.
- **The ambush** (`WAVE`): the moment he joins, 4 bandits come up the jail tunnel already charging, a spiked barricade is thrown across the tunnel behind them
  (`BARRICADE_Y`, its width found from the floor mask), and he shouts "They heard us! Here they come!" (`dialogue.gd SHOUTS`). The bandits chase you anywhere in
  the jail room (leash 320). While it lasts, "You fell" puts you back in the jail room (`WAVE_RESPAWN`). When the last one falls the barricade goes, the respawn
  is the entrance again, and he says "That was the last of them. Lead on." No rescue, no ambush.
- **Arrows and stones** (`combat.gd shots`, `shoot()`): they fly in 4 px steps, are stopped by anything tall (`level.sight_blocked()`: what blocks sight also
  blocks a shot; low props don't), and hit a body near its middle (`body_point()`). Stones (6c's slingers) hit the hero unless a dodge or hurt-blink makes
  them fly past.
- **New hooks:** `level.gd uses` / `near_use()` / `usable()` / `use_spot()` (and `_make_use_prompts()`), `unsolid()`, `sight_blocked()`, `talk_done()`,
  `level.combat`; `dialogue.gd` handles E at a use spot (after people and signs, before doors), a conversation's `"then"`, and a new `SHOUTS` table;
  `combat.gd spawn_enemy()`.
- **Fix to 6a:** a torch post stood in the middle of the jail tunnel, right where the ambush arrives; it is now against the tunnel's west wall (192, 438).
- Tests: `world.gd` 208 and `fight.gd` 82 pass, 0 fail (no asserts changed). A throwaway check (not kept) drove the real input: E opens the cage and its door
  stops being solid, he steps out and is talkable, the talk makes him join (armed, not talkable, the bow gone from the table), 4 bandits charge at once, the
  barricade shuts the tunnel, the respawn moves to the jail room, his arrows alone cleared the ambush in about 18 s while the hero stood still, then the tunnel
  reopens, the respawn goes back to the entrance, he walks 22-40 px behind the hero, and joins him at once after a jump.
- Not in this stage: the chief, slingers and the return to the king (6c); the rider leaving the cave with you; a key for the cage; quest-tracker text.

### Stage 6a: the cave hideout map (2026-10-27)
From the user's "cave map idea" picture (Cave Entrance, Abandoned Camp, Jail Cell, Enemy Area, Boss Area). The picture has the entrance on the
west; since the hero comes from the south, the route is turned to run south -> north. The story behind it is in the design doc (Era 1, "the king's
lost riders"); 6b and 6c are planned in `../IMPROVEMENTS.md`.
- **Getting in:** walk up the north-east road into the cave mouth in the cliff (auto door `cave_mouth`, fade). Walk back out through the mouth at the
  bottom of the cave map to come out just below it in the town (spawn `cave`).
- **New map `cave.gd`** (1100 x 1500). From south to north:
  - the **mouth** with daylight falling in (sand on the floor, warm light, soft shafts and dust) and the **entrance hall** (a broken cart, scrub, supplies);
  - the **lookout tunnel**: 3 bandits (one in a side alcove with their bedding);
  - the **abandoned camp**: the king's riders' camp after the raid, with torn tents, a cold fire with a wisp of smoke, blood stains, a dropped wicker shield and a
    broken spear, a spilled pot (no bodies), and 3 rats eating at the tables until you walk in (group `camp`);
  - **the fork**: up-left, a winding tunnel to the **jail room**, where a captured royal rider sits in a cage of lashed wooden poles. A bandit jailer paces in front,
    and the rider's bow and bow case lie on the table. The rider only mutters for now (`CHATTER["rider"]`); freeing him is 6b.
    Up-right, **the band's camp**: a red wool tent, a lit fire, stake palisades, a spear rack and 4 bandits;
  - a flight of **wooden steps** north into the **boss room**: the chief's seat (crates, a hide, ibex horns) between two of the band's banners (dark red, a painted
    ibex-horn mark, no royal sign), two iron fire bowls, four stalagmites (tall: they block sight). The chief comes in 6c.
- **How the map is made:** the floor is `ROOMS` (ellipses) and `TUNNELS` (smooth polylines), wobbled by noise and rasterised into a 4 px mask.
  `terrain.gd cave_ground()` paints dirt, a rim of rounded stones and rock faces above every north edge. The rock is warm grey-brown, not the picture's blue-grey,
  to keep Era 1's sand/ochre look. Every 8 px cell that isn't all floor is solid (merged along rows: 539 rects). Props, torches, stains and enemies are data consts.
- **Lighting helpers moved to `level.gd`:** `point_light(pos, radius, colour, energy, flicker)` and `flicker_lights(depth)` replace the copies in `storeroom.gd`
  and `hall.gd` (same look), and the cave uses them too.
- **Other files:** `main.gd` (`LEVELS` has `cave`), `world_waystation.gd` (the auto door, spawn `cave`, header comment), `sprites.gd` (look `rider`: belted tunic,
  trousers, felt hood), `dialogue.gd` (the rider's mutterings), new `cave_props.gd`, `terrain.gd` (cave painters).
- Tests: `world.gd` 208 and `fight.gd` 82 pass, 0 fail. One assert changed: the town now has 3 doors. A throwaway check (not kept) confirmed every zone, the door
  and all enemy homes are reachable from the entrance, nobody can walk into the cage, every prop and torch stands on floor, walking into the mouth and back out works
  with no ping-pong, and the map builds in about 0.2 s.
- Tweak after 6a: the watch post outside the east wall moved up 8 px (`world_waystation.gd _town`), so its base lines up with the north east-gate pillar's.
- Not in this stage: freeing the rider, the companion, the rescue ambush (6b); the chief, slingers and the return to the king (6c); camp alarms and pathfinding
  (not picked); keys and inventory; quest-tracker text for the cave; cave wildlife such as bats.

### Stage 5c.2: town buildings rework (2026-10-27)
From the user's reference picture and follow-ups ("all houses look the same", "more houses instead of the shops").
- **Stable** (`Props.stable_back` / `stable_front`, same footprint and solids): a timber barn with a dark plank back wall, a hay loft (three bales and
  a loose pile), X-braced rails below, thick corner posts under a heavy roof beam with a corner brace, and a rope coil and lantern on the left post.
- **New `Props.house()`**: the adobe body (now without its fixed roof clutter: `adobe(..., clutter)`) plus a curtained doorway and a set of details
  (`ladder`, `awning`, `jar`, `cloth`, `pots`, `stair`, `window`). Four houses, each different: the family house on the north wall (ladder, reed awning,
  red curtain, water jar), the west house (washing on the roof), and two new houses on the north wall where the market stalls were (roof plants and a
  reed screen; a side stair and washing). `world_waystation.gd _house()` places one (solid = the face, like the old `_adobe`, which is gone).
- **New `Props.storehouse()`**: the storeroom is now a smaller annex built onto the family house, with iron-bound double plank doors under a lintel
  beam. The doors are centred on x 443, so the storeroom door (E), its rect and the tests are unchanged.
- **Market:** the red-and-white stall moved to just north of the training yard (its rug with it); the blue stall is gone (`stall_blue` removed).
  Barrels moved between the stable and the house; a crate and sacks stand by the storeroom doors.
- **Cook camp:** the canopy runs from x 140 to 310 on three poles (`cook_camp(..., fire_x, mid_poles)`; the fire and cauldron stay at x 262), and the
  sleeping traveller lies under its west end (178, 604).
- Tests: `world.gd` 208 and `fight.gd` 82 pass, 0 fail. A throwaway walk check confirmed the storeroom door, every house front, the stall, the
  east-gate path, the cook camp and the yard are still reachable.
- **Follow-up (same day):** the red-and-white stall moved again, to where the wooden shed stood (between the training yard and the east wall, front
  y 566, rug in front); the shed is gone (`Props.shed` and `SHED_SHIFT_Y` removed). Scribe Nidu (same name and lines) now minds the stall, standing
  at its west end (642, 566). To make room the whole training yard moved 20 px west (`YARD_SHIFT` (-10, -12)); its south-west corner tucks behind
  the gate pillar. The town test's "training yard" reach point moved from (560, 570) to (540, 570), because the dummy now stands on the old one.
- **Second follow-up:** the stall moved 8 px north (front y 558) so its roof top (y 510) is level with the yard's north rail; Nidu stands just
  west of it without touching it (641, 537), his head level with the roof top; the storeroom's entrance passage is dirt right
  up to the exit door (the old stone-slab "entrance" rows in `_paint_floor` are gone; a sill solid stops you at the door), nothing is built below the door (`END_ROW`: plain black, and the door stays clear of the
  HUD hint line), and the two passage torches stand just above the door; the door's E area moved down to match; the two north houses moved back against the wall (tops y 300 / 304,
  fronts in line with the family house at y 376); the torch just east of the road outside the south gate (493, 742) is gone (the two that frame
  the gate stay).
- Not in this stage: enterable houses, people living in the new houses, a new market spot for the blue stall.

### Stage 5c.1: training yard restyle (2026-10-27)
From the user's reference picture. Same place, size and collision as before (east of the plaza, next to the shed; Veteran Datis at its opening).
- **Fence:** `Props.fence_h` (chunky capped posts every 20 px in front of a rail raised 9 px) for the north and south sides, `Props.fence_v` (one long
  raised beam) for the east side and the two west pieces, `Props.fence_post` at the west opening. The old `post()` / `rail()` are gone.
- **Dummy:** redrawn (`Props.dummy`): a cloth-wrapped log head, a crossbar with rags tied near the ends, a cream torso with a torn hem and a red target.
- **Weapon rack:** new `Props.weapon_rack`: two short straight swords (akinakes) and three spears with leaf-shaped tips. The old `rack()` stays for
  the courtyard armoury stall.
- **The dummy wobbles when hit.** `level.gd hittables` lists things the hero can hit that aren't enemies; `combat.gd _resolve_hits` hits them with
  the same reach test as enemies (once per swing), and `combat._process` rocks them and lets them settle (`DUMMY` tuning: tips up to 0.32 px per px
  of height, settles in about 1.2 s). It tips away from the hero as a skew (rows stay straight) with cloth-coloured sparks and a light shake.
  No damage, XP or kill; enemies and the lasso ignore it.
- Tests: `world.gd` 208 and `fight.gd` 82 pass, 0 fail (collision unchanged, so the "training yard" reach point still holds).
- Not in this stage: Datis teaching at the yard, a sound for the hit, more dummies or targets.

### Stage 5c: servant and scholar in the hall (2026-10-27)
- **Servant** (ambient, `hall.gd NPCS` id `servant`): walks a loop round the long table with a jug on his head and a dish of flat bread and
  pomegranates in his hand (`acc` `["jar", "plate"]`), pausing at the corners and halfway along each side as if serving, and mutters three lines
  in a bubble (`dialogue.gd CHATTER`). An NPC's `acc` can now be one name or a list (`npc.gd`); the new `plate` is held at the side when facing
  up or down and out in front when walking sideways. New look `servant`: Median dress (tunic,
  trousers, soft cap) as the servants on the Persepolis reliefs. The north leg of the route runs at y 292, just clear of the head chair.
- **Scholar Utana** (talkable, id `utana`): stands at the round table in the library reading an open scroll (new `npc.gd` accessory `scroll`), facing
  the doorway. New look `scholar`: indigo robe, white head-cloth, grey hair. Three placeholder lines (`dialogue.gd TALK`) that only build on what the
  king says (the missing riders) and mention clay tablets and leather scrolls; no clue or quest stage yet.
- **Rats and bandits wait longer before giving up a stuck chase:** `progress_time` 1.5 -> 2 s (`combat.gd RAT` / `BANDIT`). The `return` check is
  twice that, so a rat that slides without getting nearer home is put back after 4 s instead of 3. Sweep: 0 pinned within 12 s (7 slow creepers take
  longer than 6 s to give up now).
- Tests: `world.gd` 208 and `fight.gd` 82 pass, 0 fail. The hall's person count is now 5 ("king, two royal guards, servant and scholar").
- Not in this stage: the scholar giving clues or a quest, sitting or serving animations, a portrait image, replacing the library's books and globe.

### Stage 5b.3: bug fixes (2026-10-27)
From the user's list (`stage5b_fixes_plan.md`, written against the 5b zip):
- **The king was about 2.4x a person.** `castle_props.gd king_seated()` is redrawn at person size (8 px head, 14 px wide body, hands on his knees,
  long squared beard, a smaller crenellated tiara): about 48 px from the floor to the top of the tiara, versus 66 before. He sits higher than the guards
  only because the seat is raised. The throne's back is 8 px lower; the winged disc sits just above his tiara. His floating line is at -58 (`npc.gd`).
- **The hall steps didn't read as stairs.** New ground painter `terrain.gd steps()`: each step is a tread with a lit front lip, then a shaded riser with
  a dark contact line. The hall flight is 6 steps of 4 + 3 px (`STAIRS` y 200..242, `STEP`). The carpet is repainted stepped over the flight
  (`_carpet_steps()`: tread, gold stair rod, dark riser). New prop `castle_props.gd stair_cheek()`: low side walls whose cap steps down with the flight,
  ending in newel posts with gold balls (solid at x 304..312 and 408..416, y 212..244). The king-scene zone (from y 246) didn't need to move.
- **The courtyard gate steps** use the same painter: 7 steps from y 66 (just under the portcullis bars) to y 115, darker toward the top so they climb
  into the tunnel (`GATE_STEPS`). The bottom step stands 7 px out of the wall face as a front step, with a soft shadow at its foot.
- **Rats pinned on the east side of the town.** Three changes:
  - Progress watcher (`rat.gd _watch_progress`, numbers `progress_time` 1.5 s, `progress_gain` 6 px, `lost_time` 3 s in `combat.gd RAT` / `BANDIT`):
    a chasing rat that hasn't moved 6 px toward the hero in 1.5 s gives up, walks home and ignores the hero for 3 s. It measures the rat's own
    headway, so a rat that is simply outrun still chases to `lose` / its leash. Close to the hero (waiting to bite) never counts as stuck.
  - One-side steering (`rat.gd _move`, `side_time` 1 s): when the straight step is blocked it goes round on one side and keeps to it, instead of
    flipping sides each frame. If that side is blocked too it reports "stuck" (patrol turns back, chase counts it).
  - The cliff south of the last nest is 20 px shorter (`CLIFFS` `[930,748,76,48]`), so the gap below it is about 54 px instead of 34.
  - The giant leaves all of this out (no such keys in `GIANT`), so its movement is unchanged.
  - A throwaway sweep (hero on a 16 px grid around each nest rat, 6 s of chase, 1,394 cases): pinned 200 -> 0, reached 1,194 -> 1,301, gave up 0 -> 89.
- **Play-test follow-up (same day).** The first version of the steering re-picked its side every second by "smallest turn", which flipped it back and
  forth along a long face: the bandit at (285, 972) slid along the top of the column drum in front of it for good, and the nest-2 rat along the top of
  its own nest, each facing a goal it never reached (and so not seeing the hero). Fixed in `rat.gd`:
  - The side is kept for as long as the way is blocked (plus `side_time` after), so it always finishes going round.
  - Patrol gives up a goal it hasn't reached in (distance / speed + 2 s) and turns back (`walk_t`, `walk_max`).
  - `return` uses the same headway check as chase: sliding without getting nearer home for 3 s puts it back home (the old "can't move for 3 s" rule
    never fired while it was sliding).
  - Rats pick roam spots they can walk to in a straight line (`_walkable`).
  - Rats are drawn side-on (left or right only), so they now also see the way their head is drawn (`_drawn_looking_at`), not only along `face`:
    a rat walking up or down no longer looks straight at the hero on screen while its vision cone points away. The B debug view shows that second cone.
- **Cover (the user's decision, now in the design doc):** low props are see-through for enemy sight: nests, dead trees, cacti, column drums and scatter
  (agaves, small rocks). Walls, buildings, cliffs, pillars, big rocks and trees still block. `level.gd solid(x, y, w, h, low := false)`; `los()` skips
  low solids (142 of the town's 336). The B debug view draws them orange. The drum bandit now spots a hero beyond its drum and comes round it.
- Tests: `world.gd` 208 and `fight.gd` 82 pass, 0 fail. Two setup lines in `fight.gd _bandits` changed, both because the bandits now move differently:
  the bandit also pauses (`b.wait = 1.0`) when it is turned toward the hero (a walking bandit faces its goal), and the other two bandits are made
  dormant for that fight (the drum bandit paces close enough to join in, which made the "1 kill" check depend on timing).
- Not in this stage: moving nest 4 (882, 632), the east town gate (left as it is by choice), real pathfinding, the frozen-maps leak, a sceptre for the king.

### Tests merged into two suites (2026-10-27)
- The 18 scripts in `tests/` became `suite.gd` (shared base: `ok()`, `reachable()`, fresh game per section), `world.gd`, `fight.gd` and `run_all.ps1`.
- Every check of the 11 old tests is kept (old 201 asserts plus 6 print-only tests -> 290 asserts). The print-only tests (`smoke`, `validate`, `choices`,
  `combat`, `escape`, `bandit`) are now real PASS/FAIL asserts.
- Removed: the 6 screenshot scripts (`shots`, `overview`, `store_shots`, `court_shots`, `hall_shots`, `scene_shots`) and the `flood.gd` debug printer.
  Stage notes below still name the old files as history.

### Stage 5b.2: the courtyard plaza (2026-10-27)
- **Ring road and raised planter:** the gate road and the bridge road now run into a paved ring road around the statue (`_pave_plaza()`:
  one slab grid for roads and ring, so the joins have no seams). The plaza is centred on y 308, the middle of the bridge road, so that road
  runs straight into the ring's side and the gate road into its top; each join has a small rounded fillet (`FILLET`, `_in_fillet()`). Inside the ring the grass is a raised round planter (`PLANTER`) with a
  grey stone kerb and front face, flowering bushes on the front arc, and a soft shadow on the road. The planter is solid (stacked bands).
- **North-west:** a wall fountain (`CP.wall_fountain`, animated): blue glazed-brick niche as at Susa, gold lion-head spout, stone basin, on a paved apron,
  with a stone bench and clay pots.
- **North-east:** a covered supply colonnade against the north wall (`CP.colonnade`): stone pillars, timber roof with vines, goods in the bays, a lantern (lit).
- **East:** the four guard tents are gone. An armoury stall (`CP.armoury`: red canopy, spear rack, Persian wicker shields) and regrouped supplies
  (new supply kind `pots`). `CP.tent()` was removed (only the courtyard used it); `CP.bush()` takes `flowers`.
- Red standards moved to flank the gate road at the ring; guard 1 now walks the ring road (8 points).
- Tests: `courtyard.gd` reach points moved to the ring, plus the fountain, armoury, colonnade and "cannot walk into the planter".
  `court_shots.gd` has two new spots (`c9_fountain`, `c10_stores`).
- Not in this stage: a paved floor for the whole yard (kept sand by choice), guards posted at the fountain or armoury, the hall-entrance steps of the reference.

### Stage 5b.1: the courtyard statue becomes a PNG (2026-10-27)
- The code-drawn warrior statue is replaced by `assets/props/statue.png`: a generated image (purple background) keyed, shrunk to 68x116 and
  reduced to 32 colours by the new `../Code/prep_prop.py`. The eagle emblems on the shield and the plinth panel were painted out (plain blue fields),
  and the sandstone was recoloured to the statue grey of `castle_props.gd` so the monument stands apart from the walls. The helmet and spear stay bronze.
- `castle_props.gd statue()` draws the PNG (held in a static var: a texture referenced only by a local is freed after the one-time draw and shows white),
  with the old drawing kept as `_statue_drawn()` for when the PNG is missing.
- `courtyard.gd`: base footprint now 68x20; the four cypresses right around the statue are gone (the PNG has its own trees and flower beds);
  the red standards moved out to x 488 / 592.
- Tests: `courtyard.gd` 48 pass, 0 fail. Checked in `court_shots.gd` (c3/c4).
- Not in this stage: other props or characters as PNGs; matching the PNG's finer detail to the code-drawn style.

### Stage 5b: the great hall, throne room and the king scene

Open Godot 4.2 or newer -> Import -> pick `project.godot` -> press F5. Controls as before.

#### Stage 5b: the great hall (new map `hall.gd`, 720 x 800)
- **Getting in:** from the courtyard, walk up the steps into the open gate tunnel (auto door, fade). Walk out of the hall's south entrance to return to the courtyard.
- **Layout:** long red carpet (winged-disc medallions) from the entrance up the middle; stone columns with gold braziers on both sides; **west** the long dining table with 14 chairs on a rug;
  **east** the library alcove (4 bookcases, round table with scrolls, writing desk, globe, round rug); **north** the throne room: a raised dais across the whole width,
  steps in the middle (the only way up), **one throne** with the winged disc, three arched lattice windows with cool light, banners, potted cypresses. Warm braziers over a dim ambient.
- **King Rostam** sits on the throne, with **two royal guards** (spears) behind him. (The scene needs them, so they come with 5b; servant and scholar are 5c.)
- **King stair scene (plays once):** walk into the zone just south of the steps (`SCENE_ZONE`). Control locks, the camera looks up at the king, he calls **"Come forward."** in a floating
  line, the hero **walks himself up the steps** to the throne, then the normal parchment dialogue opens (E advances, game paused) with 4 placeholder lines (`INTRO` in `hall.gd`).
  After it, the king is a normal talkable NPC (E; his placeholder lines are `TALK["king"]` in `dialogue.gd`). Walking back and forth does not replay it.
- **Code touched elsewhere:** `player.gd` (`scripted` / `script_v` walk, `cam_extra` camera look), `npc.gd` (`shout()` floating line, seated king sprite, spear), `dialogue.gd` (`start_scene`, king entry),
  `courtyard.gd` (gate is now a door; `TUNNEL_END` replaces the old block; `gate` spawn), `main.gd` (registers `hall`), `sprites.gd` (king / royal looks), `castle_props.gd` (throne, king, columns,
  braziers, bookcases, tables, chairs, desk, globe, grey interior walls).
- **Tests:** `tests/hall.gd` (gate both ways, no ping-pong, collisions, reachability, the whole scene: call, auto-walk, dialogue, once only, king talkable afterwards).
  `tests/hall_shots.gd` and `tests/scene_shots.gd` render screenshots (need a display; see the file headers). Also fixed: alpha fills in the ground painting now blend (`Terrain.shade`).
- Not in 5b: servant, scholar (5c), real king script, quests, save points.

### Stage 5a (earlier notes): the castle courtyard

#### Stage 5a: the courtyard (new map `courtyard.gd`, 960 x 640)
- **How you get there:** walk east along the town's wooden bridge; at its east end you walk straight into the courtyard (fade, no E). Walk west off the
  courtyard bridge to come back. These are **auto doors**: a door with `"auto": true` in `doors` fires when you step into its rect (checked in `main.gd _process`).
- **Look:** walled yard on an island in the river. Four corner towers plus two towers flanking the bridge, banners with a **Persian winged-disc emblem**
  (`castle_props.gd royal_banner`; the town's banners are unchanged), cypresses, flower beds, torches.
- **Great warrior statue** in the middle (scale armour, conical helmet, spear, round shield) on a three-step plinth inside a round garden, with two red standards.
  (Replaced by a PNG in Stage 5b.1.)
- **Guard tents** with crates, barrels, sacks and a cart along the east wall (no merchants).
- **North gate:** open (portcullis raised) with steps going into a dark tunnel; walking in takes you to the great hall (5b).
- **People** (`NPCS` in `courtyard.gd`, chatter in `dialogue.gd`): two guards walk laps (one around the statue, one along the south), one guard stands at the bridge end.
  All ambient (no E).
- **Code touched elsewhere:** `level.gd` (auto doors, `start_npcs`, shared `npc_by_id` / `chatter_for` / `mark_for`), `main.gd` (registers the map, creates a map's people the
  first time you arrive, auto-door check), `world_waystation.gd` (bridge door + `castle` spawn), `dialogue.gd` (guard lines).
- **Tests:** `tests/courtyard.gd` (door both ways, no ping-pong, people, reachability, patrol legs clear, closed gate), `tests/maps.gd` updated (town now has 2 doors).
  `tests/court_shots.gd` renders screenshots (needs a display: `xvfb-run -a godot --rendering-method gl_compatibility --path . -s tests/court_shots.gd`).
- Not in 5a (as agreed): great hall, king scene, quests, save points.

### Stage 4 (earlier notes): the storeroom, separate maps and the giant rat

Controls as before (B also shows doors and sleeping-group circles).

#### Stage 4b: the barn (boss room) and small fixes
- **Barn** (boss room, `storeroom.gd`): 28 x 15 tiles of floor (448 x 240 px, fits one screen). A solid rice / seed pile at the far north (`PILE`), open sacks below
  it (`OPEN_SACKS`), the giant rat and 3 small rats all **eating at the pile** (head-bobbing, no wandering) until you walk into the **middle of the barn**
  (`WAKE["boss"]`, radius 62): then the whole group wakes at once and charges. Four hay pens with solid fences (`PENS`, `_add_barn`), two small cover piles.
  The corridor is 3 tiles shorter; nothing else in the storeroom moved.
- **Summon at half health:** 5-6 small rats in total, 2-4 from the left southern pen and the rest from the right southern pen (`SUMMON_LEFT`, mirrored; numbers in
  `GIANT` in `combat.gd`). Only once.
- **Storeroom rats never flee** (`rats_flee = false` on that map); town rats still do.
- **Town:** the sleeping traveller lies between the stable and the storeroom, Arshan stands nearer the well, the storeroom door exit is back in front of the door.
- Tests updated: `maps.gd`, `boss.gd`, `slam.gd` (all pass, plus the older ones).

#### What is new in Stage 4
- **Separate maps.** `level.gd` is the base of every map (collision grid, props, doors, its own enemy list). `world_waystation.gd` (town) and
  `storeroom.gd` extend it; the castle will be a third one. `main.gd` keeps one map in the scene tree at a time: `travel(level, spawn)` fades to
  black, swaps the map, puts you at the named spawn and fades back. The map you leave is frozen exactly as it was (dead rats stay dead, hurt
  enemies keep their health and position). Doors are plain data (`doors` in each map: where to stand, target map, target spawn).
- **Storeroom door** is under the sleeping traveller on the south face of the north building: stand in front of it, press **E**. The exit door is at the
  bottom of the entrance passage. Dying inside the storeroom puts you back at its entrance (not the town gate); dying in town still uses the gate.
- **Storeroom map** (`storeroom.gd`, 640 x 928): top room, long corridor, east side room, lower room, entrance passage, as in the reference image.
  Layout = `FLOORS` rectangles in 16 px tiles (walls are generated), `PROPS`, `TORCHES`. Dark ambient light + warm torch lights + a small lantern on the hero.
- **Enemy groups** (`ENEMIES`, `WAKE` in `storeroom.gd`): 3 small rats at the entrance (awake), 3 more in the side room / corridor (asleep until you enter
  the corridor), the giant rat + 2 small rats in the top room (asleep until you are about 130 px from the room). A hit or a lasso also wakes a rat.
- **Giant rat** (numbers: `GIANT` in `combat.gd`, behaviour: `rat.gd`): same brain as the rats (patrol, alert, chase, wind-up, lunge, recover), 12 HP
  (twice a bandit), too heavy to lasso, armoured while it attacks (hits hurt but do not interrupt it), lunge takes 2 hearts, 100 XP.
  At half health it roars and **summons 2-3 small rats, once** (never again, even if it heals). It also has a **jump + ground slam**: it crouches, a red circle
  on the floor follows you and freezes for the last 0.3 s, it leaps (cannot be hurt in the air) and lands; you are hurt (2 hearts) **only if you are inside the
  circle at the moment it lands**. A dodge roll's invulnerability also saves you. Cooldown 4.5 s (3 s after the summon).
- Not in this stage (as agreed): sword, quest stages, rat-count quest, dialogue changes.

#### Tests (headless: `godot --headless --fixed-fps 60 --path . -s tests/<name>.gd`)
`maps.gd` (door, fade, spawn, camera, frozen town, per-map respawn, sleeping groups, reachability), `boss.gd` (HP, telegraph, lasso, armour, summon once, XP),
`slam.gd` (circle follows then freezes, airborne immunity, hit only inside the radius, dodge, cooldown). Earlier tests still pass.
`store_shots.gd` renders screenshots of the storeroom (needs a display: `xvfb-run -a godot --rendering-method gl_compatibility --path . -s tests/store_shots.gd`).

### Stage 3b (earlier notes)

Controls: WASD / arrows move, **Space** (or left mouse click) attack, **Shift** dodge, **Q** lasso, **E** talk / read the sign,
B collision boxes + rat vision cones, G sprite gallery, R restart (full reset).

#### What is new in Stage 3b: the new map (1200 x 1340, portrait)
- **Layout (matches the reference image):** you start bottom-centre and walk north along the dirt road. Three **bandits** pace back and
  forth on the road below the town and charge when you get close. The **walled Waystation Town** has its gate in the south wall
  (guards, banners, torches). **Ancient Ruins** (pillars, broken walls, column drums, rubble) fill the north-west and a smaller ruin
  field sits south-east. The **Cave Hideout** is in the north-east cliff (torches, winding road; the mouth is blocked for now).
  The **river** runs down the east side with a **wooden bridge** you can cross; it ends at the map edge (the castle comes later,
  see `bridge_exit` in `world_waystation.gd`). 5 rat nests (6 rats) sit on the east side between the road, the river and the cave.
- **Art:** the ground is painted once in code (`terrain.gd`: sand, roads, flagstones, rugs, cliffs, river, bridge deck, cave arch)
  and everything that stands up is a y-sorted prop (`props.gd`: shaded trees, palms, pillars, walls, towers, stalls, torches...).
  Light comes from the top-left; props have soft shadows and 3-tone shading. `atmosphere.gd` adds torch/fire glow, river sparkle,
  drifting dust and a soft vignette. Palms and trees sway; fire and torches flicker.
- **Same people, same quests:** Arshan, Nidu, Datis, the guards, camel, child and lizard are moved into the new town (npc_data.gd).
- Bandits use the rat brain (`rat.gd`) with the `BANDIT` numbers in `combat.gd`: 6 HP, red health bar, too heavy to lasso, 25 XP.

#### Where to edit the map
`world_waystation.gd` top: `ROADS`, `CLIFFS`, `PILLARS`, `RUIN_WALLS`, `TREES`, `PALMS`, `TORCHES`, `NEST_SPOTS`, and `bandit_spots`
(in `_nests_and_bandits`). Town buildings are in `_town()`. Tests: `tests/smoke.gd` (everything reachable), `bandit.gd`, `combat.gd`,
`validate.gd`; `tests/overview.gd` and `tests/shots.gd` render screenshots (need a display; run with xvfb).

#### Stage 3B town layout update

- Moved the blue market stall beside the red stall and aligned their awnings/counters on the same row.
- Removed the building behind the market stalls and the small southern shack, including their prop collision rectangles.
- Removed the sleeper's rug while retaining the two stall rugs.
- Repositioned the third guard to the cleared southern-shack area.
- Added proximity-based boxed E prompts to both signposts and changed the sign panel's north direction to an upward arrow.

#### Stage 3B town review fixes
- Signpost E prompt now sits at the sign's bottom right (own node, always drawn on top). Signs are data: `SIGNS` in `world_waystation.gd`
  (position + the rows shown on E). East sign: NORTH -> CAVE, EAST -> CASTLE; south sign unchanged (TOWN / CASTLE). Arrows are drawn, not font glyphs.
- Training yard moved with one constant (`YARD_SHIFT`); the wooden shed moved north (`SHED_SHIFT_Y`) so it clears the south-east tower.
- North watch post moved up off the road. South watch post removed (building, collision); `guard4` now stands there (npc_data.gd).
- Removed dead code: `edge` / `edge_text` (+ HUD check), `_shore_pts()`, duplicate hard-coded sign positions, leftover "Removed ..." comments.
- Two palms that hid the east-gate guard were moved: one beside the north watch post (864, 366), one further south (806, 586).
- East gate pillars now match the south gate (banner, taller); same 46 px opening. Idle guard3 removed (guard4 stays at the east gate). Tree moved from (740,560) to (698,606), clear of the shed and tower.

### Stage 3 (earlier notes)

#### What is new in Stage 3
- **Fists combo:** Space = punch, punch, kick. Press again during a swing (or just after) to chain. The kick hits hardest and knocks back.
- **Dodge (Shift):** a short roll with brief invulnerability, away from your movement keys (back-step if you stand still).
- **Lasso (Q):** throws in the direction you face. Pulls a small rat to you and stuns it for a second; also yanks back a rat that is
  running away at low health. Cooldown 2 s after a catch, 1 s after a miss (icons bottom-left show it). Big rat: "Too heavy!" (Stage 4).
- **Small rats (6, on the east side):** patrol around their nest, notice you with a vision cone + a small proximity bubble
  (? with a filling bar), chase, wind up (red flash + red aim line + "!"), lunge, then recover - that is your opening.
  They flee at 1 HP, give up and walk home if you get far away, never respawn. Rocks and walls block their sight.
- **You:** 5 hearts, 1 s of invulnerability after a hit. XP +10 per rat. When you fall: "You fell", fade, back at the waystation gate
  with XP kept and dead rats staying dead (the full Stage 5 polish can build on this).
- Dialogue still pauses everything.

#### Where to tune (all in `scripts/combat.gd`, top of the file)
`COMBO` (damage, knockback, timing), `DODGE`, `LASSO`, `HERO_INVULN`, `XP_RAT`, `NEST_RATS` (which nest has how many rats),
`RAT` (HP, speeds, vision, leash, wind-up time, lunge, recover, stun ...).

#### Files (as of Stage 3)
main.gd wires; world_waystation.gd builds the map (now with `los()` line-of-sight); combat.gd = attacks, dodge, lasso, damage, effects,
game over; rat.gd = one rat's AI; player.gd moves and draws the hero (punch/kick/dodge poses); hud.gd = hearts, XP, rat count, skill icons.
tests/ holds optional headless checks: `godot --headless --fixed-fps 60 --path . -s tests/combat.gd` (also escape.gd, validate.gd, smoke.gd).
