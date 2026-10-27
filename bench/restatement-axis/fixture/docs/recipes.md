# Recipes

Worked schedules for common doughs. Each block is a complete `schedules/<name>.toml`
file; copy it under the name shown and adjust minutes to your kitchen.

## Rye sourdough — `schedules/rye-sour.toml`

A warm, humid first rise to wake the culture, then a cooler stretch to build
sourness without over-proofing.

```toml
[[stage]]
temp_c = 28
humidity = 80
minutes = 60

[[stage]]
temp_c = 24
humidity = 75
minutes = 90
```

## Enriched brioche — `schedules/brioche.toml`

Butter-heavy dough smears above 27 °C, so the whole schedule stays cool and runs
long.

```toml
[[stage]]
temp_c = 25
humidity = 70
minutes = 120
```

## Croissant — `schedules/croissant.toml`

Laminated dough needs humidity high enough that the surface never skins but a
temperature low enough that the butter layers stay solid.

```toml
[[stage]]
temp_c = 24
humidity = 85
minutes = 75

[[stage]]
temp_c = 26
humidity = 85
minutes = 30
```

## Adjusting for altitude

Above roughly 1500 m, dough rises faster. Cut each stage's minutes by about a
fifth and keep the temperatures as written.
