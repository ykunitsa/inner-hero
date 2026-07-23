#!/usr/bin/env bash
#
# Fast unit-test run. ~11s instead of the ~90s a plain `xcodebuild test` costs —
# see CLAUDE.md § "Running tests fast" for where the difference comes from.
#
# Usage:
#   ./scripts/test.sh                    # unit tests
#   ./scripts/test.sh --ui               # UI tests too (slow: +310s)
#   ./scripts/test.sh -q                 # only the summary line
#   ./scripts/test.sh Today              # only suites matching a filter
#
set -uo pipefail

PROJECT="Inner Hero.xcodeproj"
SCHEME="Inner Hero"
SIMULATOR="${INNER_HERO_SIM:-iPhone 17 Pro}"
DESTINATION="platform=iOS Simulator,name=$SIMULATOR"

cd "$(dirname "$0")/.." || exit 1

TARGET="Inner HeroTests"
QUIET=0
FILTER=""

while [ $# -gt 0 ]; do
    case "$1" in
        --ui) TARGET="" ;;
        -q|--quiet) QUIET=1 ;;
        -h|--help) sed -n '3,12p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
        *) FILTER="$1" ;;
    esac
    shift
done

# A filter narrows to one suite/class inside the unit bundle.
if [ -n "$FILTER" ] && [ -n "$TARGET" ]; then
    TARGET="Inner HeroTests/$FILTER"
fi

only_testing=()
[ -n "$TARGET" ] && only_testing=(-only-testing "$TARGET")

# Boot once and leave it up; a cold boot is otherwise paid on every run.
xcrun simctl boot "$SIMULATOR" 2>/dev/null || true

build_log=$(mktemp)
if ! xcodebuild -project "$PROJECT" -scheme "$SCHEME" -destination "$DESTINATION" \
        "${only_testing[@]}" build-for-testing >"$build_log" 2>&1; then
    echo "BUILD FAILED"
    grep -E "error:" "$build_log" | sort -u | head -20
    rm -f "$build_log"
    exit 1
fi
rm -f "$build_log"

# -parallel-testing-enabled NO: Xcode otherwise clones the simulator, which costs
# far more than a suite that executes in 0.1s.
#
# -testLanguage ru: some tests read localized strings, and one of them
# (PMRVoiceStressTests, "every override actually occurs in a spoken line") only
# means anything in Russian — the stress dictionary is for the Russian voice.
# Without pinning, the suite inherits whatever language the simulator happens to
# be in, and reinstalling the app is enough to flip it. Same discipline as the
# pinned calendar and time zone inside the tests themselves.
run_log=$(mktemp)
xcodebuild -project "$PROJECT" -scheme "$SCHEME" -destination "$DESTINATION" \
    "${only_testing[@]}" -parallel-testing-enabled NO -testLanguage ru \
    test-without-building >"$run_log" 2>&1
status=$?

# Detail lines, minus the run-level summary (echoed separately below) and the
# per-suite rollups, which only restate their tests.
if [ "$QUIET" -eq 0 ]; then
    grep -E '^✘ (Test|Suite) ' "$run_log" \
        | grep -vE '^✘ (Test run with|Suite )' \
        | sort -u | head -30
    grep -E "error:" "$run_log" | sort -u | head -10
fi

# Swift Testing prints its own summary; the legacy "Executed 0 tests" line is XCTest's
# and means nothing here.
summary=$(grep -E "Test run with .* (passed|failed)" "$run_log" | tail -1)
[ -n "$summary" ] && echo "${summary#* }"

if [ "$status" -ne 0 ]; then
    # One line per distinct failing test, not per ✘ line (a failure emits several).
    failures=$(grep -E '^✘ Test "' "$run_log" | grep -c 'failed after')
    echo "FAILED ($failures failing) — full log: $run_log"
    exit 1
fi

rm -f "$run_log"
echo "OK"
