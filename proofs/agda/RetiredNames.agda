-- SPDX-License-Identifier: MPL-2.0
-- SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>
--
-- GENERATED FILE. DO NOT EDIT BY HAND.
-- Regenerate with: bash scripts/gen-identity-agda.sh --mode retired
-- Source of the data: docs/naming/retired-names.txt (one retired name per line;
-- blank lines and lines beginning '#' are ignored). Each retired name is proved
-- here to be something a Julia package could never have been called, which is
-- why it had to be retired rather than adopted.
--
-- The refutation goes through IdentifierCharset.charset-excludes with the name's
-- tail given by name, or through the leading-character rule when the offending
-- character is the first one. Matching legal-stop is safe at this call site and
-- is not safe in a general lemma: here the index is a literal list from the
-- register, so the witness types come out concrete and Agda has no variable index
-- to split. See the comment in IdentifierCharset.agda.
--
-- The names in this module are transcribed by the generator; every obligation
-- below is decided by Agda when the module is typechecked. A wrong name is a
-- type error, not a warning.

{-# OPTIONS --safe --without-K --double-check #-}

module RetiredNames where

open import Agda.Builtin.Char     using (Char)
open import Agda.Builtin.List     using (List; []; _∷_)
open import Agda.Builtin.Equality using (_≡_; refl)
open import PackageNaming
open import IdentifierCharset

-- Retired name 1: "JuliaPackage-Reuse-Audit.jl" (docs/naming/retired-names.txt)
retiredName1 : List Char
retiredName1 = 'J' ∷ 'u' ∷ 'l' ∷ 'i' ∷ 'a' ∷ 'P' ∷ 'a' ∷ 'c' ∷ 'k' ∷ 'a' ∷ 'g' ∷ 'e' ∷ '-' ∷ 'R' ∷ 'e' ∷ 'u' ∷ 's' ∷ 'e' ∷ '-' ∷ 'A' ∷ 'u' ∷ 'd' ∷ 'i' ∷ 't' ∷ '.' ∷ 'j' ∷ 'l' ∷ []

-- The name without its first character.
retiredName1Tail : List Char
retiredName1Tail = 'u' ∷ 'l' ∷ 'i' ∷ 'a' ∷ 'P' ∷ 'a' ∷ 'c' ∷ 'k' ∷ 'a' ∷ 'g' ∷ 'e' ∷ '-' ∷ 'R' ∷ 'e' ∷ 'u' ∷ 's' ∷ 'e' ∷ '-' ∷ 'A' ∷ 'u' ∷ 'd' ∷ 'i' ∷ 't' ∷ '.' ∷ 'j' ∷ 'l' ∷ []

-- The offending character, pointed at by position rather than searched for: it
-- sits 12 characters into the name, so 11 into the tail.
retired-name1-illegal-char : Any (IsChar '-') retiredName1Tail
retired-name1-illegal-char = any-there (any-there (any-there (any-there (any-there (any-there (any-there (any-there (any-there (any-there (any-there (any-here refl)))))))))))

-- Therefore the tail is not a list of legal identifier characters, and the name
-- is not a legal Julia identifier: no package could ever have carried it.
retired-name1-not-legal-ident : ¬ (LegalIdent retiredName1)
retired-name1-not-legal-ident (legal-stop startWitness charsetWitness) =
  charset-excludes {c = '-'} hyphen-not-ident-char retiredName1Tail
    charsetWitness retired-name1-illegal-char

-- Retired name 2: "JuliaPackage-Reuse-Audit" (docs/naming/retired-names.txt)
retiredName2 : List Char
retiredName2 = 'J' ∷ 'u' ∷ 'l' ∷ 'i' ∷ 'a' ∷ 'P' ∷ 'a' ∷ 'c' ∷ 'k' ∷ 'a' ∷ 'g' ∷ 'e' ∷ '-' ∷ 'R' ∷ 'e' ∷ 'u' ∷ 's' ∷ 'e' ∷ '-' ∷ 'A' ∷ 'u' ∷ 'd' ∷ 'i' ∷ 't' ∷ []

-- The name without its first character.
retiredName2Tail : List Char
retiredName2Tail = 'u' ∷ 'l' ∷ 'i' ∷ 'a' ∷ 'P' ∷ 'a' ∷ 'c' ∷ 'k' ∷ 'a' ∷ 'g' ∷ 'e' ∷ '-' ∷ 'R' ∷ 'e' ∷ 'u' ∷ 's' ∷ 'e' ∷ '-' ∷ 'A' ∷ 'u' ∷ 'd' ∷ 'i' ∷ 't' ∷ []

-- The offending character, pointed at by position rather than searched for: it
-- sits 12 characters into the name, so 11 into the tail.
retired-name2-illegal-char : Any (IsChar '-') retiredName2Tail
retired-name2-illegal-char = any-there (any-there (any-there (any-there (any-there (any-there (any-there (any-there (any-there (any-there (any-there (any-here refl)))))))))))

-- Therefore the tail is not a list of legal identifier characters, and the name
-- is not a legal Julia identifier: no package could ever have carried it.
retired-name2-not-legal-ident : ¬ (LegalIdent retiredName2)
retired-name2-not-legal-ident (legal-stop startWitness charsetWitness) =
  charset-excludes {c = '-'} hyphen-not-ident-char retiredName2Tail
    charsetWitness retired-name2-illegal-char

-- Retired name 3: "juliapackage-reuse-audit" (docs/naming/retired-names.txt)
retiredName3 : List Char
retiredName3 = 'j' ∷ 'u' ∷ 'l' ∷ 'i' ∷ 'a' ∷ 'p' ∷ 'a' ∷ 'c' ∷ 'k' ∷ 'a' ∷ 'g' ∷ 'e' ∷ '-' ∷ 'r' ∷ 'e' ∷ 'u' ∷ 's' ∷ 'e' ∷ '-' ∷ 'a' ∷ 'u' ∷ 'd' ∷ 'i' ∷ 't' ∷ []

-- The name without its first character.
retiredName3Tail : List Char
retiredName3Tail = 'u' ∷ 'l' ∷ 'i' ∷ 'a' ∷ 'p' ∷ 'a' ∷ 'c' ∷ 'k' ∷ 'a' ∷ 'g' ∷ 'e' ∷ '-' ∷ 'r' ∷ 'e' ∷ 'u' ∷ 's' ∷ 'e' ∷ '-' ∷ 'a' ∷ 'u' ∷ 'd' ∷ 'i' ∷ 't' ∷ []

-- The offending character, pointed at by position rather than searched for: it
-- sits 12 characters into the name, so 11 into the tail.
retired-name3-illegal-char : Any (IsChar '-') retiredName3Tail
retired-name3-illegal-char = any-there (any-there (any-there (any-there (any-there (any-there (any-there (any-there (any-there (any-there (any-there (any-here refl)))))))))))

-- Therefore the tail is not a list of legal identifier characters, and the name
-- is not a legal Julia identifier: no package could ever have carried it.
retired-name3-not-legal-ident : ¬ (LegalIdent retiredName3)
retired-name3-not-legal-ident (legal-stop startWitness charsetWitness) =
  charset-excludes {c = '-'} hyphen-not-ident-char retiredName3Tail
    charsetWitness retired-name3-illegal-char

-- Retired name 4: "JuliaPackage_Reuse_Audit.jl" (docs/naming/retired-names.txt)
retiredName4 : List Char
retiredName4 = 'J' ∷ 'u' ∷ 'l' ∷ 'i' ∷ 'a' ∷ 'P' ∷ 'a' ∷ 'c' ∷ 'k' ∷ 'a' ∷ 'g' ∷ 'e' ∷ '_' ∷ 'R' ∷ 'e' ∷ 'u' ∷ 's' ∷ 'e' ∷ '_' ∷ 'A' ∷ 'u' ∷ 'd' ∷ 'i' ∷ 't' ∷ '.' ∷ 'j' ∷ 'l' ∷ []

-- The name without its first character.
retiredName4Tail : List Char
retiredName4Tail = 'u' ∷ 'l' ∷ 'i' ∷ 'a' ∷ 'P' ∷ 'a' ∷ 'c' ∷ 'k' ∷ 'a' ∷ 'g' ∷ 'e' ∷ '_' ∷ 'R' ∷ 'e' ∷ 'u' ∷ 's' ∷ 'e' ∷ '_' ∷ 'A' ∷ 'u' ∷ 'd' ∷ 'i' ∷ 't' ∷ '.' ∷ 'j' ∷ 'l' ∷ []

-- The offending character, pointed at by position rather than searched for: it
-- sits 24 characters into the name, so 23 into the tail.
retired-name4-illegal-char : Any (IsChar '.') retiredName4Tail
retired-name4-illegal-char = any-there (any-there (any-there (any-there (any-there (any-there (any-there (any-there (any-there (any-there (any-there (any-there (any-there (any-there (any-there (any-there (any-there (any-there (any-there (any-there (any-there (any-there (any-there (any-here refl)))))))))))))))))))))))

-- Therefore the tail is not a list of legal identifier characters, and the name
-- is not a legal Julia identifier: no package could ever have carried it.
retired-name4-not-legal-ident : ¬ (LegalIdent retiredName4)
retired-name4-not-legal-ident (legal-stop startWitness charsetWitness) =
  charset-excludes {c = '.'} dot-not-ident-char retiredName4Tail
    charsetWitness retired-name4-illegal-char

-- 4 retired name(s) refuted.
