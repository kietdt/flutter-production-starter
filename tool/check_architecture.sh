#!/usr/bin/env bash
# Architecture guard — run from the repo root; CI runs it before `flutter analyze`.
#
# Enforces the layer table in `.cursor/rules/layer-dependencies.mdc` (#10) and
# the project rules that no analyzer lint can express (#15).
# Relies on package imports (lint `always_use_package_imports`), so every
# cross-layer import is a greppable `package:flutter_production_starter/<layer>/`.

set -uo pipefail

PKG='package:flutter_production_starter'
status=0

# report <message> <hits> — prints the offending lines and marks the run failed.
report() {
  if [ -n "$2" ]; then
    echo "✗ $1"
    echo "$2" | sed 's/^/    /'
    status=1
  fi
}

# imports <paths...> — every `import '<PKG>/...` line as file:line:import.
imports() {
  grep -rnE "^import '$PKG/" "$@" 2>/dev/null || true
}

# --- Layer dependencies (#10) -------------------------------------------------

report "core must not import data/domain/feature/app" \
  "$(imports lib/core | grep -E "'$PKG/(data|domain|feature|app)/")"

report "domain may only import domain + core/error|core/utils" \
  "$(imports lib/domain | grep -E "'$PKG/(data|feature|app)/|'$PKG/core/" |
    grep -vE "'$PKG/core/(error|utils)/")"

report "data must not import feature/app" \
  "$(imports lib/data | grep -E "'$PKG/(feature|app)/")"

report "feature must not import data (only feature/<x>/di/ may)" \
  "$(imports lib/feature | grep -E "'$PKG/data/" |
    grep -vE '^lib/feature/[^/]+/di/')"

report "feature may only import app/coordinator, app/auth, and app/di from *_page.dart" \
  "$(imports lib/feature | grep -E "'$PKG/app/" |
    grep -vE "'$PKG/app/(coordinator|auth)/" |
    grep -vE "^lib/feature/[^:]+_page\.dart:[0-9]+:import '$PKG/app/di/")"

for dir in lib/feature/*/; do
  name=$(basename "$dir")
  report "feature/$name must not import another feature (navigate via Coordinator)" \
    "$(imports "$dir" | grep -E "'$PKG/feature/" | grep -vE "'$PKG/feature/$name/")"
done

report "main*.dart may only import app/bootstrap.dart + core/config" \
  "$(grep -nE "^import '$PKG/" lib/main*.dart |
    grep -vE "'$PKG/(app/bootstrap|core/config/app_config)\.dart'")"

# --- Project rules lints can't express (#15) ----------------------------------

# code <pattern> <paths...> — matching lines, minus `//` comment lines.
code() {
  local pattern=$1
  shift
  { grep -rnE "$pattern" "$@" 2>/dev/null || true; } |
    grep -vE '^[^:]+:[0-9]+:[[:space:]]*//'
}

report "Navigator/MaterialPageRoute only inside app/coordinator (navigation-coordinator)" \
  "$(code 'Navigator\.|MaterialPageRoute' lib | grep -v '^lib/app/coordinator/')"

report "use Gap(...) for spacing, not a child-less SizedBox (use-gap-not-sizedbox)" \
  "$(code 'SizedBox\((height|width): [^,()]+\)' lib)"

report "log through AppLogger, not dart:developer (custom-logging)" \
  "$(code "import 'dart:developer'" lib | grep -v '^lib/core/utils/app_logger\.dart:')"

report "compare FeatureStatus via its getters, e.g. status.isLoading (feature-status)" \
  "$(code '[!=]= FeatureStatus\.' lib | grep -v '^lib/core/utils/feature_status\.dart:')"

report "parse JSON through MapParser, not json['key'] (map-parser-json)" \
  "$(code "json\[['\"]" lib/data)"

if [ "$status" -eq 0 ]; then
  echo "✓ architecture checks passed"
fi
exit "$status"
