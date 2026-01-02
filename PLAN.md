# Kaiju Destruction (Roblox) — plan.md (Codex-Ready)

Owner: Randall  
Goal: Build a Roblox “kaiju city destruction” game that is **original IP** (NOT Godzilla), fun for kids, and monetizable.  
Working Title: **Kaiju Rampage** (rename anytime)

## 0) IP / Safety Guardrails (Non-Negotiable)
- Do **not** use “Godzilla”, “Gojira”, Toho names, movie designs, logos, or exact sound/roar likeness.
- Create an **original kaiju**: name, silhouette, colors, abilities, roar sound (use Roblox audio library or custom).
- Keep tone **cartoony** (Roblox-friendly). No gore. Explosions OK if stylized.

---

## 1) Core Loop (MVP)
**Spawn → Smash Buildings → Earn Rage (currency) → Upgrade Abilities / Size → Unlock New Zones → Repeat**

### Player Goals (30–120 seconds)
- Break stuff fast
- Get bigger / stronger visibly
- Flex with cosmetics (skins, trails, roar FX)
- Chase short-term quests

---

## 2) MVP Feature Set (Ship Fast)
### 2.1 City + Destructible Buildings (Simple but satisfying)
- Buildings are made of Parts grouped under a Model.
- Each building has:
  - `Health`
  - `Reward` (Rage currency)
  - `BreakMode`:
    - MVP: “Shatter” (unanchor parts + impulse)
    - Later: “SwapToRubble” (replace with rubble model)
- When building breaks:
  - Award Rage to the attacker (server-side)
  - Play SFX/VFX
  - Start respawn timer (e.g., 30–90 sec)

### 2.2 Kaiju Character Controller
- Start with Roblox Humanoid rig (R15) scaled up (MVP).
- Kaiju stats:
  - `SizeLevel`
  - `MoveSpeed`
  - `JumpPower`
  - `AttackPower`
  - `RageMultiplier`

### 2.3 3 Abilities (MVP)
All abilities must be:
- Triggered on client (input/UI)
- Validated + executed on server (anti-exploit)
- Cooldowns tracked server-side

**Ability A — Stomp (AOE)**
- AOE radius around player root
- Damages buildings + knocks loose parts
- Small camera shake + dust ring

**Ability B — Tail Swipe (Cone)**
- Cone hitbox in front (or to side) of player
- Pushback/knockback effect
- Good for clearing clusters

**Ability C — Roar (Knockback / Stun)**
- Radius effect, pushes lightweight debris
- Optional “stun” for NPC helicopters later

### 2.4 Currency + Upgrades (Monetizable later)
Currency: `Rage`
- Earn by destroying buildings
- Spend at Upgrade Shop:
  - Stomp Radius +
  - Cooldown Reduction
  - Move Speed +
  - Size Level +
  - Rage Multiplier +

### 2.5 Data Saving (MVP)
Save:
- Rage (optional if you want “prestige style”)
- Upgrades / SizeLevel
- Owned cosmetics
- Dev products owned are not saved as currency; track purchases via receipt processing.

Use:
- DataStoreService
- Retry/backoff
- Session lock (simple) or robust pattern

### 2.6 UX (Minimum)
- HUD:
  - Rage balance
  - SizeLevel
  - 3 ability buttons (also keybinds)
  - Cooldown indicators
- Shop UI:
  - Upgrade list w/ costs
  - “Buy” button
- Simple quest UI (optional in MVP):
  - “Destroy 5 buildings” → bonus Rage

---

## 3) Monetization Plan (Do This After MVP Feels Fun)
Target: “Pay for convenience + cosmetics” (avoid pay-to-win perception)

### 3.1 Game Passes (Permanent)
- **VIP Kaiju**: +10% Rage earned, special name tag
- **Speed Boost**: +10% move speed
- **Extra Loadout Slot** (later, if you add multiple kaiju types)

### 3.2 Developer Products (Consumable)
- **Rage Boost 2x** (15 minutes)
- **Instant Respawn** (if you add deaths later)
- **Nuke Taunt** (pure cosmetic VFX, big boom, no extra damage)
- **City Reset** (private servers only; resets destructibles instantly)

### 3.3 Cosmetics (UGC-friendly later)
- Skins (colorways, spikes, glow)
- Trails / footprints VFX
- Roar VFX (shockwave color)
- Emotes

---

## 4) Roblox Folder / Script Architecture (Recommended)
### 4.1 ReplicatedStorage
- `Remotes`
  - `AbilityRequest` (RemoteEvent)
  - `PurchaseRequest` (RemoteEvent)
  - `UIState` (RemoteEvent or RemoteFunction)
- `Modules`
  - `Config`
    - `AbilitiesConfig`
    - `UpgradesConfig`
    - `BuildingsConfig`
  - `Shared`
    - `MathUtil`
    - `CooldownUtil`

### 4.2 ServerScriptService
- `GameServer`
  - `AbilityService.server.lua`
  - `BuildingService.server.lua`
  - `EconomyService.server.lua`
  - `DataService.server.lua`
  - `PurchaseService.server.lua` (Dev Products / Game Pass checks)
  - `AntiExploit.server.lua` (basic rate limit & validation)

### 4.3 StarterPlayer
- `StarterPlayerScripts`
  - `Client`
    - `InputController.client.lua`
    - `HUDController.client.lua`
    - `ShopController.client.lua`
    - `VFXController.client.lua`
- `StarterCharacterScripts` (optional)
  - `KaijuAnimator.client.lua`

### 4.4 Workspace
- `Map`
  - `City`
    - `Buildings` (models)
- `Spawns`

---

## 5) Tech Decisions (MVP Defaults)
- Use **Attributes** on building models:
  - `Health`, `MaxHealth`, `Reward`, `RespawnSeconds`, `IsDestroyed`
- Use **CollectionService** tags:
  - Tag buildings as `DestructibleBuilding`
- Server is authority:
  - Damage + rewards only on server
- Cooldowns:
  - Server tracks per-player cooldowns for each ability
- Hit detection:
  - MVP: radius/cone checks using magnitude + dot product
  - Later: region/overlap queries

---

## 6) Development Steps (Codex Task Breakdown)
### Phase 1 — City + Destruction (1–2 sessions)
1. Create 10–20 simple buildings (models of parts)
2. Add building attributes + tag them
3. Implement `BuildingService`:
   - Initialize buildings (cache health)
   - `ApplyDamage(building, amount, attacker)`
   - Break + respawn logic
4. Add basic VFX on break

**Definition of Done**
- You can walk up, press a test key, and break buildings reliably.
- Rewards increment server-side.

### Phase 2 — Abilities (1–2 sessions)
1. Build remote event pipeline
2. `AbilityService` executes Stomp/Tail/Roar
3. Add cooldown UI

**DoD**
- Abilities only work within cooldown rules
- Buildings take damage; rewards granted

### Phase 3 — Economy + Upgrades (1–2 sessions)
1. `EconomyService` handles currency ledger per player
2. Shop UI uses UpgradesConfig
3. Apply upgrades to kaiju stats/ability params

**DoD**
- Upgrades persist in session; affect gameplay

### Phase 4 — Data Saving (1–2 sessions)
1. `DataService` save/load
2. Handle failures gracefully (warn + continue)
3. Auto-save every 60–120 sec

**DoD**
- Rejoin restores upgrades / stats correctly

### Phase 5 — Monetization Hooks (after fun)
1. GamePass checks (VIP multiplier)
2. Dev products receipt processing
3. Cosmetic items

---

## 7) Codex Prompts (Use These Exactly)
### Prompt A — “Scaffold Project”
> You are an expert Roblox (Luau) engineer. Create the server/client folder structure described in plan.md, including placeholder scripts with clear TODOs and comments. Use idiomatic Luau. Prefer ModuleScripts for configs and services. Include a README-style header comment in each file explaining responsibility.

### Prompt B — “BuildingService”
> Implement BuildingService.server.lua. Requirements:
> - Use CollectionService tag 'DestructibleBuilding'
> - Buildings have attributes: MaxHealth, Health, Reward, RespawnSeconds, IsDestroyed
> - Expose functions: Init(), ApplyDamage(buildingModel, amount, player)
> - On Health <= 0: mark IsDestroyed, unanchor building parts, apply impulse, award Reward to player via EconomyService, then respawn after RespawnSeconds by restoring original state.
> - Must be server-authoritative and safe from nil references.
> - Include rate limiting for ApplyDamage per player to prevent spam.

### Prompt C — “AbilityService”
> Implement AbilityService.server.lua + required shared configs.
> - RemoteEvent Remotes/AbilityRequest receives: abilityName, clientTimestamp
> - Validate: player alive, ability exists, cooldown, distance sanity (no teleport abuse)
> - Abilities:
>   - Stomp: radius AOE damage to all buildings within radius
>   - TailSwipe: cone damage in front of player using dot product
>   - Roar: radius effect with smaller damage + knockback impulse to loose parts
> - Cooldowns stored server-side per player.
> - Ability params come from AbilitiesConfig and scale with upgrades.

### Prompt D — “Economy + Upgrades”
> Implement EconomyService and UpgradesConfig.
> - EconomyService tracks per-player Rage (IntValue or table) server-side
> - Provide AddRage(player, amount, reason), SpendRage(player, amount) returning boolean
> - Upgrade purchases from client validated server-side via PurchaseRequest remote
> - Upgrades modify player stats and ability params (e.g., stompRadiusMultiplier, cooldownReduction, rageMultiplier)
> - Ensure no negative balances and prevent exploit purchases.

### Prompt E — “DataService”
> Implement DataService with DataStoreService.
> - Save/Load: Rage, upgrades, sizeLevel, ownedCosmetics
> - Use retry with exponential backoff
> - Autosave timer
> - On player removing: save
> - Handle failures without crashing game.

### Prompt F — “Client UI”
> Implement minimal HUD + Shop UI controllers.
> - Show Rage, SizeLevel, and 3 ability buttons with cooldown overlays
> - Keybinds: 1=Stomp, 2=Tail, 3=Roar
> - Shop panel toggled with a button
> - Purchases call PurchaseRequest remote
> - Ability presses call AbilityRequest remote
> - UI should be clean, simple, mobile-friendly.

---

## 8) Balancing Defaults (Start Here)
- Building Health: 50–500 (varies by size)
- Reward: 5–50 Rage
- Stomp:
  - base radius 18
  - damage 40
  - cooldown 4s
- TailSwipe:
  - range 22
  - angle cos threshold ~0.6 (tune)
  - damage 25
  - cooldown 3s
- Roar:
  - radius 24
  - damage 10
  - cooldown 8s
- Upgrades:
  - 10 tiers each, cost scaling 1.35x

---

## 9) Unique Twist Ideas (Pick 1 Later)
To stand out from generic “smash sims”:
- **Elemental Mutation**: fire/ice/storm forms with different VFX
- **Heat Meter**: smash builds “Rage Mode” for 10 seconds
- **City Alerts**: helicopters/tanks spawn when destruction passes thresholds
- **Boss Kaiju Events**: server-wide “mega boss” every 30 minutes

---

## 10) Ship Checklist
- [ ] Fun loop works in 60 seconds
- [ ] No client-side currency authority
- [ ] Basic anti-spam on remotes
- [ ] Save/load validated
- [ ] Mobile input works
- [ ] Private server pricing (optional)
- [ ] Add game icon + thumbnails

---

## 11) Naming (Original IP Suggestions)
Kaiju names:
- Brontflare
- Shardjaw
- Voltspine
- Rumblemaw
- Ashback

Game names:
- Kaiju Rampage
- City Cruncher
- Monster Mayhem
- Titan Town Smash

---

## 12) First Deliverable Today
MVP build order for today:
1) City buildings + tags/attributes  
2) BuildingService ApplyDamage + respawn  
3) Test keypress to damage nearest building  

Once that’s in, abilities are easy.

END
