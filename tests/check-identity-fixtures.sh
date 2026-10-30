#!/usr/bin/env bash
# SPDX-License-Identifier: MPL-2.0
# SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>
#
# check-identity-fixtures.sh — self-test for the mechanical identity checker.
#
# tests/check-identity.sh is the half of the gate that reads the tree. A checker
# that only ever reports PASS on the real repository proves nothing: it could be
# vacuous, or it could be failing open on every section. So it is run against
# deliberately broken trees, each broken in exactly one way, and each must be
# REJECTED. One control tree is deliberately consistent and must be ACCEPTED —
# otherwise "everything fails" would look like success.
#
# The fixture trees are built here rather than committed, for two reasons: every
# case is visible in one reviewable file, and a fixture cannot drift out of step
# with the checker it exercises. They are built in a temporary directory and
# removed afterwards; nothing is written into the repository.
#
# The canonical identity module in the consistent fixture is produced by the real
# generator (scripts/gen-identity-agda.sh --mode canonical), so this self-test
# also exercises the transcriber against a second Project.toml.
set -uo pipefail
cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.."

# name|sections|expected-exit|builder
#   sections: comma-separated list, or ALL for the whole checker
cases=(
  "consistent|ALL|0|build_consistent"
  "repo-name-mismatch|reconciled|1|build_repo_name_mismatch"
  "module-name-mismatch|module-decl|1|build_module_name_mismatch"
  "missing-src-file|src-file|1|build_missing_src_file"
  "hyphenated-package-name|project-name,identifier|1|build_hyphenated_package_name"
  "digit-leading-package-name|identifier|1|build_digit_leading_package_name"
  "missing-using|tests-using|1|build_missing_using"
  "readme-omits-package|readme-names|1|build_readme_omits_package"
  "readme-example-drift|readme-example|1|build_readme_example_drift"
  "missing-example|readme-example|1|build_missing_example"
  "stale-self-url|internal-urls|1|build_stale_self_url"
  "no-self-url|internal-urls|1|build_no_self_url"
  "retired-name-reintroduced|retired-names|1|build_retired_name_reintroduced"
  "retired-register-missing|retired-names|1|build_retired_register_missing"
  "decided-identity-drift|decided-identity|1|build_decided_identity_drift"
  # One rejected case per spelling family of the retired name (OldThing.jl here).
  # Each family is a real way the tree carried a retired repository name (see the
  # spelling notes in docs/naming/retired-names.txt). A rule nobody has seen fail
  # is not trusted.
  "spelling-hyphen-camel|retired-names|1|build_spelling_hyphen_camel"
  "spelling-spaced-title|retired-names|1|build_spelling_spaced_title"
  "spelling-lowercase-hyphen|retired-names|1|build_spelling_lowercase_hyphen"
  "spelling-underscore|retired-names|1|build_spelling_underscore"
  "spelling-upper-case|retired-names|1|build_spelling_upper_case"
  "spelling-no-suffix|retired-names|1|build_spelling_no_suffix"
  "spelling-no-separators|retired-names|1|build_spelling_no_separators"
  "spelling-wrapped-line|retired-names|1|build_spelling_wrapped_line"
  # A deliberately consistent tree that uses the words of the retired name in
  # legitimate senses. Must be ACCEPTED, or the rule is too broad.
  "legitimate-concept-mentions|retired-names|0|build_legitimate_mentions"
)

PKG="MyThing"
REPO="MyThing.jl"
RETIRED="OldThing.jl"

# A consistent tree: every section of the checker passes on it.
build_consistent() {
  local d="$1"
  mkdir -p "$d/src" "$d/test" "$d/examples" "$d/docs/naming" "$d/proofs/agda"

  cat >"$d/Project.toml" <<TOML
name = "$PKG"
uuid = "00000000-0000-0000-0000-000000000000"
version = "0.1.0"

[deps]
TOML

  cat >"$d/src/${PKG}.jl" <<JL
# SPDX-License-Identifier: MPL-2.0
module ${PKG}

greeting() = "hello"

end # module ${PKG}
JL

  cat >"$d/test/runtests.jl" <<JL
using ${PKG}
using Test

@testset "${PKG}" begin
    @test ${PKG}.greeting() == "hello"
end
JL

  cat >"$d/examples/quickstart.jl" <<JL
# SPDX-License-Identifier: MPL-2.0
using ${PKG}

${PKG}.greeting()
JL

  cat >"$d/README.adoc" <<ADOC
= ${PKG}.jl

Clone with:

    git clone https://github.com/hyperpolymath/${REPO}

== Quick start

[source,julia]
----
$(awk 'BEGIN { skip = 1 } skip && /^#/ { next } skip && /^[[:space:]]*$/ { next } { skip = 0; print }' "$d/examples/quickstart.jl")
----
ADOC

  cat >"$d/docs/naming/retired-names.txt" <<TXT
# Retired names for the fixture repository.
${RETIRED}
TXT

  cat >"$d/docs/naming/retired-names-allowlist.txt" <<TXT
# The register and the allowlist may name a retired name; nothing else may.
docs/naming/retired-names.txt
docs/naming/retired-names-allowlist.txt
TXT

  bash scripts/gen-identity-agda.sh --mode canonical --root "$d" >/dev/null 2>&1 ||
    { printf 'FAIL: fixture builder could not generate the canonical identity module\n'; return 1; }
}

build_repo_name_mismatch() {
  build_consistent "$1" || return 1
}
build_module_name_mismatch() {
  build_consistent "$1" || return 1
  sed -i "s/^module ${PKG}$/module SomethingElse/" "$1/src/${PKG}.jl"
}
build_missing_src_file() {
  build_consistent "$1" || return 1
  rm -f "$1/src/${PKG}.jl"
}
build_hyphenated_package_name() {
  build_consistent "$1" || return 1
  sed -i 's/^name = "MyThing"/name = "My-Thing"/' "$1/Project.toml"
}
build_digit_leading_package_name() {
  build_consistent "$1" || return 1
  sed -i 's/^name = "MyThing"/name = "9Lives"/' "$1/Project.toml"
}
build_missing_using() {
  build_consistent "$1" || return 1
  sed -i "s/^using ${PKG}$/using Test/" "$1/test/runtests.jl"
}
build_readme_omits_package() {
  build_consistent "$1" || return 1
  # Every mention goes, not just the title: a README that names the package only
  # inside a clone URL still fails this section, because the title is what a
  # reader takes as the name of the thing.
  sed -i "s/${PKG}\.jl/SomeOtherThing.jl/g" "$1/README.adoc"
}
build_readme_example_drift() {
  build_consistent "$1" || return 1
  printf '\nprintln("this line is not in the README")\n' >>"$1/examples/quickstart.jl"
}
build_missing_example() {
  build_consistent "$1" || return 1
  rm -f "$1/examples/quickstart.jl"
}
build_stale_self_url() {
  build_consistent "$1" || return 1
  sed -i "s|hyperpolymath/${REPO}|hyperpolymath/${RETIRED}|" "$1/README.adoc"
}
build_no_self_url() {
  build_consistent "$1" || return 1
  sed -i '/github\.com\/hyperpolymath/d' "$1/README.adoc"
}
build_retired_name_reintroduced() {
  build_consistent "$1" || return 1
  mkdir -p "$1/docs"
  printf '= Notes\n\nFormerly known as %s, which is retired.\n' "$RETIRED" >"$1/docs/notes.adoc"
}
build_retired_register_missing() {
  build_consistent "$1" || return 1
  rm -f "$1/docs/naming/retired-names.txt"
}
build_decided_identity_drift() {
  build_consistent "$1" || return 1
  # Simulate somebody editing the generated module by hand: one character of the
  # decided package name changed.
  sed -i "0,/'T'/s//'X'/" "$1/proofs/agda/CanonicalIdentity.agda"
}

# Build a consistent tree, then plant one spelling of the retired name in a note.
# printf %b turns the \n in the argument into a real line break, which is how the
# wrapped-line family is produced.
build_spelling() {
  build_consistent "$1" || return 1
  printf '%b\n' "$2" >"$1/docs/notes.adoc"
}
build_spelling_hyphen_camel()     { build_spelling "$1" 'Formerly Old-Thing.jl, now retired.'; }
build_spelling_spaced_title()     { build_spelling "$1" 'Formerly Old Thing.Jl, now retired.'; }
build_spelling_lowercase_hyphen() { build_spelling "$1" 'Formerly old-thing, now retired.'; }
build_spelling_underscore()       { build_spelling "$1" 'Formerly Old_Thing.jl, now retired.'; }
build_spelling_upper_case()       { build_spelling "$1" 'Formerly OLD_THING.JL, now retired.'; }
build_spelling_no_suffix()        { build_spelling "$1" 'Formerly OldThing, now retired.'; }
build_spelling_no_separators()    { build_spelling "$1" 'Formerly oldthingjl, now retired.'; }
build_spelling_wrapped_line()     { build_spelling "$1" 'Formerly Old\nThing.jl, now retired.'; }

# The consistent tree, but with the REAL register (every entry the repository
# retired) and sentences that use the words of the retired name in legitimate
# senses. The checker must accept it: it is the control for over-matching.
build_legitimate_mentions() {
  build_consistent "$1" || return 1
  cp "docs/naming/retired-names.txt" "$1/docs/naming/retired-names.txt" || return 1
  cat >"$1/docs/notes.adoc" <<'ADOC'
= Notes

The roadmap lists an Automated "Reuse Audit" feature that is not yet built.

The package is classified as a Julia package — dependency reuse auditing
is the field it belongs to.

This repository used to be named after a "reuse audit" capability.
A Julia package reuse auditing tool is a different project.
ADOC
}

workdir="$(mktemp -d)"
trap 'rm -rf "$workdir"' EXIT

fail=0
ran=0
accepted=0
rejected=0
for entry in "${cases[@]}"; do
  IFS='|' read -r name sections expected builder <<<"$entry"
  dir="${workdir}/${name}"
  mkdir -p "$dir"
  if ! "$builder" "$dir"; then
    printf 'FAIL: %s: fixture builder failed\n' "$name"
    fail=1
    continue
  fi
  args=(--root "$dir")
  if [ "$sections" != "ALL" ]; then args+=(--sections "$sections"); fi
  # The repository name the checker is told it lives in. Every case except the
  # reconciliation one is told the truth, so a failure can only come from the
  # tree.
  case "$name" in
    repo-name-mismatch) args+=(--repo-name "NotMyThing.jl") ;;
    *) args+=(--repo-name "$REPO") ;;
  esac
  status=0
  output="$(bash tests/check-identity.sh "${args[@]}" 2>&1)" || status=$?
  ran=$((ran + 1))
  # A rejection must be the checker REPORTING a failure, not a crash or a usage
  # error that happens to exit non-zero: it must print at least one FAIL line.
  reported=0
  if printf '%s\n' "$output" | grep -q '^FAIL: '; then reported=1; fi
  if { [ "$status" -eq "$expected" ] && [ "$expected" -eq 0 ]; } ||
     { [ "$expected" -eq 1 ] && [ "$status" -ne 0 ] && [ "$reported" -eq 1 ]; }; then
    printf 'PASS: %-28s exited %d as expected (sections: %s)\n' "$name" "$status" "$sections"
    if [ "$expected" -eq 0 ]; then accepted=$((accepted + 1)); else rejected=$((rejected + 1)); fi
    if [ "$expected" -ne 0 ]; then
      printf '%s\n' "$output" | grep -m1 '^FAIL:' | sed 's/^/        /'
    fi
  else
    printf 'FAIL: %-28s exited %d, expected %s (sections: %s)\n' "$name" "$status" "$expected" "$sections"
    printf '%s\n' "$output" | sed 's/^/        /'
    fail=1
  fi
done

printf '\nidentity-checker self-test: %d of %d cases ran\n' "$ran" "${#cases[@]}"
if [ "$ran" -ne "${#cases[@]}" ]; then
  printf 'FAIL: some declared cases did not run\n'
  fail=1
fi
if [ "$fail" -ne 0 ]; then
  printf 'FAIL: the identity checker did not behave as declared\n'
  exit 1
fi
if [ "$accepted" -lt 1 ] || [ "$rejected" -lt 1 ]; then
  printf 'FAIL: the self-test needs at least one accepted control and one rejected case\n'
  exit 1
fi
printf 'PASS: the identity checker accepted %d control tree(s) and rejected all %d broken ones\n' "$accepted" "$rejected"
