#!/usr/bin/env bash
# SPDX-License-Identifier: MPL-2.0
# SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>
#
# check-identity.sh — the mechanical half of the package identity gate.
#
# The Agda half (proofs/agda, checked by tests/check-proofs.sh) proves the rule:
# a repository name is its package name with ".jl" appended, that map is
# injective, its witness is unique, and it is never the identity. This script
# applies the rule to the tree in front of it, reading each value from a
# different place so that no single file can declare itself consistent:
#
#   package name     Project.toml
#   module name      the `module X` declaration inside src/<X>.jl
#   source file      the filename src/<X>.jl
#   test wiring      `using X` in test/runtests.jl
#   documentation    README.adoc naming <X>.jl, and its julia snippet being
#                    byte-identical to examples/quickstart.jl
#   repository name  --repo-name, else $GITHUB_REPOSITORY, else the origin remote
#   self-references  github.com/hyperpolymath/<name> URLs that name THIS
#                    repository, which must use the current name and not a
#                    retired one (URLs naming other estate repositories are
#                    correct and are left alone)
#   retired names    docs/naming/retired-names.txt, minus the allowlist
#   decided identity the characters committed in proofs/agda/CanonicalIdentity.agda
#
# Fail-closed by construction: a missing file, an unreadable value or an empty
# scan result is a failure, never a pass and never a skip. Every section prints
# PASS or FAIL with the value it examined, so a green run is auditable from the
# log alone.
#
# Usage:
#   tests/check-identity.sh [--root DIR] [--repo-name NAME] [--sections a,b,c]
set -uo pipefail

export LC_ALL=C

root="."
repo_name=""
sections=""

usage() { sed -n '4,30p' "$0" | sed 's/^# \{0,1\}//'; }

while [ "$#" -gt 0 ]; do
  case "$1" in
    --root) root="${2:?--root needs a directory}"; shift 2 ;;
    --root=*) root="${1#--root=}"; shift ;;
    --repo-name) repo_name="${2:?--repo-name needs a name}"; shift 2 ;;
    --repo-name=*) repo_name="${1#--repo-name=}"; shift ;;
    --sections) sections="${2:?--sections needs a comma-separated list}"; shift 2 ;;
    --sections=*) sections="${1#--sections=}"; shift ;;
    -h | --help) usage; exit 0 ;;
    *) printf 'FAIL: check-identity: unknown argument %s\n' "$1" >&2; exit 2 ;;
  esac
done

ALL_SECTIONS="project-name identifier src-file module-decl tests-using readme-names readme-example reconciled internal-urls retired-names decided-identity"

if [ -z "$sections" ]; then
  sections="$ALL_SECTIONS"
else
  for s in ${sections//,/ }; do
    case " $ALL_SECTIONS " in
      *" $s "*) ;;
      *) printf 'FAIL: check-identity: unknown section %s\n' "$s" >&2; exit 2 ;;
    esac
  done
fi

want() { case " ${sections//,/ } " in *" $1 "*) return 0 ;; *) return 1 ;; esac; }

pass_count=0
fail_count=0
note_pass() { pass_count=$((pass_count + 1)); printf 'PASS: %s\n' "$1"; }
note_fail() { fail_count=$((fail_count + 1)); printf 'FAIL: %s\n' "$1"; }

[ -d "$root" ] || { printf 'FAIL: check-identity: root %s is not a directory\n' "$root" >&2; exit 2; }

allowlist=""
if [ -f "${root}/docs/naming/retired-names-allowlist.txt" ]; then
  allowlist="$(grep -vE '^[[:space:]]*(#|$)' "${root}/docs/naming/retired-names-allowlist.txt" |
    sed 's/[[:space:]]*$//')"
fi

is_allowlisted() {
  local p="$1" a
  [ -n "$allowlist" ] || return 1
  while IFS= read -r a; do
    [ -n "$a" ] || continue
    if [ "$p" = "$a" ]; then return 0; fi
  done <<<"$allowlist"
  return 1
}

# Files to scan: everything in the tree except the VCS directory and the
# generated directory (whose contents this gate produces at check time).
scan_grep() { # extra grep args...
  grep -rIn "$@" --exclude-dir=.git --exclude-dir=generated "$root" 2>/dev/null
}

# Turn a scan hit into a repository-relative path (the form the allowlist uses).
relativize() {
  local p="$1"
  p="${p#"$root"}"
  printf '%s' "${p#/}"
}

resolve_repo_name() {
  local url base
  if [ -n "$repo_name" ]; then printf '%s' "$repo_name"; return 0; fi
  if [ -n "${GITHUB_REPOSITORY:-}" ]; then printf '%s' "${GITHUB_REPOSITORY##*/}"; return 0; fi
  if command -v git >/dev/null 2>&1 && git -C "$root" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    url="$(git -C "$root" remote get-url origin 2>/dev/null || true)"
    if [ -n "$url" ]; then
      base="${url##*/}"
      printf '%s' "${base%.git}"
      return 0
    fi
  fi
  return 1
}

project_toml_name() {
  awk '
    /^[[:space:]]*\[/ { exit }
    /^[[:space:]]*name[[:space:]]*=/ {
      if (match($0, /"[^"]*"/)) { print substr($0, RSTART + 1, RLENGTH - 2); exit }
    }
  ' "$1"
}

# ── package name ────────────────────────────────────────────────────────────

pkg=""
if want project-name; then
  toml="${root}/Project.toml"
  if [ ! -f "$toml" ]; then
    note_fail "project-name: ${toml} does not exist"
  else
    pkg="$(project_toml_name "$toml")"
    if [ -z "$pkg" ]; then
      note_fail "project-name: no top-level name = \"...\" in ${toml}"
    else
      note_pass "project-name: Project.toml declares '${pkg}'"
    fi
  fi
fi

if [ -z "$pkg" ] && [ -f "${root}/Project.toml" ]; then
  pkg="$(project_toml_name "${root}/Project.toml")"
fi

if want identifier; then
  if [ -z "$pkg" ]; then
    note_fail "identifier: no package name to check"
  elif printf '%s' "$pkg" | grep -qE '^[A-Za-z_][A-Za-z0-9_!]*$'; then
    note_pass "identifier: '${pkg}' is a legal Julia identifier (leading letter or underscore; letters, digits, underscore, '!' thereafter)"
  else
    note_fail "identifier: '${pkg}' is not a legal Julia identifier — a module cannot be named this, which is the defect class this gate exists to stop"
  fi
fi

if want src-file; then
  if [ -z "$pkg" ]; then
    note_fail "src-file: no package name to check"
  elif [ -f "${root}/src/${pkg}.jl" ]; then
    note_pass "src-file: src/${pkg}.jl exists"
  else
    note_fail "src-file: src/${pkg}.jl does not exist (found: $(ls "${root}/src" 2>/dev/null | tr '\n' ' '))"
  fi
fi

if want module-decl; then
  if [ -z "$pkg" ] || [ ! -f "${root}/src/${pkg}.jl" ]; then
    note_fail "module-decl: cannot check without src/${pkg:-<unknown>}.jl"
  elif grep -qE "^module[[:space:]]+${pkg}[[:space:]]*$" "${root}/src/${pkg}.jl"; then
    note_pass "module-decl: src/${pkg}.jl declares 'module ${pkg}'"
  else
    note_fail "module-decl: src/${pkg}.jl does not declare 'module ${pkg}' (found: $(grep -oE '^module[[:space:]]+[A-Za-z0-9_!]+' "${root}/src/${pkg}.jl" | tr '\n' ' '))"
  fi
fi

if want tests-using; then
  if [ -z "$pkg" ]; then
    note_fail "tests-using: no package name to check"
  elif [ ! -f "${root}/test/runtests.jl" ]; then
    note_fail "tests-using: test/runtests.jl does not exist"
  elif grep -qE "^using[[:space:]]+${pkg}[[:space:]]*$" "${root}/test/runtests.jl"; then
    note_pass "tests-using: test/runtests.jl has 'using ${pkg}'"
  else
    note_fail "tests-using: test/runtests.jl never loads the package by name (expected a line 'using ${pkg}')"
  fi
fi

if want readme-names; then
  readme=""
  for candidate in README.adoc README.md; do
    if [ -f "${root}/${candidate}" ]; then readme="${root}/${candidate}"; break; fi
  done
  if [ -z "$readme" ]; then
    note_fail "readme-names: no README.adoc or README.md"
  elif [ -z "$pkg" ]; then
    note_fail "readme-names: no package name to check"
  elif grep -qF "${pkg}.jl" "$readme"; then
    note_pass "readme-names: ${readme#"${root}/"} names ${pkg}.jl"
  else
    note_fail "readme-names: ${readme#"${root}/"} never mentions ${pkg}.jl — the entry document does not name the thing it documents"
  fi
fi

if want readme-example; then
  readme="${root}/README.adoc"
  example="${root}/examples/quickstart.jl"
  if [ ! -f "$readme" ]; then
    note_fail "readme-example: ${readme} does not exist"
  elif [ ! -f "$example" ]; then
    note_fail "readme-example: ${example} does not exist — the documented snippet must be a file that is executed, not prose"
  else
    block="$(awk '
      /^\[source,julia\][[:space:]]*$/ { pending = 1; next }
      pending && /^----+[[:space:]]*$/ { pending = 0; infence = 1; next }
      infence && /^----+[[:space:]]*$/ { exit }
      infence { print }
    ' "$readme")"
    body="$(awk 'BEGIN { skip = 1 } skip && /^#/ { next } skip && /^[[:space:]]*$/ { next } { skip = 0; print }' "$example")"
    if [ -z "$block" ]; then
      note_fail "readme-example: no [source,julia] block found in README.adoc"
    elif [ -z "$body" ]; then
      note_fail "readme-example: examples/quickstart.jl has no content after its header comments"
    elif [ "$block" = "$body" ]; then
      note_pass "readme-example: README.adoc's julia block is byte-identical to examples/quickstart.jl (minus its header comments)"
    else
      note_fail "readme-example: README.adoc's julia block differs from examples/quickstart.jl — the documented quick start is not the code that is tested"
      diff -u --label "examples/quickstart.jl" --label "README.adoc [source,julia]" \
        <(printf '%s\n' "$body") <(printf '%s\n' "$block") | head -40
    fi
  fi
fi

# ── reconciliation ──────────────────────────────────────────────────────────

if want reconciled; then
  if ! observed_repo="$(resolve_repo_name)"; then
    note_fail "reconciled: cannot determine the repository name (pass --repo-name, or set GITHUB_REPOSITORY, or run in a clone with an origin remote)"
  elif [ -z "$pkg" ]; then
    note_fail "reconciled: no package name to reconcile against"
  elif [ "$observed_repo" = "${pkg}.jl" ]; then
    note_pass "reconciled: repository '${observed_repo}' = package '${pkg}' ++ \".jl\""
  else
    note_fail "reconciled: repository is '${observed_repo}' but the package is '${pkg}', so the repository name should be '${pkg}.jl'. The two names describe different things to anyone arriving from a search result."
  fi
fi

if want internal-urls; then
  if ! observed_repo="$(resolve_repo_name)"; then
    note_fail "internal-urls: cannot determine the repository name"
  else
    # Only self-references are in scope. A URL that names another repository in
    # the estate (standards, hypatia, cicd-suite, ...) is correct and must not be
    # flagged: this section asks whether the tree still points at itself by the
    # name it currently has.
    refs="$(scan_grep -oE 'github\.com/hyperpolymath/[A-Za-z0-9._-]+' || true)"
    if [ -z "$refs" ]; then
      note_fail "internal-urls: found no github.com/hyperpolymath/... reference in the tree — this repository documents itself by URL, so an empty result means the scan is broken rather than the tree being clean"
    else
      self_current=0
      self_retired=0
      shown=0
      retired_url_hits=""
      if [ -f "${root}/docs/naming/retired-names.txt" ]; then
        retired_url_hits="$(grep -vE '^[[:space:]]*(#|$)' "${root}/docs/naming/retired-names.txt" |
          sed 's/[[:space:]]*$//')"
      fi
      while IFS= read -r ref; do
        [ -n "$ref" ] || continue
        path="$(relativize "${ref%%:*}")"
        named="${ref##*github.com/hyperpolymath/}"
        if [ "$named" = "$observed_repo" ] || [ "$named" = "${observed_repo}.git" ]; then
          self_current=$((self_current + 1))
          continue
        fi
        match=0
        while IFS= read -r retired; do
          [ -n "$retired" ] || continue
          if [ "$named" = "$retired" ] || [ "$named" = "${retired}.git" ]; then match=1; break; fi
        done <<<"$retired_url_hits"
        if [ "$match" -eq 1 ]; then
          if is_allowlisted "$path"; then continue; fi
          self_retired=$((self_retired + 1))
          if [ "$shown" -lt 25 ]; then
            printf '  %s -> github.com/hyperpolymath/%s\n' "$path" "$named"
            shown=$((shown + 1))
          fi
        fi
      done <<<"$refs"
      if [ "$self_retired" -gt 0 ]; then
        note_fail "internal-urls: ${self_retired} self-reference(s) still point at a retired repository name (showing at most 25 above). GitHub redirects the old URL, so these keep working and keep teaching the old name."
      elif [ "$self_current" -eq 0 ]; then
        note_fail "internal-urls: no self-reference to github.com/hyperpolymath/${observed_repo} anywhere in the tree — either the scan is broken or the repository stopped naming itself"
      else
        note_pass "internal-urls: ${self_current} self-reference(s) all name github.com/hyperpolymath/${observed_repo}, and none points at a retired name"
      fi
    fi
  fi
fi

# ── retired-name spellings ──────────────────────────────────────────────────
#
# A register entry names one identity, and the tree has carried that identity in
# every spelling a person or a tool produced: hyphens, spaces, underscores, title
# case, upper case, the ".jl" suffix dropped, the separators dropped, or a line
# break in the middle of a sentence. So each entry becomes a pattern that matches
# all of them:
#   1. split the entry into words at camel humps and at separator runs [-_. ];
#   2. lowercase the words and rejoin them with [-_. ]* (any run of separators,
#      including none);
#   3. a trailing "jl" word is an optional suffix, ([-_. ]*jl)?.
# Matching is case-insensitive (the haystack is lowercased), and every line is
# also tried joined to the line before it, so a name wrapped across a line break
# is one occurrence. The rule needs every word of the entry, in order, so a
# legitimate mention such as 'Automated "Reuse Audit"' or 'Julia package —
# dependency reuse auditing' does not match.
#
# Written for mawk: no interval expressions anywhere, and no gawk extensions.
spelling_pattern() { # register entry -> ERE on stdout
  awk -v name="$1" '
    function flush() { if (word != "") { words[++n] = tolower(word); word = "" } }
    BEGIN {
      n = 0; word = ""; prev = ""
      len = length(name)
      for (i = 1; i <= len; i++) {
        c = substr(name, i, 1)
        if (c ~ /[-_. ]/) { flush(); prev = c; continue }
        if (c ~ /[A-Z]/ && word != "" &&
            (prev ~ /[a-z0-9]/ || (prev ~ /[A-Z]/ && substr(name, i + 1, 1) ~ /[a-z]/)))
          flush()
        word = word c
        prev = c
      }
      flush()
      if (n == 0) exit 1
      suffix = ""
      # A trailing word boundary keeps "reuse auditing" (a concept) from matching
      # "reuse audit" (the retired identity): the last word must end the match.
      suffix = "([^a-z]|$)"
      if (n > 1 && words[n] == "jl") { n--; suffix = "([-_. ]*jl)?" suffix }
      out = ""
      for (k = 1; k <= n; k++) {
        w = words[k]
        esc = ""
        for (j = 1; j <= length(w); j++) {
          ch = substr(w, j, 1)
          esc = (ch ~ /[a-z0-9]/) ? esc ch : esc "\\" ch
        }
        out = (k == 1) ? esc : out "[-_. ]*" esc
      }
      printf "%s%s\n", out, suffix
    }'
}

# retired_scan PATTERN FILE -> path:line:text for each line (or wrapped pair) that matches
retired_scan() {
  RETIRED_PAT="$1" awk '
    BEGIN { pat = ENVIRON["RETIRED_PAT"]; prev = "" }
    {
      cur = tolower($0)
      if (cur ~ pat) {
        printf "%s:%d:%s\n", FILENAME, FNR, $0
      } else if (prev !~ pat && (prev " " cur) ~ pat) {
        printf "%s:%d:[wrapped across line break] %s\n", FILENAME, FNR, $0
      }
      prev = cur
    }' "$2"
}

if want retired-names; then
  register="${root}/docs/naming/retired-names.txt"
  if [ ! -f "$register" ]; then
    note_fail "retired-names: ${register} does not exist — without the register the gate cannot tell a retired name from a current one, and a rename leaves no trace"
  else
    names="$(grep -vE '^[[:space:]]*(#|$)' "$register" | sed 's/[[:space:]]*$//')"
    if [ -z "$names" ]; then
      note_fail "retired-names: ${register} declares no retired names"
    else
      # One spelling-insensitive pattern per register entry, joined by '|'.
      pattern=""
      bad_entry=""
      while IFS= read -r name; do
        one="$(spelling_pattern "$name")" || { bad_entry="$name"; break; }
        if [ -z "$one" ]; then bad_entry="$name"; break; fi
        pattern="${pattern:+${pattern}|}${one}"
      done <<<"$names"
      if [ -n "$bad_entry" ]; then
        note_fail "retired-names: cannot derive a spelling pattern for register entry '${bad_entry}'"
      else
        hits=""
        while IFS= read -r f; do
          grep -Iq . "$f" 2>/dev/null || continue
          hits+="$(retired_scan "$pattern" "$f")"$'\n'
        done < <(find "$root" \( -name .git -o -name generated \) -prune -o -type f -print)
        hits="$(printf '%s' "$hits" | grep -v '^$' || true)"
        if [ -z "$hits" ]; then
          note_pass "retired-names: no spelling of $(printf '%s' "$names" | wc -l | tr -d ' ') retired name(s) anywhere in the tree (pattern: ${pattern})"
        else
          bad=0
          shown=0
          # One line matched by two retired forms is one finding, so deduplicate on
          # path:line before counting.
          deduped="$(printf '%s\n' "$hits" | awk -F: '{ key = $1 ":" $2 } !seen[key]++ { print }')"
          while IFS= read -r hit; do
            [ -n "$hit" ] || continue
            path="$(relativize "${hit%%:*}")"
            if is_allowlisted "$path"; then continue; fi
            bad=$((bad + 1))
            if [ "$shown" -lt 25 ]; then
              printf '  %s\n' "$(printf '%s' "$hit" | sed "s|^${root}/||; s|^\./||" | cut -c1-160)"
              shown=$((shown + 1))
            fi
          done <<<"$deduped"
          if [ "$bad" -eq 0 ]; then
            note_pass "retired-names: every spelling of a retired name sits in the recorded historical allowlist"
          else
            note_fail "retired-names: ${bad} occurrence(s) of a retired name in any spelling outside the allowlist (showing at most 25 above). A retired name that survives in the tree is how the next person gets confused."
          fi
        fi
      fi
    fi
  fi
fi

if want decided-identity; then
  canonical="${root}/proofs/agda/CanonicalIdentity.agda"
  if [ ! -f "$canonical" ]; then
    note_fail "decided-identity: ${canonical} does not exist — the committed Agda identity is missing, so the proof gate has nothing decided to compare the live tree against"
  elif [ -z "$pkg" ]; then
    note_fail "decided-identity: no package name to compare"
  else
    decided="$(sed -n 's/^canonicalPackage = //p' "$canonical" | tr -d ' \n' | sed "s/∷//g; s/\[\]//g; s/'//g")"
    if [ -z "$decided" ]; then
      note_fail "decided-identity: cannot read canonicalPackage from ${canonical} — the generated module has been edited into a shape the gate cannot parse"
    elif [ "$decided" = "$pkg" ]; then
      note_pass "decided-identity: proofs/agda/CanonicalIdentity.agda decides '${decided}', which is what Project.toml declares"
    else
      note_fail "decided-identity: proofs/agda/CanonicalIdentity.agda decides '${decided}' but Project.toml declares '${pkg}' — regenerate with scripts/gen-identity-agda.sh --mode canonical"
    fi
  fi
fi

printf '\nidentity: %d passed, %d failed\n' "$pass_count" "$fail_count"
if [ "$fail_count" -gt 0 ]; then exit 1; fi
if [ "$pass_count" -eq 0 ]; then
  printf 'FAIL: identity: nothing was checked — a gate that examined nothing is not a gate\n'
  exit 1
fi
exit 0
