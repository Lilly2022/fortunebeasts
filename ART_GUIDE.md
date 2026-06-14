# Art Guide — making the characters look like your concept art (no coding)

You don't need to write any code to give the babies their real look. You upload
art to Roblox, copy the ID it gives you, and paste it into one line per baby. This
guide shows the smooth path.

---

## TL;DR recommendation

**Do the 2D artwork first.** It's the fastest, smoothest, and closest to your
concept — because your concept renders *are* the finished art. The 3D meshes are
optional and can come later.

| Step | What you do | Result |
|---|---|---|
| 1 | Upload each character render as an **Image** in Roblox | Get an asset ID |
| 2 | Paste the ID into that baby's `image = "..."` line | Art shows in the Collection Board, hatch popup, and as a portrait above the in-world baby — **identical to your render** |
| 3 *(optional, later)* | Turn renders into 3D meshes and upload them | The in-world figure becomes a real 3D model too |

---

## Part 1 — 2D artwork (do this first)

### A. Prepare the images
- One PNG per character (square works best, e.g. 512×512 or 1024×1024).
- Transparent background looks best for portraits (so there's no white box). Tools
  like remove.bg or Photopea can cut the background in a minute.

### B. Upload to Roblox and get the ID
**Easiest (in Roblox Studio):**
1. Open Studio → top menu **View → Asset Manager**.
2. Right-click in the Images folder → **Add Images…** → select your PNGs.
3. After they finish moderation (usually minutes), right-click an image → **Copy ID
   to Clipboard**. That number is your asset ID.

**Or via the website:** https://create.roblox.com/dashboard/creations → **Decals/
Images → Upload**. Click an uploaded image; the number in its URL is the ID.

> Note: uploaded images must pass Roblox moderation before they appear in-game.

### C. Put the ID in the game
Open `src/shared/BabyData.luau`. Find the baby you want and add an `image` field:

```lua
{ id = "goldberry_banker", name = "Goldberry Banker", ... ,
  image = "rbxassetid://PASTE_NUMBER_HERE" },
```

That's the whole change. The code already shows `image` everywhere a character
appears. Repeat per baby. (If you'd rather not touch the file, send me the list of
`baby name → asset ID` and I'll paste them all in.)

---

## Part 2 — 3D meshes (optional, for the in-world figure)

This makes the actual walk-up-to-it 3D baby match too. It's more work, so treat it
as a phase 2.

### Getting a 3D model from your render
You have no-/low-modeling options:
- **AI image → 3D:** [Meshy](https://www.meshy.ai), [Tripo](https://www.tripo3d.ai),
  or [Luma Genie](https://lumalabs.ai/genie) — upload your render, download a
  `.obj`/`.fbx` + texture. Expect to clean it up a bit.
- **Hire a modeler:** for a polished, consistent set across all routes, one artist
  on Fiverr/Roblox talent can model the roster from your renders. Best quality.

### Upload to Roblox
1. Studio → **Asset Manager → Meshes → Add Meshes…** (import the `.fbx`/`.obj`).
2. Right-click the mesh → **Copy ID**. Do the same for its texture image (Part 1B).

### Put the IDs in the game
In `src/shared/BabyData.luau`, add `meshId` (and `textureId`) to the baby:

```lua
{ id = "goldberry_banker", name = "Goldberry Banker", ... ,
  image = "rbxassetid://1111",      -- 2D art (menus + portrait)
  meshId = "rbxassetid://2222",     -- 3D figure in the world
  textureId = "rbxassetid://3333" }, -- texture for that mesh
```

The code automatically uses the mesh for the world figure when `meshId` is set, and
still falls back to the cute placeholder for any baby that doesn't have one yet — so
you can upgrade babies one at a time.

---

## What I (Claude) can do for you
- Paste in all your asset IDs once you have them (just send `name → id`).
- Add new babies/routes from your design sheets (see `RouteData.luau`).
- Wire the route system, stealing, and game modes when you're ready.

You handle the uploads (they need your Roblox account); I handle all the code.
