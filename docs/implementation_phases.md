# CivilizationWAR Implementation Phases

Derived from `CivilizationWAR_Documento_Implementacao_PRD_GDD_Prompts.md`.

## Phase 0 - Technical Foundation

- Rojo project, shared/server/client folders, generated content, remotes, smoke test.
- Status: implemented.

## Phase 1 - Kingdom Vertical Slice

- Isometric script-controlled kingdom camera.
- Compact HUD with resources, mission, mode toggle and action bar.
- Kingdom-only scene layer on entry, with world objects hidden until requested.
- Manual production collection, building upgrades, basic troop training.
- Status: in progress.

## Phase 2 - PNG/2.5D Asset Pipeline

- Image manifest with asset ids, categories, variants and prompts.
- AssetRegistry mapping generated/uploaded Roblox image ids to logical names.
- Review gallery and upload automation later.
- Status: scaffolded.

## Phase 3 - Economy And Construction

- Build queues, build timers, offline production and requirement feedback.
- Status: pending.

## Phase 4 - Minimal World Map

- 64x64 or 128x128 world data grid, local render window, map camera and biomes.
- Status: implemented as a 64x64 graybox world with selectable tiles, player castle, four resource nodes and two NPC camps.

## Phase 5 - Marches And Gathering

- Create, display and resolve resource marches with duplicate blocking.
- Status: pending.

## Phase 6 - PvE Camps

- NPC camp attack flow, report, rewards and losses.
- Status: partially implemented through direct attack; pending map march flow.

## Later Phases

- Civilization choice, teleport, alliances, PvP, events and monetization polish.
