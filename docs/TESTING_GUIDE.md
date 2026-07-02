# Testing Guide 🧪

Test every feature in the build order it was made. You never need to write code —
just open `build/FortuneBeasts.rbxl` in Roblox Studio and follow along.

**Reading debug messages:** open the **Output** window in Studio (View tab → Output).
Every game system prints lines starting with `[FB]`. If something seems broken,
the Output window tells you what the server actually did.

**Starting a 2-player test:** Test tab → set "1 Player" to "2 Players" → Start.
Two windows open (Player1 + Player2). Click **Cleanup** when done.

---

## 1. Map + plots build themselves

**What was built:** MapService + PlotService generate the whole world at runtime.

**Test:** Press Play ▶️.
- You spawn at the center **Market** plaza
- You see the orange **CARAVAN START** pad, a bridge over a river, and a green **DELIVERY** pad in one direction
- 8 wooden plots ring the map; one sign now says **"🏠 [YourName]'s Base"**
- Output shows `[FB] Server ready`

**What could break:** if the Output shows a red error mentioning a service name,
that service failed — copy the error into a bug report / ask Claude to fix it.
**Undo:** nothing to undo — the map is rebuilt fresh every Play.

## 2. Coins + leaderstats

**Test:** Press Play. Top-left HUD shows **🪙 100**. Press Tab (player list) —
you have **Coins 100, Trust 0**.

## 3. Starter beasts

**Test:** Walk to your plot. A gray **Tax Rat** and a golden **Gold Frog** sit on
two yellow pads, with your name under theirs. HUD alert says you received them.

## 4. Passive income

**Test:** Stand still 30 seconds. Coins go 100 → 125 → 150... (+25 per 10s tick:
Tax Rat 5 + Gold Frog 20, both exposed = 100%). Output logs `[FB][Income]` ticks.

## 5. Vault (protect) / expose

**Test:** Press **E** on your Gold Frog → it jumps to a blue pad inside the stone
vault hut. Next tick pays only +15 (5 + 20×50%). Press **E** again → back outside.

**What could break:** if both vault pads are full you get "❌ No free vault slot!" —
that's correct behavior, not a bug.

## 6. Stealing + raid alert + chase (THE moment) 🚨

**Test (2 Players):**
1. **Player2:** press E on your own Gold Frog twice if needed so it's OUTSIDE.
   Wait 3 minutes (beginner protection) — or for fast testing, open
   `GameConfig.lua` and set `beginnerProtectionSeconds = 5` first.
2. **Player1:** run to Player2's base, stand by the Gold Frog, **hold F** for 2s
3. The frog sticks to your back, you're slower, and you see "Run to your CAPTURE ZONE!"
4. **Player2:** you get 🚨 **RAID!** — chase Player1!
   - If you **touch** Player1 → "💪 You caught the thief!" and the frog goes home
   - If Player1 reaches their red **Capture Zone** → the frog is theirs, name tag
     changes, and you get 60s protection (🛡️ timer in your HUD)
5. Try holding F on a **vaulted** beast → "🔒 ... can't be stolen!"
6. Try holding F on a starter **Tax Rat** → there is no steal prompt at all (starters are safe)

**What could break:** if the beast floats weirdly while carried, that's cosmetic —
ownership is still decided by the server. Resetting your character (Esc → Reset)
while carrying returns the beast home (that's rule #15, not a bug).

## 7. Market + Debt Dragon 🐉

**Test:** Walk to a colored stall at the market, hold E:
- **Vault Turtle (60)** / **Trust Owl (80)**: coins deducted, beast appears at your base
- Not enough coins → "❌ Not enough coins!" and NOTHING is deducted
- **Debt Dragon (free)**: you instantly get **+100 coins**... then watch the next
  income ticks: "🐉 Debt Dragon took X coins from your income..." Forever. 😈
  (That's the lesson: instant money isn't free money.)

## 8. Caravan — solo

**Test:** Hold E on the orange **CARAVAN START** pad. A countdown runs (20s), then
a wagon 🚚 spawns and rolls toward the bridge. **Walk beside it** — if you fall
more than 25 studs behind, it pauses ("⏸️ Wagon waiting"). At the green
**DELIVERY** pad: "🎉 Solo delivery! +50 coins!"

## 9. Caravan — trust or betray 💀

**Test (2 Players):**
1. Both players hold E on the CARAVAN START pad (second join launches it instantly)
2. Escort the wagon together to the delivery pad
3. Both get a choice popup: **🤝 SPLIT FAIR** or **😈 GRAB EXTRA**
   - Both fair → 60 coins each, **+5 Trust** each (check Tab list)
   - One grabs → betrayer +90 but **-10 Trust** and a floating 💀 **OATHBREAKER**
     tag over their head for 10 minutes; victim gets 30 and a "💔 BETRAYED" alert
   - Both grab → only 40 each, both lose trust, both marked
   - Ignore the popup 30s → counts as Split Fair

**What could break:** if a player leaves mid-run the caravan continues for the
other player (or is abandoned if empty) — check Output for `[FB][Caravan]` lines.

## 10. Mystery Egg + collection 🥚

**Test:** Earn/wait until you have 150+ coins, walk to the big white egg at the
market, hold E. You hatch one of **305 collectible babies** (30 species × 10
numbered variants, e.g. "Strawberry 88 · 草莓88"). Check:
- HUD alert shows the baby's name + rarity; "✨ NEW!" on first-time discoveries
- The 🏆 Babies counter (top-left) goes up on new discoveries
- Rarer babies are visibly bigger; Legendaries are golden with a crown and are
  announced to the whole server
- With a full base (8 beasts) the egg refuses and does NOT charge you

## 11. Beginner protection

**Test (2 Players):** immediately after starting, try to steal from the other
player → "🛡️ ... is protected right now." Both HUDs show the 🛡️ countdown from 3:00.

---

## Changing numbers safely

All balance lives in `ReplicatedStorage → FB_Modules → GameConfig` (in Studio) or
`src/shared/GameConfig.lua` (in this repo). Change one number, press Play, test.
If you break something, undo with **Ctrl+Z** (in Studio) or `git checkout` (in the repo).

Good first tweaks:
- `beginnerProtectionSeconds = 5` — makes steal-testing fast
- `incomeTickSeconds = 3` — coins flow faster for testing
- `caravanJoinWindowSeconds = 5` — less waiting when testing solo caravans
