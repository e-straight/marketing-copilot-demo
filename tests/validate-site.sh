#!/usr/bin/env bash

set -euo pipefail

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

public_page="docs/index.html"
speaker_page="docs/speaker-notes/index.html"
stylesheet="docs/assets/styles.css"
tabs_script="docs/assets/tabs.js"
favicon="docs/assets/images/favicon.svg"

test -f "$public_page" || fail "public workshop page is missing"
test -f "$speaker_page" || fail "direct speaker page is missing"
test -f "$stylesheet" || fail "shared stylesheet is missing"
test -f "$tabs_script" || fail "tabs script is missing"
test -f "$favicon" || fail "favicon is missing"
test -f "docs/.nojekyll" || fail ".nojekyll is missing"

for id in setup download sign-in add-project confirm-workiq ready speaker-notes compare-apps; do
  grep -q "id=\"$id\"" "$public_page" || fail "public page is missing #$id"
done

tab_count="$(grep -o 'class="tab"' "$public_page" | wc -l | tr -d ' ')"
test "$tab_count" = "3" || fail "public page should expose exactly Setup, Speaker notes, and Compare apps tabs"
grep -q 'href="#setup"' "$public_page" || fail "public page is missing the Setup tab"
grep -q 'href="#speaker-notes"' "$public_page" || fail "public page is missing the Speaker notes tab"
grep -q 'href="#compare-apps"' "$public_page" || fail "public page is missing the Compare apps tab"
grep -q '>Speaker notes<' "$public_page" || fail "Speaker notes tab is not clearly labeled"
grep -q '>Compare apps<' "$public_page" || fail "Compare apps tab is not clearly labeled"
setup_line="$(grep -n 'href="#setup"' "$public_page" | head -1 | cut -d: -f1)"
compare_line="$(grep -n 'href="#compare-apps"' "$public_page" | head -1 | cut -d: -f1)"
speaker_line="$(grep -n 'href="#speaker-notes"' "$public_page" | head -1 | cut -d: -f1)"
test "$setup_line" -lt "$compare_line" && test "$compare_line" -lt "$speaker_line" ||
  fail "tab order must be Setup, Compare apps, Speaker notes"

if grep -q 'tabindex="-1"' "$public_page"; then
  fail "static tab links must remain keyboard focusable before JavaScript loads"
fi

for id in \
  notes-scenario \
  notes-install \
  notes-orient \
  notes-project \
  notes-context \
  notes-tracker \
  notes-automate \
  notes-verify \
  notes-compare \
  notes-close; do
  grep -q "id=\"$id\"" "$public_page" || fail "speaker notes are missing #$id"
done

for phrase in \
  'Timing' \
  'Demo actions' \
  'Suggested prompt' \
  'Expected result' \
  'Handoff' \
  'Fallback' \
  'BRK 999 group chat' \
  'participants use their own chat' \
  'slide deck' \
  'Ashley' \
  'workflow tracker' \
  'scheduled check' \
  'Create manually' \
  'BRK 999 tracker check' \
  '15 minutes' \
  'Create and run' \
  'play button' \
  'GitHub Copilot app' \
  'Microsoft Copilot app'; do
  grep -Fqi "$phrase" "$public_page" || fail "speaker notes are missing: $phrase"
done

for phrase in \
  'durable project context' \
  'everyday personal productivity' \
  'may be interchangeable' \
  'permitted Microsoft 365 context'; do
  grep -Fqi "$phrase" "$public_page" || fail "app comparison is missing: $phrase"
done

grep -q 'https://github.com/github/app/releases' "$public_page" ||
  fail "setup is missing the official app download link"
grep -q 'https://github.com/e-straight/marketing-copilot-demo' "$public_page" ||
  fail "setup is missing the workshop repository link"
grep -q 'https://docs.github.com/en/copilot/get-started/quickstart-copilot-app' "$public_page" ||
  fail "speaker notes are missing the official app quickstart"
grep -q 'https://www.microsoft.com/en-us/copilot/download-copilot-app' "$public_page" ||
  fail "speaker notes are missing the Microsoft Copilot app link"
grep -q 'assets/styles.css' "$public_page" ||
  fail "public page does not load the shared stylesheet"
grep -q 'assets/tabs.js' "$public_page" ||
  fail "public page does not load the tabs script"
grep -q 'assets/images/favicon.svg' "$public_page" ||
  fail "public page does not link the favicon"

grep -q 'name="robots" content="noindex, nofollow"' "$speaker_page" ||
  fail "direct speaker page does not opt out of indexing"
grep -q '../assets/styles.css' "$speaker_page" ||
  fail "direct speaker page does not load the shared stylesheet"

grep -q 'document.documentElement.classList.add("tabs-enhanced")' "$tabs_script" ||
  fail "tabs do not use progressive enhancement"
grep -q 'ArrowRight' "$tabs_script" ||
  fail "tabs are missing keyboard navigation"
grep -q 'closest(".tab-panel")' "$tabs_script" ||
  fail "tabs do not reveal panels for child deep links"
grep -q 'setAttribute("role", "tab")' "$tabs_script" ||
  fail "tab semantics are not added during enhancement"

grep -q ':focus-visible' "$stylesheet" ||
  fail "stylesheet is missing visible keyboard focus"
grep -q -- '--focus-ring: #24113d' "$stylesheet" ||
  fail "stylesheet is missing the high-contrast focus color"
grep -q '@media (max-width: 760px)' "$stylesheet" ||
  fail "stylesheet is missing the mobile breakpoint"
grep -q 'prefers-reduced-motion' "$stylesheet" ||
  fail "stylesheet is missing reduced-motion handling"
grep -q '.workshop-tabs' "$stylesheet" ||
  fail "stylesheet is missing tab navigation"
grep -q '.notes-step' "$stylesheet" ||
  fail "stylesheet is missing speaker-note step styling"
grep -q 'font-size: clamp(2.6rem, 8vw, 5.6rem)' "$stylesheet" ||
  fail "original setup hero typography was not preserved"
grep -q 'padding: 3rem 0' "$stylesheet" ||
  fail "original setup step spacing was not preserved"
grep -q 'min-height: 220px' "$stylesheet" ||
  fail "original setup callout treatment was not preserved"

grep -q 'https://e-straight.github.io/marketing-copilot-demo/' README.md ||
  fail "README is missing the GitHub Pages link"
grep -q 'WORKSHOP-AGENDA.md' README.md ||
  fail "README no longer links the workshop agenda"
grep -q 'python3 -m http.server 8000 --directory docs' README.md ||
  fail "README no longer preserves the local preview instructions"

printf 'PASS: setup guide and linear speaker notes checks\n'
