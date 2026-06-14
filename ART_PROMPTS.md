# Character Render Prompts

Ready-to-use prompts for generating each baby's artwork (via Codex image render or
any generator). The goal is a **consistent set**: same toy style, same camera, same
lighting, plain background — so they look like one cohesive collection and cut out
cleanly for the game.

---

## How to use this

1. For each character: render using **STYLE BLOCK + that character's Subject line**
   (paste the style block first, then the subject).
2. Save each result as **`<id>.png`** using the exact `id` in the heading (e.g.
   `goldberry_banker.png`). That filename = the in-code id, so wiring is trivial.
3. Upload the PNGs to Roblox (Studio → Asset Manager → Add Images), then send me
   the list of `id → rbxassetid` and I'll paste them into `BabyData.luau`.

## Image specs (important for a clean game look)
- **1:1 square, 1024×1024.**
- **One character, centered, full body, seated**, small margin around it.
- **Plain solid white (or transparent) background** — no scenery, no text, no extra
  props on the floor. (White is fine; I/you can knock it out with remove.bg.)
- **3/4 front view, eye level**, consistent across all of them.

---

## STYLE BLOCK (prepend to every prompt)

> 3D-rendered collectible vinyl designer-toy figurine of a chubby cute baby,
> blind-box style (Popmart/Soft-vinyl aesthetic), soft matte vinyl with subtle
> glossy highlights. Big round head, chunky squishable body, seated full-body pose,
> a pacifier in its mouth, slightly grumpy-yet-adorable expression, big glossy eyes,
> rosy blushed cheeks. Wearing a fruit-themed hood/hat. Clean studio product
> lighting, soft shadows, centered composition, plain solid white background, no
> text, highly detailed, octane render, 1:1 square.

---

## Subjects (main roster — 24 babies)

**goldberry_banker** — a golden strawberry-hood baby dressed as a banker in a tiny
dark suit and tie, holding a shiny gold coin, a small abacus beside it; rich gold
accents. (Epic · Income)

**peach_comfort** — a soft pink peach-hood baby in cozy pastel pajamas, hugging a
plush pink heart, warm gentle look. (Uncommon · Support)

**bluecoin** — a blueberry-hood baby in a blue cap marked with a "B" coin logo,
holding a big blue coin, sporty tracksuit. (Rare · Income)

**kiwi_analyst** — a fuzzy kiwi-hood baby with round glasses and a tiny grey suit,
holding a tablet showing a rising stock chart. (Rare · Trust)

**bossberry** — a purple grape-cluster-hood baby as a mafia boss in a black suit and
sunglasses, holding a small golden scepter, sitting in a red leather chair. (Legendary · Raid)

**apple_hr** — a red apple-hood baby in office wear holding an "HR" clipboard, kind
but firm expression. (Uncommon · Support)

**exam_sprint** — a lemon-hood baby with a white "A+" headband, gripping a pencil,
an open book beside it, determined cramming face. (Uncommon · Trust)

**berry_scholar** — a grape-hood baby scholar with round glasses reading a green
hardcover book, scarf. (Rare · Trust)

**cherry_cheer** — a red cherry-hood baby cheerleader holding two fluffy pink
pom-poms, energetic happy pose. (Uncommon · Support)

**chillberry** — a light-blue blueberry-hood baby bundled in a frosty winter onesie
with little snowflakes, cool calm look, icy breath. (Common · Support)

**explorer_orange** — an orange-hood baby explorer in a safari hat holding a compass
and a rolled map. (Rare · Caravan)

**jungleberry** — a green watermelon-hood baby in leafy jungle-guard gear holding a
small leaf shield. (Uncommon · Defense)

**strawberry_striker** — a red strawberry-hood baby soccer player in a jersey
numbered 10, one foot on a soccer ball. (Rare · Raid)

**peach_tennis_ace** — a peach-hood baby tennis player with a headband and wristband
holding a tennis racket, a tennis ball nearby. (Rare · Raid)

**dragonfruit_brawler** — a hot-pink dragonfruit-hood baby martial artist in a white
karate gi with a red belt, fists up, fierce cute glare. (Epic · Raid)

**blueberry_skater** — a blue blueberry-hood baby skater in a backwards cap and
hoodie, one foot on a skateboard. (Rare · Caravan)

**avocash** — an avocado-hood baby (brown pit visible on top) in casual wear,
holding a fan of cash and a gold coin, smug rich look. (Epic · Income)

**papaya_planner** — an orange papaya-hood baby in a neat blazer holding a planner
notebook labeled "PLAN" and a pen. (Rare · Trust)

**coconut_sage** — a brown coconut-hood baby as a wise old sage with a tiny white
beard, holding a wooden staff, serene. (Uncommon · Support)

**melon_knight** — a green melon-hood baby knight in light armor holding a small
sword and round shield, brave stance. (Epic · Defense)

**mango_ranger** — a yellow-orange mango-hood baby ranger in an outback hat with a
utility vest, holding a small blade, adventurous. (Rare · Caravan)

**pumpkin_punk** — an orange pumpkin-hood baby punk rocker in a tiny black leather
jacket with studs, holding a mini electric guitar, rebellious smirk. (Epic · Raid)

**starfruit_dj** — a bright-yellow star-shaped (starfruit) hood baby DJ wearing big
headphones, hands on a small DJ turntable deck, music notes. (Legendary · Support)

**grape_clerk** — a purple grape-hood baby office clerk in a vest holding a
calculator and a stack of papers. (Uncommon · Trust)

---

## Route babies (optional, next batch)

The 40+ route babies live in `RouteData.luau` (Arctic, Africa, New York, Singapore,
Osaka), each with a `theme` describing its costume/animal motif. Same recipe: STYLE
BLOCK + the baby's theme + role. Tell me when you want the full prompt list for a
route and I'll generate it the same way.
