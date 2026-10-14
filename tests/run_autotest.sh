#!/usr/bin/env bash
# Automated checks for DOSIER.
#
#   tests/run_autotest.sh [path/to/godot] [screenshot_dir]
#
# 1. Imports the project.
# 2. Compiles every script & shader with all default GDScript warnings
#    promoted to errors (tests/strict_warnings.cfg -> override.cfg).
# 3. Plays the whole prologue automatically (dialogue auto-advances, choices,
#    QTE and battles are played by a bot) and saves screenshots.
# 4. Fails if any SCRIPT ERROR / ERROR line was printed.
set -u
GODOT="${1:-godot}"
SHOTS="${2:-test_output/shots}"
cd "$(dirname "$0")/.."
mkdir -p test_output
LOG=test_output/autotest.log

cleanup() { rm -f override.cfg; }
trap cleanup EXIT

echo "== import"
"$GODOT" --headless --path . --import >/dev/null 2>&1

echo "== strict compile"
cp tests/strict_warnings.cfg override.cfg
if ! "$GODOT" --headless --path . res://tests/compile_all.tscn 2>&1 | tee test_output/compile.log | grep -q "0 failed"; then
	echo "Compile check FAILED (see test_output/compile.log)"
	exit 1
fi

echo "== full play-through (this takes a while on software rendering)"
RUN=("$GODOT" --path . --audio-driver Dummy -- --autotest "--shots=$PWD/$SHOTS")
if command -v xvfb-run >/dev/null 2>&1 && [ -z "${DISPLAY:-}" ]; then
	xvfb-run -a -s "-screen 0 1280x720x24" "${RUN[@]}" >"$LOG" 2>&1
else
	"${RUN[@]}" >"$LOG" 2>&1
fi

# The dummy audio driver never releases playing streams at exit; those two
# shutdown lines are an engine/test-environment artefact, not a game error.
ERRORS=$(grep -E "SCRIPT ERROR|^ERROR" "$LOG" | grep -vE "resources still in use at exit" || true)
if ! grep -q "\[autotest\] COMPLETE" "$LOG"; then
	echo "Play-through did NOT complete (see $LOG)"
	exit 1
fi
if [ -n "$ERRORS" ]; then
	echo "Errors found:"
	echo "$ERRORS"
	exit 1
fi
echo "All checks passed. Screenshots: $SHOTS"
