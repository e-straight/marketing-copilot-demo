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
  notes-context \
  notes-automate \
  notes-verify \
  notes-compare \
  notes-close; do
  grep -q "id=\"$id\"" "$public_page" || fail "speaker notes are missing #$id"
done

notes_step_count="$(grep -c '<li class="notes-step"' "$public_page")"
test "$notes_step_count" = "10" ||
  fail "speaker notes should contain exactly ten steps"
actual_notes_sequence="$(grep '<li class="notes-step"' "$public_page" |
  sed -E 's/.*id="([^"]+)".*/\1/' |
  paste -sd ' ' -)"
expected_notes_sequence='notes-scenario notes-tracker notes-install notes-orient notes-project notes-context notes-automate notes-verify notes-compare notes-close'
test "$actual_notes_sequence" = "$expected_notes_sequence" ||
  fail "speaker notes steps are missing, duplicated, or out of order"

for step in \
  'notes-scenario:1' \
  'notes-tracker:2' \
  'notes-install:3' \
  'notes-orient:4' \
  'notes-project:5' \
  'notes-context:6' \
  'notes-automate:7' \
  'notes-verify:8' \
  'notes-compare:9' \
  'notes-close:10'; do
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
  'Project context already contains the permitted source results' \
  'validate and enrich the running tracker' \
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
test "$prompt_count" = "6" ||
  fail "speaker notes should retain exactly six concrete Suggested prompt blocks"
grep -Fq 'Create a canvas named BRK 999 tracker from these results. Use columns for work item, owner, status, location or source, next action, and last updated. Keep source links. Use Needs confirmation when the evidence is incomplete. Use the impeccable design plugin to make this happen and keep it as simple as possible.' "$public_page" ||
  fail "tracker Suggested prompt does not use the requested canvas and impeccable plugin wording"
grep -Fq 'Check my permitted BRK 999 Teams context for new messages about items already in the BRK 999 tracker artifact. Update owner, status, next action, source, and last updated only when the message is explicit. Put conflicts or missing details in Needs confirmation. Preserve the source link for every change.' "$public_page" ||
  fail "automation Suggested prompt does not match the requested wording"

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
  'live connection to an external tool or data source' \
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
  printf '%s\n' "$speaker_orientation_html" | grep -Fqi "$phrase" ||
    fail "app orientation explainer is missing: $phrase"
done

printf '%s\n' "$speaker_orientation_html" | grep -Fq 'https://msit.powerbi.com/groups/me/apps/8be2db21-d297-485b-a01b-6a03fbf6fbd1/reports/6ddd79d1-b24c-42dc-bf9a-b4877eba032d/personalv2phase1page?ctid=72f988bf-86f1-41af-91ab-2d7cd011db47&amp;experience=power-bi' ||
  fail "AI credits guidance is missing the exact Personal Usage V2 link"
if grep -Eqi 'pooled|pooling|roll[ -]?over|monthly|resets? on the (1st|first)|pool resets' "$public_page"; then
  fail "speaker notes should not mention pooled or monthly credit behavior"
fi

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
printf '%s\n' "$speaker_orientation_html" | grep -q 'https://docs.github.com/en/copilot/concepts/models/auto-model-selection' ||
  fail "model selection notes are missing the official Auto documentation"
printf '%s\n' "$speaker_orientation_html" | grep -q 'https://docs.github.com/en/copilot/concepts/models/copilot-fusion' ||
  fail "model selection notes are missing the official Copilot Fusion documentation"
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
