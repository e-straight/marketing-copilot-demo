#!/usr/bin/env bash

set -euo pipefail

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

public_page="docs/index.html"
speaker_page="docs/speaker-notes/index.html"
stylesheet="docs/assets/styles.css"
favicon="docs/assets/images/favicon.svg"

test -f "$public_page" || fail "public setup page is missing"
test -f "$speaker_page" || fail "speaker notes page is missing"
test -f "$stylesheet" || fail "shared stylesheet is missing"
test -f "$favicon" || fail "favicon is missing"
test -f "docs/.nojekyll" || fail ".nojekyll is missing"

for id in download sign-in add-project confirm-workiq ready; do
  grep -q "id=\"$id\"" "$public_page" || fail "public page is missing #$id"
done

grep -q 'https://github.com/github/app/releases' "$public_page" ||
  fail "public page is missing the official app download link"
grep -q 'https://github.com/e-straight/marketing-copilot-demo' "$public_page" ||
  fail "public page is missing the workshop repository link"
grep -q 'assets/styles.css' "$public_page" ||
  fail "public page does not load the shared stylesheet"
grep -q 'assets/images/favicon.svg' "$public_page" ||
  fail "public page does not link the favicon"

grep -q 'name="robots" content="noindex, nofollow"' "$speaker_page" ||
  fail "speaker notes do not opt out of indexing"
grep -q '../assets/styles.css' "$speaker_page" ||
  fail "speaker notes do not load the shared stylesheet"
grep -q '../assets/images/favicon.svg' "$speaker_page" ||
  fail "speaker notes do not link the favicon"

for id in projects sessions canvas workiq customize permissions; do
  grep -q "id=\"$id\"" "$speaker_page" || fail "speaker notes are missing #$id"
done

if grep -Eqi 'speaker-notes|speaker notes' "$public_page"; then
  fail "public page exposes the speaker notes"
fi

if grep -Eqi '<script([[:space:]>])' "$public_page" "$speaker_page"; then
  fail "core pages must not depend on JavaScript"
fi

grep -q ':focus-visible' "$stylesheet" ||
  fail "stylesheet is missing visible keyboard focus"
grep -q -- '--focus-ring: #24113d' "$stylesheet" ||
  fail "stylesheet is missing the high-contrast focus color"
grep -q 'box-shadow: 0 0 0 6px var(--focus-ring)' "$stylesheet" ||
  fail "stylesheet is missing the two-color focus ring"
grep -q '@media (max-width: 760px)' "$stylesheet" ||
  fail "stylesheet is missing the mobile breakpoint"
grep -q 'prefers-reduced-motion' "$stylesheet" ||
  fail "stylesheet is missing reduced-motion handling"
grep -q 'font-size: clamp(2.6rem, 8vw, 5.6rem)' "$stylesheet" ||
  fail "public hero typography has not been restored"
grep -q 'font-size: clamp(2.35rem, 6vw, 4.6rem)' "$stylesheet" ||
  fail "speaker hero typography has not been restored"
grep -q 'font-size: clamp(1.8rem, 4vw, 2.7rem)' "$stylesheet" ||
  fail "section heading typography has not been restored"
grep -q 'line-height: 1.5' "$stylesheet" ||
  fail "body line height has not been tightened"
grep -q 'padding: 1.75rem 0 3.25rem' "$stylesheet" ||
  fail "header spacing has not been tightened"
grep -q 'padding: 3rem 0' "$stylesheet" ||
  fail "setup step spacing has not been tightened"
grep -q 'min-height: 220px' "$stylesheet" ||
  fail "callout height has not been tightened"
grep -q 'margin: 3rem 0' "$stylesheet" ||
  fail "readiness spacing has not been tightened"
grep -q 'padding: 2rem 0 4rem' "$stylesheet" ||
  fail "speaker shell spacing has not been tightened"
grep -q 'padding: 1.75rem 0' "$stylesheet" ||
  fail "speaker feature spacing has not been tightened"
grep -q 'min-height: 48px' "$stylesheet" ||
  fail "button touch targets have been reduced"

printf 'PASS: static site structure and content checks\n'
