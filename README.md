# Fortune Beasts: Squish Caravan 🍓👶🚚

A Roblox social game built from the *Fortune Beasts: Squish Caravan* (偷娃大作战)
concept. The loop, in four verbs:

| 养娃 Raise | 护娃 Protect | 偷娃 Steal | 运娃 Caravan |
|---|---|---|---|
| Hatch squishy fruit "babies" that earn coins passively. | Keep them safe in the vault — or place them out for **2× income** at the risk of being stolen. | Sneak into rival bases and steal their high-earners. | Load babies into a vehicle, buy insurance, and haul loot home — then **split fairly** or **betray** for more. |

…plus a collectible roster with rarities & roles, and the signature **squish** mechanic (stand by a baby, press **E**, watch it go boing).

---

## What's implemented (playable core loop)

- **Server-authoritative economy & persistence** — DataStore-backed profiles with
  an in-memory fallback (works in Studio without API access), offline earnings,
  and auto-save.
- **Raising (养娃)** — hatch rarity-weighted babies, place/recall them between the
  vault (1×) and the open (2×, exposed), passive income tick.
- **Squish (解压)** — a Squish Station near spawn renders your placed babies as
  bouncy procedural models; press **E** to squish the nearest one for a fun coin
  trickle (server rate-limited).
- **Caravan runs (运娃)** — pick an owned vehicle, buy an insurance tier, load
  babies, launch a timed run, then settle with an ambush/breakdown roll and a
  **Split vs Betray** choice that moves your Trust.
- **Garage** — buy vehicles with different capacity/speed/defense/fuel trade-offs.
- **Full UI** — coins/income/trust HUD, My Babies (collection + place/recall +
  caravan loadout), Caravan, and Garage panels, plus toast notifications.

## Content data (all defined, easy to tune)

- `src/shared/BabyData.luau` — 24-baby roster (fruit + profession themed) with
  rarity, role, income, squish factor and colours.
- `src/shared/Rarity.luau` — Common → Mythic tiers (hatch odds + income mult).
- `src/shared/Roles.luau` — Income / Trust / Defense / Raid / Caravan / Support.
- `src/shared/VehicleData.luau` — cart → Pearl River freighter.
- `src/shared/InsuranceData.luau` — None / Basic / Standard / Full.
- `src/shared/RouteData.luau` — themed caravan routes (Arctic / Africa / New York /
  Singapore / Osaka) with their babies, vehicles, and insurance. Captured for the
  upcoming route phase of the caravan system.
- `src/shared/GameConfig.luau` — **every gameplay number lives here.**

## Character art (no coding needed)

Each baby supports optional `image` (2D artwork), `meshId` and `textureId` (3D
figure) fields. Drop in Roblox asset IDs and the game uses them automatically — the
art appears in the Collection Board, hatch popup, the in-world portrait billboard,
and (for meshes) the 3D figure, with a graceful fallback to the procedural
placeholder for any baby without art yet. **See [`ART_GUIDE.md`](ART_GUIDE.md)** for
the step-by-step upload guide.

---

## Running it

Roblox code can't be compiled here; you open it in **Roblox Studio**. This repo is
a [Rojo](https://rojo.space) project, the standard way to keep Roblox code in git.

### Option A — Rojo (recommended)

1. Install [Rokit](https://github.com/rojo-rbx/rokit) (a toolchain manager), then
   from the repo root:
   ```sh
   rokit install      # installs rojo, selene, stylua pinned in rokit.toml
   ```
2. Open Roblox Studio → install the **Rojo** plugin (`rojo plugin install`).
3. In the repo: `rojo serve`
4. In Studio: open the Rojo plugin → **Connect**. The code syncs into the place.
5. Press **Play**. Hatch a baby, place it, walk to the Squish Station, press **E**.

Build a `.rbxlx` you can double-click instead:
```sh
rojo build default.project.json --output FortuneBeasts.rbxlx
```

### Option B — no tooling

`rojo build` (above) produces a place file you can open directly in Studio with no
plugin. Enable **Studio Access to API Services** (Game Settings → Security) if you
want DataStore saves; otherwise the in-memory fallback keeps everything working
for testing.

---

## Project layout

```
default.project.json     Rojo: maps folders -> Roblox services
src/shared/              ReplicatedStorage.Shared — data + types + net (client+server)
src/server/              ServerScriptService.Server — authoritative game logic
src/client/              StarterPlayerScripts.Client — UI + squish world view
.github/workflows/ci.yml StyLua + Selene + Rojo build on every push
```

Architecture: the **server owns the truth** (coins, babies, caravans) and pushes a
profile snapshot via the `StateUpdate` remote; the client mirrors it into
`State.luau` and re-renders. Every action is a validated RemoteFunction. See
`src/shared/Net.luau` for the full remote list.

---

## Roadmap — the rest of the concept

These have clean extension points in the current code (noted inline):

1. **PvP stealing / raids (偷娃 · 护娃)** — `StealService`: target another online
   player's *placed* babies, success rolled against their Defense-role babies and
   your Raid-role babies; raid-alert notifications; cooldown in `GameConfig`.
2. **Multiplayer team caravans** — extend `CaravanService` from solo to a shared
   pot with per-member betray (the hooks are noted in the file).
3. **Baby levelling / fusion** — `OwnedBaby.level` already exists; add an upgrade
   service and cost curve.
4. **Used-car market & vehicle modding** — random-condition cheap vehicles +
   engine/tire/safe upgrades (concept pages 5–6).
5. **Game modes** — 3v3 Steal, Protect-the-base, Caravan Escort matchmaking.
6. **Real art** — swap the procedural `BabyModel` for modelled/animated assets and
   add viewport thumbnails in the collection grid.

Each is independently shippable on top of the working core.
