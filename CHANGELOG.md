# Changelog

All notable changes to FS25 No-Reset MP are documented here.
The format is based on [Keep a Changelog](https://keepachangelog.com/).

## [1.0.1.0] - 2026-07-12

### Changed
- Relicensed to **Proprietary, source-available** (was MIT), consistent with the
  KeilerHirsch mod standard. The prior v1.0.0.0 release remains under MIT; this
  change applies from this release onward.
- Added the author signature to the script header.

### Added
- `.github/FUNDING.yml` (Ko-fi) and a Ko-fi support callout in the README.

## [1.0.0.0] - 2026-07-11

### Added
- Initial release — **Hardcore** mode.
- Blocks the player-triggered "reset vehicle to shop" option in multiplayer by
  overwriting `Vehicle.getCanBeReset` to return `false` while in a multiplayer
  session.
- Singleplayer behaviour is left completely unchanged.
- The engine out-of-world safety net is deliberately preserved (it calls
  `Vehicle:reset` directly and does not consult `getCanBeReset`), so vehicles
  that genuinely leave the world are still rescued automatically.
