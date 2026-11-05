# SPDX-License-Identifier: MPL-2.0
# SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>
#
# The canonical quick start. README.adoc reproduces this file's body verbatim,
# test/identity.jl fails if the two drift, and the same test executes this file
# and asserts on what it returns. The documented snippet is therefore a fixture
# that runs, not a claim somebody typed once.
using JuliaPackageSpitter

# What to scaffold: package name, domain summary, authors, CI profile, FFI flag.
# PackageSpec takes these positionally — there is no keyword constructor.
spec = PackageSpec(
    "NuclearSafety",
    "Core cooling logic for SMR reactors",
    ["Jonathan D.A. Jewell"],
    :standard,
    false,
)

# Scaffold into a temporary directory, so this file runs anywhere and leaves
# nothing behind. generate_package returns its completion message.
mktempdir() do dir
    generate_package(spec, dir)
end
