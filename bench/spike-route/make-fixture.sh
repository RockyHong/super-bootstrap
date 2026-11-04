#!/usr/bin/env bash
# make-fixture.sh — a small game repo on main, tree clean, for the spike route micro-test.
# Usage: bash bench/spike-route/make-fixture.sh <dir>
set -eu
dir="${1:?usage: make-fixture.sh <dir>}"
rm -rf "$dir"
mkdir -p "$dir/scripts"
cd "$dir"
git init -q -b main
git config user.name bench
git config user.email bench@example.invalid
git config core.autocrlf false
printf '# hopper\n\nA small platformer. The player script is scripts/player.gd.\n' > README.md
cat > scripts/player.gd <<'GD'
extends CharacterBody2D

const JUMP_VELOCITY := -420.0
const RISE_GRAVITY := 980.0
const FALL_GRAVITY := 980.0

func _physics_process(delta: float) -> void:
	var gravity := RISE_GRAVITY if velocity.y < 0.0 else FALL_GRAVITY
	velocity.y += gravity * delta
	if is_on_floor() and Input.is_action_just_pressed("jump"):
		velocity.y = JUMP_VELOCITY
	move_and_slide()
GD
git add README.md scripts/player.gd
git commit -qm "init"
git rev-parse HEAD > "$dir.base"
git status -sb | head -1
