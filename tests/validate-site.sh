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

for id in setup download sign-in confirm-workiq ready speaker-notes compare-apps; do
  grep -q "id=\"$id\"" "$public_page" || fail "public page is missing #$id"
done

if grep -Fqi 'Add the workshop project' "$public_page" ||
  grep -q 'id="add-project"' "$public_page" ||
  grep -Fqi 'Start a session in the workshop project' "$public_page" ||
  grep -Fqi 'The workshop project appears under Projects' "$public_page"; then
  fail "Setup should not include the workshop project step or orphaned helper copy"
fi
grep -Fq 'You are ready when all three are true.' "$public_page" ||
  fail "Setup readiness count should reflect the three remaining checks"
setup_step_count="$(grep -c '<li class="setup-step"' "$public_page")"
test "$setup_step_count" = "3" ||
  fail "Setup should contain exactly three steps"
setup_step_numbers="$(grep 'class="step-number"' "$public_page" |
  sed -E 's/.*>([0-9]+)<.*/\1/' |
  paste -sd ' ' -)"
test "$setup_step_numbers" = "1 2 3" ||
  fail "Setup steps should be numbered 1 through 3"

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
  notes-tracker \
  notes-install \
  notes-orient \
  notes-project \
  notes-automate \
  notes-verify \
  notes-compare \
  notes-close; do
  grep -q "id=\"$id\"" "$public_page" || fail "speaker notes are missing #$id"
done

notes_step_count="$(grep -c '<li class="notes-step"' "$public_page")"
test "$notes_step_count" = "9" ||
  fail "speaker notes should contain exactly nine steps"
actual_notes_sequence="$(grep '<li class="notes-step"' "$public_page" |
  sed -E 's/.*id="([^"]+)".*/\1/' |
  paste -sd ' ' -)"
expected_notes_sequence='notes-scenario notes-tracker notes-install notes-orient notes-project notes-automate notes-verify notes-compare notes-close'
test "$actual_notes_sequence" = "$expected_notes_sequence" ||
  fail "speaker notes steps are missing, duplicated, or out of order"

for step in \
  'notes-scenario:1' \
  'notes-tracker:2' \
  'notes-install:3' \
  'notes-orient:4' \
  'notes-project:5' \
  'notes-automate:6' \
  'notes-verify:7' \
  'notes-compare:8' \
  'notes-close:9'; do
  step_id="${step%%:*}"
  expected_number="${step##*:}"
  actual_number="$(sed -n "/id=\"$step_id\"/,/<\\/li>/p" "$public_page" |
    grep -m1 'class="notes-number"' |
    sed -E 's/.*>([0-9]+)<.*/\1/')"
  test "$actual_number" = "$expected_number" ||
    fail "#$step_id should be numbered step $expected_number"
done

for phrase in \
  'Timing' \
  'Demo actions' \
  'Suggested prompt' \
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
  '10 minutes' \
  'Create and run' \
  'play button' \
  'focused session' \
  'continue speaking instead of waiting' \
  'GitHub Copilot app' \
  'Microsoft Copilot app'; do
  grep -Fqi "$phrase" "$public_page" || fail "speaker notes are missing: $phrase"
done

if grep -Fqi 'Expected result' "$public_page"; then
  fail "speaker notes should not include Expected result blocks"
fi
if grep -Eqi 'prompt-inline\">[[:space:]]*No prompt' "$public_page"; then
  fail "speaker notes should not include no-prompt placeholders"
fi
prompt_count="$(grep -c '<h4>Suggested prompt</h4>' "$public_page")"
test "$prompt_count" = "5" ||
  fail "speaker notes should retain exactly five concrete Suggested prompt blocks"
tracker_prompt_html="$(sed -n '/id="notes-tracker"/,/id="notes-install"/p' "$public_page")"
tracker_prompt_text="$(printf '%s\n' "$tracker_prompt_html" |
  sed -E 's/<[^>]+>/ /g; s/&gt;/>/g; s/&amp;/\&/g; s/[[:space:]]+/ /g; s/ ([.,;:])/\1/g')"
tracker_requirement_count="$(printf '%s\n' "$tracker_prompt_html" | grep -c '<li>')"
test "$tracker_requirement_count" = "11" ||
  fail "tracker Suggested prompt should contain exactly eleven requirement bullets"
for phrase in \
  'Create a user-scoped Copilot canvas extension named BRK 999 2.0.' \
  'Work item, Owner, Status, Next action, Last updated' \
  'Do not include location, source, summary, framework, or decisions fields.' \
  'Add editable controls for every field.' \
  'Not started, In progress, Blocked, Done, Needs confirmation.' \
  'Add work item' \
  'remove-row controls' \
  'autosave' \
  'Save changes' \
  'auto-growing multiline textarea that never clips text or creates giant rows' \
  'responsive card layout for narrow screens' \
  'one shared user-level JSON file' \
  'atomic file writes and validate malformed input' \
  'Elijah for GitHub Pages, BRK 999 script, and Workshop canvas' \
  'Ashley for Workshop artifacts and Teams research' \
  'reloading the extension and reopening the active canvas instance after changes' \
  'focused Bun tests for persistence, migration, server endpoints, registration, responsive sizing, save behavior, and injection protection' \
  'verify live that all owners appear, rows remain compact, Next action text is not clipped, and no console errors occur'; do
  printf '%s\n' "$tracker_prompt_text" | grep -Fq "$phrase" ||
    fail "tracker Suggested prompt is missing: $phrase"
done
grep -Fq 'Hey can you set up an automation that runs every 10 mins and checks BRK 999 Demo teams thread and then update the BRK999 tracker?' "$public_page" ||
  fail "automation Suggested prompt does not match the requested wording"
if grep -Fq 'Create a canvas named BRK 999 tracker from these results.' "$public_page"; then
  fail "speaker notes should not include the old one-line tracker prompt"
fi
if grep -Fq 'BRK 1999' "$public_page"; then
  fail "speaker notes should not reference BRK 1999"
fi
if grep -Fq 'Project context already contains the permitted source results' "$public_page" ||
  grep -Fq 'after the WorkIQ context step' "$public_page"; then
  fail "step 2 should not rely on stale source-context or WorkIQ-step language"
fi
if grep -Fq 'Gather context and refine the tracker' "$public_page" ||
  grep -Fq 'Use WorkIQ to find recent messages in my BRK 999 group chat about the slide deck and speaker script.' "$public_page"; then
  fail "speaker notes should not include the removed context-refinement step"
fi

for phrase in \
  'GitHub is like OneDrive for a project' \
  'permanent version history' \
  'shared task trail' \
  'what changed, why it changed, and what should happen next' \
  'Repository:' \
  'Commit:' \
  'Pull request:'; do
  grep -Fqi "$phrase" "$public_page" || fail "GitHub explainer is missing: $phrase"
done

for phrase in \
  'Which Copilot experience should I use?' \
  'Use GitHub Copilot app when...' \
  'Use GitHub Copilot CLI when...' \
  'Use Microsoft Copilot Chat or Cowork when...' \
  'Use Microsoft Copilot Code when...' \
  'More than one can work when...' \
  'keep a project, source files, sessions, and automation together' \
  'install or manage plugins, skills, and MCP connections directly from Customize' \
  'prefer terminal workflows' \
  'current working directory' \
  'scriptable or keyboard-first workflow' \
  'reviewing commands, file changes, and permission requests' \
  'supported skills, plugins, and MCP connections from the command line' \
  'work mostly happens in Microsoft 365' \
  'use or create Microsoft Copilot agents' \
  'availability varies by account, license, and organization settings' \
  'Microsoft 365 Copilot or Copilot Studio' \
  'governed plugins, connectors, actions, skills, or MCP-backed tools' \
  'app, dashboard, automation, website, or script in plain language' \
  'live preview' \
  'optional GitHub repository and pull-request workflows' \
  'publish a small internal app' \
  'Frontier preview; availability, licensing, and features may change' \
  'brainstorm, summarize, research, or draft'; do
  grep -Fqi "$phrase" "$public_page" || fail "app comparison is missing: $phrase"
done

comparison_html="$(sed -n '/id="compare-apps"/,/<\/section>/p' "$public_page")"
comparison_card_count="$(printf '%s\n' "$comparison_html" | grep -c '<article class="comparison-card')"
test "$comparison_card_count" = "4" ||
  fail "comparison should contain exactly four product experience cards"
comparison_bullets="$(printf '%s\n' "$comparison_html" | grep -c '<li>')"
test "$comparison_bullets" -ge 20 ||
  fail "comparison should use at least twenty short bullet points"

github_app_card="$(printf '%s\n' "$comparison_html" | sed -n '/class="comparison-card github-card"/,/<\/article>/p')"
github_cli_card="$(printf '%s\n' "$comparison_html" | sed -n '/class="comparison-card cli-card"/,/<\/article>/p')"
microsoft_card="$(printf '%s\n' "$comparison_html" | sed -n '/class="comparison-card microsoft-card"/,/<\/article>/p')"
code_card="$(printf '%s\n' "$comparison_html" | sed -n '/class="comparison-card code-card"/,/<\/article>/p')"
for card in "$github_app_card" "$github_cli_card" "$microsoft_card" "$code_card"; do
  printf '%s\n' "$card" | grep -q '<h3>' ||
    fail "each comparison card should use a semantic heading"
  printf '%s\n' "$card" | grep -q '<ul>' ||
    fail "each comparison card should present guidance as a list"
done
printf '%s\n' "$github_app_card" | grep -Fq 'Use GitHub Copilot app when...' ||
  fail "GitHub Copilot app guidance is outside its card"
printf '%s\n' "$github_cli_card" | grep -Fq 'Use GitHub Copilot CLI when...' ||
  fail "GitHub Copilot CLI guidance is outside its card"
printf '%s\n' "$microsoft_card" | grep -Fq 'Use Microsoft Copilot Chat or Cowork when...' ||
  fail "Microsoft Copilot Chat and Cowork guidance is outside its card"
printf '%s\n' "$code_card" | grep -Fq 'Use Microsoft Copilot Code when...' ||
  fail "Microsoft Copilot Code guidance is outside its card"
printf '%s\n' "$code_card" | grep -Fq 'share an organization-scoped static app from a cloud project' ||
  fail "Copilot Code static-app sharing should retain the cloud-only qualification"

comparison_grid_html="$(printf '%s\n' "$comparison_html" | sed -n '/<div class="comparison-grid">/,/<\/div>/p')"
if printf '%s\n' "$comparison_grid_html" | grep -q 'class="overlap-note"'; then
  fail "overlap guidance should remain separate from the four product cards"
fi
printf '%s\n' "$comparison_html" | grep -q '<article class="overlap-note">' ||
  fail "comparison is missing separate overlap guidance"

if printf '%s\n' "$comparison_html" | grep -Fqi 'BRK 999'; then
  fail "app comparison should not reference BRK 999"
fi
if printf '%s\n' "$comparison_html" | grep -Eqi 'Microsoft Copilot (does not|doesn.t) support (plugins|skills|MCP)'; then
  fail "app comparison should not make an absolute Microsoft Copilot extensibility claim"
fi

for phrase in \
  'Projects:' \
  'Sessions:' \
  'Customize:' \
  'Automations:' \
  'Artifacts and canvases:' \
  'Dashboards:' \
  'view or edit one specific output' \
  'scan several workstreams, sessions, or statuses' \
  'quick, standalone question or draft' \
  'setup, source context, tracker artifact, automation, and later updates'; do
  grep -Fqi "$phrase" "$public_page" || fail "app orientation is missing: $phrase"
done

speaker_orientation_html="$(sed -n '/id="notes-orient"/,/id="notes-project"/p' "$public_page")"
for phrase in \
  'A repo is where Copilot performs coding work' \
  'a Project is the persistent coordinator for a larger outcome' \
  'Microsoft Ignite readiness' \
  'isolated checkout of that specific repository' \
  'does not contain or replace the repos' \
  'multiple repositories' \
  'Plugin:' \
  'installable bundle' \
  'Skill:' \
  'reusable recipe' \
  'MCP server:' \
  'live connection to an external tool or data source'; do
  printf '%s\n' "$speaker_orientation_html" | grep -Fqi "$phrase" ||
    fail "app orientation explainer is missing: $phrase"
done

for heading in 'AI credits' 'Model selection and switching'; do
  heading_count="$(grep -Foc "<h4>$heading</h4>" "$public_page")"
  test "$heading_count" = "1" ||
    fail "$heading should occur exactly once"
  if printf '%s\n' "$speaker_orientation_html" | grep -Fq "$heading"; then
    fail "$heading should not remain in App orientation"
  fi
done

speaker_final_reference_html="$(sed -n '/id="speaker-final-reference"/,/<\/section>/p' "$public_page")"
for phrase in \
  'AI credits' \
  'Credits work like a phone data plan' \
  'more powerful models generally use more' \
  'Credit usage varies by model and task complexity' \
  'Simple requests typically use fewer credits than complex tasks' \
  'Personal Usage V2' \
  'Model selection' \
  'Click the model name below the prompt box' \
  'switch models at any point during a session' \
  'Start with Copilot Fusion when it is available' \
  'Standard for everyday work' \
  'High for challenging work' \
  'Max for the most demanding tasks' \
  'Each model is billed at its normal rate' \
  'Paid plans currently receive a limited-time 30% discount on model costs with Fusion' \
  'Start with Fusion Standard' \
  'switch back to Standard' \
  'If the picker shows Auto instead, use Auto for general work' \
  'Efficiency, Balance, and Intelligence' \
  'Choose a specific model' \
  'surface, plan, rollout, and organization model policies'; do
  printf '%s\n' "$speaker_final_reference_html" | grep -Fqi "$phrase" ||
    fail "final speaker reference is missing: $phrase"
  if printf '%s\n' "$speaker_orientation_html" | grep -Fqi "$phrase"; then
    fail "moved final-reference content should not remain in App orientation: $phrase"
  fi
done

printf '%s\n' "$speaker_final_reference_html" | grep -Fq 'https://msit.powerbi.com/groups/me/apps/8be2db21-d297-485b-a01b-6a03fbf6fbd1/reports/6ddd79d1-b24c-42dc-bf9a-b4877eba032d/personalv2phase1page?ctid=72f988bf-86f1-41af-91ab-2d7cd011db47&amp;experience=power-bi' ||
  fail "AI credits guidance is missing the exact Personal Usage V2 link"
if grep -Eqi 'pooled|pooling|roll[ -]?over|monthly|resets? on the (1st|first)|pool resets' "$public_page"; then
  fail "speaker notes should not mention pooled or monthly credit behavior"
fi

notes_close_line="$(grep -n 'id="notes-close"' "$public_page" | head -1 | cut -d: -f1)"
notes_flow_close_line="$(grep -n '</ol>' "$public_page" |
  awk -F: -v start="$notes_close_line" '$1 > start { print $1; exit }')"
final_reference_line="$(grep -n 'id="speaker-final-reference"' "$public_page" | head -1 | cut -d: -f1)"
speaker_panel_close_line="$(grep -n '<section class="tab-panel compare-panel"' "$public_page" |
  head -1 |
  cut -d: -f1)"
test -n "$final_reference_line" &&
  test "$notes_close_line" -lt "$notes_flow_close_line" &&
  test "$notes_flow_close_line" -lt "$final_reference_line" &&
  test "$final_reference_line" -lt "$speaker_panel_close_line" ||
  fail "final speaker reference should appear after notes-close"

orientation_bullets="$(printf '%s\n' "$speaker_orientation_html" | grep -c '<li>')"
test "$orientation_bullets" = "6" ||
  fail "app orientation should contain exactly six bullets"

grep -q 'https://github.com/features/copilot' "$public_page" ||
  fail "setup is missing the official app download link"
grep -q 'https://docs.github.com/en/copilot/get-started/quickstart-copilot-app' "$public_page" ||
  fail "speaker notes are missing the official app quickstart"
printf '%s\n' "$speaker_orientation_html" | grep -q 'https://docs.github.com/en/copilot/concepts/customizations/plugins' ||
  fail "page is missing the official GitHub Copilot plugins documentation"
printf '%s\n' "$speaker_orientation_html" | grep -q 'https://docs.github.com/en/copilot/concepts/customizations/agent-skills' ||
  fail "page is missing the official GitHub Copilot skills documentation"
grep -q 'https://www.microsoft.com/en-us/copilot/download-copilot-app' "$public_page" ||
  fail "speaker notes are missing the Microsoft Copilot app link"
printf '%s\n' "$comparison_html" | grep -q 'https://support.microsoft.com/en-us/microsoft-365-copilot/get-started-with-agents-in-the-microsoft-365-copilot-app' ||
  fail "page is missing the official Microsoft Copilot agents documentation"
printf '%s\n' "$comparison_html" | grep -q 'https://learn.microsoft.com/en-us/microsoft-copilot-studio/mcp-add-existing-server-to-agent' ||
  fail "page is missing the official Copilot Studio MCP documentation"
printf '%s\n' "$comparison_html" | grep -q 'https://learn.microsoft.com/en-us/microsoft-agent-365/admin/manage-plugins-skills-mcp-servers' ||
  fail "page is missing the official Microsoft 365 extensibility governance documentation"
printf '%s\n' "$comparison_html" | grep -q 'https://learn.microsoft.com/en-us/microsoft-365/copilot/extensibility/overview-copilot-connector' ||
  fail "page is missing the official Microsoft 365 Copilot connectors documentation"
printf '%s\n' "$comparison_html" | grep -q 'https://docs.github.com/en/copilot/get-started/cli-quickstart' ||
  fail "comparison is missing the official GitHub Copilot CLI quickstart"
printf '%s\n' "$comparison_html" | grep -q 'https://learn.microsoft.com/en-us/copilot/code/overview' ||
  fail "comparison is missing the official Microsoft Copilot Code overview"
printf '%s\n' "$comparison_html" | grep -q 'https://support.microsoft.com/en-us/microsoft-365-copilot/get-started-with-microsoft-365-copilot-chat' ||
  fail "comparison is missing official Microsoft 365 Copilot Chat documentation"
printf '%s\n' "$comparison_html" | grep -q 'https://support.microsoft.com/en-us/microsoft-365-copilot/get-started-with-cowork' ||
  fail "comparison is missing official Microsoft Copilot Cowork documentation"
printf '%s\n' "$speaker_final_reference_html" | grep -q 'https://docs.github.com/en/copilot/concepts/models/auto-model-selection' ||
  fail "model selection notes are missing the official Auto documentation"
printf '%s\n' "$speaker_final_reference_html" | grep -q 'https://docs.github.com/en/copilot/concepts/models/copilot-fusion' ||
  fail "model selection notes are missing the official Copilot Fusion documentation"
if printf '%s\n' "$speaker_orientation_html" | grep -Eq 'auto-model-selection|copilot-fusion'; then
  fail "model source links should not remain in App orientation"
fi
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
reveal_line="$(grep -n '^  revealHashTarget();' "$tabs_script" | head -1 | cut -d: -f1)"
enhanced_line="$(grep -n 'document.documentElement.classList.add("tabs-enhanced")' "$tabs_script" | head -1 | cut -d: -f1)"
test "$reveal_line" -lt "$enhanced_line" ||
  fail "tabs must set hidden panel state before enabling enhanced display styles"
grep -q '.tabs-enhanced .tab-panel:not(\[hidden\])' "$stylesheet" ||
  fail "enhanced tabs do not show the selected non-hidden panel"
grep -q '.tabs-enhanced #setup\[hidden\]' "$stylesheet" ||
  fail "enhanced tabs do not override the default Setup panel when it is hidden"
grep -q 'body:has(.tab-panel:not(#setup):target) #setup' "$stylesheet" ||
  fail "the default Setup panel must not hide itself when #setup is targeted"
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
grep -q '.cli-card' "$stylesheet" ||
  fail "stylesheet is missing GitHub Copilot CLI card styling"
grep -q '.code-card' "$stylesheet" ||
  fail "stylesheet is missing Microsoft Copilot Code card styling"
comparison_grid_css="$(sed -n '/^\.comparison-grid {/,/^}/p' "$stylesheet")"
printf '%s\n' "$comparison_grid_css" | grep -q 'grid-template-columns: repeat(2, minmax(0, 1fr));' ||
  fail "comparison cards should use two columns on desktop and tablet"
mobile_css="$(sed -n '/^@media (max-width: 760px)/,$p' "$stylesheet")"
printf '%s\n' "$mobile_css" | sed -n '/\.comparison-grid/,/}/p' | grep -q 'grid-template-columns: 1fr;' ||
  fail "comparison cards should use one column on mobile"
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
