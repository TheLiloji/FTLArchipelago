# Seeds de la nuit du 11/11 (apworlds beta.23), slot Tester

Servir : ArchipelagoServer --host 127.0.0.1 --port 38281 <dossier>/AP_*.zip. Chaque dossier a son YAML.

## b01_kestrel_key_rock
```yaml
  start_ship: rock
  kestrel_key: true
  layout_count: 10
  trap_chance: 30
  death_link: true
```
## b02_layouts_independent
```yaml
  layout_unlocks: independent
  layout_count: 20
  ship_layouts: all_layouts
  early_ship_keys: 3
```
## b03_layouts_progressive
```yaml
  layout_unlocks: progressive
  layout_count: 15
  victory_collects_layout: true
```
## b04_systems_all
```yaml
  systemsanity: every_level
  progressive_systems: true
  system_blueprints: true
  system_install: immediately
  progressive_unlocks_system: true
  free_upgrades: true
```
## b05_shop_heavy
```yaml
  shop_checks: 100
  shop_by_sector: true
  shop_per_ship: per_layout
  shop_unlock_mode: locked
  shop_hints: seen
  shop_deal_scrap: 200
```
## b06_combat_sector
```yaml
  combat_checks: 10
  combat_checks_mode: per_sector
  fights_per_sector: 3
  event_checks: 20
  reactor_checks: true
```
## b07_sector_skip_locks
```yaml
  sector_skip: true
  sector_locks: true
  flagship_sabotage: 5
  sector_logic: power
```
## b08_minimal_one_win
```yaml
  layout_count: 1
  victories_required: 1
  shop_checks: 5
  sectorsanity: disabled
  general_achievements: disabled
  ship_achievements: false
```
## b09_crew_names_links
```yaml
  crew_names: multiworld_and_team
  energy_link: true
  trap_link: true
  death_link: true
  death_link_effect: major_incident
  crew_checks: true
  crew_members: true
```
## b10_archives_goal
```yaml
  archives: 10
  archives_required: 10
  victories_required: 3
  head_starts: 5
  run_start_scrap: 50
```
## m01_mv_default
```yaml
  death_link: false
```
## m02_mv_links_traps
```yaml
  trap_chance: 40
  death_link: true
  trap_link: true
  energy_link: true
```
## m03_mv_shop_combat
```yaml
  shop_checks: 80
  combat_checks: 10
  combat_checks_mode: per_sector
  shop_per_ship: per_class
```
## m04_mv_kestrel_key
```yaml
  kestrel_key: true
  layout_count: 12
  layout_unlocks: progressive
```
