# Kaiju Rampage

Kaiju Rampage is a Roblox game prototype where players become a giant monster and smash a city to earn Rage, upgrade abilities, and unlock new zones.

## Project Structure
- `src/ReplicatedStorage/Modules` - Shared configs and utilities
- `src/ServerScriptService/GameServer` - Server-side services (abilities, economy, data, anti-exploit)
- `src/StarterPlayer` - Client controllers and character scripts
- `src/Workspace` - Map, buildings, and spawn points

## Development
- Edit scripts under `src/` and sync them into Roblox Studio using your preferred workflow.
- Design goals and roadmap live in `PLAN.md`.

## Linting
Run the lightweight whitespace lint:

```
./scripts/lint.sh
```
