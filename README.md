# Fortune Beasts: Caravan Wars 🐸🪙

> **Collect weird money beasts. Build your vault. Run caravans with friends. Steal from rival clans. Don't trust the Debt Dragon.**

A Roblox kingdom-heist game: collect coin-making **Fortune Beasts**, place them in your base, protect them, **steal** exposed beasts from rivals, run **caravans** with friends — then choose to **Split Fair** or **Grab Extra** (betray!).

This repository contains the complete, playable **MVP** — no coding needed to run it.

---

## 🚀 How to play it RIGHT NOW (no coding!)

1. **Install Roblox Studio** (free): <https://create.roblox.com> → "Get Studio"
2. **Download the game file**: grab [`build/FortuneBeasts.rbxl`](build/FortuneBeasts.rbxl) from this repository
   (on GitHub: click the file → click the **Download** button ⬇️)
3. **Double-click `FortuneBeasts.rbxl`** — it opens in Roblox Studio
4. Press the big blue **Play** button ▶️ — the whole map builds itself and you spawn with a Tax Rat 🐭 and a Gold Frog 🐸

### 🧑‍🤝‍🧑 Test the fun part (stealing!) with 2 players
In Studio, don't press Play. Instead:
1. Open the **Test** tab at the top
2. Set **"1 Player"** dropdown to **"2 Players"** (Local Server)
3. Click **Start** — two game windows open, each is a different player
4. In window 1: walk to the other player's base, stand near their **Gold Frog**, **hold F** to steal it, then RUN back to your red **Capture Zone**!
5. In window 2: you'll see the 🚨 **RAID ALERT** — chase the thief and **touch them** to get your frog back!
6. When you're done, click **Cleanup** in the Test tab to close the test servers.

### 🌍 Publish it so friends can play
1. In Studio: **File → Publish to Roblox**
2. Give it a name and click **Create**
3. Click **Game Settings → Permissions → Friends** (or Public) → Save
4. Find the game on your Roblox profile and play with real friends!

---

## 🎮 How the game works

| Action | How | What happens |
|---|---|---|
| **Earn coins** | automatic | Every beast pays coins every 10 seconds |
| **Protect a beast** | press **E** on your beast | Moves it into your **vault** — safe, but only 50% income |
| **Expose a beast** | press **E** again | Back outside — 100% income, but stealable! |
| **Steal** | hold **F** on a rival's exposed beast | It sticks to your back (you walk slower) — run home to your red **Capture Zone** to keep it! |
| **Defend** | chase the thief and **touch them** | Your beast escapes and returns home |
| **Buy beasts** | market stalls at the center | Vault Turtle 🐢 (60), Trust Owl 🦉 (80), Debt Dragon 🐉 (free... 😏) |
| **Hatch babies** | 🥚 Mystery Egg at the market (150) | One of **305 collectible babies** — 30 species × 10 numbered variants (草莓88 style!) across 5 rarities. Rarer = bigger, shinier, crowned 👑 |
| **Caravan** | orange pad at the market | Escort the wagon to the delivery point. Solo = 50 coins. With a friend = 120-coin pool... |
| **Trust or betray** | end of a 2-player caravan | **Split Fair** (60 each, +trust) or **Grab Extra** (90 vs 30, but you're marked 💀 **OATHBREAKER** for 10 minutes) |

**New-player safety:** you can't be robbed for your first 3 minutes, you get 60s protection after being robbed, and your starter Tax Rat can never be stolen.

---

## 📁 What's in this repository

```
default.project.json      Rojo project file (maps src/ into a Roblox place)
build/FortuneBeasts.rbxl  ⭐ The ready-to-open game file
src/
  shared/                 ReplicatedStorage.FB_Modules
    GameConfig.lua        Every game number (income, timers, rewards) - tweak here!
    BeastConfig.lua       The 5 Fortune Beasts and their stats
  server/                 ServerScriptService.FB_Server (server-authoritative)
    init.server.lua       Boots everything, creates remotes
    MapService.lua        Builds the map (ground, market, caravan route)
    PlotService.lua       Builds + assigns the 8 player plots
    PlayerDataService.lua Coins, trust, protection, Oathbreaker
    BeastService.lua      Beast models, placement, vault/expose, ownership
    IncomeService.lua     The 10-second income tick (+ Debt Dragon's cut)
    StealService.lua      Stealing, carrying, chasing, capture zones
    MarketService.lua     The 3 market stalls
    CaravanService.lua    Caravan runs + Split Fair / Grab Extra
  client/                 StarterPlayerScripts.FB_ClientController
    init.client.lua       HUD, alerts, caravan choice buttons
docs/
  TESTING_GUIDE.md        Step-by-step tests for every feature (+ what could break)
  ROADMAP.md              How we grow this into the full Squish Caravan vision
```

**Changing the game without coding:** open `src/shared/GameConfig.lua` — every number has a comment. Want stealing to feel scarier? Lower `grabBackDistance`. Want richer players? Raise `startingCoins`. (In Studio, the same file lives at `ReplicatedStorage → FB_Modules → GameConfig`.)

---

## 🔧 For developers (optional)

The project uses [Rojo](https://rojo.space). To rebuild the place file after editing source:

```bash
rojo build default.project.json -o build/FortuneBeasts.rbxl
```

Or live-sync into an open Studio session with `rojo serve` + the Rojo Studio plugin.

Design pillars:
- **Server authoritative** — the client never decides coins, ownership, steals, or rewards
- **Everything is generated from code** — no hand-built map, no Toolbox assets, nothing copyrighted
- **One config file** — all balance numbers live in `GameConfig.lua`
- **Debug prints** — every system logs with a `[FB]` prefix (set `GameConfig.debug = false` to silence)
