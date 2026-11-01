K9!
# SPDX-License-Identifier: MPL-2.0
# Kennel-level K9 contract: Project metadata for JuliaPackageSpitter.jl
# Security Level: Kennel (pure data, no execution)

{
  pedigree = {
    schema_version = "1.0.0",
    component_type = "project-metadata",
    security = {
      leash = 'Kennel,
      trust_level = "data-only",
      allow_network = false,
      allow_filesystem_write = false,
      allow_subprocess = false,
    },
    metadata = {
      name = "juliapackagespitter-metadata",
      version = "0.1.0",
      description = "Canonical package metadata for JuliaPackageSpitter.jl",
      author = "Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>",
    },
  },

  project = {
    name = "JuliaPackageSpitter",
    repo_name = "JuliaPackageSpitter.jl",
    uuid = "81dd1219-803c-8eeb-85ea-39cf86282952",
    uuid_profile = "ADR-008 Profile C (julia-package-identity:github.com/hyperpolymath/JuliaPackageSpitter.jl)",
    version = "0.1.0",
    language = "Julia",
    julia_compat = "1.10",
    clade = "dx",
    description = "Automated RSR-compliant Julia package scaffolding library",

    repository = {
      url = "https://github.com/hyperpolymath/JuliaPackageSpitter.jl",
      type = "git",
    },

    author = {
      name = "Jonathan D.A. Jewell",
      email = "j.d.a.jewell@open.ac.uk",
      organization = "hyperpolymath",
    },

    license = "MPL-2.0",

    exports = [
      "PackageSpec",
      "generate_package",
    ],

    artifacts = {
      manifest = "Project.toml",
      entrypoint = "src/JuliaPackageSpitter.jl",
      generator = "src/generator.jl",
      quickstart = "examples/quickstart.jl",
      identity_proof = "proofs/agda/Identity.agda",
      chora_deed = "dx-JuliaPackageSpitter.jl_chora.deed",
    },
  },
}
